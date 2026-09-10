# Detailed rules, fun and originality — design-only recommendation

## 1. Authority, scope and decision

Parent owner: [REPLANNING_FOUNDATION](REPLANNING_FOUNDATION.md), REPLAN-043. Latest user instruction on2026-09-10: implementation later; research, benchmark and choose recommended detailed rules, including fun and originality. This document is `RESEARCHED / SPECIFIED_DESIGN_RECOMMENDATION`, not implemented gameplay, final balance, proven fun or final user acceptance. The baseline and foundation section10's controlled v0.1 A/B fixture remain unchanged. Changes below belong to **recommended design pack R1**, which must never be silently substituted for that fixture.

Source: completed main56a7b9e75f3c4f4754b6ad1b64c37390a4c60c50, checked2026-09-10. Existing open Draft PR19/23/33/46/85/100 remain read-only; this work does not absorb them. PR100's editor-connection blocker does not block planning. No Godot launch, gameplay modification, image replacement, saved-data migration, new service or Base migration is part of this instruction.

**Recommendation:** retain two persistent preparation boards and a visible boss deadline; make skill purposes stable; deepen encounters through readable threat patterns and the opportunity cost of spending existing resources. Simplify punitive or ambiguous rules before adding another currency, timer, skill tier or progression system.

The reader should be able to explain the game as: *prepare power in one puzzle, prepare amplification in the other, and spend either now or save it for the next visible threat*. This is a design intention, not a measured description of player behavior.

## 2. Research ledger and evidence limits

Pages below were inspected2026-09-10. Developer/publisher descriptions establish features, not our hands-on experience or causal proof of enjoyment. Practitioner essays are design arguments, not controlled studies. Existing foundation section3 retains its broader eleven-game comparison; this detail adds focused reasoning rather than pretending every old entry was newly played.

