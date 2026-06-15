# Demixr: Demucs Executorch Migration Plan

> **Created**: 2026-06-15
> **Status**: Draft — ready for agent execution
> **Related**: `plan.md` (master cross-platform plan), `openunmix-torchscript/` (legacy)

## Goal

Replace OpenUnmix (`.ptl`) with **Demucs v4 (htdemucs)** exported to **ExecuTorch (`.pte`)** format, enabling:
- **GPU acceleration** via MPS (macOS) / CoreML (iOS)
- **`executorch_flutter`** plugin integration (already in `pubspec.yaml`)
- **Higher quality** separation (Demucs v4 is SOTA, used by Apple Music Logic Pro)

## Current State

| Component | Status | Notes |
|-----------|--------|-------|
| **OpenUnmix** (current) | ✅ Working (`.ptl`) | Baseline quality, no GPU accel, frozen repo (2022) |
| **Demucs v2** (archived) | 📦 Reference | Original Facebook Research code (2019), superseded |
| **Demucs v4 (htdemucs)** | ❌ Not ported | **SOTA** — 84 MB (4-stem), 333 MB (ft), no official mobile port |
| **ExecuTorch** | ✅ Installed | `executorch_flutter: ^0.0.6` in pubspec, SPM Swift API |
| **Model URLs** | ❌ Broken | `github.com/demixr/openunmix-executorch` returns 404 |

## Blockers (Must Fix First)

### Blocker 1: No `.pte` models exist

**Problem**: No pre-converted Demucs `.pte` models exist anywhere (HuggingFace, GitHub, PyPI). The only `.pte` models on HuggingFace are LLMs (Llama, Qwen) and a TTS model (Chatterbox).

