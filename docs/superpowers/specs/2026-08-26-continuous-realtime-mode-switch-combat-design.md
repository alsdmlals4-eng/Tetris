# Continuous Real-Time Mode-Switch Combat Design

- Status: **USER-APPROVED CORE DIRECTION / WRITTEN SPEC REVIEW REQUIRED / RUNTIME NOT AUTHORIZED**
- Decision: `TETRIS-CORE-029 · Continuous Real-Time Mode-Switch Combat + Full Tactical Pause`
- Date: 2026-08-26
- Repository: `alsdmlals4-eng/Tetris`
- Scope: first production-quality Vertical Slice combat architecture
- Supersedes directionally: `TETRIS-CORE-024`, `TETRIS-TIME-025` where they define ordered player/enemy turns, `LINE → CHAIN → ACTION`, Shared Player Turn Budget, READY stage handoff, timeout/PASS turn flow, and Tempo-as-turn-speed reward.
- Retains unless explicitly changed below: production Line grammar, production Swap-Match Chain grammar, Line→Energy ownership, Chain→Chain Stock/Tier ownership, `ATK / DEF / SUP × Tier 1–6`, authored enemy Telegraph/Forecast, current `TETRIS-VISUAL-028` art/UI direction, and deterministic evidence boundaries.

## 1. Product thesis

Combat runs continuously from encounter start to Victory or Defeat.

The player and enemy share one continuous combat timeline. The player does **not** receive an alternating turn, and the enemy does **not** wait for a `LINE → CHAIN → ACTION` sequence to finish.

The player continuously decides which workspace is most valuable **right now**:

```text
LINE workspace  → build Energy
CHAIN workspace → build Chain/Combo performance and Chain Stock/Tier access
SKILL workspace → full tactical pause, inspect ATK/DEF/SUP, commit a Technique
```

Core player question:

> The enemy is acting in real time. Should I keep building Energy, switch to Chain for stronger Tier access, or freeze the fight now and spend what I have on the right Attack / Defense / Support Technique?

The intended pressure comes from **real-time enemy threat + opportunity cost of where the player spends attention**, not from a per-turn countdown.

## 2. Canonical encounter loop

```text
BATTLE_START
→ COMBAT_RUNNING
   ├─ active workspace = LINE
   ├─ active workspace = CHAIN
   └─ open SKILL → TACTICAL_PAUSE_SKILL
                    → inspect/select/confirm Technique
                    → COMBAT_RUNNING
→ VICTORY | DEFEAT
```

There is no mandatory player-turn boundary between these states.

The encounter ends only when a real encounter terminal condition is reached, normally enemy HP ≤ 0 or player HP ≤ 0.

## 3. Time model

### 3.1 Continuous combat time

While `COMBAT_RUNNING`:

- enemy action timers/telegraphs advance;
- enemy authored action scheduler advances;
- combat statuses/cooldowns that are defined as real-time advance;
- active puzzle workspace simulation advances;
- combat animation/VFX/audio advance;
- the inactive puzzle workspace does not accept input and does not advance its puzzle simulation except for the safe-switch boundary defined below.

There is **no Shared Player Turn Budget** and no `LINE / CHAIN / ACTION` timer reset because those stages no longer exist.

### 3.2 Full tactical pause

Opening the Skill workspace enters `TACTICAL_PAUSE_SKILL`.

During this state the game simulation is fully stopped:

- enemy action timers and Telegraph countdowns stop;
- enemy action resolution does not advance;
- enemy/player combat animation and simulation-driven VFX stop;
- puzzle gravity, lock delay, Chain resolution, and puzzle timers stop;
- combat status ticks stop;
- real-time skill cooldowns stop;
- encounter timers stop;
- simulation audio is paused or held consistently with the project's pause implementation;
- **only Skill/UI navigation and confirmation input remain active**.

The player may spend unlimited wall-clock time reading and choosing a Technique. This is intentional tactical cognition, not a performance failure.

