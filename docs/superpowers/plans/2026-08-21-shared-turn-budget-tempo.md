# Shared Turn Budget + Tempo Reward Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Status: **PLANNING HANDOFF / DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION**

**Goal:** Implement `TETRIS-TIME-025` so one shared active-input time budget spans Line, Chain, and Action, supports difficulty/item/Haste/Slow modifiers, and rewards qualified fast completion with a capped Tempo Bonus.

**Architecture:** Keep `TETRIS-CORE-024` phase order, but move timing ownership to a production `TurnBudget` service owned by the turn/combat layer. Puzzle engines report stable-boundary and performance events; they never mutate time directly. A separate `TempoEvaluator` compares active time against an unmodified performance reference so time-extension effects cannot create free reward.

**Tech Stack:** Godot 4.x, GDScript, JSON data/config, GUT production tests, existing semantic Python canon tests.

**Spec:** `docs/superpowers/specs/2026-08-21-shared-turn-budget-tempo-design.md`

## Global Constraints

- Current timing authority is `docs/design/PRODUCTION_TURN_TIME_CANON.md` / `TETRIS-TIME-025`.
- Current turn order remains `TETRIS-CORE-024`.
- Do not execute runtime tasks until the user explicitly declares `기획 완료 / BUILD 진행` or equivalent.
- PR #9 remains read-only unless separately named and authorized.
- Production code must remain separate from historical Core Combat Foundation / Engineering Harness code and tests.
- One shared budget spans `LINE`, `CHAIN`, and `ACTION`; it never resets between them.
- `LINE_SETTLE`, `CHAIN_SETTLE`, forced animation/transition, Enemy Resolve, and System Pause do not consume player budget.
- First implementation supports flat-second modifiers and stacking groups only; no percentage stacking.
- Effective Budget and Tempo Reference are separate values; modifiers never mutate Tempo Reference.
- Timeout must settle deterministically and reach PASS without deadlock.
- Tempo requires Line qualification + Chain qualification + legal non-PASS Action + no timeout + first-slice no Board Break.
- Tempo is initially a capped current-action potency modifier plus telemetry score, not persistent currency.
- Exact seconds and Tempo curve values remain data-driven tuning seeds until runtime/human validation.

---

## File Structure

Create or modify the production paths below during BUILD:

```text
src/production/turn/
  turn_phase.gd                 # existing/new phase vocabulary
  turn_budget.gd                # shared active-input clock + snapshot
  turn_budget_modifier.gd       # typed modifier value / stacking metadata
  turn_controller.gd            # phase order, READY, settle, timeout routing
src/production/combat/
  tempo_evaluator.gd            # eligibility + saved-time ratio + potency result
  production_combat_state.gd    # current resources/status links
src/production/status/
  time_effect_state.gd          # active Haste/Slow/item timing effects
src/production/telemetry/
  production_telemetry.gd       # timing/Tempo events
data/production/
  turn_time_config.json         # difficulty base, clamps, Tempo reference/curve
  time_effects.json             # Haste/Slow/item effect definitions
tests/production/unit/
  test_turn_budget.gd
  test_time_effect_state.gd
  test_tempo_evaluator.gd
tests/production/integration/
  test_shared_turn_timing.gd
  test_turn_time_modifiers.gd
  test_tempo_integration.gd
```

Do not merge these responsibilities into Line or Chain board classes.

---

### Task 1: Shared TurnBudget domain

**Files:**
- Create: `src/production/turn/turn_budget.gd`
- Create: `tests/production/unit/test_turn_budget.gd`
- Create/Modify: `data/production/turn_time_config.json`

**Interfaces:**
- Consumes: `base_budget_seconds: float`, `flat_modifier_seconds: float`, `min_budget_seconds: float`, `max_budget_seconds: float`.
- Produces: `snapshot(...)`, `consume(delta)`, `remaining_seconds`, `active_used_seconds`, `is_expired()`, `freeze()`.

