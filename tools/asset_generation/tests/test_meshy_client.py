"""Unit tests for tools/asset_generation/clients/meshy.py."""
from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from tools.asset_generation import common
from tools.asset_generation.clients.meshy import MeshyClient, MeshyError


def _make_response(payload: dict | None = None, content: bytes = b"") -> MagicMock:
    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.json = MagicMock(return_value=payload or {})
    resp.content = content
    return resp


def test_submit_preview_extracts_result_id() -> None:
    session = MagicMock()
    session.post.return_value = _make_response(payload={"result": "task-uuid"})
    client = MeshyClient(api_key="test_key", session=session)
    task_id = client.submit_text_to_3d_preview("a rock")
    assert task_id == "task-uuid"

    _, kwargs = session.post.call_args
    assert kwargs["headers"]["Authorization"] == "Bearer test_key"
    assert kwargs["json"]["mode"] == "preview"
    assert kwargs["json"]["prompt"] == "a rock"


def test_submit_passes_extra_kwargs_into_body() -> None:
    session = MagicMock()
    session.post.return_value = _make_response(payload={"result": "t"})
    client = MeshyClient(api_key="k", session=session)
    client.submit_text_to_3d_preview(
        "p", target_polycount=10000, should_remesh=True,
    )
    _, kwargs = session.post.call_args
    assert kwargs["json"]["target_polycount"] == 10000
    assert kwargs["json"]["should_remesh"] is True


def test_submit_raises_when_no_result() -> None:
    session = MagicMock()
    session.post.return_value = _make_response(payload={})
    client = MeshyClient(api_key="k", session=session)
    with pytest.raises(MeshyError, match="result"):
        client.submit_text_to_3d_preview("p")


def test_extract_glb_url_returns_glb_field() -> None:
    task = {"model_urls": {"glb": "https://e/x.glb", "fbx": "https://e/x.fbx"}}
    assert MeshyClient.extract_glb_url(task) == "https://e/x.glb"


def test_extract_glb_url_raises_when_glb_missing() -> None:
    with pytest.raises(MeshyError, match="No GLB URL"):
        MeshyClient.extract_glb_url({"model_urls": {"fbx": "https://e/x.fbx"}})


def test_extract_glb_url_raises_when_no_model_urls() -> None:
    with pytest.raises(MeshyError, match="No GLB URL"):
        MeshyClient.extract_glb_url({})


def test_wait_for_completion_polls_through_pending_in_progress() -> None:
    session = MagicMock()
    session.get.side_effect = [
        _make_response(payload={"status": "PENDING"}),
        _make_response(payload={"status": "IN_PROGRESS"}),
        _make_response(payload={
            "status": "SUCCEEDED", "model_urls": {"glb": "u"},
        }),
    ]
    client = MeshyClient(api_key="k", session=session, poll_interval_sec=0)
    task = client.wait_for_completion("tid")
    assert task["status"] == "SUCCEEDED"
    assert session.get.call_count == 3


def test_wait_for_completion_raises_on_failed() -> None:
    session = MagicMock()
    session.get.return_value = _make_response(payload={
        "status": "FAILED", "task_error": {"message": "bad prompt"},
    })
    client = MeshyClient(api_key="k", session=session, poll_interval_sec=0)
    with pytest.raises(MeshyError, match="FAILED"):
        client.wait_for_completion("tid")


def test_wait_for_completion_raises_on_canceled() -> None:
    session = MagicMock()
    session.get.return_value = _make_response(payload={
        "status": "CANCELED", "task_error": {},
    })
    client = MeshyClient(api_key="k", session=session, poll_interval_sec=0)
    with pytest.raises(MeshyError, match="CANCELED"):
        client.wait_for_completion("tid")


