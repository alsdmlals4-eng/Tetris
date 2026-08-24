# Vanguard Tactical Skill Matrix

- Status: **CURRENT PRODUCTION SKILL CANON / USER-APPROVED DIRECTION / BUILD DEFERRED**
- Decision: `TETRIS-SKILL-026 · Situational Tactical Tier Matrix`
- Date: 2026-08-24
- Parent combat canon: `TETRIS-CORE-024`
- Timing canon: `TETRIS-TIME-025`
- Human-readable Notion owner: `15 · Vanguard 스킬 · Tactical Tier Matrix`

## 1. Product thesis

The Vanguard skill system must not collapse into `save Stock → press the highest Tier available`.

The player reads the enemy Telegraph, checks HP / Energy / Chain Stock / next Forecast, then chooses the **cheapest or most specialized Technique that solves the current problem while preserving future options**.

Current lanes remain:

- **ATK** — pressure, damage, setup, finishing.
- **DEF** — protection, mitigation, counter, resource ward.
- **SUP** — recovery, self-buff, timing utility, non-damage disruption.

`Tier 1–6` remains the player-facing grid and Stock cost grammar, but **Tier is a commitment/cost band, not a linear quality ladder**.

## 2. What SKILL-026 supersedes

Retain from `TETRIS-SKILL-022`:

- three persistent lanes: Attack / Defense / Support;
- Tier range 1–6;
- `Tier N` requires `Stock >= N` plus configured Energy;
- using Tier N spends exactly N Chain Stock plus its Energy cost;
- no core terminology change from `Energy` to Mana/Magic/Spell.

Supersede these interpretations:

- every Tier is merely a stronger numerical version of one identical action;
- the highest affordable Tier should normally be the best choice;
- player-facing Technique identity is forbidden from changing by Tier;
- `18 independent skills` means `18 bespoke subsystems/scripts`.

New boundary:

> The UI may expose 18 distinct Technique cells, but runtime implementation composes them from a bounded set of reusable effect primitives and shared lane presentation grammar.

## 3. Alternatives considered

### A. Linear upgrade ladder

Each lane keeps one action and T1→T6 mostly raises numbers.

- Strength: simplest implementation and onboarding.
- Failure: directly violates the user requirement for situational tuning and makes saved Stock converge toward the highest Tier.
- Decision: **REJECT**.

### B. Technique + separate Tier selector

Player first chooses a Technique, then separately chooses how much Tier/Stock to invest.

- Strength: maximum flexibility and long-term build depth.
- Failure: two-dimensional Action selection, more clicks, more UI density, more content/balance permutations during a shared timed turn.
- Decision: **REJECT for first Slice; possible future expansion after evidence**.

### C. Tactical Tier Matrix

Each lane keeps six visible cells, but each Tier cell has a distinct tactical role inside the lane.

- Strength: preserves the current 3×6 HUD, enables diverse skills, makes lower tiers situationally rational, and avoids an extra selection layer.
- Weakness: 18 identities can overload onboarding if all are explained at once.
- Correction: Stock availability naturally gates higher tiers; onboarding teaches T1 first and exposes new roles contextually.
- Decision: **ADOPT**.

## 4. Dominance Guard

Every T2–T6 Technique must leave at least one encounter state where a lower Tier in the same lane is the rational choice.

### Required tradeoff grammar

- **T1–T2:** resource efficiency, light response, finishing, low commitment.
- **T3–T5:** setup, counter, debuff, ward, specialized response.
- **T6:** conditional signature, lethal safety, or expensive long-horizon setup.

### Forbidden dominance patterns

- T6 bundles more damage + more defense + more healing + more control than lower tiers.
- Energy efficiency monotonically improves with Tier.
- a higher Tier strictly contains the lower Tier effect for a modest cost increase.
- a status/debuff is only a decorative extra on a numerically dominant high Tier.

### Runtime evidence failure

The matrix FAILS if telemetry shows:

- `highest available Tier whenever affordable` becomes the default policy;
- any lower Tier is effectively unused outside the tutorial;
- player explanations for Technique choice do not refer to Telegraph, current resources, HP, setup, or future opportunity cost.

## 5. Vanguard matrix

