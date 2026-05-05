"""CLI entry point: generate one asset via Tripo or Meshy.

Usage:
    python -m tools.asset_generation.generate_asset \
        --service tripo --kind rock \
        --prompt "weathered sea boulder, granite, cracked surface" \
        --asset-id rock_test_001 [--dry-run]

Environment variables:
    TRIPO_API_KEY   — required for --service tripo (real-call mode)
    MESHY_API_KEY   — required for --service meshy (real-call mode)
    DRY_RUN=true    — skip HTTP, write a placeholder minimal GLB

Outputs:
    assets/raw/<kind>/<asset-id>.glb
    pipeline/metadata/<asset-id>.json
    pipeline/api_calls/<YYYY-MM-DD>.jsonl  (one line appended)
"""
from __future__ import annotations

import argparse
import os
import sys

from .clients.meshy import MeshyClient
from .clients.tripo import TripoClient
from .common import load_dotenv_if_present


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Generate one asset via Tripo or Meshy.",
    )
    parser.add_argument("--service", required=True, choices=["tripo", "meshy"])
    parser.add_argument(
        "--kind", required=True,
        help="Asset kind (e.g. rock, prop, character) — folder under assets/raw/",
    )
    parser.add_argument("--prompt", required=True, help="Text prompt for the model.")
    parser.add_argument(
        "--asset-id", required=True,
        help="Stable ID for this asset (used as filename + metadata key).",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Force DRY_RUN=true for this invocation (no HTTP, no credit).",
    )
    args = parser.parse_args(argv)

    load_dotenv_if_present()
    if args.dry_run:
        os.environ["DRY_RUN"] = "true"

    client = TripoClient() if args.service == "tripo" else MeshyClient()
    result = client.generate_text_to_model(
        prompt=args.prompt,
        kind=args.kind,
        asset_id=args.asset_id,
    )

    print(
        f"OK service={result.service} job={result.job_id} "
        f"sha256={result.sha256[:12]}… bytes={result.bytes_size}"
    )
    print(f"  -> {result.output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
