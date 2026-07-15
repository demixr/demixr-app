#!/usr/bin/env python3
"""Smoke-test an exported SCNet core with selected ONNX providers."""

from __future__ import annotations

import argparse
import time
from pathlib import Path

import numpy as np
import onnxruntime as ort


PROVIDERS = {
    "cpu": "CPUExecutionProvider",
    "coreml": "CoreMLExecutionProvider",
    "directml": "DmlExecutionProvider",
    "nnapi": "NnapiExecutionProvider",
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("model", type=Path)
    parser.add_argument("--provider", choices=PROVIDERS, default="cpu")
    parser.add_argument("--frames", type=int, default=476)
    args = parser.parse_args()

    requested = PROVIDERS[args.provider]
    providers = [requested]
    if requested != PROVIDERS["cpu"]:
        providers.append(PROVIDERS["cpu"])

    sample = np.zeros((1, 4, 2049, args.frames), dtype=np.float32)
    started = time.perf_counter()
    session = ort.InferenceSession(str(args.model), providers=providers)
    session_seconds = time.perf_counter() - started

    started = time.perf_counter()
    output = session.run(["stems_spec"], {"mix_spec": sample})[0]
    inference_seconds = time.perf_counter() - started

    print(f"requested: {requested}")
    print(f"active: {session.get_providers()}")
    print(f"session: {session_seconds:.3f}s")
    print(f"inference: {inference_seconds:.3f}s")
    print(f"output: {list(output.shape)}")


if __name__ == "__main__":
    main()