### 3.3 Manual system pause

Manual Pause also fully stops simulation. It is a system/menu state, not a Skill decision state.

`TACTICAL_PAUSE_SKILL` and `SYSTEM_PAUSE` may share the same low-level simulation pause primitive, but they remain distinct player-facing states and telemetry events.

### 3.4 Measurement boundary

Telemetry must distinguish:

- wall-clock encounter duration;
- active combat simulation time;
- tactical-pause duration;
- manual-pause duration.

Do not score or balance a player as slower merely because they spent longer reading a paused Skill panel unless a later approved rule explicitly uses wall-clock time.

## 4. Persistent puzzle workspaces

The left side of the battle screen is one **large Puzzle Surface**, not two simultaneously visible boards.

The game owns two independent persistent workspace states:

```text
LineWorkspaceState
ChainWorkspaceState
```

Only one is visible/input-active at a time.

### 4.1 LINE workspace

- production falling-block Line gameplay;
- Line clear remains the primary Energy source;
- queue/Hold/Next/ghost/gravity/lock state belong to LineWorkspaceState;
- leaving Line does not rebuild the board, reroll the queue, reset the active piece, reset lock delay, or grant a new spawn.

### 4.2 CHAIN workspace

- production Swap-Match Chain gameplay;
- adjacent-swap → match → clear → gravity/refill → cascade grammar remains;
- Chain/Combo performance remains the primary source of Chain Stock/Tier opportunity;
- leaving Chain does not rebuild the board, reroll seed/refill state, clear selection history, or grant free Chain progress.

### 4.3 Return-state guarantee

Required invariant:

```text
LINE state A
→ switch to CHAIN
→ play CHAIN to state B
→ switch to LINE
→ exact legal continuation of state A
→ switch to CHAIN
→ exact legal continuation of state B
```

Mode switching changes **visibility + input ownership**, not workspace identity.

## 5. Safe workspace switching

Player intent to switch `LINE ↔ CHAIN` is free and may be requested during real-time combat.

The implementation must not allow rapid switching to reset puzzle mechanics or duplicate rewards.

### 5.1 Deterministic handoff rule

A switch request is accepted immediately by the input layer, but the workspace handoff commits at the next deterministic puzzle-safe boundary:

- Line: after the currently committed atomic movement/rotation/drop/placement step is resolved;
- Chain: after the currently committed swap and any already-triggered clear/gravity/refill/cascade reach a stable board.

Until that boundary, no new player puzzle input is accepted for the outgoing workspace.

When the boundary is reached:

1. commit puzzle rewards/telemetry exactly once;
2. snapshot the outgoing workspace;
3. freeze its puzzle simulation;
4. restore the incoming workspace exactly;
5. give input authority to the incoming workspace.

This small deterministic handoff is not a tactical pause: enemy combat time continues while the handoff finishes.

### 5.2 No switch exploit

Switching must not:

- reset gravity or lock delay;
- reroll Hold/Next/refill/randomizer state;
- cancel an already-earned Board Break;
- duplicate a clear/cascade reward;
- erase an unfavorable active piece or Chain selection without preserving its legal state;
- pause the enemy clock;
- create free Energy or Stock.

## 6. Enemy real-time scheduler and Telegraph

The enemy acts on a continuous authored combat schedule while `COMBAT_RUNNING`.

The player must be able to read **what is coming and when** without leaving the puzzle surface.

Minimum combat information:

- current enemy action identity/category;
- expected result or damage/resource effect;
- current action ETA/countdown when the action is time-scheduled;
- lower-priority Next Forecast when authored/known;
- enemy HP/phase/state.

The enemy cannot secretly swap the current telegraphed action in direct reaction to the player's current board state or selected counter unless a later explicit encounter rule defines a visible reactive enemy archetype.

### 6.1 Same-frame pause/action boundary

