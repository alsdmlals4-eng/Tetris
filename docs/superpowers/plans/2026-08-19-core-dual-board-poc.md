# Core Dual-Board Combat POC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the smallest runnable Godot POC that proves the approved Line/Chain mode-switching combat loop before investing in production-quality Line and Chain puzzle engines.

**Architecture:** Keep puzzle simulation behind two interchangeable event-source interfaces. The first POC uses deterministic debug/event controls to emit Line Clear and completed Chain events, while real combat state, mode switching, global Combat Clock, resource spending, enemy timing, UI state and telemetry are implemented for real. After this loop passes the 45-second validation contract, production Line and Chain engines replace the event sources without changing combat/resource rules.

**Tech Stack:** Godot 4.x + GDScript; deterministic GDScript tests with GUT when the local Godot/GUT compatibility preflight is satisfied; Git is repository change truth. HiGodot remains the sole persistent Godot authoring authority if editor automation is used. Hera, if adopted later, is read/run/QA only and must not become a second persistent authoring authority.

**Spec:** `docs/design/CORE_GAMEPLAY_GDD.md`, `docs/design/POC_RULESET_V0_1.md`

## Global Constraints

- Do not use `Mana`, `Magic`, or `Spell` as core-system terminology.
- Line and Chain are separate persistent modes.
- Only the active mode may be `RUNNING`; inactive mode is `SUSPENDED`.
- A mode switch always lands on the destination mode as `LOCKED`; it never auto-runs.
- `LOCKED` freezes puzzle/event progression only. Combat Clock always continues unless a future explicit Skill effect changes it.
- A switch request during `RESOLVING` is queued until resolution reaches a stable state.
- Line Clear produces Energy.
- Completed N-Chain updates Stock with `max(current_stock, min(N, 5))`; repeated low Chains cannot add up to a higher Tier.
- Tier-N Skill requires enough Energy and `Chain Stock >= N`; activation consumes configured Energy and exactly N Stock.
- POC Skill roles are Attack / Defense / Heal and remain class-agnostic.
- Score is recorded separately and never purchases Skills.
- POC Energy mapping: Single 10, Double 22, Triple 36, 4-Line Clear 52.
- POC Skill Energy baseline: T1 15, T2 25, T3 40, T4 60, T5 85.
- Emergency Energy recovery: +1 per real combat second only while Energy < 15; clamp at 15.
- First enemy schedule: 12s attack 40, 24s attack 70, 36s heal 40; deterministic, no RNG.
- No paid API, runner, SaaS, marketplace credit, or additional paid dependency.
- Do not implement production tetromino rotation/kicks, Puyo-style pair controls, final top-out behavior, equipment, classes, progression, PvP, production art, or mobile controls in this POC.

---

## Why This Is a Separate POC

### Alternative A — build both production puzzle engines first

**Benefit:** earliest build already feels like the final puzzle game.

**Cost/Risk:** large implementation surface before proving that manual mode switching, global enemy timing, dual-resource preparation and Skill spending are enjoyable. Bugs in puzzle physics obscure whether the combat loop itself works.

**Decision:** REJECT for first slice; return after Core POC validation.

### Alternative B — real combat loop + replaceable deterministic event sources

**Benefit:** validates the unique game decision loop quickly, keeps rules testable, and allows real Line/Chain engines to plug in later.

**Cost/Risk:** cannot validate final puzzle feel or true Line/Chain difficulty balance yet.

**Decision:** ADOPT for first slice.

### Alternative C — one generic grid engine for both modes from day one

**Benefit:** apparent code reuse.

**Cost/Risk:** Line and Chain resolution rules are structurally different; premature shared abstraction risks coupling and later condition-heavy code.

**Decision:** REJECT until both real engines exist and shared behavior can be proven rather than guessed.

### Revisit conditions

Revisit Alternative B after the 45-second slice if the event-source boundary makes real puzzle integration awkward, or if the mode/resource loop cannot be evaluated without real piece-placement timing.

