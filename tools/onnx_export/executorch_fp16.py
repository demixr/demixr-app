"""fp16 export via model.half(): halves stored .pte weights (download size).
Exports core (CoreML) + post (XNNPACK) in fp16, measures size + parity vs the
fp32 eager model.
"""
import sys
import types

if "torchaudio" not in sys.modules:
    _ta = types.ModuleType("torchaudio")
    _ta.__version__ = "0"
    sys.modules["torchaudio"] = _ta

import torch
import torch.nn as nn
from demucs.pretrained import get_model

from executorch_m0 import export_safe_mha_forward
from executorch_m2_export import CoreWithSTFT
from executorch_m2_pipeline import Post

SEG = 343980


def main():
    model = get_model("htdemucs").models[0].eval()
    model.use_train_segment = False
    from demucs_onnx.export.patch import patch_htdemucs_for_onnx
    patch_htdemucs_for_onnx(model)
    for m in model.modules():
        if isinstance(m, nn.MultiheadAttention):
            m.forward = types.MethodType(export_safe_mha_forward, m)
    for m in model.modules():
        nps = getattr(m, "_non_persistent_buffers_set", None)
        if nps:
            for n in list(nps):
                nps.discard(n)

    core = CoreWithSTFT(model).eval()
    post = Post(model).eval()
    mix = torch.randn(1, 2, SEG) * 0.1
    with torch.no_grad():
        eager_full = model(mix).float()
        spec_e, time_e = core(mix)

    # fp16 weights everywhere.
    model.half()
    mix16 = mix.half()
    spec16, time16 = spec_e.half(), time_e.half()

    from executorch.exir import to_edge_transform_and_lower
    from executorch.runtime import Runtime
    from executorch.backends.apple.coreml.partition import CoreMLPartitioner
    from executorch.backends.xnnpack.partition.xnnpack_partitioner import (
        XnnpackPartitioner,
    )

    ep_core = torch.export.export(core, (mix16,))
    buf = to_edge_transform_and_lower(
        ep_core, partitioner=[CoreMLPartitioner()]).to_executorch().buffer
    open("core_coreml_fp16.pte", "wb").write(buf)
    print(f"core_coreml_fp16.pte = {len(buf)/1e6:.0f} MB (fp32 was 277)")

    ep_post = torch.export.export(post, (spec16, time16))
    bufp = to_edge_transform_and_lower(
        ep_post, partitioner=[XnnpackPartitioner()]).to_executorch().buffer
    open("post_xnnpack_fp16.pte", "wb").write(bufp)
    print(f"post_xnnpack_fp16.pte = {len(bufp)/1e6:.0f} MB (fp32 was 129)")

    rt = Runtime.get()
    cm = rt.load_program("core_coreml_fp16.pte").load_method("forward")
    pm = rt.load_program("post_xnnpack_fp16.pte").load_method("forward")
    spec_t, time_t = cm.execute((mix16,))
    stems = pm.execute((spec_t, time_t))[0].float()
    corr = torch.corrcoef(torch.stack(
        [stems.flatten(), eager_full.flatten()]))[0, 1].item()
    print(f"fp16 chain parity vs fp32 eager: corr={corr:.4f}")


if __name__ == "__main__":
    main()
