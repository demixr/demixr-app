"""Measure peak RSS of htdemucs ONNX inference under different session options,
to find what's ballooning memory on mobile.

Usage: mem_probe.py <model.onnx> <arena 0|1> <ALL|BASIC|DISABLE>
"""
import resource
import sys
import time
import numpy as np
import onnxruntime as ort

path, arena, opt = sys.argv[1], sys.argv[2] == "1", sys.argv[3]
so = ort.SessionOptions()
so.enable_cpu_mem_arena = arena
so.graph_optimization_level = {
    "ALL": ort.GraphOptimizationLevel.ORT_ENABLE_ALL,
    "BASIC": ort.GraphOptimizationLevel.ORT_ENABLE_BASIC,
    "DISABLE": ort.GraphOptimizationLevel.ORT_DISABLE_ALL,
}[opt]
t0 = time.perf_counter()
sess = ort.InferenceSession(path, so, providers=["CPUExecutionProvider"])
x = np.zeros((1, 2, 343980), dtype=np.float32)
sess.run(None, {"mix": x})
dt = time.perf_counter() - t0
# macOS ru_maxrss is bytes; Linux is KB.
peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
peak_mb = peak / 1e6 if sys.platform == "darwin" else peak / 1024
print(f"{path.split('/')[-1]:28s} arena={int(arena)} opt={opt:8s} "
      f"peak_rss={peak_mb:7.0f} MB  time={dt:.1f}s")
