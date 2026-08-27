# Approved Combat Composition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the approved battle-screen reference into a real 960×540 CORE-029 Godot surface without changing combat rules.

**Architecture:** `battle.tscn` keeps the existing 60/40 one-workspace layout. The right column gains a source-documented decorative boss AtlasTexture, runtime-backed readouts, and an action matrix that composes existing category and tier APIs rather than adding a second skill system.

**Tech Stack:** Godot 4.7, GDScript, GUT, `.tscn`, `.tres`.

**Spec:** `docs/superpowers/specs/2026-08-27-approved-combat-composition-design.md`

## Global Constraints

- Preserve CORE-029 continuous realtime, token pause, and a single visible puzzle workspace.
- Consume only approved `IMG-P0-003`; no generated image is required for this slice.
- Decorative texture nodes use `MOUSE_FILTER_IGNORE`.
- The live 960×540 screenshot is visual evidence, not human validation.

---

### Task 1: Define the approved boss source consumer

**Files:**
- Modify: `scenes/production/battle.tscn`
- Modify: `tests/production/ui/test_realtime_battle_surface.gd`
- Create: `docs/assets/production/TETRIS-IMG-032-GATEBREAKER-STAGE-CUTOUT.md`

**Interfaces:**
- Consumes: `IMG-P0-003` at `docs/assets/reference/approved/TETRIS-IMG-P0-003-asymmetric-breach-colossus-master.png`.
- Produces: `CombatStage/BossReference : TextureRect`, backed by an `AtlasTexture` crop and safe for non-interactive visual composition.

- [x] **Step 1: Write the failing scene test**

```gdscript
var boss_reference = battle.get_node_or_null("MainRow/CombatColumn/CombatStage/BossReference")
assert_true(boss_reference is TextureRect)
assert_not_null(boss_reference.texture)
assert_eq(boss_reference.mouse_filter, Control.MOUSE_FILTER_IGNORE)
```

- [x] **Step 2: Run the focused test and verify it fails because `BossReference` is absent.**

- [x] **Step 3: Add the minimal AtlasTexture ext-resource/sub-resource and non-interactive `BossReference` layer, then document its exact source, atlas region, consumer path, and verification ceiling.**

- [x] **Step 4: Re-run the focused test and verify it passes.**

### Task 2: Replace the generic skill controls with an actionable 3×6 matrix

**Files:**
- Modify: `scenes/production/battle.tscn`
- Modify: `src/production/ui/production_battle.gd`
- Modify: `tests/production/ui/test_realtime_battle_surface.gd`

**Interfaces:**
- Produces: `select_skill_matrix(lane: String, tier: int) -> Dictionary`.
- Consumes: existing `select_skill_category(category)` and `select_skill_tier(tier)`.

- [x] **Step 1: Write failing tests asserting `SkillMatrix` contains `AttackRow`, `DefenseRow`, and `SupportRow`, each with exactly six buttons, and asserting `select_skill_matrix("ATTACK", 4)` selects the existing lane/tier through a stub runtime.**

```gdscript
assert_true(battle.has_method("select_skill_matrix"))
assert_eq(matrix.get_node("AttackRow").get_child_count(), 6)
```

- [x] **Step 2: Run the focused test and verify it fails for missing matrix/API.**

- [x] **Step 3: Add the row buttons and connect each to `select_skill_matrix`. Implement the method by rejecting non-paused or invalid requests, then calling the existing category and tier selection methods.**

- [x] **Step 4: Re-run the focused test and verify it passes.**

### Task 3: Add runtime-backed boss and threat composition

**Files:**
- Modify: `scenes/production/battle.tscn`
- Modify: `src/production/ui/production_battle.gd`
- Modify: `tests/production/ui/test_realtime_battle_surface.gd`

**Interfaces:**
- Produces: `BossReadout : Label`, `ThreatTimeline : VBoxContainer`, and refreshed texts sourced only from `ProductionCombatRuntime.snapshot()`.

- [x] **Step 1: Write a failing test that injects a snapshot and expects `BossReadout` to contain the enemy HP and `CurrentTelegraph` to retain its ETA.**
- [x] **Step 2: Run the test and verify it fails because the readout is absent.**
- [x] **Step 3: Add the labels and update `_refresh_runtime_labels()` without modifying runtime simulation state.**
- [x] **Step 4: Re-run focused tests and verify they pass.**

### Task 4: Run visual and regression verification

**Files:**
- Modify: `docs/superpowers/plans/2026-08-27-approved-combat-composition.md` (check off evidence)

- [x] **Step 1: Start the Godot editor for this isolated worktree and run the main scene.**
- [x] **Step 2: Capture a 960×540 runtime screenshot and inspect it for readable left puzzle, boss identity, timeline, resources, matrix, and USE control.**
- [x] **Step 3: Run focused UI GUT, the full GUT suite, Godot parse/import, and the applicable repository diff check.**
- [x] **Step 4: Commit only source, test, and documentation changes; exclude Godot-generated import/uid/project files.**

## Self-review

- Spec coverage: Tasks 1–3 map every visual/interaction requirement; Task 4 supplies machine and runtime evidence.
- Placeholder scan: no execution placeholder remains; every task names its files, API, and validation.
- Interface consistency: `select_skill_matrix(lane, tier)` composes the pre-existing category/tier methods and does not alter runtime APIs.