def test_submit_refine_uses_preview_task_id_and_enables_pbr() -> None:
    session = MagicMock()
    session.post.return_value = _make_response(payload={"result": "refine-id"})
    client = MeshyClient(api_key="k", session=session)
    refine_id = client.submit_text_to_3d_refine("preview-id-123")
    assert refine_id == "refine-id"

    _, kwargs = session.post.call_args
    body = kwargs["json"]
    assert body["mode"] == "refine"
    assert body["preview_task_id"] == "preview-id-123"
    assert body["enable_pbr"] is True


def test_generate_chains_preview_then_refine(tmp_path, monkeypatch) -> None:
    """Default flow: submit preview, wait, submit refine, wait, download."""
    monkeypatch.setattr(common, "ASSETS_RAW_DIR", tmp_path / "raw")
    monkeypatch.setattr(common, "API_CALLS_DIR", tmp_path / "calls")
    monkeypatch.setattr(common, "METADATA_DIR", tmp_path / "meta")
    monkeypatch.delenv("DRY_RUN", raising=False)

    session = MagicMock()
    # Two POSTs (preview submit, refine submit), then GETs while polling.
    session.post.side_effect = [
        _make_response(payload={"result": "preview-id"}),
        _make_response(payload={"result": "refine-id"}),
    ]
    session.get.side_effect = [
        # preview poll: SUCCEEDED immediately
        _make_response(payload={"status": "SUCCEEDED", "model_urls": {"glb": "p"}}),
        # refine poll: SUCCEEDED immediately
        _make_response(payload={
            "status": "SUCCEEDED", "model_urls": {"glb": "https://e/r.glb"},
        }),
        # download GET
        _make_response(content=b"\x00" * 100),
    ]
    client = MeshyClient(api_key="k", session=session, poll_interval_sec=0)
    result = client.generate_text_to_model(prompt="rock", kind="rock", asset_id="r1")

    # Two POSTs: preview + refine.
    assert session.post.call_count == 2
    # Job id records both stages.
    assert "preview-id" in result.job_id and "refine-id" in result.job_id
    # Downloaded the refine URL (last GET should be download).
    download_url = session.get.call_args_list[-1][0][0]
    assert download_url == "https://e/r.glb"


def test_skip_refine_uses_preview_only(tmp_path, monkeypatch) -> None:
    monkeypatch.setattr(common, "ASSETS_RAW_DIR", tmp_path / "raw")
    monkeypatch.setattr(common, "API_CALLS_DIR", tmp_path / "calls")
    monkeypatch.setattr(common, "METADATA_DIR", tmp_path / "meta")
    monkeypatch.delenv("DRY_RUN", raising=False)

    session = MagicMock()
    session.post.side_effect = [_make_response(payload={"result": "preview-id"})]
    session.get.side_effect = [
        _make_response(payload={"status": "SUCCEEDED", "model_urls": {"glb": "https://e/p.glb"}}),
        _make_response(content=b"\x00" * 50),
    ]
    client = MeshyClient(api_key="k", session=session, poll_interval_sec=0)
    result = client.generate_text_to_model(
        prompt="rock", kind="rock", asset_id="r2", skip_refine=True,
    )
    # Only one POST (preview); no refine.
    assert session.post.call_count == 1
    assert result.job_id == "preview-id"


def test_dry_run_writes_minimal_glb_metadata_and_log(tmp_path, monkeypatch) -> None:
    monkeypatch.setattr(common, "ASSETS_RAW_DIR", tmp_path / "raw")
    monkeypatch.setattr(common, "API_CALLS_DIR", tmp_path / "calls")
    monkeypatch.setattr(common, "METADATA_DIR", tmp_path / "meta")
    monkeypatch.setenv("DRY_RUN", "true")

    client = MeshyClient(api_key="never_used")
    result = client.generate_text_to_model(
        prompt="a rock", kind="rock", asset_id="rock_001",
    )

    assert result.output_path.exists()
    data = result.output_path.read_bytes()
    assert data[:4] == b"glTF"
    assert result.job_id == "DRY_RUN"

    meta_path = tmp_path / "meta" / "rock_001.json"
    assert meta_path.exists()
    assert any((tmp_path / "calls").iterdir())
