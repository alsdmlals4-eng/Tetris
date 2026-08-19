# Dual-Board Puzzle Combat POC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal Godot POC where the player manually switches between a Line board and a Chain board, earns Energy from Line clears, earns Chain Stock from completed Chains, and spends both on Attack / Defense / Heal skills while a visible enemy Combat Clock keeps advancing.

**Architecture:** Use Godot/GDScript with domain logic split from scene presentation. `CombatState` owns HP, Energy, Chain Stock and the enemy clock; `ModeController` owns active-board state transitions; Line and Chain boards emit normalized resolution events into separate scoring/resource calculators. UI observes state and sends commands but does not own rules, so puzzle/combat logic can be covered by deterministic GUT tests before scene-level QA.

**Tech Stack:** Godot 4.x + GDScript, GUT for deterministic project tests when adopted, Git for change truth. HiGodot remains the persistent Godot authoring authority and Hera, if adopted later, is QA/observation only.

**Spec:** `docs/design/CORE_GAMEPLAY_GDD.md` and `docs/design/POC_RULESET_V0_1.md`

## Global Constraints

- Line and Chain are separate persistent boards for the whole encounter.
- Only the active visible board may enter `RUNNING`; the inactive board is `SUSPENDED` and never advances.
- Switching modes sets the destination board to `LOCKED`; the player must explicitly choose `RUN`.
- `LOCKED` freezes puzzle simulation and puzzle input only; the Combat Clock continues.
- Mode-switch requests during puzzle `RESOLVING` are queued until a stable board state.
- Line clears generate Energy; completed Chains set non-additive Chain Stock with `max(current, completed_chain)` capped at 5.
- Tier-N Skill requires `Chain Stock >= N` and enough Energy; activation consumes configured Energy and exactly N Chain Stock.
- Core Skill roles are Attack / Defense / Heal and remain class-agnostic.
- Score is separate from Energy and Chain Stock.
- POC benchmark board sizes: Line 10×20; Chain 6×12.
- POC Energy values: Single 10, Double 22, Triple 36, 4-Line 52.
- POC Skill Energy baseline: T1 15, T2 25, T3 40, T4 60, T5 85.
- Emergency Energy recovery is +1/sec only while Energy < 15 and stops at 15.
- No advanced Spin, Back-to-Back, Perfect Clear, All Clear combat bonuses are required for the first runnable slice; event hooks must not block adding them later.
- No final class roster, loot, PvP, final top-out rule, mobile input, monetization, or production art in this plan.
- No new paid service, API, runner, addon, or metered dependency.

---

## File Map

- `project.godot` — minimal Godot project configuration and input actions.
- `src/core/board_state.gd` — shared board-state enum/constants.
- `src/core/combat_state.gd` — HP, enemy HP, Energy, Chain Stock, skill spending, emergency Energy floor, Combat Clock.
- `src/core/mode_controller.gd` — active mode, RUN/LOCK/SUSPEND/RESOLVING transition policy and queued switches.
- `src/line/line_rules.gd` — normalized Line clear event and Energy/Score calculation for Single/Double/Triple/4-Line POC actions.
- `src/line/line_board.gd` — minimal 10×20 falling-block board state sufficient to place pieces and clear rows.
- `src/chain/chain_rules.gd` — completed-chain normalization, Chain Stock contribution and Chain Score event shape.
- `src/chain/chain_board.gd` — minimal 6×12 colored-pair board, connected-group removal and chain resolution.
- `src/skills/skill_definition.gd` — data object for tier, role, Energy cost and effect magnitude.
- `src/skills/skill_executor.gd` — validates and applies Attack / Defense / Heal actions against `CombatState`.
- `src/enemies/enemy_pattern.gd` — one deterministic timed enemy pattern for the POC.
- `src/ui/poc_battle.gd` — presentation/controller bridge for tabs, RUN/LOCK, resources, countdown and three Skill buttons.
- `scenes/poc_battle.tscn` — one-screen POC scene with active-board container and inactive-board summary.
- `tests/unit/test_combat_state.gd` — resource, Stock, skill-cost and clock tests.
- `tests/unit/test_mode_controller.gd` — board-state transition and queued-switch tests.
- `tests/unit/test_line_rules.gd` — Line Energy/Score mapping tests.
- `tests/unit/test_chain_rules.gd` — Chain Stock non-additive/cap tests.
- `tests/unit/test_skill_executor.gd` — Attack/Defense/Heal validation and spending tests.
- `tests/integration/test_dual_board_flow.gd` — Line→Chain→Skill→enemy-action end-to-end domain flow.
- `tests/integration/test_board_freeze.gd` — inactive/locked boards do not advance while Combat Clock does.

