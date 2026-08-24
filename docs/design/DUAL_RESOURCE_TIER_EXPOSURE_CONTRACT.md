# Dual-Resource Tier Exposure Contract

- Status: **CURRENT PRODUCTION BALANCE STRUCTURE / PLANNING CONTINUATION / BUILD DEFERRED**
- Decision: `TETRIS-BALANCE-027 · Dual-Resource Opportunity Cost + Tier Exposure`
- Date: 2026-08-24
- Parent skill decision: `TETRIS-SKILL-026`
- Turn authority: `TETRIS-CORE-024`
- Timing authority: `TETRIS-TIME-025`
- Human-readable Notion owner: `16 · Resource Economy · Tier Exposure Contract`

## 1. Product thesis

The combat economy must not collapse into either:

- `hoard Chain Stock until Tier 6, then press the biggest button`; or
- `spam the cheapest Tier every turn because saving has no meaningful payoff`.

The intended question after Line and Chain settle is:

> Given the enemy Telegraph, my HP, Energy, Chain Stock, current setup, and the next Forecast, how much should I spend **now** and how much option value should I preserve for the next turn?

Energy and Chain Stock remain deliberately non-interchangeable so both puzzle phases keep a distinct combat purpose.

## 2. Alternatives considered

### A. Merge Energy and Stock into one resource

- Strength: simplest economy and UI.
- Failure: Line and Chain become alternate ways to buy the same result; one puzzle can become strategically redundant.
- Decision: **REJECT**.

### B. Dual-resource opportunity cost — ADOPT

- Line creates **Energy**, the flexible/repeatable throughput resource.
- Chain creates **Chain Stock**, the persistent Tier-access / commitment resource.
- Tier N spends exactly N Stock; Energy supplies a separate technique-specific soft price.
- Lower tiers tend toward efficiency/light commitment; higher tiers provide peak, specialization, or action compression.
- Decision: **ADOPT**.

### C. Add per-Technique currencies/cooldowns

- Strength: long-term buildcraft depth.
- Failure: first-Slice UI, tutorial, content and balance surface expands before the core turn is validated.
- Decision: **REJECT CURRENT**.

## 3. Resource ownership

### Energy

- Primary source: production Line.
- Persists across turns until spent or explicitly modified.
- Represents flexible ability throughput and technique-specific utility price.
- No passive `+1 Energy/sec` production recovery in the first production baseline.
- Lower tiers generally retain strong Energy efficiency, but utility Techniques may price differently from same-Tier raw damage.

### Chain Stock

- Primary source: production Swap-Match Chain.
- Persists across turns until spent or explicitly modified.
- Production cap: **6**, aligned with current Tier range.
- Tier N action spends exactly N Stock.
- Tier 6 therefore consumes the entire full-cap commitment budget from a fresh cap state and must create a real next-turn opportunity cost.
- Stock gain at cap may be wasted; indefinite hoarding therefore has a visible lost-opportunity edge instead of being free.

Neither resource may silently substitute for the other in first-Slice Skill legality.

## 4. Tier exposure over a first run

This is an **exposure contract**, not a fixed turn-by-turn reward script.

### First tutorial turn

Use an authored production board seed that makes at least one meaningful Line result and one meaningful Chain result learnable under the real rules.

- The player earns the resources through the real puzzles.
- The tutorial does not simply gift T1 resources behind the scenes.
- T1 should become a natural first legal action under competent basic completion.
- Higher tiers remain visibly gated by Stock/Energy rather than being modal-hidden.

### Early fight

- T1–T2 are the most common visible choices.
- Light pressure teaches efficient low commitment and future Stock preservation.

### Mid fight

- Good Chain performance and/or deliberate saving opens T3–T5.
- Gatebreaker resource-loss, heavy-hit and repair Intents create reasons to use specialized Breach / Counter / Haste / Ward / Seal / setup options.

### Climax

- T6 is a signature candidate, not a routine per-turn expectation.
- Siege Charge, lethal windows, execution windows, or low-pressure long setup may justify T6.
- The encounter must not require T6 every turn or require a single exact T6 Technique to survive.