---

## File Map

- `AGENTS.md` — project-local operating contract derived from the approved project decisions and current Base authority.
- `project.godot` — minimal desktop Godot project and input actions.
- `src/core/board_state.gd` — shared `RUNNING/LOCKED/SUSPENDED/RESOLVING` constants.
- `src/core/combat_state.gd` — HP, Shield, Energy, Chain Stock, Score, Combat Clock and resource validation.
- `src/core/mode_controller.gd` — active mode and legal transition policy.
- `src/core/poc_session.gd` — orchestration boundary; UI must not bypass it.
- `src/core/telemetry_log.gd` — local in-memory evidence events; no network analytics.
- `src/puzzle/puzzle_event_source.gd` — interface contract for Line/Chain event sources.
- `src/puzzle/debug_line_source.gd` — deterministic POC Line event emitter.
- `src/puzzle/debug_chain_source.gd` — deterministic POC Chain event emitter.
- `src/rules/line_rules.gd` — Energy and Line Score mapping.
- `src/rules/chain_rules.gd` — completed-chain Stock contribution and Chain Score event shape.
- `src/skills/skill_definition.gd` — class-agnostic Skill data.
- `src/skills/skill_executor.gd` — Attack/Defense/Heal execution.
- `src/enemies/enemy_pattern.gd` — deterministic enemy schedule.
- `src/ui/poc_battle.gd` — scene/controller adapter only.
- `scenes/poc_battle.tscn` — one-screen POC.
- `tests/unit/` — deterministic domain tests.
- `tests/integration/` — cross-component state-flow tests.
- `docs/validation/POC_45S_VALIDATION.md` — actual evidence only; statuses start as `NOT_RUN` and change only after execution.

---

### Task 1: Establish local project rules and execution preflight

**Files:**
- Create: `AGENTS.md`
- Create: `docs/validation/POC_45S_VALIDATION.md`

**Interfaces:**
- Produces project-local rules for later tasks; no gameplay code.

- [ ] **Step 1: Read current authorities before editing**

Read in order:

```text
Tetris/docs/design/CORE_GAMEPLAY_GDD.md
Tetris/docs/design/POC_RULESET_V0_1.md
Base/AGENTS.md
Base/docs/knowledge/godot/HIGODOT_SINGLE_AUTHORITY_AND_SAFE_OPERATION.md
Base current Godot/GUT compatibility authority
```

Do not copy unrelated Base project content.

- [ ] **Step 2: Verify local execution prerequisites**

Run:

```bash
git status --short
godot --version
git --version
```

Expected: clean/understood working tree, Godot 4.x installed, Git available. If Godot is absent or outside the supported project range chosen from current Base authority, stop code execution and record the exact blocker; do not claim tests ran.

- [ ] **Step 3: Verify the current GUT compatibility from its official source before installation**

Use the exact local Godot version from Step 2 and the current official GUT compatibility table. Pin one compatible GUT version. Do not choose a version from stale memory.

- [ ] **Step 4: Create `AGENTS.md`**

It must state at minimum:

```markdown
# Tetris project work rules

- Canon gameplay: docs/design/CORE_GAMEPLAY_GDD.md and docs/design/POC_RULESET_V0_1.md.
- Core terminology: HP, Energy, Chain, Chain Stock, Skill, Skill Tier, Combo, Score.
- Do not introduce Mana/Magic/Spell as core-system terms.
- Godot/GDScript is the runtime implementation path.
- Persistent Godot authoring automation follows Base HiGodot single-authority policy.
- Deterministic GDScript tests use the project-adopted compatible GUT pin.
- Inactive puzzle mode never advances.
- LOCK never pauses Combat Clock.
- Score never becomes a Skill currency.
- No additional paid dependency without explicit user approval.
- Do not overwrite unrelated user changes; validate diff before completion.
```

