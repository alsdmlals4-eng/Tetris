# Vanguard Tactical Tier Matrix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> Status: **PLANNING HANDOFF / DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION**

**Goal:** Implement `TETRIS-SKILL-026` so `ATK / DEF / SUP × T1–T6` contains situational Technique identities, uses reusable effect primitives, preserves lower-tier viability, and integrates safely with `TETRIS-CORE-024` and `TETRIS-TIME-025`.

**Architecture:** Keep Action selection as one existing 3×6 grid. Technique behavior is data-driven: `ActionDefinition` parses bounded effect primitives, `ActionExecutor` applies them through typed combat/status interfaces, and each skill status uses explicit one-stack/consume-or-expire semantics. Do not create one script per Technique or a generic RPG status engine.

**Tech Stack:** Godot 4.x, GDScript, JSON data/config, GUT production tests, Python semantic-canon tests.

**Spec:** `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md`

## Global Constraints

- Runtime BUILD is forbidden until the user separately declares `기획 완료 / BUILD 진행` or equivalent.
- `TETRIS-CORE-024` owns turn order and enemy Telegraph/resolve semantics.
- `TETRIS-TIME-025` owns Shared Player Turn Budget, Haste/Slow timing, timeout and Tempo.
- Tier N spends exactly N Chain Stock plus configured Energy.
- Tier is a tactical commitment/cost band, not a linear upgrade ladder.
- No cooldown system in first Slice.
- No bespoke script per Technique.
- No first-Slice mob/add roster merely to prove AoE.
- Tempo never scales Haste seconds, status duration, cost, ward count, target count or lethal HP-floor behavior.
- Historical Foundation code/tests remain separate evidence and are not rewritten to match production skill semantics.

---

## File Structure

```text
src/production/combat/
  action_definition.gd          # data model + validation for one Technique
  action_effect.gd              # typed primitive record/value object
  action_executor.gd            # ordered primitive execution
  production_combat_state.gd    # HP/Energy/Stock + player/enemy status links
src/production/status/
  bounded_status.gd             # one bounded status record
  skill_status_state.gd         # apply/consume/expire first-slice statuses
src/production/targeting/
  target_pattern.gd             # SELF / SINGLE_ENEMY / ALL_ENEMIES contract
src/production/telemetry/
  production_telemetry.gd       # action-choice/dominance metrics
src/production/ui/
  action_grid_presenter.gd      # 3×6 semantic cell presentation only
data/production/
  skill_lanes.json              # 18 Technique definitions
  skill_statuses.json           # bounded status definitions
  skill_balance_seed.json       # Energy/effect tuning seeds, explicitly non-final
scenes/production/
  battle.tscn                   # existing/future Action grid scene consumer
tests/production/unit/
  test_action_definition.gd
  test_skill_status_state.gd
  test_target_pattern.gd
tests/production/integration/
  test_tactical_skill_matrix.gd
  test_skill_tempo_safety.gd
  test_gatebreaker_skill_responses.gd
  test_skill_dominance_scenarios.gd
tests/tooling/
  test_production_canon_contract.py
```

If actual BUILD discovers equivalent focused production files already exist, update those owners instead of creating duplicates. Responsibility boundaries above remain mandatory.

---

### Task 1: Semantic canon guard for SKILL-026

**Files:**
- Modify: `tests/tooling/test_production_canon_contract.py`
- Read: `docs/design/PRODUCTION_CANON_INDEX.json`
- Read: `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md`

**Interfaces:**
- Consumes: machine-readable production canon index.
- Produces: cold-start regression that fails if SKILL-026 routing or tactical Tier semantics disappear.

- [ ] **Step 1: Add failing semantic-canon assertions**

Add constants:

```python
SKILL_CANON_PATH = ROOT / "docs" / "design" / "VANGUARD_TACTICAL_SKILL_MATRIX.md"
SKILL_PLAN_PATH = (
    ROOT
    / "docs"
    / "superpowers"
    / "plans"
    / "2026-08-24-vanguard-tactical-tier-matrix.md"
)
```