## 5. Cost curve boundary

Stock grammar is fixed structurally:

```text
Tier:       1  2  3  4  5  6
Stock cost: 1  2  3  4  5  6
```

Energy values are **TUNE_REQUIRED**. A first comparison seed may use T1-relative factors around:

```text
1.00 / 1.25 / 1.55 / 1.90 / 2.20 / 2.55
```

This ratio is not final canon. It exists to initialize impossible-state and dominance simulation once production Line Energy gain data exists.

Rules:

- higher Tier must not automatically improve Energy efficiency;
- a utility-heavy Technique may exchange immediate output for control/setup value;
- a high-Tier specialized action may be deliberately inefficient outside its condition;
- exact Energy gain/cost and effect magnitude remain runtime/human-evidence tuning.

## 6. Anti-hoarding / anti-spam pressure

Five independent mechanisms prevent one-direction play:

1. **Stock cap 6:** saving forever can waste future Chain gain.
2. **Rift Siphon / Chain Fracture:** threatened resources can be protected or pre-spent.
3. **Rift Repair / heavy/lethal pressure:** some turns create a reason to commit resources now.
4. **Setup Techniques:** low immediate output can improve future opportunity, creating the opposite choice from raw spend-now burst.
5. **Tempo non-currency rule:** fast completion does not directly generate Energy or Stock, preventing time skill from becoming a compounding resource faucet.

## 7. Curated scenario contract

Automated scenario tests use curated states to detect obvious strict dominance or impossible states. They are not a substitute for human fun/balance evidence.

| Scenario | Rational candidate set | Purpose |
|---|---|---|
| Light hit + scarce resources | ATK T1 / DEF T1 | low-tier efficiency survives |
| Light hit + heavy next Forecast | DEF T2 Fortify / low-tier response + preserve Stock | future value matters |
| Heavy direct hit | DEF T3 Counter / DEF T4 Bulwark / lethal ATK | counter vs safety vs race |
| Energy/Stock loss telegraphed | DEF T5 / SUP T5 / pre-spend threatened resource | protect vs disrupt vs consume |
| Enemy Repair | ATK T3 Breach / ATK T4 burst / SUP T4 setup | immediate vs future offense |
| Lethal Siege Charge | DEF T4 / DEF T6 / conditional ATK T6 kill | high-Tier moment without single answer |
| Low-pressure setup window | ATK T3 / SUP T2 / SUP T3 / SUP T6 / preserve | setup may beat raw Tier |
| Synthetic multi-target future case | ATK T2 Sweeping Cut | AoE schema remains useful without first-Slice mob expansion |

A tuning seed FAILS if its numbers make every candidate except the highest affordable Tier obviously irrational in these fixtures.

## 8. Encounter integration

Gatebreaker authored intent ladder must expose multiple economic questions over one complete battle:

- **Light:** spend little or invest in setup.
- **Heavy:** spend for mitigation/counter or race lethal.
- **Resource loss:** protect, disrupt, or pre-spend.
- **Repair:** use immediate damage or future offense setup.
- **Siege/lethal:** peak survival or kill-before-resolve.
- **Low-pressure window:** invest in next-turn preparation.

Enemy behavior remains authored. It never reads the chosen player Technique and secretly swaps the already-telegraphed current action.

## 9. First-run teaching contract

- Do not explain all 18 Techniques in a catalog.
- Stock availability naturally exposes the lower part of the grid first.
- When a new role becomes materially relevant, short tags/highlights may explain `효율 / 범위 / 설치 / 반격 / 자원보호 / 피니셔`.
- Tutorial hints do not secretly pause the Shared Player Turn Budget; only System Pause does.
- The first 2–3 turns do not use “reach Tier 6” as the tutorial objective.
- A player should learn `higher Tier = more commitment / different use`, not `higher Tier = upgrade unlocked`.

## 10. Telemetry contract

Record per turn/action:

- Energy at turn start / after Line / after Chain / before Action / after Action;
- Stock at turn start / after Chain / before Action / after Action;
- Stock gain lost at cap;
- highest available Tier;
- selected lane/Tier/Technique;
- whether the highest available Tier was selected;
- current Intent and next Forecast category;
- player/enemy HP;
- overkill;
- prevented damage / counter damage;
- threatened resource pre-spent or protected;
- setup status created/consumed;
- PASS / timeout / Board Break;
- first turn each Tier became available;
- first turn each Tier was selected.

Derived review metrics:

- highest-available-Tier pick rate;
- lower-tier unused rate;
- Stock carried distribution;
- Stock-cap waste;
- Energy surplus/shortage distribution;
- Intent→response diversity;
- conditional T6 use when condition is false.

## 11. Simulation Reality Gate

### Automated simulation may claim

- a resource state has zero legal actions;
- a cost curve creates obvious strict dominance under the curated scenario utility assumptions;
- Stock cap overflow or persistent resource starvation/surplus occurs under seeded runs;
- deterministic seeds reproduce availability and spending outcomes.

### Automated simulation may not claim

- the decision is fun;
- the player understands why a lower Tier is good;
- Telegraph/readability is sufficient;
- the final Energy/Stock/effect/Turn-time numbers are balanced.

Human evidence remains mandatory for those claims.

## 12. Human evidence gate

Minimum A/B/C production runs ask:

1. Can the player explain **why they did not choose the highest available Tier** using Intent/resources/future plan?
2. Does Line matter because Energy matters, and Chain matter because Stock/Tier option value matters?
3. Does the player always hoard to 6 or always dump Stock immediately?
4. Do low tiers remain practical beyond onboarding through efficiency, finishing, or preservation?
5. Do Siphon/Fracture create `spend now vs protect` decisions rather than pure frustration?
6. Is T6 memorable as a signature commitment rather than routine housekeeping?

## 13. Benchmark absorption

### Into the Breach — ADOPT

Enemy attacks are explicitly telegraphed and the player analyzes the shown attack to find the appropriate counter. Adopt **situation fit over hidden reaction or fixed power ranking**.

### Slay the Spire family — ADAPT

Low-cost actions may retain utility/setup/debuff value, and Mega Crit describes active rework/balance work aimed at keeping cards/items interesting and viable. Adapt **continued viability through differentiated purpose rather than cost alone**.

### Grindstone — ADAPT

Puzzle performance directly increases combat output, while longer commitment brings rising danger. Adapt the opportunity-cost feeling into `prepare more vs act now`, without copying its pathing/combat rules.

### REJECT

- technique-specific new currencies/cooldowns in the first Slice;
- finalizing exact economy values before production puzzle/runtime evidence;
- adding extra enemies merely to validate AoE.

## 14. Five-pass adversarial review

1. **Tier-6 hoarding:** corrected with cap pressure, resource-loss threats, now-vs-later Intents, and specialized rather than universal T6.
2. **Low-tier spam:** corrected by Heavy/Repair/Siege and setup/control opportunities where mid/high Tier has unique purpose.
3. **One puzzle becomes optional:** prevented by keeping Energy and Stock non-substitutable gates.
4. **Tutorial overload:** corrected with real puzzle-earned T1 and contextual Tier-role exposure rather than 18-item teaching.
5. **False precision:** only structural costs, relative seed, scenarios and evidence requirements are locked; exact values remain TUNE_REQUIRED.

`CLEAN_REVIEW_EXIT` for economy/tier-exposure structure.

## 15. Implementation Reality Gate

Current claims allowed:

- dual-resource role split is documented;
- Tier-exposure and anti-dominance validation contract is specified;
- first-run/encounter scenario requirements are defined;
- exact numeric values are intentionally not final.

Current claims forbidden:

- final Energy/Stock economy balanced;
- Tier pick distribution proven;
- T6 frequency validated;
- human lower-tier viability proven;
- production economy runtime implemented.

Production BUILD remains deferred until explicit `기획 완료 / BUILD 진행` authorization or equivalent.
