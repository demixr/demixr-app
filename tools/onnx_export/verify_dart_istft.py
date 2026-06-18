"""Validate the Dart FFT-iSTFT math (istft.dart) against the reference Post.

Re-implements istft.dart in numpy and checks Post(core(mix)) == numpy-istft on
the same pre-mask spec + time. If this matches, the Dart port is correct modulo
a coding bug (caught by the integration test).
"""
import sys
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
from executorch_m2_pipeline import Post

SEG = 343980
N = 4096
HOP = 1024
FR = 2048
OFFSET = HOP // 2 * 3  # 1536
NORM = 1.0 / np.sqrt(N)


def dart_istft(spec, time, sources):
    """numpy mirror of Istft.run. spec [S,2C,FR,T], time [S,2,SEG]."""
    T = spec.shape[-1]
    window = 0.5 - 0.5 * np.cos(2 * np.pi * np.arange(N) / N)

    env = np.zeros(SEG)
    for fv in range(-2, T + 2):
        base = fv * HOP - OFFSET
        lo = max(0, -base)
        hi = min(N, SEG - base)
        if hi > lo:
            env[base + lo:base + hi] += (window**2)[lo:hi]
    env = np.maximum(env, 1e-11)

    out = np.zeros((sources, 2, SEG), dtype=np.float64)
    for s in range(sources):
        for ch in range(2):
            ola = np.zeros(SEG)
            re = spec[s, 2 * ch]       # (FR, T)
            im = spec[s, 2 * ch + 1]
            for frame in range(T):
                X = np.zeros(N // 2 + 1, dtype=np.complex128)
                X[:FR] = re[:, frame] + 1j * im[:, frame]  # bin FR (Nyquist)=0
                xt = np.fft.irfft(X, N) * N  # undo numpy's 1/N -> raw IDFT real
                frame_time = NORM * window * xt
                base = frame * HOP - OFFSET
                lo = max(0, -base)
                hi = min(N, SEG - base)
                if hi > lo:
                    ola[base + lo:base + hi] += frame_time[lo:hi]
            out[s, ch] = time[s, ch] + ola / env
    return out


def main():
    model = get_model("htdemucs").models[0].eval()
    model.use_train_segment = False
    from demucs_onnx.export.patch import patch_htdemucs_for_onnx
    patch_htdemucs_for_onnx(model)
    for m in model.modules():
        if isinstance(m, nn.MultiheadAttention):
            m.forward = types.MethodType(export_safe_mha_forward, m)

    core = CoreWithSTFT(model).eval()
    post = Post(model).eval()
    mix = torch.randn(1, 2, SEG) * 0.1
    with torch.no_grad():
        spec, time = core(mix)          # spec [1,S,2C,FR,T], time [1,S,2,SEG]
        ref = post(spec, time)[0].numpy()  # [S,2,SEG]

    S = spec.shape[1]
    mine = dart_istft(spec[0].numpy(), time[0].numpy(), S)

    corr = np.corrcoef(mine.flatten(), ref.flatten())[0, 1]
    rel = np.linalg.norm(mine - ref) / (np.linalg.norm(ref) + 1e-9)
    maxabs = np.abs(mine - ref).max()
    print(f"dart-istft vs reference Post: corr={corr:.6f} rel={rel:.2e} "
          f"maxabs={maxabs:.2e}")


if __name__ == "__main__":
    main()
