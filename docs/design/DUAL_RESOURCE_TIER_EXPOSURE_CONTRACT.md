# Dual-Resource Tier Exposure Contract

- Status: **RETAINED PRODUCTION BALANCE STRUCTURE / CORE-029 REALTIME MIGRATION BOUNDARY**
- Decision: `TETRIS-BALANCE-027 · Dual-Resource Opportunity Cost + Tier Exposure`
- Date: 2026-08-24
- Parent skill decision: `TETRIS-SKILL-026`
- Current combat authority: `TETRIS-CORE-029`
- Historical turn/timing provenance: `TETRIS-CORE-024` / `TETRIS-TIME-025`
- Human-readable Notion owner: `16 · Resource Economy · Tier Exposure Contract`

> `TETRIS-CHAIN-038` terminology bridge: player-facing **MP** is the current runtime field `energy`; player-facing **Combo** is the current runtime field `stock` / historical `Chain Stock`. This is a naming and ownership correction, not a third currency. LINE recovers MP; CHAIN earns the single shared Combo resource. Each CHAIN wave gives Combo +1 then recovers MP from its maximal-line total and current Combo. A failed CHAIN swap restores or may spend fixed **1 MP** to stay in place; either outcome resets Combo without an immediate reward. MP has a hard cap of **60** and Combo has a hard cap of **10**. Approved initial LINE recovery is Single/Double/Triple/Four = **10 / 22 / 36 / 52 MP**; CHAIN numerical balance remains `TUNE_REQUIRED`.

## 1. Product thesis

The combat economy must not collapse into either:

- `hoard Combo until Tier 6, then press the biggest button`; or
- `spam the cheapest Tier every turn because saving has no meaningful payoff`.

The intended question after Line and Chain settle is:

> Given the enemy Telegraph, my HP, MP, Combo, current setup, and the next Forecast, how much should I spend **now** and how much option value should I preserve for the next turn?

MP and Combo remain deliberately non-interchangeable so both puzzle phases keep a distinct combat purpose.

## 2. Alternatives considered

### A. Merge MP and Combo into one resource

- Strength: simplest economy and UI.
- Failure: Line and Chain become alternate ways to buy the same result; one puzzle can become strategically redundant.
- Decision: **REJECT**.

### B. Dual-resource opportunity cost — ADOPT

- Line creates **MP**, the flexible/repeatable throughput resource.
- Chain creates **Combo**, the persistent Tier-access / commitment resource.
- Tier N spends exactly N Combo; MP supplies a separate technique-specific soft price.
- Lower tiers tend toward efficiency/light commitment; higher tiers provide peak, specialization, or action compression.
- Decision: **ADOPT**.

### C. Add per-Technique currencies/cooldowns

- Strength: long-term buildcraft depth.
- Failure: first-Slice UI, tutorial, content and balance surface expands before the core turn is validated.
- Decision: **REJECT CURRENT**.

## 3. Resource ownership

### MP

- Primary source: production Line.
- Persists across turns until spent or explicitly modified.
- Hard cap: **60 MP**. Excess Line reward has no combat conversion and must be visibly signaled before a further Line reward.
- Approved initial implementation seed: no clear **0**, Single **10**, Double **22**, Triple **36**, Four **52 MP**. These values match `data/production/line_reward_seed.json`; they are not final Human-validated balance.
- Represents flexible ability throughput, technique-specific utility price, and the optional failed-swap CHAIN lock price.
- No passive `+1 MP/sec` production recovery in the first production baseline.
- Lower tiers generally retain strong MP efficiency, but utility Techniques may price differently from same-Tier raw damage.

### Combo