| Source | What the source supports | Decision for this project |
| --- | --- | --- |
| [SEGA: Puyo Puyo Tetris2 rules](https://puyo.sega.jp/puyopuyotetris2/rule.html) | Timed puzzle switching and HP/MP skill combat are already established patterns | ADAPT role teaching and recoverable failure; REJECT forced periodic swapping and a novelty claim for hybrid puzzle combat itself |
| [Subset: Into the Breach](https://www.subsetgames.com/itb.html) | Enemy attacks are forecast so players can plan responses | ADAPT explicit threat information to continuous time; REJECT importing ordered turns |
| [Enhance: Tetris Effect](https://www.tetriseffect.game/) | Player actions drive synchronized audiovisual feedback; Zone changes time behavior | ADAPT clear-to-payoff feedback; REJECT adding another stop-time meter beside tactical pause |
| [Mega Crit: Slay the Spire press kit](https://www.megacrit.com/press-kits/slay-the-spire/) | Character-specific card sets, encounters and items support differentiated builds | ADAPT distinct play patterns as a later goal; REJECT copying a large content count before the basic loop works |
| [Mega Crit FAQ](https://www.megacrit.com/faq/) | Player feedback matters to balance and quality-of-life work | ADOPT iterative observation; do not call spreadsheet tuning validated balance |
| [Sirlin: viable options](https://www.sirlin.net/articles/balancing-multiplayer-games-part-1-definitions) | Many buttons do not imply many meaningful choices; context matters | ADAPT the dominant-strategy audit to solo PvE. REJECT treating competitive fairness as this game's objective |
| [Sirlin: subtractive design](https://www.sirlin.net/articles/subtractive-design) | Removing elements can strengthen a core experience | ADAPT removal tests for currencies, tiers and failure taxes; do not equate fewer rules with automatically better play |
| [Riot: gameplay clarity](https://www.riotgames.com/en/news/valorant-shaders-and-gameplay-clarity) | Art, gameplay readability and performance must be considered together | ADAPT threat/tile signal priority and scalable cosmetic effects; REJECT copying shooter performance targets or art |

FTL's page was initially accessible but a subsequent detailed fetch failed; no new FTL-dependent rule is justified here. No public-video viewing, player interview, commercial originality clearance or market-success prediction is claimed.

## 3. Alternatives, SWOT and the identity hypothesis

| Material alternative | Value | Main risk / long-term cost | Disposition |
| --- | --- | --- | --- |
| Shared-resource hybrid: both puzzles fund the same skills | Either puzzle can support all play; accessible preference | Faster/preferred puzzle can make the other redundant | KEEP as baseline comparator, not default R1 |
| Complementary preparation: LINE supplies MP; CHAIN supplies optional strength | Different reasons to revisit persistent boards; small skill vocabulary | Optional can become irrelevant or secretly compulsory | RECOMMEND R1; test marginal value and player reasons |
| Direct spell construction from piece shapes and chain formations | Strong spatial authorship and potentially distinct mastery | New recognition grammar, many recipes, greater art/tutorial/test burden | DEFER as a different core; no recipe system in R1 |

Strength: existing deterministic boards, explicit confirmation and pause support deliberate decisions. Weakness: switching plus two puzzle grammars can split attention; Combo currently carries several meanings. Opportunity: make *prepared board positions* part of the player's plan rather than disposable minigames. Threat: a LINE expert may win without CHAIN, while a novice may feel forced to service both boards before every action.

Identity hypothesis: **two preserved preparations against one shared threat clock**. The signature is a sequence of decisions, not a trademarked mechanic claim. A player might leave a nearly completed LINE clear, build two CHAIN waves, and return to cash in MP before a heavy attack. Another might spend immediately and accept the next hit to finish the boss. Neither route is automatically superior; their value depends on HP, enemy HP, resource caps, known next action and current board positions.

Originality test: remove either persistent workspace, the forecast, or explicit resource allocation and ask which characteristic decisions disappear. If play remains effectively the same after removing CHAIN, the signature is not working. Do not restore it by making all skills require CHAIN; that creates an access fee, not evidence of strategic depth. New names, elaborate borders and more visual effects cannot repair this failure.

## 4. Rule packs and terminology

| Term | Meaning in R1 | Not this |
| --- | --- | --- |
| MP | Stored skill fuel earned from LINE | Score, cooldown, automatic income |
| Amplification charge | Player-facing name for the stored resource currently called Combo; internal rename deferred | A streak that expires when the player waits or switches |
| Chain depth | Number of resolution waves in one cascade | The stored charge balance |
| Shared action timer | Current boss ETA and therefore the available reaction window | A separate player turn budget |
| Forecast | Known next action and its own windup duration | A guarantee of all future random actions |

Use separate labels for stored charge and cascade depth. R1 prefers a plain charge count plus a marker at the next affordable amplification; do not revive a T1–T6 technique selector. Skill purpose stays identical when amplified. Internal fields `energy` and `stock` remain untouched while implementation is deferred.

For numerical examples, use foundation section10's D/S/H and costs. Those values remain trial seeds. R1's changed failure/matching rules below are an independent package and require a later separately labelled comparison; do not change the v0.1 measurements retroactively.

## 5. LINE: short-term fuel, long-term board planning

- Retain the current10×20 visible board, hidden spawn area, seven-bag generator, HOLD and ghost. One HOLD per active piece; HOLD cannot reroll the bag. Preserve the inactive board, active piece and RNG state when switching.
- Retain current feel values as initial comparison references only: gravity1.0s/cell, lock delay0.5s, maximum15 lock resets, DAS0.15s and ARR0.04s. These are repository settings, not recommended values for every player. Input tuning and speed difficulty must be independently adjustable/tested later.
- Keep MP payouts10/22/36/52 for one through four cleared lines and cap60. One-line clears remain useful for an urgent cast; larger clears improve resource efficiency but risk building too high. No new T-spin/back-to-back MP multiplier in the first design pack. Such skill expression may retain score feedback without becoming another mandatory economy.
- No automatic gravity escalation during the first teaching encounter. Later difficulty should initially change readable threat patterns, not both puzzle speed and boss pressure together.
- R1 overflow recommendation: a blocked spawn costs25HP, resets only the LINE playfield and active-piece cycle through its defined next-piece path, and gives no clear reward. It does not reset CHAIN or award charge. No invulnerability or resource grant follows. If HP reaches0 the encounter ends before another piece spawns. This is a **new planning seed**, not current production behavior or part of v0.1.
- The25HP loss is a board-failure penalty, not a boss action: Ward cannot absorb it and its existing reservation remains bound to the boss. Preserve existing MP/charge, CHAIN state and the continuing bag sequence; do not reseed or restore spent HOLD through overflow. Clear only the blocked LINE field/active piece and spawn the next queued piece if still alive. These details supersede any ambiguous reading of "cycle reset" above for R1 only.
- Deliberate overflow must not outperform competent clearing as a resource-farming strategy: observe repeated-overflow policies and tune the penalty if board reset becomes optimal. Do not add penalties to three resources at once to conceal that failure.

## 6. CHAIN: optional amplification with recoverable mistakes

R1 recommends an8×8 board with six distinct color+glyph families; orthogonally adjacent swaps; straight horizontal or vertical3+ matches. Diagonal matching remains in v0.1 and production but is **off in R1** to reduce hidden match-reading burden. This is a separately tested grammar change, not an unnoticed adjustment.

Resolve all qualifying lines in a wave simultaneously. Their cell union clears once, gravity/refill follows, and new matches create the next wave. Each wave adds1 stored charge, capped at10; it grants no MP in R1. A cross match in the same wave is one wave, not two charges. A long line may receive clearer score/visual feedback but does not quietly count as extra waves.

R1 failure rule: an adjacent legal swap producing no match restores the exact board and deducts1 stored charge, clamped at0. It costs no MP and does not erase all stored preparation. Nonadjacent/out-of-board clicks and selection cancellation are rejected without cost. Failed swaps do not advance refill RNG. This combines a smaller failure cost with removing the current paid keep-or-revert choice; evaluate those changes separately before attributing an improvement to either.

Alternative failed-swap policies: retain full reset+paid keep (preserves current mastery but is harsh); restore with no penalty (welcoming but encourages blind probing); restore with charge−1 (recommended middle candidate, still weakens the whole-charge penalty). Never fake a rationale that the recommended candidate is already better for novices. At zero charge, bad swaps still consume active encounter time; avoid adding an artificial input stall before observing whether this is a real exploit.

Deadlock recommendation: when a stable board has no legal matching swap, perform an automatic deterministic reshuffle at the next safe boundary, preserving tile counts and granting no reward. It must produce no immediate matches and at least one legal move. If a bounded reshuffle search fails, stop with an explicit recoverable encounter error instead of endless shuffling, a hidden reroll reward or fabricated victory. This is a planned safeguard, not a verified existing feature.

## 7. Switching, pause and simultaneous events

Switching is voluntary and free of MP/charge cost. The inactive board does not advance. A switch cannot reroll, cancel a committed clear or refund a committed move. During an unresolved cascade, queue at most the latest requested target workspace and hand off after that committed resolution boundary. Selecting the already active mode has no effect.

Opening Skill or manual pause freezes the encounter simulation and its presentation timeline. Selection/inspection/cancel never spends resources. A confirmed skill closes the tactical panel; this does not create an arbitrary cooldown or promise a free extra interval before the next boss attack. With sufficient MP, repeated skills remain possible through valid subsequent confirmations. Measure repetitive menu use before inventing a one-skill-per-attack restriction.

R1 deterministic ordering recommendation: process queued valid player commands at the step boundary; reject Skill-open if the boss action has already committed; then advance the active puzzle, apply committed puzzle rewards, and advance/resolve the boss. Recheck pause and terminal state after each committed command and each damage transaction; do not continue later steps after victory, defeat or an active full pause. A reward produced in that simulation step cannot be spent by an earlier command in the same step. Terminal resolution disables new gameplay input. If a future concurrent-damage feature permits both HP values to reach0 in one transaction, classify defeat; the initial direct-skill fixture should not generate that case. Animation completion is never a damage authority.

Focus loss should enter a separate full pause before advancing further simulation and resume explicitly, not with a surprise hit on return. This planned accessibility behavior and longer-description reading remain separate from a ranked speed challenge, which is not in scope.

## 8. Skills: stable purposes, honest costs, contextual choices

Start with three techniques, not thirty new illustrations. Working labels are Strike / Ward / Recover. Base costs10MP; amplified costs10MP+2charge. Section10 of the foundation owns seed effects20/20/14 and amplified30/30/21. No silent conversion, fallback technique, random crit or new cooldown. Preview actual target, capped effect and exact remaining resources.

| Technique | When it has a reason to be chosen | When another choice can be better |
| --- | --- | --- |
| Strike | Defeat boss before a damaging action; spend MP before overflow | A nonlethal strike may leave insufficient resources to survive |
| Ward | Known damaging action is pending; prevention is worth more than later repair | Capacity wasted against a weak hit; lethal Strike can avoid the entire attack |
| Recover | Repair past damage and build HP for multiple later threats | Full HP or immediate hit greater than healed survival; Ward may prevent more |

Ward targets only the visible current uncommitted damaging action, not the hidden forecast guard or arbitrary future action. Keep foundation section10's one-reservation/no-replacement, exact once-only precommit cancellation refund, caps/overflow and terminal-disposal contract. For a future multi-hit action, the capacity is shared across its ordered hits; it is not refreshed per hit. Once the action commits, later interruption does not create a refund. Preview total expected damage and how capacity is distributed; multi-hit content is outside the first fixture.

Recover at full HP is disabled. At HP93, a14 heal shows effective7 for the full10MP cost. Never advertise14 actual healing. After confirmation, receipt and HUD must agree; a stale or invalid target spends nothing. Choosing BASE with enough charge is permitted so the player can save amplification for a later forecast.

**Important limitation:** BASE and AMPLIFIED are not automatically two meaningful choices. When charge has no plausible later value, AMPLIFIED dominates BASE for the same MP. Do not claim deep choice merely because both buttons exist. The design needs scenarios where saving charge changes later survival or damage opportunities, and cases where spending now is sensible. If these do not occur, simplify the presentation or revise the charge economy; do not add a secret penalty to manufacture indecision.

## 9. Hand-checkable economy and decisions

These are arithmetic checks, not simulations or measured clear speed. Ignore caps, enemy changes and movement time only where expressly stated.

- One single-line clear funds one base Strike:10MP →20damage. Four separate singles yield40MP; a four-line clear yields52MP, a30% MP increase for the same number of lines, before cap loss. This does not mean the four-line strategy is30% faster or safer.
- Two CHAIN waves buy one amplification: +10Strike damage, +10Ward capacity or +7Recover healing. Against a12 hit, amplified Ward prevents exactly as much as base Ward;18 capacity expires unused. More charge is not always more value.
- With MP already available, let `t_chain2` be time for two CHAIN waves and `t_line1` time for one LINE single. Ignoring caps and threat constraints, CHAIN's extra10damage exceeds LINE's20damage per preparation time only when `t_chain2 < 0.5 × t_line1`. This is a diagnostic threshold, not a requirement to force CHAIN speed. Available board setups, MP cap and preventing lethal damage can reverse this local comparison.
- At MP60, another LINE reward may overflow while CHAIN can still add useful amplification. At charge10 and low MP the reverse holds. Caps create context, but making the player alternate solely to avoid full bars is not enough to establish fun.

| Snapshot (same seed effects) | Valid reasoning | What it tests |
| --- | --- | --- |
| PlayerHP10, bossHP60, MP10, charge2, current35damage | Amplified Ward leaves5HP; base Ward is lethal; amplified Recover raisesHP31 then loses35; Strike is nonlethal | A real prevention purpose, not arbitrary category preference |
| PlayerHP10, bossHP30, same resources/threat | Amplified Strike defeats boss before its uncommitted action; no extra boss damage follows terminal | Aggression can be the best defense |
| PlayerHP80, bossHP60, MP20, charge2; light12 now, heavy35 next | Base Ward fully covers the light hit and preserves charge for heavy; amplified Ward wastes charge now | Future context can justify BASE |
| PlayerHP40, bossHP60, MP20, charge2; light12 now | Recover repairs14/21; Ward can prevent only12; attack may still shorten encounter | Healing is not merely weaker shielding |

After each scenario, ask what changed the decision. A correct answer learned from the walkthrough is teaching evidence, not an independent discovery result. For later evaluation, use unseen variants and preserve answers before coaching.

## 10. Boss content grammar and encounter pacing

Keep the first v0.1 boss's authored six-action schedule unchanged for fair comparison. R1 content planning then expands one demand at a time:

| Encounter role | Readable variation | Player opportunity | Avoid |
| --- | --- | --- | --- |
| Introductory heavy attacker | Distinct light versus heavy windups | Learn when prevention is efficient and when killing first is possible | Hidden attack speeds or simultaneous resource drain teaching |
| Pressure attacker | Announced sequences of smaller hits, later a clearly grouped multi-hit | Compare repair, prevention and MP spent to finish earlier | A Ward tooltip that lies about per-hit capacity |
| Opportunity attacker | An announced recovery interval after a heavy action | Prepare a board or cash in damage while safe | A mandatory last-frame button press or unseen damage bonus |

The recovery interval is initially just time before the next threatening commit. It grants no extra multiplier, currency or free action. A later vulnerability modifier must be a separately described candidate with visible duration and damage preview, not added through art.

Current action must not secretly change after commitment to its displayed identity. If a later encounter supports replacement/cancellation, announce it and resolve attached reservations through their contract. Difficulty may alter initial layout or announced cadence, but no hidden punishment triggered by player success. Do not use resource theft, board blackout, garbage insertion and faster gravity all in the first fight.

R1 first normal encounter target is approximately90–180 active simulation seconds, excluding tactical/manual pauses; this is a pacing hypothesis for later trials, not a change to the60-second v0.1 schedule or a promised completion time. Teaching practice and normal challenge must have separate configurations and labelled results. Do not balance against guessed expert clears per second.

## 11. Fun layers, originality and expansion restraint

| Intended pleasure | Supporting rule or feedback | Failure indicator | First response |
| --- | --- | --- | --- |
| Immediate control | Predictable movement, readable selection, visible reward destination | Player cannot explain a failed move or vanished resource | Fix input/feedback before rewards |
| Preparation payoff | Persistent boards and visible next threat | Switching feels like redoing a minigame | Inspect setup persistence and marginal benefit |
| Tactical reversal | Ward prevents lethal damage or Strike wins just before a hit | Correct response is always the same category | Rebalance encounter contexts, not add categories |
| Mastery | Larger clears, planned cascades and efficient resource spending | Best method is mindless single-clear/menu spam | Compare timings, stock levels and best policies |
| Expression | Same forecast admits a risky fast finish and a safer preparation route | Only one viable route across materially different states | Revisit reward/encounter relationships |
| Spectacle | Clear → resource → chosen skill → boss response is visually traceable | Effects obscure the decision or imply an unearned stagger | Reduce cosmetic clutter and bind feedback to events |

Do not add a permanent progression system to solve a dull first encounter. Later build variety should change how the same preparation loop is used, not require five new resource bars. Candidate extension order: one alternate technique per category as a pre-encounter replacement, then one meaningful boss variation, then a short authored encounter sequence. No concurrent six-skill loadout or random item economy is approved by this recommendation.

An optional future **response-echo** idea—successful prevention prepares a small follow-up attack benefit—could tie defense to offense without a new currency. It is `DEFERRED_IDEA`, not R1: it risks making Ward compulsory and needs explicit trigger, cap, expiry and other-category opportunity costs before specification. Do not generate icons or code for this idea now.

## 12. Teaching, visual storytelling and motion briefs

Teach in three observable steps: LINE reward arrives in MP; a CHAIN wave arrives in charge; opening Skill freezes the same boss ETA and previews a chosen result. Let the player see the difference between stored charge and the current cascade count. Avoid teaching paid swap retention or thirty technique stages in the R1 opening.

Portraits remain face-first, more anime-like and slim in silhouette; this is a direction, not a pixel-art mandate. Boss scale should communicate threat while preserving its silhouette and attack read. Tiles require distinguishable glyphs. Skill icons communicate stable purpose rather than every strength tier. Animation priorities are readable preparation, event-bound impact, brief recovery and a truthful reduced-motion/static alternative. Do not decide frame counts from a mood image.

Planning art can be prepared independently of Godot under the project's standing candidate rules once its purpose and brief are explicit. Runtime packaging and final crop/pivot/scale validation still require an actual consumer. Therefore a disconnected editor is **not** a reason to stop design or all concept work, but no untested image becomes a runtime-ready replacement. No new art is generated by this rule-writing task.

World/title work remains separate from the mechanics recommendation: retain the rift/threat motifs as references, do not finalize the previous title through inference, and do not use Vanguard (a player role) as the whole game's name. A lore name cannot serve as evidence that a generic mechanism is original.

## 13. Validation plan and re-evaluation triggers

Desk checks can establish rule consistency, arithmetic and a plausible implementation boundary. They cannot establish actual enjoyment, novice comprehension, input feel, rendering, performance, commercial originality or release readiness. Runtime and Human work are deferred, not failed requirements of this planning deliverable.

Later measurement must separate conditions: v0.1 A/B first, then R1 grammar, failure penalty and paid-keep removal one at a time. Paired seeds require identical valid initial board states under the rule being compared; do not reuse a diagonal-only legal board as an allegedly identical orthogonal fixture. Record tactical pause time separately from active play, and distinguish novice instructions from scored probes.

Observe time-to-first-purposeful-skill, explanations of resource roles, voluntary switch reasons, cap waste, effective versus wasted prevention/heal, repeated ineffective swaps, total pause burden, and the strategy used to win or lose. No fixed50:50 board-time target. Low use of one board is a finding only in context, not an automatic failure for an individual player.

Use foundation section10's small-cohort direction gate as qualitative evidence only. Add explicit hypothesis rejection: repeated obligatory switching without a decision; amplified choices with no opportunity cost; all-situations dominant Strike or Ward; lower failure cost causing thoughtless repeated probes; persistent difficulty reading diagonal or glyph states. Review representative losing attempts as well as wins. If later data contradicts the recommendation, retain the observed advantage of A or a narrower hybrid instead of forcing R1.

## 14. Change register and next design work

| Current state | Recommendation | Reason / expected effect | Status |
| --- | --- | --- | --- |
| Combo means both stored resource and cascade association | Separate stored amplification charge from chain depth in player wording | Reduce resource/streak confusion | R1 RECOMMENDED |
| Technique identity changes with Combo in baseline | Stable purposes and explicit same-purpose amplification | More predictable planning and icon reuse | Existing B recommendation detailed |
| Failed CHAIN loses all Combo and offers paid keep | R1 restore with charge−1; remove paid keep in that pack | Reduce punishment and an extra decision layer; possible reduced mastery depth acknowledged | R1 RECOMMENDED; isolated test needed |
| Diagonal matching in baseline | Orthogonal-only R1 trial | Lower scan burden; possible loss of satisfying discovery | R1 RECOMMENDED; preserve old control |
| Overflow lacks an R1 encounter cost | Plan25HP local LINE reset | Recoverable failure without free board cleansing | NEW TUNING SEED, not implemented |
| Desire for larger skill/image roster | Three coherent purposes first | Concentrate on distinct decisions and reusable state art | KEEP SMALL; expansion deferred |
| Proposed extra counters, forced switching, reflex timing bonus | Do not include in R1 | Avoid competing with the shared threat and preparation identity | REJECT FOR R1 |
| Godot connection previously blocked prototype | Defer implementation per user and continue design independently | No unnecessary environment work | CURRENT SCOPE |

Next planning topics after this rule pack: a short encounter-content sheet with exact telegraph wording and teaching variants; a player-facing Korean rules glossary and example skill cards; representative image briefs with coherent visual identity. These do not require gameplay implementation first. Broader campaign length, permanent progression and monetization are not silently decided here.

Rollback: remove this linked recommendation and receipt through Git; baseline files/data/assets remain unchanged. Project-only lesson: audit marginal resource value and stored-resource naming before producing a large skill art set. Existing Base research/review rules already cover the method; no new shared framework, plugin or Base policy is justified by this single design pass.
