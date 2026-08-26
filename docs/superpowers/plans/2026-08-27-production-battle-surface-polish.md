# Production Battle Surface Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use inline execution with `superpowers:test-driven-development`; steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Issue #30 by making CORE-029 battle hierarchy visually explicit through a reusable Godot theme and semantic frames.

**Architecture:** `production_battle_theme.tres` owns only reusable color, border, spacing, and control states. `battle.tscn` owns semantic presentation containers; `production_battle.gd` only updates labels through its revised node paths. No gameplay system reads presentation state.

**Tech Stack:** Godot 4.7.1, GDScript, `.tres` Theme resource, GUT 9.7.1.

**Spec:** `docs/superpowers/specs/2026-08-27-production-battle-surface-polish-design.md`

## Global Constraints

- Start from `dab7922080c5081c74f7a83e449fd4e99432f144` on `codex/production-ui-polish`.
- Preserve current 60/40 stretch ratios, CORE-029 runtime behavior, StageBackdrop binding, and the PR #19 read-only boundary.
- Do not create or change raster/audio assets, gameplay data, costs, timing, or Human evidence status.

---

### Task 1: Theme-backed semantic battle hierarchy

**Files:**

- Create: `resources/production/production_battle_theme.tres`
- Modify: `scenes/production/battle.tscn`
- Modify: `src/production/ui/production_battle.gd`
- Modify: `tests/production/ui/test_realtime_battle_surface.gd`

**Interfaces:** Existing `ProductionBattle` public methods and the `StageBackdrop` consumer contract remain unchanged. The scene adds `ModeFrame`, `ThreatFrame`, `ResourceFrame`, and `SkillFrame` nodes.

- [x] Write a failing UI contract that asserts a non-null scene theme and every new frame node.
- [x] Run the focused GUT test and verify that contract is RED because the initial scene has no theme/frame hierarchy.
- [x] Add the minimal reusable Theme and wrap ModeBar, ThreatPanel, ResourceBar, and SkillPanel; update `ProductionBattle` paths without changing command/pause/retry behavior.
- [x] Re-run focused GUT to GREEN.
- [x] Run tooling discovery, full GUT, Godot headless import/parse, and Windows launcher static contract with no parse or validation failure.
- [x] Commit the docs, theme, scene, script, and test as `feat: polish production battle surface`.

## Self-review

- Scope coverage: the sole task covers all design criteria.
- Placeholder scan: no deferred implementation instruction is present.
- Type consistency: existing `Label` and `Button` references remain typed at their leaf nodes after frame insertion.
