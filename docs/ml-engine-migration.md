# ML Engine Migration — Handoff Plan

> **Audience**: the next agent/developer taking over the demixing engine.
> **Status**: IN PROGRESS on branch `ml-engine-onnx` (off `modernization`). The
> cross-platform ONNX engine is built and **validated on macOS**; the old Android
> engine is intentionally still in place. Read this before touching anything.

## Progress (branch `ml-engine-onnx`)

**Done & validated:**
- **Runtime**: `flutter_onnxruntime` ^1.8.0 (ONNX Runtime 1.24.x). Builds on
  **macOS** (full), **Android** (debug APK under AGP 8.13), and **iOS** (pods +
  Xcode compile; device run needs an installed iOS SDK). Adopting it bumped
  deployment targets to **macOS 14.0 / iOS 16.0** + static pod linkage, added an
  Android `proguard-rules.pro`, and fixed a stale `RunnerTests` ref in the iOS
  Podfile. It's another AGP-9 blocker (KGP), same as `audioplayers`.
- **Model**: single **htdemucs** (Demucs v4, 4-stem, opset 17, in-graph
  STFT/iSTFT), pre-exported + parity-verified. Shipping the `fp16weights`
  variant (158 MB). Input `mix [1,2,343980]`, output `stems [1,4,2,343980]` in
  order drums/bass/other/vocals. Hosted on HuggingFace (`StemSplitio/htdemucs-onnx`);
  **re-host on a demixr GitHub release as a follow-up**.
- **Engine** (`lib/helpers/onnx/`): pure-Dart orchestration — FFmpeg decode →
  ONNX inference → triangular-window overlap-add (streaming to disk, ~one-segment
  RAM) → 16-bit/44.1k/stereo WAVs. Numerically matches the `demucs-onnx` Python
  reference: **maxDiff 1 LSB, rms 0.71 LSB** (`integration_test/onnx_demixing_test.dart`).
  Public `DemixingHelper.separate(...)` contract unchanged; progress is now a
  plain `Stream<double>`.
- **Acceleration (measured, not assumed)**: on macOS M-series, CPU = 3.9 s vs
  CoreML = 20 s for a 12 s clip — CoreML's ~16 s transformer graph-compile isn't
  amortized in a one-shot separation. Default EP is **XNNPACK→CPU** everywhere;
  CoreML/NNAPI are opt-in via `providerOverride` (benchmark:
  `integration_test/onnx_benchmark_test.dart`).

**GPU acceleration — investigated and rejected (with data).** We tried hard to
run htdemucs on the on-device GPU/ANE. Every model→GPU path needed major surgery
because htdemucs bakes STFT + dynamic-shape ops into the graph: ONNX Runtime's
CoreML EP fails to compile the full model (`Espresso generic_general_slice`),
and `coremltools` fails on dynamic int-casts. After splitting the STFT out and
reusing demucs-onnx's MHA/pos-embed patches, the conv+transformer **core** did
run on CoreML — and was **2.4× slower than CPU** (0.588s vs 1.441s per 7.8s
chunk on an M-series Mac): CoreML accepted 1209/1426 nodes but fragmented them
into 112 GPU↔CPU partitions, and the workload doesn't favor ANE/GPU at this
size. Conclusion: **multi-threaded CPU (XNNPACK) is the fastest on-device path
for this model**; the GPU makes it worse. (Spike scripts: `tools/onnx_export/
{coreml_spike,coreml_core_spike,onnx_core_spike}.py`.) On-device GPU would only
pay off with a different, GPU-friendly model or a native per-platform engine —
out of scope.

**Remaining before the old engine can be removed (Phase 3):**
- Run the ONNX path on a **real Android device** and an **iOS device** (peak RAM,
  wall-clock, correctness; test the 16 KB-page emulator). Only then delete
  `DemixingPlugin.java`, `WavFile*.java`, `android/app/src/main/cpp/**`, the
  CMake/`externalNativeBuild` block, and `pytorch_android_lite`. **Do not remove
  the working Android native engine based on the macOS validation alone.**
- Seam test on real music; confirm player playback/cancellation with ONNX stems.

---


## TL;DR

The app currently demixes **only on Android**, on **CPU**, via a native
PyTorch-Lite engine running **OpenUnmix** `.ptl` models. The goal of this work
is to replace that with a **cross-platform, accelerator-backed inference
runtime** so demixing also works on **iOS/macOS** and runs on the
**GPU/NPU** — and ideally with **better models (Demucs v4)**.

**Do not delete the working Android engine until the replacement is validated
end-to-end.** The previous attempt did exactly that and left the app unable to
demix at all, pointing at model URLs that 404'd. This branch is the cleanup of
that mess.

## Where things stand today (after PR #54)

- **Engine**: `android/app/src/main/java/com/demixr/demixr_app/DemixingPlugin.java`
  loads an OpenUnmix `.ptl` with `org.pytorch:pytorch_android_lite:1.10.0`,
  resamples via a C++ JNI lib (`android/app/src/main/cpp/` → `libwavResampler.so`),
  and reads/writes WAV via `WavFile.java`. **Android-only. CPU-only.**
- **iOS/macOS**: project scaffolding exists, but **no demixing engine** (there
  never was one).
- **Dart interface** (keep this stable!): `lib/helpers/demixing_helper.dart`
  talks to the native side over the `demixing` MethodChannel + `demixing/progress`
  EventChannel, and returns an `UnmixedSong` with paths to 4 stem WAV files
  (vocals, drums, bass, other). Everything downstream (player, library,
  `stems_player.dart`) depends on **4 stem `.wav` files on disk**.
