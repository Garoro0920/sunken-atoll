"""Unit tests for tools/asset_generation/common.py."""
from __future__ import annotations

import struct

from tools.asset_generation.common import (
    is_dry_run,
    minimal_glb_bytes,
    new_request_id,
    project_relative,
    PROJECT_ROOT,
    prompt_excerpt,
    sha256_bytes,
)


def test_minimal_glb_starts_with_magic() -> None:
    data = minimal_glb_bytes()
    assert data[:4] == b"glTF"


def test_minimal_glb_version_is_2() -> None:
    data = minimal_glb_bytes()
    version = struct.unpack("<I", data[4:8])[0]
    assert version == 2


def test_minimal_glb_declared_length_matches_actual() -> None:
    data = minimal_glb_bytes()
    declared = struct.unpack("<I", data[8:12])[0]
    assert declared == len(data)


def test_minimal_glb_has_json_chunk_type() -> None:
    data = minimal_glb_bytes()
    assert data[16:20] == b"JSON"


def test_minimal_glb_is_deterministic() -> None:
    assert minimal_glb_bytes() == minimal_glb_bytes()


def test_minimal_glb_is_96_bytes() -> None:
    # 12 header + 8 chunk header + 76 padded JSON payload (scene+node).
    # The empty-asset variant was 48 bytes but triggered a Godot import
    # warning ("glTF file has no nodes"); the current variant adds a
    # single empty scene+node so Godot imports silently.
    assert len(minimal_glb_bytes()) == 96


def test_minimal_glb_payload_includes_scene_and_node() -> None:
    # Sanity check that the payload actually carries a scene reference,
    # which is what suppresses the Godot import warning.
    data = minimal_glb_bytes()
    assert b'"scenes"' in data
    assert b'"nodes"' in data
    assert b'"scene":0' in data


def test_sha256_returns_64_hex_chars() -> None:
    h = sha256_bytes(b"hello")
    assert len(h) == 64
    assert all(c in "0123456789abcdef" for c in h)


def test_sha256_is_deterministic() -> None:
    assert sha256_bytes(b"x") == sha256_bytes(b"x")


def test_new_request_id_is_hex_and_unique() -> None:
    a, b = new_request_id(), new_request_id()
    assert a != b
    assert len(a) == 32
    assert all(c in "0123456789abcdef" for c in a)


def test_is_dry_run_respects_truthy_envs(monkeypatch) -> None:
    for val in ("true", "TRUE", "1", "yes"):
        monkeypatch.setenv("DRY_RUN", val)
        assert is_dry_run(), f"DRY_RUN={val!r} should be truthy"


def test_is_dry_run_falsy_for_other_values(monkeypatch) -> None:
    for val in ("false", "0", "no", ""):
        monkeypatch.setenv("DRY_RUN", val)
        assert not is_dry_run(), f"DRY_RUN={val!r} should be falsy"


def test_prompt_excerpt_short_unchanged() -> None:
    assert prompt_excerpt("a rock") == "a rock"


def test_prompt_excerpt_long_truncated_with_ellipsis() -> None:
    long = "x" * 500
    out = prompt_excerpt(long)
    assert out.endswith("…")
    assert len(out) < len(long)


def test_project_relative_inside_root_returns_posix() -> None:
    inside = PROJECT_ROOT / "assets" / "raw" / "rock" / "x.glb"
    rel = project_relative(inside)
    assert rel == "assets/raw/rock/x.glb"
