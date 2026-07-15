#!/usr/bin/env python3
"""Export SCNet's spectral core to ExecuTorch CoreML or Vulkan.

This is an exploratory exporter. It records how much of the graph is delegated
so a technically valid artifact is not mistaken for a useful GPU artifact.
"""

from __future__ import annotations

import argparse
import logging
from pathlib import Path

import torch

from export_scnet_core import SCNetSpectralCore, _load_official_model


def _time_frames(segment_samples: int) -> int:
    hop = 1024
    padding = hop - segment_samples % hop
    if (segment_samples + padding) // hop % 2 == 0:
        padding += hop
    return (segment_samples + padding) // hop + 1


def _delegation_counts(edge_program) -> tuple[int, int]:
    graph = edge_program.exported_program().graph_module.graph
    delegates = 0
    cpu_calls = 0
    for node in graph.nodes:
        if node.op != "call_function":
            continue
        if "delegate" in str(node.target):
            delegates += 1
        else:
            cpu_calls += 1
    return delegates, cpu_calls


def _partition(exported_program, backend: str, vulkan_storage: str):
    from executorch.exir import to_edge_transform_and_lower

    if backend == "vulkan":
        from executorch.backends.vulkan.partitioner.vulkan_partitioner import (
            VulkanPartitioner,
        )
        from executorch.backends.vulkan.serialization.vulkan_graph_schema import (
            VkStorageType,
        )

        storage_type = (
            VkStorageType.BUFFER
            if vulkan_storage == "buffer"
            else VkStorageType.TEXTURE_3D
        )
        partitioner = VulkanPartitioner(
            compile_options={
                "storage_type_override": storage_type,
                # Mobile Vulkan commonly limits every 3D-image axis to 2048.
                # SCNet's 2049-bin spectrum must therefore remain a buffer or
                # portable CPU boundary instead of becoming an invalid image.
                "texture_limits": (2048, 2048, 2048),
            }
        )
    else:
        import coremltools as ct
        from executorch.backends.apple.coreml.compiler import CoreMLBackend
        from executorch.backends.apple.coreml.partition import CoreMLPartitioner

        specs = CoreMLBackend.generate_compile_specs(
            compute_precision=ct.precision.FLOAT16,
            minimum_deployment_target=ct.target.iOS16,
        )
        partitioner = CoreMLPartitioner(compile_specs=specs)

    return to_edge_transform_and_lower(exported_program, partitioner=[partitioner])


def main() -> None:
    logging.getLogger().setLevel(logging.WARNING)
    parser = argparse.ArgumentParser()
    parser.add_argument("backend", choices=("coreml", "vulkan"))
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--segment-samples", type=int, default=343_980)
    parser.add_argument(
        "--vulkan-storage",
        choices=("buffer", "texture"),
        default="buffer",
        help="Buffer avoids large 3D texture limits for SCNet spectral tensors.",
    )
    args = parser.parse_args()

    frames = _time_frames(args.segment_samples)
    model = _load_official_model(args.source, args.checkpoint)
    core = SCNetSpectralCore(model, frames).eval()
    sample = torch.zeros(1, 4, 2049, frames)

    print(f"torch.export: input={list(sample.shape)}")
    exported = torch.export.export(core, (sample,))
    print(f"exported graph nodes: {len(list(exported.graph.nodes))}")

    edge = _partition(exported, args.backend, args.vulkan_storage)
    delegated, cpu_calls = _delegation_counts(edge)
    print(f"delegated partitions: {delegated}; remaining CPU calls: {cpu_calls}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(edge.to_executorch().buffer)
    print(f"wrote {args.output} ({args.output.stat().st_size / 1024 / 1024:.1f} MiB)")


if __name__ == "__main__":
    main()