---

### Task 1: Bootstrap the Godot project and deterministic test harness

**Files:**
- Create: `project.godot`
- Create: `src/core/board_state.gd`
- Create: `tests/unit/test_project_bootstrap.gd`

**Interfaces:**
- Produces: `BoardState` constants `RUNNING`, `LOCKED`, `SUSPENDED`, `RESOLVING`; project input actions `mode_line`, `mode_chain`, `toggle_run_lock`, `skill_attack`, `skill_defense`, `skill_heal`.

- [ ] **Step 1: Write the failing bootstrap test**

```gdscript
extends GutTest

func test_board_state_constants_exist() -> void:
    var board_state := load("res://src/core/board_state.gd")
    assert_not_null(board_state)
    assert_eq(board_state.RUNNING, 0)
    assert_eq(board_state.LOCKED, 1)
    assert_eq(board_state.SUSPENDED, 2)
    assert_eq(board_state.RESOLVING, 3)
```

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_project_bootstrap.gd
```

Expected: FAIL because `src/core/board_state.gd` does not exist.

- [ ] **Step 3: Add the minimal project and board-state definition**

```gdscript
# src/core/board_state.gd
class_name BoardState
extends RefCounted

const RUNNING := 0
const LOCKED := 1
const SUSPENDED := 2
const RESOLVING := 3
```

`project.godot` must define the six input actions listed in the Interfaces block and use a Godot 4 renderer suitable for a desktop POC.

- [ ] **Step 4: Run the focused test and project parse check**

```bash
godot --headless --path . --editor --quit
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_project_bootstrap.gd
```

Expected: both commands exit 0.

- [ ] **Step 5: Commit**

```bash
git add project.godot src/core/board_state.gd tests/unit/test_project_bootstrap.gd
git commit -m "chore: bootstrap dual-board Godot POC"
```

---

### Task 2: Implement CombatState resource economy and Combat Clock

**Files:**
- Create: `src/core/combat_state.gd`
- Create: `tests/unit/test_combat_state.gd`

**Interfaces:**
- Produces: `CombatState.new()`, `tick(delta: float)`, `gain_energy(amount: int)`, `set_chain_stock_from_completed_chain(chain_count: int)`, `can_spend_skill(tier: int, energy_cost: int) -> bool`, `spend_skill(tier: int, energy_cost: int) -> bool`.
- State: `player_hp: int = 200`, `player_max_hp: int = 200`, `enemy_hp: int = 300`, `enemy_max_hp: int = 300`, `energy: int = 0`, `chain_stock: int = 0`, `combat_time: float = 0.0`, `enemy_countdown: float = 12.0`.

- [ ] **Step 1: Write failing tests for Stock, Skill spending and emergency Energy recovery**

```gdscript
extends GutTest

var CombatStateScript := preload("res://src/core/combat_state.gd")

func test_completed_chain_sets_non_additive_stock_with_cap() -> void:
    var state = CombatStateScript.new()
    state.set_chain_stock_from_completed_chain(2)
    state.set_chain_stock_from_completed_chain(2)
    assert_eq(state.chain_stock, 2)
    state.set_chain_stock_from_completed_chain(7)
    assert_eq(state.chain_stock, 5)

func test_skill_spending_requires_both_resources() -> void:
    var state = CombatStateScript.new()
    state.energy = 40
    state.chain_stock = 3
    assert_true(state.spend_skill(3, 40))
    assert_eq(state.energy, 0)
    assert_eq(state.chain_stock, 0)
    assert_false(state.spend_skill(1, 15))

func test_emergency_energy_recovery_stops_at_15() -> void:
    var state = CombatStateScript.new()
    state.tick(20.0)
    assert_eq(state.energy, 15)
    state.tick(20.0)
    assert_eq(state.energy, 15)

func test_combat_clock_always_advances_when_ticked() -> void:
    var state = CombatStateScript.new()
    state.tick(2.5)
    assert_almost_eq(state.combat_time, 2.5, 0.001)
    assert_almost_eq(state.enemy_countdown, 9.5, 0.001)
```

- [ ] **Step 2: Run focused tests and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_combat_state.gd
```

Expected: FAIL because `CombatState` is not implemented.

- [ ] **Step 3: Implement only the tested domain rules**

`tick(delta)` increments `combat_time`, decrements `enemy_countdown`, and adds Energy at 1 point per accumulated second only while `energy < 15`, clamping to 15. `set_chain_stock_from_completed_chain` clamps the completed chain to 0…5 and assigns `max(current, clamped)`. `spend_skill` returns false without mutation if tier is outside 1…5 or either resource is insufficient.