- Primary source: production Swap-Match Chain.
- Persists across workspace switches and tactical pause until spent, reset by a failed CHAIN swap/MP lock, or explicitly modified.
- Award basis: **each resolved CHAIN wave gives Combo +1**; the initial valid 3+ result and every later gravity/refill wave each add one, capped at 10. A later successful manual CHAIN swap continues this same stored resource.
- The same post-wave stored Combo adds to that wave's CHAIN MP recovery. Spending Combo on Tier access therefore lowers the later recovery available from a successful CHAIN wave.
- Production target cap: **10**. The current merged runtime cap remains 6 until Phase 2 implementation.
- Tier N action spends exactly N Combo.
- Tier 6 spends 6 of the 10-cap resource. The player can retain some Combo to grow later CHAIN MP recovery, or spend it to answer the current threat; this is the intended strategic tension.
- Combo gain at cap may be wasted, while a failed/reverted CHAIN swap or MP lock resets the stored Combo. Indefinite hoarding is therefore neither free nor automatically optimal.

Neither resource may silently substitute for the other in first-Slice Skill legality. The MP lock is a deliberate cross-workspace spend, not a Combo grant or a substitute for a Tier cost.

## 4. Tier exposure over a first run

This is an **exposure contract**, not a fixed turn-by-turn reward script.

### First tutorial turn

Use an authored production board seed that makes at least one meaningful Line result and one meaningful Chain result learnable under the real rules.

- The player earns the resources through the real puzzles.
- The tutorial does not simply gift T1 resources behind the scenes.
- T1 should become a natural first legal action under competent basic completion.
- Higher tiers remain visibly gated by Combo/MP rather than being modal-hidden.

### Early fight

- T1–T2 are the most common visible choices.
- Light pressure teaches efficient low commitment and future Combo preservation.

### Mid fight

- Good Chain performance and/or deliberate saving opens T3–T5.
- Gatebreaker resource-loss, heavy-hit and repair Intents create reasons to use specialized Breach / Counter / Haste / Ward / Seal / setup options.

### Climax

- T6 is a signature candidate, not a routine per-turn expectation.
- Siege Charge, lethal windows, execution windows, or low-pressure long setup may justify T6.
- The encounter must not require T6 every turn or require a single exact T6 Technique to survive.

## 5. Cost curve boundary

Combo grammar is fixed structurally:

```text
Tier:       1  2  3  4  5  6
Combo cost: 1  2  3  4  5  6
```

Technique MP values remain **TUNE_REQUIRED**. The approved initial LINE gain seed is fixed at 10 / 22 / 36 / 52 MP; a first comparison may use T1-relative Technique-cost factors around:

```text
1.00 / 1.25 / 1.55 / 1.90 / 2.20 / 2.55
```

This ratio is not final canon. It exists to initialize impossible-state and dominance simulation once production Line MP gain data exists.

Rules:

- higher Tier must not automatically improve MP efficiency;
- a utility-heavy Technique may exchange immediate output for control/setup value;
- a high-Tier specialized action may be deliberately inefficient outside its condition;
- exact Technique MP cost and effect magnitude remain runtime/human-evidence tuning; initial LINE gains are 10 / 22 / 36 / 52 MP, failed-swap lock cost is fixed at **1 MP**, and MP is hard-capped at **60**.

## 6. Anti-hoarding / anti-spam pressure

Five independent mechanisms prevent one-direction play:

1. **Combo cap 10 + reset risk:** saving forever can waste future CHAIN gain and puts the stored MP-recovery multiplier at risk on a failed/reverted swap or MP lock.
2. **Rift Siphon / Chain Fracture:** the current threatened resource can be protected with DEF T5 `Rift Ward` or pre-spent; a visible **future** Rift utility Forecast can instead be prepared against with SUP T5 `Rift Seal`.
3. **Rift Repair / heavy/lethal pressure:** some turns create a reason to commit resources now.
4. **Setup Techniques:** low immediate output can improve future opportunity, creating the opposite choice from raw spend-now burst.
5. **Tempo non-currency rule:** fast completion does not directly generate MP or Combo, preventing time skill from becoming a compounding resource faucet.

## 7. Curated scenario contract

