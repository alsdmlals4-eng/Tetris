# Phase 2 Tactical Core Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver one verified first-session vertical slice in which `TETRIS-CHAIN-038`, `TETRIS-SKILL-039`, `TETRIS-BALANCE-040`, `TETRIS-SKILL-042`, `TETRIS-ONBOARDING-037`, and the short briefing work together without changing their player promise.

**Architecture:** Keep `ProductionCombatState` as the sole owner of HP/MP/Combo mutation, keep `ProductionCombatRuntime` as the frame-order owner, and retain data-driven skill definitions. Split the delivery into three mergeable implementation PRs: deterministic CHAIN/resource alignment, combo-resolved Skill/time control, then briefing/tutorial handoff. The UI reads authoritative runtime snapshots; it never chooses an effect, mutates a resource, or edits an enemy clock directly.

**Tech Stack:** Godot 4.7.1-stable, GDScript, JSON production seeds, GUT 9.7.1, Python tooling tests, GitHub Actions `core-poc-ci`.

**Spec:** `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md`, `docs/design/CHAIN_COMBO_MP_CONTRACT.md`, `docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md`, `docs/design/COMBO_STAGE_SKILL_CONTENT_GDD.md`, and `docs/design/FIRST_SESSION_ONBOARDING_CONTRACT.md`.

## Global Constraints