- [ ] **Step 5: Create the validation ledger with factual initial state**

`docs/validation/POC_45S_VALIDATION.md` must list every acceptance item from Task 10 as `NOT_RUN`. Do not write expected PASS results as if observed.

- [ ] **Step 6: Commit**

```bash
git add AGENTS.md docs/validation/POC_45S_VALIDATION.md
git commit -m "chore: establish Tetris POC execution contract"
```

---

### Task 2: Bootstrap Godot and shared board states

**Files:**
- Create: `project.godot`
- Create: `src/core/board_state.gd`
- Create: `tests/unit/test_board_state.gd`

**Interfaces:**
- Produces `BoardState.RUNNING`, `LOCKED`, `SUSPENDED`, `RESOLVING`.
- Project input actions: `mode_line`, `mode_chain`, `toggle_run_lock`, `skill_attack`, `skill_defense`, `skill_heal`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GutTest

func test_board_state_constants() -> void:
    var board_state := load("res://src/core/board_state.gd")
    assert_not_null(board_state)
    assert_eq(board_state.RUNNING, 0)
    assert_eq(board_state.LOCKED, 1)
    assert_eq(board_state.SUSPENDED, 2)
    assert_eq(board_state.RESOLVING, 3)
```

- [ ] **Step 2: Run the focused test and confirm failure**

Use the adopted GUT CLI command for the pinned version. Expected: fail because `board_state.gd` does not exist.

- [ ] **Step 3: Add minimal implementation**

```gdscript
class_name BoardState
extends RefCounted

const RUNNING := 0
const LOCKED := 1
const SUSPENDED := 2
const RESOLVING := 3
```

Create `project.godot` with the six input actions and `scenes/poc_battle.tscn` as the future main scene only after that scene exists.

- [ ] **Step 4: Run parse + focused test**

```bash
godot --headless --path . --editor --quit
```

Then run the adopted focused GUT command. Expected: both exit 0.

- [ ] **Step 5: Commit**

```bash
git add project.godot src/core/board_state.gd tests/unit/test_board_state.gd
git commit -m "chore: bootstrap Godot POC core"
```

---

### Task 3: Implement CombatState

**Files:**
- Create: `src/core/combat_state.gd`
- Create: `tests/unit/test_combat_state.gd`

**Interfaces:**
- Produces `CombatState.new()`.
- Fields: `player_hp=200`, `player_max_hp=200`, `shield=0`, `enemy_hp=300`, `enemy_max_hp=300`, `energy=0`, `chain_stock=0`, `score=0`, `combat_time=0.0`.
- Methods: `tick(delta)`, `gain_energy(amount)`, `add_score(amount)`, `set_chain_stock_from_completed_chain(chain_count)`, `can_spend_skill(tier, energy_cost)`, `spend_skill(tier, energy_cost)`, `apply_incoming_damage(amount)`.

- [ ] **Step 1: Write failing resource tests**

```gdscript
extends GutTest

var CombatStateScript := preload("res://src/core/combat_state.gd")

func test_chain_stock_is_non_additive_and_capped() -> void:
    var state = CombatStateScript.new()
    state.set_chain_stock_from_completed_chain(2)
    state.set_chain_stock_from_completed_chain(2)
    assert_eq(state.chain_stock, 2)
    state.set_chain_stock_from_completed_chain(9)
    assert_eq(state.chain_stock, 5)

func test_tier_three_spend_consumes_exactly_three_stock() -> void:
    var state = CombatStateScript.new()
    state.energy = 40
    state.chain_stock = 5
    assert_true(state.spend_skill(3, 40))
    assert_eq(state.energy, 0)
    assert_eq(state.chain_stock, 2)

func test_emergency_energy_recovery_stops_at_fifteen() -> void:
    var state = CombatStateScript.new()
    state.tick(30.0)
    assert_eq(state.energy, 15)
    state.tick(30.0)
    assert_eq(state.energy, 15)