If Skill-open input and an enemy action deadline occur on the same simulation frame, ordering must be deterministic.

Recommended authority:

1. process player Skill-open input at the beginning of the input frame;
2. if tactical pause is successfully entered before the enemy action has committed, simulation freezes and the enemy action waits;
3. once an enemy action has crossed its explicit commit point, opening Skill cannot retroactively cancel that action.

The commit point must be visible/testable in the enemy scheduler rather than inferred from animation timing.

## 7. Skill workspace

Skill is a tactical decision surface, not an ordered `ACTION_PHASE`.

### 7.1 Entry

- player may open Skill during `COMBAT_RUNNING` whenever system rules permit;
- opening Skill fully pauses simulation;
- active Line/Chain workspace remains visually present as frozen context but receives no input;
- the right-side Combat/Technique region becomes the primary interaction surface.

### 7.2 Selection flow

Current first-Slice interaction remains:

```text
ATK / DEF / SUP category
→ selected category's T1–T6 Techniques
→ select Technique
→ inspect detail / cost / condition / target
→ explicit USE confirm
```

Selecting a Technique row does not spend resources or resume combat.

Only `USE` commits the action.

### 7.3 Exit

After Technique resolution/commit:

- deduct configured Energy and Chain Stock atomically;
- apply Technique effect according to data-driven effect primitives;
- close Skill workspace unless the Technique explicitly owns another short resolution state;
- resume `COMBAT_RUNNING` at the exact paused simulation time;
- restore the previously active puzzle workspace and its unchanged state.

Canceling Skill resumes combat without spending resources.

### 7.4 Pause abuse is not a blocker

Because manual Pause is already allowed, using Skill entry to think is not treated as a competitive exploit in the first Slice.

However, Skill pause may not be used to manipulate simulation progression: no cooldown ticks, puzzle progress, enemy timer progress, passive resource gain, or hidden animation-time resolution occurs while paused.

## 8. Resource and Tier contract under real-time combat

The dual-resource identity remains:

- **Energy**: primarily earned in Line;
- **Chain Stock**: primarily earned from Chain/Combo performance;
- Tier N Technique currently spends N Stock plus Technique-specific Energy under `TETRIS-BALANCE-027`, unless later tuning changes the economy contract.

What changes is the opportunity-cost question.

Old question:

> How much shared turn time should I allocate before this turn ends?

New question:

> While the enemy clock keeps moving, how long can I safely stay in Line or Chain before I should pause and spend resources?

Exact Energy gain, Chain→Stock mapping, cooldowns, enemy cadence, and effect magnitudes remain `TUNE_REQUIRED` and require runtime/human evidence.

## 9. Skill matrix migration

Most `TETRIS-SKILL-026` identity remains reusable, but turn-bound semantics must be migrated.

### Retain

- ATK / DEF / SUP lanes;
- Tier 1–6 commitment grammar;
- lower-Tier situational viability / anti-dominance goal;
- direct damage, mitigation, counter, heal, resource ward, setup/debuff primitive families;
- current-vs-next Telegraph tactical distinction where a visible Next Forecast exists.

### Must be redesigned before BUILD

- `Haste = add seconds to next Shared Player Turn Budget`;
- `Battle Trance = next-turn Line/Chain preparation window`;
- any status duration expressed only as `turn` boundaries;
- Tempo-scalable potency and Tempo eligibility;
- `current turn Enemy Resolve` wording for wards/counters.

These are not silently ported to real-time seconds. Each needs a separate bounded real-time semantic decision before implementation.

## 10. Balance migration

`TETRIS-BALANCE-027` keeps the structural dual-resource opportunity cost but loses turn-specific teaching and telemetry assumptions.

### Retain

- Energy and Chain Stock are not interchangeable;
- Stock cap 6 baseline;
- Tier N → Stock N baseline;
- lower-Tier efficiency vs higher-Tier specialization/commitment;
- anti-hoarding pressure from Stock cap and enemy resource threats;
- automated simulation cannot claim fun/readability/final balance.