- [ ] **Step 1: Write failing TurnBudget tests**

```gdscript
func test_snapshot_clamps_effective_budget() -> void:
    var budget := TurnBudget.new()
    budget.snapshot(90.0, 20.0, 30.0, 100.0)
    assert_eq(budget.effective_budget_seconds, 100.0)
    assert_eq(budget.remaining_seconds, 100.0)

func test_consume_uses_one_shared_clock() -> void:
    var budget := TurnBudget.new()
    budget.snapshot(90.0, 0.0, 30.0, 120.0)
    budget.consume(12.0)
    budget.consume(8.0)
    assert_eq(budget.remaining_seconds, 70.0)
    assert_eq(budget.active_used_seconds, 20.0)

func test_non_positive_delta_never_changes_budget() -> void:
    var budget := TurnBudget.new()
    budget.snapshot(90.0, 0.0, 30.0, 120.0)
    budget.consume(0.0)
    budget.consume(-10.0)
    assert_eq(budget.remaining_seconds, 90.0)
```

- [ ] **Step 2: Run focused tests and confirm RED**

Run the production GUT target for `test_turn_budget.gd`.
Expected: FAIL because `TurnBudget` does not exist.

- [ ] **Step 3: Implement minimal deterministic TurnBudget**

```gdscript
class_name TurnBudget
extends RefCounted

var effective_budget_seconds: float = 0.0
var remaining_seconds: float = 0.0
var active_used_seconds: float = 0.0
var frozen: bool = true

func snapshot(base_seconds: float, flat_modifier_seconds: float, min_seconds: float, max_seconds: float) -> void:
    effective_budget_seconds = clampf(base_seconds + flat_modifier_seconds, min_seconds, max_seconds)
    remaining_seconds = effective_budget_seconds
    active_used_seconds = 0.0
    frozen = false

func consume(delta: float) -> void:
    if frozen or delta <= 0.0 or remaining_seconds <= 0.0:
        return
    var spent := minf(delta, remaining_seconds)
    remaining_seconds -= spent
    active_used_seconds += spent

func is_expired() -> bool:
    return remaining_seconds <= 0.0

func freeze() -> void:
    frozen = true
```

- [ ] **Step 4: Re-run focused tests and regression**

Expected: TurnBudget tests PASS; historical Foundation suite remains unchanged.

- [ ] **Step 5: Commit**

```bash
git add src/production/turn/turn_budget.gd tests/production/unit/test_turn_budget.gd data/production/turn_time_config.json
git commit -m "feat: add shared player turn budget"
```

---

### Task 2: Time effect modifier state

**Files:**
- Create: `src/production/turn/turn_budget_modifier.gd`
- Create: `src/production/status/time_effect_state.gd`
- Create: `data/production/time_effects.json`
- Create: `tests/production/unit/test_time_effect_state.gd`

**Interfaces:**
- Produces modifier records with `source_id`, `stack_group`, `flat_seconds`, `stackable`, `expires_after_turns`.
- Produces `get_total_flat_seconds_for_next_turn()` without mutating Tempo Reference.

- [ ] **Step 1: Write failing stacking tests**

```gdscript
func test_default_haste_refreshes_same_stack_group() -> void:
    var state := TimeEffectState.new()
    state.apply_effect("haste", "haste_default", 8.0, false, 1)
    state.apply_effect("haste", "haste_default", 8.0, false, 1)
    assert_eq(state.get_total_flat_seconds_for_next_turn(), 8.0)

func test_distinct_groups_combine() -> void:
    var state := TimeEffectState.new()
    state.apply_effect("boots", "equipment_boots", 3.0, false, -1)
    state.apply_effect("slow", "slow_default", -5.0, false, 1)
    assert_eq(state.get_total_flat_seconds_for_next_turn(), -2.0)
```

- [ ] **Step 2: Confirm RED**

Expected: missing modifier/status classes.

- [ ] **Step 3: Implement minimal stacking-group behavior**

