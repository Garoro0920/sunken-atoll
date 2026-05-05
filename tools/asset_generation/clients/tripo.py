"""Tripo3D API client.

References:
- Service page: docs/02_services/tripo.md
- Adoption decision: pipeline/decisions/2026-05-05_island_assets_meshy_tripo_adoption.md
- Common API patterns: docs/02_services/api_integration_guide.md
- Tripo OpenAPI / Python SDK (used to verify exact field names):
    https://github.com/VAST-AI-Research/tripo-python-sdk
"""
from __future__ import annotations

import time
from pathlib import Path
from typing import Any

import requests

from ..common import (
    GenerationResult,
    append_api_call_log,
    asset_output_path,
    is_dry_run,
    minimal_glb_bytes,
    new_request_id,
    project_relative,
    prompt_excerpt,
    require_env,
    sha256_bytes,
    utc_now_iso,
    write_metadata,
)

BASE_URL = "https://api.tripo3d.ai/v2/openapi"
TASK_PATH = "/task"
DEFAULT_TIMEOUT_SEC = 60
DEFAULT_POLL_INTERVAL_SEC = 5
DEFAULT_POLL_MAX_SEC = 600  # 10 minutes
SUCCESS_STATUSES = frozenset({"success"})
FAILURE_STATUSES = frozenset({"failed", "cancelled", "banned", "expired"})
TERMINAL_STATUSES = SUCCESS_STATUSES | FAILURE_STATUSES


class TripoError(RuntimeError):
    pass