### ATK Lane

| Tier | Technique | Type | Tactical reason |
|---|---|---|---|
| T1 | `Quick Cut` / 신속 베기 | Single / Efficient | Cheapest direct damage. Finisher, light-pressure action, Stock preservation. |
| T2 | `Sweeping Cut` / 휩쓸기 | AoE-capable / Flexible | Moderate damage with multi-target target pattern. Normal single-target fallback in the one-boss first Slice. |
| T3 | `Rift Breach` / 균열 파쇄 | Setup / Enemy Debuff | Moderate damage + one `BREACH` mark consumed by a later ATK. Approved replacement direction for countdown Stagger. |
| T4 | `Crushing Strike` / 중압 강타 | Raw Burst | High unconditional single-target damage when setup is unavailable or immediate damage matters most. |
| T5 | `Suppressive Break` / 제압 파쇄 | Damage / Future Weaken | Damage + weakens the next direct-hit enemy Intent. Does not cancel or secretly replace the Telegraph. |
| T6 | `Execution Edge` / 처형 일격 | Conditional Finisher | Signature burst when `BREACH` exists or enemy HP is below the configured threshold. Intentionally inefficient without condition. |

### DEF Lane

| Tier | Technique | Type | Tactical reason |
|---|---|---|---|
| T1 | `Guard` / 방어 태세 | Efficient Mitigation | Light direct-hit response. Avoids wasting high Tier on Light Smash. |
| T2 | `Fortify` / 견고한 자세 | Mitigation / Self Buff | Moderate mitigation + small carry-over protection for the next direct hit. Strong when current hit is light and next Forecast is heavy. |
| T3 | `Counter Stance` / 역습 준비 | Mitigation / Counter | Converts a bounded portion of actually prevented damage into counter damage. More valuable against meaningful direct hits. |
| T4 | `Bulwark` / 철벽 수호 | Peak Mitigation | Strong immediate protection when survival now matters more than setup/counter value. |
| T5 | `Rift Ward` / 균열 방벽 | Resource Ward | Reduces one telegraphed Energy/Stock-loss effect such as Rift Siphon or Chain Fracture. Not a direct-HP block. |
| T6 | `Last Bastion` / 불굴의 성채 | Lethal Safety | Emergency lethal-direct-hit safety / HP-floor behavior with bounded mitigation. Intentionally wasteful when the hit is not lethal. |

### SUP Lane

| Tier | Technique | Type | Tactical reason |
|---|---|---|---|
| T1 | `Second Wind` / 재기 | Efficient Heal | Cheap recovery for small HP loss. |
| T2 | `Rally` / 재정비 | Self Buff | Buffs the next player Action once. Setup choice when immediate survival is not required. |
| T3 | `Haste` / 전투 가속 | Time Utility | Adds configured seconds to the next eligible Shared Player Turn Budget under TIME-025. Never mutates current visible timer or Tempo Reference. |
| T4 | `Mark Weakness` / 약점 지시 | Enemy Debuff / Setup | Marks the enemy so a later ATK gains bounded offensive value. No immediate damage. |
| T5 | `Rift Seal` / 균열 봉쇄 | Intent Disruption | Reduces one upcoming resource-loss or repair Intent. Direct hits remain DEF territory. |
| T6 | `Battle Trance` / 전투 몰입 | Expensive Self Setup | No immediate heal/defense. Bounded next-turn Line Energy conversion + Chain reward conversion boost. Bad choice under immediate lethal pressure. |

Names are first-slice working names. Exact copy may change without changing Technique semantics.

## 6. Effect primitive contract

First production implementation composes skill data from these primitives rather than one script per Technique:

- `DAMAGE_SINGLE`
- `DAMAGE_AOE`
- `MITIGATE_CURRENT_DIRECT`
- `COUNTER_FROM_PREVENTED_DAMAGE`
- `HEAL_SELF`
- `APPLY_SELF_BUFF`
- `APPLY_ENEMY_DEBUFF`
- `PROTECT_RESOURCE_LOSS`
- `MODIFY_NEXT_TURN_BUDGET`
- `CONDITIONAL_MULTIPLIER`
- `LETHAL_SAFETY`
- `TARGET_PATTERN`

