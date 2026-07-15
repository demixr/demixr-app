# SCNet deployment exploration

This directory contains a reproducible feasibility spike for adding the
official MIT-licensed [SCNet](https://github.com/starrytong/SCNet) model without
vendoring its research code or checkpoint.

## Result

SCNet is now integrated as a production CPU pipeline and an Android Vulkan
pipeline. Spectral preprocessing stays in Dart so both runtimes receive the
same tensors and produce the same stem ordering.

- The 7.8-second ONNX core is 49.8 MiB, 68.5% smaller than Demixr's 158 MiB
  HTDemucs ONNX artifact.
- Across all 50 official MUSDB18-7 test excerpts, SCNet was 25.0% faster on
  ONNX Runtime CPU and improved the average per-stem median SDR by 0.34 dB.
- SCNet improved drums, other, and vocals, but reduced bass SDR by 0.74 dB.
- The learned core is intrinsically GPU-friendly: direct PyTorch MPS inference
  was about 23x faster than PyTorch CPU on the same Mac and tensor.
- Native Core ML has near-exact parity, but its `.mlpackage` still needs an
  app-side native bridge. Apple platforms use the ONNX artifact initially.
- The ExecuTorch Vulkan artifact loads and executes through Flutter on Android;
  physical-device timing remains more representative than emulator timing.

Published artifacts and their stable manifest live in
[`demixr/scnet-executorch`](https://github.com/demixr/scnet-executorch).

## Comparative benchmark

The benchmark uses every 7-second test excerpt in the official MUSDB18-7 STEMS
sample archive: 50 tracks and 340.17 seconds of audio. Both models receive the
same mixtures and references. Quality is the median of one-second, non-silent
chunk SDR values for each track and stem, then the median across tracks. This
is a consistent A/B metric, not the full MUSDB cSDR leaderboard protocol.

| Measurement | HTDemucs | SCNet 7.8 s | SCNet delta |
| --- | ---: | ---: | ---: |
| ONNX artifact | 165.61 MB | 52.18 MB | -68.5% |
| CPU inference, 340.17 s audio | 49.87 s | 37.38 s | -25.0% |
| Drums median SDR | 9.77 dB | 10.03 dB | +0.25 dB |
| Bass median SDR | 9.72 dB | 8.98 dB | -0.74 dB |
| Other median SDR | 5.56 dB | 6.12 dB | +0.57 dB |
| Vocals median SDR | 8.11 dB | 9.40 dB | +1.28 dB |
| Average of stem medians | 8.29 dB | 8.63 dB | +0.34 dB |

ONNX Runtime graph optimization and the CPU arena were enabled for those
timings. With Demixr's memory-conservative settings disabled, a two-track smoke
test still favored the 7.8-second SCNet export (1.90 s versus 3.01 s). Python
`ru_maxrss` was 3.45 GB for SCNet and 3.25 GB for HTDemucs in that smoke test;
these are process-level development proxies, not app memory claims.

Direct PyTorch core timing for one 7.8-second spectral tensor was 2.387 seconds
on CPU and 0.103 seconds on Apple MPS. This ceiling test excludes STFT/iSTFT and
does not represent the Flutter deployment runtime.

## Why a spectral core?

A direct waveform-to-waveform ONNX export passes the ONNX checker, but ONNX
Runtime 1.27 rejects PyTorch's generated integer `ScatterND` nodes. It also
leaves complex `STFT`/`DFT` operations in the graph, preventing useful GPU
delegation.

`export_scnet_core.py` exports only SCNet's learned spectral network:

```text
audio -> STFT + normalization -> SCNet core -> denormalization + iSTFT -> stems
              app/runtime          model          app/runtime
```

SCNet alternates RFFT and IRFFT inside its dual-path network. The exporter
replaces those fixed-size transforms with mathematically equivalent real
matrix operations. Full random-waveform reconstruction differed from the
official PyTorch implementation by at most `2.53e-7` (`1.26e-8` mean).

## Reproduce

Clone the official repository and download the standard checkpoint linked from
its README. Export the 7.8-second ONNX core with:

```sh
python3 tool/scnet/export_scnet_core.py \
  --source /path/to/SCNet \
  --checkpoint /path/to/checkpoint.th \
  --segment-samples 343980 \
  --output /tmp/scnet_core_7_8s.onnx
```

Run the end-to-end audio/quality comparison with:

```sh
python3 tool/scnet/compare_quality.py \
  --dataset /path/to/musdb18-7/test \
  --model scnet \
  --artifact /tmp/scnet_core_7_8s.onnx \
  --segment-samples 343980 \
  --output /tmp/scnet_results.json
```

Export experimental ExecuTorch artifacts with:

```sh
python3 tool/scnet/export_scnet_executorch.py coreml \
  --source /path/to/SCNet --checkpoint /path/to/checkpoint.th \
  --output /tmp/scnet_coreml.pte

python3 tool/scnet/export_scnet_executorch.py vulkan \
  --source /path/to/SCNet --checkpoint /path/to/checkpoint.th \
  --output /tmp/scnet_vulkan.pte
```

The checkpoint and generated model artifacts are deliberately not committed.
