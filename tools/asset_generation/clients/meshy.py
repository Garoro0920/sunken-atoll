"""Meshy AI API client.

References:
- Service page: docs/02_services/meshy.md
- Adoption decision: pipeline/decisions/2026-05-05_island_assets_meshy_tripo_adoption.md
- Meshy API ref: https://docs.meshy.ai/  (Text to 3D v2 endpoint)
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

BASE_URL = "https://api.meshy.ai"
TEXT_TO_3D_PATH = "/openapi/v2/text-to-3d"
DEFAULT_TIMEOUT_SEC = 60
DEFAULT_POLL_INTERVAL_SEC = 5
DEFAULT_POLL_MAX_SEC = 600
SUCCESS_STATUSES = frozenset({"SUCCEEDED"})
FAILURE_STATUSES = frozenset({"FAILED", "CANCELED"})
TERMINAL_STATUSES = SUCCESS_STATUSES | FAILURE_STATUSES


class MeshyError(RuntimeError):
    pass


class MeshyClient:
    name = "meshy"

    def __init__(
        self,
        api_key: str | None = None,
        session: requests.Session | None = None,
        poll_interval_sec: float = DEFAULT_POLL_INTERVAL_SEC,
        poll_max_sec: float = DEFAULT_POLL_MAX_SEC,
        request_timeout_sec: float = DEFAULT_TIMEOUT_SEC,
    ) -> None:
        self._api_key = api_key
        self._session = session or requests.Session()
        self.poll_interval_sec = poll_interval_sec
        self.poll_max_sec = poll_max_sec
        self.request_timeout_sec = request_timeout_sec

    def _ensure_key(self) -> str:
        if not self._api_key:
            self._api_key = require_env("MESHY_API_KEY")
        return self._api_key

    def _auth_headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self._ensure_key()}"}

    def submit_text_to_3d_preview(self, prompt: str, **extra: Any) -> str:
        """POST /openapi/v2/text-to-3d (mode=preview). Returns task id from `result`."""
        body = {"mode": "preview", "prompt": prompt, **extra}
        resp = self._session.post(
            f"{BASE_URL}{TEXT_TO_3D_PATH}",
            json=body,
            headers={**self._auth_headers(), "Content-Type": "application/json"},
            timeout=self.request_timeout_sec,
        )
        resp.raise_for_status()
        payload = resp.json()
        task_id = payload.get("result")
        if not task_id:
            raise MeshyError(f"Meshy submit returned no result: {payload!r}")
        return task_id

    def get_task(self, task_id: str) -> dict[str, Any]:
        resp = self._session.get(
            f"{BASE_URL}{TEXT_TO_3D_PATH}/{task_id}",
            headers=self._auth_headers(),
            timeout=self.request_timeout_sec,
        )
        resp.raise_for_status()
        return resp.json()

    def wait_for_completion(self, task_id: str) -> dict[str, Any]:
        deadline = time.monotonic() + self.poll_max_sec
        while time.monotonic() < deadline:
            task = self.get_task(task_id)
            status = task.get("status", "PENDING")
            if status in TERMINAL_STATUSES:
                if status not in SUCCESS_STATUSES:
                    raise MeshyError(
                        f"Meshy task {task_id} ended with status={status}: "
                        f"{task.get('task_error', {})!r}"
                    )
                return task
            time.sleep(self.poll_interval_sec)
        raise MeshyError(f"Meshy task {task_id} did not finish within {self.poll_max_sec}s")

    @staticmethod
    def extract_glb_url(task: dict[str, Any]) -> str:
        urls = task.get("model_urls") or {}
        glb = urls.get("glb")
        if not glb:
            raise MeshyError(f"No GLB URL in Meshy task model_urls: {urls!r}")
        return glb

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
        task_id = self.submit_text_to_3d_preview(prompt, **(extra_submit_kwargs or {}))
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
            "endpoint": TEXT_TO_3D_PATH,
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
                "model": "meshy:text-to-3d:preview",
                "prompt": prompt,
                "seed": None,
                "parameters": {},
                "license": "Meshy Pro plan terms — see docs/02_services/meshy.md §7",
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
