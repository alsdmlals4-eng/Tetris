# LINE Controls, Queue Visibility, and Advanced-Clear Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make CORE-029 LINE controls discoverable and standard-key playable while surfacing the authoritative Hold, Next-five, and advanced-clear state.

**Architecture:** Keep `ProductionBattle` as the named-input bridge and add arrow aliases to its existing InputMap actions. Extend `ProductionLineBoardView` into the self-contained LINE presentation surface: it derives a compact left meta rail from `ProductionLineSession`/`LinePieceCycle`, draws preview tetrominoes from the existing catalog, and formats the already-produced `LineClearResult` without changing rules or rewards.

**Tech Stack:** Godot 4.7.1, GDScript, GUT 9.7.1, project-owned SRS-style tetromino data, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-08-26-line-controls-meta-feedback-design.md`

## Global Constraints

- GitHub Issue: #25; current task branch / Draft PR: #24 only.
- Preserve current letter controls: `A/D/S`, `Z/X`, `C`, `Space`.
- Add no paid dependency, image, audio, balance, combat, CHAIN, or PR #19 change.
- All new GDScript files begin with a Korean first-line role header; this plan creates no new runtime GDScript files.
- Presentation is read-only: `LinePieceCycle` and `LineClearResult` remain the sole Hold/Next/recognition authorities.
- Do not stage, alter, or revert existing Godot-editor local changes outside the task-owned files.

---

## File structure

| File | Responsibility |
| --- | --- |
| `project.godot` | Add directional-key aliases to existing named LINE actions. |
| `src/production/ui/production_line_board_view.gd` | Draw the board-first LINE workspace and expose testable meta/clear-label mapping. |
| `tests/production/ui/test_realtime_battle_surface.gd` | Assert named action availability and exact directional aliases. |
| `tests/production/ui/test_production_line_board_view.gd` | Assert Hold/Next snapshots and advanced-clear label mapping without a runtime scene. |
| `docs/superpowers/specs/2026-08-26-line-controls-meta-feedback-design.md` | Approved scope and acceptance contract. |
| `docs/superpowers/plans/2026-08-26-line-controls-meta-feedback.md` | This execution plan. |

## Task 1: Lock the documentation and input-alias contract

**Files:**
- Modify: `project.godot:56-89`
- Modify: `tests/production/ui/test_realtime_battle_surface.gd:68-80`
- Modify: `docs/superpowers/specs/2026-08-26-line-controls-meta-feedback-design.md`
- Create: `docs/superpowers/plans/2026-08-26-line-controls-meta-feedback.md`

**Interfaces:**
- Consumes: existing named actions `line_left`, `line_right`, `line_soft_drop`, `line_rotate_cw`.
- Produces: each action contains both its existing letter-key event and the directional alias checked by GUT.

- [ ] **Step 1: Write the failing directional-alias assertions**

Add a helper and test to `test_realtime_battle_surface.gd`:

```gdscript
func _has_physical_key(action_name: String, expected_key: Key) -> bool:
    for event in InputMap.action_get_events(action_name):
        if event is InputEventKey and event.physical_keycode == expected_key:
            return true
    return false

func test_line_actions_keep_letter_bindings_and_add_directional_aliases() -> void:
    assert_true(_has_physical_key("line_left", KEY_A))
    assert_true(_has_physical_key("line_left", KEY_LEFT))
    assert_true(_has_physical_key("line_right", KEY_D))
    assert_true(_has_physical_key("line_right", KEY_RIGHT))
    assert_true(_has_physical_key("line_soft_drop", KEY_S))
    assert_true(_has_physical_key("line_soft_drop", KEY_DOWN))
    assert_true(_has_physical_key("line_rotate_cw", KEY_X))
    assert_true(_has_physical_key("line_rotate_cw", KEY_UP))
