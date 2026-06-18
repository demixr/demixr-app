"""Does PyTorch on the Mac GPU (MPS/Metal) beat CPU for htdemucs?

Mature Metal backend, unlike ONNX Runtime's CoreML EP. Measures one 7.8s
segment forward, excluding model load, median of N runs.
"""
import statistics
import time
import torch
from demucs.pretrained import get_model


def bench(model, dev, x, n=5):
    m = model.to(dev)
    xin = x.to(dev)
    with torch.no_grad():
        m(xin)  # warmup (lazy kernel compile)
        if dev == "mps":
            torch.mps.synchronize()
        ts = []
        for _ in range(n):
            t = time.perf_counter()
            m(xin)
            if dev == "mps":
                torch.mps.synchronize()
            ts.append(time.perf_counter() - t)
    return statistics.median(ts)


def main():
    model = get_model("htdemucs").models[0].eval()
    model.use_train_segment = False
    x = torch.randn(1, 2, 343980) * 0.1

    cpu = bench(model, "cpu", x)
    print(f"PyTorch CPU : {cpu:.3f} s/chunk")

    if torch.backends.mps.is_available():
        try:
            mps = bench(model, "mps", x)
            print(f"PyTorch MPS : {mps:.3f} s/chunk  -> {cpu / mps:.2f}x vs CPU")
        except Exception as e:
            print(f"PyTorch MPS FAILED: {str(e)[:300]}")
    else:
        print("MPS not available")


if __name__ == "__main__":
    main()
