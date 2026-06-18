"""Spike: convert htdemucs to native CoreML and benchmark GPU/ANE vs CPU.

Answers: (1) does coremltools convert htdemucs at all (where ORT's CoreML EP
failed), (2) is the Apple GPU/ANE meaningfully faster than CPU at steady state?
A Mac result generalizes to iPhone (same CoreML stack).
"""
import time
import numpy as np
import torch
from demucs.pretrained import get_model

SEGMENT = 343980  # 7.8s @ 44100, the fixed model input length we use


def load_htdemucs():
    bag = get_model("htdemucs")
    model = bag.models[0]
    model.eval()
    # We always feed a fixed-length segment, so disable the dynamic
    # Fraction/int(segment*samplerate) recomputation that breaks tracing.
    model.use_train_segment = False
    return model


def trace(model):
    example = torch.zeros(1, 2, SEGMENT)
    with torch.no_grad():
        return torch.jit.trace(model, example, check_trace=False), example


def convert(traced, example):
    import coremltools as ct

    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="mix", shape=example.shape)],
        compute_units=ct.ComputeUnit.ALL,
        minimum_deployment_target=ct.target.iOS16,
        convert_to="mlprogram",
    )
    mlmodel.save("htdemucs.mlpackage")
    return mlmodel


def bench(compute_unit_name, n=6):
    import coremltools as ct

    cu = getattr(ct.ComputeUnit, compute_unit_name)
    m = ct.models.MLModel("htdemucs.mlpackage", compute_units=cu)
    x = np.random.randn(1, 2, SEGMENT).astype(np.float32) * 0.1
    inp = {"mix": x}
    # warmup (first call compiles for the target backend)
    t0 = time.perf_counter()
    m.predict(inp)
    warmup = time.perf_counter() - t0
    times = []
    for _ in range(n):
        t = time.perf_counter()
        m.predict(inp)
        times.append(time.perf_counter() - t)
    print(f"  [{compute_unit_name}] compile+first={warmup:.1f}s  "
          f"steady={np.median(times):.3f}s/chunk (min {min(times):.3f})")
    return np.median(times)


def main():
    print("loading htdemucs (PyTorch)...")
    model = load_htdemucs()
    print("tracing...")
    traced, example = trace(model)
    print("converting to CoreML (this can take a while)...")
    convert(traced, example)
    print("benchmarking (ONNX CPU baseline was ~0.77s/chunk):")
    cpu = bench("CPU_ONLY")
    allu = bench("ALL")
    print(f"\nspeedup GPU/ANE vs CoreML-CPU: {cpu / allu:.2f}x")


if __name__ == "__main__":
    main()
