"""M1: validate the ExecuTorch export is (a) numerically correct and (b)
lowers across backends. One torch.export, lowered to XNNPACK (fp32 CPU; should
be ~exact vs eager), CoreML (fp16; should be close), and Vulkan (Android; lower-
only delegation check on Mac). Compares each backend's output to the eager
PyTorch core on the same inputs.
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

from coreml_core_spike import Core
from executorch_m0 import export_safe_mha_forward


def build():
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
    with torch.no_grad():
        refs = core(mag, mix)  # (spec, time), eager fp32
    ep = torch.export.export(core, (mag, mix))
    return ep, (mag, mix), refs


def compare(name, out, refs):
    for o, r, lbl in zip(out, refs, ["spec", "time"]):
        o = o.float().flatten()
        r = r.float().flatten()
        n = min(o.numel(), r.numel())
        o, r = o[:n], r[:n]
        maxabs = (o - r).abs().max().item()
        rel = ((o - r).norm() / (r.norm() + 1e-9)).item()
        corr = torch.corrcoef(torch.stack([o, r]))[0, 1].item()
        print(f"   [{name}] {lbl}: maxabs={maxabs:.4f} rel={rel:.4f} corr={corr:.4f}")


def lower(ep, partitioner, name, inputs, refs, run=True):
    from executorch.exir import to_edge_transform_and_lower
    edge = to_edge_transform_and_lower(ep, partitioner=[partitioner])
    gm = edge.exported_program().graph_module
    deleg = sum(1 for n in gm.graph.nodes
                if n.op == "call_function" and "delegate" in str(n.target))
    cpu = sum(1 for n in gm.graph.nodes
              if n.op == "call_function" and "delegate" not in str(n.target))
    print(f"[{name}] partitions={deleg} cpu_ops_left={cpu}")
    if not run:
        return
    prog = edge.to_executorch()
    path = f"core_{name}.pte"
    with open(path, "wb") as f:
        f.write(prog.buffer)
    from executorch.runtime import Runtime
    rt = Runtime.get()
    method = rt.load_program(path).load_method("forward")
    out = method.execute(tuple(inputs))
    compare(name, out, refs)


def main():
    print("building + torch.export ...")
    ep, inputs, refs = build()
    print("export OK; lowering per backend ...")

    def safe(fn, label):
        try:
            fn()
        except Exception as e:
            print(f"[{label}] FAILED: {str(e)[:200]}")

    # CoreML first — our Apple GPU target, and it doesn't need flatc.
    def _coreml():
        from executorch.backends.apple.coreml.partition import CoreMLPartitioner
        lower(ep, CoreMLPartitioner(), "coreml", inputs, refs)
    safe(_coreml, "coreml")

    def _xnnpack():
        from executorch.backends.xnnpack.partition.xnnpack_partitioner import (
            XnnpackPartitioner,
        )
        lower(ep, XnnpackPartitioner(), "xnnpack", inputs, refs)
    safe(_xnnpack, "xnnpack")

    def _vulkan():
        from executorch.backends.vulkan.partitioner.vulkan_partitioner import (
            VulkanPartitioner,
        )
        lower(ep, VulkanPartitioner(), "vulkan", inputs, refs, run=False)
    safe(_vulkan, "vulkan")


if __name__ == "__main__":
    main()
