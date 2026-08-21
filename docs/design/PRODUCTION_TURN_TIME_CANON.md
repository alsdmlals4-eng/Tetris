# Production Turn Time Canon

- Status: **CURRENT PRODUCTION TIMING CANON / USER_APPROVED**
- Decision: `TETRIS-TIME-025 · Shared Player Turn Budget + Tempo Reward`
- Date: 2026-08-21
- Parent combat decision: `TETRIS-CORE-024`
- Design detail: `docs/superpowers/specs/2026-08-21-shared-turn-budget-tempo-design.md`

## Authority

This document is the current production authority for player-turn timing, early completion, time modifiers, timeout fallback, and time-saved rewards.

Where `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` still describes independent Line / Chain / Action timers or discarded unused phase time, **this document supersedes those timing clauses only**. The ordered combat sequence and other `TETRIS-CORE-024` rules remain current.

## Shared player-turn budget

One shared active-input budget spans:

```text
LINE → CHAIN → ACTION
```

The budget does not reset between those stages.

- Enemy Telegraph consumes no player budget.
- Line and Chain `READY` advance early while preserving the remaining budget for the next player stage.
- Action confirmation ends player timing and freezes the remaining amount.
- `LINE_SETTLE`, `CHAIN_SETTLE`, forced animations/transitions, Enemy Resolve, and System Pause do not consume player budget.
- Unused time never banks into a future turn.

The first migration seed may preserve the former aggregate 90-second ceiling for comparison, but final total budget is **not locked**. Human evidence must compare shorter and/or difficulty-specific values.

## Timeout

If shared time reaches zero:

- in Line: stop new input → finish committed atomic Line work → settle → skip remaining Chain input → deterministic `PASS` → Enemy Resolve;
- in Chain: stop new swap → finish already-triggered cascade to stable → deterministic `PASS` → Enemy Resolve;
- in Action: deterministic `PASS` → Enemy Resolve.

No timeout path may deadlock or grant extra input time.

## Time modifier pipeline

The effective budget is snapshotted once before Line begins.

Sources may include:

- selected difficulty;
- items/equipment;
- Support effects such as Haste;
- statuses such as Slow;
- explicit encounter effects.

Initial calculation shape:

```text
effective_budget = clamp(
  difficulty_base_budget + sum(active_flat_second_modifiers),
  configured_min,
  configured_max
)
```

The first runtime uses flat-second modifiers plus explicit stacking groups. Percentage stacking is deferred until content demonstrates a need.

Effects created after the snapshot normally apply to the next eligible turn. The visible current-turn timer does not jump mid-phase.

## Tempo Bonus

Finishing a meaningful turn quickly earns **Tempo Bonus**.

Two clocks are intentionally separated:

1. **Effective Budget**: actual playable time after difficulty/items/Haste/Slow.
2. **Tempo Reference**: unmodified standard performance reference used to judge completion speed.

Time modifiers do **not** change Tempo Reference. This prevents extra-time effects from generating free speed reward.

At legal Action confirmation:

```text
tempo_saved_ratio = clamp(
  (tempo_reference_seconds - active_player_time_used_seconds)
  / tempo_reference_seconds,
  0.0,
  1.0
)
```

The reward curve is data-driven and capped. Exact numeric tuning is not final canon.

First production reward target:

- modest potency increase to the selected Attack / Defense / Support action for the current turn;
- non-currency Tempo score recorded for telemetry/result presentation.

Do not initially convert Tempo into persistent Energy, Chain Stock, or meta-currency.

## Tempo eligibility

Tempo Bonus requires all of:

- at least one committed Line performance event this turn;
- at least one committed Chain reward/performance event this turn;
- legal non-PASS Action confirmation;
- no timeout fallback;
- first-slice seed: no Board Break during the turn.

Low-Tier play remains eligible. The gate exists to prevent immediate skip/intentional failure reward farming, not to force a high Tier.

## Haste / Slow

Default behavior:

- **Haste** adds configured seconds to the next eligible shared turn budget.
- **Slow** removes configured seconds from the next eligible shared turn budget, clamped to the minimum.
- neither changes Tempo Reference;
- both are visible before the affected Line begins;
- repeated effects follow stacking-group definitions rather than unconditional additive stacking.

## Difficulty

Difficulty may change available shared turn time through explicit data. It does not silently alter the timer mid-turn.

The time-reward reference remains separated from available budget so a longer easy-mode clock does not automatically create a larger Tempo reward for the same active completion time. Any broader difficulty reward multiplier is a separate encounter/economy rule.

## UI contract

During player control, show:

1. current enemy telegraph;
2. one shared remaining timer;
3. current stage `LINE / CHAIN / ACTION`;
4. active puzzle/action surface;
5. HP / Energy / Chain Stock;
6. Tempo eligibility and provisional reward if confirmed now;
7. next enemy forecast when known.

The shared timer must not visually reset between Line, Chain, and Action. Forced settles show `RESOLVING` while the player budget is paused.

## Telemetry minimum

Record:

- base difficulty budget;
- modifier sources/stacking groups;
- effective budget;
- Tempo Reference;
- active time used in Line / Chain / Action separately;
- READY/timeout per stage;
- settle durations separately;
- total active time;
- remaining effective budget at confirmation;
- qualification events;
- PASS/timeout/Board Break;
- tempo_saved_ratio;
- Tempo eligibility reason;
- actual Tempo potency applied.

## Acceptance criteria

1. One shared budget spans Line, Chain, and Action without reset.
2. READY carries remaining time forward.
3. Forced settle/animation does not consume player budget.
4. System Pause does not consume player budget.
5. Timeout produces deterministic settle/skip/PASS behavior without deadlock.
6. Difficulty/items/Haste/Slow use one budget calculator.
7. Snapshot prevents ordinary mid-phase time jumps.
8. Time modifiers do not alter Tempo Reference.
9. Identical active completion time earns identical Tempo from the time formula even if an extra-time modifier enlarged Effective Budget.
10. Missing Line/Chain qualification, PASS, timeout, or first-slice Board Break prevents Tempo Bonus.
11. Eligible faster completion never yields less Tempo than slower eligible completion before the cap.
12. Historical Foundation tests remain evidence for their historical contract only.

## Implementation Reality Gate

- `TETRIS-TIME-025`: **DOCUMENTED / USER_APPROVED**.
- Shared player-turn budget runtime: **NOT_PRESENT**.
- Difficulty/time-modifier runtime: **NOT_PRESENT**.
- Tempo Bonus runtime: **NOT_PRESENT**.
- Haste/Slow production runtime: **NOT_PRESENT**.
- Human timing validation: **NOT_RUN**.

Do not promote documentation or historical POC tests into runtime PASS evidence.