### Replace

- `first tutorial turn`, `early/mid/climax turn exposure` with continuous encounter milestones;
- per-turn start/after-Line/after-Chain telemetry with timestamped resource events and workspace residency windows;
- timeout/PASS/Tempo metrics with real-time threat-response and mode-switch metrics.

## 11. UI / UX contract

### 11.1 Primary 60/40 composition

Target desktop battle composition:

- **Left ≈ 60%: one large Puzzle Surface**;
- **Right ≈ 40%: persistent Combat Stage + enemy threat + resources + Skill surface**.

This is a compositional target, not a fixed pixel law. 1280×720 readability testing may adjust the exact ratio, but the large single puzzle surface must remain dominant.

### 11.2 Puzzle surface

The same outer region changes mode:

```text
LINE selected  → large falling-block board
CHAIN selected → large Swap-Match board
```

The inactive board is not shown as a mandatory sidecar.

A small mode label/resource summary is allowed if needed, but it must not recreate two simultaneous full puzzle surfaces.

### 11.3 Persistent right-side combat surface

At minimum keep readable during puzzle play:

- Vanguard/enemy combat stage or compact character/boss representation;
- enemy HP/phase;
- Current Telegraph + ETA;
- lower-priority Next Forecast when known;
- player HP / Energy / Chain Stock;
- mode controls `LINE / CHAIN / SKILL`.

### 11.4 Skill-open state

When Skill is opened:

- combat visibly indicates **TACTICAL PAUSE**;
- left Puzzle Surface remains frozen and readable;
- right-side interaction expands/prioritizes `ATK / DEF / SUP → T1–T6 → detail → USE`;
- the player can still see the current enemy threat that motivated the decision;
- no obsolete `LINE / CHAIN / ACTION phase` or Shared Turn Timer is shown.

### 11.5 Remove from current production UI

- mandatory Compact Sidecar for the inactive puzzle;
- ordered `LINE → CHAIN → ACTION → ENEMY` stage rail;
- Shared Player Turn Timer;
- READY-as-stage-advance;
- PASS/timeout turn UI;
- Tempo provisional reward UI.

## 12. Runtime architecture

Recommended responsibility split:

### `ProductionCombatRuntime`

Owns encounter lifecycle, global simulation state, Victory/Defeat, and connections between enemy/puzzle/skill subsystems. It does not own puzzle rules.

### `SimulationPauseController`

Owns pause reasons and effective simulation state.

Suggested reasons:

```text
TACTICAL_SKILL
SYSTEM_MENU
RUNTIME_TRANSITION
```

Pause reasons are reference-counted or tokenized so one subsystem cannot accidentally resume simulation while another pause reason still exists.

### `PuzzleWorkspaceManager`

Owns:

- current workspace id `LINE | CHAIN`;
- persistent workspace references/state;
- switch request;
- deterministic safe-boundary handoff;
- input authority.

It does not own Energy/Stock economy formulas.

### `EnemyActionScheduler`

Owns:

- current authored action;
- ETA/commit point;
- next forecast;
- pause-aware advancement;
- deterministic action resolution request.

### `ProductionResourceState`

Owns HP/Energy/Stock and atomic gain/spend events.

### `TechniqueSession`

Owns Skill browsing/selection/eligibility/detail/confirm state. It does not advance combat time.

### `TechniqueResolver`

Owns atomic spend + effect execution after explicit confirm.

### UI presenter/view

Reads the above states and exposes the 60/40 composition without becoming gameplay authority.

## 13. Event flow

Example real-time sequence:

```text
COMBAT_RUNNING / LINE
→ enemy ETA = 6.0 s
→ player clears Line → Energy committed
→ player requests CHAIN
→ Line reaches safe boundary, freezes
→ CHAIN restored, enemy ETA keeps decreasing
→ Chain cascade resolves → Stock committed
→ enemy ETA = 2.1 s
→ player opens SKILL
→ full simulation pause
→ DEF → T5 Rift Ward inspected
→ USE
→ costs/effect commit atomically
→ simulation resumes at the exact paused time
→ enemy scheduler continues toward its action
```

## 14. Board Break

Board Break remains puzzle-local failure with combat consequence.

- detect at deterministic puzzle boundary;
- apply configured HP/resource consequence atomically;
- reset only the failed workspace according to its puzzle contract;
- preserve the other workspace state;
- enemy real-time scheduler continues unless the game entered Skill/System pause or encounter terminal state;
- Board Break does not create a hidden turn boundary.

Exact failure penalties remain `TUNE_REQUIRED` if not already locked by another retained canon.

## 15. Benchmark absorption

### FINAL FANTASY VII REMAKE / REBIRTH — ADAPT

Official Square Enix material describes real-time combat where opening the command menu enters Tactical/Wait mode and slows time so the player can make strategic command decisions.

Adopt:

- real-time pressure can coexist with a cognitively safer command-selection layer;
- the decision UI should appear at the moment the player needs tactical control rather than forcing constant menu navigation.

Change for Tetris project:

- Skill selection uses a **full stop**, not merely slow motion;
- resources come from Line/Chain puzzle performance, not ATB;
- no party-command system is imported.

References:
- https://www.jp.square-enix.com/ffvii_remake/system/index.html
- https://www.square-enix.com/ffvii/en-us/games/rebirth/battle/

### Transistor Turn() — PRINCIPLE ONLY

Transistor demonstrates a strong readability contrast between real-time danger and a frozen tactical planning state.

Adopt:

- full time-stop can make a hybrid real-time system tactically legible;
- pause state needs an unmistakable visual language.

Reject:

- action queue/planning bar;
- Turn() recharge loop;
- movement-path planning.

### Tetris real-time falling-block principle — RETAIN WITH RIGHTS BOUNDARY

Official Tetris material describes rotating/moving/dropping falling Tetriminos in real time inside the Matrix.

Adopt only the gameplay readability principle required by the current Line prototype: real-time falling-block manipulation should remain responsive and legible.

The Tetris name, logos, Tetriminos, and trade dress are protected. Internal project naming does not grant commercial-use rights. Public/product branding requires a separate rights/name decision.

Reference:
- https://www.tetris.com/about

## 16. Five-pass adversarial review

### Loop 1 — mode-switch reset exploit

Attack: rapid `LINE ↔ CHAIN` switching could reset gravity, active piece, refill, selection, or reward state.

Correction: persistent workspace identity + safe-boundary handoff + no-reset invariant.

### Loop 2 — tactical pause hidden progression exploit

Attack: enemy timer/cooldown/status/puzzle could continue invisibly while the player reads Skill UI.

Correction: one authoritative `SimulationPauseController`; Skill/UI input only while paused; telemetry separates pause from active time.

### Loop 3 — Chain cascade handoff nondeterminism

Attack: switching during cascade could duplicate rewards, abandon an unstable board, or produce replay divergence.

Correction: switch request accepted, but handoff commits only after already-triggered cascade reaches stable state while enemy time continues.

### Loop 4 — 60/40 composition hides the real threat

Attack: a large puzzle board may tunnel player attention and make enemy Telegraph unreadable.

Correction: right-side Combat surface remains persistent; Current Telegraph/ETA and HP/resources stay readable during both puzzle modes; Skill pause preserves the threat context.

### Loop 5 — full pause trivializes pressure or becomes a fake resource

Attack: unlimited Skill pause removes reflex pressure and may be used as a free thinking pause.

Decision: this is intentional. The game's difficulty is supposed to come from real-time puzzle attention allocation and resource preparation, not from forcing tooltip reading under damage. Manual Pause is already allowed. The hard boundary is that **simulation makes zero progress while paused**.