- [ ] **Step 4: Run focused tests and verify pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_combat_state.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/core/combat_state.gd tests/unit/test_combat_state.gd
git commit -m "feat: add combat resource state and clock"
```

---

### Task 3: Implement manual mode switching and board freeze policy

**Files:**
- Create: `src/core/mode_controller.gd`
- Create: `tests/unit/test_mode_controller.gd`

**Interfaces:**
- Consumes: `BoardState`.
- Produces: `ModeController.new()`, `request_switch(target_mode: StringName)`, `set_running()`, `set_locked()`, `begin_resolution(mode: StringName)`, `finish_resolution(mode: StringName)`.
- State: `active_mode: StringName = &"line"`, `line_state: int = BoardState.LOCKED`, `chain_state: int = BoardState.SUSPENDED`, `queued_mode: StringName = &""`.

- [ ] **Step 1: Write failing transition tests**

```gdscript
extends GutTest

var ModeControllerScript := preload("res://src/core/mode_controller.gd")
var BoardState := preload("res://src/core/board_state.gd")

func test_destination_is_locked_after_switch() -> void:
    var modes = ModeControllerScript.new()
    modes.set_running()
    modes.request_switch(&"chain")
    assert_eq(modes.active_mode, &"chain")
    assert_eq(modes.line_state, BoardState.SUSPENDED)
    assert_eq(modes.chain_state, BoardState.LOCKED)

func test_switch_during_resolution_is_queued() -> void:
    var modes = ModeControllerScript.new()
    modes.begin_resolution(&"line")
    modes.request_switch(&"chain")
    assert_eq(modes.active_mode, &"line")
    assert_eq(modes.queued_mode, &"chain")
    modes.finish_resolution(&"line")
    assert_eq(modes.active_mode, &"chain")
    assert_eq(modes.chain_state, BoardState.LOCKED)

func test_only_active_board_can_run() -> void:
    var modes = ModeControllerScript.new()
    modes.set_running()
    assert_eq(modes.line_state, BoardState.RUNNING)
    assert_eq(modes.chain_state, BoardState.SUSPENDED)
```

- [ ] **Step 2: Run and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_mode_controller.gd
```

Expected: FAIL.

- [ ] **Step 3: Implement the state machine exactly as tested**

Reject target modes other than `&"line"` and `&"chain"`. A switch sets the old active board to `SUSPENDED` and the destination to `LOCKED`. `set_running` and `set_locked` mutate only the active board. During active-board `RESOLVING`, a switch request is stored in `queued_mode`; `finish_resolution` makes the current board `LOCKED` and then applies the queued switch.

- [ ] **Step 4: Run and verify pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_mode_controller.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/core/mode_controller.gd tests/unit/test_mode_controller.gd
git commit -m "feat: add manual dual-board mode controller"
```

---

### Task 4: Implement Line clear normalization and Energy/Score mapping

**Files:**
- Create: `src/line/line_rules.gd`
- Create: `tests/unit/test_line_rules.gd`

**Interfaces:**
- Produces: `LineRules.energy_for_clear(lines: int) -> int`, `LineRules.base_score_for_clear(lines: int, level: int = 1) -> int`, `LineRules.make_event(lines: int, combo: int = 0, back_to_back: bool = false) -> Dictionary`.

- [ ] **Step 1: Write failing POC mapping tests**

```gdscript
extends GutTest

var LineRules := preload("res://src/line/line_rules.gd")

func test_energy_mapping_matches_poc_spec() -> void:
    assert_eq(LineRules.energy_for_clear(1), 10)
    assert_eq(LineRules.energy_for_clear(2), 22)
    assert_eq(LineRules.energy_for_clear(3), 36)
    assert_eq(LineRules.energy_for_clear(4), 52)
    assert_eq(LineRules.energy_for_clear(0), 0)

func test_reference_line_score_weights_are_separate_from_energy() -> void:
    assert_eq(LineRules.base_score_for_clear(1), 100)
    assert_eq(LineRules.base_score_for_clear(2), 300)
    assert_eq(LineRules.base_score_for_clear(3), 500)
    assert_eq(LineRules.base_score_for_clear(4), 800)
```

- [ ] **Step 2: Run and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_line_rules.gd
```

Expected: FAIL.

- [ ] **Step 3: Implement mappings and normalized event dictionary**

`make_event` returns keys `type`, `lines`, `energy`, `score`, `combo`, `back_to_back`. Do not make Combo or Back-to-Back change Energy in this first slice; preserve them as event metadata for later tuning.

