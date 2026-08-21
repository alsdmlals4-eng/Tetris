# Shared Turn Budget + Tempo Reward Design

- Status: **USER_APPROVED DESIGN / BUILD DEFERRED**
- Decision: `TETRIS-TIME-025 · Shared Player Turn Budget + Tempo Reward`
- Date: 2026-08-21
- Repository: `alsdmlals4-eng/Tetris`
- Parent turn canon: `TETRIS-CORE-024`

## 1. Problem

`TETRIS-CORE-024` established the readable turn order `Enemy Telegraph → Line → Chain → Action → Enemy Resolve`, but its first timing seed gave Line, Chain, and Action separate independent maximum timers. The approved direction changes that timing model.

The player now receives **one total player-turn time budget** covering Line/Tetris play, Swap-Match Chain play, and Action selection. The player decides how much of that shared budget to invest in each stage and may declare readiness early. Completing the turn efficiently earns an additional reward.

This design must also support difficulty selection, items/equipment, Support skills such as Haste, and status effects such as Slow without creating bonus-farming exploits or mid-phase timer jumps.

## 2. Goals

1. Make time allocation itself a strategic resource across Line, Chain, and Action.
2. Preserve the readable ordered turn structure from `TETRIS-CORE-024`.
3. Reward decisive, skillful early completion without making immediate skipping optimal.
4. Allow difficulty/items/skills/statuses to modify the playable time budget through one data-driven pipeline.
5. Keep animation/settle duration from stealing player decision time.
6. Prevent positive time extensions from directly generating free Tempo rewards.
7. Keep the first production implementation small, deterministic, testable, and telemetry-friendly.

## 3. Non-goals

- No return to a continuously advancing enemy Combat Clock.
- No simultaneous Line/Chain play.
- No tactical RUN/LOCK mechanic.
- No phase-specific hard timer reset in the current baseline.
- No permanent/meta-currency economy for Tempo in the first implementation.
- No final lock of exact seconds, reward percentages, or difficulty values before runtime/human evidence.

## 4. Chosen model

### Considered alternatives

#### A. Independent phase timers

Line, Chain, and Action each receive a separate maximum.

- Good: simple phase tuning.
- Bad: time cannot be traded between phases, and fast execution in one phase has little strategic meaning.
- Decision: **SUPERSEDED by TETRIS-TIME-025**.

#### B. Shared player-turn budget — adopted

One active-input clock spans Line → Chain → Action.

- Good: creates meaningful allocation tradeoffs.
- Good: early completion can be rewarded cleanly.
- Good: one modifier pipeline handles difficulty/Haste/Slow/items.
- Risk: player can greed too long in Line or Chain and lose later input time.
- Correction: clear shared-clock UI, explicit READY controls, warnings, deterministic timeout fallback.
- Decision: **ADOPT**.

#### C. Untimed / Action-Point baseline

- Good: maximum accessibility and planning clarity.
- Bad: removes the intended time-pressure skill axis from the baseline combat identity.
- Decision: **REFERENCE / ACCESSIBILITY REVISIT**, not the baseline.

## 5. Turn-time authority

