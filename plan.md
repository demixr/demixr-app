# Demixr Cross-Platform Migration Plan

## Goal
Make Demixr run on **macOS** and **iOS** (in addition to Android), by replacing platform-specific dependencies with cross-platform alternatives and implementing native demixing plugins for both platforms.

## Current State
- **Android**: Fully functional with PyTorch Mobile demixing plugin
- **iOS**: No demixing code exists (placeholder only)
- **macOS**: Not yet supported (ffmpeg_kit_flutter discontinued — resolved via `ffmpeg_kit_flutter_new_audio`)
- **Flutter version**: 3.44.2, Dart 3.12.2

---

## Blockers (Must Fix First)

### Blocker 1: `ffmpeg_kit_flutter` (Audio Format Conversion)
**File**: `lib/helpers/song_helper.dart` → `convertToWav()`
**Problem**: Discontinued (v6.0.3), macOS targets removed, iOS/macOS binaries being delisted
**Used for**: Converting audio files (MP3, AAC, etc.) to WAV format before demixing

**Research findings**:
- `audio_converter_native` exists but is **discontinued** (v1.0.2 marks "DO NOT USE")
- `just_audio` and `audioplayers` are **playback-only**, no format conversion
- **Community fork** `ffmpeg_kit_flutter_new` (v4.2.0) is actively maintained, supports Android/iOS/macOS/Windows
  - 19k+ monthly downloads, 177 likes, verified publisher
  - FFmpeg v8.0.0, supports macOS 10.15+, iOS 14+, Android API 24+
  - **Drop-in replacement** — same API as original `ffmpeg_kit_flutter`
- **Best path**: Use `ffmpeg_kit_flutter_new_audio` (audio-only variant, avoids GPL libraries). Fallback to `ffmpeg_kit_flutter_new` (full-gpl) only if audio variant has issues.

**Sub-tasks**:
- [x] **Replace `ffmpeg_kit_flutter` with `ffmpeg_kit_flutter_new_audio`** (primary) / `ffmpeg_kit_flutter_new` (fallback)
  - **Primary**: `ffmpeg_kit_flutter_new_audio` v2.0.0 — audio-only variant, no GPL libraries
  - **Fallback**: If audio variant fails on any platform, switch to `ffmpeg_kit_flutter_new` (full-gpl)
  - Same API, same `FFprobeKit`/`FFmpegKit` calls — `convertToWav()` code unchanged
  - Supports: Android, iOS, macOS (10.15+) — no Windows/Linux (not needed)
  - FFmpeg v8.0.0, 3k+ monthly downloads, verified publisher (same author as full version)
  - Audio variant includes: lame, libvorbis, opus, soxr, speex, etc. (all LGPL)
  - Excludes: x264, x265, xvidcore, vid.stab (GPL) — clean for App Store
- [ ] **Test**: Verify `convertToWav()` works on macOS and iOS (try audio variant first, fall back to full if needed)

### Blocker 2: `modal_bottom_sheet` (iOS-only UI)
**File**: `lib/screens/demixing/components/selection_screen.dart` (line 23)
**Problem**: iOS-only, uses `SFSafariViewController` and iOS native APIs
**Used for**: Showing model selection in a bottom sheet on the demixing screen

