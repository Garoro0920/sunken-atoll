# Tripo mocks

DRY_RUN mode (`DRY_RUN=true`) uses an inline-generated minimal valid GLB
returned by `tools.asset_generation.common.minimal_glb_bytes()`, written
directly to the destination under `assets/raw/<kind>/<asset_id>.glb`.

This directory currently holds no static fixture files because the
inline placeholder is sufficient for connectivity / metadata-flow tests.
Add a curated GLB here when a more realistic mock is needed (e.g. for
visual regression of a downstream Godot import).

Per `docs/02_services/api_integration_guide.md` §7.
