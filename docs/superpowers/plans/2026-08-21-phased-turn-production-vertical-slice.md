# Phased-Turn Production Vertical Slice Implementation Plan

> Status: **PLANNING HANDOFF / DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION**
>
> Current canon: `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` / `TETRIS-CORE-024`
>
> Existing `src/core`, `src/puzzle/debug_*`, `scenes/poc_battle.tscn` and the 45-second tests remain **Core Combat Foundation / Engineering Harness**. Do not refactor them into production code merely to reuse names.

## Goal

Build one production-quality representative Vertical Slice whose combat turn is:

```text
Enemy Telegraph
→ Line Phase
→ Line Settle
→ Swap-Match Chain Phase
→ Chain Settle
→ Action Phase
→ Player Action Resolve
→ Enemy Action Resolve
→ next Turn
```

The first player milestone remains one Vanguard, one Gatebreaker, one Frontier Gate, one 6–10 minute target flow, with actual production puzzle engines and production presentation. The phase timer seed starts at 30/30/30 seconds maximum with early finish; runtime/human evidence owns final tuning.

## Architecture decision

### A · Mutate the existing Core POC into production

- Benefit: fewer files initially.
- Failure: old `ModeController`, debug event sources, 45-second evidence and POC UI encode superseded free-switch/Combat-Clock semantics. Reusing them as production owners would destroy the historical evidence boundary and create condition-heavy migration code.
- Decision: **REJECT**.

### B · New production domain beside the verified Foundation — ADOPT

- Add a production turn controller and production Line/Chain engines under a separate namespace/path.
- Reuse only stable low-level ideas/contracts that remain valid: deterministic seeds, combat resource ownership, telemetry principles, strict CI, HiGodot binding, data-driven rules.
- Keep historical POC tests green and add a new production test suite.
- Decision: **ADOPT**.

### C · One generic grid/phase engine for both Line and Chain

- Benefit: apparent code reuse.
- Failure: falling tetromino physics and adjacent-swap cascade resolution have different movement, legality, timing, failure and replay requirements. Early unification would create branch-heavy abstractions.
- Decision: **REJECT until both production engines exist and real shared behavior can be extracted**.

## Build gate

Do not execute tasks below until all are true:

1. PR #11 production canon correction is merged and read back from `main`.
2. Notion Project Home `Repo Main SHA` and `Sync State` match the merged repository truth.
3. User explicitly declares `기획 완료 / BUILD 진행` or equivalent.
4. Current `main` and all open/recent same-goal PRs are re-read; PR #9 remains read-only unless separately authorized.
5. Dedicated local HiGodot receipt is established if persistent Godot editor mutation is required.

## Global implementation rules

- Test-first RED → GREEN → regression for deterministic GDScript domain changes.
- Do not edit old tests to make production semantics appear green. Add production tests.
- Puzzle engines own puzzle board/input/resolution state only.
- Turn/combat layer owns phase order, timers, enemy telegraph/resolve, resources and action authority.
- UI never mutates combat/puzzle resources directly.
- All timing/economy/tier values are data/config, not UI constants.
- No paid dependency or metered service.
- No player-facing debug event buttons in production flow.

## Proposed production file map

```text
src/production/
  turn/
    turn_phase.gd
    turn_config.gd
    turn_controller.gd
  line/
    line_board.gd
    tetromino.gd
    bag_randomizer.gd
    line_rotation.gd
    line_rules.gd
  chain/
    chain_board.gd
    chain_match.gd
    chain_resolver.gd
    chain_rules.gd
  combat/
    production_combat_state.gd
    action_definition.gd
    action_executor.gd
    enemy_turn_pattern.gd
  session/
    production_battle_session.gd
  telemetry/
    production_telemetry.gd
  ui/
    production_battle.gd

data/production/
  turn_config.json
  line_rules.json
  chain_rules.json
  skill_lanes.json
  gatebreaker_pattern.json
scenes/production/
  battle.tscn
tests/production/
  unit/
  integration/
  replay/
```

Exact filenames may be adjusted during BUILD if existing Godot conventions require it, but responsibility boundaries must remain.

