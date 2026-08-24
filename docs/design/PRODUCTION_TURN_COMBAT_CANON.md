# Production Turn Combat Canon

- Status: **CURRENT PRODUCTION CANON / USER_APPROVED**
- Decision: `TETRIS-CORE-024 · Telegraph → Line → Chain → Action → Enemy Resolve`
- Date: 2026-08-21
- Timing authority refreshed: 2026-08-25
- Repository: `alsdmlals4-eng/Tetris`
- Scope: first production-quality Vertical Slice and later production gameplay unless superseded by a newer approved Decision.

## 1. Authority and migration boundary

This document is the current production gameplay authority for the **ordered combat turn, Line/Chain sequencing, puzzle/resource ownership, settle boundaries, input authority, player-action order, enemy-action order, Board Break integration, and non-timing UI/telemetry requirements**.

`TETRIS-TIME-025` in `docs/design/PRODUCTION_TURN_TIME_CANON.md` is the sole current authority for **Shared Player Turn Budget timing, READY carryover, timeout behavior, time modifiers, Tempo Reference/Tempo Bonus, and which states consume active player time**. Where any older wording in this document or its history described independent Line/Chain/Action timers, discarded per-stage time, or countdown-derived timing behavior, `TETRIS-TIME-025` supersedes that wording.

The following older contracts remain useful as **Core Combat Foundation / Engineering Harness evidence**, but they are not production gameplay authority where they conflict with current production canon:

- `docs/design/CORE_GAMEPLAY_GDD.md`
- `docs/design/POC_RULESET_V0_1.md`
- `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- `docs/validation/POC_45S_VALIDATION.md`

The merged PR #3 implementation and its tests stay preserved as an Engineering Harness. Do not rewrite its historical validation evidence to pretend that it already implements current production canon.

### Superseded production rules

`TETRIS-CORE-024` supersedes these production assumptions:

- free/manual Line ↔ Chain switching at arbitrary combat times;
- a continuously advancing enemy Combat Clock during normal puzzle play;
- tactical `RUN / LOCK` as a core production combat decision;
- the blanket rule that every inactive board is always frozen;
- `TETRIS-CORE-021`'s need for Chain resolution to continue in the background while the player is already playing Line;
- enemy Intent represented primarily by seconds-until-action during an always-running combat clock.

`TETRIS-TIME-025` additionally supersedes:

- independent Line / Chain / Action timers;
- discarded time at Line→Chain or Chain→Action boundaries;
- per-stage 30/30/30 as current production timing canon.

`TETRIS-CORE-021` still owns the production **Swap-Match Chain grammar**: adjacent swap, match resolution, gravity, refill, automatic cascades, no autonomous swap generation, and stable-board completion.

`TETRIS-SKILL-026` in `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md` is the current production authority for **Attack / Defense / Support × Tier 1–6** Vanguard Technique identity and effect composition. `TETRIS-SKILL-022` remains retained historical design lineage only where not superseded.

`TETRIS-BALANCE-027` in `docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md` owns current Energy / Chain Stock opportunity-cost and Tier-exposure rules.

## 2. Product thesis

The player does not juggle two live puzzle boards simultaneously. Each enemy turn reveals a threat first, then gives the player three ordered preparation/decision stages inside one **Shared Player Turn Budget**:

1. build **Energy** through Line play;
2. build **Chain Stock / Tier access** through Swap-Match Chain play;
3. choose and execute one combat action;
4. resolve the telegraphed enemy action;
5. repeat with a new telegraph.

Core player question:

> The enemy has shown what it will do. During this shared turn budget, how much time should I invest in Energy, how much in Tier access, and which action should I commit before the enemy acts?

Pressure comes from **one bounded player-time resource + known enemy consequence + dual-resource tradeoffs**, not from requiring the player to monitor two puzzle simulations and an always-running enemy clock at the same time.

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

Only `LINE_PHASE`, `CHAIN_PHASE`, and `ACTION_PHASE` consume the active-input Shared Player Turn Budget. The settle/resolve states keep the sequence deterministic but do not spend that player budget; detailed timing behavior belongs to `TETRIS-TIME-025`.

### 3.1 ENEMY_TELEGRAPH

Before the Shared Player Turn Budget begins at Line, the current enemy action is locked and shown to the player.

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
- The player may finish Line early with an explicit `NEXT / READY` action.
- Legal READY preserves the remaining Shared Player Turn Budget for the next player stage.
- If the shared budget reaches zero during Line, stop new input and follow the deterministic Line-timeout route owned by `TETRIS-TIME-025`; do not grant fresh Chain/Action input time.
- Shared time that survives Line is available to later stages in the same turn but never banks into a future turn.

### 3.3 LINE_SETTLE

When Line input closes by READY or shared-budget expiry:

- stop new Line manipulation;
- finish only the atomic placement/clear operation already committed by the last legal input;
- commit resulting Energy/Score/telemetry;
- transition only after the board reaches a deterministic stable point;
- do not consume Shared Player Turn Budget during the forced settle.

Do not allow a zero-time input exploit after expiry. If the shared budget expired, continue through the timeout route rather than opening a new timed stage.

### 3.4 CHAIN_PHASE

- Only the production Swap-Match Chain board accepts swaps.
- A valid swap may trigger clear → gravity → refill → cascade cycles.
- Chain results create Chain Stock / Tier access according to production data.
- The Line board accepts no input and is exactly frozen during this phase.
- The player may finish Chain early with READY only when the Chain board is stable.
- Legal READY preserves the remaining Shared Player Turn Budget for Action.
- If the shared budget reaches zero during Chain, no new swap begins; finish the already-triggered deterministic cascade and follow the timeout/PASS route owned by `TETRIS-TIME-025`.

### 3.5 CHAIN_SETTLE

After Chain input closes:

- no new swap may start;
- an already-triggered clear/gravity/refill/cascade must finish to a full stable board;
- no autonomous swap is generated;
- completed Chain rewards are committed only from the final stable resolution;
- forced settle does not consume Shared Player Turn Budget;
- then the game enters Action Phase only if the timeout rules still permit player Action input; otherwise it proceeds through deterministic PASS/Enemy Resolve.

This replaces the old production need for `background resolver while Line is active`. The resolver may finish **after Chain input closes**, but the game does not advance to another puzzle input stage while it is still resolving.

### 3.6 ACTION_PHASE

- The player chooses one combat action from the currently legal Skill Lane/Tier cells.
- Current production lanes: **Attack / Defense / Support**.
- Current production Tier range: **1–6**.
- Eligibility is evaluated from the Energy and Chain Stock that exist after both puzzle stages settle.
- Selecting a legal action may resolve immediately; the player does not need to wait out the remaining Shared Player Turn Budget.
- Legal Action confirmation freezes the remaining player budget for Tempo evaluation according to `TETRIS-TIME-025`.
- If no legal action is selected before the shared budget reaches zero, the player performs deterministic `PASS` with no resource spend and the enemy proceeds.
- `PASS` is a fallback state, not a competitive resource strategy and grants no Tempo Bonus.

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

## 4. Timing integration contract

Current timing authority is `TETRIS-TIME-025 · Shared Player Turn Budget + Tempo Reward`.

The integration facts this combat canon depends on are:

- one active-input budget spans `LINE → CHAIN → ACTION` without resetting;
- READY carries remaining time from Line to Chain and from Chain to Action;
- `LINE_SETTLE`, `CHAIN_SETTLE`, forced transitions/animations, Enemy Resolve, and System Pause do not consume active player budget;
- budget modifiers are snapshotted before Line according to the timing canon;
- timeout never creates a fresh stage budget and always reaches deterministic settle/skip/PASS/Enemy Resolve behavior without deadlock;
- unused shared time never banks into a future turn;
- Tempo Reference is separate from Effective Budget, so extra-time effects do not automatically create free speed reward.

The former independent `30 s Line / 30 s Chain / 30 s Action` seed is **SUPERSEDED TIMING PROVENANCE**, not a current tuning target. The first production shared total may use the historical aggregate only as a migration comparison point, but exact total seconds, difficulty variants, modifier magnitudes, and Tempo curve remain evidence-dependent tuning owned by `TETRIS-TIME-025` and `TETRIS-BALANCE-027`.

### Timing revisit triggers

Revisit the shared-budget tuning if human evidence shows any of the following:

- Line repeatedly consumes so much time that Chain/Action become functionally absent;
- players spam READY after minimal qualification because Tempo dominates meaningful preparation;
- Haste/Slow becomes mandatory or feels unfair despite visible telegraphing;
- players routinely wait with nothing meaningful to do;
- boss combat has too few meaningful turns or the Slice exceeds intended pacing without more decision quality;
- an untimed/AP accessibility route or another bounded timing model produces higher player value without erasing the intended execution tension.

## 5. Resource contract

### Energy

- Line is the primary Energy source.
- Energy persists across stages and turns until spent or explicitly modified by an enemy/system rule.
- Production design must not rely on the Engineering Harness's `+1 Energy/sec` emergency recovery; the mandatory Line stage each turn is the primary anti-soft-lock opportunity.
- Any future emergency recovery must be approved as a separate production rule and must not reward passive waiting.

### Chain Stock / Tier access

- Swap-Match Chain is the primary source of Chain Stock/Tier access.
- Stock persists across turns until spent or explicitly modified.
- Production Tier cap is 6.
- Tier N consumes N Stock under `TETRIS-BALANCE-027`.
- Exact Stock gain formula for the Swap-Match engine must be data-driven and tied to demonstrated Chain/cascade performance rather than passive time.
- Energy and Chain Stock are not interchangeable; their distinct opportunity costs are part of the core decision.

### Score

- Score remains performance evidence, not a Skill currency.
- Line and Chain Score events retain their origin for telemetry and post-run analysis.
- Tempo score is non-currency evidence/presentation unless a later approved decision changes that boundary.

## 6. Skill contract under the turn model

Current lanes under `TETRIS-SKILL-026`:

- **Attack** — enemy defeat progress and offensive setup/forecast control.
- **Defense** — mitigation/counter-preparation and current-Telegraph protection.
- **Support** — recovery, next-action/next-turn setup, time support, and visible future control.

Current range: **Tier 1–6**. Tier is a tactical commitment/cost band, not a linear instruction to always choose the highest available Tier.

The old real-time `Stagger = add seconds to the current enemy countdown` definition is superseded because there is no always-running enemy action countdown during Line/Chain/Action stages.

For current production implementation:

- do not silently port countdown-based Stagger;
- use the approved SKILL-026 effect identities/primitives instead of preserving obsolete timing semantics;
- Attack remains valid as direct damage without an enemy countdown;
- Defense and Support retain distinct current-vs-future response ownership;
- no per-stage timer manipulation is introduced merely to preserve an old Stagger name.

## 7. Board Break under phased turns

Board Break remains part of production canon.

During Line or Chain stage:

1. detect the board failure at a deterministic boundary;
2. resolve Board Break atomically;
3. apply configured HP loss;
4. clear/reset only the failed board according to its production queue/randomizer contract;
5. preserve the other board and combat resources unless an explicit enemy/system rule says otherwise;
6. return the failed board to a legal stable state;
7. if Shared Player Turn Budget remains, resume the **same player stage**; if it reached zero, follow the timing canon's deterministic timeout path.

Default combat defeat remains player HP reaching zero. In the first timing slice, a Board Break also makes that turn ineligible for Tempo Bonus according to `TETRIS-TIME-025`.

## 8. UI / UX contract

`TETRIS-UX-023` is adapted to the current production turn and timing model.

### Persistent hierarchy

1. current enemy Telegraph and expected result;
2. one Shared Player Turn Timer + current stage `LINE / CHAIN / ACTION`;
3. active puzzle board during Line/Chain;
4. HP / Energy / Chain Stock;
5. Attack / Defense / Support Tier 1–6 lanes during Action Phase;
6. lower-priority Next Forecast when known;
7. Tempo eligibility/provisional reward when relevant;
8. inactive board preview / combat art / decorative VFX.

### Stage communication

The HUD must always make these states explicit:

- `LINE · PREPARE ENERGY`
- `CHAIN · PREPARE STOCK`
- `ACTION · CHOOSE RESPONSE`
- `RESOLVING` during forced settle
- `ENEMY · RESOLVING`

The Shared Player Turn Timer must not visually reset at Line→Chain or Chain→Action.

Do not reuse the Engineering Harness's `RUNNING / LOCKED / SUSPENDED` labels as the primary player-facing production stage language.

### Sidecar

- During Line Phase, Chain Sidecar is stable/input-off.
- During Chain Phase, Line Sidecar is exact frozen state.
- During Action Phase, both boards are input-off and show their final prepared states.
- Chain cascade visuals may continue only during `CHAIN_SETTLE`, with a clear `RESOLVING` treatment; Action input begins after stable completion if shared time remains.

### Enemy forecast

The old continuously decreasing enemy ETA timeline is replaced by a **turn forecast**:

- current telegraphed action: highest priority;
- next authored action: lower priority when known;
- one Shared Player Turn Timer: the live seconds-based pressure indicator during player control.

## 9. System Pause and input authority

- System Pause stops simulation/audio and does not consume Shared Player Turn Budget.
- Forced settle/resolution also does not consume player budget, but is not an extra decision window.
- There is no tactical `LOCK` resource mechanic in the current production turn loop.
- Gameplay uses named input actions; physical keys are not read directly in domain logic.
- A player stage owns input authority. Inputs for another stage must be rejected rather than queued invisibly.

## 10. Encounter adaptation

`TETRIS-ENCOUNTER-006 · Authored Intent Ladder + HP Phase` remains adopted, but its old real-time countdown model is not current timing authority.

Keep:

- authored readable enemy actions;
- current + next telegraph/forecast;
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
- optional future-turn modifiers.

## 11. First-run flow adaptation

The first run teaches the real turn in the same order the player uses it:

```text
Enemy Telegraph
→ Shared Player Turn Budget starts
→ Line: earn Energy
→ READY / Line Settle
→ Chain: earn Stock / Tier access
→ READY / Chain Settle
→ Action: choose ATK / DEF / SUP × Tier
→ Player Action Resolve
→ Enemy Resolve
```

Do not teach free board switching, tactical RUN/LOCK, three resetting timers, or a continuously running enemy ETA as production mechanics.

The first enemy turn must be survivable even if the player makes a weak Action choice so the complete turn loop can be learned through consequence rather than a modal explanation.

## 12. Telemetry contract

Record at minimum, alongside the more detailed timing fields owned by `TETRIS-TIME-025`:

### Per turn

- turn index;
- current Telegraph and known Next Forecast;
- effective shared budget and modifier sources;
- active player time used in Line / Chain / Action separately;
- READY/timeout state per player stage;
- Line/Chain settle durations separately from active time;
- Energy before/after Line;
- cascade depth and Stock before/after Chain;
- selected lane/tier or PASS;
- Energy/Stock spent;
- Tempo eligibility/reason and applied potency;
- enemy action result;
- HP before/after turn.

### Balance questions

1. Does Line participation create meaningful Energy preparation without starving later stages?
2. Does Chain participation produce meaningful Tier choices rather than an automatic best Tier every turn?
3. Does Action selection create a real response decision to the Telegraph?
4. Is the total Shared Player Turn Budget too slow, too fast, or badly allocated by player incentives?
5. How often does the player use READY in each stage, and why?
6. How many meaningful turns occur in the representative boss encounter?
7. Are low Tiers still useful when Tier 6 exists?
8. Is PASS rare and understandable rather than a common soft-lock state?
9. Does Tempo reward decisive play without turning minimal-qualification speed farming into the dominant strategy?

## 13. Production acceptance criteria

The production combat foundation is not complete until tests/runtime evidence show all of the following:

1. Enemy action is fixed and visible before Line begins.
2. One Shared Player Turn Budget spans Line→Chain→Action without reset.
3. Line accepts input only during Line Phase.
4. Chain accepts input only during Chain Phase.
5. Line rewards commit before Chain begins.
6. READY carries remaining shared time forward where legal.
7. A Chain cascade triggered before timeout finishes deterministically after input closes without spending player budget during settle.
8. No new Chain swap can begin after timeout.
9. Action eligibility uses post-Line/post-Chain settled resources.
10. Player action resolves before enemy action.
11. Action timeout produces PASS without deadlock.
12. Enemy resolves the telegraphed action unless a documented player effect legally modifies it.
13. Boards and resources persist correctly across turns.
14. Board Break resumes/finishes the correct stage without corrupting the other board and obeys timeout rules.
15. System Pause / forced settle do not spend active player budget.
16. Tier 1–6 is represented consistently in rules/data/UI and lower-Tier viability remains a validation requirement.
17. Existing Engineering Harness tests remain separately identifiable and are not reported as current production-turn validation.
18. Historical independent-timer wording cannot re-enter this current combat canon without failing the tooling semantic contract.

## 14. Implementation Reality Gate

This section describes **merged-main evidence**, not unmerged PR claims.

- Production turn canon: `DOCUMENTED / USER_APPROVED`.
- Production timing canon: `DOCUMENTED / USER_APPROVED`.
- Existing merged Core Combat Foundation / Engineering Harness: `IMPLEMENTED + AUTOMATED_TESTED` for its historical contract.
- Production Line Engine on merged main: `NOT_PRESENT`.
- Production Swap-Match Chain Engine on merged main: `NOT_PRESENT`.
- Production shared-budget turn controller on merged main: `NOT_PRESENT`.
- Production Tier 1–6 Skill execution on merged main: `NOT_PRESENT`.
- Production HUD/visual/audio integration on merged main: `NOT_PRESENT`.
- User Windows production runtime: `NOT_RUN`.
- Human production playtest: `NOT_RUN`.

An open implementation PR may contain working code and tests, but it does not change merged-main IRG until that exact head is validated, merged, and main is read back. Do not promote historical POC evidence or open-PR presence into a higher evidence tier.

## 15. Benchmark trade study

### A. Continuous real-time dual-board combat

- Strength: urgency and simultaneous mastery ceiling.
- Weakness: combines puzzle execution, mode switching, skill selection, and enemy countdown into one cognitive-load spike.
- Decision: **REJECT for current production baseline**.

### B. Shared-budget sequential player stages — adopted

`Telegraph → [one shared budget: Line → Chain → Action] → Enemy`

- Strength: preserves execution pressure while making the source of each decision readable.
- Strength: turns time itself into an allocation choice: more Line depth vs more Chain/Tier preparation vs enough Action decision time.
- Strength: guarantees both puzzle grammars have an explicit role without running both at once.
- Strength: one budget/modifier pipeline is easier to explain and keeps accessibility/tuning experiments coherent.
- Weakness: Line can starve later stages if budget/tuning incentives are poor.
- Correction: READY carryover, deterministic timeout, separate Tempo Reference, stage telemetry, and human A/B comparison.
- Decision: **ADOPT**.

### C. Untimed / Action-Point turn structure

- Strength: maximum readability and accessibility; strong comparison route if timer pressure blocks learning.
- Weakness: removes much of the execution pressure that currently differentiates the intended combat rhythm.
- Decision: **REFERENCE / accessibility fallback candidate**, not first production baseline.

### Long-term fit

B is currently the best fit because it keeps three distinct player questions per turn—Energy, Stock/Tier, Action—while making **time allocation itself** a fourth meaningful choice and preventing the old always-live clock from making onboarding/HUD excessively concurrent.

Revisit B if human evidence shows stage order becomes rote, one puzzle contributes little to the final action, timer pressure blocks comprehension, or the shared budget repeatedly collapses into one dominant allocation policy.

## 16. Adversarial review lineage

Earlier CORE-024 reviews correctly removed several concurrent-load and resolver problems, but their original independent-timer solution was later superseded by `TETRIS-TIME-025`.

Current protected findings/lessons are:

1. **Timing-allocation attack:** independent 30/30/30 timers made early finish strategically weak. TIME-025 replaces them with one Shared Player Turn Budget and READY carryover.
2. **Free-resource attack:** old background Chain resolution could generate Stock while the player already played Line. Ordered Chain input/settle remains preserved before Action.
3. **Cognitive-load attack:** free switching + RUN/LOCK + Combat Clock added several simultaneous state questions. Current stages give input authority to one main surface at a time.
4. **Skill-regression attack:** old Stagger depended on enemy seconds countdown. It remains explicitly superseded rather than silently ported.
5. **Foundation-regression attack:** merged PR #3 remains a historical Engineering Harness with its own evidence; current production work requires separate contracts/tests/readback.

No production implementation should begin from the old POC GDD or this combat document alone. Executors must also read `TETRIS-TIME-025`, `TETRIS-SKILL-026`, `TETRIS-BALANCE-027`, the current machine index, current `main`, and relevant open-PR state.

## 17. Planning/build boundary

This document updates planning canon and owner boundaries. It does **not** itself declare production implementation complete, merged, runtime-verified, or human-validated.

Any active Production BUILD workstream is governed by its own approved contract and exact-head evidence. This planning/canon synchronization must not take over, rebase, or merge an independent Production PR. When implementation becomes merged production truth, this document/index/System Record should be refreshed only from post-merge readback rather than from an open-PR claim.
