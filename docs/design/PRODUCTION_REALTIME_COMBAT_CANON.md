# Production Continuous Real-Time Combat Canon

- Status: **CURRENT PRODUCTION CANON / USER_APPROVED / IMPLEMENTATION AUTHORIZED**
- Decision: `TETRIS-CORE-029 · Continuous Real-Time Mode-Switch Combat + Full Tactical Pause`
- Date: 2026-08-26
- Repository: `alsdmlals4-eng/Tetris`
- Scope: first production-quality Vertical Slice combat architecture and later production gameplay unless superseded by a newer USER_APPROVED Decision.

## 1. Authority and supersession boundary

This document is the primary production gameplay authority for combat lifecycle, continuous simulation time, LINE↔CHAIN workspace switching, Skill tactical pause, enemy ETA/commit scheduling, workspace persistence, and the user-directed 50/50 battle composition.

The following production documents are **HISTORICAL / SUPERSEDED** where they define ordered player/enemy turns or turn-budget timing:

- `TETRIS-CORE-024` — `docs/design/PRODUCTION_TURN_COMBAT_CANON.md`
- `TETRIS-TIME-025` — `docs/design/PRODUCTION_TURN_TIME_CANON.md`

Their bodies remain preserved as provenance. They do not override this canon.

Retained authorities:

- `TETRIS-CORE-021` where it defines production Swap-Match Chain grammar;
- `TETRIS-CHAIN-038` for the current orthogonal-swap, straight-3+ horizontal/vertical/diagonal match grammar and optional MP lock;
- `TETRIS-SKILL-039` / `TETRIS-BALANCE-040` for Vanguard category-only Combo-Resolved Technique preview/confirm and bounded skill-only Combo-to-MP fallback;
- `TETRIS-VISUAL-041` for Parchment Field Manual + Readable Puzzle Tactics direction;
- authored Telegraph / visible Next Forecast principles where compatible with continuous combat.

Machine routing authority is `docs/design/PRODUCTION_CANON_INDEX.json`.

## 2. Product thesis

Combat runs continuously from encounter start until Victory or Defeat. The player and enemy share one real-time combat timeline.

The player continuously decides where attention is most valuable:

```text
LINE workspace  → recover MP
CHAIN workspace → earn Combo, later CHAIN MP recovery and a higher resolved Stage
SKILL workspace → FULL_TACTICAL_PAUSE, inspect and commit a Technique
```

Core player question:

> The enemy is acting in real time. Should I recover MP in LINE, switch to CHAIN to earn Combo or set up a later Combo with MP, or freeze the fight now and spend what I have on the right Attack / Defense / Support Technique?

Pressure comes from real-time enemy threat plus the opportunity cost of attention, not from an ordered player-turn countdown.

## 3. Canonical encounter lifecycle

```text
BATTLE_START
→ COMBAT_RUNNING
   ├─ active workspace = LINE
   ├─ active workspace = CHAIN
   └─ open SKILL → TACTICAL_PAUSE_SKILL
                    → inspect resolved preview / explicit CONFIRM
                    → COMBAT_RUNNING
→ VICTORY | DEFEAT
```

There is no mandatory player-turn boundary between these states.

Encounter terminal conditions are real combat terminal conditions, normally enemy HP ≤ 0 or player HP ≤ 0.

The production slice presents the terminal result as `VICTORY` or `DEFEAT` and exposes a terminal-only `RETRY` action that reloads the current Frontier Gate encounter. Retry starts a fresh encounter; it does not alter the retained combat, puzzle, or balance rules.

## 4. CONTINUOUS_REALTIME time model

While `COMBAT_RUNNING`:

- enemy action ETA and authored scheduler advance;
- active puzzle workspace simulation advances;
- combat statuses/cooldowns defined as real-time advance;
- combat animation, simulation-driven VFX, and combat audio advance;
- inactive puzzle workspace does not accept input and does not advance its puzzle simulation except for completion of an already-committed safe-switch boundary.

There is no ordered LINE → CHAIN → ACTION stage timer and no turn-speed reward model in CORE-029.

Telemetry must distinguish:

- wall-clock encounter duration;
- active combat simulation time;
- tactical-pause duration;
- manual-pause duration.