The combat sequence remains:

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
```

`TETRIS-TIME-025` changes only the timing ownership across the three player-facing input phases.

### Shared clock lifecycle

1. Enemy Telegraph is shown with the shared clock not consuming time.
2. The effective player-turn budget is snapshotted before Line begins.
3. The shared clock starts when Line receives player input authority.
4. `READY` may end Line at a legal stable boundary; remaining budget carries immediately into Chain.
5. Forced `LINE_SETTLE` does not consume the player budget.
6. `READY` may end Chain at a legal stable boundary; remaining budget carries into Action.
7. Forced `CHAIN_SETTLE` does not consume the player budget.
8. Action selection consumes the same remaining budget.
9. Confirming a legal Action ends player-turn timing immediately and freezes the remaining amount for Tempo calculation.
10. Enemy Resolve, turn transitions, and forced non-interactive animation do not consume player budget.

The budget is therefore **active player decision/input time**, not wall-clock animation time.

## 6. Early completion

The player may end each interactive stage before the shared budget is exhausted:

- Line: `READY` when the board is at a legal stable boundary.
- Chain: `READY` only when the board is stable and no swap/cascade resolution is pending.
- Action: selecting and confirming a legal action ends the player turn immediately.

Unused shared time is **not banked into a future turn**. It becomes an input to the current turn's Tempo evaluation only.

Skipping quickly is always legal when the state machine permits it, but skipping is not automatically reward-eligible.

## 7. Timeout behavior

When the shared player-turn budget reaches zero:

### Timeout during Line

1. Reject new Line input.
2. Finish only the already-committed atomic Line operation.
3. Complete `LINE_SETTLE` without consuming additional player budget.
4. Remaining Chain input is skipped because no player budget remains.
5. No Action selection time remains; resolve deterministic `PASS`.
6. Continue to Enemy Resolve.

### Timeout during Chain

1. Reject new swaps.
2. Finish the already-triggered clear/gravity/refill/cascade to a stable board.
3. Complete `CHAIN_SETTLE` without consuming additional player budget.
4. No Action selection time remains; resolve deterministic `PASS`.
5. Continue to Enemy Resolve.

### Timeout during Action

- Resolve `PASS` and continue to Enemy Resolve.

This makes over-investing in an early puzzle a real risk while guaranteeing the state machine cannot deadlock.

## 8. Time-modifier pipeline

All playable-time changes flow through one turn-budget calculator.

### Sources

- player-selected difficulty profile;
- passive item/equipment modifiers;
- consumable or encounter item effects;
- Support effects such as Haste;
- status effects such as Slow;
- explicit encounter modifiers.

### Snapshot rule

The effective budget is calculated once at `TURN_START`, after all effects that should apply to that turn are known and before Line input begins.

Once snapshotted, the current turn's effective budget does not jump up or down mid-phase. Effects created during the current turn normally apply to the **next eligible turn** unless a future approved effect explicitly declares otherwise.

This prevents a visible countdown from suddenly losing seconds and keeps deterministic replay simple.

### Initial calculation shape

The first implementation should support data-driven flat-second modifiers and stacking groups:

```text
effective_budget_seconds = clamp(
    difficulty_base_budget_seconds
    + sum(active_flat_second_modifiers),
    configured_min_budget_seconds,
    configured_max_budget_seconds
)
```

Do not add percentage stacking until a real content need exists.

### Stacking

- Different stacking groups may coexist.
- Reapplying the same default Haste/Slow group refreshes or replaces according to its effect definition rather than automatically multiplying the value.
- Only explicitly `STACKABLE` effects may accumulate multiple instances.
- The exact source list and final effective budget are exposed to telemetry and inspectable UI.

## 9. Difficulty

Difficulty may change the **available player-turn budget**, but difficulty must not be implemented as hidden dynamic punishment.

Initial candidates may be explored around the old aggregate 90-second ceiling, for example shorter on harder profiles and longer on easier profiles. These numbers remain test seeds rather than final balance canon.

Difficulty selection should normally be locked for the current battle/run boundary so the player cannot toggle difficulty inside a turn to manipulate time or rewards.

Difficulty may have its own broader encounter reward multiplier, but that is separate from Tempo calculation.

## 10. Tempo Bonus

### Purpose

Tempo Bonus rewards completing a meaningful turn faster than the standard performance reference. It is an immediate combat-performance reward, not a permanent currency in the first Slice.

### Two-clock rule

The game tracks two different concepts:

1. **Effective Budget** — how much active player time is actually available after difficulty/items/Haste/Slow.
2. **Tempo Reference** — the standard unmodified performance reference used to judge speed.

Positive or negative time modifiers **do not change the Tempo Reference**.

This prevents an item or Haste effect from granting free bonus merely because it increased the maximum clock, and prevents Slow from lowering the standard used to judge skilled completion.

### Saved-time ratio

At legal Action confirmation:

```text
tempo_saved_ratio = clamp(
    (tempo_reference_seconds - active_player_time_used_seconds)
    / tempo_reference_seconds,
    0.0,
    1.0
)
```

The reward curve is data-driven. A conservative first Slice seed may use a small dead zone followed by a capped linear reward; exact breakpoints and caps are tuning data, not locked canon.

### First reward target

For the first production implementation, Tempo Bonus modifies the **potency of the selected Attack / Defense / Support action** for the current turn and also records a non-currency Tempo score for telemetry/result presentation.

Do not initially convert Tempo directly into persistent Energy, Chain Stock, or meta-currency; doing so would create compounding snowball and farming pressure before the core loop is validated.

## 11. Tempo eligibility / anti-exploit gates

A turn earns no Tempo Bonus unless all baseline conditions are met:

1. At least one committed Line performance event was produced during the turn.
2. At least one committed Chain reward/performance event was produced during the turn.
3. The player confirms a legal non-PASS Action.
4. The turn did not use a timeout fallback.
5. First Slice seed: a Board Break during the turn disables Tempo eligibility for that turn.

These gates prevent `READY → READY → minimal action` or deliberate Board Break from becoming the fastest reward strategy.

The gates do **not** require a specific Tier. Low-Tier fast tactical play must remain capable of earning Tempo.

## 12. Haste, Slow, items, and status effects

### Haste

Default Support interpretation:

- adds configured seconds to the next eligible player-turn budget;
- does not change Tempo Reference;
- follows stacking-group rules;
- is visible before the affected turn begins.

### Slow

Default status interpretation:

- removes configured seconds from the next eligible player-turn budget;
- cannot reduce below configured minimum;
- does not change Tempo Reference;
- is visible in the enemy telegraph/status preview before the affected Line begins.

### Items/equipment

Items may provide persistent or conditional flat-second modifiers. Their source and value must be inspectable rather than hidden.

This architecture allows future classes/items to interact with time without giving UI code ownership of the timer.

## 13. UI / UX

Persistent priority during player phases:

1. current enemy telegraph;
2. **one shared remaining player-turn timer**;
3. current phase label: LINE / CHAIN / ACTION;
4. active puzzle/action surface;
5. HP / Energy / Chain Stock;
6. current Tempo eligibility and provisional bonus if the turn were confirmed now;
7. next enemy forecast when known.

### Required feedback

- `READY` is explicit during Line and Chain.
- Shared timer never visually resets between Line, Chain, and Action.
- Settle animations show `RESOLVING` while the shared budget is paused.
- Low-time warnings are based on the one shared budget.
- If Tempo is ineligible, the UI shows the reason compactly rather than showing a misleading positive bonus.
- Haste/Slow preview shows the next turn budget delta before it becomes active.

## 14. Board Break interaction

Board Break still follows the owning puzzle's deterministic reset contract.

- Forced Board Break handling does not consume shared player time.
- If shared budget remains after the board is stable, the player resumes the same phase.
- If no budget remains, normal timeout flow continues.
- First Slice: any Board Break disables Tempo eligibility for the current turn.

## 15. Telemetry

Record per turn at minimum:

- difficulty profile;
- base budget;
- all time-modifier sources and stacking groups;
- effective budget;
- Tempo Reference;
- active Line time used;
- Line READY vs timeout;
- Line performance qualification;
- Line settle duration separately from active time;
- active Chain time used;
- Chain READY vs timeout;
- Chain performance qualification;
- Chain settle duration separately from active time;
- active Action decision time;
- selected lane/tier or PASS;
- timeout phase if any;
- Board Break flag;
- total active player time used;
- remaining effective budget at confirmation;
- tempo_saved_ratio;
- Tempo eligibility plus failure reason;
- Tempo potency bonus actually applied;
- player/enemy action results.

## 16. Acceptance criteria

Timing implementation is not complete until automated/runtime evidence shows:

1. One shared budget spans Line, Chain, and Action without reset.
2. READY in Line preserves remaining budget into Chain.
3. READY in Chain preserves remaining budget into Action.
4. Settle/forced animation time does not reduce the shared budget.
5. System Pause does not reduce the shared budget.
6. Timeout in Line or Chain settles deterministically and reaches PASS without deadlock.
7. Action confirmation freezes remaining time before player action resolution.
8. Difficulty/items/Haste/Slow alter Effective Budget through the same calculator.
9. Same-turn mid-phase effects do not mutate an already snapshotted budget unless a future explicit exception is introduced.
10. Modifier changes do not change Tempo Reference.
11. A time-extension effect alone cannot increase Tempo Bonus for identical active completion time.
12. Skipping required Line/Chain performance or using PASS earns no Tempo Bonus.
13. Board Break disables Tempo in the first Slice.
14. Eligible faster completion produces a monotonically non-decreasing Tempo reward up to its configured cap.
15. Existing Foundation tests remain labeled as historical evidence and are not reported as proof of the new timing runtime.

## 17. Benchmark notes

- Puzzle Quest 3 used a timed move window whose available time increased with the hero's Speed stat, showing a practical precedent for build stats modifying puzzle execution time.
- Puzzle Quest 3 later made Action Points the default for new players to reduce timer pressure; this is a warning that time pressure must remain readable and accessibility-aware.
- Puzzle & Dragons exposes Orb Move Time extension through player-build systems, supporting the broader pattern that puzzle execution time can be a transparent build variable.

These are references, not copied rule sets. Tetris keeps its own sequential two-puzzle + Action grammar and uses the shared-budget/Tempo structure defined here.

## 18. Revisit triggers

Re-evaluate this design if human evidence shows any of the following:

- players routinely spend nearly all time in Line and never meaningfully use Chain;
- players rush minimum qualifying events solely to farm Tempo;
- Tempo potency becomes more important than puzzle resource preparation;
- easier difficulty becomes the optimal reward-farming mode;
- Haste becomes mandatory because it both improves safety and indirectly dominates output;
- timeout PASS occurs frequently despite players understanding the UI;
- settle/animation treatment makes the displayed timer feel inconsistent;
- one shared budget produces worse readability than asymmetric sub-budgets with carryover.

## 19. Implementation Reality Gate

At approval time:

- `TETRIS-TIME-025`: **DOCUMENTED / USER_APPROVED DESIGN**.
- Shared production Turn Budget runtime: **NOT_PRESENT**.
- Time Modifier calculator runtime: **NOT_PRESENT**.
- Tempo Bonus runtime: **NOT_PRESENT**.
- Haste/Slow production runtime: **NOT_PRESENT**.
- Human timing/Tempo playtest: **NOT_RUN**.

Do not claim implementation or balance validation from this document alone.