func test_shield_absorbs_damage_before_hp() -> void:
    var state = CombatStateScript.new()
    state.shield = 30
    state.apply_incoming_damage(40)
    assert_eq(state.shield, 0)
    assert_eq(state.player_hp, 190)
```

- [ ] **Step 2: Run and confirm failure**

Expected: `combat_state.gd` missing or methods missing.

- [ ] **Step 3: Implement only specified state rules**

Emergency Energy uses accumulated real `delta` and cannot exceed 15. Reject tier outside 1–5, negative cost, or insufficient Energy/Stock without mutation. Clamp HP and enemy HP to 0…max.

- [ ] **Step 4: Run focused test and full current suite**

Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add src/core/combat_state.gd tests/unit/test_combat_state.gd
git commit -m "feat: add combat state and dual resources"
```

---

### Task 4: Implement mode switching and freeze policy

**Files:**
- Create: `src/core/mode_controller.gd`
- Create: `tests/unit/test_mode_controller.gd`

**Interfaces:**
- Default: `active_mode=&"line"`, Line=`LOCKED`, Chain=`SUSPENDED`.
- Methods: `request_switch(target_mode)`, `set_running()`, `set_locked()`, `begin_resolution()`, `finish_resolution()`.

- [ ] **Step 1: Write failing transition tests**

```gdscript
extends GutTest

var ModeControllerScript := preload("res://src/core/mode_controller.gd")
var BoardState := preload("res://src/core/board_state.gd")

func test_switch_lands_destination_locked() -> void:
    var modes = ModeControllerScript.new()
    modes.set_running()
    modes.request_switch(&"chain")
    assert_eq(modes.active_mode, &"chain")
    assert_eq(modes.line_state, BoardState.SUSPENDED)
    assert_eq(modes.chain_state, BoardState.LOCKED)

func test_only_active_mode_can_run() -> void:
    var modes = ModeControllerScript.new()
    modes.set_running()
    assert_eq(modes.line_state, BoardState.RUNNING)
    assert_eq(modes.chain_state, BoardState.SUSPENDED)

func test_switch_during_resolution_is_queued() -> void:
    var modes = ModeControllerScript.new()
    modes.begin_resolution()
    modes.request_switch(&"chain")
    assert_eq(modes.active_mode, &"line")
    assert_eq(modes.queued_mode, &"chain")
    modes.finish_resolution()
    assert_eq(modes.active_mode, &"chain")
    assert_eq(modes.chain_state, BoardState.LOCKED)
```

- [ ] **Step 2: Run and confirm failure**

- [ ] **Step 3: Implement the state machine**

Invalid mode names return false and do nothing. Switching to the already active mode also does nothing. `set_running()` and `set_locked()` change only the active mode. During `RESOLVING`, one latest valid target switch may be queued.

- [ ] **Step 4: Run tests and confirm pass**

- [ ] **Step 5: Commit**

```bash
git add src/core/mode_controller.gd tests/unit/test_mode_controller.gd
git commit -m "feat: add manual line chain mode state machine"
```

---

### Task 5: Implement Line and Chain event rules

**Files:**
- Create: `src/rules/line_rules.gd`
- Create: `src/rules/chain_rules.gd`
- Create: `tests/unit/test_line_rules.gd`
- Create: `tests/unit/test_chain_rules.gd`

**Interfaces:**
- `LineRules.energy_for_clear(lines)` returns 10/22/36/52 for 1/2/3/4.
- `LineRules.score_for_clear(lines, level=1)` returns 100/300/500/800 × level.
- `ChainRules.stock_value(chain_count)` clamps chain to 0…5.
- `ChainRules.make_completed_event(chain_count, pieces_cleared)` reports event data but never directly mutates CombatState.

- [ ] **Step 1: Write failing Line tests**