Add a test:

```python
def test_tactical_skill_canon_declares_situational_tiers(self) -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    self.assertEqual(data["current_skill_decision"], "TETRIS-SKILL-026")
    self.assertEqual(
        data["skill_canon"],
        "docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md",
    )
    self.assertEqual(
        data["skill_implementation_plan"],
        "docs/superpowers/plans/2026-08-24-vanguard-tactical-tier-matrix.md",
    )
    self.assertTrue(SKILL_CANON_PATH.is_file())
    self.assertTrue(SKILL_PLAN_PATH.is_file())
    skill = data["production_skill"]
    self.assertEqual(skill["tier_model"], "TACTICAL_COMMITMENT_BAND")
    self.assertTrue(skill["lower_tier_viability_required"])
    self.assertFalse(skill["highest_available_tier_is_default"])
    self.assertEqual(skill["implementation_model"], "DATA_DRIVEN_EFFECT_PRIMITIVES")
```

- [ ] **Step 2: Run the semantic test and confirm RED**

Run:

```bash
python -m unittest tests.tooling.test_production_canon_contract -v
```

Expected: FAIL because the index does not yet contain SKILL-026 fields.

- [ ] **Step 3: Update the machine-readable canon index**

Add exact fields documented in Task 1 while preserving CORE-024/TIME-025 authority.

- [ ] **Step 4: Re-run semantic tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add docs/design/PRODUCTION_CANON_INDEX.json tests/tooling/test_production_canon_contract.py
git commit -m "docs: route tactical skill canon"
```

---

### Task 2: ActionDefinition + primitive validation

**Files:**
- Create: `src/production/combat/action_effect.gd`
- Create: `src/production/combat/action_definition.gd`
- Create: `tests/production/unit/test_action_definition.gd`

**Interfaces:**
- Consumes: JSON Technique data.
- Produces: validated `ActionDefinition` with lane, tier, costs, target mode, tags, effects, Tempo whitelist.

- [ ] **Step 1: Write failing definition-validation tests**

```gdscript
func test_tier_must_match_stock_cost() -> void:
    var result := ActionDefinition.from_dict({
        "id": "atk_t3_rift_breach",
        "lane": "ATTACK",
        "tier": 3,
        "stock_cost": 2,
        "energy_cost": 20,
        "target_mode": "SINGLE_ENEMY",
        "effects": []
    })
    assert_false(result.ok)

func test_unknown_effect_primitive_is_rejected() -> void:
    var result := ActionDefinition.from_dict({
        "id": "bad",
        "lane": "ATTACK",
        "tier": 1,
        "stock_cost": 1,
        "energy_cost": 10,
        "target_mode": "SINGLE_ENEMY",
        "effects": [{"op": "ARBITRARY_SCRIPT"}]
    })
    assert_false(result.ok)
```

- [ ] **Step 2: Confirm RED**

Expected: classes do not exist.

- [ ] **Step 3: Implement bounded primitive enum/records**

`ActionEffect` permits only:

```text
DAMAGE_SINGLE
DAMAGE_AOE
MITIGATE_CURRENT_DIRECT
COUNTER_FROM_PREVENTED_DAMAGE
HEAL_SELF
APPLY_SELF_BUFF
APPLY_ENEMY_DEBUFF
PROTECT_RESOURCE_LOSS
MODIFY_NEXT_TURN_BUDGET
CONDITIONAL_MULTIPLIER
LETHAL_SAFETY
TARGET_PATTERN
```

`ActionDefinition` validates lane in `ATTACK/DEFENSE/SUPPORT`, Tier 1–6, positive Energy cost, Stock cost == Tier, target mode, effect list, and Tempo whitelist.

- [ ] **Step 4: Re-run focused tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/production/combat/action_effect.gd src/production/combat/action_definition.gd tests/production/unit/test_action_definition.gd
git commit -m "feat: define tactical skill primitives"
```

