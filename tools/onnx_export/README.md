# htdemucs ONNX model — export & parity workspace

This directory reproduces / validates the htdemucs ONNX model the app ships.
Heavy artifacts (`.venv/`, `*.onnx`, `*.wav`, `*.pcm`, `ref_out/`) are
gitignored — only this README is tracked.

## Setup

```sh
uv venv --python 3.12 .venv
uv pip install --python .venv/bin/python "demucs-onnx[export]"
```

## The shipped model

The app downloads a **pre-exported, parity-verified** single-model htdemucs
ONNX (4-stem, opset 17, in-graph STFT/iSTFT) hosted by `demucs-onnx`:

- fp32: `https://huggingface.co/StemSplitio/htdemucs-onnx/resolve/main/htdemucs.onnx` (302 MB)
- fp16weights (shipped): `.../htdemucs_fp16weights.onnx` (158 MB, ~6e-5 max abs diff vs fp32)

Graph contract (do not change without re-exporting + bumping `DemucsConfig`):
- input  `mix`   `[1, 2, 343980]`  (stereo, 7.8 s @ 44100, fixed)
- output `stems` `[1, 4, 2, 343980]` in order **drums, bass, other, vocals**

> TODO (follow-up): re-host on a demixr-owned GitHub release to avoid depending
> on a third-party HF repo, then update `Models.htdemucs.url` in `lib/constants.dart`.

## Re-export from a PyTorch checkpoint (optional)

```sh
.venv/bin/demucs-onnx export htdemucs htdemucs.onnx   # parity-checks by default
```

## Generate reference stems for the Dart parity test

```sh
# 12 s synthetic stereo fixture
ffmpeg -y -f lavfi -i "sine=frequency=220:duration=12:sample_rate=44100" \
       -f lavfi -i "sine=frequency=880:duration=12:sample_rate=44100" \
       -filter_complex "[0:a][1:a]amerge=inputs=2,pan=stereo|c0=c0|c1=c1[a]" \
       -map "[a]" -acodec pcm_s16le test_clip.wav

.venv/bin/demucs-onnx separate test_clip.wav ref_out --model htdemucs --providers cpu -v
```

Then stage `htdemucs.onnx`, `test_clip.wav`, and `ref_out/` under
`~/Downloads/demixr_test/` and run:

```sh
flutter test integration_test/onnx_demixing_test.dart -d macos    # parity check
flutter test integration_test/onnx_benchmark_test.dart -d macos   # CPU vs CoreML
```