Use one active record per non-stackable group; replace/refresh on reapply. Explicitly stackable records may coexist using unique instance keys.

- [ ] **Step 4: Add expiry-at-turn-boundary tests**

Verify Haste/Slow created during a turn does not alter the already snapshotted current budget and becomes available only when the next turn snapshots.

- [ ] **Step 5: Commit**

```bash
git add src/production/turn/turn_budget_modifier.gd src/production/status/time_effect_state.gd data/production/time_effects.json tests/production/unit/test_time_effect_state.gd
git commit -m "feat: add turn time modifier effects"
```

---

### Task 3: TurnController integration with shared budget

**Files:**
- Modify/Create: `src/production/turn/turn_controller.gd`
- Modify/Create: `src/production/turn/turn_phase.gd`
- Create: `tests/production/integration/test_shared_turn_timing.gd`

**Interfaces:**
- Consumes: one `TurnBudget` snapshot per turn.
- Produces: `request_ready()`, deterministic settle routing, timeout PASS event.

- [ ] **Step 1: Write failing integration tests**

```gdscript
func test_line_ready_carries_remaining_budget_into_chain() -> void:
    var turn := make_turn_with_budget(90.0)
    turn.enter_line()
    turn.tick_player_time(20.0)
    turn.request_ready()
    turn.complete_line_settle()
    assert_eq(turn.phase, TurnPhase.CHAIN)
    assert_eq(turn.turn_budget.remaining_seconds, 70.0)

func test_chain_ready_carries_remaining_budget_into_action() -> void:
    var turn := make_turn_with_budget(90.0)
    enter_chain_after_spending(turn, 20.0)
    turn.tick_player_time(15.0)
    turn.request_ready()
    turn.complete_chain_settle()
    assert_eq(turn.phase, TurnPhase.ACTION)
    assert_eq(turn.turn_budget.remaining_seconds, 55.0)
```

- [ ] **Step 2: Add settle-pause RED cases**

Assert that large Line/Chain settle durations do not change `active_used_seconds` or `remaining_seconds`.

- [ ] **Step 3: Implement phase clock ownership**

Only LINE, CHAIN, ACTION player-authority states call `turn_budget.consume(delta)`; settle/resolve/pause states do not.

- [ ] **Step 4: Add timeout routing tests**

```gdscript
func test_timeout_during_line_settles_then_passes_without_chain_input() -> void:
    var turn := make_turn_with_budget(10.0)
    turn.enter_line()
    turn.tick_player_time(10.0)
    assert_eq(turn.phase, TurnPhase.LINE_SETTLE)
    turn.complete_line_settle()
    assert_true(turn.chain_input_skipped_for_timeout)
    assert_eq(turn.pending_player_action.id, "PASS")
```

Repeat for Chain and Action timeout.

- [ ] **Step 5: Commit**

```bash
git add src/production/turn/turn_controller.gd src/production/turn/turn_phase.gd tests/production/integration/test_shared_turn_timing.gd
git commit -m "feat: integrate shared budget with turn phases"
```

---

### Task 4: TempoEvaluator domain

**Files:**
- Create: `src/production/combat/tempo_evaluator.gd`
- Create: `tests/production/unit/test_tempo_evaluator.gd`
- Modify: `data/production/turn_time_config.json`

**Interfaces:**
- Consumes: `tempo_reference_seconds`, `active_used_seconds`, eligibility flags, reward-curve config.
- Produces: `eligible`, `saved_ratio`, `potency_bonus_ratio`, `ineligible_reason`.

- [ ] **Step 1: Write failing formula tests**

