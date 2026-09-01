# CHAIN Combo and MP Lock Contract

- Decision: `TETRIS-CHAIN-038`
- Status: `USER_APPROVED / RUNTIME_IMPLEMENTED / MACHINE_VERIFIED / BALANCE_AND_HUMAN_EVIDENCE_NOT_RUN`
- Issue: #56
- Cost approval: fixed **1 MP** failed-swap lock, Issue #58
- MP-cap approval: hard cap of **60 MP**, Issue #60
- Combo / CHAIN MP recovery approval: Issue #64
- Date: 2026-08-28
- Authority: latest user decision, `TETRIS-CORE-029`, `TETRIS-BALANCE-040`, `TETRIS-SKILL-039`, and `PRODUCTION_CANON_INDEX.json`.
- Scope: player-facing resource language and CHAIN interaction grammar. The deterministic board, resolver, resource bridge and in-battle lock prompt are implemented and machine-verified. This remains neither a balance lock nor a target-device runtime capture or Human/player-experience result.

## 1. Resource ownership

The two-resource loop is intentionally cross-workspace:

```text
LINE / falling-block board → recover MP
CHAIN / Swap-Match board   → earn Combo
```

`MP` is the player-facing name for the current runtime field `energy`. `Combo` is the player-facing name for the current runtime field `stock` / historical `Chain Stock`. They are **not** a third resource and must not be treated as interchangeable.

- MP remains the flexible spendable resource. It is earned by LINE and may pay an optional CHAIN board-shaping choice as well as Technique costs.
- Combo is one shared CHAIN-earned resource: it resolves the selected ATK/DEF/SUP Stage under `TETRIS-SKILL-039` **and** its current unspent amount raises CHAIN MP recovery. It is not a hidden second streak counter.
- Combo has a hard cap of **10**. Spending Combo on a category-resolved Technique immediately lowers later CHAIN MP recovery; when MP is short, only surplus Combo may convert at 5 MP each to reach the highest feasible lower Stage. This is an intentional skill-only trade, not a general second MP faucet.
- A player who declines a no-match swap or spends MP to preserve that failed swap resets Combo to **0**. MP lock still gives no immediate clear, cascade, Combo, or Technique effect.

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
| A valid straight 3+ match | Keep the swap; clear → gravity/refill → cascade until stable. | Each resolved wave gives Combo +1, then its CHAIN MP recovery. No MP payment. | Normal stable CHAIN board. |
| No valid match, player declines lock | Restore the exact pre-swap board. | Combo resets to 0; no MP recovery. | Normal stable CHAIN board. |
| No valid match, player selects MP lock | Keep the swapped board in place. | Spend fixed **1 MP**, reset Combo to 0; no immediate clear, cascade, Combo, or MP recovery. | Normal stable CHAIN board, ready for a later setup swap. |

`MP lock` is an optional response to an otherwise-invalid swap. It must not be offered for non-adjacent input, during an already-committed resolution, or as a way to keep an already-valid match from resolving.

## 4. Per-wave Combo and MP recovery

Each resolved wave — the initial valid swap result and every later gravity/refill cascade — resolves in this order:

1. Identify every **maximal** qualified straight group in that wave. A 5-cell line is one length-5 group, never several overlapping length-3 groups.
2. Add **Combo +1**, capped at **10**.
3. Recover MP for that same wave with the following structured rule:

```text
SUM_MAXIMAL_QUALIFIED_LINE_LENGTHS_MINUS_3_PLUS_POST_WAVE_COMBO
MP recovery = (sum of all qualified maximal group lengths − 3) + Combo after this wave's +1
```

- Distinct horizontal, vertical, and diagonal groups count independently even when they cross on a cell. For a horizontal 5 and vertical 5 in one wave, the line term is `5 + 5 − 3 = 7 MP`.
- The `−3` is applied **once per resolved wave**, not once per group.
- The post-wave Combo value is the actual stored value after its +1 and the 10-cap. Thus a player who spends Combo on a Technique deliberately receives less MP from later successful CHAIN waves.
- A later manual swap that creates a valid match continues the current Combo rather than starting a separate streak. A failed/reverted swap or MP lock resets it, as stated above.
- Each additional cascade wave receives its own Combo +1 and its own MP recovery; the full cascade is not collapsed into one end-of-resolution reward.

## 5. Tuning and implementation boundary

- The failed-swap MP lock cost is fixed at **1 MP** and MP has a hard cap of **60 MP** for the vertical slice. Initial LINE recovery is fixed to the existing data seed: no clear/Single/Double/Triple/Four = **0 / 10 / 22 / 36 / 52 MP**. The Combo/CHAIN-MP rule is structurally approved; its numerical balance remains `TUNE_REQUIRED` until Human evidence exists.
- MP overflow creates no combat resource. The UI must expose a full MP state before another LINE reward, and explain this rule with structured text/interaction feedback, not image-only labels: `No straight 3+ match — revert`, `Spend 1 MP to keep this swap for a later Combo`, and `MP full — spend MP before the next LINE reward`.
- The runtime keeps internal `energy` / `stock` names while exposing `MP` / `COMBO` labels. `ChainBoard` detects horizontal, vertical and both diagonal maximal straight groups; `ChainResolver` emits each wave's qualified line lengths; `ProductionCombatState` enforces MP 60 / Combo 10 and computes each wave's formula; the session preserves an invalid-swap snapshot until the player reverts or pays 1 MP to keep it. `ProductionCombatRuntime` commits every emitted wave exactly once. Its alignment is `CHAIN_RESOURCE_ALIGNMENT_IMPLEMENTED_MACHINE_VERIFIED`.
- The remaining Phase 2 Skill PR must replace the legacy manual Tier 1–6 path with the `TETRIS-SKILL-039` category-resolved Stage 1–10 path and bind its approved shortage fallback to the same atomic resource owner. The present CHAIN/resource implementation must not be represented as balance, target-device runtime, or Human/player validation.

## 6. Tutorial and visual rule

`TETRIS-ONBOARDING-037` now uses **FULL_PRE_DEPLOY_BRIEFING**. On the **first intended session only**, Deploy remains disabled until the readable full-rule region reaches its end or the player completes an equivalent accessible review action; later entries may Deploy immediately and re-open that same summary. The section presents the complete first-slice CHAIN grammar: orthogonal swap; straight horizontal, vertical, or either-diagonal 3+ match; Combo +1 per resolved wave to cap 10; `(sum maximal qualified line lengths − 3) + post-wave Combo` MP recovery; default no-match revert and Combo reset; and the fixed-1-MP optional lock that keeps the swap but resets Combo and grants no immediate reward. It also states that Tier N spends N shared Combo plus configured Technique MP, so saving Combo preserves later CHAIN MP recovery.

After Deploy, a short guided practice inside the actual CORE-029 battle verifies those disclosed rules, then continues normal play in the same encounter. MP lock remains an optional planning tool, never a required first-tutorial transaction. Planning boards and visual references may illustrate the rule, but their images are not the source of truth. The exact rule belongs to this text contract and its linked repository/GitHub decision records.