- **Models**: `lib/constants.dart` → `Models` (`umxhq`, `umxl`), `.ptl`, hosted at
  `github.com/demixr/openunmix-torchscript` releases (these URLs are live).

## Hard-won constraints / gotchas (learned the hard way)

1. **`pytorch_android_lite:1.10.0` is from 2021** — it's the reason for the
   Android 15 "16 KB page size" warning (its `.so` isn't 16 KB-aligned) and it's
   frozen. Replacing it fixes 16 KB compliance for the inference libs.
2. **AGP 9 is currently blocked** by `audioplayers_android` (applies the legacy
   Kotlin Gradle Plugin; conflicts with AGP 9 built-in Kotlin). Any inference
   runtime you add is **also a plugin** that must be AGP-compatible — check this
   before committing to a package. We're pinned at **AGP 8.13 / Gradle 8.14 /
   Kotlin 2.2.20**.
3. **"GPU" is not automatically faster on mobile.** On Apple, CoreML
   auto-routes to ANE/GPU/CPU. On Android, NNAPI is deprecated and GPU delegates
   are spotty for these models — multi-threaded **XNNPACK on CPU often wins**.
   Frame the goal as "use the platform accelerator," not "force the GPU," and
   **benchmark** before claiming a speedup.
4. **Models must actually exist and be validated.** The previous attempt pointed
   `constants.dart` at `demixr/demucs-executorch` release URLs that returned 404.
   Produce a real artifact, verify SDR vs the source model, host it, *then* wire
   it up.
5. **The Flutter bindings for both candidate runtimes are immature** (small,
   experimental). Treat them as a real risk; spike before relying on them.

## Recommended approach

### Phase 0 — Decide the runtime (spike, ~1 day)
Two realistic options:
- **ONNX Runtime** — broadest platform support, CoreML (iOS/macOS) +
  NNAPI/XNNPACK (Android) from one model file. Flutter options:
  `onnxruntime` / `flutter_onnxruntime` (native) or the Rust-based `ort` (least
  proven — we removed it). **Recommended default.**
- **ExecuTorch** — PyTorch's on-device runtime (CoreML/XNNPACK delegates).
  Natural if staying in PyTorch; the `executorch_flutter` binding is immature.

Spike: add the package, confirm it builds on Android (with our AGP 8.13 setup)
**and** iOS/macOS, and run a trivial model. Kill the option that can't build.

### Phase 1 — Get ONE validated model file (do this BEFORE app code)
- Easiest quality win: **htdemucs (Demucs v4) → ONNX**, which became viable in
  early 2026. Alternative: OpenUnmix → ONNX (lower quality, simpler).
- Export, run it offline, and **verify SDR/numerical parity** against the source
  model on a few reference tracks. Host the file (HuggingFace or a real GitHub
  release) and confirm the URL resolves.
- Decide stem count: current app assumes **4 stems** (vocals/drums/bass/other).
  htdemucs is 4-stem; htdemucs_6s adds guitar/piano (would need UI/model changes
  — out of scope for the first pass).

### Phase 2 — Integrate on ONE platform end-to-end
- Implement a new `DemixingHelper` path that loads the `.onnx`/`.pte` via the
  chosen runtime and produces the **same 4 stem WAV outputs** the rest of the app
  expects. Keep `demixing_helper.dart`'s public surface
  (`separate(song, modelPath, modelName) -> UnmixedSong`) **unchanged**.
- Pre/post-processing (resampling, STFT/iSTFT if the model needs it): prefer
  doing it **inside the exported graph** (htdemucs can include its own STFT) or in
  Dart. Avoid resurrecting native C++.
- Validate on **macOS or Android** first. Only then expand to the others.

### Phase 3 — Replace the old engine + clean up
Once the new path is validated on all target platforms:
- Remove `DemixingPlugin.java`, `WavFile.java`, `android/app/src/main/cpp/**`,
  the `externalNativeBuild`/CMake block, and the `pytorch_android_lite` dep.
- Update `lib/constants.dart` `Models` to the new model(s) + **working** URLs.
- Re-check AGP 9: with `pytorch_android_lite` gone and a modern runtime, the only
  AGP-9 blocker left should be `audioplayers` (see constraint #2).

### Phase 4 — Verify
- Add an integration test mirroring `integration_test/youtube_download_test.dart`:
  demix a short fixture and assert 4 non-empty stem `.wav` files are produced.
  (Integration tests run on a device; keep them under `integration_test/`.)
- Benchmark inference time on a real device per platform; record numbers. Test on
  the **16 KB-page emulator** (`sdk gphone16k`).
- Manually confirm the player still plays/toggles the produced stems.

## Files to touch / reference

| File | Role |
|------|------|
| `lib/helpers/demixing_helper.dart` | Public demixing API — **keep stable**, swap the implementation behind it |
| `lib/providers/demixing_provider.dart` | Drives demixing + exposes `progressStream` |
| `lib/constants.dart` (`Models`) | Model names/URLs/`fileExtension` — update to the new model |
| `lib/providers/model_provider.dart` | Model download (dio) — generic by URL, should need no change |
| `android/.../DemixingPlugin.java`, `WavFile*.java`, `android/app/src/main/cpp/**` | Old native engine — **remove in Phase 3** |
| `android/app/build.gradle` | Has `externalNativeBuild` + `pytorch_android_lite` to remove in Phase 3 |
| `lib/services/stems_player.dart`, `lib/screens/player/**` | Consume the 4 stem WAVs — should be unaffected if outputs stay the same |

## Explicitly out of scope for the first pass
- 6-stem models, real-time/streaming separation, on-device model conversion.
- Forcing AGP 9 (blocked by audioplayers; revisit when that plugin updates).
