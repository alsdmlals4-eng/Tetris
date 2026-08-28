# CHAIN Combo and MP Lock Contract

- Decision: `TETRIS-CHAIN-038`
- Status: `USER_APPROVED / PHASE 1 CANON / DOCUMENTED_NOT_IMPLEMENTED`
- Issue: #56
- Cost approval: fixed **1 MP** failed-swap lock, Issue #58
- Date: 2026-08-28
- Authority: latest user decision, `TETRIS-CORE-029`, `TETRIS-BALANCE-027`, and `PRODUCTION_CANON_INDEX.json`.
- Scope: player-facing resource language and CHAIN interaction grammar. This is not a Godot implementation, balance lock, runtime capture, or Human/player-experience result.

## 1. Resource ownership

The two-resource loop is intentionally cross-workspace:

```text
LINE / falling-block board → recover MP
CHAIN / Swap-Match board   → earn Combo
```

`MP` is the player-facing name for the current runtime field `energy`. `Combo` is the player-facing name for the current runtime field `stock` / historical `Chain Stock`. They are **not** a third resource and must not be treated as interchangeable.

- MP remains the flexible spendable resource. It is earned by LINE and may pay an optional CHAIN board-shaping choice as well as Technique costs.
- Combo remains the CHAIN-earned commitment resource that exposes/spends Tier opportunity under `TETRIS-BALANCE-027`.
- A player who spends MP to preserve a failed CHAIN swap receives no immediate Combo, clear, cascade, or Technique effect.

## 2. CHAIN match grammar

The player swaps exactly two orthogonally adjacent cells: left, right, up, or down. Diagonal **swaps** are not part of this rule.

A swap is a match when it creates a contiguous straight run of the same symbol with length three or more along at least one of these axes:

```text
HORIZONTAL         ( +1,  0)
VERTICAL           (  0, +1)
DIAGONAL_DOWN_RIGHT( +1, +1)
DIAGONAL_DOWN_LEFT ( -1, +1)
```

Connected blobs, L-shapes, or a merely adjacent pair are not matches. If runs overlap, the resolver records their individual axes but clears each affected cell once.

## 3. Swap outcomes

| Outcome | Board result | Reward / cost | Next state |
| --- | --- | --- | --- |
| A valid straight 3+ match | Keep the swap; clear → gravity/refill → cascade until stable. | Earn Combo only through the ordinary resolved CHAIN result; no MP payment. | Normal stable CHAIN board. |
| No valid match, player declines lock | Restore the exact pre-swap board. | No MP or Combo change. | Normal stable CHAIN board. |
| No valid match, player selects MP lock | Keep the swapped board in place. | Spend fixed **1 MP**; no immediate clear, cascade, or Combo. | Normal stable CHAIN board, ready for a later setup swap. |

`MP lock` is an optional response to an otherwise-invalid swap. It must not be offered for non-adjacent input, during an already-committed resolution, or as a way to keep an already-valid match from resolving.

## 4. Tuning and implementation boundary

- The failed-swap MP lock cost is fixed at **1 MP** for the vertical slice. MP cap, LINE-to-MP recovery values, and the Combo gain curve remain `TUNE_REQUIRED`; this decision deliberately does not invent those numbers.
- The UI must explain this rule with structured text/interaction feedback, not image-only labels: `No straight 3+ match — revert` and, when affordable, `Spend 1 MP to keep this swap for a later Combo`.
- Current merged runtime uses internal `energy` / `stock` names, only tests horizontal and vertical match runs, and always restores a non-match. It has no MP-lock path. Its alignment with this contract is therefore `PARTIAL_HV_ONLY_NO_MP_LOCK`.
- Phase 2 implementation must update the deterministic board/resolver/session/resource bridge, input feedback, configuration, telemetry, and regression tests together. It must not claim balance or Human/player validation before runtime evidence exists.

## 5. Tutorial and visual rule

The first-session tutorial teaches the readable base rule first: a straight horizontal, vertical, or diagonal run of three equal symbols earns Combo. A failed swap visibly reverts. MP lock is introduced as an optional planning tool, never as a required first-tutorial transaction.

Planning boards and visual references may illustrate the rule, but their images are not the source of truth. The exact rule belongs to this text contract and its linked repository/Notion decision records.
