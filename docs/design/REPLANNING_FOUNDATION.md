# Puzzle combat replanning foundation

## 1. Authority and status

- Current continuation (2026-09-11, latest user `좋아 진행해`): begin the reviewed R2 blueprint's isolated Godot implementation. [Implementation plan and evidence](../operations/TETRIS_R2_IMPLEMENTATION.md) owns current execution progress. The production baseline and published PDF/source bytes remain preserved. Older implementation-deferred statements below describe their original design/preparation stage, not a prohibition on this explicitly resumed R2 work. Runtime, Human, balance and release approval remain separate.

- Latest approved direction (2026-09-11): [R2 automatic-cast rules](REPLANNING_AUTOCAST_R2.md) own LINE four-type resources → CHAIN per-wave automatic skill casting. User approved recommended B; numerical seeds remain untested recommendations. [Complete reader](R2_COMPLETE_HUMAN_BLUEPRINT.md), [session/asset data](r2-complete-session.json), and [complete derived PDF](../blueprints/TETRIS_R2_COMPLETE_HUMAN_BLUEPRINT.pdf) supersede the old amendment's incomplete preparation status. Final art/design approval and runtime remain separate. Production runtime and Base 9.4.4 are unchanged.

- Historical R1 publication: [reader](REPLANNING_HUMAN_BLUEPRINT.md), [preserved PDF](../blueprints/TETRIS_REPLANNED_HUMAN_BLUEPRINT.pdf), [data](blueprint-data.json), and [candidate asset provenance](../assets/reference/planned/replanning/blueprint/manifest.json). Preserve their exact publication evidence, but do not use R1 manual MP/charge rules or old R2 incomplete-status fields as current execution authority. Current R2 complete reader owns session/UI/handoff additions; R2 rules own mechanics and section10 below retains the historical comparison.

- Decision: `TETRIS-REPLAN-043`, direction approved in the current conversation on 2026-09-10: replan from the dual-puzzle resource-to-boss-skill core, evaluate existing elements through research, and proceed with the recommended role-clarity direction.
- State: `RESEARCHED`; candidate rules below are `SPECIFIED_FOR_COMPARATIVE_PROTOTYPE`, not final gameplay approval or implementation evidence.
- Latest direction (2026-09-10): the user explicitly defers implementation and delegates detailed design/research decisions. Continue with [Detailed rules, fun and originality](REPLANNING_RULES_AND_FUN_SPEC.md). Godot connectivity is not a gate for this design-only work. The new detail owns recommended post-comparison changes; section10 still owns the unchanged v0.1 A/B control fixture.
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

Aseprite automatic selection is a task choice, not a demand that every image be pixel art. Use it for candidate frame assembly, consistent canvas/pivots, duration editing, frame inspection and sheet export when animation needs those operations. Use a static portrait when the actual consumer needs only a face; do not fabricate a full-body sheet. Native local Aseprite tools were discovered and version 1.3.18.5-dev checked. Subsequent section 9 records the completed static-neutral candidate roundtrip; authored animation and Godot playback remain NOT_RUN.

For each animation brief record source hash, dimensions, frame count/durations, pivot/feet and weapon alignment, loop and transition rules, target size, import filter, source/export paths, consumer and effect event. Preparation/contact/recovery must be continuous; a fixed 4×4 grid is not mandatory. Keep original artwork, editable candidate source and exported frames separate. Candidate-only packaging is not canonical registration or runtime verification.

The simulation event applies gameplay exactly once. A presenter follows that event; frame arrival never owns damage. Pausing freezes simulation-linked motion. Reduced-motion presentation preserves the same telegraph and result. Interrupted, skipped or repeated playback cannot duplicate damage, refund, resource spend or victory transitions. Do not create a mechanical stagger window merely because the boss recoil looks convincing.

## 7. Work sequence and exit evidence

Current execution override: design-only research and detailed rules come first under the latest user instruction. The table below remains the eventual production dependency order, not authorization to resume implementation now. See the linked detail for recommended rules, unresolved experiential questions and production deferrals.

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
| REMOVE_CANDIDATE | Combo-dependent technique substitution and shortage fallback in candidate B only | Keep technique purpose stable; baseline already previews the selected effect and conversion before CONFIRM, so this is not a claim that it hides the executed effect |

Project lesson: separate new-direction authority from still-running rules and asset consumers at the entrypoint. Base reuse: existing intake, design-document, art/state and review methods suffice; no new bridge or mandatory shared module. Base promotion is a candidate only until repeated evidence exists.

