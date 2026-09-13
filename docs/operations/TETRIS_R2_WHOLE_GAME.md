# R2 whole-game execution contract

## Direction anchor / authority

Continue until the dual-puzzle game is implemented as a complete playable product, not only a first encounter or one verification feature. Latest user2026-09-13 explicitly delegates research, detail design and implementation without routine approval checkpoints. `REUSED_APPROVAL`; `CONTINUOUS_WORK_ACTIVE`. Implementation authorization is not Human/fun, final branding, rights or release approval.

Source main: `a75e93006f950bc21332205a314d1ac53e061675` (readability PR108 merged and locally read back). Prior R2 first-encounter blueprint remains a preserved publication. Its campaign exclusion described the first implementation scope; this contract owns the newly requested whole-game extension. R2 automatic-cast rules retain combat authority. Base9.4.4 and protected production documents/assets remain unchanged; current Base methods inform work without replacing the adapter.

## Current state and reuse preflight

Actual `r2_session`, `r2_combat`, `r2_screen`, `r2_save`, tests and exported launcher were read. Main/briefing/practice/battle/settings/result/retry already work. Missing: multi-encounter progression, intermission choices, encounter-specific content, campaign persistence, an ending and connected production presentation. Do not rebuild LINE/CHAIN, input, skill resolution or save recovery.

- REUSE existing R2 combat, seeded boards, atomic checkpoint validation, options, next/current/last feedback and report metrics.
- ADAPT Base RM-SYS-002 explicit state/guard boundary and RM-SYS-007 authored encounter data. The registry lists contracts, not an installed reusable runtime; no generic framework/addon is needed. TETRIS profile is planned historical guidance, not a new gameplay authority.
- REFERENCE only historical planned route/result screens and older GDD meta ideas. No takeover of unrelated draft PRs100/85/46/33/23/19; no cross-project code copying. Registry references do not point to a directly compatible verified campaign implementation, so no broad cross-project scan.
- ACTIVE_OWNER: R2 runtime/data and this extension contract. COMPATIBILITY: production gameplay and first-encounter save. ARCHIVE: earlier iteration receipts. UNKNOWN_UNVERIFIED: pre-existing generated sidecars; preserve. No removal proposed.

## Fresh benchmark / three alternatives

Sources read2026-09-13; official descriptions, not hands-on play or interviews:

| source_and_evidence | observed_pattern | project_fit_and_difference | disposition |
|---|---|---|---|
| [Mega Crit press kit](https://www.megacrit.com/press-kits/slay-the-spire/) | Characters, encounters, items and generated levels support repeated runs | A run needs changing decisions; its large card/item library is not a scope template for this puzzle game | ADAPT encounter variation; REJECT content-count imitation |
| [CAPY Grindstone](https://store.steampowered.com/app/1818690/Grindstone/) | Authored puzzle hazards/bosses, gear and additional modes | Individual encounters can teach different responses; hundreds of levels and crafting are not required for a coherent ending | ADAPT authored encounter goals; DEFER gear grind |
| [Subset FTL](https://store.steampowered.com/app/212680/FTL_Faster_Than_Light/) | Pausable combat, different encounters and meaningful choices across a run | Preserve inspectable threats and between-fight consequences; do not adopt irreversible permadeath or new ship-like currencies | ADAPT run consequences; REJECT mandatory permadeath |
| [Godot saving games](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) | Identify persistent owners and serialize their state; settings can be separate | Existing complete-snapshot validation is stronger than copying a tutorial's basic save loop | REUSE existing recovery; ADAPT a separate expedition envelope |

`benchmark_preflight_state=PASS`, `reuse_preflight_state=COMPLETE` for expedition structure. New art/audio has its own consumer preflight later.

| valid alternative | player value | maintenance, risk, reversibility | decision |
|---|---|---|---|
| A authored linear chapter with checkpointed battles | Clear learning arc, lowest additional cognitive load | Predictable replays; cheap to extend; easy rollback | Retain as underlying progression spine |
| B short authored expedition with one route fork and bounded intermission choice | Carries survival/preparation choices across battles without another economy | Must prevent dominant repair choice and softlock; moderate data/save work; isolated save permits rollback | Recommended ADAPT: first complete connected run |
| C procedural endless roguelite with equipment/meta unlocks | High content combination potential | Larger balance and asset multiplication, no natural completion bound, harder migration | Defer; not required to call the finite game complete |

## Whole-game completion coverage

The first three-battle run is an implementation bridge, NOT the entire completion gate. Final scope is a finite, repeatable single-player campaign with a clear beginning and ending, distinct encounters and useful choices, complete in-game art/motion/audio, readable supported screens/input, robust resume/failure flows, player-facing help and a source-bound updated blueprint. Extra classes, commerce, online services and endless content are not implicit requirements.

| outcome ID | required result / acceptance | actual or planned consumer | state |
|---|---|---|---|
| WG-01 | Finite expedition transitions reject skips/duplicates; terminal boss leads to ending; two middle routes are reachable | r2_expedition.gd + catalogue + r2_screen | MACHINE_VERIFIED; native watchtower ending verified |
| WG-02 | Different encounter profiles execute through same combat owner; forecasts/save validation agree; first encounter remains compatible | r2_combat/r2_session, profile-bound expedition envelope | MACHINE_VERIFIED; native profile path exercised |
| WG-03 | Main→route→battle→intermission→ending is usable with mouse/keyboard; campaign save never overwrites single-battle save | r2_screen/r2_expedition_save and export preset | IMPLEMENTED; package/input completion in progress |
| WG-04 | Enemy identity/pattern purpose and story arc are distinct; rewards support choices rather than mandatory grinding | encounter catalogue, help/ending screens | TODO |
| WG-05 | Required enemy/portrait/skill/tile states, UI images, motion and audio have actual consumers and provenance | r2_assets / view / planned audio consumer | TODO |
| WG-06 | Complete supported-resolution, input, failure/resume, package and blueprint/source readback; two full review loops clean | tests, native Godot, PDF and local executable | TODO |
| WG-HUMAN | Real first-exposure/fun/accessibility/balance evidence | existing human evidence contract and local playtest reports | NOT_RUN; not substituted by automation |

## First expedition design / interface (WG-01 through WG-03)

Implementation seed, not final balance: three battles per run: outer breach → one of two middle approaches → Gatebreaker core. This combines teaching, a deliberate fork and a climax. The authored catalogue owns IDs, order/options, labels and supply magnitudes. It must be acyclic, finite and validate required references. No random route reshuffle on reload.

- `R2Expedition` owns progression only. `R2Session` owns the current real battle. The screen dispatches the same public methods used by tests, never writes progression fields.
- States `ROUTE → BATTLE → SUPPLY → ROUTE`, then `COMPLETE` on final victory or `DEFEAT` on any lost battle. No clock advances outside BATTLE. A route choice can only pick a currently listed option. Completion requires a terminal result belonging to the launched encounter identity. No fake battle timer, no rewarding a running encounter.
- The public boundary is start/configuration → available encounters → launch choice → finish current battle → one supply selection → next choices. Returned data are deep copies. Invalid, early, duplicate, wrong-encounter and post-terminal actions are rejected without state mutation. UI disabled buttons are not the guard.
- Carry current HP between encounters. Reset puzzle workspaces, bank, armor, ward and action IDs at each new encounter; intermission choice may give a bounded opening reserve. Document this at departure rather than silently carrying half-resolved boards. Existing standalone R2 behavior is unchanged.
- Supplies are one of repair, attack reserve or armor reserve. They apply once, are non-monetary, and cannot be farmed by result reentry or reload. Repair caps at existing100HP; preview shows effective repair. No permanent stat tree or new currency.
- Defeat ends the expedition result but allows retry from the saved encounter-start state, without rerolling rewards or route. Whole-run restart is explicit. Final victory shows the ending and run summary; no accidental fourth battle.
- Separate `user://replanned_r2/expedition.json` envelope; preserve `save.json` and options. Catalogue identity/hash plus the complete existing battle snapshot belong in the expedition checkpoint. Restore to full pause, fail closed on incompatible/partial data, retain validated backup. No in-place legacy migration. Never label checksum as tamper resistance or power-loss atomicity.

## Work order / validation / rollback

PLAN (intake, brainstorming, writing-plans) → BUILD (TDD) → REVIEW (verification, independent code review and two complete adversarial loops) → protected publication → rescan whole-game backlog. Approval alignment reuses latest explicit whole-game delegation; no repeated menu.

1. WG-01 catalogue/transition tests first: normal two routes, invalid IDs, early completion, duplicate reward, terminal refusal, snapshot copy isolation. Implement thin progression owner only. Planned consumer WG-03 means this alone is NOT a playable campaign.
2. WG-02 profile-aware combat constructor, strict identity/hash validation and exact default backward compatibility. Test different damage schedules, relaxed timing, same-frame outcome and cross-profile save rejection. No public setter bypassing live combat guards.
3. WG-03 connect screen and recoverable envelope. Test every page transition, interruption/backup, old-save preservation, real engine input and packaged entry. Do not publish an unconnected catalogue as the feature's completion.
4. WG-04/05 complete content and presentation after mechanics consumers stabilize; research/reuse each needed asset, true-alpha checks and runtime review. Use image model for image production, Aseprite source/atlas packaging when appropriate; do not replace approved visuals with primitives.
5. WG-06 run full regression, end-to-end route variants/failure/retry, native layout and export, updated source-derived human blueprint. Enumerate required remaining work again. WG-HUMAN remains honestly separate.

Feasibility: profile/snapshot integration is implemented and machine-verified. The existing battle owner now accepts a validated optional profile while preserving default rule-pack identity. The expedition envelope binds profile, run identity and initial LINE shape/resource plus CHAIN seeds. No new paid tools, infrastructure or dependency. Rollback reverts this branch's extension and leaves standalone save, published blueprint and baseline assets intact.

## Expedition connection evidence / learning

2026-09-13 local validation:380/380 GUT tests,4010 assertions,61 scripts,exit0; no stderr. Native Godot4.7.1 at1280×720/125% text reached SUPPLY→watchtower→SUPPLY→core→COMPLETE with88HP. The shared test-only driver issues real CHAIN/switch/advance commands without editing HP or resources. Its zero deliberation time is NOT human play, balance or fun evidence. Full route state tests cover both middle alternatives; native capture covers watchtower, not both. Screenshots show temporary common art and remaining presentation work explicitly.

Review loop1 found same-run/different-seed checkpoint acceptance and a heavy-action icon mismatch. Both were reproduced in failing tests and fixed. A native125% guidance overlap was also reproduced and corrected. The save readback diagnostic exposed mixed String/StringName checksum-key ordering; the envelope now uses explicit String keys like the existing writer. These are project-only regression lessons; no Base promotion is claimed. Loop2 completed with0 blocking findings; exactly2 full reviews, connection-slice CLEAN_REVIEW_EXIT. Exported package at376d0f5 verified actual expedition entry; eight known teardown warnings remain. [Evidence and limitations](../validation/r2-expedition-20260913/README.md). WG-04/05/06 remain required; this connected run is not a whole-game completion claim.

## SWOT and re-evaluation

- Strength: two distinct puzzle roles and exact forecasts. Strengthen by encounter schedules that make stored defense, immediate healing and an attack finish useful at different times, while retaining one rule vocabulary.
- Weakness: one boss and candidate presentation currently limit the whole experience. Improve through distinct encounter intent and connected feedback, not raw HP inflation. Test actual route coverage and readable reasons before adding content counts.
- Opportunity: between-battle preparation can make LINE/CHAIN decisions matter beyond one exchange. Test both supply and middle-route alternatives; if repair dominates all damaged states, revise authored magnitudes or encounter recovery opportunities rather than remove choice without evidence.
- Threat: content/art/save expansion can reintroduce prior visual regressions and duplicate authorities. Preserve old data; bind profile, exact asset consumer, generation source, test and runtime capture. Revisit the design when simulations expose impossible runs, same-strategy dominance or live player confusion.

No new reusable Base implementation is claimed. Capture project-only lessons first; promote only a proven repeated need. Deletable temporary files go to the user's recoverable deletion folder, not hard deletion.
