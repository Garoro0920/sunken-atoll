"""Unit tests for tools/asset_generation/clients/tripo.py."""
from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from tools.asset_generation import common
from tools.asset_generation.clients.tripo import TripoClient, TripoError


def _make_response(payload: dict | None = None, content: bytes = b"") -> MagicMock:
    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.json = MagicMock(return_value=payload or {})
    resp.content = content
    return resp


def test_submit_text_to_model_extracts_task_id() -> None:
    session = MagicMock()
    session.post.return_value = _make_response(
        payload={"code": 0, "data": {"task_id": "abc123"}}
    )
    client = TripoClient(api_key="test_key", session=session)
    task_id = client.submit_text_to_model("a rock")
    assert task_id == "abc123"

    _, kwargs = session.post.call_args
    assert kwargs["headers"]["Authorization"] == "Bearer test_key"
    assert kwargs["json"] == {"type": "text_to_model", "prompt": "a rock"}


def test_submit_passes_extra_kwargs_into_body() -> None:
    session = MagicMock()
    session.post.return_value = _make_response(
        payload={"data": {"task_id": "t"}},
    )
    client = TripoClient(api_key="k", session=session)
    client.submit_text_to_model("p", negative_prompt="blurry", model_version="v2")
    _, kwargs = session.post.call_args
    assert kwargs["json"]["negative_prompt"] == "blurry"
    assert kwargs["json"]["model_version"] == "v2"


def test_submit_raises_when_no_task_id() -> None:
    session = MagicMock()
    session.post.return_value = _make_response(payload={"code": 0, "data": {}})
    client = TripoClient(api_key="k", session=session)
    with pytest.raises(TripoError, match="task_id"):
        client.submit_text_to_model("p")


def test_extract_glb_url_prefers_pbr_model() -> None:
    task = {"output": {"pbr_model": "https://e/p.glb", "model": "https://e/m.glb"}}
    assert TripoClient.extract_glb_url(task) == "https://e/p.glb"


def test_extract_glb_url_falls_back_to_model() -> None:
    task = {"output": {"model": "https://e/m.glb"}}
    assert TripoClient.extract_glb_url(task) == "https://e/m.glb"


def test_extract_glb_url_falls_back_to_base_model() -> None:
    task = {"output": {"base_model": "https://e/b.glb"}}
    assert TripoClient.extract_glb_url(task) == "https://e/b.glb"


def test_extract_glb_url_handles_object_with_url_field() -> None:
    task = {"output": {"pbr_model": {"url": "https://e/x.glb"}}}
    assert TripoClient.extract_glb_url(task) == "https://e/x.glb"


def test_extract_glb_url_raises_when_output_empty() -> None:
    with pytest.raises(TripoError, match="No GLB URL"):
        TripoClient.extract_glb_url({"output": {}})


def test_wait_for_completion_polls_through_intermediate_states() -> None:
    session = MagicMock()
    session.get.side_effect = [
        _make_response(payload={"data": {"status": "queued"}}),
        _make_response(payload={"data": {"status": "running"}}),
        _make_response(payload={
            "data": {"status": "success", "output": {"pbr_model": "u"}},
        }),
    ]
    client = TripoClient(api_key="k", session=session, poll_interval_sec=0)
    task = client.wait_for_completion("tid")
    assert task["status"] == "success"
    assert session.get.call_count == 3


def test_wait_for_completion_raises_on_failure_status() -> None:
    session = MagicMock()
    session.get.return_value = _make_response(payload={
        "data": {"status": "failed", "error_code": 42, "error_msg": "boom"},
    })
    client = TripoClient(api_key="k", session=session, poll_interval_sec=0)
    with pytest.raises(TripoError, match="failed"):
        client.wait_for_completion("tid")


def test_dry_run_writes_minimal_glb_metadata_and_log(tmp_path, monkeypatch) -> None:
    monkeypatch.setattr(common, "ASSETS_RAW_DIR", tmp_path / "raw")
    monkeypatch.setattr(common, "API_CALLS_DIR", tmp_path / "calls")
    monkeypatch.setattr(common, "METADATA_DIR", tmp_path / "meta")
    monkeypatch.setenv("DRY_RUN", "true")

    client = TripoClient(api_key="never_used")
    result = client.generate_text_to_model(
        prompt="a rock", kind="rock", asset_id="rock_001",
    )

    # GLB written and is the deterministic minimal placeholder.
    assert result.output_path.exists()
    data = result.output_path.read_bytes()
    assert data[:4] == b"glTF"
    assert result.bytes_size == len(data)
    assert result.job_id == "DRY_RUN"

    # Metadata + JSONL log present.
    meta_path = tmp_path / "meta" / "rock_001.json"
    assert meta_path.exists()
    assert any((tmp_path / "calls").iterdir())
