# Combo-Resolved Tactical Skill Contract

- Decision: `TETRIS-SKILL-039 · Category Choice → Combo-Resolved Technique → Explicit Confirm`
- Balance amendment: `TETRIS-BALANCE-040 · Bounded Combo-to-MP Fallback`
- Content amendment: [`TETRIS-SKILL-042 · Deliberate Combo Stop + Target-Separated Time Control`](COMBO_STAGE_SKILL_CONTENT_GDD.md)
- Status: `USER_DIRECTED / PHASE 1 CANON / DOCUMENTED_NOT_IMPLEMENTED`
- Date: 2026-08-28
- Scope: one tactical-pause skill decision inside `TETRIS-CORE-029`; it does not alter continuous combat, LINE/CHAIN ownership, the 1-MP CHAIN setup lock, or the Combo cap.
- Detailed predecessors: `TETRIS-SKILL-026` and `TETRIS-BALANCE-027` are `SUPERSEDED_FOR_MANUAL_TIER_SELECTION_AND_COST_GRAMMAR`. They remain historical evidence for the three lane identities and reusable effect primitives only.

## 1. Player-facing promise

The player should make **one readable tactical choice**, not browse a wall of eighteen small cards:

```text
Current live threat + current Combo
→ open SKILL (full tactical pause)
→ choose ATK / DEF / SUP only
→ inspect the one technique automatically resolved for this Combo state
→ explicit CONFIRM
→ atomic resolution, then the same live battle resumes
```

`automatic resolution after CONFIRM` means the system resolves the already-authored lane-and-stage technique. It is **not unattended auto-cast**: a lane press is a preview, never a commitment.

## 2. Fixed interaction grammar

1. Opening `SKILL` enters the existing `TACTICAL_PAUSE_SKILL`. Puzzle, ETA, enemy scheduler, combat VFX and simulation audio remain frozen.
2. The player may choose `ATK / DEF / SUP` only. There is **no manual Tier button**, no permanent 3×6 skill wall and no separate skill-card selection.
3. On lane selection, the UI previews exactly one candidate: lane, Combo Stage, purpose, target/condition, MP/Combo cost, fallback conversion if any, and the visible expected result.
4. `Cancel` closes the surface with no resource change. Switching lane replaces the preview with no resource change. **Preview never spends MP or Combo.**
5. Only the explicit `CONFIRM` button commits. It atomically applies the displayed conversion, spends the displayed resources, resolves the displayed effect, closes Skill, and resumes the exact paused combat state.

The three category buttons are a player-facing tactical vocabulary, not three separate currencies:

| Category | Current role to preserve |
| --- | --- |
| `ATK` | Damage, breach and decisive-pressure answers. |
| `DEF` | Mitigation, counter, lethal safety and current-threat protection. |
| `SUP` | Recovery, setup, player board-play opportunity, and visible-current-Telegraph ETA utility. |

## 3. Combo Stage resolver

- Combo cap is **10**. A viable current Combo state is `C ∈ [1, 10]`.
- Each lane owns authored **Stage 1–10 content**: `LaneStage[ATK|DEF|SUP][1..10]`. Stage is a resolved Combo state, not a separately selected player tier.
- `LaneStage[C]` is the normal preview. It spends `C` Combo and its authored MP cost `MP(lane, C)`.
- The user-approved C1–C10 matrix retains contextually meaningful lower-Combo responses. The player may intentionally stop CHAIN preparation at a desired lower current Combo to use its unique response; they may not manually select a lower Stage while holding a higher Combo. `COMBO_STAGE_SKILL_CONTENT_GDD.md` owns the approved content, target-separated time-control semantics and Phase 2 content gates. The exact Phase 2 worktree now validates the 30-entry C1–C10 seed; category-only selection, fallback and the final battle presentation remain later implementation tasks.
- Stage content must remain data-driven effect composition. This contract does not authorize thirty bespoke scripts, a new currency, cooldown system or a new enemy roster.

## 4. MP-insufficient bounded fallback

The only permitted MP/Combo conversion is inside an explicit Skill confirmation. LINE still owns normal MP income; CHAIN still owns Combo and its later MP-recovery opportunity.

