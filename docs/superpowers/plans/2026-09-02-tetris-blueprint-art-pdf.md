# Tetris Blueprint Art and PDF Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for inline task-by-task execution. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve the approved continuous 50/50 battle loop while adding a versioned, consumer-bound Gatebreaker presentation asset and publishing an exact-source human blueprint PDF.

**Architecture:** The existing `GatebreakerReference` stays the only boss-stage character consumer. A new versioned source asset replaces only its scene binding, while the prior v1 file remains a rollback source. A lightweight presentation method in `ProductionBattle` adds bounded visual life without changing simulation, scheduler, puzzle or resource state. The PDF is a derived, non-canonical read model generated from the current design owners with SHA-256 source provenance.

**Tech Stack:** Godot 4.7.1 + GDScript + Textures/TextureRect; Python `unittest` for contract checks; ReportLab/Poppler for derived PDF creation and visual verification; GitHub PR/CI for exact-head evidence.

**Spec:** `docs/operations/TETRIS_BLUEPRINT_ART_WORK_CONTRACT_2026-09-02.json`, `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md`, `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`, and `docs/design/VISUAL_BIBLE.md`.

## Global Constraints

- Preserve CORE-029 continuous combat, one active LINE-or-CHAIN board, 50/50 puzzle/combat hierarchy, enemy-current ETA/shared action window, and `ATK / DEF / SUP → preview → CONFIRM`.
- No new paid dependency, addon, service, title decision, external asset license, manual Tier grid, dual board, shared player-turn budget, or gameplay/balance change.
- Keep `IMG-P0-003` and `TETRIS-IMG-034` files; create a new versioned PNG and record exact consumer/provenance/rollback facts.
- New production art must have an exact `res://` path, scene/node, geometry, alpha/crop/anchor and import contract before generation.
- The user’s 2026-09-02 standing image approval removes a per-candidate lock request, but does not remove provenance, runtime consumer, scene binding, exact-head render or Human-evidence boundaries.
- The PDF is a `HUMAN_GDD_PDF_DERIVED_VIEW`, never a second gameplay canon. It must show its source SHA, inputs and evidence ceiling.

---

### Task 1: Lock the standing-approval and derived-blueprint contracts

**Files:**
- Create: `docs/operations/TETRIS_BLUEPRINT_ART_WORK_CONTRACT_2026-09-02.json`
- Create: `docs/superpowers/plans/2026-09-02-tetris-blueprint-art-pdf.md`
- Modify: `tests/tooling/test_production_canon_contract.py`
- Modify: `tests/tooling/test_project_master_gdd_contract.py`

**Interfaces:**
- Consumes: the current image policy, canon index, Visual Bible, Master GDD and user standing approval.
- Produces: a validated L2 receipt and tests that require consumer-first generation plus the new standing-approval wording and discoverable blueprint output.

- [ ] **Step 1: Write failing contract tests**

```python
self.assertIn("USER_STANDING_IMAGE_APPROVAL_2026-09-02", image_contract)
self.assertIn("docs/blueprints/TETRIS_HUMAN_GAME_BLUEPRINT.pdf", workspace_index)
```

- [ ] **Step 2: Run the two focused tests and confirm RED**

Run: `python -m unittest tests.tooling.test_production_canon_contract tests.tooling.test_project_master_gdd_contract -v`

Expected: FAIL because neither the standing approval key nor a human blueprint PDF route exists.

- [ ] **Step 3: Update only the active owner texts and index**

Record the approval timing amendment without weakening required consumer, source, hash, geometry, import, rollback and runtime-evidence gates. Mark old manual-tier implementation claims in current presentation documents as historical text and point to the current category-resolved runtime.

- [ ] **Step 4: Re-run focused tests and receipt validation**

Run: `python -m unittest tests.tooling.test_production_canon_contract tests.tooling.test_project_master_gdd_contract -v` and `python C:/Users/user/Documents/GitHub/Base/tools/validate_work_contract_receipt.py --receipt docs/operations/TETRIS_BLUEPRINT_ART_WORK_CONTRACT_2026-09-02.json`

Expected: PASS.

### Task 2: Create and bind the bounded Gatebreaker v2 source asset

**Files:**
- Create: `assets/production/bosses/gatebreaker_combat_cutout_v2.png`
- Modify: `docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json`
- Modify: `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`
- Modify: `scenes/production/battle.tscn`
- Modify: `tests/tooling/test_runtime_character_assets.py`

**Interfaces:**
- Consumes: `TETRIS-VISUAL-041`, the exact `GatebreakerReference` node, and current `TextureRect` crop behavior.
- Produces: `TETRIS-IMG-037`, an RGBA source image bound as the boss-only stage texture, with v1 retained as a rollback source.

- [ ] **Step 1: Write a failing v2 asset-consumer test**

```python
self.assertEqual("TETRIS-IMG-037", current_gatebreaker["asset_id"])
self.assertEqual("assets/production/bosses/gatebreaker_combat_cutout_v2.png", current_gatebreaker["local_path"])
self.assertIn('texture = SubResource("AtlasTexture_gatebreaker_stage_v2")', gatebreaker_node)
```

- [ ] **Step 2: Run the test and confirm RED**

Run: `python -m unittest tests.tooling.test_runtime_character_assets.RuntimeCharacterAssetContractTests -v`

Expected: FAIL because v2 does not yet exist or bind to `GatebreakerReference`.

- [ ] **Step 3: Generate one image for the defined runtime consumer**

Generate a single vertical RGBA candidate: an original asymmetric chained Gatebreaker with a visible violet Rift Core, painterly ink-and-watercolor finish, generous transparent crop margin, no UI/text/extra characters, and a safe chest/ram-arm stage crop. Inspect the image before copying it to the exact `res://` destination.

