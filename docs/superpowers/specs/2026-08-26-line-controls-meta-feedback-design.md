# LINE Controls, Queue Visibility, and Advanced-Clear Feedback Design

- Status: **USER_APPROVED DESIGN / IMPLEMENTATION PENDING**
- Date: 2026-08-26
- Scope: CORE-029 Draft PR #24 follow-on vertical slice only
- Authority: latest user request, `PRODUCTION_REALTIME_COMBAT_CANON.md`, actual LINE runtime

## Goal and player experience

The LINE workspace should be immediately playable by either the existing letter-key layout or familiar arrow keys.  While solving, the player can read the legal controls, see the held tetromino and upcoming queue, and understand when a higher-skill clear has occurred.

The target feedback loop is:

```text
read controls and queue → place/hold/rotate confidently → clear line
→ see the recognized technique immediately → make the next placement decision
```

## Confirmed existing foundation

- Named LINE actions already route through `ProductionBattle`; no raw-key handling is required.
- `LinePieceCycle` already owns `held_piece_id`, `peek_next(5)`, seven-bag progression, Hold availability, and SRS-compatible rotation.
- `LineClearResult` already carries `spin_kind`, `combo_index`, `back_to_back`, and `perfect_clear` without changing its base reward fields.
- Existing tests establish T-Spin recognition, Combo, Back-to-Back, and Perfect Clear semantics.

The missing work is therefore input aliases and player-facing presentation, not a second set of LINE rules.

## Alternatives considered

| Alternative | Benefit | Cost / risk | Decision |
| --- | --- | --- | --- |
| A. Extend the current left LINE surface with a compact meta rail | Reuses authoritative state, keeps a 60/40 combat layout, and exposes the existing advanced rules quickly | Requires careful 960×540 layout validation | **Adopt** |
| B. Add a standalone side-panel scene beside the board | Strong component isolation | Shrinks the already narrow 60% puzzle surface and adds scene/layout ownership churn | Adapt only if the compact rail proves unreadable |
| C. Add a full guideline mechanics/balance package at once | Broad feature list | Changes lock timing, scoring, tuning, and test scope; high risk and not required to make the current mechanics usable | Reject for this slice |

## Approved interaction contract

### Input aliases

All handling continues to use the existing named InputMap actions.

| Action | Existing binding | Added binding |
| --- | --- | --- |
| Move left | `A` | `Left` |
| Move right | `D` | `Right` |
| Soft drop | `S` | `Down` |
| Clockwise rotation | `X` | `Up` |
| Counter-clockwise rotation | `Z` | unchanged |
| Hold | `C` | unchanged |
| Hard drop | `Space` | unchanged |

Arrow input is an alias, not a new action or a replacement for the existing controls.  It remains disabled whenever LINE is inactive or the simulation is paused, exactly as current named actions are.

### Left LINE meta rail

When LINE is active, the Puzzle Surface contains a compact, read-only left-side rail:

- a visual key guide: `←/A`, `→/D`, `↓/S`, `↑/X`, `Z`, `C`, `Space`;
- `HOLD`: the held tetromino, plus an unavailable treatment after the active piece has already used Hold;
- `NEXT`: five upcoming tetrominoes in exact queue order;
- `LAST CLEAR`: the most recent clear/technique result.

The board remains the visual priority.  The rail must disappear with the LINE surface when CHAIN is selected and must not accept gameplay input.

### Advanced technique feedback

No new recognition or reward balance is introduced.  The UI translates existing `LineClearResult` fields into a concise ordered label:

1. `PERFECT CLEAR`, when set;
2. `T-SPIN` plus clear kind, when `spin_kind == T_SPIN`;
3. ordinary `SINGLE` / `DOUBLE` / `TRIPLE` / `TETRIS` (four lines), when lines clear;
4. optional suffixes `B2B` and `COMBO ×N`, only when the existing result fields qualify.

For a placement with no cleared line and no recognized technique, no celebratory label is fabricated.  The previous confirmed result remains readable until superseded by the next committed placement.

## Scope boundary

In scope:

- Arrow-key aliases and their InputMap tests.
- LINE-only control guide, Hold, Next-five, and last-clear presentation.
- Read-only display of current canonical advanced-clear recognition.
- Godot runtime and automated validation at the supported desktop surface.

Out of scope:

- New images, audio, score/energy/Stock tuning, combat damage changes, or CHAIN changes.
- New advanced mechanics such as DAS/ARR tuning, new lock-reset rules, ghost changes, T-Spin mini scoring, replay, or competitive guideline compliance.
- Any alteration to PR #19 or historical turn-based implementation.

## Acceptance criteria

1. Each named movement action has its current letter key plus the specified arrow-key alias where defined.
2. Arrow inputs produce the same LINE session commands as their corresponding existing named action, only while LINE is active and simulation is running.
3. The active LINE UI visibly names every supported control and displays the actual held piece, hold availability, and the next five pieces in exact `LinePieceCycle` order.
4. After a committed line result, the UI renders the current T-Spin / line clear / B2B / combo / Perfect Clear facts without inventing a bonus or changing rewards.
5. CHAIN remains the single visible puzzle surface when selected; the LINE rail has no stale visible/input surface.
6. Relevant GUT tests, headless Godot parse/import, and direct Godot runtime inspection pass without new task-related errors or clipping at 960×540.

## Verification plan

- RED tests first for input aliases, meta-rail state mapping, and advanced-result label formatting.
- GREEN implementation using the existing `LinePieceCycle` and `LineClearResult` as the only state sources.
- Full existing GUT suite plus production UI/LINE focused tests.
- Headless editor parse/import.
- Direct Godot run: confirm arrow movement/rotation/drop, Hold and Next update, advanced label injection, LINE↔CHAIN visibility, and no runtime errors.
- Push only task-owned files, then require exact-head GitHub CI and an independent code/spec review before reporting completion.

## Risks and rollback

- Compact information may make the 960×540 LINE board too narrow.  Mitigation: fixed compact rail, board-first layout, direct screenshot inspection.
- UI could drift from gameplay state.  Mitigation: presentation reads existing session/cycle/result state without duplicating queue or recognition logic.
- A future guideline-mechanics expansion could be confused with this slice.  Mitigation: preserve the explicit out-of-scope boundary and create a separate approved balance contract first.

Rollback is a revert of this slice's task-owned commits; core LINE mechanics, current data, and PR #19 remain untouched.