```

- [ ] **Step 2: Run test to verify RED**

Run:

```powershell
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/ui -ginclude_subdirs -gexit
```

Expected: the four directional alias assertions fail because each action currently has one letter-key event.

- [ ] **Step 3: Add only the four directional aliases**

Append `InputEventKey` events to existing arrays in `project.godot`:

```text
line_left       → physical_keycode 4194319 (Left)
line_right      → physical_keycode 4194321 (Right)
line_soft_drop  → physical_keycode 4194322 (Down)
line_rotate_cw  → physical_keycode 4194320 (Up)
```

Do not create actions or alter `ProductionBattle._handle_line_action`.

- [ ] **Step 4: Run test to verify GREEN**

Run the same GUT command. Expected: all production UI tests pass.

- [ ] **Step 5: Commit only task-owned documentation and input files**

```powershell
git add project.godot tests/production/ui/test_realtime_battle_surface.gd docs/superpowers/specs/2026-08-26-line-controls-meta-feedback-design.md docs/superpowers/plans/2026-08-26-line-controls-meta-feedback.md
git commit -m "feat: add line directional control aliases"
```

## Task 2: Add testable LINE meta-state and clear-label mapping

**Files:**
- Modify: `src/production/ui/production_line_board_view.gd:1-25`
- Create: `tests/production/ui/test_production_line_board_view.gd`

**Interfaces:**
- Consumes: `ProductionLineSession.piece_cycle`, `held_piece_id`, `hold_used_for_active`, `peek_next(5)`, and `last_line_result`.
- Produces: `func get_meta_snapshot() -> Dictionary` with `hold_piece_id`, `hold_available`, `next_preview`, and `last_clear`; `func format_last_clear(result: LineClearResult) -> String`.

- [ ] **Step 1: Write failing mapping tests**

Create `test_production_line_board_view.gd` with a Korean first-line role header, a helper that reads the existing tetromino/reward JSON, creates a `LinePieceCycle`, calls `start()`, and builds a `ProductionLineSession`. Include:

```gdscript
func test_meta_snapshot_uses_exact_hold_and_next_five_from_cycle() -> void:
    var view := ProductionLineBoardView.new()
    var session := _make_line_session(321)
    assert_true(session.try_hold())
    var expected: Array = session.piece_cycle.peek_next(5)
    view.bind_line_session(session)
    var meta := view.get_meta_snapshot()
    assert_eq(meta["hold_piece_id"], session.piece_cycle.held_piece_id)
    assert_false(meta["hold_available"])
    assert_eq(meta["next_preview"], expected)

func test_last_clear_label_reports_existing_advanced_fields_without_reward_change() -> void:
	var view := ProductionLineBoardView.new()
    var result := LineClearResult.new(true, "T", 1, "SINGLE", 10, 100)
    result.spin_kind = "T_SPIN"
    result.combo_index = 2
    result.back_to_back = true
    result.perfect_clear = true
    assert_eq(view.format_last_clear(result), "PERFECT CLEAR · T-SPIN SINGLE · B2B · COMBO ×3")
```

- [ ] **Step 2: Run test to verify RED**

Run the production UI GUT command. Expected: parse/load failure for absent `get_meta_snapshot` and `format_last_clear` APIs.

- [ ] **Step 3: Implement the smallest read-only mapping API**

Add to `ProductionLineBoardView`:

```gdscript
func get_meta_snapshot() -> Dictionary:
    if _session == null or _session.piece_cycle == null:
        return {"hold_piece_id": "", "hold_available": false, "next_preview": [], "last_clear": ""}
    var cycle = _session.piece_cycle
    return {
        "hold_piece_id": cycle.held_piece_id,
        "hold_available": not cycle.hold_used_for_active,
        "next_preview": cycle.peek_next(LinePieceCycle.PREVIEW_MIN).duplicate(),
        "last_clear": format_last_clear(_session.last_line_result),
    }
