#!/usr/bin/env python3
"""Export SCNet directly to Core ML while preserving native LSTM operations.

The ExecuTorch ``torch.export`` path decomposes SCNet's bidirectional LSTMs
into thousands of primitive operations. Core ML can represent bidirectional
LSTMs natively, and Core ML Tools' mature TorchScript frontend preserves them.
This exporter tests that route and validates the resulting model against eager
PyTorch before it is considered for a native Flutter platform bridge.
"""

from __future__ import annotations

import argparse
import time
from collections import Counter
from pathlib import Path

import numpy as np
import torch

from export_scnet_core import SCNetSpectralCore, _load_official_model
from export_scnet_executorch import _time_frames


def _operation_counts(model) -> Counter[str]:
    spec = model.get_spec()
    operations: list[str] = []
    for function in spec.mlProgram.functions.values():
        for block in function.block_specializations.values():
            operations.extend(operation.type for operation in block.operations)
    return Counter(operations)


def _install_scalar_cast_workaround() -> None:
    """Work around Core ML Tools 9 casting a length-one array with `int()`.

    Fixed TorchScript shape arithmetic represents some scalar values as
    one-element numpy arrays. The frontend already permits length-one tensors,
    but its constant-folding branch calls ``int(array)`` rather than
    ``array.item()``. Keep this conversion-only shim local to the exporter.
    """
    from coremltools.converters.mil import Builder as mb
    from coremltools.converters.mil.frontend.torch import ops as torch_ops

    original_cast = torch_ops._cast

    def scalar_safe_cast(context, node, dtype, dtype_name):
        inputs = torch_ops._get_inputs(context, node, expected=1)
        value = inputs[0]
        if value.can_be_folded_to_const():
            array = np.asarray(value.val)
            if array.size == 1:
                result = mb.const(
                    val=dtype(array.reshape(-1)[0].item()), name=node.name
                )
                context.add(result, node.name)
                return
        original_cast(context, node, dtype, dtype_name)

    torch_ops._cast = scalar_safe_cast


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--segment-samples", type=int, default=343_980)
    parser.add_argument("--skip-runtime-check", action="store_true")
    args = parser.parse_args()

    import coremltools as ct

    _install_scalar_cast_workaround()

    frames = _time_frames(args.segment_samples)
    core = SCNetSpectralCore(
        _load_official_model(args.source, args.checkpoint),
        frames,
        fixed_shape=True,
    ).eval()
    torch.manual_seed(17)
    sample = torch.randn(1, 4, 2049, frames) * 0.1

    started = time.perf_counter()
    traced = torch.jit.trace(core, sample, check_trace=False, strict=False)
    print(f"TorchScript trace: {time.perf_counter() - started:.2f}s", flush=True)
    trace_path = Path(f"{args.output}.pt")
    torch.jit.save(traced, trace_path)
    print(f"Saved intermediate trace {trace_path}", flush=True)

    started = time.perf_counter()
    converted = ct.convert(
        traced,
        inputs=[ct.TensorType(name="mix_spec", shape=sample.shape)],
        minimum_deployment_target=ct.target.macOS13,
        convert_to="mlprogram",
        compute_precision=ct.precision.FLOAT16,
        compute_units=ct.ComputeUnit.CPU_AND_GPU,
    )
    print(f"Core ML conversion: {time.perf_counter() - started:.2f}s", flush=True)
    counts = _operation_counts(converted)
    print(f"Core ML operations: {sum(counts.values())} {dict(counts)}", flush=True)
    if counts["lstm"] != 12:
        raise RuntimeError(f"expected 12 native LSTMs, found {counts['lstm']}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    converted.save(str(args.output))
    print(f"Saved {args.output}", flush=True)

    if args.skip_runtime_check:
        return

    with torch.inference_mode():
        reference = core(sample).numpy()
    prediction = None
    for index in range(2):
        started = time.perf_counter()
        result = converted.predict({"mix_spec": sample.numpy()})
        elapsed = time.perf_counter() - started
        prediction = next(iter(result.values()))
        print(f"Core ML inference {index}: {elapsed:.4f}s", flush=True)

    assert prediction is not None
    correlation = float(np.corrcoef(reference.flat, prediction.flat)[0, 1])
    maximum = float(np.max(np.abs(reference - prediction)))
    mean = float(np.mean(np.abs(reference - prediction)))
    print(
        f"Parity: corr={correlation:.8f} max_abs={maximum:.6g} "
        f"mean_abs={mean:.6g}",
        flush=True,
    )
    if correlation < 0.999:
        raise RuntimeError(f"Core ML output correlation is too low: {correlation}")


if __name__ == "__main__":
    main()