For selected lane `L`, current MP `M`, current Combo `C`, MP cap `60`, and a candidate lower Stage `S`:

```text
converted_combo = C − S
converted_mp    = 5 × converted_combo
available_mp    = min(60, M + converted_mp)
candidate legal iff available_mp ≥ MP(L, S)
```

Resolver order:

1. If `M ≥ MP(L, C)`, preview `LaneStage[C]`; conversion is `0`.
2. Otherwise, inspect lower `S` from `C − 1` down to `1` and choose the **highest feasible lower Stage**.
3. The preview then states both parts: `convert C−S Combo at 5 MP per converted Combo`, followed by `spend S Combo + MP(L,S)`.
4. Because converted Combo plus the chosen Stage spend equal the opening Combo, confirmation spends all opening Combo exactly once. Preview/cancel changes neither resource.
5. If no Stage `1..C` is legal, confirmation is disabled with the missing-resource reason. This contract does not invent a Stage-0 fallback.

Example:

```text
Combo 3, player chooses ATK
→ ATK Stage 3 is previewed first
→ if MP is insufficient and ATK Stage 2 becomes legal after one conversion:
   convert 1 Combo → 5 MP
   spend 2 Combo + ATK Stage 2 MP cost
   resolve ATK Stage 2 after explicit CONFIRM
```

MP cap clipping is shown in the preview; clipped conversion has no hidden overflow value. The resolver must not silently choose a lower stage when the current stage is already legal.

## 5. Strategy and teaching boundary

The meaningful choice is now **what role answers the shown danger**, plus whether to preserve Combo by returning to CHAIN rather than opening Skill. The player no longer decides “which of six tiny cards is strongest.”

The first-session briefing and safe live tutorial must teach:

1. Combo is earned in CHAIN and improves later CHAIN MP recovery.
2. Opening Skill freezes time, but only explicit `CONFIRM` spends anything.
3. Pick ATK, DEF or SUP; the current Combo resolves the technique stage and the preview explains its consequence.
4. When MP is short, surplus Combo can become **5 MP each** only to find the highest legal lower Stage; this is an emergency trade, not general MP generation.

This preserves the user-approved tension: spend the shared Combo now for a timely category response, or save it for later CHAIN MP recovery and a higher-stage opportunity.

## 6. Actual implementation boundary

Fresh merged-main evidence began with the legacy manual Tier 1–6 flow. The exact Phase 2 implementation worktree is now `PARTIAL_IMPLEMENTATION_NOT_RUNTIME_VERIFIED`:

- `src/production/ui/production_battle.gd` binds `TierGrid/Tier1..Tier6` and maps a manually selected lane/tier to an id.
- `src/production/skill/production_skill_catalog.gd` and `data/production/vanguard_skill_seed.json` now validate one data-driven C1–C10 definition for each `ATK/DEF/SUP` lane/stage pair, including current-action packages without an unimplemented multiplier.
- `src/production/skill/production_skill_session.gd` can spend the aligned `mp_cost` / `combo_cost` fields, but still requires a manually selected technique id.
- The category-only resolver, exact 5-MP fallback preview/commit, target-separated time primitives and replacement presentation are not yet wired; this data slice alone is not the player-facing new Skill flow.

No target-device runtime, scene presentation or Human/player evidence is promoted by this partial implementation. Phase 2 must still replace the manual-grid UI/session path with a deterministic resolver, use RED→GREEN tests for the formula above, and obtain target-resolution plus first-exposure evidence before a usability/pass claim.

## 7. Acceptance contract for the later implementation issue

- A player can select only `ATK / DEF / SUP` while Skill is paused.
- The selected category shows the exact current-stage technique and its full cost/effect preview before any spend.
- `CONFIRM`, and only `CONFIRM`, commits the previewed technique atomically.
- When the current stage lacks MP, the system selects the highest feasible lower Stage after the exact 5-MP-per-Combo conversion; it never changes resources during preview.
- Combo never exceeds 10; all fallback math honors MP cap 60 and never creates a Stage 0 cast.
- Cancel returns to the exact paused battle state without any conversion, spend or board mutation.
- Current runtime/manual Tier 1–6 evidence remains labeled legacy until the replacement exact HEAD passes automated and target-device runtime validation.
