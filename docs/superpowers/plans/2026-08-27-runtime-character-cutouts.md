# Runtime Character Cutouts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare two transparent character cutouts from the approved P0 master sheets, with fixed future Battle scene consumers and verifiable asset metadata.

**Architecture:** The master sheets remain reference-only files under `docs/assets/reference/approved`. Two separately versioned PNGs live in runtime asset folders. A small tooling test reads a machine-readable manifest and inspects PNG alpha/dimensions; the consumer contract records planned scene nodes but does not claim runtime binding.

**Tech Stack:** Godot 4 asset filesystem, PNG, Python `unittest` and Pillow-compatible image inspection.

**Spec:** `docs/superpowers/specs/2026-08-27-runtime-character-cutouts.md`

## Global Constraints

- GitHub Issue #38 defines this bounded asset-preparation scope.
- Preserve the three approved P0 files byte-for-byte; do not mutate Draft PR #19 or #33.
- Use the approved `TETRIS-VISUAL-028` visual direction and do not add new character design.
- Record `RUNTIME_INTEGRATION: NOT_IMPLEMENTED` and `RUNTIME_VERIFICATION: NOT_RUN` until later scene binding/renders.
- Store source files project-locally and update the Notion asset record; do not imply Notion binary upload when only metadata is available.

---

### Task 1: Lock the derived-asset contract with a failing test

**Files:**
- Create: `tests/tooling/test_runtime_character_assets.py`
- Modify: `docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json`
- Modify: `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`

**Interfaces:**
- Consumes: approved source IDs `IMG-P0-002`, `IMG-P0-003`.
- Produces: `TETRIS-IMG-033`, `TETRIS-IMG-034` metadata entries and an executable asset contract.

- [ ] **Step 1: Write the failing test**

```python
for asset_id, expected_path in EXPECTED_ASSETS.items():
    self.assertTrue((REPO_ROOT / expected_path).is_file())
    self.assertIn(asset_id, manifest_by_id)
    self.assertEqual(manifest_by_id[asset_id]["runtime_integration"], "NOT_IMPLEMENTED")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m unittest tests.tooling.test_runtime_character_assets -v`

Expected: FAIL because the derived paths and metadata entries do not exist.

- [ ] **Step 3: Write the precise consumer records**

Add the source relationship, planned scene node, alpha/anchor/import constraints, and non-integrated evidence boundary to the manifest and contract.

- [ ] **Step 4: Run test to verify metadata still requires the assets**

Run: `python -m unittest tests.tooling.test_runtime_character_assets -v`

Expected: FAIL only because the two PNG files do not yet exist.

### Task 2: Produce and inspect each approved-source derivative

**Files:**
- Create: `assets/production/characters/vanguard_combat_cutout_v1.png`
- Create: `assets/production/bosses/gatebreaker_combat_cutout_v1.png`

**Interfaces:**
- Consumes: P0 masters and the Task 1 output contract.
- Produces: transparent PNG candidates consumed by Task 3 validation.

- [ ] **Step 1: Inspect each approved master before deriving it**

Confirm the selected central pose, retained silhouette/equipment, and removal-only boundaries.

- [ ] **Step 2: Derive Vanguard**

Use the P0-002 master as the reference image. Keep only the full-body Vanguard with sword and shield on a transparent background.

- [ ] **Step 3: Inspect Vanguard output**

Verify transparent background, retained silhouette, no sheet text/panels, and safe full-body bounds.

- [ ] **Step 4: Derive Gatebreaker**

Use the P0-003 master as the reference image. Keep only the full-body Gatebreaker with ram-arm and visible Rift Core on a transparent background.

- [ ] **Step 5: Inspect Gatebreaker output**

Verify transparent background, retained silhouette, no sheet text/panels, and safe rift-core/ram-arm bounds.

### Task 3: Validate, record, and hand off

**Files:**
- Modify: `docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json`
- Modify: `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`
- Modify: `tests/tooling/test_runtime_character_assets.py`

**Interfaces:**
- Consumes: Task 1 metadata and Task 2 PNGs.
- Produces: exact checksum/dimension evidence and a future-runtime hookup handoff.

- [ ] **Step 1: Record generated file SHA-256 and actual dimensions**

Set those manifest fields only after inspecting the local versioned files.

- [ ] **Step 2: Run targeted and relevant existing validation**

Run: `python -m unittest tests.tooling.test_runtime_character_assets tests.tooling.test_production_canon_contract -v`

Expected: PASS; it proves source/target facts and does not prove rendered use.

- [ ] **Step 3: Update the existing Notion asset package**

Add IDs, source relation, local target paths, consumer nodes, and `NOT_IMPLEMENTED` runtime boundary.

- [ ] **Step 4: Commit and open a current-task draft PR**

Commit only the two source candidates, their contract records/tests, and this plan/spec. The PR must preserve the exact evidence boundary and remain separate from Draft PR #19/#33.
