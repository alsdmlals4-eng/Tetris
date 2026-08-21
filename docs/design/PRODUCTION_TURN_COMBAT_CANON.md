# Production Turn Combat Canon

- Status: **CURRENT PRODUCTION CANON / USER_APPROVED**
- Decision: `TETRIS-CORE-024 · Telegraph → Line → Chain → Action → Enemy Resolve`
- Date: 2026-08-21
- Repository: `alsdmlals4-eng/Tetris`
- Scope: first production-quality Vertical Slice and later production gameplay unless superseded by a newer approved Decision.

## 1. Authority and migration boundary

This document is the current production gameplay authority for the turn structure, Line/Chain sequencing, phase timing, player action timing, and enemy action timing.

The following older contracts remain useful as **Core Combat Foundation / Engineering Harness evidence**, but they are not production gameplay authority where they conflict with this document:

- `docs/design/CORE_GAMEPLAY_GDD.md`
- `docs/design/POC_RULESET_V0_1.md`
- `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- `docs/validation/POC_45S_VALIDATION.md`

The merged PR #3 implementation and its tests stay preserved as an Engineering Harness. Do not rewrite its historical validation evidence to pretend that it already implements this production canon.

### Superseded production rules

`TETRIS-CORE-024` supersedes these production assumptions:

- free/manual Line ↔ Chain switching at arbitrary combat times;
- a continuously advancing enemy Combat Clock during normal puzzle play;
- tactical `RUN / LOCK` as a core production combat decision;
- the blanket rule that every inactive board is always frozen;
- `TETRIS-CORE-021`'s need for Chain resolution to continue in the background while the player is already playing Line;
- enemy Intent represented primarily by seconds-until-action during an always-running combat clock.

`TETRIS-CORE-021` still owns the production **Swap-Match Chain grammar**: adjacent swap, match resolution, gravity, refill, automatic cascades, no autonomous swap generation, and stable-board completion.

`TETRIS-SKILL-022` still owns **Attack / Defense / Support × Tier 1–6** unless a later approved Skill Decision supersedes it.

## 2. Product thesis

The player does not juggle two live puzzle boards simultaneously. Each enemy turn reveals a threat first, then gives the player three bounded preparation/decision windows:

1. build **Energy** through Line play;
2. build **Chain Stock / Tier access** through Swap-Match Chain play;
3. choose and execute one combat action;
4. resolve the telegraphed enemy action;
5. repeat with a new telegraph.

Core player question:

> The enemy has shown what it will do. During this turn, how much Energy can I earn, how much Tier access can I prepare, and which action should I commit before the enemy acts?

Pressure comes from **bounded phase time + known enemy consequence + resource tradeoffs**, not from requiring the player to monitor two puzzle simulations and an always-running enemy clock at the same time.

## 3. Canonical turn sequence

One combat turn is:

```text
TURN_START
→ ENEMY_TELEGRAPH
→ LINE_PHASE
→ LINE_SETTLE
→ CHAIN_PHASE
→ CHAIN_SETTLE
→ ACTION_PHASE
→ PLAYER_ACTION_RESOLVE
→ ENEMY_ACTION_RESOLVE
→ TURN_END
→ next TURN_START
```

### 3.1 ENEMY_TELEGRAPH

Before the Line timer starts, the current enemy action is locked and shown to the player.

At minimum show:

- action name/category;
- expected result or damage/resource effect;
- any important target or condition;
- next action preview when the encounter script already knows it.

The enemy must not secretly replace the already-telegraphed action in response to the player's Line/Chain performance during the same turn.

### 3.2 LINE_PHASE

- Only the production Line board accepts puzzle input.
- Line Clear generates Energy according to data-driven rules.
- The Chain board accepts no input and does not simulate autonomous puzzle actions.
- The Line board persists across turns; a turn does not rebuild it unless Board Break or another explicit rule does so.
- The player may finish the phase early with an explicit `NEXT / READY` action.
- Otherwise the phase ends when its timer reaches zero.
- Unused phase time is not banked into another phase or future turn.

### 3.3 LINE_SETTLE

When Line input time ends:

- stop new Line manipulation;
- finish only the atomic placement/clear operation already committed by the last legal input;
- commit resulting Energy/Score/telemetry;
- transition to Chain only after the board reaches a deterministic stable point.

Do not allow a zero-time input exploit after expiry.

### 3.4 CHAIN_PHASE

- Only the production Swap-Match Chain board accepts swaps.
- A valid swap may trigger clear → gravity → refill → cascade cycles.
- Chain results create Chain Stock / Tier access according to production data.
- The Line board accepts no input and is exactly frozen during this phase.
- The player may finish the phase early only when the Chain board is stable.
- Otherwise input closes when the phase timer reaches zero.

### 3.5 CHAIN_SETTLE

After Chain input closes:

- no new swap may start;
- an already-triggered clear/gravity/refill/cascade must finish to a full stable board;
- no autonomous swap is generated;
- completed Chain rewards are committed only from the final stable resolution;
- then the game enters Action Phase.

This replaces the old production need for `background resolver while Line is active`. The resolver may finish **after Chain input time**, but the game does not advance to another puzzle phase while it is still resolving.

### 3.6 ACTION_PHASE

- The player chooses one combat action from the currently legal Skill Lane/Tier cells.
- Current production lanes: **Attack / Defense / Support**.
- Current production Tier range: **1–6**.
- Eligibility is evaluated from the Energy and Chain Stock that exist after both puzzle phases settle.
- Selecting a legal action may resolve immediately; the player does not need to wait for the remainder of the Action timer.
- If no legal action is selected before timeout, the player performs `PASS` with no resource spend and the enemy proceeds.
- `PASS` is a fallback state, not a competitive resource strategy and grants no bonus.

### 3.7 PLAYER_ACTION_RESOLVE

Resolve the selected action and its costs before the enemy action.

- Spend configured Energy.
- Spend the configured Chain Stock/Tier requirement.
- Apply Attack / Defense / Support effect.
- If the enemy reaches defeat state, end the encounter before its pending action resolves unless the encounter explicitly declares a simultaneous-resolution exception.

### 3.8 ENEMY_ACTION_RESOLVE

If the enemy remains able to act:

- resolve exactly the action telegraphed at turn start, with any legitimate player-created modifiers;
- apply damage/resource/status effect;
- write telemetry/result feedback;
- then advance the authored encounter script/phase and reveal the next turn's action.

## 4. Phase-time contract

All player-facing phase durations are data-driven.

### Initial first-slice tuning seed

| Phase | Candidate maximum |
|---|---:|
| Line | 30 s |
| Chain | 30 s |
| Action Select | 30 s |

These are **starting test values, not final balance canon**.

Rules:

- each phase has its own timer;
- player may confirm early where legal;
- unused time is discarded;
- phase time never transfers between Line, Chain, Action, or future turns;
- System Pause stops phase timers because it is an out-of-simulation convenience;
- tutorial/inspection UI that is allowed during an active timed phase must not silently pause that phase unless explicitly marked as System Pause;
- difficulty or encounter content may later change phase budgets only through visible data/config, not hidden dynamic punishment.

### Revisit trigger

30/30/30 must be shortened or redistributed if human evidence shows:

- players routinely wait with nothing meaningful to do;
- boss combat requires too few meaningful turns;
- Action Select regularly consumes only a small fraction of its budget;
- overall Slice exceeds the intended pacing without increasing decision quality.

## 5. Resource contract

### Energy

- Line is the primary Energy source.
- Energy persists across phases and turns until spent or explicitly modified by an enemy/system rule.
- Production design must not rely on the Engineering Harness's `+1 Energy/sec` emergency recovery; the mandatory Line phase each turn is now the primary anti-soft-lock opportunity.
- Any future emergency recovery must be approved as a separate production rule and must not reward passive waiting.

### Chain Stock / Tier access

- Swap-Match Chain is the primary source of Chain Stock/Tier access.
- Stock persists across turns until spent or explicitly modified.
- Production Tier cap is 6.
- Exact Stock gain formula for the Swap-Match engine must be data-driven and tied to demonstrated Chain/cascade performance rather than passive time.

### Score

- Score remains performance evidence, not a Skill currency.
- Line and Chain Score events retain their origin for telemetry and post-run analysis.

## 6. Skill contract under the turn model

Current lanes:

- **Attack** — enemy defeat progress and offensive tempo.
- **Defense** — mitigation/counter-preparation for the already-telegraphed enemy action.
- **Support** — Vanguard uses recovery/Rally first; later classes may express support differently.

Current range: **Tier 1–6**.

The old real-time `Stagger = add seconds to the current enemy countdown` definition is superseded because there is no always-running enemy action countdown during Line/Chain/Action phases.

For the first production implementation:

- do not silently port countdown-based Stagger;
- treat its replacement effect as a separate Skill tuning/design item;
- Attack must still be valid as direct damage without Stagger;
- Defense and Support retain their clear response identities;
- no phase-timer manipulation is introduced merely to preserve the old Stagger name.

## 7. Board Break under phased turns

Board Break remains part of production canon.

During Line or Chain phase:

1. detect the board failure at a deterministic boundary;
2. resolve Board Break atomically;
3. apply configured HP loss;
4. clear/reset only the failed board according to its production queue/randomizer contract;
5. preserve the other board and combat resources unless an explicit enemy/system rule says otherwise;
6. return the failed board to a legal stable state;
7. if phase time remains, resume the **same phase**; if time has expired, continue to that phase's settle step.

Default combat defeat remains player HP reaching zero.

## 8. UI / UX contract

`TETRIS-UX-023` is adapted to the phased turn model.

### Persistent hierarchy

1. current enemy telegraph and expected result;
2. current phase name + remaining phase time;
3. active puzzle board during Line/Chain;
4. HP / Energy / Chain Stock;
5. Attack / Defense / Support Tier 1–6 lanes during Action Phase;
6. next enemy action preview;
7. inactive board preview / combat art / decorative VFX.

### Phase communication

The HUD must always make these states explicit:

- `LINE · PREPARE ENERGY`
- `CHAIN · PREPARE STOCK`
- `ACTION · CHOOSE RESPONSE`
- `ENEMY · RESOLVING`

Do not reuse the Engineering Harness's `RUNNING / LOCKED / SUSPENDED` labels as the primary player-facing production phase language.

### Sidecar

- During Line Phase, Chain Sidecar is stable/input-off.
- During Chain Phase, Line Sidecar is exact frozen state.
- During Action Phase, both boards are input-off and show their final prepared states.
- Chain cascade visuals may continue only during `CHAIN_SETTLE`, with a clear `RESOLVING` treatment; Action Phase begins after stable completion.

### Enemy timeline

The old continuously decreasing enemy ETA timeline becomes a **turn forecast**:

- current telegraphed action: highest priority;
- next authored action: lower priority when known;
- current phase timer is the live seconds-based pressure indicator.

## 9. System Pause and input authority

- System Pause stops simulation, audio timing, and current phase timer.
- There is no tactical `LOCK` resource mechanic in the current production turn loop.
- Gameplay uses named input actions; physical keys are not read directly in domain logic.
- A phase owns input authority. Inputs for another phase must be rejected rather than queued invisibly.

## 10. Encounter adaptation

`TETRIS-ENCOUNTER-006 · Authored Intent Ladder + HP Phase` remains adopted, but its time model changes.

Keep:

- authored readable enemy actions;
- current + next telegraph;
- no hidden immediate counter to the player's current board/resources;
- HP-phase progression;
- multiple valid response paths.

Replace:

- `12s / 15s / 18s enemy countdown` as the primary action clock;
- countdown-based Stagger.

Production enemy data should instead describe:

- action identity/category;
- damage/resource effect;
- phase/sequence position;
- telegraph copy/icon;
- response hooks;
- optional future turn modifiers.

## 11. First-run flow adaptation

The first run teaches the real turn in the same order the player uses it:

```text
Enemy telegraph
→ Line timer and Energy
→ Chain timer and Stock
→ Action timer and Skill choice
→ Enemy resolve
```

Do not teach free board switching or tactical RUN/LOCK as production mechanics.

The first enemy turn must be survivable even if the player makes a weak Action choice so the complete turn loop can be learned through consequence rather than a modal explanation.

## 12. Telemetry contract

Record at minimum:

### Per turn

- turn index;
- telegraphed enemy action;
- Line phase budget / actual time used / early-finish flag;
- Energy before/after Line;
- Chain phase budget / actual input time / settle duration;
- cascade depth and Stock before/after Chain;
- Action phase budget / decision time;
- selected lane/tier or PASS;
- Energy/Stock spent;
- enemy action result;
- HP before/after turn.

### Balance questions

1. Does Line time create enough but not excessive Energy preparation?
2. Does Chain time produce meaningful Tier choices rather than an automatic best Tier every turn?
3. Does Action selection create a real response decision to the telegraph?
4. Are 30/30/30 budgets too slow, too fast, or appropriately asymmetric?
5. How often does the player finish each phase early?
6. How many meaningful turns occur in the representative boss encounter?
7. Are low Tiers still useful when Tier 6 exists?
8. Is PASS rare and understandable rather than a common soft-lock state?

## 13. Production acceptance criteria

The phased combat foundation is not complete until tests/runtime evidence show all of the following:

1. Enemy action is fixed and visible before Line begins.
2. Line accepts input only during Line Phase.
3. Chain accepts input only during Chain Phase.
4. Line rewards commit before Chain begins.
5. A Chain cascade triggered before timeout finishes deterministically after input closes.
6. No new Chain swap can begin after timeout.
7. Action eligibility uses post-Line/post-Chain settled resources.
8. Player action resolves before enemy action.
9. Action timeout produces PASS without deadlock.
10. Enemy resolves the telegraphed action unless a documented player effect legally modifies it.
11. Boards and resources persist correctly across turns.
12. Board Break resumes/finishes the correct phase without corrupting the other board.
13. System Pause is the only ordinary full-timer pause.
14. Tier 1–6 is represented consistently in rules/data/UI.
15. Existing Engineering Harness tests remain separately identifiable and are not reported as production-turn validation.

## 14. Implementation Reality Gate

Current state at this Decision:

- Production turn canon: `DOCUMENTED / USER_APPROVED`.
- Existing merged Core Combat Foundation / Engineering Harness: `IMPLEMENTED + AUTOMATED_TESTED` for its historical contract.
- Production Line Engine: `NOT_PRESENT`.
- Production Swap-Match Chain Engine: `NOT_PRESENT`.
- Production phased turn controller: `NOT_PRESENT`.
- Production Tier 1–6 Skill execution: `NOT_PRESENT`.
- Production HUD/visual/audio integration: `NOT_PRESENT`.
- User Windows production runtime: `NOT_RUN`.
- Human production playtest: `NOT_RUN`.

Do not promote any historical POC evidence into a PASS for the production phased-turn contract.

## 15. Benchmark trade study

### A. Continuous real-time dual-board combat

- Strength: urgency and simultaneous mastery ceiling.
- Weakness: combines puzzle execution, mode switching, skill selection, and enemy countdown into one cognitive load spike.
- Decision: **REJECT for current production baseline**.

### B. Timed sequential player phases — adopted

`Telegraph → Line → Chain → Action → Enemy`

- Strength: preserves time pressure while making the source of each decision readable.
- Strength: guarantees both puzzle grammars have a role each turn.
- Strength: easy to tune by phase duration and easy to instrument.
- Weakness: can become slow if all timers are treated as mandatory waiting periods.
- Correction: timers are maximum budgets and legal early-finish is supported.
- Decision: **ADOPT**.

### C. Untimed / Action-Point turn structure

- Strength: maximum readability and accessibility.
- Weakness: removes much of the execution pressure that differentiates the intended combat rhythm.
- Decision: **REFERENCE / accessibility fallback candidate**, not first production baseline.

### Long-term fit

B is currently the best fit because it keeps three distinct player questions per turn—Energy, Stock, Action—while preventing the previous always-live clock from making the two-puzzle onboarding and HUD excessively concurrent.

Revisit B if human evidence shows phase order becomes rote, one puzzle contributes little to the final action, or turn duration becomes mostly waiting rather than decision-making.

## 16. Five-pass adversarial review result

1. **Pacing attack:** 30+30+30 can create 90-second turns. Corrected by making each value a maximum, supporting early finish, and requiring telemetry before final lock.
2. **Free-resource attack:** old background Chain resolution could generate Stock while the player already plays Line. Removed from the new ordered turn; Chain settles before Action begins.
3. **Cognitive-load attack:** free switching + RUN/LOCK + Combat Clock added several simultaneous state questions. Removed from production phase language; each phase owns input and one main objective.
4. **Skill-regression attack:** old Stagger depended on enemy seconds countdown. Explicitly superseded rather than silently porting a meaningless effect.
5. **Foundation-regression attack:** merged PR #3 remains a historical Engineering Harness with its tests/evidence intact; production work gets new contracts/tests instead of rewriting old PASS evidence.

No production implementation should begin from the old POC GDD alone. Executors must read this file first, then the latest approved production/visual/encounter decisions and the actual current `main` implementation boundary.

## 17. Planning/build gate

This Decision updates planning canon. It does **not** itself declare production implementation complete or human-validated.

Production BUILD remains subject to the project's current planning-completion / implementation handoff gate. When BUILD is authorized, implementation must be test-first and must create new production-turn regression tests rather than mutating old evidence into compliance.
