"""Decisive spike: convert ONLY htdemucs's conv+transformer core (no STFT) to
CoreML and benchmark GPU/ANE vs CPU.

The core takes the precomputed magnitude spectrogram (real, complex-as-channels)
and the time-domain mix, runs encoders -> cross-transformer -> decoders, and
returns the spec-domain stem output (pre-iSTFT) and the time-domain stems.
STFT/iSTFT and the complex ops stay outside (CPU). If the GPU clearly beats CPU
here, the full split-DSP + native-GPU project is justified; if not, we stop.
"""
import time
import numpy as np
import torch
import torch.nn as nn
from einops import rearrange
from demucs.pretrained import get_model


class Core(nn.Module):
    """htdemucs forward body with STFT/iSTFT removed (operates on mag + mix)."""

    def __init__(self, m):
        super().__init__()
        self.m = m

    def forward(self, mag, mix):
        m = self.m
        x = mag
        B, C, Fq, T = x.shape
        mean = x.mean(dim=(1, 2, 3), keepdim=True)
        std = x.std(dim=(1, 2, 3), keepdim=True)
        x = (x - mean) / (1e-5 + std)

        xt = mix
        meant = xt.mean(dim=(1, 2), keepdim=True)
        stdt = xt.std(dim=(1, 2), keepdim=True)
        xt = (xt - meant) / (1e-5 + stdt)

        saved, saved_t, lengths, lengths_t = [], [], [], []
        for idx, encode in enumerate(m.encoder):
            lengths.append(x.shape[-1])
            inject = None
            if idx < len(m.tencoder):
                lengths_t.append(xt.shape[-1])
                tenc = m.tencoder[idx]
                xt = tenc(xt)
                if not tenc.empty:
                    saved_t.append(xt)
                else:
                    inject = xt
            x = encode(x, inject)
            if idx == 0 and m.freq_emb is not None:
                frs = torch.arange(x.shape[-2], device=x.device)
                emb = m.freq_emb(frs).t()[None, :, :, None].expand_as(x)
                x = x + m.freq_emb_scale * emb
            saved.append(x)

        if m.crosstransformer:
            if m.bottom_channels:
                b, c, f, t = x.shape
                x = rearrange(x, "b c f t-> b c (f t)")
                x = m.channel_upsampler(x)
                x = rearrange(x, "b c (f t)-> b c f t", f=f)
                xt = m.channel_upsampler_t(xt)

            x, xt = m.crosstransformer(x, xt)

            if m.bottom_channels:
                x = rearrange(x, "b c f t-> b c (f t)")
                x = m.channel_downsampler(x)
                x = rearrange(x, "b c (f t)-> b c f t", f=f)
                xt = m.channel_downsampler_t(xt)

        for idx, decode in enumerate(m.decoder):
            skip = saved.pop(-1)
            x, pre = decode(x, skip, lengths.pop(-1))
            offset = m.depth - len(m.tdecoder)
            if idx >= offset:
                tdec = m.tdecoder[idx - offset]
                length_t = lengths_t.pop(-1)
                if tdec.empty:
                    pre = pre[:, :, 0]
                    xt, _ = tdec(pre, None, length_t)
                else:
                    skip = saved_t.pop(-1)
                    xt, _ = tdec(xt, skip, length_t)

        S = len(m.sources)
        x = x.view(B, S, -1, Fq, T)
        x = x * std[:, None] + mean[:, None]
        xt = xt.view(B, S, -1, mix.shape[-1])
        xt = xt * stdt[:, None] + meant[:, None]
        return x, xt


def main():
    print("loading htdemucs...")
    bag = get_model("htdemucs")
    model = bag.models[0]
    model.eval()
    model.use_train_segment = False

    mix = torch.zeros(1, 2, 343980)
    with torch.no_grad():
        z = model._spec(mix)
        mag = model._magnitude(z)
    print(f"core inputs: mag={tuple(mag.shape)}  mix={tuple(mix.shape)}")

    core = Core(model).eval()
    with torch.no_grad():
        traced = torch.jit.trace(core, (mag, mix), check_trace=False)
    print("tracing ok; converting core to CoreML...")

    import coremltools as ct
    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="mag", shape=mag.shape),
                ct.TensorType(name="mix", shape=mix.shape)],
        compute_units=ct.ComputeUnit.ALL,
        minimum_deployment_target=ct.target.iOS16,
        convert_to="mlprogram",
    )
    mlmodel.save("htdemucs_core.mlpackage")
    print("CONVERTED OK -> htdemucs_core.mlpackage")

    def bench(cu_name, n=6):
        cu = getattr(ct.ComputeUnit, cu_name)
        mm = ct.models.MLModel("htdemucs_core.mlpackage", compute_units=cu)
        feed = {"mag": mag.numpy().astype(np.float32),
                "mix": mix.numpy().astype(np.float32)}
        t0 = time.perf_counter(); mm.predict(feed); warm = time.perf_counter() - t0
        ts = []
        for _ in range(n):
            t = time.perf_counter(); mm.predict(feed); ts.append(time.perf_counter() - t)
        print(f"  [{cu_name}] compile+first={warm:.1f}s  steady={np.median(ts):.3f}s/chunk (min {min(ts):.3f})")
        return float(np.median(ts))

    print("benchmark (ONNX full-model CPU baseline ~0.77s/chunk):")
    cpu = bench("CPU_ONLY")
    allu = bench("ALL")
    print(f"\nGPU/ANE vs CoreML-CPU speedup: {cpu / allu:.2f}x")


if __name__ == "__main__":
    main()