```gdscript
func test_same_active_time_has_same_tempo_even_with_different_effective_budget() -> void:
    var a := TempoEvaluator.evaluate(90.0, 45.0, true, true, true, false, false)
    var b := TempoEvaluator.evaluate(90.0, 45.0, true, true, true, false, false)
    assert_eq(a.saved_ratio, b.saved_ratio)

func test_faster_eligible_completion_never_rewards_less() -> void:
    var slow := TempoEvaluator.evaluate(90.0, 70.0, true, true, true, false, false)
    var fast := TempoEvaluator.evaluate(90.0, 40.0, true, true, true, false, false)
    assert_gte(fast.potency_bonus_ratio, slow.potency_bonus_ratio)
```

- [ ] **Step 2: Add anti-exploit RED cases**

No Tempo if Line qualification false, Chain qualification false, action is PASS, timeout occurred, or first-slice Board Break occurred.

- [ ] **Step 3: Implement saved-time ratio and capped data-driven curve**

Keep the evaluator independent of `effective_budget_seconds`; only `tempo_reference_seconds` and active time determine the time score.

- [ ] **Step 4: Verify monotonicity over sampled completion times**

Loop over descending active completion times and assert reward is monotonic non-decreasing until cap.

- [ ] **Step 5: Commit**

```bash
git add src/production/combat/tempo_evaluator.gd tests/production/unit/test_tempo_evaluator.gd data/production/turn_time_config.json
git commit -m "feat: add qualified tempo reward evaluation"
```

---

### Task 5: Difficulty / Haste / Slow integration

**Files:**
- Modify: `data/production/turn_time_config.json`
- Modify: `data/production/time_effects.json`
- Create: `tests/production/integration/test_turn_time_modifiers.gd`

**Interfaces:**
- Difficulty supplies `base_budget_seconds`.
- Active time effects supply summed flat seconds.
- Tempo Reference is read from its own config field and never derived from Effective Budget.

- [ ] **Step 1: Write failing difficulty tests**

Assert difficulty changes Effective Budget but an identical active completion time uses the same configured Tempo Reference.

- [ ] **Step 2: Write failing Haste/Slow tests**

Assert Haste adds seconds, Slow subtracts seconds, clamp applies, and neither changes Tempo Reference.

- [ ] **Step 3: Implement config adapter**

Keep exact candidate values in JSON. Do not hide a dynamic-difficulty adjustment inside code.

- [ ] **Step 4: Verify next-turn snapshot semantics**

Enemy Slow applied during Enemy Resolve affects the next turn; Support Haste created during the player's current action affects its next eligible turn unless the effect definition explicitly says otherwise.

- [ ] **Step 5: Commit**

```bash
git add data/production/turn_time_config.json data/production/time_effects.json tests/production/integration/test_turn_time_modifiers.gd
git commit -m "feat: integrate difficulty haste and slow timing"
```

---

### Task 6: Apply Tempo to selected action

**Files:**
- Modify/Create: `src/production/combat/action_executor.gd`
- Modify/Create: `src/production/combat/production_combat_state.gd`
- Create: `tests/production/integration/test_tempo_integration.gd`

**Interfaces:**
- Consumes: legal selected Action + Tempo result.
- Produces: final Attack/Defense/Support potency for current action only.

- [ ] **Step 1: Write failing action-potency tests**

Verify eligible Tempo increases Attack, Defense, and Support using the same policy adapter without creating persistent Energy/Stock.

- [ ] **Step 2: Add no-currency RED cases**

Assert Tempo evaluation alone does not increase Energy, Chain Stock, or permanent progression values.

- [ ] **Step 3: Implement bounded potency application**

Apply Tempo after action eligibility/cost validation and before effect resolution. Rejected actions and PASS receive no Tempo.

- [ ] **Step 4: Regression**

Verify resource spending remains exact and Tempo cannot make an otherwise illegal Tier legal.

- [ ] **Step 5: Commit**

```bash
git add src/production/combat/action_executor.gd src/production/combat/production_combat_state.gd tests/production/integration/test_tempo_integration.gd
git commit -m "feat: apply tempo bonus to player actions"
```

---

### Task 7: UI semantics for shared budget and early completion

