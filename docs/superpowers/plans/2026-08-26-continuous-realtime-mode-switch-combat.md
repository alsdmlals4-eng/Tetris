# Continuous Real-Time Mode-Switch Combat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`. Apply `superpowers:test-driven-development` for every behavior change and `superpowers:systematic-debugging` for any unexpected failure.

**Goal:** Implement `TETRIS-CORE-029 · Continuous Real-Time Mode-Switch Combat + Full Tactical Pause` as the first production-quality playable Vertical Slice: continuous enemy combat, persistent free LINE↔CHAIN switching, full Skill tactical pause, retained Energy/Stock/Tier economy, and a single large left Puzzle Surface with persistent right Combat surface.

**Architecture:** Replace ordered `LINE → CHAIN → ACTION → ENEMY` orchestration with `ProductionCombatRuntime`, `SimulationPauseController`, `PuzzleWorkspaceManager`, and `EnemyActionScheduler`. Reuse deterministic Line/Chain engines, resource state, encounter data, skill catalog/effect primitives, and current-vs-next Telegraph concepts from immutable Draft PR #19 head `28ff25b508580ece5c0611dcd7f7a41a4f649bd8`, but never merge or cherry-pick that branch wholesale. The new runtime owns continuous time and pause; puzzle engines own only puzzle state/rules; UI is a presenter, not gameplay authority.