- [ ] **Step 4: Run and verify pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_line_rules.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/line/line_rules.gd tests/unit/test_line_rules.gd
git commit -m "feat: add line clear energy and score rules"
```

---

### Task 5: Implement Chain resolution output and non-additive Stock contribution

**Files:**
- Create: `src/chain/chain_rules.gd`
- Create: `tests/unit/test_chain_rules.gd`

**Interfaces:**
- Produces: `ChainRules.stock_from_chain(chain_count: int) -> int`, `ChainRules.make_completed_event(chain_count: int, pieces_cleared: int, color_bonus: int = 0, group_bonus: int = 0) -> Dictionary`.

- [ ] **Step 1: Write failing Chain tests**

```gdscript
extends GutTest

var ChainRules := preload("res://src/chain/chain_rules.gd")

func test_stock_contribution_is_chain_count_capped_at_five() -> void:
    assert_eq(ChainRules.stock_from_chain(1), 1)
    assert_eq(ChainRules.stock_from_chain(5), 5)
    assert_eq(ChainRules.stock_from_chain(8), 5)

func test_completed_event_keeps_score_inputs_separate_from_stock() -> void:
    var event = ChainRules.make_completed_event(4, 20, 6, 3)
    assert_eq(event.chain_count, 4)
    assert_eq(event.stock_value, 4)
    assert_eq(event.pieces_cleared, 20)
    assert_eq(event.color_bonus, 6)
    assert_eq(event.group_bonus, 3)
```

- [ ] **Step 2: Run and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chain_rules.gd
```

Expected: FAIL.

- [ ] **Step 3: Implement the normalized Chain event**

The event must not add Stock; it only reports the completed chain's capped `stock_value`. `CombatState.set_chain_stock_from_completed_chain` remains the sole authority for non-additive Stock application.

- [ ] **Step 4: Run and verify pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chain_rules.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/chain/chain_rules.gd tests/unit/test_chain_rules.gd
git commit -m "feat: add chain completion rules"
```

---

### Task 6: Implement class-agnostic Skill definitions and execution

**Files:**
- Create: `src/skills/skill_definition.gd`
- Create: `src/skills/skill_executor.gd`
- Create: `tests/unit/test_skill_executor.gd`

**Interfaces:**
- Consumes: `CombatState.spend_skill(tier, energy_cost)`.
- Produces: `SkillDefinition.new(id: StringName, role: StringName, tier: int, energy_cost: int, magnitude: int)`; `SkillExecutor.execute(skill: SkillDefinition, state) -> bool`.
- POC skills: `attack_t1` (Attack, T1, 15 Energy, 25 damage), `defense_t1` (Defense, T1, 15 Energy, 30 shield), `heal_t1` (Heal, T1, 15 Energy, 25 HP). Higher tiers use Energy 25/40/60/85 and can initially scale magnitude linearly for smoke testing only.

- [ ] **Step 1: Write failing skill tests**

```gdscript
extends GutTest

var CombatStateScript := preload("res://src/core/combat_state.gd")
var SkillDefinition := preload("res://src/skills/skill_definition.gd")
var SkillExecutor := preload("res://src/skills/skill_executor.gd")

func test_attack_spends_resources_and_damages_enemy() -> void:
    var state = CombatStateScript.new()
    state.energy = 15
    state.chain_stock = 1
    var skill = SkillDefinition.new(&"attack_t1", &"attack", 1, 15, 25)
    assert_true(SkillExecutor.execute(skill, state))
    assert_eq(state.enemy_hp, 275)
    assert_eq(state.energy, 0)
    assert_eq(state.chain_stock, 0)

func test_heal_clamps_to_max_hp() -> void:
    var state = CombatStateScript.new()
    state.player_hp = 190
    state.energy = 15
    state.chain_stock = 1
    var skill = SkillDefinition.new(&"heal_t1", &"heal", 1, 15, 25)
    assert_true(SkillExecutor.execute(skill, state))
    assert_eq(state.player_hp, 200)

func test_skill_fails_without_required_stock_without_side_effect() -> void:
    var state = CombatStateScript.new()
    state.energy = 85
    state.chain_stock = 4
    var skill = SkillDefinition.new(&"attack_t5", &"attack", 5, 85, 125)
    assert_false(SkillExecutor.execute(skill, state))
    assert_eq(state.enemy_hp, 300)
    assert_eq(state.energy, 85)
```

- [ ] **Step 2: Run and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_skill_executor.gd
```

Expected: FAIL.

- [ ] **Step 3: Implement minimal Attack / Defense / Heal effects**

Add `shield: int = 0` to `CombatState`. Attack subtracts magnitude from enemy HP, Defense adds magnitude to shield, Heal restores HP up to max. Reject unknown role names without spending resources.