Wall-clock reading time inside a paused Skill surface is not automatically treated as poor performance.

## 5. FULL_TACTICAL_PAUSE

Opening Skill enters `TACTICAL_PAUSE_SKILL`.

During this state simulation is fully stopped:

- enemy ETA/scheduler progression stops;
- enemy action resolution cannot advance;
- puzzle gravity, lock delay, Chain resolution, and puzzle timers stop;
- combat status ticks and real-time cooldowns stop;
- simulation-driven animation/VFX stop;
- simulation audio is paused/held consistently;
- only Skill/UI navigation, preview, cancel, and explicit CONFIRM remain active.

The player may spend unlimited wall-clock time reading the Skill surface in the first Slice.

Manual system pause also stops the full simulation. `TACTICAL_PAUSE_SKILL` and manual pause may share a low-level pause primitive, but they remain distinct player-facing states and telemetry reasons.

Pause ownership must be tokenized/reference-safe so one subsystem cannot resume simulation while another pause reason remains active.

## 6. Persistent puzzle workspaces

The battle owns two independent long-lived puzzle states:

```text
LineWorkspaceState
ChainWorkspaceState
```

Only one is visible and input-active at a time inside the large Puzzle Surface.

### LINE

- production falling-block Line grammar;
- Line Clear remains the primary MP source (current internal runtime field: `energy`);
- board, active piece, Hold, Next/queue, ghost, gravity, lock-delay, randomizer, and related legal state persist when leaving LINE;
- switching away does not rebuild the board, reroll the queue, respawn the active piece, or reset lock timing.

### CHAIN

- production grammar: orthogonally adjacent swap → straight horizontal/vertical/diagonal 3+ match → clear → gravity/refill → cascade → stable board; every resolved wave gives Combo +1, then CHAIN MP recovery from `(sum maximal qualified line lengths − 3) + post-wave Combo`;
- a no-match restores the pre-swap board unless the player spends fixed **1 MP** to keep that swap as a later Combo setup; either outcome resets Combo, and a kept swap gives no immediate clear, cascade, Combo, or MP recovery;
- Chain performance remains the primary source of the single shared Combo resource / Tier opportunity (current internal runtime field: `stock` / historical `Chain Stock`); Combo is capped at 10 and spending it on a Technique deliberately lowers later CHAIN MP recovery;
- board, refill/randomizer state, selection/history required for legal continuation, and pending deterministic resolution persist when leaving CHAIN;
- switching away does not grant free progress or reroll state.

`TETRIS-CHAIN-038` is current approved design, not a claim that its whole grammar is in the merged runtime: current code detects only horizontal/vertical runs, has no MP-lock path, and retains a legacy cap-6 cascade-depth Combo reward without CHAIN MP recovery. Exact implementation alignment is `PARTIAL_HV_ONLY_NO_MP_LOCK_NO_MP_CAP_LEGACY_DEPTH_REWARD` until its Phase 2 review and exact-head verification complete.

Required return invariant:

```text
LINE state A
→ CHAIN state B
→ LINE exact legal continuation of A
→ CHAIN exact legal continuation of B
```

Switching changes visibility and input ownership, not workspace identity.

## 7. Deterministic safe workspace switching

The player may request `LINE ↔ CHAIN` freely during `COMBAT_RUNNING`.

The request is accepted by the input layer, but handoff commits only at the next deterministic puzzle-safe boundary:

- LINE: after the currently committed atomic movement/rotation/drop/placement step resolves;
- CHAIN: after the currently committed swap plus any already-triggered clear/gravity/refill/cascade reaches a stable board.

After a switch request, the outgoing workspace accepts no new puzzle input. Enemy combat time continues while the safe boundary finishes.

At handoff:

1. commit puzzle rewards/telemetry exactly once;
2. preserve the exact outgoing workspace state;
3. freeze its puzzle simulation;
4. restore the incoming workspace exactly;
5. transfer input authority.

Switching must not reset gravity/lock delay, reroll Hold/Next/refill, duplicate rewards, cancel a committed Board Break, erase an unfavorable legal state, pause the enemy scheduler, or mint MP/Combo.

## 8. Enemy real-time scheduler and Telegraph

Enemy actions run on a continuous authored schedule during `COMBAT_RUNNING`.