```gdscript
extends GutTest
var LineRules := preload("res://src/rules/line_rules.gd")

func test_line_energy_mapping() -> void:
    assert_eq(LineRules.energy_for_clear(1), 10)
    assert_eq(LineRules.energy_for_clear(2), 22)
    assert_eq(LineRules.energy_for_clear(3), 36)
    assert_eq(LineRules.energy_for_clear(4), 52)
    assert_eq(LineRules.energy_for_clear(0), 0)
```

- [ ] **Step 2: Write failing Chain tests**

```gdscript
extends GutTest
var ChainRules := preload("res://src/rules/chain_rules.gd")

func test_chain_stock_value_caps_at_five() -> void:
    assert_eq(ChainRules.stock_value(1), 1)
    assert_eq(ChainRules.stock_value(5), 5)
    assert_eq(ChainRules.stock_value(8), 5)
```

- [ ] **Step 3: Run and confirm both files fail**

- [ ] **Step 4: Implement mappings and event dictionaries**

Line event keys: `kind`, `lines`, `energy`, `score`. Chain event keys: `kind`, `chain_count`, `stock_value`, `pieces_cleared`. Keep Combo/B2B/Spin/All Clear hooks outside first combat economy; do not invent their final Energy bonuses now.

- [ ] **Step 5: Run and confirm pass**

- [ ] **Step 6: Commit**

```bash
git add src/rules tests/unit/test_line_rules.gd tests/unit/test_chain_rules.gd
git commit -m "feat: add line energy and chain stock rules"
```

---

### Task 6: Implement replaceable POC puzzle event sources

**Files:**
- Create: `src/puzzle/puzzle_event_source.gd`
- Create: `src/puzzle/debug_line_source.gd`
- Create: `src/puzzle/debug_chain_source.gd`
- Create: `tests/unit/test_debug_sources.gd`

**Interfaces:**
- Base source fields: `advance_count`, `state`.
- `advance(delta)` increments only while source state is `RUNNING`.
- Line source command: `emit_clear(lines) -> Dictionary` using LineRules.
- Chain source command: `emit_completed_chain(chain_count, pieces_cleared) -> Dictionary` using ChainRules.
- Source cannot directly change Energy, Stock, HP or Score.

- [ ] **Step 1: Write failing freeze test**

```gdscript
extends GutTest

var DebugLineSource := preload("res://src/puzzle/debug_line_source.gd")
var BoardState := preload("res://src/core/board_state.gd")

func test_source_only_advances_when_running() -> void:
    var source = DebugLineSource.new()
    source.state = BoardState.LOCKED
    source.advance(1.0)
    assert_eq(source.advance_count, 0)
    source.state = BoardState.RUNNING
    source.advance(1.0)
    assert_eq(source.advance_count, 1)
```

- [ ] **Step 2: Write failing event-shape tests for both sources**

Verify Line 2-clear emits Energy 22 and Chain 4 emits Stock value 4.

- [ ] **Step 3: Run and confirm failure**

- [ ] **Step 4: Implement sources without combat-side mutation**

- [ ] **Step 5: Run and confirm pass**

- [ ] **Step 6: Commit**

```bash
git add src/puzzle tests/unit/test_debug_sources.gd
git commit -m "feat: add replaceable puzzle event sources"
```

---

### Task 7: Implement class-agnostic Skills and deterministic enemy schedule

**Files:**
- Create: `src/skills/skill_definition.gd`
- Create: `src/skills/skill_executor.gd`
- Create: `src/enemies/enemy_pattern.gd`
- Create: `tests/unit/test_skill_executor.gd`
- Create: `tests/unit/test_enemy_pattern.gd`

**Interfaces:**
- `SkillDefinition(id, role, tier, energy_cost, magnitude)`.
- `SkillExecutor.execute(skill, combat_state) -> bool`.
- Attack damages enemy, Defense adds Shield, Heal restores player HP.
- Enemy schedule uses fixed 12/24/36 second actions from Global Constraints.