A Technique definition owns data such as:

```json
{
  "id": "atk_t3_rift_breach",
  "lane": "ATTACK",
  "tier": 3,
  "stock_cost": 3,
  "energy_cost": 0,
  "target_mode": "SINGLE_ENEMY",
  "tags": ["DAMAGE", "SETUP", "ENEMY_DEBUFF"],
  "effects": [
    {"op": "DAMAGE_SINGLE", "magnitude": 0.0},
    {"op": "APPLY_ENEMY_DEBUFF", "status": "BREACH", "stacks": 1}
  ],
  "tempo_scalable_fields": ["damage"]
}
```

`0.0` values in this design example are schema placeholders only in the explanatory snippet, not runtime tuning values. Runtime data must use explicit approved/tuning-seed numbers before BUILD tests can pass.

## 7. Bounded status contract

First Slice does **not** build a general RPG status engine.

Candidate skill statuses are bounded records with explicit ownership and expiry:

- `BREACH` — max 1; consumed by qualifying ATK or expires after configured turn boundary.
- `FORTIFY` — max 1; consumed by next qualifying direct hit or expires.
- `RALLY` — max 1; consumed by next legal player Action.
- `WEAKEN` — max 1; applies only to the next qualifying direct-hit enemy Intent.
- `RIFT_WARD` — max 1; consumed by the next qualifying Energy/Stock loss.
- `RIFT_SEAL` — max 1; consumed by the next qualifying resource-loss/repair Intent.
- `BATTLE_TRANCE` — max 1; consumed across the next eligible Line/Chain preparation window.

No unconditional stacking, arbitrary duration extension, or percentage-stack algebra is added in the first Slice.

## 8. Tempo integration safety

`TETRIS-TIME-025` Tempo may scale safe action-potency fields:

- damage;
- healing;
- mitigation magnitude;
- counter magnitude;
- explicitly whitelisted bounded potency buff magnitude.

Tempo must **not** scale:

- Haste seconds;
- status duration;
- Stock/Energy cost;
- number of ward charges;
- AoE target count;
- Last Bastion HP-floor behavior;
- number of turns affected.

This prevents loops such as `finish fast → stronger Haste → more time → easier future Tempo`.

## 9. Energy/Stock budget rule

Stock cost remains exactly equal to Tier: `1,2,3,4,5,6`.

Exact Energy values remain `TUNE_REQUIRED` until production simulation/human evidence. Initial comparison may use T1-relative Energy factors around:

```text
T1 1.00
T2 1.25
T3 1.55
T4 1.90
T5 2.20
T6 2.55
```

This is a **comparison seed, not final canon**.

Utility Techniques may trade lower immediate output for their control/setup effect and may deviate within a bounded band. Higher Tier must not automatically improve Energy efficiency.

## 10. Gatebreaker response diversity

| Encounter state | Rational candidates | Decision quality target |
|---|---|---|
| Light Smash | DEF T1, DEF T2, ATK T1 | Do not overspend on a light threat. Forecast may justify Fortify. |
| Gatebreaker Slam | DEF T3, DEF T4, lethal ATK | Counter value vs reliable survival vs kill. |
| Rift Siphon | DEF T5, SUP T5, spend Energy now | Protect, disrupt, or pre-spend threatened resource. |
| Chain Fracture | DEF T5, SUP T5, spend high Stock now | Preserve Stock or convert it before loss. |
| Rift Repair | ATK T3 setup, ATK T4 burst, SUP T4 setup | Immediate damage race vs future offensive setup. |
| Siege Charge | DEF T4, DEF T6, conditional ATK T6 lethal | Peak mitigation vs lethal safety vs kill-before-resolve. |
| Low-pressure setup window | ATK T3, SUP T2/T3/T6 | Use time/resources to improve the next turn instead of maximizing current raw output. |

Enemy Telegraph remains authored and cannot secretly change because the player selected a counter.

## 11. AoE scope boundary

The core schema supports `DAMAGE_AOE` and target patterns because future encounters/classes need them.

The representative first Slice remains:

- 1 Vanguard;
- 1 Gatebreaker;
- 1 Frontier Gate.

