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
from .common import is_dry_run, load_dotenv_if_present


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
    parser.add_argument(
        "--live", action="store_true",
        help=(
            "Force a real API call by clearing DRY_RUN before dispatch. "
            "Required when .env contains DRY_RUN=true (the safe default)."
        ),
    )
    parser.add_argument(
        "--skip-refine", action="store_true",
        help=(
            "Meshy only: stop after the preview stage (geometry only, no "
            "PBR textures — render appears solid white in Godot). Use for "
            "fast geometry iteration; default is preview+refine."
        ),
    )
    args = parser.parse_args(argv)

    if args.dry_run and args.live:
        parser.error("--dry-run and --live are mutually exclusive")

    load_dotenv_if_present()
    if args.dry_run:
        os.environ["DRY_RUN"] = "true"
    if args.live:
        os.environ["DRY_RUN"] = "false"

    mode = "DRY_RUN (no HTTP, no credit consumed)" if is_dry_run() else "LIVE — real API call, will consume Pro-plan credit"
    print(f"[mode: {mode}]")
    print(f"  service={args.service} kind={args.kind} asset_id={args.asset_id}")
    print(f"  prompt={args.prompt!r}")
    if not is_dry_run():
        # Live calls block here for ~1 second so the user sees the banner
        # and can Ctrl-C if it was unintentional. Cheaper than reading a
        # surprise 0.05-USD line item later.
        import time
        time.sleep(1)

    if args.service == "tripo":
        client = TripoClient()
        if args.skip_refine:
            print("[note] --skip-refine ignored for Tripo (text_to_model is single-stage)")
        result = client.generate_text_to_model(
            prompt=args.prompt, kind=args.kind, asset_id=args.asset_id,
        )
    else:
        client = MeshyClient()
        result = client.generate_text_to_model(
            prompt=args.prompt, kind=args.kind, asset_id=args.asset_id,
            skip_refine=args.skip_refine,
        )

    print(
        f"OK service={result.service} job={result.job_id} "
        f"sha256={result.sha256[:12]}… bytes={result.bytes_size}"
    )
    print(f"  -> {result.output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