- [ ] **Step 4: Run and verify pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_skill_executor.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/core/combat_state.gd src/skills/skill_definition.gd src/skills/skill_executor.gd tests/unit/test_skill_executor.gd
git commit -m "feat: add class-agnostic combat skills"
```

---

### Task 7: Add one deterministic enemy timeline pattern

**Files:**
- Create: `src/enemies/enemy_pattern.gd`
- Extend: `src/core/combat_state.gd`
- Create: `tests/unit/test_enemy_pattern.gd`

**Interfaces:**
- Produces: `EnemyPattern.new(actions: Array[Dictionary])`, `advance(delta: float, state) -> Array[Dictionary]`; action shape `{ "time": float, "kind": StringName, "value": int }`.
- POC sequence: at 12s `attack` 40, at 24s `attack` 70, at 36s `heal` 40, then stop.

- [ ] **Step 1: Write failing pattern tests**

```gdscript
extends GutTest

var CombatStateScript := preload("res://src/core/combat_state.gd")
var EnemyPatternScript := preload("res://src/enemies/enemy_pattern.gd")

func test_enemy_action_occurs_at_visible_schedule() -> void:
    var state = CombatStateScript.new()
    var pattern = EnemyPatternScript.poc_default()
    pattern.advance(11.9, state)
    assert_eq(state.player_hp, 200)
    pattern.advance(0.1, state)
    assert_eq(state.player_hp, 160)

func test_shield_absorbs_enemy_damage_first() -> void:
    var state = CombatStateScript.new()
    state.shield = 30
    var pattern = EnemyPatternScript.poc_default()
    pattern.advance(12.0, state)
    assert_eq(state.shield, 0)
    assert_eq(state.player_hp, 190)
```

- [ ] **Step 2: Run and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_enemy_pattern.gd
```

Expected: FAIL.

- [ ] **Step 3: Implement deterministic timeline and incoming damage helper**

Add `apply_incoming_damage(amount: int)` to `CombatState`: consume shield first, then HP, clamp HP to 0. Enemy heal clamps to enemy max HP. Keep pattern state deterministic and do not randomize actions.

- [ ] **Step 4: Run and verify pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_enemy_pattern.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/core/combat_state.gd src/enemies/enemy_pattern.gd tests/unit/test_enemy_pattern.gd
git commit -m "feat: add deterministic enemy combat timeline"
```

---

### Task 8: Implement the minimum runnable Line board

**Files:**
- Create: `src/line/line_board.gd`
- Create: `tests/unit/test_line_board.gd`

**Interfaces:**
- Produces: `LineBoard.new(width: int = 10, height: int = 20)`, `set_cell(x: int, y: int, value: int)`, `get_cell(x: int, y: int) -> int`, `clear_full_rows() -> Dictionary`, `step(delta: float, running: bool) -> void`, `step_count: int`.
- Emits no UI directly. `clear_full_rows()` returns `LineRules.make_event(cleared_rows)`.

- [ ] **Step 1: Write failing board tests**

```gdscript
extends GutTest

var LineBoardScript := preload("res://src/line/line_board.gd")

func test_default_board_is_10_by_20() -> void:
    var board = LineBoardScript.new()
    assert_eq(board.width, 10)
    assert_eq(board.height, 20)

func test_full_row_clear_returns_energy_event() -> void:
    var board = LineBoardScript.new()
    for x in range(10):
        board.set_cell(x, 19, 1)
    var event = board.clear_full_rows()
    assert_eq(event.lines, 1)
    assert_eq(event.energy, 10)

func test_step_does_not_advance_when_not_running() -> void:
    var board = LineBoardScript.new()
    board.step(1.0, false)
    assert_eq(board.step_count, 0)
    board.step(1.0, true)
    assert_eq(board.step_count, 1)
```

- [ ] **Step 2: Run and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_line_board.gd
```

Expected: FAIL.

- [ ] **Step 3: Implement grid storage, row clear and deterministic stepping**

For this task, do not implement the full production rotation system. The POC board only needs deterministic grid mutation, row clearing and a `step()` hook that later scene/input code can drive. Keep piece-generation/rotation as the next refinement after the dual-resource combat loop proves useful.

