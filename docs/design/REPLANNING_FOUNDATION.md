# Puzzle combat replanning foundation

## 1. Authority and status

- Decision: `TETRIS-REPLAN-043`, direction approved in the current conversation on 2026-09-10: replan from the dual-puzzle resource-to-boss-skill core, evaluate existing elements through research, and proceed with the recommended role-clarity direction.
- State: `RESEARCHED`; candidate rules below are `SPECIFIED_FOR_COMPARATIVE_PROTOTYPE`, not final gameplay approval or implementation evidence.
- This file owns the new design direction, comparison and production order. Existing combat/skill/CHAIN contracts continue to describe the unchanged playable baseline. They do not silently constrain the new design.
- Comparison source: completed main `b3a0975d2586dc093d3a3929a426bdcd7e4f3575`, inspected 2026-09-10. Re-read latest main and PR overlap before implementation; this SHA is evidence, not permanent execution authority.
- Existing images and visual locks are `REFERENCE_ONLY_FOR_REPLANNING`. Preserve runtime-bound assets and original manifests until approved replacements have verified consumers. Do not impose parchment, pixel art, earlier title art or earlier composition as the new visual decision.
- Retain the installed Base 9.4.4 adapter/version lock. Current Base research, production and review methods supplement this task without replacing the adapter.
- The existing Human Blueprint PDF is a preserved **baseline-derived artifact**, not a blueprint of this proposal. A new derived reader PDF follows coherent screen/rule/asset specifications and render review.
- Excluded now: replacing runtime rules/assets, deleting old PRs or assets, release approval, paid tools, claiming player-tested fun or globally unique mechanics.

## 2. Current implementation and the problem to solve

The current game already has persistent LINE/CHAIN boards, manual switching, a continuous enemy ETA, a full tactical pause, an atomic skill confirmation, three skill categories and thirty Combo-stage entries. LINE has a seven-bag, HOLD, ghost and input tuning. CHAIN supports orthogonal swaps and straight horizontal, vertical and diagonal matches. These are reusable implementation facts, not missing features to rebuild.

Current resource rules are LINE MP 10/22/36/52, MP cap 60, Combo cap 10, and CHAIN MP recovery based on matches plus post-wave Combo. Current Combo determines technique identity as well as recovery and shortage conversion. The resolver can select a lower affordable stage by converting surplus Combo at 5 MP per stage. A cascade can therefore change *what* a selected category does, not merely its strength. This is a design risk, not demonstrated player confusion: Human evidence is still NOT_RUN.

Actual comparison owners:

- `data/production/vanguard_skill_seed.json`, `line_reward_seed.json`, `chain_runtime_seed.json`.
- `src/production/skill/production_skill_session.gd` and the technique catalog/resolver/effect executor.
- `src/production/chain/chain_board.gd`, CHAIN resolver/session; LINE piece cycle and active tetromino.
- `src/production/runtime/` scheduling, pause, board opportunity and workspace owners.
- `scenes/production/battle.tscn`, `src/production/ui/`: image consumers and battle interaction.

The stored, capped LINE-only board-opportunity reserve already exists. It stops LINE gravity/lock, not enemy ETA. Do not rebrand it as a newly invented shared timer or turn budget.

## 3. Research and adoption ledger

Source inspection: 2026-09-10. Official descriptions demonstrate published mechanics, not our hands-on tests or a causal improvement in enjoyment. Store reviews are self-selected qualitative leads, not representative evidence. No interviews or full conference-video viewing are claimed.