Result after corrections: **NO NEW P0 ARCHITECTURAL BLOCKER** for the approved direction. Runtime/balance/human validation remain unverified.

## 17. Migration impact

### Existing default-main structured canon

Until this design is reviewed and promoted, default `main` still truthfully contains `CORE-024/TIME-025`. Do not pretend `main` already implements or routes to CORE-029.

After spec approval, the structured-canon migration should:

1. create/promote a current real-time production combat canon for `TETRIS-CORE-029`;
2. mark `PRODUCTION_TURN_COMBAT_CANON.md` and `PRODUCTION_TURN_TIME_CANON.md` as `HISTORICAL / SUPERSEDED BY CORE-029` rather than deleting historical reasoning;
3. update `AGENTS.md` canon order and terminology;
4. update `PRODUCTION_CANON_INDEX.json` current routing;
5. adapt `TETRIS-SKILL-026` turn/time-specific clauses;
6. adapt `TETRIS-BALANCE-027` turn-specific teaching/telemetry clauses;
7. sync Notion Home / Flow / Core System / Gatebreaker Encounter / Visual-P0 consumer descriptions;
8. only then write the new implementation plan.

### Draft PR #19

PR #19 is an open Draft workstream built around `CORE-024/TIME-025` and is **READ_ONLY in this design task**.

Do not merge its ordered-turn controller/shared-budget/Tempo architecture into the new current design merely because the branch contains substantial implementation.

Reusable components should later be harvested by explicit comparison, likely including puzzle engines, board/randomizer logic, resource/skill primitives, UI components, and deterministic tests that are independent of the ordered-turn controller.

The new implementation plan must classify PR #19 files as:

```text
REUSE_AS_IS
ADAPT
SUPERSEDED
HISTORICAL_EVIDENCE_ONLY
```

before any code migration.

## 18. Implementation Reality Gate

Current evidence at design time:

```text
TETRIS-CORE-029 user direction: USER_APPROVED
Written design spec: PRESENT / USER REVIEW REQUIRED
Default-main structured canon migration: NOT_DONE
Production runtime for CORE-029: NOT_PRESENT
PR #19 ordered-turn runtime: PRESENT ON DRAFT BRANCH / SEMANTICALLY SUPERSEDED FOR CORE FLOW
Godot local runtime validation for CORE-029: NOT_RUN
Human usability: NOT_RUN
Player experience / fun / balance: NOT_RUN
```

Do not claim the real-time design is implemented, playable, balanced, readable, or fun until corresponding evidence exists.

## 19. Acceptance criteria for the later Vertical Slice

The implementation is not considered CORE-029-compliant unless all are demonstrated:

1. encounter time advances continuously from start to Victory/Defeat while not paused;
2. enemy action schedule advances while the player uses Line or Chain;
3. player can request `LINE ↔ CHAIN` switching without a turn/stage gate;
4. returning to either workspace restores its exact legal persistent state;
5. switching cannot reset/duplicate puzzle state or rewards;
6. Line remains the Energy source and Chain remains the Chain Stock/Tier source;
7. opening Skill fully stops simulation and leaves only Skill/UI input active;
8. canceled Skill resumes the exact paused simulation state with no resource spend;
9. confirmed Skill spends resources/effects atomically and resumes combat deterministically;
10. manual Pause fully stops simulation independently of Skill pause;
11. Current enemy Telegraph/ETA remains readable during both puzzle modes;
12. desktop UI is approximately `60% large single Puzzle Surface / 40% persistent Combat surface` and does not require a second full board sidecar;
13. old Shared Turn Budget / READY / ordered Phase / Tempo semantics are absent from the current runtime path;
14. deterministic tests cover safe switching, pause ownership, same-frame enemy commit boundary, resource commits, and workspace restoration;
15. actual human test confirms the player understands `switch workspace vs pause-and-spend Skill` without relying on old phase terminology.