- [ ] **Step 4: Run and verify pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_line_board.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/line/line_board.gd tests/unit/test_line_board.gd
git commit -m "feat: add minimal line board domain model"
```

---

### Task 9: Implement the minimum runnable Chain board and complete-chain detection

**Files:**
- Create: `src/chain/chain_board.gd`
- Create: `tests/unit/test_chain_board.gd`

**Interfaces:**
- Produces: `ChainBoard.new(width: int = 6, height: int = 12)`, `set_cell(x: int, y: int, color: int)`, `get_cell(x: int, y: int) -> int`, `resolve_until_stable() -> Dictionary`, `step(delta: float, running: bool) -> void`, `step_count: int`.
- Connected orthogonal groups of 4+ matching nonzero colors clear. Gravity compacts each column after each clear. `resolve_until_stable()` repeats until no group clears and returns one `ChainRules.make_completed_event` for the total chain count and pieces cleared.

- [ ] **Step 1: Write failing Chain board tests**

```gdscript
extends GutTest

var ChainBoardScript := preload("res://src/chain/chain_board.gd")

func test_default_board_is_6_by_12() -> void:
    var board = ChainBoardScript.new()
    assert_eq(board.width, 6)
    assert_eq(board.height, 12)

func test_four_connected_cells_clear_as_one_chain() -> void:
    var board = ChainBoardScript.new()
    board.set_cell(0, 11, 1)
    board.set_cell(1, 11, 1)
    board.set_cell(0, 10, 1)
    board.set_cell(1, 10, 1)
    var event = board.resolve_until_stable()
    assert_eq(event.chain_count, 1)
    assert_eq(event.stock_value, 1)
    assert_eq(event.pieces_cleared, 4)

func test_step_does_not_advance_when_not_running() -> void:
    var board = ChainBoardScript.new()
    board.step(1.0, false)
    assert_eq(board.step_count, 0)
```

- [ ] **Step 2: Run and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chain_board.gd
```

Expected: FAIL.

- [ ] **Step 3: Implement group search, clear, gravity and repeated resolution**

Use iterative flood fill, not recursion, to avoid stack coupling. Resolution must be atomic from the caller's perspective: once started, it runs to a stable board before returning the final event.

- [ ] **Step 4: Run and verify pass**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chain_board.gd
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/chain/chain_board.gd tests/unit/test_chain_board.gd
git commit -m "feat: add minimal chain board resolution"
```

---

### Task 10: Integrate mode state, both boards, resources and enemy clock

**Files:**
- Create: `src/core/poc_session.gd`
- Create: `tests/integration/test_dual_board_flow.gd`
- Create: `tests/integration/test_board_freeze.gd`

**Interfaces:**
- Consumes: `CombatState`, `ModeController`, `LineBoard`, `ChainBoard`, `SkillExecutor`, `EnemyPattern`.
- Produces: `PocSession.new()`, `tick(delta: float)`, `switch_mode(mode: StringName)`, `set_running()`, `set_locked()`, `apply_line_clear(lines: int)`, `resolve_chain()`, `use_skill(skill) -> bool`.

- [ ] **Step 1: Write failing end-to-end resource flow test**

```gdscript
extends GutTest

var PocSessionScript := preload("res://src/core/poc_session.gd")
var SkillDefinition := preload("res://src/skills/skill_definition.gd")

func test_line_to_chain_to_skill_flow() -> void:
    var session = PocSessionScript.new()
    session.apply_line_clear(2)
    assert_eq(session.combat.energy, 22)

    session.combat.set_chain_stock_from_completed_chain(1)
    var attack = SkillDefinition.new(&"attack_t1", &"attack", 1, 15, 25)
    assert_true(session.use_skill(attack))
    assert_eq(session.combat.energy, 7)
    assert_eq(session.combat.chain_stock, 0)
    assert_eq(session.combat.enemy_hp, 275)
```

- [ ] **Step 2: Write failing freeze-policy integration test**

```gdscript
func test_inactive_and_locked_boards_freeze_but_combat_time_advances() -> void:
    var session = PocSessionScript.new()
    session.set_running()
    session.tick(1.0)
    assert_eq(session.line_board.step_count, 1)
    assert_eq(session.chain_board.step_count, 0)

    session.set_locked()
    session.tick(1.0)
    assert_eq(session.line_board.step_count, 1)
    assert_almost_eq(session.combat.combat_time, 2.0, 0.001)

    session.switch_mode(&"chain")
    session.tick(1.0)
    assert_eq(session.chain_board.step_count, 0)
    assert_almost_eq(session.combat.combat_time, 3.0, 0.001)
```

- [ ] **Step 3: Run both integration tests and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_dual_board_flow.gd,res://tests/integration/test_board_freeze.gd
```

Expected: FAIL.

- [ ] **Step 4: Implement `PocSession` as the sole orchestration object**