```

`format_last_clear` returns `""` for null/no qualifying result, then builds `PERFECT CLEAR`, `T-SPIN` or normal clear kind, `B2B`, and `COMBO ×(combo_index + 1)` in documented order.

- [ ] **Step 4: Run test to verify GREEN**

Run the production UI GUT command. Expected: existing and new production UI tests pass.

- [ ] **Step 5: Commit the presentation-state contract**

```powershell
git add src/production/ui/production_line_board_view.gd tests/production/ui/test_production_line_board_view.gd
git commit -m "feat: expose line hold queue and clear state"
```

## Task 3: Render the compact, board-first LINE rail

**Files:**
- Modify: `src/production/ui/production_line_board_view.gd:10-25`
- Modify: `tests/production/ui/test_production_line_board_view.gd`

**Interfaces:**
- Consumes: Task 2 `get_meta_snapshot()` and the session's `TetrominoCatalog`.
- Produces: a left visual rail for guide/HOLD/NEXT/LAST CLEAR while retaining existing board/active-piece rendering on the right.

- [ ] **Step 1: Write failing render-contract assertions**

Add:

```gdscript
func test_meta_snapshot_is_safe_before_session_binding() -> void:
    var view := ProductionLineBoardView.new()
    assert_eq(view.get_meta_snapshot()["next_preview"], [])
    assert_eq(view.get_meta_snapshot()["last_clear"], "")

func test_control_guide_lists_all_supported_line_inputs() -> void:
    assert_eq(ProductionLineBoardView.CONTROL_GUIDE, ["← / A", "→ / D", "↓ / S", "↑ / X", "Z", "C HOLD", "SPACE DROP"])
```

- [ ] **Step 2: Run test to verify RED**

Run the production UI GUT command. Expected: failure because `CONTROL_GUIDE` does not exist.

- [ ] **Step 3: Draw the rail without creating game state**

Implement:

```gdscript
const CONTROL_GUIDE := ["← / A", "→ / D", "↓ / S", "↑ / X", "Z", "C HOLD", "SPACE DROP"]

# Reserve max(128.0, size.x * 0.28) pixels for the rail.
# Render the board in the remaining right rectangle.
# Use cycle.catalog.get_cells(piece_id, 0) for HOLD and NEXT mini tetrominoes.
# Draw HOLD USED muted when hold_available is false.
# Draw LAST CLEAR only when formatted text is non-empty.
```

`bind_line_session` must call `queue_redraw()`. No input handler, randomizer, reward, or session mutation is added to this view.

- [ ] **Step 4: Run UI tests and headless parse/import**

Run:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/ui -ginclude_subdirs -gexit
```

Expected: no parser/import errors and all focused tests pass.

- [ ] **Step 5: Commit the rendered LINE rail**

```powershell
git add src/production/ui/production_line_board_view.gd tests/production/ui/test_production_line_board_view.gd
git commit -m "feat: render line controls and preview rail"
```

## Task 4: Regressions, direct Godot validation, and exact-head review

**Files:**
- Modify only if evidence truth changed: `docs/design/PRODUCTION_CANON_INDEX.json` and Notion Current Handoff.

**Interfaces:**
- Consumes: task-owned commits and user-local Godot target instance `38480`.
- Produces: exact-head automated and direct-runtime evidence, with no claim beyond observed results.

- [ ] **Step 1: Run full local validation**

```powershell
python -m unittest discover -s tests/tooling -p "test_*.py" -v
pwsh ./tools/windows/start_tetris_local_executor.ps1 -StaticSelfTest
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Expected: complete tooling, PowerShell, import/parse, and GUT suites are green.

- [ ] **Step 2: Directly inspect Godot runtime**

Use Hera against instance `38480`. Launch current scene; send named LINE actions for left/right/down/up/hold/hard drop; confirm Hold and Next update; switch to CHAIN and back; inspect a canonical advanced-result label; check diagnostics for new errors.

- [ ] **Step 3: Perform independent quality/spec review**

Review only task-owned diff against Issue #25 and the approved design. Verify no raw-key bypass, duplicated queue/recognition, reward/balance drift, stale LINE rail in CHAIN, PR #19 mutation, or modification of user-local editor files.

- [ ] **Step 4: Push and require exact-head CI**

```powershell
git push origin build/realtime-mode-switch-combat
git rev-parse HEAD
```

Fetch CI runs for the exact SHA and require all repository checks to pass.

- [ ] **Step 5: Update durable handoff truth and report**

Update Notion Current Handoff only with verified exact-head, CI, and runtime facts. Report Issue #25, PR #24 exact head, changed files, tests, direct Godot evidence, remaining Human/balance limitations, and rollback commits.