Minimum persistent information:

- current action identity/category;
- expected result or damage/resource effect;
- current ETA when time-scheduled;
- lower-priority visible Next Forecast when authored/known;
- enemy HP/phase/state.

The current telegraphed action is not secretly replaced in direct reaction to the player's current board or selected counter unless a later approved visible reactive-archetype rule explicitly allows it.

### Same-frame Skill-open boundary

Ordering is deterministic:

1. process Skill-open intent at the beginning of the input frame;
2. if `TACTICAL_PAUSE_SKILL` is entered before the enemy action commit point, simulation freezes and the action waits;
3. after the explicit commit point is crossed, opening Skill cannot retroactively cancel the committed action.

The commit point is state in the scheduler, not inferred from animation timing.

Enemy exact cadence/ETA values remain `TUNE_REQUIRED` until runtime and Human evidence justify them.

## 9. Skill tactical decision surface

Skill is not an ordered action phase.

Entry flow:

```text
COMBAT_RUNNING
→ open SKILL
→ TACTICAL_PAUSE_SKILL
→ ATK / DEF / SUP only
→ one Combo-Resolved Stage preview
→ inspect detail / cost / fallback / condition / target
→ explicit CONFIRM
→ resolve atomically
→ COMBAT_RUNNING at exact paused simulation time
```

Selecting a category never spends resources. Only explicit CONFIRM commits.

On successful CONFIRM:

- previewed MP and Combo costs, including a needed 5-MP-per-Combo fallback conversion, are spent atomically (current internal fields: `energy` and `stock`);
- Technique effects resolve through approved data-driven primitives;
- Skill closes unless the Technique owns a bounded explicit resolution state;
- combat resumes at the exact paused simulation time;
- the previously active LINE/CHAIN workspace remains unchanged by reading the Skill UI.

Cancel resumes combat with no spend.

## 10. Resource and Tier contract

Retained structural identity:

- **MP** is primarily earned through LINE;
- **Combo** is primarily earned through CHAIN performance and is the shared Tier/CHAIN-MP resource;
- the resources are not interchangeable;
- Combo is hard-capped at **10**;
- MP is hard-capped at **60**; MP overflow does not create a combat resource and must be visible before a further LINE reward;
- approved initial LINE gains are Single/Double/Triple/Four = **10 / 22 / 36 / 52 MP**, making a competent first Single enough for the initial 10-MP Stage-1 opportunity;
- every resolved CHAIN wave gives Combo +1, then recovers MP by `(sum of maximal qualified line lengths − 3) + post-wave Combo`; crossing qualified groups count independently, the `−3` applies once per wave, and a later successful manual swap continues the same stored Combo;
- current Combo resolves one authored Stage in the selected ATK/DEF/SUP lane; no manual Tier selection exists in the approved flow;
- MP cost remains Technique-specific and data-driven. If the current Combo Stage lacks MP, only surplus Combo may convert at **5 MP each** to reach the highest feasible lower Stage; a failed/reverted CHAIN swap or fixed-**1 MP** MP lock still resets Combo;
- the category decision is a tactical commitment, not a linear instruction to choose a highest manual Tier. Saving Combo remains valuable because it improves later CHAIN MP recovery and preserves a higher resolved Stage.

The opportunity-cost question is now real-time:

> While the enemy clock keeps moving, how long can I safely stay in LINE or CHAIN before I pause and spend resources?

Technique MP costs, enemy cadence, cooldowns, and magnitudes remain `TUNE_REQUIRED` / `TUNING_SEED_NOT_FINAL` until supported by runtime and Human evidence. The initial 10/22/36/52 LINE gains, fixed 1-MP failed-swap lock, 60-MP hard cap, and structured Combo/CHAIN-MP rule are approved player-facing rules, while still subject to a later data-only balance revision after evidence.

## 11. Legacy SKILL-026 semantic migration boundary

Do not silently translate turn-bound effects into seconds.

The following remain `REALTIME_MIGRATION_REQUIRED` and fail closed until a separate bounded semantic decision is approved:

- Haste defined as additional time for a future player-turn budget;
- Battle Trance defined only as a next-turn LINE/CHAIN preparation window;
- status durations defined only by turn boundaries where no event-bound meaning already exists;
- turn-speed/Tempo-based potency or eligibility;
- wording whose only valid trigger is a current-turn enemy-resolve boundary.