`tick(delta)` must always advance `CombatState` and `EnemyPattern`. It advances only the board whose state is `RUNNING`. `switch_mode` delegates to `ModeController`. `apply_line_clear` applies `LineRules.energy_for_clear`. Chain Stock changes only after a completed Chain event. Do not let UI code bypass `PocSession` to mutate resource rules.

- [ ] **Step 5: Run all unit + integration tests**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/core/poc_session.gd tests/integration/test_dual_board_flow.gd tests/integration/test_board_freeze.gd
git commit -m "feat: integrate dual-board combat session"
```

---

### Task 11: Build the one-screen POC UI without moving rules into presentation

**Files:**
- Create: `scenes/poc_battle.tscn`
- Create: `src/ui/poc_battle.gd`
- Modify: `project.godot`

**Interfaces:**
- Consumes: `PocSession` public commands/state only.
- Produces: playable desktop scene with Line/Chain tabs, active-board area, inactive-board summary, RUN/LOCK button, Energy, Chain Stock, HP/enemy HP, enemy countdown, Attack/Defense/Heal buttons.

- [ ] **Step 1: Add a scene smoke test that fails until the scene exists**

Create `tests/integration/test_poc_scene.gd`:

```gdscript
extends GutTest

func test_poc_scene_instantiates() -> void:
    var packed := load("res://scenes/poc_battle.tscn")
    assert_not_null(packed)
    var scene = packed.instantiate()
    assert_not_null(scene)
    scene.free()
```

- [ ] **Step 2: Run scene smoke test and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_poc_scene.gd
```

Expected: FAIL because the scene does not exist.

- [ ] **Step 3: Build the minimal scene and bind controls**

The scene must visibly show:

```text
Enemy HP | Next action countdown
LINE [Energy N] | CHAIN [Stock N]
Active board area
Inactive board summary
RUN / LOCK
Attack | Defense | Heal
Player HP | Shield | Score
```

Mode switch calls `session.switch_mode`. Switching never auto-runs the destination. RUN/LOCK calls `session.set_running` / `session.set_locked`. Skill buttons call `session.use_skill` with Tier-1 smoke-test SkillDefinitions. UI reads state every frame but never writes Energy/Stock/HP directly.

- [ ] **Step 4: Run scene smoke test and full test suite**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_poc_scene.gd
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: PASS.

- [ ] **Step 5: Run manual desktop smoke test**

```bash
godot --path . res://scenes/poc_battle.tscn
```

Verify manually:

1. Line is initially visible and locked.
2. RUN starts only Line progression.
3. Switching to Chain freezes Line and Chain arrives locked.
4. Enemy countdown continues through LOCK and switching.
5. Line clear debug action/resource path increases Energy.
6. Completed Chain path raises Stock without adding repeated low Chains.
7. Attack/Defense/Heal spend both required resources.

- [ ] **Step 6: Commit**

```bash
git add scenes/poc_battle.tscn src/ui/poc_battle.gd project.godot tests/integration/test_poc_scene.gd
git commit -m "feat: add dual-board combat POC scene"
```

---

### Task 12: Add telemetry needed for the 45-second balance slice

**Files:**
- Create: `src/core/telemetry_log.gd`
- Extend: `src/core/poc_session.gd`
- Create: `tests/unit/test_telemetry_log.gd`

**Interfaces:**
- Produces: `TelemetryLog.record(type: StringName, payload: Dictionary, combat_time: float)`, `TelemetryLog.events: Array[Dictionary]`, `TelemetryLog.count(type: StringName) -> int`.
- Required event types: `mode_switch`, `lock`, `run`, `line_clear`, `chain_complete`, `skill_use`, `skill_rejected`, `enemy_action`, `player_defeated`, `enemy_defeated`.

- [ ] **Step 1: Write failing telemetry test**

```gdscript
extends GutTest

var TelemetryLogScript := preload("res://src/core/telemetry_log.gd")

func test_records_timestamped_event_without_mutating_payload() -> void:
    var log = TelemetryLogScript.new()
    var payload := {"mode": "chain"}
    log.record(&"mode_switch", payload, 7.5)
    assert_eq(log.count(&"mode_switch"), 1)
    assert_almost_eq(log.events[0].combat_time, 7.5, 0.001)
    assert_eq(log.events[0].payload.mode, "chain")
```

- [ ] **Step 2: Run and verify failure**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_telemetry_log.gd
```

Expected: FAIL.

- [ ] **Step 3: Implement log and hook POC session commands**

Every mode/resource/skill/enemy transition listed above must emit exactly one telemetry event. Store data in memory only for the POC; do not add external analytics or network calls.

- [ ] **Step 4: Run all tests**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/core/telemetry_log.gd src/core/poc_session.gd tests/unit/test_telemetry_log.gd
git commit -m "feat: add local POC telemetry"
```