**Tech Stack:** Godot 4.7.1-stable, GDScript, GUT 9.7.1, Python `unittest` tooling contracts, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-08-26-continuous-realtime-mode-switch-combat-design.md`

## Global Constraints

- Source branch for reusable implementation evidence: immutable PR #19 head `28ff25b508580ece5c0611dcd7f7a41a4f649bd8`.
- PR #19 remains **READ_ONLY**: no commits, rebase, close, merge, metadata rewrite, or force-update.
- Do not cherry-pick PR #19 wholesale. Copy only the files named in this plan, then immediately remove ordered-turn dependencies where this plan marks `ADAPT`.
- Start implementation on `build/realtime-mode-switch-combat` from the exact approved planning head containing this plan.
- Preserve historical CORE-024/TIME-025 documents and tests as provenance; do not rewrite old PASS receipts as CORE-029 evidence.
- No new paid dependency, runner class, marketplace credit, external SaaS, or metered service.
- No image generation/editing during this implementation workstream. Current image backlog remains paused.
- Every deterministic behavior change is RED → minimal GREEN → regression. Never add implementation before the failing contract that justifies it.
- `TUNE_REQUIRED` / `TUNING_SEED_NOT_FINAL` values are evidence labels, not permission to invent final balance. This plan supplies explicit temporary deterministic seeds where execution needs numbers.
- User-local Windows runtime, usability, fun, readability, and final balance remain `NOT_RUN` until actual receipts exist.
- Human-facing Notion may be updated after verified milestones, but GitHub code/data/tests remain runtime truth.
- Completion requires at least five whole-state adversarial review loops after exact-head automated verification; material corrections reset the clean-loop count.

## Reuse Matrix from PR #19

### `REUSE_AS_IS` or near-as-is

- Line core: `src/production/line/active_tetromino.gd`, `line_board.gd`, `line_board_break_result.gd`, `line_clear_result.gd`, `line_fall_state.gd`, `line_feel_config.gd`, `line_piece_cycle.gd`, `line_reward_config.gd`, `line_spin_recognizer.gd`, `line_streak_state.gd`, `seven_bag.gd`, `tetromino_catalog.gd`.
- Line data: `data/production/line_feel_config.json`, `line_reward_seed.json`, `line_tetrominoes.json`.
- Chain core: `src/production/chain/chain_board.gd`, `chain_randomizer.gd`, `chain_resolver.gd`.
- Resource/combat primitives: `src/production/combat/production_combat_state.gd`, `production_response_state.gd`, `production_enemy_action_resolver.gd`, `gatebreaker_action_catalog.gd`, `gatebreaker_encounter_director.gd`, `gatebreaker_telegraph_state.gd`.
- Encounter data: `data/production/gatebreaker_action_seed.json`, `gatebreaker_sequence_seed.json`.
- Skill/target primitives: `src/production/skill/production_skill_catalog.gd`, `production_effect_executor.gd`, `production_status_state.gd`, `production_technique_resolver.gd`, `src/production/targeting/target_pattern.gd`, `data/production/vanguard_skill_seed.json` with the runtime-status migration below.
- Existing Line view: `src/production/ui/production_line_board_view.gd`.

### `ADAPT`

- `src/production/line/production_line_session.gd`: remove `TurnController`, phase gating, Shared Budget, READY ownership; keep persistent board/piece/fall state and deterministic rewards.
- `src/production/chain/production_chain_session.gd`: remove turn/phase/budget ownership; expose input enable/disable, stable resolution, and reward event output.
- `src/production/skill/production_skill_session.gd`: replace ACTION-phase immediate-spend behavior with paused browse/select/detail/explicit-USE session.
- `src/production/ui/production_battle.gd`: retain useful Technique list/detail/USE presentation patterns; remove phase rail, Shared Timer, READY, Tempo, mandatory Sidecar.
- `src/production/session/production_battle_bootstrap.gd`, `production_battle_runtime_bridge.gd`, `src/production/ui/production_battle_presenter.gd`, `scenes/production/battle.tscn`: rewire around CORE-029 runtime.
- `src/production/telemetry/production_telemetry.gd`: change turn metrics into continuous timestamp/workspace/pause metrics.

### `SUPERSEDED / HISTORICAL_EVIDENCE_ONLY`

Do not port into the CORE-029 runtime:

- `src/production/turn/*`
- `src/production/combat/tempo_evaluator.gd`
- `src/production/combat/production_turn_performance_state.gd`
- `src/production/status/time_effect_state.gd`
- `data/production/time_effects.json`
- `data/production/turn_time_config.json`
- ordered-turn/Shared-Budget/Tempo integration tests and replay tests.

---

## Task 1 · Migrate structured canon to CORE-029 before runtime work

**Files:**
- Create `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md`.
- Modify `docs/design/PRODUCTION_TURN_COMBAT_CANON.md`.
- Modify `docs/design/PRODUCTION_TURN_TIME_CANON.md`.
- Modify `docs/design/PRODUCTION_CANON_INDEX.json`.
- Modify `tests/tooling/test_production_canon_contract.py`.
- Modify `AGENTS.md`.
- Modify `README.md`.

### Step 1: Write the RED tooling contract first

Change `tests/tooling/test_production_canon_contract.py` so it requires:

```python
self.assertEqual(data["schema_version"], 3)
self.assertEqual(data["current_core_decision"], "TETRIS-CORE-029")
self.assertEqual(
    data["primary_canon"],
    "docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md",
)
self.assertEqual(data["combat_time"]["model"], "CONTINUOUS_REALTIME")
self.assertTrue(data["combat_time"]["free_workspace_switching"])
self.assertEqual(data["combat_time"]["skill_mode"], "FULL_TACTICAL_PAUSE")
self.assertFalse(data["combat_time"]["shared_player_turn_budget"])
self.assertFalse(data["combat_time"]["tempo_bonus"])
self.assertFalse(data["ui"]["mandatory_sidecar"])
self.assertEqual(data["ui"]["puzzle_surface_target_ratio"], 0.60)
self.assertEqual(data["ui"]["combat_surface_target_ratio"], 0.40)
```

Also require that `continuous_enemy_combat_clock` and `free_manual_board_switching` are **not** in `superseded_contracts`, while ordered stage flow, Shared Turn Budget, READY handoff, turn timeout/PASS, and Tempo timing are.

Run:

```bash
python -m unittest tests.tooling.test_production_canon_contract -v
```

Expected: **FAIL** because the current index still declares schema 2 / CORE-024 / TIME-025 / Shared Turn Budget.

### Step 2: Implement the canonical migration

Create `PRODUCTION_REALTIME_COMBAT_CANON.md` as the structured production owner derived from the approved spec. It must explicitly own:

```text
BATTLE_START
→ COMBAT_RUNNING [LINE | CHAIN]
↔ TACTICAL_PAUSE_SKILL
→ COMBAT_RUNNING
→ VICTORY | DEFEAT
```

Define `PRODUCTION_CANON_INDEX.json` schema 3 with this shape:

```json
{
  "schema_version": 3,
  "project": "TETRIS",
  "status": "CURRENT_PRODUCTION_CANON",
  "current_core_decision": "TETRIS-CORE-029",
  "primary_canon": "docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md",
  "skill_canon": "docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md",
  "balance_canon": "docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md",
  "implementation_plan": "docs/superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md",
  "combat_time": {
    "model": "CONTINUOUS_REALTIME",
    "encounter_end": "VICTORY_OR_DEFEAT",
    "active_workspaces": ["LINE", "CHAIN"],
    "free_workspace_switching": true,
    "inactive_workspace_simulates": false,
    "skill_mode": "FULL_TACTICAL_PAUSE",
    "manual_pause": "FULL_SIMULATION_PAUSE",
    "shared_player_turn_budget": false,
    "tempo_bonus": false
  },
  "ui": {
    "puzzle_surface_target_ratio": 0.60,
    "combat_surface_target_ratio": 0.40,
    "mandatory_sidecar": false
  }
}
```

Keep SKILL-026 and BALANCE-027 as retained authorities **with explicit realtime migration boundaries**. Mark `PRODUCTION_TURN_COMBAT_CANON.md` and `PRODUCTION_TURN_TIME_CANON.md` at the top as historical/superseded by CORE-029; do not delete their bodies.

Update `AGENTS.md`/`README.md` so the first current authority is `PRODUCTION_REALTIME_COMBAT_CANON.md`, and remove player-facing claims that Shared Turn Budget/READY/Tempo are current.

### Step 3: Verify GREEN

Run:

```bash
python -m unittest discover -s tests/tooling -p 'test_*.py' -v
```

Expected: **PASS** with CORE-029 machine routing and all unrelated tooling contracts intact.

### Step 4: Commit

```bash
git add docs/design tests/tooling/test_production_canon_contract.py AGENTS.md README.md
git commit -m "docs: migrate production canon to realtime combat"
```

---

## Task 2 · Port deterministic Line core without old turn ownership

**Files:**
- Copy from PR #19 head the Line core/data files listed in the reuse matrix.
- Copy `tests/production/line/*` from PR #19 head.
- Adapt `src/production/line/production_line_session.gd`.
- Add `tests/production/runtime/test_realtime_line_session.gd`.

### Step 1: Restore tests and core from the immutable source SHA

Use a read-only source restore, never checkout PR #19:

```bash
git restore --source=28ff25b508580ece5c0611dcd7f7a41a4f649bd8 -- \
  src/production/line \
  data/production/line_feel_config.json \
  data/production/line_reward_seed.json \
  data/production/line_tetrominoes.json \
  tests/production/line
```

Immediately add a new RED runtime contract requiring the session to have no `TurnController` dependency and to preserve its active piece, queue/Hold, fall state, gravity accumulator, grounded time, and lock-reset count when input is disabled/re-enabled.

Required session surface:

```gdscript
var input_enabled: bool = true
func set_input_enabled(enabled: bool) -> void
func can_accept_input() -> bool
func tick(delta: float, soft_drop: bool = false) -> Dictionary
func snapshot_runtime_state() -> Dictionary
```

`set_input_enabled(false)` must only stop input/ticking. It must not rebuild board, respawn a piece, reset `LineFallState`, or reroll `LinePieceCycle`.

### Step 2: Run RED

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/production/line -ginclude_subdirs -gexit
```

Expected: existing Line tests are mostly reusable, while the new realtime session contract fails because the copied session still depends on `TurnController` / `TurnPhase.LINE` / Shared Budget / READY.

### Step 3: Minimal adaptation

Refactor `ProductionLineSession` so puzzle state remains owned by the same long-lived object. Remove phase progression and READY methods from active runtime usage. Do not alter the deterministic Line rules already covered by tests.

### Step 4: GREEN and regression

Run Line tests plus the realtime session test. Then run the full GUT suite available on the branch.

Expected: all imported Line core tests pass; the runtime test proves disable→enable is state-preserving.

### Step 5: Commit

```bash
git add src/production/line data/production/line_* tests/production/line tests/production/runtime/test_realtime_line_session.gd
git commit -m "feat: port persistent realtime line workspace"
```

---

## Task 3 · Port Chain core and close the existing deterministic RED contracts

**Files:**
- Copy `src/production/chain/chain_board.gd`.
- Copy `src/production/chain/chain_randomizer.gd`.
- Copy `src/production/chain/chain_resolver.gd`.
- Copy/adapt `src/production/chain/production_chain_session.gd`.
- Copy `tests/production/chain/*`.
- Create `src/production/chain/production_chain_config.gd`.
- Create `data/production/chain_runtime_seed.json`.
- Add `tests/production/runtime/test_realtime_chain_session.gd`.

### Step 1: Restore source/tests

```bash
git restore --source=28ff25b508580ece5c0611dcd7f7a41a4f649bd8 -- \
  src/production/chain \
  tests/production/chain
```

### Step 2: Confirm the inherited RED contract

Run:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/production/chain -ginclude_subdirs -gexit
```

Expected failures are specifically:

- missing `ChainBoard.has_available_swap()`;
- missing `ChainRandomizer.fill_playable_board()`;
- missing `ProductionChainConfig`;
- missing `data/production/chain_runtime_seed.json`.

Do not suppress or delete these tests.

### Step 3: Implement playable-board detection without mutation

`ChainBoard.has_available_swap()` must test each right/down adjacent pair, use the existing swap/match rules, and restore the exact original snapshot before returning.

### Step 4: Implement deterministic playable fill

`ChainRandomizer.fill_playable_board(board, max_attempts := 128)` must:

1. preserve the original board snapshot;
2. repeatedly call stable seeded fill;
3. accept only a board with zero starting matches and `has_available_swap() == true`;
4. restore the original board and return `false` after the attempt limit.

Identical seed/palette/board shape must produce identical accepted boards.

### Step 5: Implement explicit Chain runtime seed/config

Create:

```json
{
  "balance_status": "TUNING_SEED_NOT_FINAL",
  "seed_source": "HISTORICAL_FOUNDATION_CHAIN_DEPTH_MAPPING_ADAPTED_TO_PRODUCTION_CAP_6",
  "board": {
    "width": 8,
    "height": 8,
    "palette": ["R", "G", "B", "Y", "P", "C"],
    "random_seed": 54321
  },
  "stock_by_chain_depth": {
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "6": 6
  }
}
```

`ProductionChainConfig.from_dictionary()` must fail closed on missing/invalid shape. `stock_for_resolution()` returns 0 for failed/missing/negative depth and clamps successful positive depth to Stock cap 6.

### Step 6: Adapt the Chain session for persistent realtime ownership

Required surface:

```gdscript
var input_enabled: bool = true
func set_input_enabled(enabled: bool) -> void
func can_accept_input() -> bool
func begin_swap(a: Vector2i, b: Vector2i) -> Dictionary
func is_resolving() -> bool
func complete_pending_resolution() -> Dictionary
func snapshot_runtime_state() -> Dictionary
```

The session must not own TurnPhase, Shared Budget, or READY. It returns a deterministic reward event such as:

```gdscript
{
  "success": true,
  "chain_depth": 3,
  "stock_requested": 3,
  "board_snapshot": [...]
}
```

It does not directly spend or grant combat resources; `ProductionCombatRuntime` will apply the event once.

### Step 7: GREEN

Run Chain tests and the realtime Chain session test. Expected: the previous 8 exact-head PR #19 failures are closed in the new branch without mutating PR #19.

### Step 8: Commit

```bash
git add src/production/chain data/production/chain_runtime_seed.json tests/production/chain tests/production/runtime/test_realtime_chain_session.gd
git commit -m "feat: port deterministic realtime chain workspace"
```

---

## Task 4 · Add tokenized full-simulation pause authority

**Files:**
- Create `src/production/runtime/simulation_pause_controller.gd`.
- Create `tests/production/runtime/test_simulation_pause_controller.gd`.

### Step 1: RED contract

Required interface:

```gdscript
class_name SimulationPauseController
extends RefCounted

func acquire(reason: String) -> int
func release(token: int) -> bool
func is_paused() -> bool
func has_reason(reason: String) -> bool
func active_reasons() -> Array[String]
```

Reasons used by this slice:

```text
TACTICAL_SKILL
SYSTEM_MENU
RUNTIME_TRANSITION
```

Tests must prove:

- first token pauses;
- multiple reasons coexist;
- releasing one token never resumes while another token remains;
- duplicate reason tokens are independent;
- unknown/repeated release fails closed;
- no gameplay system can directly clear all pause reasons.

Run runtime tests; expected **FAIL** because controller does not exist.

### Step 2: Minimal GREEN

Implement monotonic integer tokens and a token→reason map. Do not directly call SceneTree pause from this pure domain object; `ProductionCombatRuntime`/scene bridge applies the effective pause state.

### Step 3: Verify and commit

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/production/runtime -ginclude_subdirs -gexit
git add src/production/runtime tests/production/runtime
git commit -m "feat: add tokenized simulation pause authority"
```

---

## Task 5 · Implement persistent LINE↔CHAIN workspace switching

**Files:**
- Create `src/production/runtime/puzzle_workspace_manager.gd`.
- Create `tests/production/runtime/test_puzzle_workspace_manager.gd`.
- Modify the two adapted session files only as needed for handoff queries.

### Step 1: RED invariants

Required surface:

```gdscript
class_name PuzzleWorkspaceManager
extends RefCounted

const LINE := "LINE"
const CHAIN := "CHAIN"

func active_workspace() -> String
func request_switch(target: String) -> Dictionary
func process_safe_handoff() -> Dictionary
func is_switch_pending() -> bool
func line_input_enabled() -> bool
func chain_input_enabled() -> bool
```

Tests must prove the exact user-approved invariant:

```text
LINE state A
→ CHAIN
→ CHAIN state B
→ LINE = exact A continuation
→ CHAIN = exact B continuation
```

Also prove rapid repeated switch requests cannot:

- reset Line gravity/grounded/lock counters;
- reroll Line Hold/Next;
- reroll Chain RNG/refill state;
- duplicate Energy/Stock reward events;
- pause or own enemy time.

Chain handoff remains pending while a committed resolution is unresolved; once stable, switch completes. Line handoff occurs after the current synchronous atomic input/tick returns; it never forces a placement merely because a switch was requested.

### Step 2: Implement minimal manager

Keep **the same session objects alive**. Switching changes only input authority/visibility owner; do not serialize/reconstruct sessions as the normal path.

### Step 3: GREEN and commit

Run Line, Chain, and runtime workspace tests.

```bash
git add src/production/runtime/puzzle_workspace_manager.gd src/production/line/production_line_session.gd src/production/chain/production_chain_session.gd tests/production/runtime
git commit -m "feat: preserve puzzle state across free mode switching"
```

---

## Task 6 · Port combat/resource primitives and implement the realtime Gatebreaker scheduler

**Files:**
- Restore reusable combat files from PR #19 listed above.
- Restore `data/production/gatebreaker_action_seed.json` and `gatebreaker_sequence_seed.json`.
- Create `src/production/runtime/enemy_action_scheduler.gd`.
- Create `src/production/runtime/gatebreaker_realtime_timing_config.gd`.
- Create `data/production/gatebreaker_realtime_timing_seed.json`.
- Create `tests/production/runtime/test_enemy_action_scheduler.gd`.
- Restore compatible combat unit tests: action catalog, encounter director/preview, telegraph state, enemy resolver, combat state.

### Step 1: RED scheduler contract

Use a deterministic nonfinal seed:

```json
{
  "balance_status": "TUNING_SEED_NOT_FINAL",
  "commit_lead_seconds": 0.0,
  "action_seconds": {
    "light_smash": 8.0,
    "gatebreaker_slam": 12.0,
    "rift_siphon": 10.0,
    "chain_fracture": 10.0,
    "rift_repair": 9.0,
    "siege_charge": 14.0
  }
}
```

`commit_lead_seconds = 0.0` intentionally makes first-slice commit and resolution deadline identical, eliminating an ambiguous precommitted-but-paused animation state. These seconds are deterministic test seeds, not final balance.

Required scheduler surface:

```gdscript
func start() -> Dictionary
func tick_simulation(delta: float, context: Dictionary) -> Array[Dictionary]
func current_action_id() -> String
func next_action_id() -> String
func remaining_seconds() -> float
func is_action_committed() -> bool
```

Tests must prove:

- ETA decreases only when `tick_simulation()` is called;
- action resolves exactly once at zero;
- next authored action advances afterward;
- current action cannot secretly retarget from player resources/workspace;
- deterministic same seed/sequence produces deterministic action order/ETA;
- with zero commit lead, Skill-open processed before a runtime tick can pause an action at 0<ETA, but cannot undo an action already resolved by a previous tick.

### Step 2: Implement and verify

`EnemyActionScheduler` composes the existing catalog/director/telegraph/resolver; it does not recreate their rules.

Run combat + runtime scheduler tests.

### Step 3: Commit

```bash
git add src/production/combat src/production/runtime data/production/gatebreaker_* tests/production/combat tests/production/runtime
git commit -m "feat: schedule authored enemy actions in realtime"
```

---

## Task 7 · Port skill primitives and make Skill a full tactical-pause session

**Files:**
- Restore skill/target files and compatible tests from PR #19.
- Modify `data/production/vanguard_skill_seed.json`.
- Adapt/replace `src/production/skill/production_skill_session.gd`.
- Modify `src/production/skill/production_skill_catalog.gd` only if validation must accept `runtime_status`.
- Modify `src/production/skill/production_technique_resolver.gd` / `production_effect_executor.gd` to remove active Tempo/next-turn execution paths from CORE-029.
- Create `tests/production/runtime/test_tactical_skill_session.gd`.

### Step 1: Freeze unresolved turn-bound Technique semantics instead of inventing them

Add a per-Technique `runtime_status` field.

For the first CORE-029 slice:

- `sup_t3_haste` → `REALTIME_MIGRATION_REQUIRED`.
- `sup_t6_battle_trance` → `REALTIME_MIGRATION_REQUIRED`.
- `sup_t4_mark_weakness` keeps its existing unresolved effect-contract gate and remains unavailable until its existing contract becomes executable.
- Other Techniques remain eligible only if all of their effects are event-bound/current-or-visible-forecast-bound and the existing resolver can fully preflight them.

Do not reinterpret Haste as realtime seconds, cooldown speed, enemy slow, or puzzle speed. Do not reinterpret Battle Trance into a duration. Do not run Tempo scaling.

### Step 2: RED session contract

Required session behavior:

```gdscript
func open() -> bool
func select_category(category: String) -> bool
func select_technique(technique_id: String) -> Dictionary
func selected_detail() -> Dictionary
func readiness(technique_id: String, context: Dictionary) -> Dictionary
func commit_selected(context: Dictionary) -> Dictionary
func cancel() -> Dictionary
```

Selecting a row must not mutate HP/Energy/Stock/statuses and must not release pause. Only `commit_selected()` after explicit USE may spend resources/apply effects.

Tests prove:

- opening acquires `TACTICAL_SKILL` pause token;
- browsing/selection leaves simulation paused and resources unchanged;
- cancel releases only its own tactical token;
- system-menu token coexisting with tactical token keeps simulation paused after Skill closes;
- unresolved realtime Techniques return the explicit migration/error reason and cannot spend resources;
- insufficient Energy/Stock never partially applies effects;
- successful USE spends configured Energy + Stock exactly once, applies effect once, then releases tactical pause and restores the previous puzzle workspace.

### Step 3: Atomicity boundary

Before spending resources, `ProductionTechniqueResolver` must complete deterministic preflight for **all** effects and targets. Once preflight succeeds, resource spend and effect execution occur in one runtime command; known invalid/no-op conditions must be rejected during preflight rather than after partial mutation.

### Step 4: GREEN and commit

Run skill, targeting, combat, and runtime tactical-pause tests.

```bash
git add src/production/skill src/production/targeting data/production/vanguard_skill_seed.json tests/production/skill tests/production/targeting tests/production/runtime
git commit -m "feat: make skill selection a full tactical pause"
```

---

## Task 8 · Build `ProductionCombatRuntime` as the only continuous-time orchestrator

**Files:**
- Create `src/production/runtime/production_combat_runtime.gd`.
- Create `tests/production/integration/test_realtime_combat_runtime.gd`.
- Do **not** port old `production_battle_session.gd`, TurnController, TurnBudget, TempoEvaluator.

### Step 1: RED integration contract

Required high-level interface:

```gdscript
func start_battle() -> Dictionary
func process_player_command(command: Dictionary) -> Dictionary
func tick(delta: float) -> Array[Dictionary]
func open_skill() -> Dictionary
func close_skill_without_use() -> Dictionary
func is_simulation_paused() -> bool
func is_terminal() -> bool
func snapshot() -> Dictionary
```

Frame ordering is fixed:

```text
1. receive player input commands, including SKILL open
2. apply pause/workspace command state
3. if simulation paused: do not advance puzzle/enemy/status simulation
4. if running: tick active puzzle + enemy scheduler using the same delta
5. commit puzzle resource events once
6. resolve terminal Victory/Defeat
7. publish snapshot/events for presenter/telemetry
```

Tests must prove:

- enemy ETA decreases while LINE and while CHAIN;
- enemy ETA does not decrease during Skill or manual pause;
- inactive puzzle does not simulate;
- active puzzle does simulate;
- switching workspaces does not alter enemy ETA except normal elapsed delta;
- LINE clear grants Energy once;
- CHAIN resolution grants Stock once and caps at 6;
- opening Skill before scheduler tick freezes that frame's scheduler progression;
- use/cancel resumes from exact ETA/puzzle state;
- player/enemy HP terminal states end the encounter without hidden turn transitions.

### Step 2: Implement minimal orchestrator

The runtime holds references to `SimulationPauseController`, `PuzzleWorkspaceManager`, `EnemyActionScheduler`, `ProductionCombatState`, and tactical Skill session. It does not contain puzzle rule calculations or UI node access.

### Step 3: GREEN and commit

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/production/integration -ginclude_subdirs -gexit
git add src/production/runtime tests/production/integration/test_realtime_combat_runtime.gd
git commit -m "feat: orchestrate continuous realtime puzzle combat"
```

---

## Task 9 · Rebuild battle UI around one 60/40 mode-switch surface

**Files:**
- Adapt `scenes/production/battle.tscn`.
- Adapt `src/production/ui/production_battle.gd`.
- Replace/adapt `src/production/ui/production_battle_presenter.gd`.
- Reuse `src/production/ui/production_line_board_view.gd`.
- Create `src/production/ui/production_chain_board_view.gd`.
- Replace/adapt `src/production/session/production_battle_runtime_bridge.gd`.
- Create/replace UI tests under `tests/production/ui/`.
- Modify `project.godot` input actions only; do not switch main scene yet.

### Step 1: RED scene/presenter contract

Required scene hierarchy:

```text
Battle
└─ MainRow
   ├─ PuzzleColumn          # target ~60%
   │  ├─ ModeBar            # LINE | CHAIN | SKILL
   │  └─ PuzzleHost
   │     ├─ LineBoardView
   │     └─ ChainBoardView
   └─ CombatColumn          # target ~40%
      ├─ ThreatPanel        # current ETA + next forecast
      ├─ CombatStage
      ├─ ResourceBar        # HP / Energy / Stock
      └─ SkillPanel         # compact closed; interactive when tactical pause open
```

At 1280×720, automated layout tests require PuzzleColumn ratio within `0.56..0.64`, CombatColumn the remainder, and only one puzzle view visible/input-active.

The closed running HUD must contain no current-production `Shared Turn Timer`, `READY`, phase rail, `PASS`, `Tempo`, or mandatory inactive-board Sidecar.

Skill-open state must visibly show `TACTICAL PAUSE`, leave the frozen puzzle readable, preserve Current Telegraph/ETA context, and expose `ATK/DEF/SUP → T1–T6 → detail → USE`.

### Step 2: Named input actions

Add named actions in `project.godot`, for example:

```text
workspace_line
workspace_chain
open_skill
pause_game
```

Keep existing Line movement/rotate/drop/Hold actions. `production_battle_runtime_bridge.gd` reads named actions, not physical keycodes, and submits commands to `ProductionCombatRuntime`.

### Step 3: Implement Chain board presentation

`ProductionChainBoardView` renders the 8×8 snapshot and selection/match feedback needed by the current interactive Chain session. It must not own swap legality or resource rewards.

### Step 4: GREEN

Run UI scene/presenter/live-surface tests at 1280×720 plus runtime integration tests.

### Step 5: Commit

```bash
git add scenes/production/battle.tscn src/production/ui src/production/session/production_battle_runtime_bridge.gd project.godot tests/production/ui
git commit -m "feat: build 60-40 realtime battle interface"
```

---

## Task 10 · Add continuous telemetry and remove turn-speed evidence from current runtime

**Files:**
- Restore/adapt `src/production/telemetry/production_telemetry.gd`.
- Restore/adapt `tests/production/telemetry/test_production_telemetry.gd`.
- Create `tests/production/telemetry/test_realtime_combat_telemetry.gd`.

### Step 1: RED telemetry contract

Required event families:

```text
BATTLE_STARTED
WORKSPACE_ENTERED
WORKSPACE_EXITED
WORKSPACE_SWITCH_REQUESTED
WORKSPACE_SWITCH_COMMITTED
LINE_REWARD
CHAIN_REWARD
TACTICAL_PAUSE_OPENED
TACTICAL_PAUSE_CLOSED
SYSTEM_PAUSE_OPENED
SYSTEM_PAUSE_CLOSED
TECHNIQUE_USED
ENEMY_TELEGRAPH_STARTED
ENEMY_ACTION_RESOLVED
BOARD_BREAK
VICTORY
DEFEAT
```

Every gameplay event receives `simulation_time_seconds`. Pause events additionally record wall-clock duration separately. Summary must expose:

```text
wall_clock_encounter_duration
active_simulation_duration
line_residency_duration
chain_residency_duration
tactical_pause_duration
manual_pause_duration
workspace_switch_count
technique_use_count
```

Current CORE-029 telemetry must not calculate Tempo reward or use wall-clock reading time as performance speed.

### Step 2: Implement and verify

Use runtime-published events; telemetry never drives gameplay decisions.

### Step 3: Commit

```bash
git add src/production/telemetry tests/production/telemetry
git commit -m "feat: record continuous combat telemetry"
```

---

## Task 11 · Rebuild bootstrap, make Production battle launchable, then change branch main scene

**Files:**
- Replace/adapt `src/production/session/production_battle_bootstrap.gd`.
- Create/adapt `src/production/session/production_battle_coordinator.gd` only if a thin scene-facing façade is still useful; it must not recreate TurnController semantics.
- Modify `project.godot` `run/main_scene` to `res://scenes/production/battle.tscn` **on the build branch only**.
- Update `tests/production/ui/test_production_battle_bootstrap.gd` and relevant bootstrap/scene tests.

### Step 1: RED bootstrap contract

Bootstrap must construct:

```text
ProductionCombatState
Line session
Chain config + Chain session
SimulationPauseController
PuzzleWorkspaceManager
Gatebreaker catalog/director/telegraph/resolver
EnemyActionScheduler
Skill catalog/status/response/effect/resolver/session
ProductionCombatRuntime
Telemetry
Presenter/runtime bridge
```

It must not instantiate `TurnController`, `TurnBudget`, `TempoEvaluator`, or `TimeEffectState` for CORE-029 gameplay.

### Step 2: Implement bootstrap and scene startup

The initial visible workspace is LINE. CHAIN exists with deterministic playable seeded state but remains hidden/input-off until selected. Enemy scheduler begins on battle start. Skill starts closed.

### Step 3: Branch-only main-scene switch

After automated bootstrap/runtime/UI tests are green, change:

```ini
run/main_scene="res://scenes/production/battle.tscn"
```

Do not claim user-playable PASS from this file change alone.

### Step 4: Verify import/parse + GUT

```bash
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests -ginclude_subdirs -gexit
```

Expected: no script parse/import errors and full applicable suite GREEN. Historical tests that are intentionally not copied from PR #19 are not part of this new branch's claimed runtime contract.

### Step 5: Commit

```bash
git add src/production/session project.godot tests/production/ui
git commit -m "feat: launch production realtime battle slice"
```

---

## Task 12 · CI, runtime evidence, adversarial review, and PR closeout gate

**Files/Surfaces:**
- `.github/workflows/core-poc-ci.yml` only if the existing workflow needs path/name wording adjustment; keep the pinned Godot/GUT versions and zero-incremental-cost runner class.
- `docs/validation/` CORE-029 receipts if project conventions require committed evidence.
- Notion Home / Production Handoff / Validation pages after evidence exists.
- Current implementation PR created from `build/realtime-mode-switch-combat`.

### Step 1: Exact-head automated verification

Run locally/CI-equivalent:

```bash
python -m unittest discover -s tests/tooling -p 'test_*.py' -v
pwsh ./tools/windows/start_tetris_local_executor.ps1 -StaticSelfTest
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests -ginclude_subdirs -gexit
```

Then push the exact build head and require GitHub Actions GREEN. Do not reuse PR #19's older green runs or its current RED run as CORE-029 evidence.

### Step 2: Required automated CORE-029 acceptance set

Automated evidence must prove all of:

1. continuous enemy ETA advances in LINE and CHAIN;
2. LINE and CHAIN states survive repeated switches exactly;
3. switching does not reset gravity/lock/Hold/Next/RNG or duplicate rewards;
4. inactive workspace does not simulate;
5. Skill tactical pause freezes enemy ETA, both puzzle simulations, status/cooldown simulation, and runtime animation-driving simulation clocks;
6. system pause and tactical pause tokens compose safely;
7. explicit USE is the only Technique spend/commit path;
8. Current/Next Telegraph-bound statuses remain attached to exact authored action IDs;
9. unresolved turn-bound Techniques fail closed;
10. 60/40 UI has one active puzzle surface and persistent right threat/resource/combat surface;
11. Production scene boots from the build branch without old TurnController/Shared Budget/Tempo ownership;
12. Victory/Defeat terminate the continuous encounter deterministically.

### Step 3: User-local / Human evidence remains a separate gate

After automated GREEN, run an actual user-facing Windows session when authorized and record separately:

- can the player understand LINE↔CHAIN switching without Sidecar;
- does returning to each board visibly preserve state;
- is Current Telegraph/ETA readable while focused on the large puzzle;
- does full Skill pause feel intentional rather than like a freeze/bug;
- can the player explain why they switched to LINE, CHAIN, or Skill at key threat moments;
- does 60/40 preserve puzzle readability and combat awareness;
- does Energy vs Stock/Tier remain understandable;
- is the real-time pressure fair enough to continue tuning rather than redesign immediately.

Until receipts exist, keep:

```text
USER_WINDOWS_RUNTIME = NOT_RUN
HUMAN_USABILITY = NOT_RUN
PLAYER_EXPERIENCE = NOT_RUN
FINAL_BALANCE = NOT_RUN
```

### Step 4: Five whole-state adversarial loops

Run five complete loops after exact-head verification:

1. **Authority loop:** CORE-029 routing, no accidental CORE-024/TIME-025 current claims, PR #19 unchanged.
2. **Exploit/determinism loop:** switch spam, pause stacking, reward duplication, RNG/gravity resets, same-frame Skill/enemy deadline.
3. **Architecture loop:** puzzle rules remain inside puzzle systems; UI/telemetry do not become gameplay authority; no hidden TurnController resurrection.
4. **UX/IRG loop:** 60/40 single-surface semantics, threat readability, tactical-pause communication, no claim beyond automated/human evidence.
5. **Maintainability/cost loop:** selective reuse is smaller than rewrite, no paid dependency, no unnecessary class/boss/biome scope, reversible PR isolation.

Any material fix resets the clean-loop count and requires exact-head verification again.

### Step 5: Compare against main and protect old PR

Before closeout:

```bash
git diff --stat main...HEAD
git log --oneline main..HEAD
```

Also live-read PR #19 and verify head remains `28ff25b508580ece5c0611dcd7f7a41a4f649bd8` unless the user independently changed it. If it moved externally, record the drift; do not rewrite it.

### Step 6: PR / Notion closeout

Only after exact-head automated GREEN and clean adversarial review:

- update the CORE-029 implementation PR with evidence and remaining Human gates;
- keep it Draft until required project review gate is satisfied;
- update Notion human-facing current state and read back destination pages;
- do not merge merely because automated tests pass if the current project contract requires user/player evidence before merge;
- if merged later, verify post-merge `main`, post-merge CI, and structured canon readback before declaring the workstream complete.

---

## Execution Order Summary

```text
1. CORE-029 structured canon
2. persistent Line core
3. deterministic Chain core + close inherited RED
4. tokenized full pause
5. persistent workspace switching
6. realtime enemy scheduler
7. tactical-pause Skill session
8. continuous combat runtime
9. 60/40 UI + named input bridge
10. continuous telemetry
11. production bootstrap + branch main scene
12. exact-head CI + human gate + 5-loop adversarial closeout
```

This order is intentional. Do not begin with UI or by adapting the old coordinator: doing so would make the superseded TurnController/Shared Budget architecture the temporary skeleton and create avoidable rework.