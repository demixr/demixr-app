#!/usr/bin/env python3
"""Compare Demixr's HTDemucs ONNX model with an exported SCNet core.

The input is the official MUSDB18-7 STEMS sample archive. Each model runs in a
separate invocation so `/usr/bin/time -l` can report meaningful peak RSS.
Results are emitted as JSON for reproducibility.
"""

from __future__ import annotations

import argparse
import json
import math
import resource
import subprocess
import time
from pathlib import Path

import numpy as np
import onnxruntime as ort
import torch
from torch.nn import functional as torch_functional


SAMPLE_RATE = 44_100
STEMS = ("drums", "bass", "other", "vocals")
STREAMS = {"mixture": 0, "drums": 1, "bass": 2, "other": 3, "vocals": 4}
HTDEMUCS_SEGMENT = 343_980


def decode_stream(path: Path, stream: int) -> np.ndarray:
    command = [
        "ffmpeg",
        "-v",
        "error",
        "-i",
        str(path),
        "-map",
        f"0:a:{stream}",
        "-f",
        "f32le",
        "-acodec",
        "pcm_f32le",
        "-ar",
        str(SAMPLE_RATE),
        "-ac",
        "2",
        "-",
    ]
    result = subprocess.run(command, check=True, capture_output=True)
    return np.frombuffer(result.stdout, dtype="<f4").reshape(-1, 2).T.copy()


def center_pad(audio: np.ndarray, length: int) -> tuple[np.ndarray, int]:
    missing = length - audio.shape[-1]
    if missing < 0:
        raise ValueError(f"audio has {audio.shape[-1]} samples, limit is {length}")
    left = missing // 2
    return np.pad(audio, ((0, 0), (left, missing - left))), left


class HTDemucs:
    def __init__(self, path: Path, optimize: bool, arena: bool) -> None:
        options = session_options(optimize, arena)
        self.session = ort.InferenceSession(
            str(path), sess_options=options, providers=["CPUExecutionProvider"]
        )

    def separate(self, mixture: np.ndarray) -> np.ndarray:
        padded, left = center_pad(mixture, HTDEMUCS_SEGMENT)
        output = self.session.run(
            ["stems"], {"mix": padded[None].astype(np.float32)}
        )[0][0]
        return output[..., left : left + mixture.shape[-1]]


class SCNet:
    def __init__(
        self,
        path: Path,
        provider: str,
        optimize: bool,
        arena: bool,
        segment_samples: int,
    ) -> None:
        providers = {
            "cpu": ["CPUExecutionProvider"],
            "coreml": ["CoreMLExecutionProvider", "CPUExecutionProvider"],
        }[provider]
        self.session = ort.InferenceSession(
            str(path), sess_options=session_options(optimize, arena), providers=providers
        )
        self.segment = segment_samples
        self.padded = padded_scnet_length(segment_samples)

    def separate(self, mixture: np.ndarray) -> np.ndarray:
        padded, left = center_pad(mixture, self.segment)
        waveform = torch.from_numpy(padded[None])
        waveform = torch_functional.pad(
            waveform, (0, self.padded - self.segment)
        )
        flattened = waveform.reshape(-1, waveform.shape[-1])
        spectrum = torch.stft(
            flattened,
            n_fft=4096,
            hop_length=1024,
            win_length=4096,
            center=True,
            normalized=True,
            window=torch.ones(4096),
            return_complex=True,
        )
        real_spectrum = torch.view_as_real(spectrum)
        real_spectrum = real_spectrum.permute(0, 3, 1, 2).reshape(
            1, 4, spectrum.shape[-2], spectrum.shape[-1]
        )
        mean = real_spectrum.mean(dim=(1, 2, 3), keepdim=True)
        std = real_spectrum.std(dim=(1, 2, 3), keepdim=True)
        normalized = (real_spectrum - mean) / (1e-5 + std)

        output = self.session.run(
            ["stems_spec"], {"mix_spec": normalized.numpy()}
        )[0]
        stem_spectrum = torch.from_numpy(output) * std[:, None] + mean[:, None]
        stem_spectrum = stem_spectrum.reshape(
            -1, 2, stem_spectrum.shape[-2], stem_spectrum.shape[-1]
        ).permute(0, 2, 3, 1)
        complex_spectrum = torch.view_as_complex(stem_spectrum.contiguous())
        stems = torch.istft(
            complex_spectrum,
            n_fft=4096,
            hop_length=1024,
            win_length=4096,
            center=True,
            normalized=True,
            window=torch.ones(4096),
        ).reshape(1, 4, 2, -1)[0, ..., : self.segment]
        return stems.numpy()[..., left : left + mixture.shape[-1]]