- Issue: [#82](https://github.com/alsdmlals4-eng/Tetris/issues/82). This plan is `USER_REVIEW_REQUIRED`; do not start any Godot implementation until the user explicitly approves this contract.
- Work from a fresh isolated `codex/` worktree created from the latest completed `main`; all other open/draft PRs remain read-only.
- Preserve continuous CORE-029 combat, one active 60/40 Puzzle/Combat surface, persistent LINE↔CHAIN state, full tokenized Skill/manual pause, and explicit scheduler commit boundaries.
- Use `energy` and `stock` as internal field names in this delivery. Player-facing labels are `MP` and `COMBO`; no broad field-name migration is permitted.
- MP cap is exactly `60`; Combo cap is exactly `10`. A successful CHAIN wave awards Combo before its own MP recovery: `sum(maximal qualified line lengths) - 3 + post-wave Combo`.
- A failed CHAIN swap resets Combo exactly once. A player may spend exactly `1 MP` to keep that already-swapped board, but that lock gives no immediate clear, cascade, Combo, or CHAIN MP.
- Skill has exactly `ATK / DEF / SUP → one current-Combo-resolved preview → explicit CONFIRM`. No Tier grid, manual lower-stage browser, automatic cast, cooldown, new currency, card collection, route/progression system, or new enemy roster.
- The only voluntary lower-Combo strategy is ending CHAIN at that current Combo. The only resolver down-rank is the approved MP-shortage fallback: every converted surplus Combo gives exactly `5 MP`, then the highest feasible lower stage resolves; the transaction spends all opening Combo.
- Player board-play opportunity affects only active LINE gravity/lock simulation. Enemy ETA effects affect only the exact visible current Telegraph action ID. Never use `Engine.time_scale`, a global pause, an inactive workspace, a Next Forecast, or a hidden future action as an effect target.
- A preview, category press, cancel, manual pause, or tactical pause changes no resource, board state, or clock. An ETA effect cannot apply after `EnemyActionScheduler.is_action_committed()` becomes true.
- All new GDScript files start with a one-line Korean role comment. Do not generate a production image batch; retain the existing `TETRIS-VISUAL-041` Parchment Field Manual theme and existing runtime consumers.
- Every code task follows RED → expected failure → minimal GREEN → focused regression → commit. Every implementation PR requires exact-head full GUT, Python tooling, Godot import/parse, CI, runtime receipt, and the stated Human gate before any player-experience claim.

---

## Contracted tuning seeds

These are implementation seeds, not balance approval or Human evidence. They make preview, data validation, fallback tests, and the first safe encounter deterministic. A later data-only balance pass may change a value only after runtime and Human evidence.

| Stage | MP cost | ATK | DEF | SUP |
| --- | ---: | --- | --- | --- |
| C1 | 10 | First Edge: 12 direct damage | Brace: 10 direct mitigation | First Aid: heal 15 |
| C2 | 12 | Rift Snare: current enemy ETA +2 s | Supply Guard: current MP/Combo loss ward 100% | Rally Step: player board opportunity +2 s |
| C3 | 15 | Fracture Cut: 18 direct damage | Riposte Guard: prevented-damage counter 50% | Second Wind: heal 25 |
| C4 | 18 | Shieldbreaker: 28 direct damage | Bulwark: 28 direct mitigation | Anchor Pulse: heal 8 + current enemy ETA +2 s |
| C5 | 22 | Severing Drive: 24 direct damage + board opportunity +2 s | Last Guard: current-action lethal floor 1, one charge | Field Mend: heal 40 |
| C6 | 26 | Execution Edge: 34 direct damage | Aegis Relay: direct action = mitigation 35 + counter 50%; resource-loss action = ward 100%; both packages add board opportunity +2 s | Breather: board opportunity +3 s + current enemy ETA +2 s |
| C7 | 31 | Rift Lancer: 38 direct damage + current enemy ETA +1 s | Counterwall: mitigation 28 + counter 75% | Vanguard Refresh: heal 32 + board opportunity +3 s |
| C8 | 37 | Sundering Chain: 44 direct damage + board opportunity +2 s | Preservation Field: resource ward 100% + board opportunity +3 s | Suspension Chant: current enemy ETA +4 s + heal 18 |
| C9 | 44 | Gatebreak Sequence: 52 direct damage + current enemy ETA +3 s | Bastion Return: lethal floor 1, one charge + counter 100% | Rift Renewal: heal 45 + current enemy ETA +3 s |
| C10 | 52 | Frontier Verdict: 62 direct damage + current enemy ETA +4 s | Vanguard Aegis: direct action = mitigation 50 + counter 100%; resource-loss action = ward 100% | Second Dawn: heal 60 + board opportunity +4 s + current enemy ETA +4 s |

`current enemy ETA +N s` means enemy deceleration. The player-side opportunity window has a hard cap of `12.0` stored seconds. It consumes real elapsed time only while LINE is active and simulation is running; it passes `0.0` to LINE gravity/lock while it has coverage, but leaves LINE input enabled and sends the full unscaled frame delta to the enemy scheduler. It neither advances nor consumes while CHAIN is active, during either pause, or after terminal state.

The fallback search is exact:

```text
opening_combo = current Combo C
for stage from C down to 1:
  converted_combo = C - stage
  effective_mp = min(60, current MP + 5 * converted_combo)
  choose the first stage whose MP cost <= effective_mp
commit: MP = effective_mp - chosen MP cost; Combo = 0
```

The candidate must be a valid lane/stage definition and must have one legal current-action variant when it contains an adaptive package. If no candidate is feasible, preview `INSUFFICIENT_RESOURCE` and mutate nothing.

## File structure and PR boundaries

| Delivery | Files | Responsibility |
| --- | --- | --- |
| PR A — CHAIN/resource core | `production_combat_state.gd`, `chain_board.gd`, `production_chain_config.gd`, `production_chain_session.gd`, `production_combat_runtime.gd`, `production_battle.gd`, `battle.tscn`, chain seed and focused tests | Diagonal groups, per-wave Combo/MP, 60/10 caps, deterministic failed-swap lock prompt. |
| PR B — Skill/time control | `player_board_opportunity_state.gd` (new), scheduler, Skill catalog/session/resolver/executor, bootstrap, skill seed, runtime/UI/scene and focused tests | Data-driven C1–C10 resolution, fallback, target-separated timing, category preview/CONFIRM. |
| PR C — First session | `first_session_progress.gd` (new), `battle_briefing.gd` (new), `battle_briefing.tscn` (new), tutorial state/seed (new), bootstrap/runtime/UI/scene/project config and focused tests | Full rule review, safe continuous live practice, re-openable rules, real encounter handoff. |
| Documentation/verification | This plan, current canonical contracts, human evidence index/contract, Issue #82 and PR descriptions | Evidence boundaries, accepted seeds, exact-head/runtime/Human readback. |

The same implementation agent must not combine PR A/B/C just to reduce Git work. Each PR is a review gate and has an independently runnable behavior. A defect in a later PR is fixed against latest merged `main`, never by rewriting an older open PR.

## Feasibility and research evidence

| Surface | Classification | Current evidence and bounded delivery |
| --- | --- | --- |
| Diagonal CHAIN, per-wave reward, caps, and 1-MP lock | `FEASIBLE` | `ChainBoard` already owns adjacency/snapshots/groups and `ProductionCombatRuntime` already owns event-to-resource commit; PR A moves only missing group axes, wave lengths, and resource transactions into those owners. |
| C1–C10 data and category-resolved preview/CONFIRM | `PARTIAL` | The current JSON/catalog/session/executor path is data-driven and pause-aware, but it is legacy manual Tier 1–6 with an unexecuted multiplier. PR B replaces that schema and removes the multiplier dependency. |
| Player board opportunity | `PARTIAL` | `ProductionLineSession.tick(delta)` is isolated from `EnemyActionScheduler.tick_simulation(delta)`. `PlayerBoardOpportunityState` is a narrow LINE-delta gate, so it is feasible without a global clock or inactive-workspace simulation. |
| Exact current Telegraph ETA adjustment | `FEASIBLE` | Scheduler already owns `_remaining_seconds`, `current_action_id()`, `next_action_id()`, and `is_action_committed()`. PR B adds an ID-checked adjustment method at that owner. |
| First briefing and safe live practice | `FEASIBLE` | `project.godot` has one direct Battle entry and runtime/telemetry already own simulation state. PR C adds a small entry scene, a one-bit local completion record, and observed tutorial state without a parallel economy or combat loop. |
| Runtime readability, strategy quality, and fun | `BLOCKED_UNVERIFIED` | Automated tests can prove deterministic behavior only. Target-device runtime receipt and three independent Human first-exposure sessions are still required. |

Fresh official Godot research was read on 2026-08-29: [Engine time scale](https://docs.godotengine.org/en/stable/classes/class_engine.html), [pausing and process modes](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html), and [SceneTree](https://docs.godotengine.org/en/stable/classes/class_scenetree.html). `Engine.time_scale` affects timers and delta-driven simulation broadly, so it is rejected. Existing tokenized pause and local runtime delta ownership are the compatible implementation path.

### Task 1: Lock caps and atomic resource contracts (PR A)

**Files:**
- Modify: `src/production/combat/production_combat_state.gd:5-63`
- Modify: `tests/unit/test_combat_state.gd`

**Interfaces:**
- Produces `const MP_CAP: int = 60`, `const COMBO_CAP: int = 10`.
- Produces `apply_chain_wave(line_lengths: Array[int]) -> Dictionary`, `reset_combo() -> int`, `try_spend_mp(amount: int) -> bool`, and `try_commit_combo_skill(mp_cost: int, opening_combo: int, resolved_stage: int) -> Dictionary`.
- `apply_chain_wave` returns `{ "combo_before", "combo_after", "mp_requested", "mp_applied", "mp_lost_at_cap" }`.
- `try_commit_combo_skill` returns `{ "committed", "resolved_stage", "converted_combo", "mp_spent", "combo_spent" }` and changes neither field on failure.

- [ ] **Step 1: Write failing cap, per-wave, and fallback tests.**

```gdscript
func test_chain_wave_awards_combo_before_formula_and_caps_mp_and_combo() -> void:
    var state = load(COMBAT_STATE_PATH).new(100)
    state.energy = 58
    state.stock = 9
    var event: Dictionary = state.apply_chain_wave([5, 5])
    assert_eq(event["combo_after"], 10)
    assert_eq(event["mp_requested"], 17) # 5 + 5 - 3 + 10
    assert_eq(state.energy, 60)
    assert_eq(event["mp_lost_at_cap"], 15)

func test_shortage_fallback_converts_only_surplus_combo_and_spends_opening_combo_once() -> void:
    var state = load(COMBAT_STATE_PATH).new(100)
    state.energy = 8
    state.stock = 5
    var result: Dictionary = state.try_commit_combo_skill(18, 5, 4)
    assert_true(result["committed"])
    assert_eq(result["converted_combo"], 1)
    assert_eq(state.energy, 0)
    assert_eq(state.stock, 0)
```

- [ ] **Step 2: Run the focused test and confirm the old cap-6/depth behavior fails.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit`

Expected: FAIL because `MP_CAP`, `COMBO_CAP`, `apply_chain_wave`, and `try_commit_combo_skill` do not exist.

- [ ] **Step 3: Implement only the atomic state mutations.**

```gdscript
func apply_chain_wave(line_lengths: Array[int]) -> Dictionary:
    var qualified_total := 0
    for length in line_lengths:
        if length >= 3:
            qualified_total += length
    if qualified_total == 0:
        return {"combo_before": stock, "combo_after": stock, "mp_requested": 0, "mp_applied": 0, "mp_lost_at_cap": 0}
    var combo_before := stock
    stock = mini(COMBO_CAP, stock + 1)
    var requested := qualified_total - 3 + stock
    var before_mp := energy
    energy = clampi(energy + requested, 0, MP_CAP)
    return {"combo_before": combo_before, "combo_after": stock, "mp_requested": requested, "mp_applied": energy - before_mp, "mp_lost_at_cap": requested - (energy - before_mp)}

func try_commit_combo_skill(mp_cost: int, opening_combo: int, resolved_stage: int) -> Dictionary:
    var converted := opening_combo - resolved_stage
    if opening_combo != stock or resolved_stage < 1 or converted < 0 or mp_cost < 0:
        return {"committed": false, "reason": "INVALID_COMBO_TRANSACTION"}
    var available := mini(MP_CAP, energy + converted * 5)
    if available < mp_cost:
        return {"committed": false, "reason": "INSUFFICIENT_RESOURCE"}
    energy = available - mp_cost
    stock = 0
    return {"committed": true, "resolved_stage": resolved_stage, "converted_combo": converted, "mp_spent": mp_cost, "combo_spent": opening_combo}
```

- [ ] **Step 4: Run focused state tests and the existing Line reward tests.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit`

Expected: PASS; negative MP deltas, unqualified line lengths, a 60-MP overflow, Combo 10, and failed shortage transactions are deterministic.

- [ ] **Step 5: Commit the atomic resource boundary.**

```bash
git add src/production/combat/production_combat_state.gd tests/unit/test_combat_state.gd
git commit -m "feat: align combo and mp resource caps"
```

### Task 2: Add both diagonal CHAIN axes and maximal-line wave data (PR A)

**Files:**
- Modify: `src/production/chain/chain_board.gd:52-107`
- Modify: `src/production/chain/chain_resolver.gd:13-63`
- Modify: `tests/production/chain/test_chain_board.gd`
- Modify: `tests/production/chain/test_chain_board_resolution.gd`

**Interfaces:**
- `ChainBoard.find_match_groups(3)` returns groups with axes `H`, `V`, `D_DOWN_RIGHT`, or `D_DOWN_LEFT`; each group is one maximal contiguous run.
- `ChainResolver.resolve_existing_matches()` returns each wave with `groups`, `cleared_count`, and `qualified_line_lengths` copied from `group["cells"].size()`.
- Crossing groups count individually in `qualified_line_lengths`; `matched_cells()` still clears each cell once.

- [ ] **Step 1: Add failing diagonal and crossing-line tests.**

```gdscript
func test_match_groups_detect_both_diagonal_axes_as_distinct_maximal_lines() -> void:
    var board = _board(5, 5)
    _fill(board, [["A","B","C","D","E"], ["F","A","G","H","I"], ["J","K","A","L","M"], ["N","O","P","A","Q"], ["R","S","T","U","A"]])
    var groups: Array = board.find_match_groups()
    assert_eq(groups.size(), 1)
    assert_eq(groups[0]["axis"], "D_DOWN_RIGHT")
    assert_eq(groups[0]["cells"].size(), 5)

func test_crossing_groups_clear_once_but_report_both_line_lengths() -> void:
    var resolution: Dictionary = resolver.resolve_existing_matches()
    assert_eq(resolution["waves"][0]["qualified_line_lengths"], [3, 3])
    assert_eq(resolution["waves"][0]["cleared_count"], 5)
```

- [ ] **Step 2: Run chain board tests and confirm diagonal groups/wave lengths are absent.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/chain -ginclude_subdirs -gexit`

Expected: FAIL because the old board only emits `H` and `V`, and the resolver has no `qualified_line_lengths`.

- [ ] **Step 3: Implement four-direction maximal-run scanning and propagate lengths.**

```gdscript
const MATCH_DIRECTIONS := [
    {"axis": "H", "step": Vector2i.RIGHT},
    {"axis": "V", "step": Vector2i.DOWN},
    {"axis": "D_DOWN_RIGHT", "step": Vector2i(1, 1)},
    {"axis": "D_DOWN_LEFT", "step": Vector2i(-1, 1)},
]

func _is_run_start(position: Vector2i, step: Vector2i, symbol: String) -> bool:
    return not _inside(position - step) or get_cell(position - step) != symbol
```

For every non-empty cell and each direction, scan only when `_is_run_start` is true, append a group only when its maximal run has at least three cells, then preserve the existing unique-cell clearing path.

- [ ] **Step 4: Run chain tests and assert a five-line remains one 5-length group.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/chain -ginclude_subdirs -gexit`

Expected: PASS; neither diagonal is duplicated from an interior cell, a crossing clears once, and a length-five run is never split into three-length fragments.

- [ ] **Step 5: Commit the match grammar.**

```bash
git add src/production/chain/chain_board.gd src/production/chain/chain_resolver.gd tests/production/chain
git commit -m "feat: add diagonal chain groups and wave lengths"
```

### Task 3: Resolve CHAIN rewards per wave and offer the fixed MP lock (PR A)

**Files:**
- Modify: `src/production/chain/production_chain_config.gd:4-92`
- Modify: `src/production/chain/production_chain_session.gd:4-110`
- Modify: `src/production/runtime/puzzle_workspace_manager.gd:48-77`
- Modify: `src/production/runtime/production_combat_runtime.gd:41-175`
- Modify: `data/production/chain_runtime_seed.json`
- Modify: `tests/production/chain/test_chain_runtime_config.gd`
- Modify: `tests/production/runtime/test_realtime_chain_session.gd`
- Modify: `tests/production/integration/test_realtime_combat_runtime.gd`

**Interfaces:**
- Remove `stock_by_chain_depth`; `ProductionChainConfig` retains board/palette/random seed only and validates source `TETRIS-CHAIN-038`.
- `ProductionChainSession.has_pending_failed_swap()`, `keep_pending_failed_swap()`, and `discard_pending_failed_swap()` own only board snapshots and input lock.
- `ProductionCombatRuntime.try_chain_swap(first, second)` resets Combo once for `NO_MATCH`; `confirm_chain_mp_lock()` spends exactly 1 MP through `ProductionCombatState.try_spend_mp(1)` before applying the pending swapped snapshot.
- Successful `production_chain_resolved` events carry all waves; runtime calls `apply_chain_wave(wave["qualified_line_lengths"])` once per wave.

- [ ] **Step 1: Add failing per-wave/cap/lock tests.**

```gdscript
func test_failed_swap_resets_combo_and_keep_choice_costs_one_mp_without_reward() -> void:
    var result: Dictionary = runtime.try_chain_swap(Vector2i(0, 1), Vector2i(1, 1))
    assert_eq(result["reason"], "NO_MATCH")
    assert_eq(player.stock, 0)
    assert_true(chain.has_pending_failed_swap())
    assert_true(runtime.confirm_chain_mp_lock()["kept"])
    assert_eq(player.energy, 19)
    assert_eq(chain.board.snapshot(), result["swapped_snapshot"])

func test_runtime_awards_every_wave_in_order() -> void:
    chain.events.append({"kind": "production_chain_resolved", "waves": [{"qualified_line_lengths": [3]}, {"qualified_line_lengths": [4]}]})
    runtime.tick(0.1)
    assert_eq(player.stock, 2)
    assert_eq(player.energy, 7) # (3-3+1) + (4-3+2)
```

- [ ] **Step 2: Run the focused chain/runtime suite and confirm map-depth rewards and lock APIs fail.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Expected: FAIL because the old session restores without a pending choice and runtime calls `gain_stock(stock_requested)` once after all waves.

- [ ] **Step 3: Implement snapshot-only pending lock and runtime-owned resource operations.**

```gdscript
func confirm_chain_mp_lock() -> Dictionary:
    var chain = _workspace_manager.chain_session
    if chain == null or not chain.has_pending_failed_swap():
        return {"kept": false, "reason": "NO_PENDING_LOCK"}
    if not _player.try_spend_mp(1):
        return {"kept": false, "reason": "INSUFFICIENT_MP"}
    if not chain.keep_pending_failed_swap():
        _player.apply_energy_delta(1)
        return {"kept": false, "reason": "LOCK_APPLY_FAILED"}
    return {"kept": true, "mp_cost": 1}
```

`PuzzleWorkspaceManager.process_safe_handoff()` must return `CHAIN_LOCK_CHOICE_PENDING` while a failed-swap choice exists; enemy time continues and neither board resets.

- [ ] **Step 4: Run focused suite and inspect serialized event payloads.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Expected: PASS; a failed swap cannot mint a reward, lock failure restores no MP change, two waves get two formula applications, Combo cannot exceed ten, and MP cannot exceed sixty.

- [ ] **Step 5: Commit PR A runtime behavior.**

```bash
git add src/production/chain src/production/runtime data/production/chain_runtime_seed.json tests/production/chain tests/production/runtime tests/production/integration
git commit -m "feat: resolve chain rewards per wave and support mp lock"
```

### Task 4: Replace Tier data with validated C1–C10 definitions (PR B)

**Files:**
- Modify: `data/production/vanguard_skill_seed.json`
- Modify: `src/production/skill/production_skill_catalog.gd:5-82`
- Modify: `tests/production/runtime/test_tactical_skill_session.gd`
- Create: `tests/production/skill/test_combo_stage_skill_catalog.gd`

**Interfaces:**
- A definition has `id`, `lane`, `stage`, `combo_cost`, `mp_cost`, `display_name`, `preview_lines`, `effects`, and optional `action_variants`.
- `ProductionSkillCatalog.definition_for_lane_stage(lane: String, stage: int) -> Dictionary` returns one valid definition or `{}`.
- `ProductionSkillCatalog.resolve_effects(definition: Dictionary, action_kind: String) -> Dictionary` returns `{ "ok", "effects", "preview_lines" }`; an adaptive definition has exactly one matching variant for `DIRECT_HP_RATIO`, `ENERGY_LOSS`, or `STOCK_LOSS`.
- Allowed primitive operations are `DAMAGE_SINGLE`, `HEAL_SELF`, `MITIGATE_CURRENT_DIRECT`, `COUNTER_FROM_PREVENTED_DAMAGE`, `PROTECT_RESOURCE_LOSS`, `LETHAL_SAFETY`, `GRANT_PLAYER_BOARD_OPPORTUNITY`, and `ADJUST_CURRENT_ENEMY_ETA`.

- [ ] **Step 1: Add failing schema and content-count tests.**

```gdscript
func test_catalog_has_exactly_one_definition_for_each_lane_and_stage() -> void:
    var catalog = _catalog()
    assert_eq(catalog.technique_count(), 30)
    for lane in ["ATTACK", "DEFENSE", "SUPPORT"]:
        for stage in range(1, 11):
            var definition: Dictionary = catalog.definition_for_lane_stage(lane, stage)
            assert_eq(definition["stage"], stage)
            assert_eq(definition["combo_cost"], stage)

func test_adaptive_aegis_preview_has_only_one_current_action_package() -> void:
    var direct = catalog.resolve_effects(catalog.definition_for_lane_stage("DEFENSE", 6), "DIRECT_HP_RATIO")
    var resource = catalog.resolve_effects(catalog.definition_for_lane_stage("DEFENSE", 6), "ENERGY_LOSS")
    assert_true(direct["ok"])
    assert_true(resource["ok"])
    assert_ne(direct["preview_lines"], resource["preview_lines"])
```

- [ ] **Step 2: Run the catalog tests and confirm the Tier-6 schema fails.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/skill -ginclude_subdirs -gexit`

Expected: FAIL because legacy entries use `tier`, reject stages above six, allow unimplemented multiplier data, and have eighteen definitions.

- [ ] **Step 3: Replace the seed and catalog validator with the contract schema.**

```gdscript
func _validate_definition(definition: Dictionary) -> bool:
    var lane := String(definition.get("lane", ""))
    var stage := int(definition.get("stage", 0))
    if not LANES.has(lane) or stage < 1 or stage > 10:
        return false
    if int(definition.get("combo_cost", -1)) != stage or int(definition.get("mp_cost", -1)) < 0:
        return false
    return _validate_effect_list(definition.get("effects", [])) and _validate_variants(definition.get("action_variants", []))
```

Do not include `CONDITIONAL_MULTIPLIER`, `DAMAGE_AOE`, status placeholders, `Haste`, `Battle Trance`, or a hidden future-action target in the new seed. Encode Aegis Relay and Vanguard Aegis as `action_variants`, with their player-board opportunity as ordinary shared effects.

- [ ] **Step 4: Run catalog/session tests and validate seed JSON.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Run: `python -c "import json; json.load(open('data/production/vanguard_skill_seed.json', encoding='utf-8')); print('skill seed JSON: OK')"`

Expected: PASS; every one of the thirty authored entries is visible in the catalog and every adaptive preview has one legal package.

- [ ] **Step 5: Commit the C1–C10 data contract.**

```bash
git add data/production/vanguard_skill_seed.json src/production/skill/production_skill_catalog.gd tests/production/skill tests/production/runtime/test_tactical_skill_session.gd
git commit -m "feat: define combo-resolved skill stages"
```

### Task 5: Add target-separated board opportunity and current-ETA primitives (PR B)

**Files:**
- Create: `src/production/runtime/player_board_opportunity_state.gd`
- Modify: `src/production/runtime/enemy_action_scheduler.gd:47-96`
- Modify: `src/production/skill/production_effect_executor.gd:7-67`
- Modify: `src/production/runtime/production_combat_runtime.gd:17-175`
- Modify: `src/production/session/production_battle_bootstrap.gd:14-70`
- Create: `tests/production/runtime/test_player_board_opportunity_state.gd`
- Modify: `tests/production/runtime/test_enemy_action_scheduler.gd`
- Modify: `tests/production/integration/test_realtime_combat_runtime.gd`

**Interfaces:**
- `PlayerBoardOpportunityState.grant(seconds: float) -> Dictionary` caps stored seconds at `12.0`.
- `PlayerBoardOpportunityState.consume_line_delta(delta: float) -> Dictionary` returns `{ "line_delta", "consumed_seconds", "remaining_seconds" }` and never consumes on CHAIN/pause because runtime calls it only before an active LINE tick.
- `EnemyActionScheduler.adjust_current_eta(action_id: String, delta_seconds: float) -> Dictionary` checks exact current ID and `not is_action_committed()`, clamps the new ETA to at least `commit_lead_seconds`, and returns `{ "adjusted", "before_seconds", "after_seconds", "action_id" }`.
- Runtime constructor receives `board_opportunity`; `snapshot()` adds `player_board_opportunity_seconds` and `last_time_feedback`.

- [ ] **Step 1: Add failing independence and commit-boundary tests.**

```gdscript
func test_player_board_opportunity_freezes_only_line_gravity_while_enemy_eta_uses_full_delta() -> void:
    runtime.grant_player_board_opportunity(2.0)
    var eta_before: float = scheduler.remaining_seconds()
    runtime.tick(1.0)
    assert_eq(fake_line.last_delta, 0.0)
    assert_almost_eq(scheduler.remaining_seconds(), eta_before - 1.0, 0.001)

func test_current_eta_adjustment_rejects_next_action_and_committed_action() -> void:
    var next_id := scheduler.next_action_id()
    assert_false(scheduler.adjust_current_eta(next_id, 2.0)["adjusted"])
    scheduler.tick_simulation(8.0, _context())
    assert_false(scheduler.adjust_current_eta(scheduler.current_action_id(), 2.0)["adjusted"])
```

- [ ] **Step 2: Run timing tests and confirm no local time-domain primitives exist.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/runtime -ginclude_subdirs -gexit`

Expected: FAIL because current runtime forwards the same delta to Line and scheduler, and scheduler has no ETA adjustment API.

- [ ] **Step 3: Implement local time-domain ownership without global scaling.**

```gdscript
func _tick_active_puzzle(delta: float) -> void:
    if _workspace_manager.active_workspace() == "LINE" and _workspace_manager.line_session != null:
        var budget: Dictionary = _board_opportunity.consume_line_delta(delta)
        _workspace_manager.line_session.tick(float(budget["line_delta"]))
    elif _workspace_manager.active_workspace() == "CHAIN" and _workspace_manager.chain_session != null and _workspace_manager.chain_session.is_resolving():
        _workspace_manager.chain_session.complete_pending_resolution()
```

`ProductionEffectExecutor` passes `context["board_opportunity"]` only to `GRANT_PLAYER_BOARD_OPPORTUNITY` and passes `context["enemy_scheduler"]` only to `ADJUST_CURRENT_ENEMY_ETA`; neither primitive accepts the other target. Keep `Engine.time_scale` absent from the repository.

- [ ] **Step 4: Run timing, pause, and integration tests.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Expected: PASS; player timing does not change enemy ETA, enemy timing does not change line opportunity, paused time consumes neither, and a current ETA never changes a Next Forecast ID.

- [ ] **Step 5: Commit local time primitives.**

```bash
git add src/production/runtime/player_board_opportunity_state.gd src/production/runtime/enemy_action_scheduler.gd src/production/runtime/production_combat_runtime.gd src/production/skill/production_effect_executor.gd src/production/session/production_battle_bootstrap.gd tests/production/runtime tests/production/integration
git commit -m "feat: add target separated board and eta timing"
```

### Task 6: Resolve category preview, fallback, and atomic CONFIRM (PR B)

**Files:**
- Modify: `src/production/skill/production_skill_session.gd:14-77`
- Modify: `src/production/skill/production_technique_resolver.gd:10-48`
- Modify: `src/production/runtime/production_combat_runtime.gd:87-151`
- Modify: `tests/production/runtime/test_tactical_skill_session.gd`
- Modify: `tests/production/integration/test_realtime_combat_runtime.gd`

**Interfaces:**
- `ProductionSkillSession.select_category(category: String, context: Dictionary) -> Dictionary` returns its resolved preview; it has no `select_technique` path.
- `ProductionSkillSession.selected_preview() -> Dictionary` includes `opening_combo`, `resolved_stage`, `converted_combo`, `mp_cost`, `preview_lines`, `effects`, and `ready`.
- `ProductionCombatRuntime.select_skill_category(category: String) -> Dictionary` builds context from player, enemy, response state, scheduler, board opportunity, current action ID, and current action kind.
- `ProductionCombatRuntime.open_skill()` returns `ENEMY_ACTION_COMMITTED` and does not acquire a pause token when the scheduler is committed.

- [ ] **Step 1: Add failing current-stage, deliberate-C5, fallback, cancel, and commit-once tests.**

```gdscript
func test_category_preview_resolves_current_c5_without_manual_lower_stage_selection() -> void:
    player.stock = 5
    assert_true(session.open())
    var preview: Dictionary = session.select_category("DEFENSE", _direct_context())
    assert_eq(preview["resolved_stage"], 5)
    assert_eq(preview["converted_combo"], 0)
    assert_eq(preview["display_name"], "Last Guard")
    assert_false(session.has_method("select_technique"))

func test_previewed_shortage_fallback_uses_highest_feasible_lower_stage_on_confirm() -> void:
    player.stock = 5
    player.energy = 8
    var preview: Dictionary = session.select_category("ATTACK", _direct_context())
    assert_eq(preview["resolved_stage"], 4)
    assert_eq(preview["converted_combo"], 1)
    assert_true(session.commit_selected(_direct_context())["committed"])
    assert_eq(player.stock, 0)
    assert_eq(player.energy, 0)
```

- [ ] **Step 2: Run Skill/runtime tests and confirm the legacy manual selection API fails the new contract.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/runtime -ginclude_subdirs -gexit`

Expected: FAIL because the current session requires a technique ID and does not compute fallback preview data.

- [ ] **Step 3: Implement deterministic preview and all-or-nothing commit.**

```gdscript
func select_category(category: String, context: Dictionary) -> Dictionary:
    if _pause_token == 0 or not LANES.has(category):
        return {"selected": false, "reason": "INVALID_CATEGORY"}
    _selected_category = category
    _selected_preview = _preview_for_opening_combo(category, context)
    return _selected_preview.duplicate(true)

func commit_selected(context: Dictionary) -> Dictionary:
    if _pause_token == 0 or _selected_preview.is_empty() or not bool(_selected_preview.get("ready", false)):
        return {"committed": false, "reason": "NO_READY_PREVIEW"}
    var transaction := _combat_state.try_commit_combo_skill(int(_selected_preview["mp_cost"]), int(_selected_preview["opening_combo"]), int(_selected_preview["resolved_stage"]))
    if not bool(transaction.get("committed", false)):
        return transaction
    var resolution := _technique_resolver.resolve_effects(Array(_selected_preview["effects"]), context)
    if not bool(resolution.get("ok", false)):
        _combat_state.restore_resource_snapshot(_selected_preview["resource_snapshot"])
        return {"committed": false, "reason": resolution.get("reason", "EFFECT_FAILED")}
    cancel()
    return {"committed": true, "preview": _selected_preview.duplicate(true), "results": resolution["results"]}
```

Add `resource_snapshot()` / `restore_resource_snapshot(snapshot)` to `ProductionCombatState` in the same task so rollback restores both MP and Combo if any effect fails.

- [ ] **Step 4: Run focused Skill, scheduler, and integration tests.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Expected: PASS; category preview spends nothing, C5 remains C5 when affordable, fallback is non-voluntary and highest-feasible, cancel restores exact paused state, confirm applies exactly once, and committed enemy actions cannot be retroactively paused.

- [ ] **Step 5: Commit the current-Combo Skill flow.**

```bash
git add src/production/combat/production_combat_state.gd src/production/skill src/production/runtime/production_combat_runtime.gd tests/production/runtime tests/production/integration
git commit -m "feat: resolve skills from current combo on confirm"
```

### Task 7: Replace the Tier grid with readable preview, confirmation, and timing feedback (PR B)

**Files:**
- Modify: `scenes/production/battle.tscn:195-284`
- Modify: `src/production/ui/production_battle.gd:18-237`
- Modify: `tests/production/ui/test_realtime_battle_surface.gd`
- Create: `tests/production/ui/test_combo_skill_preview_surface.gd`

**Interfaces:**
- Replace `TierGrid/Tier1..Tier6` with `SkillPreview: RichTextLabel`, `ConfirmButton: Button`, `CancelButton: Button`, and `TimingFeedback: Label`.
- Add `ChainLockPrompt: PanelContainer` with `KeepSwapButton` and `RestoreSwapButton` under `PuzzleColumn`; it is visible only for `has_pending_failed_swap()`.
- `ProductionBattle.select_skill_category(category) -> Dictionary` binds returned preview before confirming; `_use_selected_skill()` calls runtime only through `ConfirmButton`.
- `TimingFeedback` renders target, changed value, and unchanged value from `snapshot()["last_time_feedback"]` for 4.0 real UI seconds after a confirmed time effect.

- [ ] **Step 1: Add failing scene and presenter tests.**

```gdscript
func test_skill_surface_has_categories_one_preview_and_explicit_confirm_without_tier_grid() -> void:
    assert_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/TierGrid"))
    assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/SkillPreview"))
    assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/ConfirmButton"))

func test_timing_feedback_names_target_and_unchanged_domain() -> void:
    battle._runtime = _runtime_with_feedback({"target": "PLAYER", "changed": "Board play opportunity +2.0 s", "unchanged": "Enemy ETA unchanged"})
    battle._refresh_runtime_labels()
    assert_string_contains(battle.get_node(TIMING_FEEDBACK_PATH).text, "Enemy ETA unchanged")
```

- [ ] **Step 2: Run UI tests and confirm the old manual-tier surface fails.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/ui -ginclude_subdirs -gexit`

Expected: FAIL because `TierGrid`, `select_skill_tier`, and `UseButton` still define the current scene.

- [ ] **Step 3: Build the textual, current-theme UI path.**

```gdscript
func select_skill_category(category: String) -> Dictionary:
    if _runtime == null or not _runtime.is_skill_open():
        return {"selected": false, "reason": "SKILL_NOT_OPEN"}
    var preview: Dictionary = _runtime.select_skill_category(category)
    _skill_preview.text = String(preview.get("formatted_preview", ""))
    _confirm_button.disabled = not bool(preview.get("ready", false))
    return preview
```

Use the existing named theme and Parchment Field Manual hierarchy. The preview must expose the resolved stage, target, effect, unchanged comparison value, fallback conversion when present, and total cost before `CONFIRM` is enabled. Do not add imagery, icons, pseudo-text, or a visual card wall to convey rules.

- [ ] **Step 4: Run UI plus full production tests and inspect a 960×540 local runtime scene.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Run: `godot --headless --path . --editor --quit`

Expected: PASS; the active skill path has exactly three categories, one preview and one confirm action; the current Telegraph remains visible during the full pause; no Tier button or unconfirmed auto-cast exists.

- [ ] **Step 5: Commit the combat surface change.**

```bash
git add scenes/production/battle.tscn src/production/ui/production_battle.gd tests/production/ui
git commit -m "feat: present combo resolved skill confirmation"
```

### Task 8: Build a full-rule first-session briefing with a minimal persistent completion record (PR C)

**Files:**
- Create: `src/production/session/first_session_progress.gd`
- Create: `src/production/ui/battle_briefing.gd`
- Create: `scenes/production/battle_briefing.tscn`
- Create: `data/production/first_session_briefing_seed.json`
- Modify: `project.godot:8`
- Modify: `scenes/production/battle.tscn`
- Modify: `src/production/ui/production_battle.gd`
- Create: `tests/production/session/test_first_session_progress.gd`
- Create: `tests/production/ui/test_battle_briefing.gd`

**Interfaces:**
- `FirstSessionProgress.is_briefing_complete() -> bool`, `mark_briefing_complete() -> bool`, `reset_for_test() -> void`; it stores only `{ "briefing_complete": true }` at `user://first_session_progress.json`.
- `BattleBriefing.configure(reference_mode: bool = false) -> void`; first visit disables Deploy until the rules `ScrollContainer` reaches its end, later visit enables Deploy immediately, reference mode never changes progress.
- `BattleBriefing.deployed` signal causes the main scene to change to `battle.tscn`; a `RulesButton` in Battle opens the same scene in reference mode inside a `PopupPanel`.
- The seed text contains only existing world facts: Vanguard, Frontier Gate, Gatebreaker, imminent threat, LINE MP, CHAIN rule/reward/lock, C1–C10 category preview/confirm/fallback, and target-separated timing contrast.

- [ ] **Step 1: Add failing progress and briefing-gate tests.**

```gdscript
func test_first_visit_requires_full_rules_review_but_later_visit_can_deploy_immediately() -> void:
    progress.reset_for_test()
    briefing.configure()
    assert_true(briefing.deploy_button.disabled)
    briefing.rules_scroll.scroll_vertical = briefing.rules_scroll.get_v_scroll_bar().max_value
    briefing._on_rules_scrolled()
    assert_false(briefing.deploy_button.disabled)
    briefing._on_deploy_pressed()
    assert_true(progress.is_briefing_complete())
    var revisit = _briefing()
    revisit.configure()
    assert_false(revisit.deploy_button.disabled)
```

- [ ] **Step 2: Run briefing tests and confirm the direct-to-battle main scene fails.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production/session -ginclude_subdirs -gexit`

Expected: FAIL because there is no progress object, briefing scene, scroll gate, or reference-mode surface.

- [ ] **Step 3: Implement the small save and structured briefing.**

```gdscript
func _on_rules_scrolled() -> void:
    if _reference_mode or _progress.is_briefing_complete():
        _deploy_button.disabled = false
        return
    var bar := _rules_scroll.get_v_scroll_bar()
    _deploy_button.disabled = bar.value + bar.page < bar.max_value

func _on_deploy_pressed() -> void:
    if _deploy_button.disabled:
        return
    _progress.mark_briefing_complete()
    deployed.emit()
```

The visible briefing order is: immediate Frontier Gate threat; live ETA begins only on Deploy; LINE creates MP; CHAIN has orthogonal H/V/diagonal 3+ plus per-wave reward and 1-MP lock; Combo can be spent by category at the current stage; `CONFIRM` is the commitment; player board opportunity and current enemy ETA are different effects. No lore history, faction, named character, asset, or tutorial-only economy is added.

- [ ] **Step 4: Run briefing/UI tests and import the project.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Run: `godot --headless --path . --editor --quit`

Expected: PASS; keyboard or pointer scrolling can satisfy the accessible review boundary, later runs expose immediate Deploy plus a readable rule summary, and no simulation begins before Deploy.

- [ ] **Step 5: Commit the briefing entry surface.**

```bash
git add project.godot scenes/production/battle_briefing.tscn scenes/production/battle.tscn src/production/session/first_session_progress.gd src/production/ui/battle_briefing.gd src/production/ui/production_battle.gd data/production/first_session_briefing_seed.json tests/production/session tests/production/ui
git commit -m "feat: add first session rules briefing"
```

### Task 9: Add safe continuous practice in the real encounter (PR C)

**Files:**
- Create: `src/production/session/first_session_tutorial_state.gd`
- Modify: `data/production/gatebreaker_realtime_timing_seed.json`
- Modify: `src/production/runtime/gatebreaker_realtime_timing_config.gd`
- Modify: `src/production/runtime/enemy_action_scheduler.gd`
- Modify: `src/production/runtime/production_combat_runtime.gd`
- Modify: `src/production/telemetry/production_telemetry.gd`
- Modify: `src/production/ui/production_battle.gd`
- Create: `tests/production/session/test_first_session_tutorial_state.gd`
- Modify: `tests/production/runtime/test_enemy_action_scheduler.gd`
- Modify: `tests/production/integration/test_realtime_combat_runtime.gd`
- Modify: `tests/production/telemetry/test_realtime_combat_telemetry.gd`

**Interfaces:**
- Tutorial steps are `READ_THREAT`, `LINE_REWARD`, `CHAIN_REWARD`, `SKILL_PREVIEW`, `SKILL_CONFIRM`, `FREE_PLAY`.
- The first-session seed adds `tutorial_opening_eta_seconds: 45.0` and `tutorial_nonterminal_until_first_confirm: true`.
- Scheduler uses `tutorial_opening_eta_seconds` only for its first displayed current action after Deploy; it still decrements continuously.
- Before first confirmed Skill, enemy direct damage obeys an explicit nonterminal floor of 1 HP; resource loss, board play, switching, and all timing remain real. The guard is removed permanently on first confirmed Skill.
- Telemetry records `TUTORIAL_STEP_COMPLETED`, `TUTORIAL_SAFE_OPENING_STARTED`, and `TUTORIAL_FREE_PLAY_STARTED` with simulation time.

- [ ] **Step 1: Add failing safe-opening and seamless-handoff tests.**

```gdscript
func test_safe_opening_uses_live_45_second_eta_and_cannot_defeat_before_confirm() -> void:
    runtime.start_battle()
    assert_almost_eq(runtime.snapshot()["enemy_eta_seconds"], 45.0, 0.001)
    runtime.tick(44.0)
    assert_false(runtime.is_terminal())
    runtime.tick(1.0)
    assert_gte(player.hp, 1)

func test_first_confirm_ends_guard_without_resetting_same_encounter() -> void:
    var board_before := workspace.line_session.snapshot_runtime_state()
    assert_true(_confirm_c1_skill(runtime)["committed"])
    assert_true(tutorial.is_free_play())
    assert_eq(workspace.line_session.snapshot_runtime_state(), board_before)
```

- [ ] **Step 2: Run session/runtime tests and confirm the scheduler lacks tutorial state.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Expected: FAIL because the current opening ETA is 8.0 seconds and enemy resolution has no tutorial guard ownership.

- [ ] **Step 3: Implement event-observing tutorial state and one-time safe opening.**

```gdscript
func observe(events: Array[Dictionary]) -> Array[Dictionary]:
    for event in events:
        match String(event.get("kind", "")):
            "production_line_resolved": _complete("LINE_REWARD")
            "production_chain_resolved": _complete("CHAIN_REWARD")
            "TECHNIQUE_PREVIEWED": _complete("SKILL_PREVIEW")
            "TECHNIQUE_USED":
                _complete("SKILL_CONFIRM")
                _complete("FREE_PLAY")
    return drain_events()
```

The tutorial may render short prompts from this state, but it may not acquire a pause token, replace a board, grant resources, select a category, commit a Skill, or reset the encounter. `ProductionCombatRuntime` passes the tutorial nonterminal flag only into enemy-action resolution before the first confirm.

- [ ] **Step 4: Run session, runtime, telemetry, and full GUT suites.**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/production -ginclude_subdirs -gexit`

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`

Expected: PASS; the first timer is live, tutorial prompts reflect actual events, the first explicit confirm removes only the guard, and free play continues in the same Line/Chain/enemy state.

- [ ] **Step 5: Commit the tutorial handoff.**

```bash
git add src/production/session/first_session_tutorial_state.gd src/production/runtime src/production/telemetry src/production/ui/production_battle.gd data/production/gatebreaker_realtime_timing_seed.json tests/production/session tests/production/runtime tests/production/integration tests/production/telemetry
git commit -m "feat: guide first continuous battle safely"
```

### Task 10: Exact-head verification, runtime receipt, and Human gate (after PR C)

**Files:**
- Modify: `docs/validation/PRODUCTION_HUMAN_EVIDENCE_INDEX.json` only when real receipts exist.
- Create: one dated receipt under `docs/validation/receipts/` for each actual Human session A/B/C.
- Modify: `docs/design/PROJECT_MASTER_GDD.md` and `docs/design/PROJECT_WORKSPACE_INDEX.md` only to reflect exact merged evidence, not aspiration.

**Interfaces:**
- A runtime receipt records exact SHA, Godot version, device/input, scene path, opening ETA, one diagonal CHAIN, a failed-swap decision, one C5 deliberate current-stage cast, one target-separated time effect, preview/cancel/confirm behavior, and terminal/retry outcome.
- A Human receipt follows `PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md`; `PASS` still requires three independent first-exposure sessions A/B/C.

- [ ] **Step 1: Write the exact-head verification checklist before running commands.**

```text
HEAD equals the reviewed PR head; working tree is clean; PR base is latest completed main;
no other PR was edited; C1–C10 seed parses; GUT sees no errors; tooling checks pass;
runtime receipt is labeled observed; Human evidence remains NOT_RUN until a real participant session exists.
```

- [ ] **Step 2: Run automated exact-head gates.**

Run: `python -m unittest discover -s tests/tooling -p 'test_*.py' -v`

Run: `godot --headless --path . --editor --quit`

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`

Expected: PASS with no new parser, test, or strict-GUT-log failure.

- [ ] **Step 3: Perform the target-device runtime scenario without promoting Human evidence.**

```text
Launch BattleBriefing → complete rule review → Deploy → read live 45-second ETA → make one LINE MP reward → make one diagonal CHAIN reward → fail one swap and choose restore or 1-MP keep → open Skill → inspect a C5 preview → cancel → inspect a target-separated time preview → CONFIRM → verify unchanged comparison value → finish or Retry.
```

- [ ] **Step 4: Record the actual result and adversarial closeout.**

Run five current-state attacks: canonical drift; actual code/data mismatch; player-flow/readability failure; visual/runtime-consumer confusion; and exact-head/merge regression. Correct a material finding in its owning PR, re-run only affected gates plus full regression, and do not call an unobserved Human/player claim a pass.

- [ ] **Step 5: Commit documentation evidence, open the implementation PR, and merge only after checks.**

```bash
git add docs/validation docs/design
git commit -m "docs: record phase two verification evidence"
git push origin <current-task-branch>
```

Use the exact reviewed HEAD for CI/readback, then squash merge only the current-task PR after required checks, unresolved review threads, and runtime evidence are clear. Post-merge, fetch `origin/main`, read the documented destination, and keep Human evidence `NOT_RUN` unless the required real receipts were recorded.

## Plan self-review

### Spec coverage

- CHAIN-038 is covered by Tasks 1–3: orthogonal swaps remain, H/V/diagonal runs become maximal groups, waves award Combo then MP, cap/lock/reset semantics are deterministic.
- SKILL-039/BALANCE-040/SKILL-042 are covered by Tasks 4–7: C1–C10 data, category preview, deliberate C5, forced shortage fallback, atomic confirm, and exact current-action target separation.
- The unresolved multiplier is removed from new content rather than silently skipped.
- `TETRIS-ONBOARDING-037` is covered by Tasks 8–9: short world framing, full pre-Deploy rules, live but safe opening, actual encounter handoff, later re-openable rules.
- Visual-041 is protected by Task 7: existing theme and runtime consumers only; no reference board is promoted to a production asset.
- Runtime/Human evidence ceiling is covered by Task 10.

### Placeholder scan

The plan specifies owners, paths, method names, return shapes, test cases, values, command lines, commits, and all accepted scope boundaries. It contains no unowned feature, blank data field, or deferred undefined interface.

### Type consistency

- Combo is stored in `ProductionCombatState.stock` and presented as `COMBO`; all new transaction interfaces use `opening_combo` and `resolved_stage` as integers.
- Board opportunity uses floats in seconds; enemy ETA adjustment uses a signed float only inside `EnemyActionScheduler.adjust_current_eta` and keeps its exact current action ID string.
- Chain groups carry `Array[Vector2i]`; wave rewards consume `Array[int]` lengths, so crossing clear identity never changes the formula.
- UI consumes dictionaries returned by runtime/session and never accesses catalog, response state, or scheduler directly.

## Adversarial review closeout

| Loop | Failure assumption | Recheck / correction built into the plan |
| --- | --- | --- |
| 1 — canon drift | A high Combo might browse down to C5 manually, restoring the rejected Tier wall. | Task 6 has no technique-selection API; C5 is tested only as the actual opening Combo. The fallback is the sole lower-stage resolver path. |
| 2 — reward math | A crossing or a 5-line might double-clear, split, or apply `−3` per group. | Tasks 1–3 preserve unique board clear cells, report distinct maximal group lengths, and call `apply_chain_wave` once per resolution wave. |
| 3 — time bleed | A player time effect might slow enemy ETA, or an ETA effect might touch Next Forecast. | Task 5 uses separate objects, full scheduler delta, exact current action ID, commit rejection, and an explicit ban on `Engine.time_scale`. |
| 4 — false content claim | An adaptive DEF effect or legacy multiplier might preview an effect that cannot resolve. | Task 4 selects one variant by exact current action kind and removes `CONDITIONAL_MULTIPLIER` from approved Stage data; Task 6 rolls back the resource snapshot on resolver failure. |
| 5 — evidence inflation | A scene test, generated reference, or CI pass might be described as Human or runtime validation. | Task 10 separates automated exact-head checks, target-device runtime receipt, and A/B/C Human receipts; no production asset batch or user-experience PASS is permitted before its evidence. |

## Approval gate

This contract intentionally sets numeric seeds, the LINE-only board-opportunity mechanism, a 45-second first safe ETA, exact new data fields, and three implementation PR boundaries. User approval of this plan authorizes implementation planning only until each PR’s exact issue/goal and review gate are created; it does not turn current docs or automated checks into Human usability/pass evidence.