- [ ] **Step 1: Write failing Skill tests**

Test Attack T1 at Energy 15/Stock 1 reduces enemy HP by 25 and consumes both resources; test an unavailable T5 causes no mutation; test Heal clamps to max HP.

- [ ] **Step 2: Write failing enemy tests**

At 11.9s no action. At 12.0s first 40 damage action resolves. Shield absorbs first. At 36s enemy Heal clamps to max.

- [ ] **Step 3: Run and confirm failure**

- [ ] **Step 4: Implement minimal effects**

Use Energy costs 15/25/40/60/85. POC magnitude profile may be data-defined, but only T1 Attack/Defense/Heal must be exposed in the first UI; do not tune class balance here.

- [ ] **Step 5: Run and confirm pass**

- [ ] **Step 6: Commit**

```bash
git add src/skills src/enemies tests/unit/test_skill_executor.gd tests/unit/test_enemy_pattern.gd
git commit -m "feat: add skills and enemy timeline"
```

---

### Task 8: Integrate the session and telemetry

**Files:**
- Create: `src/core/poc_session.gd`
- Create: `src/core/telemetry_log.gd`
- Create: `tests/integration/test_poc_session.gd`
- Create: `tests/integration/test_freeze_contract.gd`

**Interfaces:**
- `PocSession` owns CombatState, ModeController, both event sources, SkillExecutor, EnemyPattern and TelemetryLog.
- Commands: `tick(delta)`, `switch_mode(mode)`, `run_active()`, `lock_active()`, `submit_line_clear(lines)`, `submit_completed_chain(chain_count, pieces_cleared)`, `use_skill(skill)`.
- Telemetry event names: `mode_switch`, `run`, `lock`, `line_clear`, `chain_complete`, `skill_use`, `skill_rejected`, `enemy_action`, `player_defeated`, `enemy_defeated`.

- [ ] **Step 1: Write failing dual-resource integration test**

```gdscript
extends GutTest

var PocSessionScript := preload("res://src/core/poc_session.gd")
var SkillDefinition := preload("res://src/skills/skill_definition.gd")

func test_line_then_chain_then_skill() -> void:
    var session = PocSessionScript.new()
    session.submit_line_clear(2)
    assert_eq(session.combat.energy, 22)
    session.submit_completed_chain(1, 4)
    assert_eq(session.combat.chain_stock, 1)
    var attack = SkillDefinition.new(&"attack_t1", &"attack", 1, 15, 25)
    assert_true(session.use_skill(attack))
    assert_eq(session.combat.energy, 7)
    assert_eq(session.combat.chain_stock, 0)
```

- [ ] **Step 2: Write failing global-clock freeze contract**

Start Line RUNNING, tick once, lock, tick once, switch to Chain, tick once. Assert Line source advanced only during first tick, Chain did not advance until explicit RUN, and `combat_time` reached 3 seconds.

- [ ] **Step 3: Run and confirm failure**

- [ ] **Step 4: Implement orchestration**

`tick(delta)` always advances CombatState and EnemyPattern. It advances only the source whose mode state is RUNNING. UI and sources cannot bypass `PocSession` to mutate resource rules.

- [ ] **Step 5: Implement local in-memory telemetry**

Record immutable copies of event payloads with Combat Clock timestamps. Do not add analytics SDK/network output.

- [ ] **Step 6: Run full suite and confirm pass**

- [ ] **Step 7: Commit**

```bash
git add src/core/poc_session.gd src/core/telemetry_log.gd tests/integration
git commit -m "feat: integrate dual-board combat session"
```

---

### Task 9: Build the one-screen Core POC UI

**Files:**
- Create: `scenes/poc_battle.tscn`
- Create: `src/ui/poc_battle.gd`
- Create: `tests/integration/test_poc_scene.gd`
- Modify: `project.godot`