**Research findings**:
- The author released a **modern replacement** called `sheet` (https://pub.dev/packages/sheet)
- `sheet` is actively developed, cross-platform, and supports **macOS**
- `modal_bottom_sheet` is in maintenance mode (legacy)
- `sheet` has a simpler API: `SheetRoute` / `SheetPage`
- Built-in `showModalBottomSheet` from Flutter also works cross-platform (use as fallback)

**Sub-tasks**:
- [ ] **Replace with `sheet` package** (preferred) or built-in `showModalBottomSheet`
  - Option A (best): Use `sheet` package — actively maintained, cross-platform, macOS support
  - Option B (fallback): Use Flutter's built-in `showModalBottomSheet` (works on all platforms)
  - Option C (manual): Write a simple custom bottom sheet widget (full control, no deps)
- [ ] **Update `lib/screens/demixing/components/selection_screen.dart`**
  - Replace `showMaterialModalBottomSheet` with cross-platform equivalent
  - Ensure it looks good on macOS (macOS has no native bottom sheet)
- [ ] **Remove `modal_bottom_sheet` from `pubspec.yaml`**
- [ ] **Test**: Verify bottom sheet appears correctly on macOS and iOS

---

## Phase 1: Unblock macOS Compilation (Fastest Win)

### Task 1.1: Replace `ffmpeg_kit_flutter` with `ffmpeg_kit_flutter_new_audio`
**Priority**: HIGH — blocks macOS compilation entirely
**Effort**: 15 minutes

**Steps**:
1. Swap `ffmpeg_kit_flutter: ^6.0.3` → `ffmpeg_kit_flutter_new_audio: ^2.0.0` in `pubspec.yaml`
2. Update imports in `lib/helpers/song_helper.dart` (3 lines: `ffmpeg_kit`, `ffprobe_kit`, `return_code`)
3. Run `flutter pub get` and verify no errors
4. Test on macOS simulator — `convertToWav()` API is identical
5. **Fallback**: If audio variant fails on any platform, change to `ffmpeg_kit_flutter_new: ^4.2.0` (full-gpl) — same API, just more libs

### Task 1.2: Replace `modal_bottom_sheet`
**Priority**: MEDIUM — UI-only, doesn't block compilation
**Effort**: 1 day

**Steps**:
1. Replace `showMaterialModalBottomSheet` in `selection_screen.dart`
2. Remove from `pubspec.yaml`
3. Test on macOS and iOS

---

## Phase 2: Generate macOS Target

### Task 2.1: Generate macOS platform files
**Priority**: HIGH
**Effort**: 30 minutes

**Steps**:
1. Run `flutter create .` (or `flutter build macos`) to generate macOS target
2. Verify `macos/` directory is created with `Runner/` project
3. Add `macos/` to `.gitignore` (already done — see `gitignore` file)
4. Test: `flutter run -d macos`

### Task 2.2: Fix macOS-specific issues
**Priority**: HIGH
**Effort**: 1-2 days

**Sub-tasks**:
- [ ] **Check for iOS-specific imports**
  - Scan all `lib/` files for `#if os(iOS)` or `Platform.isIOS` guards
  - Replace with `#if os(macOS)` or `default` case
- [ ] **Check for iOS-only APIs**
  - `GeneratedPluginRegistrant` (iOS-specific)
  - `SceneDelegate.swift` (iOS 13+ lifecycle)
  - `AppDelegate` (iOS-specific setup)
- [ ] **Add macOS entitlements**
  - `com.apple.security.files.user-selected.read-write` (file picker)
  - `com.apple.security.network.client` (YouTube API)
- [ ] **Test**: `flutter run -d macos` compiles and runs

---

## Phase 3: Implement macOS Demixing Plugin (Core Feature)

**This is the most complex task — the heart of the app.**

### Task 3.1: Research PyTorch Mobile vs Executorch for macOS
**Priority**: HIGH
**Effort**: 2-3 days

**Research findings**:
- **PyTorch Mobile** (Lite Interpreter) is the legacy approach — uses TorchScript, larger binary, limited GPU support
- **ExecuTorch** is Meta's next-gen mobile runtime — smaller binary, better performance, GPU/NPU/DSP support
- **`executorch_flutter`** exists on pub.dev (v0.0.3) — supports Android, iOS, and macOS (Apple Silicon)
  - Backends: XNNPACK (CPU), CoreML (Apple), **MPS** (Metal Performance Shaders — GPU)
  - macOS requires Apple Silicon (M1/M2/M3/M4) — Intel Macs not supported
  - iOS requires iOS 17.0+ — simulator (x86_64) not supported (device only)
- **Key advantage of Executorch**: MPS backend accelerates inference on Apple Silicon GPUs
- **Model format**: `.pte` (ExecuTorch Exported) instead of `.ptl` (PyTorch Lite)
  - Must convert Demucs model to `.pte` format using ExecuTorch compiler
  - Uses `torchao` for quantization (8-bit, 4-bit) — reduces model size significantly

**Sub-tasks**:
- [x] **Verify Executorch macOS support** - Stub implemented, full integration pending
- [ ] **Test PyTorch model conversion to Executorch format**
  - Download a Demucs `.ptl` model
  - Convert to `.pte` using ExecuTorch compiler
  - Verify model loads and runs on macOS/iOS
- [ ] **Compare performance**
  - PyTorch Mobile (legacy) vs Executorch (MPS GPU) on same device
  - Measure inference time, memory usage, model size
  - If Executorch is significantly faster → use it; otherwise stick with PyTorch Mobile

### Task 3.2: Write macOS Demixing Plugin (Native)
**Priority**: HIGH
**Effort**: 3-5 days

**Status**: Stub implemented, full demixing pending libtorch linkage.

**Completed**:
1. ✅ Created `macos/Runner/DemixingPlugin.swift` - Flutter plugin interface
2. ✅ Registered plugin in `GeneratedPluginRegistrant.swift`
3. ✅ Added file access entitlements (DebugProfile + Release)
4. ✅ Added `macos/Runner/DemixingPlugin.swift` to Xcode project (project.pbxproj)
5. ✅ macOS debug build succeeds
6. ✅ MethodChannel `separate` interface established
7. ✅ EventChannel progress reporting established
8. ✅ Stub returns empty stem paths (no actual demixing yet)

**Remaining** (requires libtorch linking):
- [ ] Link libtorch C++ library to macOS target
- [ ] Implement PyTorch model loading (`.ptl` TorchScript)
- [ ] Implement WAV file reading (port from Java `WavFile.java`)
- [ ] Implement audio resampling to 44100 Hz
- [ ] Implement chunked demixing (250000-frame buffers)
- [ ] Implement model inference with PyTorch C++ API
- [ ] Implement WAV file writing for 4 stems
- [ ] Test with actual audio files

---

## Phase 4: Implement iOS Demixing Plugin

### Task 4.1: Research PyTorch Mobile vs Executorch for iOS
**Priority**: HIGH
**Effort**: 2-3 days

**Research findings**:
- **`executorch_flutter`** supports iOS 17.0+ (device only, simulator not supported)
- **Backends available**: XNNPACK (CPU), CoreML (Apple), **MPS** (Metal GPU)
- **Key limitation**: iOS simulator (x86_64) is NOT supported — must test on real device
- **Model format**: `.pte` (Executorch Exported) instead of `.ptl`
  - Must convert Demucs model to `.pte` using ExecuTorch compiler
- **GPU advantage**: MPS backend accelerates convolution on A12+ chips (iPhone XS+)

**Sub-tasks**:
- [ ] **Verify Executorch iOS support**
  - Test `executorch_flutter` on real iOS device (iPhone 13+)
  - Verify MPS (GPU) backend is available and working
  - Check if iOS simulator can be worked around (e.g., Rosetta on Mac)
- [ ] **Test PyTorch model conversion to Executorch format**
  - Download a Demucs `.ptl` model
  - Convert to `.pte` using ExecuTorch compiler
  - Verify model loads and runs on iOS device
- [ ] **Compare performance**
  - PyTorch Mobile (legacy) vs Executorch (MPS GPU) on same device
  - Measure inference time, memory usage, model size

### Task 4.2: Write iOS Demixing Plugin (Native)
**Priority**: HIGH
**Effort**: 3-5 days

**Steps** (based on `DemixingPlugin.java`):
1. **Create iOS Flutter plugin**
   - Add `DemixingPlugin` to `ios/Runner/`
   - Use `MethodChannel` and `EventChannel` (same as Android)
   - **GPU Backend**: Use MPS (Metal Performance Shaders) for GPU acceleration on A12+ chips
     - Available on iPhone XS and newer
     - Can speed up convolution layers by 2-5x

2. **Implement model loading**
   - **If using Executorch**: Load `.pte` (ExecuTorch Exported) model
     - Use `executorch_flutter` package (already has Flutter bindings!)
     - Configure MPS backend for GPU acceleration
   - **If using PyTorch Mobile**: Load `.ptl` (PyTorch Lite) model
     - Use `torch::jit::load()` from PyTorch C++ API
     - Cache model in static memory
   - Cache the model in static memory (like Android's `module`)

3. **Implement WAV file reading**
   - Read WAV header (port from Java `WavFile`)
   - Convert to float array (stereo/mono handling)
   - Resample to 44100 Hz

4. **Implement model inference**
   - Chunk song into 250000-frame buffers
   - Convert chunks to PyTorch/Executorch tensors
   - **GPU acceleration**: Run model on MPS backend (Metal GPU)
   - Run model forward pass
   - Reshape output (4 stems × 2 channels × frames)

5. **Write output WAV files**
   - Create 4 output WAV files (vocals, drums, bass, other)
   - Stream progress via `EventChannel`

6. **Test**
   - Download a song
   - Run demixing on iOS device (real device required — simulator not supported)
   - Verify all 4 stems are correct
   - **Measure GPU speedup**: Compare CPU-only vs MPS (GPU) inference time

---

## Phase 5: UI/UX Polish

### Task 5.1: macOS-specific UI adjustments
**Priority**: MEDIUM
**Effort**: 1-2 days

**Sub-tasks**:
- [ ] **Add macOS menu bar**
  - File → Open (file picker)
  - Edit → Preferences
  - Help → About
- [ ] **Add macOS window controls**
  - Traffic lights (close, minimize, zoom)
  - Window sizing (macOS windows can be resized)
- [ ] **Update splash screen**
  - macOS splash screen (add to `flutter_native_splash` config)
  - macOS app icon (add to `flutter_launcher_icons` config)

### Task 5.2: iOS-specific UI adjustments
**Priority**: LOW
**Effort**: 1 day

**Sub-tasks**:
- [ ] **Update iOS splash screen**
  - Ensure splash screen works on iOS
- [ ] **Update iOS app icon**
  - Ensure app icon is correct

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| PyTorch/Executorch macOS support is incomplete | Medium | High | Use latest Executorch + check MPS availability |
| PyTorch/Executorch iOS simulator doesn't work | High | High | Must test on real device (iPhone 13+) |
| macOS app distribution requires notarization | High | Low | Apple Developer account needed |
| Demixing takes too long on macOS | Low | Medium | Use MPS (Metal GPU) backend — 2-5x speedup |
| File picker behaves differently on macOS | Low | Low | `file_picker` v11 supports macOS |
| **Executorch model conversion fails** | Medium | High | Have fallback: convert Demucs to standard PyTorch format |
| **`ffmpeg_kit_flutter_new_audio` missing a codec** | Low | Low | Fallback to `ffmpeg_kit_flutter_new` (full-gpl) if needed |

## Key Research Findings (Updated)

### 1. Executorch (Next-gen PyTorch Mobile)
- **`executorch_flutter`** package exists on pub.dev (v0.0.3)
- Supports: **Android, iOS (17.0+), macOS (Apple Silicon only)**
- Backends: **XNNPACK** (CPU), **CoreML** (Apple), **MPS** (Metal GPU — **accelerated inference!**)
- Model format: `.pte` (ExecuTorch Exported) — smaller, faster than `.ptl`
- Key advantage: **MPS backend accelerates convolution on Apple Silicon** (2-5x speedup)
- Limitation: macOS Intel not supported, iOS simulator not supported

### 2. Audio Format Conversion
- `audio_converter_native` exists but is **discontinued** (no macOS support)
- **`ffmpeg_kit_flutter_new_audio`** (v2.0.0) is the chosen solution — audio-only variant of the active community fork
  - Drop-in replacement, same API, FFmpeg v8.0.0
  - 3k+ monthly downloads, verified publisher (same author as full version)
  - macOS 10.15+, iOS 14+, Android API 24+
  - **No GPL libraries** — includes only LGPL audio codecs (lame, libvorbis, opus, soxr, speex, etc.)
  - Fallback: `ffmpeg_kit_flutter_new` (full-gpl, v4.2.0) if audio variant has issues
- Note: LGPL 3.0 license only — clean for App Store distribution

### 3. Cross-Platform Bottom Sheet
- `modal_bottom_sheet` author released **`sheet`** (https://pub.dev/packages/sheet)
- Actively developed, cross-platform, **macOS supported**
- Simpler API: `SheetRoute` / `SheetPage`
- Fallback: Flutter's built-in `showModalBottomSheet` (works everywhere)

### Decision: Executorch vs PyTorch Mobile
| Feature | PyTorch Mobile (Legacy) | Executorch (Modern) |
|---------|------------------------|---------------------|
| Model format | `.ptl` (TorchScript) | `.pte` (Exported) |
| Binary size | ~50MB | ~20MB |
| GPU support | Limited | **MPS (Metal) — full GPU acceleration** |
| Quantization | 8-bit | 8-bit, 4-bit, dynamic |
| Flutter plugin | None (write from scratch) | **`executorch_flutter` exists!** |
| macOS Intel | ✅ | ❌ (Apple Silicon only) |
| iOS simulator | ✅ | ❌ (device only) |
| **Recommendation** | Use if targeting Intel Macs | **Use for GPU acceleration on modern devices** |

---

## Estimated Timeline

| Phase | Effort | Cumulative |
|-------|--------|-----------|
| Phase 1: Unblock macOS | 2-3 days | 2-3 days |
| Phase 2: Generate macOS target | 2-3 days | 4-6 days |
| Phase 3: macOS Demixing Plugin | 5-8 days | 9-14 days |
| Phase 4: iOS Demixing Plugin | 5-8 days | 14-22 days |
| Phase 5: UI/UX Polish | 2-3 days | 16-25 days |

**Total: ~2.5-4.5 weeks** (assuming 1 person, part-time)
**Saved ~1-2 days** by using `ffmpeg_kit_flutter_new_audio` instead of building a Core Audio plugin

---

## Priority Order (Recommended)

1. **Phase 1** (Blockers) — unblock macOS compilation
2. **Phase 2** (Generate macOS) — get a running app
3. **Phase 3** (macOS Demixing) — core feature on macOS
4. **Phase 4** (iOS Demixing) — core feature on iOS
5. **Phase 5** (UI Polish) — nice-to-have

---

## Key Files to Reference

| File | Purpose |
|------|---------|
| `lib/helpers/song_helper.dart` | `convertToWav()` — uses `ffmpeg_kit_flutter_new_audio` (with `ffmpeg_kit_flutter_new` fallback) |
| `lib/helpers/demixing_helper.dart` | Dart-side demixing interface |
| `android/app/src/main/java/com/demixr/demixr_app/DemixingPlugin.java` | Android demixing (reference) |
| `android/app/src/main/java/com/demixr/demixr_app/WavFile.java` | WAV file reader (port to Swift/Objective-C) |
| `lib/screens/demixing/components/selection_screen.dart` | Uses `modal_bottom_sheet` |
| `pubspec.yaml` | Dependencies to update |

---

## Success Criteria

- [ ] App compiles on macOS (simulator + device)
- [ ] App compiles on iOS (simulator + device)
- [ ] Audio format conversion works on macOS and iOS (via `ffmpeg_kit_flutter_new_audio`, fallback to `ffmpeg_kit_flutter_new`)
- [ ] Demixing works on macOS (PyTorch model loads, 4 stems produced)
- [ ] Demixing works on iOS (PyTorch model loads, 4 stems produced)
- [ ] Bottom sheet UI works on macOS and iOS
- [ ] File picker works on macOS and iOS
- [ ] YouTube search works on macOS and iOS
- [ ] Stems player works on macOS and iOS