**Files:**
- Modify/Create: `src/production/ui/production_battle.gd`
- Modify/Create: `scenes/production/battle.tscn`
- Add production UI semantic tests where current project patterns support them.

**Interfaces:**
- Reads immutable presentation state from TurnController/TempoEvaluator.
- Sends named `READY` / action-confirm intents only.

- [ ] **Step 1: Add semantic UI assertions**

Require one shared timer, current phase label, READY in Line/Chain, Tempo eligibility/provisional bonus, and no independent per-phase timer reset widgets.

- [ ] **Step 2: Implement shared timer presentation**

The timer value must remain continuous when the phase label changes Line → Chain → Action.

- [ ] **Step 3: Implement RESOLVING pause treatment**

Settle state displays `RESOLVING`; the visible shared budget remains unchanged until the next player-authority phase.

- [ ] **Step 4: Add low-time warning and Tempo reason copy**

Keep warning thresholds data-driven. When ineligible, show a compact reason rather than a misleading positive reward preview.

- [ ] **Step 5: Commit**

```bash
git add src/production/ui/production_battle.gd scenes/production/battle.tscn tests/production
git commit -m "feat: present shared turn clock and tempo feedback"
```

---

### Task 8: Telemetry and deterministic replay evidence

**Files:**
- Modify/Create: `src/production/telemetry/production_telemetry.gd`
- Add: production replay/timing fixtures.

**Interfaces:**
- Emits no network analytics requirement for first Slice; deterministic local logs are sufficient.

- [ ] **Step 1: Add timing telemetry contract tests**

Require base budget, modifiers, effective budget, Tempo Reference, per-stage active time, settle durations, READY/timeout, qualification flags, saved ratio, eligibility reason, applied potency, and outcome.

- [ ] **Step 2: Implement telemetry event schema**

Do not combine active player time with settle/animation time in one field.

- [ ] **Step 3: Add deterministic replay fixture**

Same seed + same timestamped named inputs must reproduce phase transitions, budget remaining, timeout route, and Tempo result.

- [ ] **Step 4: Commit**

```bash
git add src/production/telemetry tests/production/replay
git commit -m "test: add shared-time replay evidence"
```

---

### Task 9: Production validation matrix

**Files:**
- Modify: project production validation documentation/evidence paths created by the main Vertical Slice plan.

- [ ] **Step 1: Automated matrix**

Run semantic canon tests, all new production timing tests, full production suite, and historical Foundation suite. Report each boundary separately.

- [ ] **Step 2: Runtime matrix**

On the dedicated Tetris Godot runtime, verify timer continuity, settle pauses, Haste/Slow preview, timeout fallback, READY transitions, and Tempo feedback at 1280×720.

- [ ] **Step 3: Human A/B/C runs**

Compare at minimum three total-budget candidates around the migration seed rather than declaring 90 seconds final. Record per-stage active-time distribution and Tempo farming behavior.

- [ ] **Step 4: Difficulty check**

Verify easier profiles do not become optimal Tempo farming solely because they grant more available time.

- [ ] **Step 5: Adversarial loops**

Run five whole-scope attacks:
1. Line hogging starves Chain/Action.
2. Minimum-event rush farms Tempo.
3. Haste becomes mandatory/double-dips reward.
4. Slow/timeout feels unfair or unclear.
5. Animation/settle makes the clock feel dishonest.

Correct only evidence-backed failures, then rerun regression after each correction.

---

## Build Gate

Before Task 1 runtime implementation begins, all must be true:

1. `TETRIS-TIME-025` timing canon is merged to `main` and read back.
2. Notion Project Home/08/03/06 and Issue #10 agree with the merged repository truth.
3. User explicitly declares `기획 완료 / BUILD 진행` or equivalent.
4. Current `main` and open/recent same-goal PRs are re-read; PR #9 remains protected/read-only.
5. Dedicated local HiGodot receipt is established if persistent editor mutation is needed.

Until those conditions are met, this file is an implementation handoff only and **must not be executed**.