**Interfaces:**
- UI reads state from `PocSession` and sends commands only.
- Persistent HUD: Player HP/Shield, Enemy HP, countdown/next action, Energy, Chain Stock, Score, active mode/state.
- Mode tabs: `LINE — Energy N`, `CHAIN — Stock N`.
- Active debug controls: Line Single/Double/Triple/4-Line buttons or Chain 1–5 Chain buttons depending on selected mode.
- RUN/LOCK toggle.
- Attack/Defense/Heal T1 buttons.

- [ ] **Step 1: Write failing scene-instantiation test**

```gdscript
extends GutTest

func test_poc_scene_instantiates() -> void:
    var packed := load("res://scenes/poc_battle.tscn")
    assert_not_null(packed)
    var scene = packed.instantiate()
    assert_not_null(scene)
    scene.free()
```

- [ ] **Step 2: Run and confirm failure**

- [ ] **Step 3: Build minimal scene hierarchy**

The UI must visually distinguish `RUNNING`, `LOCKED`, and inactive `SUSPENDED`. Destination mode never auto-runs. Disable impossible Skill buttons but preserve rejection behavior in the session API for tests.

- [ ] **Step 4: Bind debug event controls through `PocSession`**

No button may write Energy, Stock, HP or Score directly.

- [ ] **Step 5: Set scene as project main scene and run parse + tests**

```bash
godot --headless --path . --editor --quit
```

Then run full adopted GUT suite. Expected: exit 0.

- [ ] **Step 6: Commit**

```bash
git add scenes src/ui project.godot tests/integration/test_poc_scene.gd
git commit -m "feat: add core dual-board POC UI"
```

---

### Task 10: Run the 45-second validation contract

**Files:**
- Modify: `docs/validation/POC_45S_VALIDATION.md`

**Interfaces:**
- No new production behavior; produces evidence only.

- [ ] **Step 1: Record exact environment evidence**

Run and copy exact outputs into the validation document:

```bash
godot --version
git rev-parse HEAD
git status --short
```

Record the exact adopted GUT pin from the project/addon metadata.

- [ ] **Step 2: Run import/parse validation**

```bash
godot --headless --path . --editor --quit
```

Mark PASS only on exit 0 without parse errors.

- [ ] **Step 3: Run complete deterministic test suite**

Use the adopted GUT full-suite command. Record test count, pass/fail count and exit code.

- [ ] **Step 4: Run one continuous 45-second manual encounter**

Within the same encounter perform all of these:

1. Start Line in LOCKED state.
2. RUN Line and create at least one Energy event.
3. LOCK Line while Combat Clock keeps moving.
4. Switch Line→Chain and confirm Chain lands LOCKED.
5. Explicitly RUN Chain and complete at least one Chain event.
6. Use one successful Skill.
7. Attempt one Skill lacking Energy or Stock and confirm no resource mutation.
8. Allow at least one enemy action to occur while the active puzzle source is LOCKED.
9. Switch back to Line and confirm its saved state did not advance while inactive.

- [ ] **Step 5: Update every ledger status from evidence**

Required verdicts:

```text
Godot import/parse
GUT unit suite
GUT integration suite
inactive mode freeze
LOCK freeze
Combat Clock during LOCK
mode destination requires explicit RUN
Line event -> Energy
completed Chain -> non-additive Stock
Skill -> Energy + Stock consumption
insufficient-resource Skill -> no mutation
enemy schedule visible and fires on time
telemetry contains the performed transitions
```

Use only `PASS`, `FAIL`, or `NOT_RUN`, with evidence beside each item.

- [ ] **Step 6: Preserve explicit NOT_RUN scope**

Keep these as `NOT_RUN` after Core POC completion:

```text
production Line falling-piece controls and rotation/kicks
production Chain pair controls and gravity feel
true Line-vs-Chain difficulty balance
advanced Combo/B2B/Spin/Perfect Clear combat bonuses
All Clear bonus design
final top-out recovery
class roster balance
external tester validation
```