---

## Task 0 · Re-read authority and establish production test namespace

### Files

- Create: `tests/production/README.md`
- Create: first production contract test fixture.

### RED

Add a test requiring a production Turn phase vocabulary that does not yet exist:

- `ENEMY_TELEGRAPH`
- `LINE`
- `LINE_SETTLE`
- `CHAIN`
- `CHAIN_SETTLE`
- `ACTION`
- `PLAYER_RESOLVE`
- `ENEMY_RESOLVE`

Confirm the test fails because production Turn code is absent.

### GREEN boundary

Only add the minimal production phase constants. Do not touch `src/core/board_state.gd`.

### Verify

- production focused test PASS;
- complete historical GUT suite still PASS;
- semantic canon tooling tests PASS.

---

## Task 1 · Production Turn Controller

### Responsibilities

`TurnController` owns:

- turn index;
- current phase;
- current phase elapsed/remaining time;
- phase max duration from data;
- early finish legality;
- timeout transition;
- pause clock exclusion;
- settle handoff;
- Action timeout → PASS;
- event/signal emission for UI/session.

It does **not** own puzzle grid mutations or Skill effects.

### Initial config

```json
{
  "line_max_seconds": 30.0,
  "chain_max_seconds": 30.0,
  "action_max_seconds": 30.0,
  "allow_early_finish": true,
  "bank_unused_time": false
}
```

### RED cases

1. starts at `ENEMY_TELEGRAPH`;
2. telegraph confirm enters Line with exactly configured max time;
3. only current phase timer advances;
4. early finish discards unused time;
5. Line timeout enters `LINE_SETTLE`, not directly Chain;
6. Chain timeout enters `CHAIN_SETTLE`;
7. Action timeout emits PASS and proceeds to player/enemy resolve;
8. System Pause freezes phase timer;
9. negative/zero delta cannot advance phase;
10. no input from another phase is silently queued.

### GREEN

Implement minimal state machine only.

### Regression

Run all production Turn tests + historical 50-test Foundation suite.

---

## Task 2 · Production combat/resource state for Tier 1–6

Do **not** change historical `CombatState.CHAIN_STOCK_CAP = 5` because that is old Harness evidence.

### New production state

- player HP/max HP;
- enemy HP/max HP;
- Energy;
- Chain Stock cap 6;
- Score;
- current turn/telegraph link;
- no passive +1/sec Energy recovery by default.

### RED cases

- Tier 6 legal at Stock 6 + enough Energy;
- Tier 6 illegal at Stock 5;
- Tier N spends exactly N Stock + configured Energy;
- rejected action never mutates resources;
- Line gain persists into Chain/Action and later turns;
- Chain Stock persists into later turns;
- PASS spends nothing;
- HP clamps;
- no passive Energy generation while idle.

---

## Task 3 · Enemy telegraph / authored turn pattern

Adapt `TETRIS-ENCOUNTER-006` to turn-based authored intent.

### Data owns

- action id;
- category;
- expected result;
- damage/resource effect;
- phase thresholds;
- sequence order;
- next-action preview eligibility.

No primary 12/15/18-second enemy countdown fields in production.

### RED cases

- action is selected/locked before Line begins;
- same-turn player resources cannot secretly replace the telegraphed action;
- Player Action resolves before Enemy Action;
- lethal player action prevents normal pending Enemy Action;
- phase transition applies only after already-telegraphed Enemy Action unless lethal ended encounter;
- next forecast is deterministic from seed/phase state.

---

## Task 4 · Production Line Engine

### Required first-slice mechanics

- 10×20 visible matrix + hidden/spawn handling;
- seven tetrominoes;
- deterministic 7-bag;
- Next, Hold, Ghost;
- move / rotate / soft drop / hard drop;
- gravity;
- lock delay with bounded reset;
- SRS-style rotation/kicks as project-owned implementation data;
- collision/placement;
- line detection + compaction;
- Single/Double/Triple/4-line;
- Combo / B2B / Spin / Perfect Clear recognition needed by current Slice score profile;
- Score event + Energy event;
- Board Break integration;
- exact persistent board/queue/randomizer/Hold state across turns.