---

### Task 13: Verify the 45-second POC contract and document evidence

**Files:**
- Create: `docs/validation/POC_45S_VALIDATION.md`

**Interfaces:**
- Consumes: all previous POC behavior and telemetry.
- Produces: explicit PASS/FAIL/NOT_RUN evidence for the GDD acceptance criteria that are testable in this slice.

- [ ] **Step 1: Run Godot parse/import validation**

```bash
godot --headless --path . --editor --quit
```

Expected: exit 0 and no parse errors.

- [ ] **Step 2: Run full deterministic GUT suite**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: exit 0.

- [ ] **Step 3: Run the POC for at least one 45-second encounter**

```bash
godot --path . res://scenes/poc_battle.tscn
```

During the run, intentionally perform at least:

- one `LINE RUNNING → LOCKED` transition;
- one `LINE → CHAIN` mode switch and explicit RUN;
- one Energy-producing Line clear;
- one completed Chain that creates Stock;
- one successful Skill use;
- one rejected Skill use due to insufficient Energy or Stock;
- one enemy action while the puzzle board is locked.

- [ ] **Step 4: Write validation evidence**

`docs/validation/POC_45S_VALIDATION.md` must contain:

```markdown
# POC 45-Second Validation

## Environment
- Godot version: <actual command output>
- GUT version: <actual adopted version>
- Commit: <actual SHA>

## Automated
- Godot parse/import: PASS/FAIL
- GUT unit suite: PASS/FAIL
- GUT integration suite: PASS/FAIL

## Manual 45s run
- inactive board stayed frozen: PASS/FAIL
- locked active board stayed frozen: PASS/FAIL
- Combat Clock advanced during lock: PASS/FAIL
- mode destination required explicit RUN: PASS/FAIL
- Line clear produced Energy: PASS/FAIL
- completed Chain produced non-additive Stock: PASS/FAIL
- Skill spent Energy + Stock: PASS/FAIL
- enemy action remained legible under mode switching: PASS/FAIL

## Telemetry excerpt
<copy the relevant local events>

## Remaining NOT_RUN
- production Line piece rotation/kicks
- advanced Spin/B2B/Perfect Clear bonuses
- production Chain pair controls
- final top-out recovery
- class roster balancing
- external tester validation
```

Replace every angle-bracket item with actual evidence before marking validation complete.

- [ ] **Step 5: Review git diff for scope**

```bash
git status --short
git diff --stat main...HEAD
git diff main...HEAD -- project.godot src scenes tests docs/validation
```

Expected: only files required by this plan plus the already-approved design/plan documents; no unrelated refactors or user changes removed.

- [ ] **Step 6: Commit validation evidence**

```bash
git add docs/validation/POC_45S_VALIDATION.md
git commit -m "test: document dual-board POC validation"
```

---

## Plan Self-Review

### Spec coverage

- persistent independent Line/Chain boards → Tasks 8–10
- active-only RUNNING / inactive SUSPENDED → Tasks 3 and 10
- destination LOCKED + explicit RUN → Tasks 3, 10, 11
- Combat Clock continues during lock/switch/skill UI → Tasks 2, 7, 10, 11, 13
- Line→Energy → Tasks 4, 8, 10
- completed Chain→non-additive capped Stock → Tasks 2, 5, 9, 10
- Tier-N Energy + Stock spending → Tasks 2 and 6
- Attack/Defense/Heal → Task 6
- Score separated from combat economy → Tasks 4 and 5; UI displays score hook without using it as currency
- 10×20 / 6×12 boards → Tasks 8 and 9
- visible enemy timeline → Tasks 7 and 11
- telemetry and balance evidence → Tasks 12 and 13

### Deliberate POC exclusions

The plan does not yet implement production-quality tetromino rotation/kicks, complete Puyo pair controls, advanced Line bonuses, final top-out recovery, production class kits, equipment, or content progression. These are intentionally excluded because the first question to validate is whether **manual dual-board switching + separate Energy/Chain jobs + global enemy timing** creates the intended decision loop.

### Revisit conditions

Revisit the architecture before extending content if any 45-second validation run shows one of these:

- players can ignore either Line or Chain for most of the fight;
- LOCK makes the game functionally easier without meaningful enemy-clock pressure;
- mode-switch frequency is so high that it becomes UI tax rather than a decision;
- non-additive Chain Stock makes rebuilding high-tier access too slow after one Skill;
- automatic Energy floor makes deliberate Line play unnecessary for survival;
- domain logic cannot be tested without scene/UI dependencies.
