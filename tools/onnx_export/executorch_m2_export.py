"""M2 artifact: export the FULL htdemucs (conv-STFT in-graph) so the .pte is
audio -> stems, lower to CoreML, verify parity + delegation + speed.

Uses demucs-onnx's patch (RealSTFT/RealISTFT + real _magnitude/_mask + pos-embed
+ segment) which makes the model complex-free, plus our identity-based MHA so
torch.export accepts it. Input: mix [1,2,343980]. Output: stems [1,4,2,343980].
"""
import sys
import time
import types

if "torchaudio" not in sys.modules:
    _ta = types.ModuleType("torchaudio")
    _ta.__version__ = "0"
    sys.modules["torchaudio"] = _ta

import numpy as np
import torch
import torch.nn as nn
from demucs.pretrained import get_model

from coreml_core_spike import Core
from executorch_m0 import export_safe_mha_forward

SEG = 343980


class CoreWithSTFT(nn.Module):
    """mix -> (pre-mask spec output, time output). Includes the forward conv
    STFT (rank<=5, CoreML-ok) but NOT _mask/_ispec (rank-6 + iSTFT stay outside,
    on CPU)."""

    def __init__(self, model):
        super().__init__()
        self.model = model
        self.core = Core(model)

    def forward(self, mix):
        mag = self.model._magnitude(self.model._spec(mix))
        return self.core(mag, mix)


def main():
    print("loading + patching htdemucs (in-graph conv STFT)...")
    model = get_model("htdemucs").models[0].eval()
    model.use_train_segment = False

    from demucs_onnx.export.patch import patch_htdemucs_for_onnx
    patch_htdemucs_for_onnx(model)
    # Override the torch.equal-based MHA (data-dependent) with identity-based.
    for m in model.modules():
        if isinstance(m, nn.MultiheadAttention):
            m.forward = types.MethodType(export_safe_mha_forward, m)

    net = CoreWithSTFT(model).eval()
    mix = torch.randn(1, 2, SEG) * 0.1
    with torch.no_grad():
        ref = net(mix)[0]  # pre-mask spec output
    print(f"eager spec-out shape={tuple(ref.shape)}")

    print("torch.export (mix -> STFT+network, mask/iSTFT excluded)...")
    ep = torch.export.export(net, (mix,))
    print("export OK")

    from executorch.exir import to_edge_transform_and_lower
    from executorch.backends.apple.coreml.partition import CoreMLPartitioner
    edge = to_edge_transform_and_lower(ep, partitioner=[CoreMLPartitioner()])
    gm = edge.exported_program().graph_module
    deleg = sum(1 for n in gm.graph.nodes
                if n.op == "call_function" and "delegate" in str(n.target))
    cpu = sum(1 for n in gm.graph.nodes
              if n.op == "call_function" and "delegate" not in str(n.target))
    print(f"[CoreML] delegated partitions={deleg} cpu_ops_left={cpu}")

    prog = edge.to_executorch()
    with open("htdemucs_full_coreml.pte", "wb") as f:
        f.write(prog.buffer)
    print(f"saved htdemucs_full_coreml.pte ({len(prog.buffer)/1e6:.0f} MB)")

    from executorch.runtime import Runtime
    method = Runtime.get().load_program("htdemucs_full_coreml.pte").load_method("forward")
    out = method.execute((mix,))
    o = out[0].float().flatten()
    r = ref.float().flatten()
    n = min(o.numel(), r.numel())
    corr = torch.corrcoef(torch.stack([o[:n], r[:n]]))[0, 1].item()
    rel = ((o[:n] - r[:n]).norm() / (r[:n].norm() + 1e-9)).item()
    print(f"[CoreML] parity vs eager: corr={corr:.4f} rel={rel:.4f}")

    t0 = time.perf_counter(); method.execute((mix,)); warm = time.perf_counter() - t0
    ts = []
    for _ in range(5):
        t = time.perf_counter(); method.execute((mix,)); ts.append(time.perf_counter() - t)
    print(f"[CoreML] full-model run: compile+first={warm:.1f}s "
          f"steady={np.median(ts):.3f}s/chunk (ONNX CPU full ~0.77)")


if __name__ == "__main__":
    main()