Initial foundation milestone ceiling (before section 9's continued preparation): research/source inspection and planning only; new art and Aseprite processing were NOT_RUN at that milestone. Current candidate-specific evidence is in section 9 and its manifest. Prototype, Godot runtime comparison, accessibility audit, performance, Human UX and release evidence remain NOT_RUN. Rollback this planning change through Git; runtime and approved source binaries remain untouched.

## 9. Continued preparation: portrait direction experiment

User continuation after foundation publication authorizes encounter specification and bounded visual candidates, not a final art style or live replacement. The earlier ceiling above records the foundation milestone; this section and the linked preparation receipt record the subsequent work.

Requirement `REPLAN-VR-PORTRAIT-01`, P1 IDENTITY / EMOTIONAL, `PLANNED_GAME_SURFACE`: a new neutral face-first portrait for the existing battle HUD slot `scenes/production/battle.tscn::MainRow/CombatColumn/ResourceFrame/ResourceRow/VanguardPortrait`. Current minimum display is 128x96; future comparison also uses a square 96x96 face area with no additional full-body requirement. Texture2D, linear filtering for illustrated candidates, no mipmaps at fixed HUD scale, no baked UI text/frame. The existing atlas and image stay unchanged.

Delete test: without a new face-scale trial, choosing a global style from large full-body illustrations repeats the known unreadable-HUD risk. Reuse assessment: old images serve the baseline but do not answer the user's request to make new art. This is one named portrait requirement with three meaningful alternatives, not a general asset-production batch.

Shared candidate brief: original adult male frontier defender, dark tousled hair, clear eyes and eyebrows, restrained dark armor collar and short mantle, calm determined neutral expression. Head and upper shoulders only, near-front slight three-quarter view, face large and unobscured, complete hair silhouette with safe outer margin, no weapon, no text, no ornate frame or background scene. Genuine transparent background requested. General defender role is reused; the old exact face, armor ornament and portrait crop are not copied or newly locked.

Compare A: clean anime cel shading (broad light/shadow, clear contours); B: painterly anime (soft material modeling, restrained texture); C: graphic ink-and-flat-color anime (strong shape hierarchy, little texture). These are visual candidates, not three new characters or final identities. Once A exists, B/C use that candidate as an identity anchor so the comparison primarily changes rendering language. A is the initial technical recommendation for HUD readability and repeatable expressions, subject to actual output review.

Coverage: battle neutral portrait REQUIREMENT_LINKED; damage/terminal expressions remain a later state-family requirement, not hidden completed work. Title/briefing/result screens, boss, tiles and skill icons are outside this first portrait generation batch; their planned needs remain in section 6. Aseprite is evaluated for a non-destructive editable neutral source and export inspection, not to manufacture animation by repeating one frame. New creative pixels come from the image model only. No per-candidate generation approval is requested under the project standing approval. Promotion and runtime proof remain separate.

Preparation result: [three named candidates and provenance](../assets/reference/planned/replanning/portrait-candidates.json), [static size-comparison view](../assets/reference/planned/replanning/portrait-comparison.html). A has real alpha and a pixel-identical Aseprite roundtrip; its 18px head-top margin still needs framing review. B/C retain painted checkerboards after two failed repair attempts and are **style comparison only**, never production-ready. The viewer opened and its content was checked, but an actual 96px screenshot audit and Human preference test are NOT_RUN. No final style or replacement approval is inferred.

## 10. Comparative encounter specification v0.1

Status: `SPECIFIED_FOR_COMPARATIVE_PROTOTYPE`, not a production balance lock. This completes the numerical and edge-case preparation requested after the foundation. The prototype implementation is still a separate, isolated change; no production seed files are edited by this specification.

Within this experimental v0.1 only, the numerical seeds and no-replacement Ward lifecycle below supersede section 5's earlier open D/S/H and replacement-warning exploration. Section 5 remains the direction/rationale, not a second implementation authority.

### Conditions and reproducibility

Compare **A: current mechanics package** against **B: section 5 stable-purpose package**. Keep the same old art, UI geometry, input bindings and explanation duration during gameplay testing; do not use the new portrait variants in the A/B gameplay experiment. A retains current thirty-stage data, CHAIN MP reward, failed-swap rules, pause and previewed fallback. B changes the economy/skill package only. This experiment cannot attribute a result separately to amplification, MP recovery removal or stable identity; a later ablation is needed for that claim.

Initial fixture for both: player HP/maxHP 100/100, enemy HP/maxHP 100/100, MP 20, Combo 2; LINE active, empty 10x20 visible board plus existing 4 hidden rows, HOLD empty and unused, current generator seed 20260826. CHAIN uses existing 8x8 six-color playable-board generator seed 54321. Preserve the generator implementation and record its Git revision, both actual initial board arrays, active/HOLD/NEXT pieces and RNG state in every trial receipt. Equal seed values across different engine/generator versions alone do not prove equal boards. Compare identical initial-state hashes before accepting a pair.

Use six authored forecast entries: `light_smash` 8s, `gatebreaker_slam` 12s, `light_smash` 8s, `gatebreaker_slam` 12s, `light_smash` 8s, `gatebreaker_slam` 12s. Damage is the existing 12%/35% of maxHP: 12 and 35 at maxHP100. Assign unique instance IDs `trial-<run>-action-1..6`, not merely action names. Freeze authored phase at phase1 for this comparison; reject unexpected phase/director overrides. Keep the current scheduler's commit ordering and pause behavior. Current and next are visible. No first-session 45-second override or nonterminal guard during the measured fixture; preparation uses the same unscored practice allowance in both conditions.

The undelayed schedule totals 60 active simulation seconds and 141 incoming damage. Actual deadlines may change through A's legal time effects; this is part of the package, not a broken matched pair. End measured encounter on victory/defeat or resolution of entry6. If neither side is terminal at entry6, label `OBSERVATION_COMPLETE`, not player victory. Add a 180-active-second observation cap for delay-heavy behavior; manual and tactical pause do not advance it. This is research session termination, not a new gameplay turn budget or defeat rule.

Terminal forecast boundary: the existing telegraph requires a valid next action, so the isolated fixture supplies a seventh forecast-only `light_smash` guard (8s, unique instance ID) in both conditions. At entry6, render Next as `END OF OBSERVATION`, not a promise of another scored attack. After entry6 resolves, stop the fixture before scheduler advancement; guard7 must never commit, deal damage, receive a Ward or be counted in the six-entry/60-second total. Do not alter the production scheduler to implement this research-only termination. Verify both terminal-by-HP and observation-complete paths, including same-frame input, against zero guard7 commits.

### B numerical seeds and resource edges

Set D=20, S=20, H=14. Amplified values are 30,30,21 respectively. These values are deliberately simple trial hypotheses derived around the baseline 35-damage heavy hit, not imported competitor balance. Ward prevents more than Recover restores (20 versus14) because it must be committed before a valid damaging action; Strike20 requires five base casts to defeat the 100-HP comparison boss. Two resolved CHAIN waves buy +10 Strike damage, +10 Ward capacity or +7 Recover healing. Measure whether this benefit justifies the actual time spent on CHAIN rather than assuming it does.

Base cost is 10MP; amplified cost is 10MP+2Combo. No combo-to-MP conversion, no lower-technique substitution. LINE rewards and caps remain unchanged; each valid CHAIN resolution wave grants Combo+1 without MP. Failed swap retains the existing default restore/reset-Combo or 1-MP keep/reset-Combo behavior, and must be disclosed in practice. At cap, clamp; log actual gain and overflow separately. At full HP disable Recover with `NO_MISSING_HP`; when partly injured show actual capped healing before confirming. Strike requires a live target. Inputs with negative/non-integer costs, missing target or stale preview revision fail without spending.

### Ward reservation lifecycle

Ward may target **the currently visible, uncommitted damaging action only**, not an unseen future action or a non-damaging current action. Its absorption is min(capacity, resolved incoming direct damage); excess capacity expires. It never stacks across actions.

Once a Ward is committed, a second Ward is disabled with `WARD_ALREADY_RESERVED` until resolution/cancellation; BASE cannot be repeatedly refunded and upgraded. This deliberately replaces the section5 exploratory replacement warning with a simpler no-replacement rule for v0.1. Opening/canceling Skill does not cancel an already committed Ward.

If the scheduler cancels/replaces the bound action **before commit**, expire its Ward and refund the exact paid MP/Combo once, subject to the usual caps; show refund and any overflow. Store receipt ID and consumed/refunded terminal state, preventing repeated refund events. A delayed action retaining the same instance ID keeps the Ward without refund. Once enemy action commit occurs, no cancellation refund is possible. On encounter victory/defeat dispose the reservation without refund or carryover; resources are encounter-local. Invalidating a target between preview and player confirmation spends nothing. A resolver failure restores the complete pre-transaction checkpoint; it is not a gameplay refund and cannot issue a second refund event.

### Hand-checkable expectations

| Scenario | Expected result in B |
| --- | --- |
| Strike BASE, MP20/Combo2, enemyHP100 | MP10/Combo2/enemyHP80 |
| Strike AMPLIFIED, same initial state | MP10/Combo0/enemyHP70 |
| Ward BASE against heavy35 | Damage15; 20 absorbed; reservation consumed once |
| Ward AMPLIFIED against heavy35 | Damage5; 30 absorbed; reservation consumed once |
| Ward AMPLIFIED against light12 | Damage0; 12 absorbed; 18 unused capacity expires |
| Recover BASE at HP93 | Effective heal7, HP100; full cost10MP shown before confirm |
| Amplified at MP9 or Combo1 | Disabled; no spend and no substitute technique |
| Bound action canceled pre-commit after amplified Ward | Exact paid10MP+2Combo refund once, clamped with overflow logged |
| Animation skipped/replayed or focus lost | No extra damage, spend or refund; pause ordering unchanged |

### Evaluation and decision rule

Start with three independent first-exposure participants following the project's existing Human-evidence ceiling. Each receives the same explanation and a maximum 90-second unscored practice per condition; record actual time. Alternate A→B and B→A order (2/1 split); report the imbalance and learning effect, not population significance. Use a later fresh cohort if order changes the conclusion. These are proposed observations; no recruitment or Human PASS is claimed now.

Before first CONFIRM in each category ask the participant to state target, expected purpose and cost. Record assistance and correctness; do not teach the answer during the scored probe. Log switches and their reason, per-board active time, paused decision time, MP/Combo gains/spends, amplified/base choices, fallback in A, canceled previews and actual result. Ask whether switching served a plan or merely paid an obligatory fee. A switch alone is not evidence of strategic value; ignoring CHAIN alone is not evidence that the player misunderstood it.

For this small first-direction gate, require all three participants to identify the purpose and resource roles after the common explanation without corrective coaching, at least two to voluntarily use both boards and explain a distinct useful reason, and no observed case where a participant cannot understand the final selected effect after preview. Any duplicated effect/refund, state corruption, timer ambiguity or mismatch of paired initial-state hashes invalidates that session. If the role-clarity criteria fail, keep B experimental and revise; do not average away a severe failure. If they pass, mark only `DIRECTIONAL_SIGNAL`, not final balance, accessibility, commercial originality or release approval. A's comparison outcomes and preference reasons must still be reported, including evidence favoring A.

## 11. Implementation and motion handoff boundary

Feasibility is `PARTIAL`: the existing bootstrap, session checkpoint/atomic commit, scheduler and effect executors supply reusable primitives, but the B resource bridge, explicit amplification and Ward reservation/refund require an isolated implementation and tests. Do not turn PARTIAL into IMPLEMENTED by adding this document.

Proposed bounded implementation ownership: a separate comparison bootstrap/scene and experiment config, reusing the existing board/scheduler interfaces; a B-only skill policy and reservation object; no save migration and no modification of production default entry. Log condition and source revision in telemetry. Tests must cover every row above plus same-frame deadline/Skill-open, caps, failed-swap and inactive-board persistence. A comparison selector belongs only to the development experiment, not the shipping menu. Do not add an addon, service or universal combat framework for this fixture.

Motion contract for later production: boss idle → readable preparation during the current forecast → commit-driven contact → recovery; blocked hit, unblocked hit and death follow the actual resolved event. HP, resources and victory belong to simulation, not frame arrival. Portrait damage reaction is optional presentation and cannot imply stun. Pause freezes simulation-linked playback, while UI navigation remains active. Use an unanimated but truthful fallback on missing art. Key poses are reviewed before inbetweens; record pivot/crop/weapon continuity and effect-off checks. Duration tuning remains tied to the chosen action presenter, not guessed from a generated pose sheet.

Current official sources inspected 2026-09-10: [Godot sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html) establishes separate-frame/sheet playback options (ADAPT, no import/runtime claim); [Aseprite CLI](https://www.aseprite.org/docs/cli/) supports source/export metadata workflows (ADAPT existing native candidate tools; no new CLI bridge); [GDC animation session description](https://www.gdcvault.com/play/1021657/Powerful-and-Effective-Animation-for) informs anticipation and timing under gameplay constraints (ADAPT; full video NOT_VIEWED). Motion direction and final portrait style still require visual evaluation, not automatic acceptance from these sources.