| Primary source | Observed pattern | Disposition and project-specific use |
| --- | --- | --- |
| [Tetris Effect](https://www.tetriseffect.game/) | Zone and synchronized audiovisual feedback give clearing a distinct payoff | ADAPT: make a successful clear readable and consequential; REJECT a copied Zone or art direction |
| [Puyo Puyo Tetris 2 rules](https://puyo.sega.jp/puyopuyotetris2/rule.html) | Multiple puzzle rules, switching and HP/MP skill combat already have precedents | ADAPT: teach each puzzle's role; REJECT forced timed swap and claims that the combination alone is novel |
| [Grindstone](https://store.steampowered.com/app/1818690/Grindstone/) | Puzzle planning connects to combat, equipment and hazards | ADAPT: readable planning-to-impact feedback; do not replace our swap grammar with its path system |
| [Clash of Heroes](https://store.steampowered.com/app/2213300/) | Puzzle formations prepare combat outcomes | ADAPT: show preparation and consequence; defer formation-based attacks as a different core |
| [Into the Breach](https://store.steampowered.com/app/590380/Into_the_Breach/) | Forecast attacks allow deliberate responses | ADOPT the forecast principle; ADAPT to continuous ETA, not its turn system |
| [FTL](https://store.steampowered.com/app/212680/FTL_Faster_Than_Light/) | Pausable real-time decisions | ADAPT: keep tactical pause and inspectable threats; no reflex-only skill menu |
| [Slay the Spire](https://store.steampowered.com/app/646570/Slay_the_Spire/) | Synergies create distinct builds | ADAPT: a small number of legible technique purposes first; defer large progression/content multiplication |
| [Shogun Showdown](https://store.steampowered.com/app/2084000/Shogun_Showdown/) | Preparation and timing give actions strategic weight | ADAPT anticipation and recovery readability; REJECT silently importing positional turn rules |
| [Wildfrost press kit](https://www.wildfrostgame.com/presskit/) | Counter timing and manipulation matter | ADAPT explicit target/time previews; retain exact ETA semantics instead of new ambiguous time currencies |
| [SpellRogue](https://store.steampowered.com/app/1990110/SpellRogue/) | Random inputs can be manipulated into spell plans | ADAPT understandable preparation/control; defer more reroll/split currencies |
| [Puzzle Quest 3](https://store.steampowered.com/app/1380410/Puzzle_Quest_3/) | Match combat plus equipment/progression | ADAPT clear combat feedback; REJECT treating menu/currency expansion as inherently deeper gameplay |

Professional implementation references:

- [Riot gameplay clarity](https://www.riotgames.com/en/news/valorant-shaders-and-gameplay-clarity): ADAPT effects hierarchy and readable gameplay signals, not its genre-specific frame-rate target.
- [Xbox accessibility guideline 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103): ADOPT redundant shape/text signals; tile color alone must not convey meaning. This is a design requirement, not accessibility certification.
- [GDC metrics session description](https://www.gdcvault.com/play/1025731/-Slay-the-Spire-Metrics): ADAPT measured iteration with player feedback. Public abstract read; full session NOT_VIEWED.
- [Aseprite sprite sheets](https://www.aseprite.org/docs/sprite-sheet/): ADAPT source-to-sheet packaging when frame animation is required, not mandatory pixel styling.

## 4. SWOT, alternatives and originality

| Lens | Finding | Response |
| --- | --- | --- |
| Strength | Deterministic owners, persistent boards and atomic confirmation already exist | Reuse them as a stable comparison fixture |
| Weakness | Combo carries several meanings; thirty stages enlarge explanation and asset scope | Stabilize technique purpose and reduce the first experiment's surface |
| Opportunity | Both puzzles can have distinct preparation roles against visible boss threats | Test preparation → choice → response as the game's signature |
| Threat | Mandatory switching can feel like upkeep; two puzzle audiences may have different strengths | Measure forced switches, inactive-board neglect and threat comprehension |

| Alternative | Player value | Risk / cost / reversibility | Decision |
| --- | --- | --- | --- |
| A: unchanged economy, clearer preview and feedback | Lowest learning disruption; fastest baseline improvement | Preserves Combo purpose shifts; low implementation cost, easy rollback | RETAIN as control |
| B: LINE prepares MP, CHAIN prepares optional amplification; stable skills | Explains why each board exists and lets timing be a choice | CHAIN could become optional or compulsory busywork; moderate change, isolate behind a prototype fixture | ADAPT / recommended prototype |
| C: block shapes and chain formations directly author attacks | Stronger spatial expression | Rewrites both puzzle-to-combat bridges, adds recognition and balance burden; difficult rollback | DEFER, not rejected forever |

Originality hypothesis: voluntary switching between two persistent preparation spaces, followed by an explicit response to the same boss forecast, can create a recognizable rhythm. None of these components alone is claimed novel. Distinction must be demonstrated by player decisions and audiovisual identity, not a larger mechanic list.

## 5. Candidate B: bounded playable specification

### Preserved comparison controls

Retain board sizes, piece generator, HOLD/ghost, current CHAIN matcher, safe-boundary switching, MP cap 60, Combo cap 10, continuous scheduling and tactical pause for the first experiment. Keep existing failed-swap policy as a named control condition; assess diagonal matching and failure penalties separately. Do not change puzzle grammar, economy, art and boss difficulty together and then attribute results to one change.

### Resource and confirmation contract

| Element | Current baseline | Candidate B trial |
| --- | --- | --- |
| LINE clear | MP 10/22/36/52 | Keep those values initially to isolate the resource-role change |
| CHAIN resolved wave | Combo +1 and MP recovery | Combo +1 only; no CHAIN MP recovery in this fixture |
| Combo use | Changes category technique and supports shortage conversion | Optional amplification of the same technique; no technique substitution |
| Skill cost | Stage data and fallback | Initial trial: 10 MP base; 10 MP + 2 Combo amplified; no automatic conversion |
| Low MP | May fall back to another stage | Explain exact shortage and disable CONFIRM; never silently change effect |
| Amplification | Implicit current stage | Explicit BASE / AMPLIFIED preview; BASE remains available at high Combo |

These are test seeds, not approved balance. At zero Combo a base skill remains usable with sufficient MP; amplification must offer relevant utility without making it obligatory. At insufficient Combo only amplification is unavailable. Cancel spends nothing. Confirm validates resource, target and encounter state again, then commits once. UI previews and animation callbacks cannot spend resources or apply effects independently.

### First three technique purposes

Working labels only; no final name, icon style or job roster is locked.

| Category | Base purpose | Amplified purpose | Required preview |
| --- | --- | --- | --- |
| ATK / Strike | Direct boss damage D | Same target and damage purpose, trial 1.5 × D | Damage estimate, cost, target, selected mode |
| DEF / Ward | Absorb S damage from the identified next damaging action | Same action, trial 1.5 × S | Bound action ID, estimated prevented damage, expiry/invalid-target behavior |
| SUP / Recover | Restore H missing HP | Same healing purpose, trial 1.5 × H | Effective heal after HP cap, cost; no concealed time effect |

D/S/H must come from a recorded comparison encounter's damage budget before a runtime fixture is declared ready. Ratios above are explicit hypotheses, not measured tuning. A second family per category can be considered after the three-purpose test, not six simultaneous mandatory buttons or an unapproved loadout system.

Ward does not become a permanent stacking shield: one active reservation, bound to the named forecast action; preview warns before replacement. Non-damaging actions are not valid Ward targets. Cancellation/replacement of the enemy action must resolve the reservation deterministically and visibly; the prototype must specify a refund policy before implementing that branch. No free repeated shield farming or ambiguous effect carryover.

### Example, not a runtime claim

With 20 MP and 2 Combo, the player sees an incoming damaging action, pauses, selects Ward and compares base versus amplified prevention. BASE costs 10 MP and preserves 2 Combo; AMPLIFIED costs 10 MP and 2 Combo. Cancel preserves all resources. After a valid confirm, the same action ID and chosen resource delta appear in the receipt and effect log. Raising Combo must never turn Ward into a different technique.

## 6. Boss, interface, images and motion are one production chain

The retained comparison layout is one visible puzzle and a boss/threat/resource/skill region. Earlier 50:50 layouts remain comparison fixtures, not final new-screen approval. Preserve a single visible shared ETA meaning: remaining time to the forecast boss action, not an invented player-turn duration.

| Visual requirement | Existing consumer / proposed use | Required states and motion | Readiness |
| --- | --- | --- | --- |
| Player face portrait | VanguardPortrait HUD slot; no full-body art requirement from this consumer | Neutral, damage response; face readable at actual HUD size | BRIEF_PENDING_STYLE |
| Boss silhouette and action | GatebreakerReference comparison slot, future dedicated action presenter | Idle → anticipation → contact → recovery; hurt/death independently authored | BRIEF_PENDING_STYLE_AND_ACTION_TIMING |
| LINE/CHAIN tiles | Existing board views | Normal, focus/selection, invalid, resolving/clear; redundant glyphs | BRIEF_PENDING_STYLE |
| Three skill-family icons | Technique preview/category surface | Normal/selected/disabled plus non-color amplification marker; reuse icon identity | BRIEF_PENDING_STYLE |
| Threat/ETA feedback | Scheduler-driven battle UI | Current/next, imminent, paused, resolved; no animation-only timing truth | FEASIBLE_FROM_EXISTING_OWNER |

New images must be generated by the image model after the visual brief selects a direction; do not substitute primitives or generated vector drawings for art. Existing references may inform readability and hierarchy without copying their characters or locking their medium.

Aseprite automatic selection is a task choice, not a demand that every image be pixel art. Use it for candidate frame assembly, consistent canvas/pivots, duration editing, frame inspection and sheet export when animation needs those operations. Use a static portrait when the actual consumer needs only a face; do not fabricate a full-body sheet. Native local Aseprite tools were discovered and version 1.3.18.5-dev checked; Tetris candidate processing remains NOT_RUN.

For each animation brief record source hash, dimensions, frame count/durations, pivot/feet and weapon alignment, loop and transition rules, target size, import filter, source/export paths, consumer and effect event. Preparation/contact/recovery must be continuous; a fixed 4×4 grid is not mandatory. Keep original artwork, editable candidate source and exported frames separate. Candidate-only packaging is not canonical registration or runtime verification.

The simulation event applies gameplay exactly once. A presenter follows that event; frame arrival never owns damage. Pausing freezes simulation-linked motion. Reduced-motion presentation preserves the same telegraph and result. Interrupted, skipped or repeated playback cannot duplicate damage, refund, resource spend or victory transitions. Do not create a mechanical stagger window merely because the boss recoil looks convincing.

## 7. Work sequence and exit evidence

| Order | Bounded output | Exit evidence / next dependency |
| --- | --- | --- |
| 1 | This research-backed foundation and corrected entry routing | Static references, existing tooling tests, unchanged runtime/assets; does not prove fun |
| 2 | Comparative encounter specification | Record D/S/H, Ward cancellation/refund, initial board seeds, boss schedule, conditions A/B and measurement definitions; resolve core-meaning choices before runtime changes |
| 3 | Small visual-direction candidates and state briefs | Image-model candidates at real display scale; choose coherent direction before canonical replacements; no old assets deleted |
| 4 | Isolated three-purpose prototype and deterministic tests | Single-spend, pause, target invalidation, low resources, no overflow, board persistence, seeded comparison; current baseline still runnable |
| 5 | Action/portrait/tile/icon production and integration | Source/provenance/hash, Aseprite result where applicable, actual consumer and frame continuity; runtime capture |
| 6 | Human comparison, correction, full blueprint derived view | Observe comprehension and choices, revise, render/read PDF; no automatic USER_APPROVED or release PASS |

Steps 2 and 3 may prepare independently, but production cannot invent a final style or rule while their decisions remain open. Implementation planning is written after the comparative specification, rather than presenting this research brief as executable code instructions.

Evaluation protocol: use the same deterministic board seeds and boss schedule for A/B, alternate first-play order, log skill purpose prediction before confirm, cancels, forced switches, time spent per board, amplification choices and failure reason. Ask what the player expected and why they switched. Small qualitative samples produce findings, not statistical proof. Set trial success/failure thresholds in the encounter specification before collecting data. Reject B if clearer wording still leads to compulsory maintenance switching or one board is consistently irrelevant; revisit A or a narrower hybrid.

## 8. Change register and evidence ceiling

| Disposition | Element | Reason / expected effect |
| --- | --- | --- |
| KEEP | Deterministic scheduling, atomic confirm, persistent boards, pause | Reduce regression and preserve comparison integrity |
| CHANGE_CANDIDATE | Combo semantics, resource overlap, shortage fallback | Make skill purpose predictable and spending intentional |
| ADD_CANDIDATE | Explicit amplification, event-bound motion and comparative metrics | Link preparation, choice and visible consequence |
| DEFER | Thirty new skill illustrations, job expansion, progression, shape-authored attacks | Avoid content multiplication before the core earns it |
| REFERENCE_ONLY | Existing visual locks, images and old PDF for new design | Permit a genuine restart without damaging the running baseline |
| REMOVE_CANDIDATE | Hidden technique substitution in candidate B only | Eliminate unexpected effects; no deletion from baseline in this change |

Project lesson: separate new-direction authority from still-running rules and asset consumers at the entrypoint. Base reuse: existing intake, design-document, art/state and review methods suffice; no new bridge or mandatory shared module. Base promotion is a candidate only until repeated evidence exists.

Current ceiling: research/source inspection and planning only. Prototype, new art, Aseprite processing, Godot runtime comparison, accessibility audit, performance, Human UX and release evidence are NOT_RUN. Rollback this planning change through Git; runtime and approved source binaries remain untouched.