Do **not** add a mob/add roster merely to prove AoE.

`Sweeping Cut` must have a legal single-target fallback against Gatebreaker. Multi-target balance and encounter value remain future evidence, not first-Slice completion evidence.

## 12. UI / onboarding contract

- Keep one 3×6 lane grid; no Technique submenu in the first Slice.
- Each cell shows lane, Tier, Technique name/icon, Stock gate, Energy gate, and a short tactical tag.
- Readiness must still distinguish `Stock insufficient`, `Energy insufficient`, and `Ready`.
- Meaning is not color-only.
- First tutorial turn naturally exposes T1 because Stock is low; it does not modal-explain all 18 Techniques.
- Higher Tier cells become learnable as Stock grows and Gatebreaker creates relevant Intent situations.
- Tooltips may explain exact effects, but the primary Action decision must be legible from short tags such as `효율`, `범위`, `설치`, `반격`, `자원보호`, `피니셔`.

## 13. Telemetry / validation

Record at minimum:

- selected lane + Tier + Technique id;
- available highest Tier at decision time;
- HP/Energy/Stock before selection;
- enemy current Intent + next Forecast category;
- overkill amount;
- prevented damage / counter damage;
- resource loss prevented;
- setup status created/consumed;
- whether the player selected the highest available Tier;
- reason tags available to the decision scenario;
- victory/defeat and encounter turn index.

Dominance review metrics:

- per-Technique pick rate;
- lower-tier unused rate;
- highest-available-Tier pick rate;
- average resource overkill/waste;
- Intent→response diversity;
- T6 pick rate when its condition is false.

## 14. Benchmark absorption

### Into the Breach — ADOPT

Official product framing emphasizes that enemy attacks are telegraphed and the player analyzes the attack to find the appropriate counter. Adopt **situation-fit over hidden reaction or raw power hierarchy**.

### Slay the Spire family — ADAPT

Official Slay the Spire 2 previews include cheap/zero-cost actions whose value comes from utility/debuff/setup rather than raw cost, and Mega Crit explicitly describes ongoing balance work so cards/items remain interesting and viable. Adapt the principle: **low commitment actions keep tactical identity instead of becoming obsolete**.

### Shogun Showdown — ADAPT

The game frames combat around every action counting, attack timing, upgrades and combos. Adapt action economy: **one well-timed specialized Technique may beat a larger raw action**.

### REJECT

- 18 unique bespoke controllers/scripts;
- first-Slice mob expansion just to justify AoE;
- generic long-duration status-stack RPG system;
- extra Technique-selection submenu;
- hidden enemy counter-selection after Telegraph.

## 15. Five-pass adversarial review

1. **Tier dominance:** T6 all-purpose risk found. Corrected by assigning T6 conditional finisher / lethal safety / long setup and preserving lower-tier efficiency.
2. **Lane blur:** Diverse effects risk making every lane solve everything. Corrected ownership: ATK pressure, DEF protection, SUP recovery/buff/non-damage disruption.
3. **Cognitive load:** 18 identities risk tutorial overload. Corrected with one 3×6 grid, Stock-gated exposure, shared tags, no modal catalog dump.
4. **AoE scope:** range attack risk expanding the one-boss Slice. Corrected by schema support + single-target fallback; multi-target content remains later.
5. **Solo-dev cost:** 18 Technique behaviors risk bespoke-code explosion. Corrected with effect primitives, bounded statuses, data definitions, and scenario-driven verification.

`CLEAN_REVIEW_EXIT` for planning structure. Numeric balance remains evidence-tuned.

## 16. Implementation Reality Gate

Current claims allowed:

- `TETRIS-SKILL-026` tactical Tier architecture is documented and user-directed/approved at the design level.
- Notion owner + GitHub Issue #10 ledger contain the same direction.
- Effect primitive and dominance/telemetry contracts are specified.

Current claims forbidden:

- production skill runtime implemented;
- 18 Technique data integrated;
- lower-tier viability proven;
- AoE multi-target balance proven;
- Energy costs or effect magnitudes final;
- Human playtest PASS.

Runtime BUILD remains blocked until the user separately declares `기획 완료 / BUILD 진행` or equivalent.