---

### Task 3: Bounded skill status state

**Files:**
- Create: `src/production/status/bounded_status.gd`
- Create: `src/production/status/skill_status_state.gd`
- Create: `data/production/skill_statuses.json`
- Create: `tests/production/unit/test_skill_status_state.gd`

**Interfaces:**
- Consumes: status id + one-stack bounded data.
- Produces: apply/refresh, consume-on-trigger, expire-at-turn-boundary.

- [ ] **Step 1: Write RED tests for max-one-stack behavior**

```gdscript
func test_breach_refreshes_instead_of_stacking() -> void:
    var state := SkillStatusState.new()
    state.apply("BREACH")
    state.apply("BREACH")
    assert_eq(state.stack_count("BREACH"), 1)
```

- [ ] **Step 2: Add consume/expiry RED cases**

Verify:

- BREACH consumed by qualifying ATK;
- FORTIFY consumed by direct hit;
- RALLY consumed by next player Action;
- WEAKEN consumed by next direct-hit enemy Intent;
- RIFT_WARD consumed by Energy/Stock loss;
- RIFT_SEAL consumed by resource-loss/repair;
- BATTLE_TRANCE expires after its next eligible preparation window.

- [ ] **Step 3: Implement minimal bounded state store**

No generic arbitrary stack/duration algebra.

- [ ] **Step 4: Re-run tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/production/status/bounded_status.gd src/production/status/skill_status_state.gd data/production/skill_statuses.json tests/production/unit/test_skill_status_state.gd
git commit -m "feat: add bounded tactical skill statuses"
```

---

### Task 4: Target pattern + AoE fallback

**Files:**
- Create: `src/production/targeting/target_pattern.gd`
- Create: `tests/production/unit/test_target_pattern.gd`

**Interfaces:**
- Produces target modes: `SELF`, `SINGLE_ENEMY`, `ALL_ENEMIES`.
- First Slice must support one Gatebreaker with legal `ALL_ENEMIES` fallback returning that one enemy.

- [ ] **Step 1: Write failing target tests**

```gdscript
func test_all_enemies_with_one_boss_returns_one_target() -> void:
    var targets := TargetPattern.resolve("ALL_ENEMIES", make_single_gatebreaker_context())
    assert_eq(targets.size(), 1)
```

- [ ] **Step 2: Add no-target/rejected-target tests**

Do not silently change `ALL_ENEMIES` into a different semantic target mode.

- [ ] **Step 3: Implement deterministic target resolver**

No mob roster or spawning logic belongs here.

- [ ] **Step 4: Re-run tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/production/targeting/target_pattern.gd tests/production/unit/test_target_pattern.gd
git commit -m "feat: add tactical target patterns"
```

---

### Task 5: Define the 18 Vanguard Techniques in data

**Files:**
- Create/Modify: `data/production/skill_lanes.json`
- Create: `data/production/skill_balance_seed.json`
- Create: `tests/production/integration/test_tactical_skill_matrix.gd`

**Interfaces:**
- Consumes: Task 2 schema.
- Produces all 18 canonical Technique definitions.

- [ ] **Step 1: Write a failing matrix completeness test**

```gdscript
func test_matrix_contains_exactly_six_techniques_per_lane() -> void:
    var matrix := load_skill_matrix()
    assert_eq(matrix.by_lane("ATTACK").size(), 6)
    assert_eq(matrix.by_lane("DEFENSE").size(), 6)
    assert_eq(matrix.by_lane("SUPPORT").size(), 6)
```

- [ ] **Step 2: Add identity assertions**

Assert ids exist:

```text
atk_t1_quick_cut
atk_t2_sweeping_cut
atk_t3_rift_breach
atk_t4_crushing_strike
atk_t5_suppressive_break
atk_t6_execution_edge
def_t1_guard
def_t2_fortify
def_t3_counter_stance
def_t4_bulwark
def_t5_rift_ward
def_t6_last_bastion
sup_t1_second_wind
sup_t2_rally
sup_t3_haste
sup_t4_mark_weakness
sup_t5_rift_seal
sup_t6_battle_trance
```