### Turn integration RED cases

- no input outside Line Phase;
- timer expiry rejects new manipulation;
- already-committed atomic placement/clear may settle after expiry;
- Energy commits before Chain Phase;
- early finish only at legal stable boundary;
- Line board remains bit-for-bit unchanged through Chain/Action/Enemy phases except explicit enemy/system effect;
- Board Break with remaining Line time resumes Line; expired time proceeds via Line Settle.

### Feel values

Expose gravity/DAS/ARR/lock delay/reset caps in data. Do not tune from memory as final.

---

## Task 5 · Production Swap-Match Chain Engine

Do not implement Puyo-style pivot/child falling pairs.

### Required first-slice mechanics

- deterministic initial board + refill RNG;
- adjacent swap;
- legal-match validation;
- invalid swap rollback;
- match clear;
- gravity;
- refill;
- automatic cascade;
- exact cascade/Chain depth;
- multi-group/multi-color event data as needed;
- All Clear if current Slice score contract retains it;
- final stable reward event;
- Board Break/failure rule if production Chain layout can fail;
- deterministic replay fixture.

### Turn integration RED cases

1. no Chain input during Line;
2. Chain input starts only in Chain Phase;
3. timer expiry prevents a new swap;
4. swap committed before expiry may finish clear/gravity/refill/cascade after timer reaches zero;
5. no autonomous swap is created during Settle;
6. Action Phase does not begin until board is stable;
7. Stock is committed at stable completion;
8. Line remains frozen during Chain + Chain Settle;
9. no background Chain resolver runs while a later Line Phase is active;
10. deterministic seed reproduces exact settle result.

---

## Task 6 · Skill Lanes × Tier 1–6

### Current grammar

- ATK / DEF / SUP.
- T1 emergency/basic.
- T2 standard.
- T3 first qualitative breakpoint.
- T4–T5 stronger numerical/efficiency variants.
- T6 signature maximum / strongest same-family keyword expression.

### Important CORE-024 migration

Old countdown Stagger is not ported automatically.

First GREEN may ship Attack as direct damage at every Tier while the qualitative Attack breakpoint is represented as `TUNE_REQUIRED` data only if the final effect is not yet approved. Do not implement phase-timer manipulation merely to retain the old word `Stagger`.

### RED cases

- 18 cells reflect 3 lane identities, not 18 unrelated abilities;
- readiness distinguishes Stock gate vs Energy shortage;
- selecting a legal cell resolves immediately and exits Action Phase;
- Action input rejected before Action Phase;
- Action timeout PASS is deterministic;
- Defense applies to current telegraphed direct hit only under current baseline;
- Support/Vanguard recovery cannot restore Energy/Stock;
- T6 cap is consistent in state/data/UI.

---

## Task 7 · Board Break in phased turns

### RED cases

- Line Board Break applies HP damage and resets Line only;
- Chain Board Break resets Chain only if its failure rule exists;
- other board exact state preserved;
- Energy/Stock not additionally confiscated;
- randomizer/queue anti-reroll contract preserved;
- remaining current phase time resumes same phase;
- expired phase completes settle/transition without receiving bonus time;
- HP 0 ends battle immediately.

---

## Task 8 · Production telemetry

Record per Turn:

- turn index;
- telegraphed action;
- Line budget/used/early finish;
- Energy before/after;
- Chain budget/input used/settle duration/cascade depth/early finish;
- Stock before/after;
- Action budget/decision time;
- lane/Tier or PASS;
- resource spend;
- player action result;
- enemy action result;
- HP before/after;
- Board Break;
- outcome.

No network analytics required for the first Slice; local deterministic log is sufficient.

---

## Task 9 · Production battle UI skeleton before final art integration

This is a production semantic layout, not debug UI.

### 1280×720 first proof

Must demonstrate:

- Current Enemy Telegraph + expected result;
- Current Phase name + remaining time;
- active puzzle focus;
- compact prepared-state Sidecar;
- HP/Energy/Stock;
- Action phase ATK/DEF/SUP × T1–T6 direct cells;
- next turn forecast when known;
- no RUN/LOCK controls;
- no continuously decreasing enemy ETA.

