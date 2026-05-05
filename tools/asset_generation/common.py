"""Shared utilities for the asset generation pipeline.

Per docs/02_services/api_integration_guide.md and
docs/03_workflows/asset_generation_workflow.md.
"""
from __future__ import annotations

import hashlib
import json
import os
import struct
import uuid
from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[2]
PIPELINE_DIR = PROJECT_ROOT / "pipeline"
ASSETS_RAW_DIR = PROJECT_ROOT / "assets" / "raw"
API_CALLS_DIR = PIPELINE_DIR / "api_calls"
METADATA_DIR = PIPELINE_DIR / "metadata"
MOCKS_DIR = PIPELINE_DIR / "mocks"

PROMPT_LOG_EXCERPT_LEN = 120


def is_dry_run() -> bool:
    return os.environ.get("DRY_RUN", "").lower() in ("1", "true", "yes")


def require_env(name: str) -> str:
    val = os.environ.get(name, "").strip()
    if not val:
        raise RuntimeError(
            f"Missing required environment variable: {name}. "
            f"See docs/02_services/secrets_management.md."
        )
    return val


def new_request_id() -> str:
    return uuid.uuid4().hex


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def append_api_call_log(entry: dict[str, Any]) -> Path:
    """Append one JSONL line to pipeline/api_calls/<YYYY-MM-DD>.jsonl.

    Per api_integration_guide.md §8. The caller is responsible for
    redacting secrets and trimming long prompts before passing the entry.
    """
    API_CALLS_DIR.mkdir(parents=True, exist_ok=True)
    log_path = API_CALLS_DIR / f"{date.today().isoformat()}.jsonl"
    with log_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    return log_path


def write_metadata(asset_id: str, metadata: dict[str, Any]) -> Path:
    """Write pipeline/metadata/<asset_id>.json per asset_generation_workflow.md §12."""
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    path = METADATA_DIR / f"{asset_id}.json"
    with path.open("w", encoding="utf-8") as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    return path


def asset_output_path(kind: str, asset_id: str, ext: str = "glb") -> Path:
    out_dir = ASSETS_RAW_DIR / kind
    out_dir.mkdir(parents=True, exist_ok=True)
    return out_dir / f"{asset_id}.{ext}"


def project_relative(path: Path) -> str:
    """Posix-style path relative to PROJECT_ROOT (falls back to absolute)."""
    try:
        return path.resolve().relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def load_dotenv_if_present() -> None:
    """Load .env from project root if python-dotenv is installed."""
    try:
        from dotenv import load_dotenv
    except ImportError:
        return
    env_path = PROJECT_ROOT / ".env"
    if env_path.exists():
        load_dotenv(env_path, override=False)


def minimal_glb_bytes() -> bytes:
    """Return a minimum valid GLB (glTF 2.0 binary) with one empty scene+node.

    Used by DRY_RUN mode and tests as a deterministic placeholder that
    downstream tools accept without warnings. The previous version was a
    24-byte JSON body with no nodes; Godot 4.6's glTF importer warns
    "This glTF file has no nodes, the generated Godot scene will be empty"
    on those, which is true but spammy for a placeholder. Including a
    single empty node makes Godot import silently.

    Layout per the glTF 2.0 binary spec:
      - 12-byte header: magic 'glTF', version 2 (uint32 LE), total length (uint32 LE)
      - 8-byte JSON chunk header: chunkLength (uint32 LE), type 'JSON'
      - JSON payload (padded to 4-byte multiple with ASCII spaces)
    """
    json_payload = (
        b'{"asset":{"version":"2.0"},'
        b'"scenes":[{"nodes":[0]}],'
        b'"nodes":[{}],'
        b'"scene":0}'
    )
    pad_count = (4 - len(json_payload) % 4) % 4
    json_padded = json_payload + b" " * pad_count
    file_length = 12 + 8 + len(json_padded)
    header = b"glTF" + struct.pack("<II", 2, file_length)
    chunk_header = struct.pack("<I", len(json_padded)) + b"JSON"
    return header + chunk_header + json_padded


def prompt_excerpt(prompt: str) -> str:
    """Truncate prompt for logging — full prompt lives in metadata only."""
    if len(prompt) <= PROMPT_LOG_EXCERPT_LEN:
        return prompt
    return prompt[:PROMPT_LOG_EXCERPT_LEN] + "…"


@dataclass
class GenerationResult:
    asset_id: str
    service: str
    output_path: Path
    sha256: str
    bytes_size: int
    job_id: str
    request_id: str
    cost_estimate_usd: float | None = None
    raw_response: dict[str, Any] = field(default_factory=dict)
