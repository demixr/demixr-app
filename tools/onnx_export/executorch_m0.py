"""M0 gating spike: export htdemucs's conv+transformer core via torch.export,
lower to a CoreML-delegated ExecuTorch .pte, report how much is delegated, and
benchmark on the Mac vs the CPU baseline (~0.59 s/chunk ONNX-CPU).

STFT stays OUT of the graph (the Core takes the precomputed magnitude spec +
the time-domain mix), so the delegate only sees conv + transformer + convT.
"""
import sys
import time
import types

# torch was bumped to 2.12 by executorch; the old torchaudio .so won't load and
# demucs only needs it transitively — stub it.
if "torchaudio" not in sys.modules:
    _ta = types.ModuleType("torchaudio")
    _ta.__version__ = "0"
    sys.modules["torchaudio"] = _ta

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from demucs.pretrained import get_model

from coreml_core_spike import Core


def export_safe_mha_forward(self_, query, key, value, key_padding_mask=None,
                            need_weights=True, attn_mask=None,
                            average_attn_weights=True, is_causal=False):
    """nn.MultiheadAttention.forward built from primitives, torch.export-safe.

    Same as demucs-onnx's ONNX-friendly MHA, but detects self-attention with
    Python identity (`query is key`) instead of `torch.equal` (a data-dependent
    op torch.export rejects). Identity is resolved at trace time.
    """
    if self_.batch_first:
        query = query.transpose(0, 1)
        key = key.transpose(0, 1)
        value = value.transpose(0, 1)

    tgt_len, bsz, embed_dim = query.shape
    src_len = key.shape[0]
    num_heads = self_.num_heads
    head_dim = embed_dim // num_heads
    scaling = head_dim ** -0.5

    if self_._qkv_same_embed_dim:
        w = self_.in_proj_weight
        b = self_.in_proj_bias
        if query is key and key is value:
            q, k, v = F.linear(query, w, b).chunk(3, dim=-1)
        else:
            w_q, w_k, w_v = w.chunk(3, dim=0)
            b_q, b_k, b_v = (b.chunk(3, dim=0) if b is not None
                             else (None, None, None))
            q = F.linear(query, w_q, b_q)
            k = F.linear(key, w_k, b_k)
            v = F.linear(value, w_v, b_v)
    else:
        bias = self_.in_proj_bias
        q = F.linear(query, self_.q_proj_weight,
                     bias[:embed_dim] if bias is not None else None)
        k = F.linear(key, self_.k_proj_weight,
                     bias[embed_dim:2 * embed_dim] if bias is not None else None)
        v = F.linear(value, self_.v_proj_weight,
                     bias[2 * embed_dim:] if bias is not None else None)

    q = q.contiguous().view(tgt_len, bsz * num_heads, head_dim).transpose(0, 1)
    k = k.contiguous().view(src_len, bsz * num_heads, head_dim).transpose(0, 1)
    v = v.contiguous().view(src_len, bsz * num_heads, head_dim).transpose(0, 1)

    q = q * scaling
    attn = torch.bmm(q, k.transpose(1, 2))
    if attn_mask is not None:
        attn = attn + attn_mask
    attn = F.softmax(attn, dim=-1)
    out = torch.bmm(attn, v)
    out = out.transpose(0, 1).contiguous().view(tgt_len, bsz, embed_dim)
    out = self_.out_proj(out)
    if self_.batch_first:
        out = out.transpose(0, 1)
    return out, None


def main():
    print("loading htdemucs...")
    model = get_model("htdemucs").models[0].eval()
    model.use_train_segment = False

    mix = torch.randn(1, 2, 343980) * 0.1
    with torch.no_grad():
        mag = model._magnitude(model._spec(mix))

    from demucs_onnx.export.pos_embed import disable_random_pos_shift
    disable_random_pos_shift(model)
    for m in model.modules():
        if isinstance(m, nn.MultiheadAttention):
            m.forward = types.MethodType(export_safe_mha_forward, m)

    core = Core(model).eval()

    print("torch.export ...")
    ep = torch.export.export(core, (mag, mix))
    print("torch.export OK")

    from executorch.exir import to_edge_transform_and_lower
    from executorch.backends.apple.coreml.partition import CoreMLPartitioner

    edge = to_edge_transform_and_lower(ep, partitioner=[CoreMLPartitioner()])
    gm = edge.exported_program().graph_module
    deleg = [n for n in gm.graph.nodes
             if n.op == "call_function" and "delegate" in str(n.target)]
    other = [n for n in gm.graph.nodes
             if n.op == "call_function" and "delegate" not in str(n.target)]
    print(f"[CoreML] delegated partitions={len(deleg)}  "
          f"non-delegated call_functions left on CPU={len(other)}")

    prog = edge.to_executorch()
    with open("htdemucs_core_coreml.pte", "wb") as f:
        f.write(prog.buffer)
    print(f"saved htdemucs_core_coreml.pte ({len(prog.buffer)/1e6:.0f} MB)")

    # Try to execute via the ExecuTorch Python runtime (CoreML backend may not
    # be in the pip wheel; delegation stats above are informative regardless).
    try:
        from executorch.runtime import Runtime
        rt = Runtime.get()
        prog_rt = rt.load_program("htdemucs_core_coreml.pte")
        method = prog_rt.load_method("forward")
        inputs = (mag, mix)
        t0 = time.perf_counter(); method.execute(inputs); warm = time.perf_counter() - t0
        ts = []
        for _ in range(5):
            t = time.perf_counter(); method.execute(inputs); ts.append(time.perf_counter() - t)
        print(f"[CoreML] ExecuTorch run: compile+first={warm:.1f}s "
              f"steady={np.median(ts):.3f}s/chunk  (CPU baseline ~0.59)")
    except Exception as e:
        print(f"[CoreML] Python runtime execute unavailable: {str(e)[:200]}")


if __name__ == "__main__":
    main()
