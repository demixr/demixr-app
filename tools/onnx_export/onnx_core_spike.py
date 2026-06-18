"""Decisive spike v2: export htdemucs's conv+transformer CORE (no STFT) to ONNX,
then benchmark ONNX Runtime CoreML EP (GPU/ANE) vs CPU on macOS.

This uses our actual runtime (ONNX Runtime). The STFT slice op was what broke
the CoreML EP on the full model; the core has no STFT, so this tests whether
CoreML can offload the heavy conv+transformer and whether it beats CPU.
"""
import time
import numpy as np
import torch
from demucs.pretrained import get_model
from coreml_core_spike import Core  # reuse the STFT-free core wrapper


def main():
    print("loading htdemucs...")
    bag = get_model("htdemucs")
    model = bag.models[0].eval()
    model.use_train_segment = False

    mix = torch.randn(1, 2, 343980) * 0.1
    with torch.no_grad():
        mag = model._magnitude(model._spec(mix))
    print(f"core inputs: mag={tuple(mag.shape)} mix={tuple(mix.shape)}")

    # Reuse demucs-onnx's export patches: they unfuse MultiheadAttention and
    # fix the positional-embedding op (the ONNX export blockers). These mutate
    # the transformer modules our Core reuses. The core doesn't call STFT, so
    # the STFT replacement is irrelevant here.
    from demucs_onnx.export.patch import patch_htdemucs_for_onnx
    patch_htdemucs_for_onnx(model)

    core = Core(model).eval()
    onnx_path = "htdemucs_core.onnx"
    print("exporting core to ONNX...")
    with torch.no_grad():
        torch.onnx.export(
            core, (mag, mix), onnx_path,
            input_names=["mag", "mix"], output_names=["spec_out", "time_out"],
            opset_version=17, do_constant_folding=True,
        )
    print("ONNX export OK")

    import onnxruntime as ort
    print("available EPs:", ort.get_available_providers())
    feed = {"mag": mag.numpy().astype(np.float32), "mix": mix.numpy().astype(np.float32)}

    def bench(provider, n=6):
        try:
            so = ort.SessionOptions()
            so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            sess = ort.InferenceSession(onnx_path, sess_options=so, providers=[provider])
        except Exception as e:
            print(f"  [{provider}] session FAILED: {str(e)[:200]}")
            return None
        try:
            t0 = time.perf_counter(); sess.run(None, feed); warm = time.perf_counter() - t0
        except Exception as e:
            print(f"  [{provider}] run FAILED: {str(e)[:200]}")
            return None
        ts = []
        for _ in range(n):
            t = time.perf_counter(); sess.run(None, feed); ts.append(time.perf_counter() - t)
        print(f"  [{provider}] compile+first={warm:.1f}s steady={np.median(ts):.3f}s/chunk (min {min(ts):.3f})")
        return float(np.median(ts))

    print("benchmark (full-model ONNX CPU baseline was ~0.77s/chunk):")
    cpu = bench("CPUExecutionProvider")
    ml = bench("CoreMLExecutionProvider")
    if cpu and ml:
        print(f"\nCoreML vs CPU speedup: {cpu/ml:.2f}x")


if __name__ == "__main__":
    main()
