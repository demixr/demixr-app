"""M2 pipeline: build BOTH ExecuTorch programs and validate the full chain.

  core.pte  (CoreML, GPU):  mix -> (pre-mask spec, time)
  post.pte  (XNNPACK, CPU):  (spec, time) -> stems   [mask + iSTFT + combine]

Verifies post(core(mix)) == eager full model(mix).
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

from executorch_m0 import export_safe_mha_forward
from executorch_m2_export import CoreWithSTFT

SEG = 343980


class Post(nn.Module):
    """(pre-mask spec, time) -> stems: mask (reshape) + iSTFT + combine."""

    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, spec, time_out):
        zout = self.model._mask(spec, spec)  # cac path ignores 1st arg
        xi = self.model._ispec(zout, SEG)
        return time_out + xi


def lower_run(net, args, partitioner, name):
    from executorch.exir import to_edge_transform_and_lower
    ep = torch.export.export(net, args)
    edge = to_edge_transform_and_lower(ep, partitioner=[partitioner])
    gm = edge.exported_program().graph_module
    deleg = sum(1 for n in gm.graph.nodes
                if n.op == "call_function" and "delegate" in str(n.target))
    cpu = sum(1 for n in gm.graph.nodes
              if n.op == "call_function" and "delegate" not in str(n.target))
    prog = edge.to_executorch()
    path = f"{name}.pte"
    with open(path, "wb") as f:
        f.write(prog.buffer)
    print(f"[{name}] partitions={deleg} cpu_ops_left={cpu} size={len(prog.buffer)/1e6:.0f}MB")
    from executorch.runtime import Runtime
    return Runtime.get().load_program(path).load_method("forward")


def main():
    model = get_model("htdemucs").models[0].eval()
    model.use_train_segment = False
    from demucs_onnx.export.patch import patch_htdemucs_for_onnx
    patch_htdemucs_for_onnx(model)
    for m in model.modules():
        if isinstance(m, nn.MultiheadAttention):
            m.forward = types.MethodType(export_safe_mha_forward, m)
    # RealSTFT/RealISTFT register their DFT kernels as non-persistent buffers;
    # the XNNPACK pass-manager re-validation rejects those. Mark all persistent.
    for m in model.modules():
        nps = getattr(m, "_non_persistent_buffers_set", None)
        if nps:
            for n in list(nps):
                nps.discard(n)

    core = CoreWithSTFT(model).eval()
    post = Post(model).eval()
    mix = torch.randn(1, 2, SEG) * 0.1

    with torch.no_grad():
        eager_full = model(mix)
        spec_e, time_e = core(mix)
        post_eager = post(spec_e, time_e)
    ep_corr = torch.corrcoef(torch.stack(
        [post_eager.flatten(), eager_full.flatten()]))[0, 1].item()
    print(f"eager Post(Core(mix)) vs full model: corr={ep_corr:.4f}")

    from executorch.backends.apple.coreml.partition import CoreMLPartitioner
    from executorch.backends.xnnpack.partition.xnnpack_partitioner import (
        XnnpackPartitioner,
    )
    core_m = lower_run(core, (mix,), CoreMLPartitioner(), "core_coreml")
    post_m = lower_run(post, (spec_e, time_e), XnnpackPartitioner(), "post_xnnpack")

    # full chain on the runtimes
    t0 = time.perf_counter()
    spec_t, time_t = core_m.execute((mix,))
    stems = post_m.execute((spec_t, time_t))[0]
    dt = time.perf_counter() - t0
    corr = torch.corrcoef(torch.stack(
        [stems.float().flatten(), eager_full.float().flatten()]))[0, 1].item()
    rel = ((stems.float() - eager_full.float()).norm()
           / (eager_full.float().norm() + 1e-9)).item()
    print(f"PTE chain stems shape={tuple(stems.shape)} "
          f"vs eager full: corr={corr:.4f} rel={rel:.4f}  ({dt:.2f}s/chunk)")


if __name__ == "__main__":
    main()