def padded_scnet_length(segment: int) -> int:
    hop = 1024
    padding = hop - segment % hop
    if (segment + padding) // hop % 2 == 0:
        padding += hop
    return segment + padding


def chunk_sdr(reference: np.ndarray, estimate: np.ndarray) -> float:
    chunk = SAMPLE_RATE
    scores: list[float] = []
    total_energy = float(np.mean(reference * reference))
    threshold = max(total_energy * 1e-4, 1e-10)
    for start in range(0, reference.shape[-1], chunk):
        target = reference[..., start : start + chunk]
        predicted = estimate[..., start : start + chunk]
        energy = float(np.mean(target * target))
        if energy < threshold:
            continue
        error = target - predicted
        scores.append(
            10 * math.log10(
                (float(np.sum(target * target)) + 1e-10)
                / (float(np.sum(error * error)) + 1e-10)
            )
        )
    return float(np.median(scores)) if scores else float("nan")


def session_options(optimize: bool, arena: bool) -> ort.SessionOptions:
    options = ort.SessionOptions()
    options.enable_cpu_mem_arena = arena
    options.graph_optimization_level = (
        ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        if optimize
        else ort.GraphOptimizationLevel.ORT_DISABLE_ALL
    )
    return options


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=Path, required=True)
    parser.add_argument("--model", choices=("htdemucs", "scnet"), required=True)
    parser.add_argument("--artifact", type=Path, required=True)
    parser.add_argument("--provider", choices=("cpu", "coreml"), default="cpu")
    parser.add_argument("--optimize", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--arena", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--segment-samples", type=int, default=485_100)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    tracks = sorted(args.dataset.glob("*.stem.mp4"))
    if args.limit is not None:
        tracks = tracks[: args.limit]
    separator = (
        HTDemucs(args.artifact, args.optimize, args.arena)
        if args.model == "htdemucs"
        else SCNet(
            args.artifact,
            args.provider,
            args.optimize,
            args.arena,
            args.segment_samples,
        )
    )

    track_results = []
    started = time.perf_counter()
    for index, track in enumerate(tracks, start=1):
        mixture = decode_stream(track, STREAMS["mixture"])
        references = np.stack(
            [decode_stream(track, STREAMS[stem]) for stem in STEMS]
        )
        inference_started = time.perf_counter()
        estimates = separator.separate(mixture)
        inference_seconds = time.perf_counter() - inference_started
        scores = {
            stem: chunk_sdr(references[row], estimates[row])
            for row, stem in enumerate(STEMS)
        }
        track_results.append(
            {
                "track": track.stem.removesuffix(".stem"),
                "seconds": mixture.shape[-1] / SAMPLE_RATE,
                "inference_seconds": inference_seconds,
                "sdr": scores,
            }
        )
        print(
            f"[{index}/{len(tracks)}] {track.name}: "
            f"{inference_seconds:.2f}s, {np.mean(list(scores.values())):.2f} dB",
            flush=True,
        )

    stem_medians = {
        stem: float(np.nanmedian([item["sdr"][stem] for item in track_results]))
        for stem in STEMS
    }
    result = {
        "model": args.model,
        "provider": args.provider,
        "graph_optimization": args.optimize,
        "cpu_memory_arena": args.arena,
        "segment_samples": args.segment_samples if args.model == "scnet" else HTDEMUCS_SEGMENT,
        "artifact_bytes": args.artifact.stat().st_size,
        "tracks": len(track_results),
        "audio_seconds": sum(item["seconds"] for item in track_results),
        "inference_seconds": sum(
            item["inference_seconds"] for item in track_results
        ),
        "wall_seconds": time.perf_counter() - started,
        "peak_rss_bytes": resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        "median_sdr": stem_medians,
        "average_median_sdr": float(np.mean(list(stem_medians.values()))),
        "track_results": track_results,
    }
    encoded = json.dumps(result, indent=2)
    if args.output:
        args.output.write_text(encoded + "\n", encoding="utf-8")
    print(encoded)


if __name__ == "__main__":
    main()