class TripoClient:
    name = "tripo"

    def __init__(
        self,
        api_key: str | None = None,
        session: requests.Session | None = None,
        poll_interval_sec: float = DEFAULT_POLL_INTERVAL_SEC,
        poll_max_sec: float = DEFAULT_POLL_MAX_SEC,
        request_timeout_sec: float = DEFAULT_TIMEOUT_SEC,
    ) -> None:
        self._api_key = api_key  # resolved lazily so DRY_RUN doesn't need a key
        self._session = session or requests.Session()
        self.poll_interval_sec = poll_interval_sec
        self.poll_max_sec = poll_max_sec
        self.request_timeout_sec = request_timeout_sec

    def _ensure_key(self) -> str:
        if not self._api_key:
            self._api_key = require_env("TRIPO_API_KEY")
        return self._api_key

    def _auth_headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self._ensure_key()}"}

    def submit_text_to_model(self, prompt: str, **extra: Any) -> str:
        """POST /task with type=text_to_model. Returns Tripo's task_id."""
        body = {"type": "text_to_model", "prompt": prompt, **extra}
        resp = self._session.post(
            f"{BASE_URL}{TASK_PATH}",
            json=body,
            headers={**self._auth_headers(), "Content-Type": "application/json"},
            timeout=self.request_timeout_sec,
        )
        resp.raise_for_status()
        payload = resp.json()
        # Tripo wraps successful responses in {"code": 0, "data": {...}}.
        data = payload.get("data") or payload
        task_id = data.get("task_id")
        if not task_id:
            raise TripoError(f"Tripo submit returned no task_id: {payload!r}")
        return task_id

    def get_task(self, task_id: str) -> dict[str, Any]:
        resp = self._session.get(
            f"{BASE_URL}{TASK_PATH}/{task_id}",
            headers=self._auth_headers(),
            timeout=self.request_timeout_sec,
        )
        resp.raise_for_status()
        payload = resp.json()
        return payload.get("data") or payload

    def wait_for_completion(self, task_id: str) -> dict[str, Any]:
        deadline = time.monotonic() + self.poll_max_sec
        while time.monotonic() < deadline:
            task = self.get_task(task_id)
            status = task.get("status", "unknown")
            if status in TERMINAL_STATUSES:
                if status not in SUCCESS_STATUSES:
                    raise TripoError(
                        f"Tripo task {task_id} ended with status={status} "
                        f"error_code={task.get('error_code')} "
                        f"error_msg={task.get('error_msg')!r}"
                    )
                return task
            time.sleep(self.poll_interval_sec)
        raise TripoError(f"Tripo task {task_id} did not finish within {self.poll_max_sec}s")

    @staticmethod
    def extract_glb_url(task: dict[str, Any]) -> str:
        """Pick the best available GLB URL. Prefers pbr_model > model > base_model.

        Tripo returns either a URL string or an object with a `url` field;
        the SDK's TaskOutput dataclass treats them interchangeably.
        """
        output = task.get("output", {}) or {}
        for key in ("pbr_model", "model", "base_model"):
            value = output.get(key)
            if value is None:
                continue
            if isinstance(value, str):
                return value
            if isinstance(value, dict):
                url = value.get("url")
                if url:
                    return url
        raise TripoError(f"No GLB URL in Tripo task output: {output!r}")

    def download(self, url: str) -> bytes:
        resp = self._session.get(url, timeout=self.request_timeout_sec)
        resp.raise_for_status()
        return resp.content

    def generate_text_to_model(
        self,
        prompt: str,
        kind: str,
        asset_id: str,
        extra_submit_kwargs: dict[str, Any] | None = None,
    ) -> GenerationResult:
        """End-to-end: submit -> poll -> download -> save -> log -> metadata.

        DRY_RUN mode skips all HTTP and writes a minimal GLB placeholder
        so the rest of the pipeline (Godot import, metadata, etc.) can
        be exercised without API calls or Pro-plan credit consumption.
        """
        request_id = new_request_id()
        submitted_at = utc_now_iso()
        out_path = asset_output_path(kind, asset_id)

        if is_dry_run():
            payload = minimal_glb_bytes()
            out_path.write_bytes(payload)
            sha = sha256_bytes(payload)
            self._log(
                "dry_run", request_id, submitted_at, prompt, kind, asset_id,
                status=200, latency_ms=0, job_id="DRY_RUN",
            )
            self._write_metadata(asset_id, kind, prompt, request_id, "DRY_RUN", out_path, sha, len(payload))
            return GenerationResult(
                asset_id=asset_id, service=self.name, output_path=out_path,
                sha256=sha, bytes_size=len(payload), job_id="DRY_RUN",
                request_id=request_id, raw_response={"dry_run": True},
            )

        t0 = time.monotonic()
        task_id = self.submit_text_to_model(prompt, **(extra_submit_kwargs or {}))
        task = self.wait_for_completion(task_id)
        glb_url = self.extract_glb_url(task)
        payload = self.download(glb_url)
        sha = sha256_bytes(payload)
        out_path.write_bytes(payload)
        latency_ms = int((time.monotonic() - t0) * 1000)
        self._log(
            "submit", request_id, submitted_at, prompt, kind, asset_id,
            status=200, latency_ms=latency_ms, job_id=task_id,
        )
        self._write_metadata(asset_id, kind, prompt, request_id, task_id, out_path, sha, len(payload))
        return GenerationResult(
            asset_id=asset_id, service=self.name, output_path=out_path,
            sha256=sha, bytes_size=len(payload), job_id=task_id,
            request_id=request_id, raw_response=task,
        )

    def _log(self, log_kind: str, request_id: str, ts: str, prompt: str,
             asset_kind: str, asset_id: str, **extra: Any) -> None:
        entry = {
            "request_id": request_id,
            "ts": ts,
            "service": self.name,
            "endpoint": TASK_PATH,
            "params_redacted": {
                "prompt_excerpt": prompt_excerpt(prompt),
                "asset_kind": asset_kind,
                "asset_id": asset_id,
            },
            "kind": log_kind,
        }
        entry.update(extra)
        append_api_call_log(entry)

    def _write_metadata(self, asset_id: str, kind: str, prompt: str, request_id: str,
                        job_id: str, out_path: Path, sha: str, size: int) -> None:
        write_metadata(
            asset_id,
            {
                "id": asset_id,
                "kind": kind,
                "service": self.name,
                "model": "tripo:text_to_model",
                "prompt": prompt,
                "seed": None,
                "parameters": {},
                "license": "Tripo Pro plan terms — see docs/02_services/tripo.md §7",
                "attribution": None,
                "generated_at": utc_now_iso(),
                "input_files": [],
                "output_files": [project_relative(out_path)],
                "checksum": {"algorithm": "sha256", "value": sha, "bytes": size},
                "request_id": request_id,
                "job_id": job_id,
                "cost_estimate_usd": None,
            },
        )