Retained non-turn-bound families include direct damage, healing, mitigation, counter from prevented damage, resource ward, setup/debuff primitives, lethal safety, targeting, and exact current-vs-visible-next action binding where their semantics remain valid under real-time scheduling.

## 12. UI / UX contract

Target desktop composition:

- left ≈ **50%**: one large Puzzle Surface;
- right ≈ **50%**: persistent Combat Stage + enemy threat + resources + Skill surface.

The ratio is a user-directed readability target, not a fixed pixel law. The Gatebreaker occupies the dominant CombatStage silhouette; the separate Vanguard portrait keeps player identity readable without shrinking the boss. 1280×720 validation may adjust small gutters without making either primary surface secondary.

The left surface shows only the active full puzzle workspace:

```text
LINE selected  → large falling-block board
CHAIN selected → large Swap-Match board
```

The inactive board is not a mandatory full sidecar.

The right surface keeps at least:

- player/enemy combat representation;
- enemy HP/phase;
- Current Telegraph + ETA;
- lower-priority Next Forecast when known;
- player HP / MP / Combo;
- mode controls `LINE / CHAIN / SKILL`.

Skill-open state visibly communicates `TACTICAL PAUSE`, preserves the frozen puzzle as context, and prioritizes `ATK / DEF / SUP → one Combo-Resolved preview → explicit CONFIRM` while keeping the motivating enemy threat readable.

Do not show obsolete ordered stage rails, stage-advance READY UI, turn-timeout PASS UI, or the superseded turn-speed reward UI as current production controls.

## 13. Runtime ownership

Recommended responsibility split:

### `ProductionCombatRuntime`
Owns encounter lifecycle, global simulation state, Victory/Defeat, and subsystem orchestration. It does not own puzzle rules.

### `SimulationPauseController`
Owns pause reasons/tokens and effective simulation pause state.

### `PuzzleWorkspaceManager`
Owns active workspace id, persistent LINE/CHAIN references, switch request, safe-boundary handoff, and puzzle input authority. It does not own MP/Combo formulas.

### `EnemyActionScheduler`
Owns current authored action, ETA, explicit commit point, Next Forecast, pause-aware advancement, and deterministic resolution request.

### `ProductionResourceState`
Owns HP/MP/Combo semantics and atomic gain/spend events; the current implementation field names remain `energy` / `stock` until Phase 2 migration.

### `TechniqueSession`
Owns paused browse/selection/eligibility/detail/confirm state. It does not advance combat time.

### `TechniqueResolver`
Owns atomic spend + effect execution after explicit CONFIRM of the resolved preview.

### UI presenter/view
Reads authoritative state and renders it; UI does not become gameplay authority.

## 14. Board Break

Board Break remains puzzle-local failure with combat consequence.

At a deterministic puzzle boundary:

1. detect failure;
2. apply configured HP/resource consequence atomically;
3. reset only the failed workspace according to its puzzle contract;
4. preserve the other workspace state;
5. continue enemy real-time scheduling unless the game is in tactical/system pause or has reached Victory/Defeat.

Board Break does not create a hidden turn boundary. Exact penalties remain `TUNE_REQUIRED` unless another retained canon already locks them.

## 15. Evidence and Implementation Reality Gate

Evidence classes remain separate:

- this canon/spec → approved design intent;
- branch files/tests → exact-branch implementation evidence only;
- GitHub Actions → automated evidence for the tested SHA only;
- merged-main readback → merged repository truth;
- target-device runtime receipt → observed runtime on that target;
- Human first-exposure receipts → comprehension/readability/choice/experience evidence only for the tested build.

Current CORE-029 runtime status at canon migration start: **NOT_PRESENT**.

Draft PR #19 ordered-turn implementation is a **READ_ONLY source snapshot** for selected reusable deterministic components. Its old ordered orchestration is not current CORE-029 runtime evidence and is not merged wholesale.

User Windows runtime, first-exposure comprehension, readability, fun, memorable payoff, and final balance remain **NOT_RUN / FUN_HYPOTHESIS / TUNE_REQUIRED** until the corresponding receipts exist.
