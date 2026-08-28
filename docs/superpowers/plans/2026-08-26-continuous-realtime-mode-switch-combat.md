# Continuous Real-Time Mode-Switch Combat Implementation Plan

> **TETRIS-CHAIN-038 amendment · 2026-08-28 · Phase 2 review required before BUILD:** The user-approved player contract is `LINE → MP` and `CHAIN → one shared Combo resource`, where MP/Combo map to the current implementation fields `energy`/`stock` rather than forming a third resource. CHAIN swaps remain orthogonal, but a valid run is a straight horizontal, vertical, down-right diagonal, or down-left diagonal run of 3+ equal symbols. Each resolved wave gives Combo +1 (cap 10), then recovers MP by `(sum maximal qualified line lengths − 3) + post-wave Combo`; the same stored Combo may instead be spent on Tier Skills. A no-match restores and resets Combo; fixed 1 MP may retain that failed swap but also resets Combo and gives no immediate reward. The merged runtime currently implements only horizontal/vertical matching, default restore, cap-6 cascade-depth Combo reward, and no CHAIN MP recovery. Therefore Task 3 and every affected resource/UI/telemetry/test step below require a bounded Phase 2 contract amendment and fresh exact-head review; this historical plan alone does **not** authorize the diagonal matcher, MP-lock, Combo cap/reset, or CHAIN-MP implementation.

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`. For every deterministic behavior change, use `superpowers:test-driven-development`; for any unexpected failure, use `superpowers:systematic-debugging` before proposing a fix.

**Goal:** Implement `TETRIS-CORE-029 · Continuous Real-Time Mode-Switch Combat + Full Tactical Pause` as the first production-quality playable Vertical Slice: continuous enemy combat, persistent free `LINE ↔ CHAIN` switching, full Skill tactical pause, retained Energy/Chain Stock/Tier economy, and a single large left Puzzle Surface with a persistent right Combat surface.

**Architecture:** Replace ordered `LINE → CHAIN → ACTION → ENEMY` orchestration with four owners: `ProductionCombatRuntime`, `SimulationPauseController`, `PuzzleWorkspaceManager`, and `EnemyActionScheduler`. Selectively reuse deterministic Line/Chain engines, resource state, Gatebreaker data, and skill primitives from immutable Draft PR #19 head `28ff25b508580ece5c0611dcd7f7a41a4f649bd8`; never merge or cherry-pick that branch wholesale. Runtime owns continuous simulation/time. Puzzle modules own puzzle rules/state only. Skill selection owns paused decision state only. UI/telemetry read runtime state and never become gameplay authority.

**Tech Stack:** Godot `4.7.1-stable`, GDScript, GUT `9.7.1`, Python `unittest` tooling contracts, GitHub Actions.

**Approved Spec:** `docs/superpowers/specs/2026-08-26-continuous-realtime-mode-switch-combat-design.md`

## Global Constraints

- Start implementation on `build/realtime-mode-switch-combat` from the exact planning head that contains this plan.
- PR #19 remains **READ_ONLY**. No commits, rebase, close, merge, metadata mutation, force-update, or branch takeover.
- PR #19 head `28ff25b508580ece5c0611dcd7f7a41a4f649bd8` is a read-only source snapshot only.
- Never cherry-pick PR #19 wholesale. Copy only files named below, then remove old turn dependencies immediately where marked `ADAPT`.
- Preserve CORE-024/TIME-025 docs/tests as historical provenance. Never rewrite old PASS evidence as CORE-029 evidence.
- No new paid dependency, runner class, marketplace credit, SaaS, metered API, or additional paid asset dependency.
- No image generation/editing in this implementation workstream. Current image backlog stays paused.
- `TUNE_REQUIRED` and `TUNING_SEED_NOT_FINAL` are explicit evidence/tuning states, not missing implementation instructions.
- User-local Windows runtime, usability, fun, first-exposure comprehension, and final balance remain `NOT_RUN` until actual receipts exist.
- Completion requires exact-head verification plus at least five whole-state adversarial review loops. A material correction resets the clean-loop count.

## Reuse Classification from PR #19

### REUSE_AS_IS / near-as-is

- Line core: `active_tetromino.gd`, `line_board.gd`, `line_board_break_result.gd`, `line_clear_result.gd`, `line_fall_state.gd`, `line_feel_config.gd`, `line_piece_cycle.gd`, `line_reward_config.gd`, `line_spin_recognizer.gd`, `line_streak_state.gd`, `seven_bag.gd`, `tetromino_catalog.gd`.
- Line data: `line_feel_config.json`, `line_reward_seed.json`, `line_tetrominoes.json`.
- Chain core: `chain_board.gd`, `chain_randomizer.gd`, `chain_resolver.gd`.
- Combat/resource: `production_combat_state.gd`, `production_response_state.gd`, `production_enemy_action_resolver.gd`, `gatebreaker_action_catalog.gd`, `gatebreaker_encounter_director.gd`, `gatebreaker_telegraph_state.gd`.
- Encounter data: `gatebreaker_action_seed.json`, `gatebreaker_sequence_seed.json`.
- Skill/target primitives: `production_skill_catalog.gd`, `production_effect_executor.gd`, `production_status_state.gd`, `production_technique_resolver.gd`, `target_pattern.gd`, `vanguard_skill_seed.json` with migration flags below.
- Existing Line view: `production_line_board_view.gd`.

### ADAPT

- `production_line_session.gd`: remove `TurnController`, `TurnPhase`, Shared Budget, READY; keep long-lived board/piece/fall/queue/Hold state.
- `production_chain_session.gd`: remove phase/budget/READY ownership; expose stable resolution and reward events.
- `production_skill_session.gd`: replace ACTION-phase immediate-spend behavior with paused browse/select/detail/explicit-USE.
- `production_battle.gd`, `production_battle_presenter.gd`, `production_battle_runtime_bridge.gd`, `production_battle_bootstrap.gd`, `production_battle_coordinator.gd`, `battle.tscn`: rewire around CORE-029.
- `production_telemetry.gd`: replace turn/Tempo metrics with continuous simulation/workspace/pause metrics.

### SUPERSEDED / HISTORICAL_EVIDENCE_ONLY

Do not port into the active CORE-029 runtime:

- `src/production/turn/*`
- `tempo_evaluator.gd`
- `production_turn_performance_state.gd`
- `time_effect_state.gd`
- `time_effects.json`
- `turn_time_config.json`
- ordered-turn/Shared-Budget/Tempo integration and replay tests.

---

## Task 1 · Migrate all current authority/evidence contracts to CORE-029 before runtime code

**Files:**
- Create `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md`.
- Modify `docs/design/PRODUCTION_TURN_COMBAT_CANON.md`.
- Modify `docs/design/PRODUCTION_TURN_TIME_CANON.md`.
- Modify `docs/design/PRODUCTION_CANON_INDEX.json`.
- Modify `tests/tooling/test_production_canon_contract.py`.
- Modify `AGENTS.md`.
- Modify `README.md`.
- Modify `docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md`.
- Modify `docs/validation/PRODUCTION_HUMAN_EVIDENCE_INDEX.json` if present.
- Modify `tests/tooling/test_human_evidence_contract.py`.

### 1A · RED: structured canon contract

First change `test_production_canon_contract.py` to require:

```python
self.assertEqual(data["schema_version"], 3)
self.assertEqual(data["current_core_decision"], "TETRIS-CORE-029")
self.assertEqual(data["primary_canon"], "docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md")
self.assertEqual(data["combat_time"]["model"], "CONTINUOUS_REALTIME")
self.assertTrue(data["combat_time"]["free_workspace_switching"])
self.assertFalse(data["combat_time"]["inactive_workspace_simulates"])
self.assertEqual(data["combat_time"]["skill_mode"], "FULL_TACTICAL_PAUSE")
self.assertEqual(data["combat_time"]["manual_pause"], "FULL_SIMULATION_PAUSE")
self.assertFalse(data["combat_time"]["shared_player_turn_budget"])
self.assertFalse(data["combat_time"]["tempo_bonus"])
self.assertFalse(data["ui"]["mandatory_sidecar"])
self.assertEqual(data["ui"]["puzzle_surface_target_ratio"], 0.60)
self.assertEqual(data["ui"]["combat_surface_target_ratio"], 0.40)
```

Require `continuous_enemy_combat_clock` and `free_manual_board_switching` to be removed from `superseded_contracts`. Require ordered stages, Shared Turn Budget, READY handoff, turn timeout/PASS, and Tempo timing to be added as superseded contracts.

Run:

```bash
python -m unittest tests.tooling.test_production_canon_contract -v
```

Expected: **FAIL** against current schema 2 / CORE-024 / TIME-025 routing.

### 1B · RED: Human evidence contract migration

Change `test_human_evidence_contract.py` so the current Human gate requires these CORE-029 dimensions instead of Shared Turn Budget:

```text
REALTIME_THREAT_READABILITY
WORKSPACE_SWITCH_COMPREHENSION
WORKSPACE_STATE_PERSISTENCE
TACTICAL_PAUSE_COMPREHENSION
LINE_ENERGY_VS_CHAIN_STOCK
TECHNIQUE_DECISION_QUALITY
SIXTY_FORTY_LAYOUT_READABILITY
PLAYER_EXPERIENCE_SIGNAL
```

Keep the existing three-independent-first-exposure receipt floor for a positive directional PASS and keep Human status `NOT_RUN` until real receipts exist.

Run:

```bash
python -m unittest tests.tooling.test_human_evidence_contract -v
```

Expected: **FAIL** because the existing Human contract still names Shared Turn Budget/ordered-turn dimensions.

### 1C · GREEN: write current realtime canon

`PRODUCTION_REALTIME_COMBAT_CANON.md` owns:

```text
BATTLE_START
→ COMBAT_RUNNING [active workspace = LINE | CHAIN]
↔ TACTICAL_PAUSE_SKILL
→ COMBAT_RUNNING
→ VICTORY | DEFEAT
→ Result / Retry
```

`PRODUCTION_CANON_INDEX.json` becomes schema 3. Required minimum fields:

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

Keep SKILL-026 and BALANCE-027 as retained authorities with explicit realtime migration boundaries. Mark old turn/time canons at the top `HISTORICAL / SUPERSEDED BY TETRIS-CORE-029`; preserve their bodies.

Update `AGENTS.md`/`README.md` current authority order and remove current claims for Shared Budget/READY/Tempo.

Update Human evidence contract/index to CORE-029 while preserving `NOT_RUN` and the existing evidence ceiling.

### 1D · Verify

```bash
python -m unittest discover -s tests/tooling -p 'test_*.py' -v
```

Expected: all tooling contracts GREEN and no current validation surface still requires Shared Turn Budget.

### 1E · Commit

```bash
git add AGENTS.md README.md docs/design docs/validation tests/tooling
git commit -m "docs: migrate production authority to realtime combat"
```

---

## Task 2 · Port deterministic Line core as a persistent workspace

**Files:**
- Restore PR #19 `src/production/line/*` and the three Line data files.
- Restore `tests/production/line/*`.
- Adapt `src/production/line/production_line_session.gd`.
- Create `tests/production/runtime/test_realtime_line_session.gd`.

### 2A · Restore from immutable source

```bash
git restore --source=28ff25b508580ece5c0611dcd7f7a41a4f649bd8 -- \
  src/production/line \
  data/production/line_feel_config.json \
  data/production/line_reward_seed.json \
  data/production/line_tetrominoes.json \
  tests/production/line
```

### 2B · RED contract

Required session API:

```gdscript
var input_enabled: bool = true
func set_input_enabled(enabled: bool) -> void
func can_accept_input() -> bool
func tick(delta: float, soft_drop: bool = false) -> Dictionary
func snapshot_runtime_state() -> Dictionary
```

Test disable→enable preservation of board, active piece, queue, Hold, `gravity_accumulator_seconds`, `grounded_seconds`, `lock_reset_count`, and lock state. Switching away must not spawn/reroll/reset anything.

Run Line tests. Expected new runtime test **FAIL** because copied session still depends on TurnController/TurnPhase/Shared Budget/READY.

### 2C · Minimal GREEN

Remove active runtime turn ownership only. Keep existing deterministic puzzle behavior untouched.

### 2D · Verify/commit

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/line -ginclude_subdirs -gexit
git add src/production/line data/production/line_* tests/production/line tests/production/runtime/test_realtime_line_session.gd
git commit -m "feat: port persistent realtime line workspace"
```

---

## Task 3 · Port Chain core and close PR #19's unfinished deterministic RED

**Files:**
- Restore `src/production/chain/*` and `tests/production/chain/*` from PR #19 head.
- Create `src/production/chain/production_chain_config.gd`.
- Create `data/production/chain_runtime_seed.json`.
- Adapt `production_chain_session.gd`.
- Create `tests/production/runtime/test_realtime_chain_session.gd`.

### 3A · Confirm inherited RED

```bash
git restore --source=28ff25b508580ece5c0611dcd7f7a41a4f649bd8 -- src/production/chain tests/production/chain
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/chain -ginclude_subdirs -gexit
```

Expected failures specifically cover missing:

- `ChainBoard.has_available_swap()`;
- `ChainRandomizer.fill_playable_board()`;
- `ProductionChainConfig`;
- `data/production/chain_runtime_seed.json`.

Do not delete/suppress them.

### 3B · Implement playable-state contracts

`has_available_swap()` checks each right/down adjacent pair and restores the exact board before returning.

`fill_playable_board(board, max_attempts := 128)`:

1. preserve original board;
2. deterministic seeded stable fill;
3. accept only no-starting-match + at least one available swap;
4. after limit, restore original and return `false`.

### 3C · Explicit nonfinal config

Use:

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
  "stock_by_chain_depth": {"1":1,"2":2,"3":3,"4":4,"5":5,"6":6}
}
```

`from_dictionary()` fails closed on invalid shape. `stock_for_resolution()` returns 0 for failed/missing/negative depth and clamps successful depth to 6.

### 3D · Adapt session

Required API:

```gdscript
var input_enabled: bool = true
func set_input_enabled(enabled: bool) -> void
func can_accept_input() -> bool
func begin_swap(a: Vector2i, b: Vector2i) -> Dictionary
func is_resolving() -> bool
func complete_pending_resolution() -> Dictionary
func snapshot_runtime_state() -> Dictionary
```

The session returns a reward event such as `{"success":true,"chain_depth":3,"stock_requested":3}`. It does not directly mutate combat Stock.

### 3E · Verify/commit

Run Chain tests + realtime session test. The old 8 PR #19 Chain failures must be GREEN in the new branch without changing PR #19.

```bash
git add src/production/chain data/production/chain_runtime_seed.json tests/production/chain tests/production/runtime/test_realtime_chain_session.gd
git commit -m "feat: port deterministic realtime chain workspace"
```

---

## Task 4 · Implement tokenized pause authority **and actual Godot full-pause bridge**

**Files:**
- Create `src/production/runtime/simulation_pause_controller.gd`.
- Create `src/production/runtime/simulation_pause_bridge.gd`.
- Create `tests/production/runtime/test_simulation_pause_controller.gd`.
- Create `tests/production/runtime/test_simulation_pause_bridge.gd`.

### 4A · RED domain contract

```gdscript
func acquire(reason: String) -> int
func release(token: int) -> bool
func is_paused() -> bool
func has_reason(reason: String) -> bool
func active_reasons() -> Array[String]
```

Reasons: `TACTICAL_SKILL`, `SYSTEM_MENU`, `RUNTIME_TRANSITION`.

Tests: multiple tokens/reasons compose; releasing one never resumes while another remains; duplicate reason tokens are independent; unknown/double release fails closed.

### 4B · RED engine bridge contract

`SimulationPauseController` alone is insufficient. `SimulationPauseBridge` is a Node with `process_mode = PROCESS_MODE_ALWAYS` and applies the controller's effective state to Godot:

- `get_tree().paused = true/false` for simulation/physics/AnimationPlayer inheritance;
- Skill/pause UI roots use `PROCESS_MODE_WHEN_PAUSED` or `PROCESS_MODE_ALWAYS` so navigation/cancel/USE remains available;
- all project-owned combat AudioStreamPlayer nodes belong to group `simulation_audio`; bridge sets `stream_paused = true/false` while preserving already-stopped players;
- the bridge itself remains processable while paused so it can release pause;
- no hidden enemy/puzzle tick is manually called while Tree is paused.

Scene test must prove a normal simulation probe node stops `_process/_physics_process`, a paused-enabled UI probe still receives process/input, and registered simulation audio pause state toggles with the controller.

### 4C · GREEN/commit

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/runtime -ginclude_subdirs -gexit
git add src/production/runtime tests/production/runtime
git commit -m "feat: add full simulation pause authority"
```

---

## Task 5 · Implement persistent free workspace switching

**Files:**
- Create `src/production/runtime/puzzle_workspace_manager.gd`.
- Create `tests/production/runtime/test_puzzle_workspace_manager.gd`.
- Modify the two sessions only if handoff queries are needed.

Required API:

```gdscript
const LINE := "LINE"
const CHAIN := "CHAIN"
func active_workspace() -> String
func request_switch(target: String) -> Dictionary
func process_safe_handoff() -> Dictionary
func is_switch_pending() -> bool
func line_input_enabled() -> bool
func chain_input_enabled() -> bool
```

RED tests prove:

```text
LINE state A → CHAIN → CHAIN state B → LINE exact A → CHAIN exact B
```

Also prove switch spam cannot reset Line gravity/lock/Hold/Next, reroll Chain RNG/refill, duplicate rewards, or pause enemy time.

Implementation retains the same two session objects. Line switches after the current synchronous atomic operation returns; switching never forces a placement. Chain switch waits only for an already-committed resolution to reach stable state.

Run Line+Chain+runtime tests and commit:

```bash
git add src/production/runtime/puzzle_workspace_manager.gd src/production/line/production_line_session.gd src/production/chain/production_chain_session.gd tests/production/runtime
git commit -m "feat: preserve puzzle state across free mode switching"
```

---

## Task 6 · Port combat/resource primitives and create realtime Gatebreaker scheduler

**Files:**
- Restore reusable combat files/data listed above.
- Create `src/production/runtime/gatebreaker_realtime_timing_config.gd`.
- Create `src/production/runtime/enemy_action_scheduler.gd`.
- Create `data/production/gatebreaker_realtime_timing_seed.json`.
- Restore compatible combat tests.
- Create `tests/production/runtime/test_enemy_action_scheduler.gd`.

Use deterministic nonfinal timing seed:

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

`commit_lead_seconds=0.0` deliberately makes first-slice commit and resolution deadline identical, eliminating an ambiguous precommitted-but-paused state. These seconds are test/tuning seeds, not final balance.

Required API:

```gdscript
func start() -> Dictionary
func tick_simulation(delta: float, context: Dictionary) -> Array[Dictionary]
func current_action_id() -> String
func next_action_id() -> String
func remaining_seconds() -> float
func is_action_committed() -> bool
```

RED tests: ETA advances only when ticked; resolves exactly once at zero; advances authored sequence; never secretly retargets from player state; deterministic order; Skill-open processed before runtime tick can freeze a still-uncommitted deadline; already-resolved prior-frame action cannot be undone.

Compose existing catalog/director/telegraph/resolver rather than duplicating their rules.

Commit:

```bash
git add src/production/combat src/production/runtime data/production/gatebreaker_* tests/production/combat tests/production/runtime
git commit -m "feat: schedule authored enemy actions in realtime"
```

---

## Task 7 · Port skill primitives; Skill becomes full tactical-pause browse→USE flow

**Files:**
- Restore skill/target files/tests from PR #19.
- Modify `vanguard_skill_seed.json`.
- Adapt/replace `production_skill_session.gd`.
- Modify catalog/resolver/executor as required for realtime migration status.
- Create `tests/production/runtime/test_tactical_skill_session.gd`.

### 7A · Fail-closed migration boundary

Do **not** invent realtime semantics for approved-spec turn-bound techniques:

- `sup_t3_haste` → `runtime_status: REALTIME_MIGRATION_REQUIRED`.
- `sup_t6_battle_trance` → `runtime_status: REALTIME_MIGRATION_REQUIRED`.
- `sup_t4_mark_weakness` remains unavailable while its existing effect contract is unresolved.
- Tempo scaling is inactive in CORE-029.
- `MODIFY_NEXT_TURN_BUDGET` may remain parseable historical vocabulary but is not executable by a realtime-ready technique.
- `BATTLE_TRANCE` status is not created/consumed by the CORE-029 first slice.

This is a conservative exclusion, not a reinterpretation. Those techniques remain visible identities with explicit unavailable reason until a separate approved realtime semantic decision exists.

### 7B · RED session contract

```gdscript
func open() -> bool
func select_category(category: String) -> bool
func select_technique(technique_id: String) -> Dictionary
func selected_detail() -> Dictionary
func readiness(technique_id: String, context: Dictionary) -> Dictionary
func commit_selected(context: Dictionary) -> Dictionary
func cancel() -> Dictionary
```

Tests:

- opening acquires `TACTICAL_SKILL` pause token;
- browse/select mutates no resources/status and never resumes;
- row click never spends;
- cancel releases only its tactical token;
- `SYSTEM_MENU` + tactical tokens compose safely;
- unresolved techniques return explicit fail-closed reason and spend nothing;
- insufficient resources/effect preflight failure produces no partial mutation;
- explicit USE spends Energy+Stock exactly once, applies effect once, closes tactical pause, restores prior workspace.

Before any spend, resolver must complete deterministic preflight for all effects/targets. Known invalid/no-op conditions are rejected during preflight.

Run skill+target+runtime tests and commit:

```bash
git add src/production/skill src/production/targeting data/production/vanguard_skill_seed.json tests/production/skill tests/production/targeting tests/production/runtime
git commit -m "feat: make skill selection a full tactical pause"
```

---

## Task 8 · Build `ProductionCombatRuntime` as sole continuous-time orchestrator

**Files:**
- Create `src/production/runtime/production_combat_runtime.gd`.
- Create `tests/production/integration/test_realtime_combat_runtime.gd`.
- Do not port old `production_battle_session.gd`, TurnController, TurnBudget, or TempoEvaluator into active runtime.

Required API:

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

Frame order is fixed:

```text
1. process player commands, including Skill-open
2. apply pause/workspace command state
3. if paused: zero simulation advancement
4. if running: tick active puzzle + enemy scheduler using same delta
5. commit puzzle resource events once
6. resolve Victory/Defeat
7. publish events/snapshot
```

RED integration tests prove enemy ETA advances in LINE/CHAIN; stops in tactical/manual pause; inactive puzzle never simulates; active puzzle does; switches preserve ETA except normal elapsed delta; Line reward grants Energy once; each CHAIN wave adds shared Combo +1 (cap 10) then its structured CHAIN MP recovery, while failed/reverted swaps and MP lock reset Combo; Skill-open before scheduler tick freezes that frame; cancel/use resumes exact ETA/puzzle state; terminal HP states end encounter without turn transitions.

Commit:

```bash
git add src/production/runtime tests/production/integration/test_realtime_combat_runtime.gd
git commit -m "feat: orchestrate continuous realtime puzzle combat"
```

---

## Task 9 · Rebuild UI as one large 60/40 mode-switch battle surface

**Files:**
- Adapt `scenes/production/battle.tscn`.
- Adapt `production_battle.gd`.
- Adapt/replace `production_battle_presenter.gd`.
- Reuse `production_line_board_view.gd`.
- Create `production_chain_board_view.gd`.
- Adapt/replace `production_battle_runtime_bridge.gd`.
- Update/create `tests/production/ui/*` CORE-029 tests.
- Modify `project.godot` input actions only; main scene changes in Task 11.

Required hierarchy:

```text
Battle
└─ MainRow
   ├─ PuzzleColumn (~60%)
   │  ├─ ModeBar [LINE | CHAIN | SKILL]
   │  └─ PuzzleHost [LineBoardView | ChainBoardView; exactly one visible]
   └─ CombatColumn (~40%)
      ├─ ThreatPanel [Current Telegraph + ETA + Next Forecast]
      ├─ CombatStage
      ├─ ResourceBar [HP | Energy | Stock]
      └─ SkillPanel
```

At 1280×720 automated layout test: Puzzle ratio `0.56..0.64`; only one puzzle visible/input-active.

Forbidden current UI: Shared Turn Timer, READY, ordered phase rail, PASS, Tempo provisional reward, mandatory inactive-board Sidecar.

Skill-open state: explicit `TACTICAL PAUSE`; frozen puzzle remains readable; Current threat remains visible; right interaction exposes `ATK/DEF/SUP → T1–T6 → detail → USE`.

Named actions:

```text
workspace_line
workspace_chain
open_skill
pause_game
```

Bridge reads named actions, never raw physical keys, and has a paused-capable process mode so Skill/pause can close while SceneTree is paused. All battle simulation audio players join `simulation_audio`.

`ProductionChainBoardView` only renders state/selection feedback; it owns no swap legality/rewards.

Run UI+runtime tests and commit:

```bash
git add scenes/production/battle.tscn src/production/ui src/production/session/production_battle_runtime_bridge.gd project.godot tests/production/ui
git commit -m "feat: build 60-40 realtime battle interface"
```

---

## Task 10 · Replace turn/Tempo telemetry with continuous simulation evidence

**Files:**
- Restore/adapt `production_telemetry.gd`.
- Restore/adapt existing telemetry test.
- Create `tests/production/telemetry/test_realtime_combat_telemetry.gd`.

Required events:

```text
BATTLE_STARTED
WORKSPACE_ENTERED / WORKSPACE_EXITED
WORKSPACE_SWITCH_REQUESTED / WORKSPACE_SWITCH_COMMITTED
LINE_REWARD / CHAIN_REWARD
TACTICAL_PAUSE_OPENED / TACTICAL_PAUSE_CLOSED
SYSTEM_PAUSE_OPENED / SYSTEM_PAUSE_CLOSED
TECHNIQUE_USED
ENEMY_TELEGRAPH_STARTED / ENEMY_ACTION_RESOLVED
BOARD_BREAK
VICTORY / DEFEAT
```

Gameplay events use `simulation_time_seconds`. Pause events also record wall-clock duration separately.

Summary fields:

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

No Tempo reward and no penalty for paused reading time.

Commit:

```bash
git add src/production/telemetry tests/production/telemetry
git commit -m "feat: record continuous combat telemetry"
```

---

## Task 11 · Rebuild bootstrap and make Production battle the build-branch main scene

**Files:**
- Adapt/replace `production_battle_bootstrap.gd`.
- Adapt `production_battle_coordinator.gd` only as a thin scene-facing façade; it must not recreate turn semantics.
- Update bootstrap/scene tests.
- Modify `project.godot` `run/main_scene` after automated bootstrap/runtime/UI tests are green.

Bootstrap constructs:

```text
ProductionCombatState
Line session
Chain config/session
SimulationPauseController + SimulationPauseBridge
PuzzleWorkspaceManager
Gatebreaker catalog/director/telegraph/resolver
EnemyActionScheduler
Skill catalog/status/response/effect/resolver/session
ProductionCombatRuntime
Telemetry
Presenter/runtime bridge
```

It must not instantiate TurnController, TurnBudget, TempoEvaluator, or TimeEffectState for CORE-029 gameplay.

Initial state: LINE visible/input-active; CHAIN deterministic playable state exists hidden/input-off; enemy scheduler running; Skill closed.

After automated tests are green on the build branch only:

```ini
run/main_scene="res://scenes/production/battle.tscn"
```

Then:

```bash
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

No user-playable PASS claim comes from setting `main_scene` alone.

Commit:

```bash
git add src/production/session project.godot tests/production/ui tests/production/integration
git commit -m "feat: launch production realtime battle slice"
```

---

## Task 12 · Exact-head CI, runtime evidence, adversarial review, and closeout gate

### 12A · Automated exact-head verification

Run CI-equivalent commands:

```bash
python -m unittest discover -s tests/tooling -p 'test_*.py' -v
pwsh ./tools/windows/start_tetris_local_executor.ps1 -StaticSelfTest
godot --headless --path . --editor --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Push exact head and require GitHub Actions GREEN. Never reuse PR #19 CI as CORE-029 evidence.

Automated acceptance must prove:

1. enemy ETA advances in LINE and CHAIN;
2. both workspace states survive repeated switches exactly;
3. switches cannot reset gravity/lock/Hold/Next/RNG or duplicate rewards;
4. inactive workspace never simulates;
5. Skill tactical pause actually pauses SceneTree-driven simulation, puzzle/enemy ticks, relevant animation processing, simulation audio, statuses/cooldowns;
6. paused-capable UI can still select/cancel/USE;
7. manual+tactical pause tokens compose safely;
8. explicit USE is the only Technique spend path;
9. forecast/current action-bound statuses stay on exact authored action IDs;
10. unresolved realtime Techniques fail closed;
11. 60/40 screen has one active puzzle surface + persistent threat/resource/combat surface;
12. bootstrap contains no active old TurnController/Shared Budget/Tempo owner;
13. Victory/Defeat terminate continuous encounter deterministically.

### 12B · User-local/Human gate remains separate

When authorized, actual Windows first-exposure receipts must test:

- LINE↔CHAIN switch comprehension without Sidecar;
- visible state persistence on return;
- Current Telegraph/ETA readability while focused on puzzle;
- full Skill pause reads as deliberate tactical state rather than bug/freeze;
- player can explain why they chose LINE, CHAIN, or Skill at key moments;
- 60/40 preserves puzzle readability + combat awareness;
- Energy vs Stock/Tier distinction remains understandable;
- real-time pressure feels fair enough to tune rather than immediately redesign.

Until receipts exist:

```text
USER_WINDOWS_RUNTIME = NOT_RUN
HUMAN_USABILITY = NOT_RUN
PLAYER_EXPERIENCE = NOT_RUN
FINAL_BALANCE = NOT_RUN
```

### 12C · Five whole-state adversarial loops

After exact-head automated verification, run five full loops:

1. **Authority:** CORE-029 routing, Human contract migrated, no current CORE-024/TIME-025 claims, PR #19 unchanged.
2. **Exploit/determinism:** switch spam, pause stacking, reward duplication, RNG/gravity resets, same-frame Skill/enemy deadline.
3. **Architecture:** puzzle rules stay in puzzle systems; UI/telemetry stay read-only; no hidden TurnController resurrection.
4. **UX/IRG:** 60/40 semantics, threat readability, tactical-pause communication, evidence ceilings honest.
5. **Maintainability/cost:** selective reuse smaller than rewrite; zero paid dependency; no unnecessary class/boss/biome breadth; PR isolation/reversibility preserved.

Any material correction resets clean-loop count and requires exact-head verification again.

### 12D · Compare/PR/Notion closeout

```bash
git diff --stat main...HEAD
git log --oneline main..HEAD
```

Live-read PR #19; verify its head is still the source snapshot unless the user independently changed it. External movement is recorded as drift, not overwritten.

After verified milestones, update Notion Home/Production Handoff/Validation and destination-readback them. Keep Human status `NOT_RUN` until receipts.

Do not merge merely because automated tests pass if the current project contract still requires user/player evidence before merge. If merge is later authorized, verify post-merge `main`, post-merge CI, structured canon, and Notion readback before completion claim.

---

## Execution Order

```text
1. CORE-029 + Human evidence authority migration
2. persistent Line core
3. deterministic Chain core + inherited RED closure
4. domain + actual Godot full-pause bridge
5. persistent workspace switching
6. realtime enemy scheduler
7. tactical-pause Skill session
8. continuous CombatRuntime
9. 60/40 UI + named-input bridge
10. continuous telemetry
11. production bootstrap + build-branch main scene
12. exact-head CI + Human gate + 5-loop closeout
```

This order is deliberate. Do not start with UI or adapt the old coordinator first; that would make the superseded TurnController/Shared Budget architecture the temporary skeleton and create avoidable rework.
