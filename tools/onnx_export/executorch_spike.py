"""ExecuTorch spike: lower htdemucs core to MPS / CoreML delegate and report how
much of the graph is delegated to the GPU vs left on CPU.

Few delegated partitions covering the conv+attention core => likely captures the
~12.6x eager-MPS win on-device. Heavy fragmentation (like ONNX-RT CoreML's 112
partitions) => no win.
"""
import sys
import types

# The executorch install bumped torch to 2.12, which broke the old torchaudio
# binary. demucs only imports torchaudio transitively (not needed to define the
# model), so stub it out to avoid loading the mismatched .so.
if "torchaudio" not in sys.modules:
    _ta = types.ModuleType("torchaudio")
    _ta.__version__ = "0"
    sys.modules["torchaudio"] = _ta

import torch
from demucs.pretrained import get_model
from coreml_core_spike import Core


def summarize(edge, label):
    gm = edge.exported_program().graph_module
    delegates = [n for n in gm.graph.nodes
                 if n.op == "call_function" and "delegate" in str(n.target)]
    aten = [n for n in gm.graph.nodes
            if n.op == "call_function" and "delegate" not in str(n.target)]
    print(f"[{label}] delegated partitions={len(delegates)}  "
          f"non-delegated (CPU) ops left in top graph={len(aten)}")


def main():
    model = get_model("htdemucs").models[0].eval()
    model.use_train_segment = False
    mix = torch.randn(1, 2, 343980) * 0.1
    with torch.no_grad():
        mag = model._magnitude(model._spec(mix))

    from demucs_onnx.export.patch import patch_htdemucs_for_onnx
    patch_htdemucs_for_onnx(model)
    core = Core(model).eval()

    print("torch.export...")
    exported = torch.export.export(core, (mag, mix))
    print("exported OK")

    from executorch.exir import to_edge_transform_and_lower

    for label, mk_part in [("MPS", _mps_partitioner), ("CoreML", _coreml_partitioner)]:
        try:
            part = mk_part()
            if part is None:
                continue
            edge = to_edge_transform_and_lower(exported, partitioner=[part])
            summarize(edge, label)
        except Exception as e:
            print(f"[{label}] lowering FAILED: {str(e)[:300]}")


def _mps_partitioner():
    try:
        from executorch.backends.apple.mps.partition.mps_partitioner import MPSPartitioner
        from executorch.exir.backend.backend_details import CompileSpec
        return MPSPartitioner(compile_specs=[CompileSpec("use_fp16", bytes([1]))])
    except Exception as e:
        print("MPS partitioner unavailable:", str(e)[:150])
        return None


def _coreml_partitioner():
    try:
        from executorch.backends.apple.coreml.partition import CoreMLPartitioner
        return CoreMLPartitioner()
    except Exception as e:
        print("CoreML partitioner unavailable:", str(e)[:150])
        return None


if __name__ == "__main__":
    main()
