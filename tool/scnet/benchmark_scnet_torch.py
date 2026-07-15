#!/usr/bin/env python3
"""Measure the exported-shape SCNet core directly with PyTorch CPU or MPS.

MPS is not a deployment path for Flutter. It is useful as a ceiling test: if
the same learned graph is not faster on the GPU even before conversion, a more
complex mobile delegate export is unlikely to help.
"""

from __future__ import annotations

import argparse
import time
from pathlib import Path

import torch

from export_scnet_core import SCNetSpectralCore, _load_official_model
from export_scnet_executorch import _time_frames


def _synchronize(device: str) -> None:
    if device == "mps":
        torch.mps.synchronize()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--device", choices=("cpu", "mps"), required=True)
    parser.add_argument("--segment-samples", type=int, default=343_980)
    parser.add_argument("--warmup", type=int, default=1)
    parser.add_argument("--runs", type=int, default=3)
    args = parser.parse_args()

    frames = _time_frames(args.segment_samples)
    core = SCNetSpectralCore(
        _load_official_model(args.source, args.checkpoint), frames
    ).eval().to(args.device)
    sample = torch.zeros(1, 4, 2049, frames, device=args.device)

    elapsed = []
    with torch.inference_mode():
        for index in range(args.warmup + args.runs):
            _synchronize(args.device)
            started = time.perf_counter()
            output = core(sample)
            _synchronize(args.device)
            seconds = time.perf_counter() - started
            if index >= args.warmup:
                elapsed.append(seconds)

    print(f"device={args.device} output={list(output.shape)}")
    print("runs_seconds=" + ",".join(f"{value:.6f}" for value in elapsed))
    print(f"median_seconds={sorted(elapsed)[len(elapsed) // 2]:.6f}")


if __name__ == "__main__":
    main()