- [ ] **Step 7: Review scope diff**

```bash
git status --short
git diff --stat main...HEAD
git diff main...HEAD
```

Fail the completion gate if unrelated files changed or a user change was removed.

- [ ] **Step 8: Commit validation evidence**

```bash
git add docs/validation/POC_45S_VALIDATION.md
git commit -m "test: validate core dual-board combat POC"
```

---

## Five Full Adversarial Review Loops Applied to This Plan

### Loop 1 — false confidence from debug puzzle events

**Attack:** A debug-event POC can prove state machinery while saying nothing about whether real Line/Chain play feels good.

**Correction:** Core POC acceptance explicitly excludes puzzle feel and true Line-vs-Chain difficulty. Real engines get separate follow-up plans and their own play validation.

**Regression check:** No plan task claims production puzzle controls or balance are complete.

### Loop 2 — LOCK could remove intended difficulty

**Attack:** If LOCK freezes both puzzle and enemy time, the player gets unlimited free thinking.

**Correction:** CombatState time is advanced unconditionally by `PocSession.tick`; only the active event source checks RUNNING state.

**Regression check:** Integration test requires Combat Clock to reach 3 seconds across RUN→LOCK→switch while both puzzle sources remain appropriately frozen.

### Loop 3 — Chain Stock can create either grind or exploit

**Attack:** Additive low Chains would trivialize T5; strict non-additive Stock might make rebuilding T4/T5 too slow after spending.

**Correction:** Keep approved non-additive rule for POC and record Chain completion/Skill spend timing. Do not preemptively invent recovery mechanics.

**Regression check:** 45-second evidence must preserve this as a revisit condition rather than silently tuning the rule.

### Loop 4 — mode switching can become UI tax

**Attack:** Requiring tab switch + LOCK + RUN + Skill input may create excessive button work rather than strategy.

**Correction:** One active mode, one RUN/LOCK toggle, persistent resource labels, and Skills usable from either active state. Record mode-switch/lock/run telemetry.

**Regression check:** Revisit if 45-second test produces frequent mechanical switching without a resource/timing reason.

### Loop 5 — prototype shortcuts can contaminate production architecture

**Attack:** Debug clear/chain buttons could become hard-coded gameplay logic and make real puzzle engines expensive to attach.

**Correction:** Debug sources emit normalized events only. Combat mutations live in `PocSession`/domain objects. Real puzzle engines later implement the same event-source boundary.

**Regression check:** Tests verify source objects cannot directly own Energy/Stock/HP changes, and UI commands cannot bypass `PocSession`.

**Clean-exit result:** No remaining MUST_FIX architecture contradiction was found after the fifth loop. Remaining uncertainty is intentionally empirical: actual puzzle feel, balance, input ergonomics and top-out behavior require later runnable validation.

---

## Completion Criteria for This Plan

The Core POC is complete only when:

1. Project-local rules and exact local Godot/GUT execution evidence exist.
2. Automated domain and integration tests pass.
3. Line/Chain mode switching obeys RUNNING/LOCKED/SUSPENDED/RESOLVING rules.
4. Combat Clock continues through LOCK and switching.
5. Line events produce approved Energy values.
6. completed Chain events produce capped non-additive Stock.
7. Skills require and consume both resources correctly.
8. Attack/Defense/Heal T1 actions work.
9. Deterministic enemy actions fire on the visible schedule.
10. UI demonstrates deliberate LOCK play and continuous RUN play paths.
11. 45-second manual validation has actual evidence.
12. Remaining production puzzle-engine work stays explicitly NOT_RUN.

## Rollback Boundary

This POC must be isolated in its implementation branch/PR. If the loop proves weak, revert the POC implementation PR without reverting the already-approved GDD. If only one rule fails, change the narrow domain module and its tests; do not rewrite unrelated puzzle/UI layers.