### RED/verification

Use scene tests for semantic labels/input authority and screenshot/readability review for layout. Do not claim visual PASS from unit tests.

---

## Task 10 · Tactical Anime Pixel Rift Fantasy integration

Integrate approved visual package only after explicit image-generation/asset instruction provides actual approved assets.

Until then:

- semantic layout may use deliberately labeled temporary engineering shapes in internal development scenes;
- player-ready Gate B cannot pass with placeholders;
- do not generate images automatically.

Production art requirements come from `TETRIS-VISUAL-020` and updated Notion `14 · P0 이미지 제작 패키지`.

---

## Task 11 · Audio / VFX phase grammar

Implement production semantic cues:

- Enemy Telegraph;
- Line start/end/early confirm;
- Chain start/cascade/settle;
- Action start/confirm/PASS;
- Enemy Resolve;
- Energy/Stock/Tier readiness;
- Board Break;
- Vanguard actions;
- Gatebreaker major actions.

No old Combat Clock tick or countdown-Stagger cue should be introduced as current production meaning.

---

## Task 12 · First-run flow

Current onboarding is the first real Light Smash Turn:

```text
Title
→ Gate Arrival
→ Light Smash Telegraph
→ Line Phase hint
→ Chain Phase hint
→ Action Phase hint
→ Player Action
→ Light Smash resolves
→ normal Gatebreaker turns
→ Result
```

Hints are one-concept/no-modal. They do not silently freeze active Phase time; explicit System Pause does.

Retry Battle may omit repeated tutorial hints. Restart Tutorial remains optional.

---

## Task 13 · Deterministic Production Gate

### Gate A · Engineering

- semantic canon tests PASS;
- historical Foundation suite remains PASS;
- Production Turn tests PASS;
- Line tests PASS;
- Swap-Match Chain tests PASS;
- Skill/Enemy integration tests PASS;
- deterministic replay fixtures reproduce;
- strict GUT false-green guard PASS.

### Gate B · Runtime / Presentation

- Windows import/export/run PASS;
- dedicated HiGodot receipt when used;
- 1280×720 readability PASS;
- production assets/VFX/audio integrated;
- Title → Turn tutorial → battle → Pause/settings → result/retry complete;
- no player-facing debug simulation controls;
- no critical cue occlusion/masking;
- performance probe PASS.

### Gate C · Human

Run A/B/C minimum 3 complete production runs.

Record:

- phase actual times and early-finish rates;
- meaningful Turn count;
- Tiers chosen;
- PASS frequency;
- Energy/Stock surplus/shortage;
- Board Breaks;
- victory/defeat;
- readability/tension/first-impression notes.

Do not tune final 30/30/30 or Tier economy before this evidence unless automated simulations prove an obvious impossible state.

---

## Task 14 · Adversarial refinement after first human evidence

Minimum five full whole-scope loops:

1. **Pacing:** mandatory-wait / too-few-turn / timer panic.
2. **Economy:** one puzzle becomes automatic or irrelevant; T6 dominates; PASS common.
3. **Enemy decision quality:** Telegraph fails to change preparation/action choice.
4. **UX/presentation:** Phase/Telegraph/Board/Skill information competes or obscures.
5. **Production cost/regression:** 1-person asset/runtime burden, replay instability, historical Foundation corruption.

After each verified finding: minimal correction → regression → whole-scope reattack. Exit only after five full loops minimum and no blocking finding remains.

## Rollback strategy

- Production code is additive beside Foundation until its own Gate A/B passes.
- If the phased-turn prototype fails before player-ready integration, revert only the production workstream; PR #3 Foundation remains a known-good engineering reference.
- Never restore stale production authority by deleting `CORE-024` without a newer explicit user Decision.

## Completion definition for this plan

This plan is complete only when production code, assets/presentation, runtime verification and human evidence all exist. Merely merging this planning document or passing the historical 50-test Foundation suite does **not** complete it.