Automated scenario tests use curated states to detect obvious strict dominance or impossible states. They are not a substitute for human fun/balance evidence.

| Scenario | Rational candidate set | Purpose |
|---|---|---|
| Light hit + scarce resources | ATK T1 / DEF T1 | low-tier efficiency survives |
| Light hit + heavy next Forecast | DEF T2 Fortify / ATK T5 Suppressive Break if affordable / low-tier response + preserve Combo | future direct-hit value matters without making current defense mandatory |
| Heavy direct hit | DEF T3 Counter / DEF T4 Bulwark / lethal ATK | counter vs safety vs race |
| Current MP/Combo loss Telegraph | DEF T5 Rift Ward / pre-spend threatened resource | current protection vs consume-before-loss; SUP T5 does not answer the current effect |
| Current Light + visible next resource-loss/repair Forecast | SUP T5 Rift Seal / low-tier current response + preserve Combo | proactive control of a visible future Rift utility action |
| Enemy Repair as current Telegraph | ATK T3 Breach / ATK T4 burst / SUP T4 setup | immediate damage vs future offense; Rift Seal does not retroactively stop current Repair |
| Lethal Siege Charge | DEF T4 / DEF T6 / conditional ATK T6 kill | high-Tier moment without single answer |
| Low-pressure setup window | ATK T3 / SUP T2 / SUP T3 / SUP T6 / preserve | setup may beat raw Tier |
| Synthetic multi-target future case | ATK T2 Sweeping Cut | AoE schema remains useful without first-Slice mob expansion |

A tuning seed FAILS if its numbers make every candidate except the highest affordable Tier obviously irrational in these fixtures.

### Current vs future control rule

- **DEF T5 Rift Ward** answers the current visible resource-loss Telegraph during this turn's Enemy Resolve.
- **ATK T5 Suppressive Break** may bind WEAKEN only to a visible next direct-hit Forecast.
- **SUP T5 Rift Seal** may bind Seal only to a visible next resource-loss/repair Forecast.
- Forecast control never waits invisibly for an unknown future action or jumps to another action if its bound forecast becomes invalid.

This boundary keeps current survival/protection in DEF while ATK/SUP trade immediate output for visible future control.

## 8. Encounter integration

Gatebreaker authored intent ladder must expose multiple economic questions over one complete battle:

- **Light:** spend little or invest in setup / visible next-Forecast control.
- **Heavy:** spend for mitigation/counter or race lethal.
- **Current resource loss:** protect with Rift Ward or pre-spend.
- **Visible future resource-loss/repair Forecast:** spend now for Rift Seal setup or preserve Combo for another answer.
- **Current Repair:** use immediate damage or future offense setup.
- **Siege/lethal:** peak survival or kill-before-resolve.
- **Low-pressure window:** invest in next-turn preparation.

Enemy behavior remains authored. It never reads the chosen player Technique and secretly swaps the already-telegraphed current action or silently changes a visible forecast-bound status target.

## 9. First-run teaching contract

- Do not explain all 18 Techniques in a catalog.
- Combo availability naturally exposes the lower part of the grid first.
- When a new role becomes materially relevant, short tags/highlights may explain `효율 / 범위 / 설치 / 반격 / 자원보호 / 다음행동 / 피니셔`.
- Forecast-targeted controls visibly identify which Next Forecast they affect; without a qualifying visible Forecast their control component is clearly non-applicable.
- Tutorial hints do not secretly pause the Shared Player Turn Budget; only System Pause does.
- The first 2–3 turns do not use “reach Tier 6” as the tutorial objective.
- A player should learn `higher Tier = more commitment / different use`, not `higher Tier = upgrade unlocked`.

## 10. Telemetry contract

Record per turn/action:

- MP at encounter start / after LINE / before and after an MP lock / before and after Technique use;
- Combo at encounter start / after CHAIN resolution / before and after Technique use;
- Combo gain lost at cap;
- highest available Tier;
- selected lane/Tier/Technique;
- whether the highest available Tier was selected;
- current Intent and next Forecast category/action id;
- forecast action id bound by a future-control status;
- player/enemy HP;
- overkill;
- prevented damage / counter damage;
- threatened resource pre-spent or protected;
- setup status created/consumed/expired-untriggered;
- PASS / timeout / Board Break;
- first turn each Tier became available;
- first turn each Tier was selected.

Derived review metrics:

- highest-available-Tier pick rate;
- lower-tier unused rate;
- Combo carried distribution;
- Combo-cap waste;
- MP surplus/shortage distribution;
- Intent→response diversity;
- conditional T6 use when condition is false;
- future-control pick rate when no qualifying visible Forecast exists.

## 11. Simulation Reality Gate

### Automated simulation may claim

- a resource state has zero legal actions;
- a cost curve creates obvious strict dominance under the curated scenario utility assumptions;
- Combo cap overflow or persistent resource starvation/surplus occurs under seeded runs;
- deterministic seeds reproduce availability and spending outcomes;
- forecast-bound statuses stay attached to the exact visible action id and never migrate to hidden future actions.

### Automated simulation may not claim

- the decision is fun;
- the player understands why a lower Tier is good;
- Telegraph/readability is sufficient;
- future-control target presentation is visually understandable;
- the final MP/Combo/effect/Turn-time numbers are balanced.

Human evidence remains mandatory for those claims.

## 12. Human evidence gate

Minimum A/B/C production runs ask:

1. Can the player explain **why they did not choose the highest available Tier** using Intent/resources/future plan?
2. Does LINE matter because MP matters, and CHAIN matter because Combo/Tier option value matters?
3. Does the player always hoard to 6 or always dump Combo immediately?
4. Can the player explain that an MP lock preserves a failed CHAIN setup without falsely awarding Combo?
5. Do low tiers remain practical beyond onboarding through efficiency, finishing, or preservation?
6. Do Siphon/Fracture create `spend now vs protect` decisions rather than pure frustration?
7. Can the player distinguish `current Rift Ward` from `future Rift Seal / Suppressive Break` without reading a long tooltip?
8. Is T6 memorable as a signature commitment rather than routine housekeeping?

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
- adding extra enemies merely to validate AoE;
- hidden future-control targets that are not already visible to the player.

## 14. Five-pass adversarial review

1. **Tier-6 hoarding:** corrected with cap pressure, resource-loss threats, now-vs-later Intents, and specialized rather than universal T6.
2. **Low-tier spam:** corrected by Heavy/Repair/Siege and setup/control opportunities where mid/high Tier has unique purpose.
3. **One puzzle becomes optional:** prevented by keeping MP and Combo non-substitutable gates while allowing only the explicit MP lock board-shaping spend.
4. **Lane/control overlap:** final audit found current Rift Ward and future Rift Seal could read as the same response. Corrected by binding DEF T5 to the current Telegraph and ATK/SUP future control to exact visible Next Forecast action ids.
5. **False precision / scope:** only structural costs, relative seed, scenarios and evidence requirements are locked; exact values remain TUNE_REQUIRED and no extra mob/currency/cooldown system is added.

`CLEAN_REVIEW_EXIT` for economy/tier-exposure structure after forecast-control clarification.

## 15. Implementation Reality Gate

Current claims allowed:

- dual-resource role split is documented;
- Tier-exposure and anti-dominance validation contract is specified;
- current-vs-future forecast-control ownership is specified;
- first-run/encounter scenario requirements are defined;
- exact numeric values are intentionally not final.

Current claims forbidden:

- final MP/Combo economy balanced;
- Tier pick distribution proven;
- T6 frequency validated;
- future-control readability proven;
- human lower-tier viability proven;
- production economy runtime implemented.

Production BUILD remains deferred until explicit `기획 완료 / BUILD 진행` authorization or equivalent.