- [ ] **Step 4: Add source record and scene binding**

Use the real output dimensions and SHA-256. Preserve the v1 record as a retained rollback source, bind v2 through an `AtlasTexture`, and document lossless 2D import, aspect-covered clipping and the no-player-in-enemy-stage rule.

- [ ] **Step 5: Re-run the focused asset test**

Run: `python -m unittest tests.tooling.test_runtime_character_assets.RuntimeCharacterAssetContractTests -v`

Expected: PASS with real file/header/hash/alpha and scene-binding assertions.

### Task 3: Add bounded presentation motion without altering combat simulation

**Files:**
- Modify: `src/production/ui/production_battle.gd`
- Modify: `tests/tooling/test_runtime_combat_vfx_assets.py`

**Interfaces:**
- Consumes: `_stage_vfx_elapsed`, `GatebreakerReference`, pause-aware scene layout and current threat visibility.
- Produces: a small boss-only scale/offset pulse that remains presentational, bounded and independent of scheduler/ETA/resource state.

- [ ] **Step 1: Write a failing presentation-boundary test**

```python
self.assertIn("_refresh_gatebreaker_presence", script)
self.assertIn("_gatebreaker_reference", script)
self.assertNotIn("enemy_eta_seconds =", script)
```

- [ ] **Step 2: Run the focused test and confirm RED**

Run: `python -m unittest tests.tooling.test_runtime_combat_vfx_assets.RuntimeCombatVfxAssetTests -v`

Expected: FAIL because the bounded presentation method is absent.

- [ ] **Step 3: Implement the smallest motion**

Update only the existing boss TextureRect’s visual scale/offset from `_stage_vfx_elapsed`; keep amplitude below 2%, do not mutate simulation, and reset the display transform at terminal or unavailable runtime states.

- [ ] **Step 4: Re-run focused test**

Run: `python -m unittest tests.tooling.test_runtime_combat_vfx_assets.RuntimeCombatVfxAssetTests -v`

Expected: PASS.

### Task 4: Publish the human blueprint PDF from current owners

**Files:**
- Create: `tools/build_human_game_blueprint_pdf.py`
- Create: `docs/blueprints/TETRIS_HUMAN_GAME_BLUEPRINT.pdf`
- Create: `docs/blueprints/TETRIS_HUMAN_GAME_BLUEPRINT.manifest.json`
- Modify: `docs/design/PROJECT_WORKSPACE_INDEX.md`
- Create: `tests/tooling/test_human_blueprint_pdf.py`

**Interfaces:**
- Consumes: the exact worktree SHA, primary combat/skill/chain/onboarding/image owners, Master GDD, surface inventory and asset manifest.
- Produces: a short Korean human-readable PDF that routes every rule to its canonical owner, shows player flow, asset status, current implementation versus evidence ceiling, and a real source-file hash manifest.

- [ ] **Step 1: Write a failing derived-publication test**

```python
self.assertTrue(PDF_PATH.is_file())
self.assertEqual("HUMAN_GDD_PDF_DERIVED_VIEW", manifest["artifact_role"])
self.assertEqual(current_sha, manifest["source_commit"])
```

- [ ] **Step 2: Run the test and confirm RED**

Run: `python -m unittest tests.tooling.test_human_blueprint_pdf -v`

Expected: FAIL because the derived PDF and its manifest do not exist.

- [ ] **Step 3: Create generator, issue PDF and manifest**

Generate a PDF with Korean-capable embedded font, title/authority/evidence headers, game promise, 50/50 surface map, first-session flow, LINE/CHAIN/Skill rules, current asset records, implementation/evidence table, user edit guide, required human validation, rollback and exact input hashes. Do not duplicate the full owners or treat the PDF as a new canon.

- [ ] **Step 4: Render every PDF page and inspect the output**

Run the artifact-operation marker before PDF authoring, render with Poppler, inspect all generated page PNGs, run `pdfinfo`/text extraction, and correct clipping, blank pages or Korean-font failures before writing the manifest.

- [ ] **Step 5: Re-run the publication test and workspace-index check**

Run: `python -m unittest tests.tooling.test_human_blueprint_pdf tests.tooling.test_project_home_ia_contract -v`

Expected: PASS.

### Task 5: Integrate, review, verify and publish

**Files:**
- Modify only files listed above plus exact test/manifest updates required by their consumers.

**Interfaces:**
- Consumes: exact branch head, full tooling suite, Godot import/GUT route, PDF render output and read-only PR state.
- Produces: one reviewable PR with exact-head checks and a post-merge main readback.

- [ ] **Step 1: Run static, JSON, asset, PDF and full tooling checks**

Run: Python tooling discovery, JSON parsing, receipt validator, PDF text/visual check and target file hash checks.

- [ ] **Step 2: Run Godot parse and full GUT through the pinned local validator**

Use a new task-owned temporary validation root. Keep unrelated Godot editors untouched; if the route is unavailable, record `DEFERRED_EXTERNAL_EXECUTOR` rather than claiming runtime PASS.

- [ ] **Step 3: Run five adversarial full-scope reviews**

Attack canon drift, source/scene contradiction, player-flow/readability regression, image/evidence inflation, and exact-head/merge drift. Fix only valid in-scope findings, then re-run affected and full checks.

- [ ] **Step 4: Commit, push, PR, exact-head CI and merge where permitted**

Verify the precise reviewed SHA, required checks and unresolved review state before merge; then read fresh `main`, PDF manifest and runtime asset consumers after merge.