- [ ] **Step 3: Add balance seed data**

Use explicit numeric seeds, not zero/TBD. Start from T1-relative Energy factors from the spec and documented non-final effect magnitudes. Mark the file metadata `balance_status: TUNING_SEED_NOT_FINAL`.

- [ ] **Step 4: Validate all definitions through ActionDefinition**

Expected: all 18 pass schema validation and `stock_cost == tier`.

- [ ] **Step 5: Commit**

```bash
git add data/production/skill_lanes.json data/production/skill_balance_seed.json tests/production/integration/test_tactical_skill_matrix.gd
git commit -m "feat: define vanguard tactical skill matrix"
```

---

### Task 6: Primitive ActionExecutor

**Files:**
- Create/Modify: `src/production/combat/action_executor.gd`
- Modify/Create: `src/production/combat/production_combat_state.gd`
- Create/Modify: `tests/production/integration/test_tactical_skill_matrix.gd`

**Interfaces:**
- Consumes: legal `ActionDefinition`, current combat state, enemy Telegraph context, target resolver, bounded status state.
- Produces: deterministic action result + resource spend + effects.

- [ ] **Step 1: RED resource-spend test**

Verify legal Technique spends exactly its Tier Stock and configured Energy once; rejected actions spend nothing.

- [ ] **Step 2: RED primitive-order tests**

Examples:

- Rift Breach deals damage then applies BREACH;
- Execution evaluates condition against pre-resolution status/HP according to explicit spec order;
- Counter damage derives from actual prevented damage;
- Last Bastion only changes lethal direct-hit resolution.

- [ ] **Step 3: Implement primitive dispatch**

Use an explicit `match effect.op` dispatch table. No dynamic script path from JSON.

- [ ] **Step 4: Re-run focused integration tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/production/combat/action_executor.gd src/production/combat/production_combat_state.gd tests/production/integration/test_tactical_skill_matrix.gd
git commit -m "feat: execute tactical skill primitives"
```

---

### Task 7: TIME-025 / Tempo safety integration

**Files:**
- Modify: `src/production/combat/action_executor.gd`
- Modify: `src/production/combat/tempo_evaluator.gd`
- Create: `tests/production/integration/test_skill_tempo_safety.gd`

**Interfaces:**
- Consumes: Tempo result + per-Technique whitelist.
- Produces: scaled safe fields only.

- [ ] **Step 1: Write RED whitelist tests**

Assert eligible Tempo may increase damage/heal/mitigation/counter but does not change:

- `sup_t3_haste` seconds;
- status duration;
- Stock/Energy cost;
- Rift Ward / Rift Seal charges;
- Sweeping Cut target count;
- Last Bastion HP floor.

- [ ] **Step 2: Write positive-feedback regression**

Two turns with identical active completion time and different Haste must still derive Tempo from the same Tempo Reference and Haste seconds must not be Tempo-amplified.

- [ ] **Step 3: Implement whitelist application**

- [ ] **Step 4: Re-run TIME-025 + skill tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/production/combat/action_executor.gd src/production/combat/tempo_evaluator.gd tests/production/integration/test_skill_tempo_safety.gd
git commit -m "feat: enforce skill tempo safety"
```

---

### Task 8: Gatebreaker response hooks

**Files:**
- Modify/Create: `data/production/gatebreaker_pattern.json`
- Create: `tests/production/integration/test_gatebreaker_skill_responses.gd`

**Interfaces:**
- Enemy Intent exposes category hooks without choosing the player's answer.
- Skill Executor queries only the already-telegraphed category/effect.

- [ ] **Step 1: Write RED category tests**

Map first-slice intents to categories:

```text
Light Smash -> DIRECT_HIT_LIGHT
Gatebreaker Slam -> DIRECT_HIT_HEAVY
Rift Siphon -> RESOURCE_LOSS_ENERGY
Chain Fracture -> RESOURCE_LOSS_STOCK
Rift Repair -> ENEMY_REPAIR
Siege Charge -> DIRECT_HIT_LETHAL_CANDIDATE
```

- [ ] **Step 2: Verify multiple valid responses exist**

At fixture resource states, assert at least two materially different legal response paths for Slam, Siphon/Fracture, Repair and Siege Charge.

- [ ] **Step 3: Assert no reactive counter rewrite**

Selecting Rift Ward, Bulwark, or Execution must not cause the current telegraphed enemy action id to change.

- [ ] **Step 4: Re-run encounter integration tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add data/production/gatebreaker_pattern.json tests/production/integration/test_gatebreaker_skill_responses.gd
git commit -m "test: bind skill matrix to gatebreaker intents"
```

---

### Task 9: Dominance scenario regression

**Files:**
- Create: `tests/production/integration/test_skill_dominance_scenarios.gd`

**Interfaces:**
- Consumes: tuning-seed Technique data.
- Produces: non-final scenario checks that reject obvious strict dominance before human play.

- [ ] **Step 1: Encode scenario fixtures**

At minimum:

```text
LIGHT_DIRECT_HIT
HEAVY_DIRECT_HIT
LETHAL_DIRECT_HIT
ENERGY_LOSS
STOCK_LOSS
ENEMY_REPAIR
LOW_HP_SMALL_RECOVERY
LOW_PRESSURE_SETUP
MULTI_TARGET_SYNTHETIC
LOW_ENEMY_HP_FINISH
```

- [ ] **Step 2: Write lower-tier viability assertions**

Examples:

```gdscript
func test_guard_beats_last_bastion_opportunity_cost_on_light_hit() -> void:
    var result := compare_choices(light_hit_context(), "def_t1_guard", "def_t6_last_bastion")
    assert_true(result.prefers_first)

func test_execution_requires_condition_to_beat_raw_t4_value() -> void:
    assert_true(compare_choices(no_condition_context(), "atk_t4_crushing_strike", "atk_t6_execution_edge").prefers_first)
    assert_true(compare_choices(execution_condition_context(), "atk_t6_execution_edge", "atk_t4_crushing_strike").prefers_first)