**Research findings**:
- Demucs is **PyTorch-native** — no TensorFlow dependency (unlike Spleeter)
- Demucs v4 (htdemucs) is **fully convolutional/transformer-based** — no dynamic frame indexing (unlike OpenUnmix's LSTM)
- **`torch.export`** should work on Demucs because it has no data-dependent control flow
- Meta released Demucs under MIT license — weights are official and free to use

**Solution**: Create a new repo `demixr/demucs-executorch` with an export pipeline that:
1. Downloads latest Demucs v4 (htdemucs) weights from PyPI
2. Exports to `.pte` using `torch.export` → `to_edge` → `to_executorch`
3. Uploads `.pte` files as GitHub releases

### Blocker 2: OpenUnex model is not traceable

**Problem**: OpenUnmix uses **dynamic frame indexing** (`int(cur_frame[-1]) + 1`) that `torch.export` cannot trace. This was the reason our OpenUnmix Executorch export script (on `executorch-export` branch) falls back to `.ptl` only.

**Evidence** (from testing on `executorch-export` branch):
```
GuardOnDataDependentSymNode: Could not extract specialized integer
from data-dependent expression u0 (unhinted: u0).
```

**Solution**: **Switch to Demucs** instead of modifying OpenUnmix. Demucs has no dynamic frame indexing — it processes the full audio at once using fixed-size tensor ops. This is a **much simpler** path than rewriting OpenUnmix's LSTM.

### Blocker 3: Model URL in `constants.dart` points to 404

**File**: `lib/constants.dart` (lines 42-52)
**Problem**: `github.com/demixr/openunmix-executorch/releases/download/v1.2/umxhq.pte` returns 404.

**Solution**: Once we create `demixr/demucs-executorch` and upload `.pte` files, update the URLs in `constants.dart` to point to the new repo's releases.

---

## Phase 1: Create `demixr/demucs-executorch` repo

### Task 1.1: Clone latest Demucs (v4/htdemucs)

**Action**: Clone the Facebook Research Demucs repo (latest version with htdemucs v4):

```bash
git clone https://github.com/facebookresearch/demucs.git
```

**Reference**: 
- `demixr/demucsv2-torchscript` (archived, v2 — for reference only)
- Latest Demucs has `htdemucs` (Hybrid Transformer Demucs) — the current SOTA

### Task 1.2: Create export script

**File**: `demucs_executorch.py` (new)

**Pipeline**:
1. Load Demucs v4 (htdemucs) model from PyPI
2. Create example input tensor (stereo waveform, ~3 seconds)
3. `torch.export.export()` → ExportedProgram
4. `to_edge()` → EdgeProgram (IR)
5. `to_executorch()` → ExecutorchProgram (runtime binary)
6. Write `.pte` file

**Key difference from OpenUnmix script**:
- Demucs is **fully traceable** (no dynamic frame indexing)
- No LSTM-based frame chunking — processes full spectrogram at once
- Should export without modification (unlike OpenUnmix)

### Task 1.3: Set up `uv` package management

**Files**:
- `pyproject.toml` — declarative deps: `torch`, `demucs`, `executorch`
- `uv.lock` — locked reproducible manifest (commit this!)
- `.gitignore` — exclude `.venv/`, `dist/`

**Commands**:
```bash
uv sync                    # install deps
uv run python export.py    # generate .pte models
```

### Task 1.4: Generate and upload `.pte` models

**Models to generate**:
| Model | Size | Description |
|-------|------|-------------|
| `htdemucs.pte` | ~84 MB | Balanced speed/quality (4-stem) |
| `htdemucs_ft.pte` | ~333 MB | Fine-tuned, best quality (4-stem) |
| `htdemucs_6s.pte` | ~84 MB | 6-stem (adds piano, guitar) |

**Upload**: Push `.pte` files to GitHub releases on `demixr/demucs-executorch`.

---

## Phase 2: Update `demixr-app`

### Task 2.1: Update `lib/constants.dart`

**File**: `lib/constants.dart`

**Changes**:
1. Replace OpenUnmix URLs with Demucs URLs:
   ```dart
   // OLD (broken):
   url: 'https://github.com/demixr/openunmix-executorch/releases/download/v1.2/umxhq.pte'
   
   // NEW:
   url: 'https://github.com/demixr/demucs-executorch/releases/download/v1.0/htdemucs.pte'
   ```

2. Update model names: `umxhq` → `htdemucs`, `umxl` → `htdemucs_ft`

3. Update model descriptions to reflect Demucs quality differences

### Task 2.2: Update model download logic

**File**: `lib/providers/model_provider.dart` (or wherever download happens)

**Changes**:
- Verify download URLs resolve correctly
- Test `.pte` file download (84 MB / 333 MB)
- Verify file integrity after download

### Task 2.3: Update native demixing plugins

**Files**:
- `macos/Runner/DemixingPlugin.swift` — update model loading for Demucs architecture
- `ios/Runner/DemixingPlugin.swift` — update model loading for Demucs architecture
- `android/app/src/main/java/com/demixr/demixr_app/DemixingPlugin.java` — update for Demucs

**Key changes**:
- Demucs has **different architecture** than OpenUnmix (U-Net + Transformer vs. LSTM)
- Input tensor shape may differ (Demucs uses waveform, not spectrogram)
- Output tensor shape may differ (4 stems: vocals, drums, bass, other)
- May need to adjust chunking strategy (Demucs processes full audio, not frame-by-frame)

### Task 2.4: Test on devices

**Test matrix**:
| Platform | Device | Expected Result |
|----------|--------|-----------------|
| macOS | Apple Silicon (M1/M2/M3/M4) | Demucs loads, 4 stems output, MPS GPU accel |
| macOS | Intel | Demucs loads, CPU inference (no MPS) |
| iOS | iPhone 13+ (A15+) | Demucs loads, CoreML GPU accel |
| iOS | Simulator (x86_64) | ❌ Not supported (Executorch device-only) |
| Android | Real device | Demucs loads, NNAPI/CPU inference |

---

## Phase 3: Validation & Quality

### Task 3.1: Compare separation quality

**Benchmark**: Run the same test songs through:
1. **OpenUnmix** (current, `.ptl`) — baseline
2. **Demucs v4** (new, `.pte`) — expected improvement

**Metrics** (from [MVSEP leaderboard](https://mvsep.com/quality_checker)):
- **SDR (Signal-to-Distortion Ratio)**: Higher = better
  - Demucs v4 htdemucs: ~12.1 SDR (vocals), ~11.3 SDR (drums)
  - OpenUnmix: ~6.3 SDR (overall)
- **MOS Quality**: Human rating 1-5 (higher = better)
  - Demucs v4: ~3.2 MOS
  - OpenUnmix: ~3.0 MOS

### Task 3.2: Compare inference speed

**Benchmark**: Measure inference time on same audio:
- OpenUnex `.ptl` (CPU, no GPU)
- Demucs `.pte` (MPS/CoreML GPU, if available)

**Expected**: Demucs should be **faster** on GPU despite larger model, due to GPU acceleration.

### Task 3.3: Compare model size

| Model | Format | Size | GPU? | Quality |
|-------|--------|------|------|---------|
| OpenUnmix | `.ptl` | 136 MB (umxhq) | ❌ | Baseline |
| OpenUnmix | `.ptl` | 432 MB (umxl) | ❌ | Good |
| Demucs v4 | `.pte` | **84 MB** (htdemucs) | ✅ | **SOTA** |
| Demucs v4 | `.pte` | **333 MB** (htdemucs_ft) | ✅ | **Best** |

---

## Files to Reference

| File | Purpose |
|------|---------|
| `lib/constants.dart` | Model constants (URLs, names, descriptions) |
| `lib/providers/model_provider.dart` | Model download logic |
| `macos/Runner/DemixingPlugin.swift` | macOS demixing (Executorch MPS backend) |
| `ios/Runner/DemixingPlugin.swift` | iOS demixing (Executorch CoreML backend) |
| `android/app/src/main/java/com/demixr/demixr_app/DemixingPlugin.java` | Android demixing (Executorch NNAPI) |
| `pubspec.yaml` | `executorch_flutter: ^0.0.6` (SPM Swift API) |
| `openunmix-torchscript/openunmix_executorch.py` | Legacy export script (reference) |
| `openunmix-torchscript/NOTES.md` | Why OpenUnmix can't export to `.pte` |

---

## Success Criteria

- [ ] `demixr/demucs-executorch` repo created with export pipeline
- [ ] `htdemucs.pte` (~84 MB) generated and uploaded to GitHub releases
- [ ] `htdemucs_ft.pte` (~333 MB) generated and uploaded to GitHub releases
- [ ] `lib/constants.dart` URLs updated to new repo releases
- [ ] Demucs models download successfully on all platforms
- [ ] Demucs models load and run on macOS (Apple Silicon, MPS GPU)
- [ ] Demucs models load and run on iOS (device, CoreML GPU)
- [ ] Demucs models load and run on Android (NNAPI/CPU)
- [ ] 4 stems output (vocals, drums, bass, other) verified
- [ ] Separation quality exceeds OpenUnmix (SDR > 10 for vocals)
- [ ] Inference speed acceptable on target devices

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Demucs not traceable by `torch.export` | **Medium** | **High** | Test on Apple Silicon; if fails, fallback to `.ptl` |
| Demucs architecture differs from OpenUnmix | **High** | **Medium** | Update native plugins for Demucs input/output shapes |
| `.pte` file too large for App Store | **Low** | Medium | Use `htdemecs` (84 MB) instead of `htdemucs_ft` (333 MB) |
| Executorch version incompatibility | **Medium** | Medium | Pin Executorch version; test with `executorch_flutter` |
| Demucs uses unsupported operators | **Medium** | **High** | Check Executorch operator support; fallback to CPU if needed |

---

## Estimated Timeline

| Phase | Effort | Cumulative |
|-------|--------|------------|
| Phase 1: Create `demucs-executorch` repo | 2-3 days | 2-3 days |
| Phase 2: Update `demixr-app` | 3-5 days | 5-8 days |
| Phase 3: Validation & testing | 2-3 days | 7-11 days |

**Total**: ~7-11 days (assuming 1 person, part-time)

---

## Decision: Demucs vs. OpenUnmix

| Feature | OpenUnmix (current) | Demucs v4 (proposed) |
|---------|---------------------|---------------------|
| Quality | Baseline (SDR ~6.3) | **SOTA** (SDR ~12.1 vocals) |
| Model size | 136/432 MB | **84/333 MB** |
| GPU acceleration | ❌ Limited | ✅ MPS/CoreML |
| Traceable by `torch.export` | ❌ (dynamic LSTM) | ✅ (conv/transformer) |
| Executorch `.pte` export | Hard (needs model mod) | **Easy** (no mod needed) |
| Community support | Frozen (2022) | **Active** (Meta, latest) |
| Used by | — | **Apple Music** (Logic Pro) |
| **Recommendation** | Keep for reference | **Use for production** |

**Verdict**: **Switch to Demucs v4 (htdemucs)**. It's higher quality, smaller, GPU-acceleratable, and critically — **traceable by `torch.export`** without model modification.