```

These are seed sanity guards, not final balance proof.

- [ ] **Step 3: Add synthetic AoE case**

Verify Sweeping Cut can win when multiple targets exist without requiring that content in the first Slice.

- [ ] **Step 4: Run scenario suite**

Expected: PASS for initial seeds.

- [ ] **Step 5: Commit**

```bash
git add tests/production/integration/test_skill_dominance_scenarios.gd
git commit -m "test: guard against linear tier dominance"
```

---

### Task 10: Action grid semantic UI

**Files:**
- Create/Modify: `src/production/ui/action_grid_presenter.gd`
- Modify: `scenes/production/battle.tscn`
- Test: appropriate production UI/scene tests.

**Interfaces:**
- Consumes: 18 ActionDefinitions + current Energy/Stock + Action Phase state.
- Produces: one 3×6 grid with Technique tags/readiness.

- [ ] **Step 1: RED semantic cell tests**

Each cell exposes:

- lane;
- Tier;
- Technique short name/icon;
- Stock cost;
- Energy cost;
- tactical role tag;
- readiness reason.

- [ ] **Step 2: Assert no submenu requirement**

One click/confirm on a legal cell resolves selection; no Technique→Tier second-stage selection.

- [ ] **Step 3: Implement presenter only**

UI never spends resources directly.

- [ ] **Step 4: 1280×720 screenshot/readability review**

Human/visual review must confirm the 18 cells do not eclipse Telegraph, shared timer or core resources. Unit tests cannot claim visual PASS.

- [ ] **Step 5: Commit**

```bash
git add src/production/ui/action_grid_presenter.gd scenes/production/battle.tscn tests/production
git commit -m "feat: present situational tactical tiers"
```

---

### Task 11: First-run contextual exposure

**Files:**
- Modify/Create: production onboarding/session data and tests appropriate to existing implementation.
- Test: first-run flow integration tests.

**Interfaces:**
- First tutorial Turn uses actual production Action grid.
- Does not modal-teach all 18 Techniques.

- [ ] **Step 1: RED onboarding test**

Assert initial Stock makes T1 the natural visible legal option while higher tiers show clear locked/insufficient state.

- [ ] **Step 2: Add contextual tag exposure tests**

When later Stock/Intent makes a specialized Tier relevant, the UI may highlight/describe the role without pausing the shared timer unless System Pause is explicitly invoked.

- [ ] **Step 3: Implement minimal contextual hints**

- [ ] **Step 4: Verify First Run contract + retry skip**

- [ ] **Step 5: Commit**

```bash
git add src/production data/production tests/production
git commit -m "feat: teach tactical tiers contextually"
```

---

### Task 12: Telemetry for Tier viability

**Files:**
- Modify: `src/production/telemetry/production_telemetry.gd`
- Add/Modify: telemetry tests.

**Interfaces:**
- Produces per-action evidence needed for human tuning.

- [ ] **Step 1: RED telemetry payload test**

Require fields:

```text
turn_index
technique_id
lane
tier
highest_available_tier
selected_highest_available_tier
energy_before
stock_before
current_intent
next_forecast_category
player_hp
boss_hp
overkill
prevented_damage
counter_damage
resource_loss_prevented
status_created
status_consumed
```

- [ ] **Step 2: Implement local deterministic logging only**

No network analytics dependency.

- [ ] **Step 3: Verify replay determinism does not depend on telemetry sink**

- [ ] **Step 4: Commit**

```bash
git add src/production/telemetry/production_telemetry.gd tests/production
git commit -m "feat: log tactical tier choices"
```

---

### Task 13: Full verification and human evidence gate

**Files:** no new production contract files unless findings require a separately reviewed correction.

- [ ] **Step 1: Run semantic + production automated suites**

Required:

```text
semantic canon tests
historical Foundation regression
production action-definition/status/target tests
skill matrix integration
TIME-025 Tempo safety
Gatebreaker response fixtures
dominance scenario sanity suite
strict GUT false-green guard
```

- [ ] **Step 2: Run Windows production runtime / presentation checks**

Do not claim PASS without actual receipts.

- [ ] **Step 3: Run minimum Human A/B/C complete Slice runs**

Record:

- Technique/Tier distribution;
- highest-available-Tier pick rate;
- lower-tier unused rate;
- overkill/resource waste;
- Intent→response match;
- setup status creation/consumption;
- PASS/timeout/Board Break;
- whether players can explain why they chose a lower Tier.

- [ ] **Step 4: Apply five full adversarial re-review loops after evidence**

1. Tier dominance.
2. Lane identity/overlap.
3. Telegraph response quality.
4. Action-grid cognitive load.
5. Solo-development/content cost and regression.

Each valid finding: minimal correction → automated regression → runtime/human recheck where affected.

- [ ] **Step 5: Only then tune final numbers**

Human evidence may change Energy costs/effect magnitudes. It does not silently change the SKILL-026 structural contract; structural changes require a new Decision.

## Implementation Reality Gate

At plan creation time:

- SKILL-026 design: `DOCUMENTED / USER-APPROVED DIRECTION`.
- Notion + Issue ledger: `SYNCED`.
- repository skill canon sync: this planning workstream.
- production Effect Primitive runtime: `NOT_PRESENT`.
- 18 Technique runtime: `NOT_PRESENT`.
- lower-tier viability: `NOT_PROVEN`.
- multi-target AoE balance: `NOT_RUN`.
- Human production playtest: `NOT_RUN`.

Do not execute this plan before explicit BUILD authorization.
