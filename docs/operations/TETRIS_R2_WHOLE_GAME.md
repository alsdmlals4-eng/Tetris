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

Audio PR111 merged normally at14866c0a033ca3c6dde9e86464356881eae49753 after exact5f3ed27 CI2SUCCESS and unresolved threads0. Local/origin main readback matched. Next WG06 reader branch starts there.

Reader plan: current original37-page preimplementation PDF remains a historical source, not current implementation status. Compare A overwrite original (reject provenance loss), B separate small status PDF only (risk reader misses detailed rules/atlases), C current implementation supplement first plus unchanged original pages in one derived reader (ADOPT). Reuse existing Korean ReportLab/table helpers, real runtime screenshots and existing asset manifest; no decorative raster reconstruction. Generate encounter/skill/resource tables from actual JSON and bind code/data/source hashes to exact commit. Include detailed SWOT response, failure paths, deferred art/audio/Human limits, actual screenshots versus old design projections. Validate hashes/text/page count and visually inspect all new pages; preserve original PDF bytes.

Watchtower bounded layout correction v2 returned RGB1254×1254 with a painted checkerboard, no alpha: `.asset-vault/r2-watchtower-20260913/watchtower-layout-v2-rejected.png`, SHA256fea7c9b21d01102044d26831f13fdc1aab940498f5efd5c42e5255634b19b476. REJECTED_ALPHA; not atlas-ready, no runtime replacement. Original and first candidate preserved. No repeated automatic generation batch.

Content publication: PR110 merged at `9b980c1c9c0bd00abbbe71f24550ea2bd0ee882e`, exact head c0fe1a7 had both CI checks SUCCESS, no unresolved threads, CLEAN. Local main was fast-forwarded and read back before audio work.

### Audio implementation plan / WG-05

Implementation receipt: isolated native audio owner, four effect voices plus one short-jingle player,6 selected CC0 files, real event/menu/settings hooks, preview/cancel/mute and pause boundaries. Final GUT393/393 and tooling88/88; native playing/volume/mute readback and125% layout inspected. Exactly2 reviews,0 remaining blockers. Evidence `docs/validation/r2-audio-20260913/README.md`. Complete soundtrack, listening/mix and distinct enemy art remain required WG05 work. No Base promotion: NO_NEW_REUSE_LEARNING; existing Godot facility was sufficient.

Current actual consumer gap: saved effects/music sliders have no playback owner. Existing visual receipts remain authoritative and sound must never grant resources, advance the shared clock or replay restored actions. Reuse preflight read existing screen/event/settings code, targeted Base reuse registry (no applicable audio module), and official Godot AudioStreamPlayer documentation. No addon required. Alternatives: silent presentation (safe fallback but ineffective volume controls), native non-positional players with selected CC0 sounds (ADOPT, small bounded dependency), custom synthesis/middleware (REJECT unnecessary authoring and maintenance). Official Kenney Interface Sounds, Impact Sounds and Music Jingles pages and each downloaded archive License.txt declare CC0; retain source/hash/license evidence and do not imply third-party legal review. Source archives stay in user deletion-wait folder, only consumed files enter project.

Plan: failing tests → isolated audio presentation owner with bounded voices and true zero-volume mute → existing successful event and menu consumers → preview/cancel/save settings semantics → explicit export/provenance → full regression and native playback-state checks → two independent reviews. One short ending jingle is not a looping soundtrack or completed audio mix. Sound-on-device/listening quality remains separate from engine playback verification. No new gameplay or save schema. Rollback removes audio owner/hooks/assets, preserving all gameplay/settings compatibility.

The first three-battle run is an implementation bridge, NOT the entire completion gate. Final scope is a finite, repeatable single-player campaign with a clear beginning and ending, distinct encounters and useful choices, complete in-game art/motion/audio, readable supported screens/input, robust resume/failure flows, player-facing help and a source-bound updated blueprint. Extra classes, commerce, online services and endless content are not implicit requirements.

| outcome ID | required result / acceptance | actual or planned consumer | state |
|---|---|---|---|
| WG-01 | Finite expedition transitions reject skips/duplicates; terminal boss leads to ending; two middle routes are reachable | r2_expedition.gd + catalogue + r2_screen | MACHINE_VERIFIED; native watchtower ending verified |
| WG-02 | Different encounter profiles execute through same combat owner; forecasts/save validation agree; first encounter remains compatible | r2_combat/r2_session, profile-bound expedition envelope | MACHINE_VERIFIED; native profile path exercised |
| WG-03 | Main→route→battle→intermission→ending is usable with mouse/keyboard; campaign save never overwrites single-battle save | r2_screen/r2_expedition_save and export preset | IMPLEMENTED; package/input completion in progress |
| WG-04 | Enemy identity/pattern purpose and story arc are distinct; rewards support choices rather than mandatory grinding | encounter catalogue, presentation text, route preview and ending screens | IMPLEMENTED/MACHINE_VERIFIED text and real cycle preview; player balance NOT_RUN |
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

Publication readback: PR109 merged normally at `142c56e1ef3fd64d204f715b64c406075525862e`; local main and origin/main match. Exact PR head10bd3fd had both required CI checks SUCCESS, no review threads, CLEAN merge state. Next work branch starts from this completed main, not an unrelated draft.

2026-09-13 local validation:380/380 GUT tests,4010 assertions,61 scripts,exit0; no stderr. Native Godot4.7.1 at1280×720/125% text reached SUPPLY→watchtower→SUPPLY→core→COMPLETE with88HP. The shared test-only driver issues real CHAIN/switch/advance commands without editing HP or resources. Its zero deliberation time is NOT human play, balance or fun evidence. Full route state tests cover both middle alternatives; native capture covers watchtower, not both. Screenshots show temporary common art and remaining presentation work explicitly.

Review loop1 found same-run/different-seed checkpoint acceptance and a heavy-action icon mismatch. Both were reproduced in failing tests and fixed. A native125% guidance overlap was also reproduced and corrected. The save readback diagnostic exposed mixed String/StringName checksum-key ordering; the envelope now uses explicit String keys like the existing writer. These are project-only regression lessons; no Base promotion is claimed. Loop2 completed with0 blocking findings; exactly2 full reviews, connection-slice CLEAN_REVIEW_EXIT. Exported package at376d0f5 verified actual expedition entry; eight known teardown warnings remain. [Evidence and limitations](../validation/r2-expedition-20260913/README.md). WG-04/05/06 remain required; this connected run is not a whole-game completion claim.

## SWOT and re-evaluation

- Strength: two distinct puzzle roles and exact forecasts. Strengthen by encounter schedules that make stored defense, immediate healing and an attack finish useful at different times, while retaining one rule vocabulary.
- Weakness: one boss and candidate presentation currently limit the whole experience. Improve through distinct encounter intent and connected feedback, not raw HP inflation. Test actual route coverage and readable reasons before adding content counts.
- Opportunity: between-battle preparation can make LINE/CHAIN decisions matter beyond one exchange. Test both supply and middle-route alternatives; if repair dominates all damaged states, revise authored magnitudes or encounter recovery opportunities rather than remove choice without evidence.
- Threat: content/art/save expansion can reintroduce prior visual regressions and duplicate authorities. Preserve old data; bind profile, exact asset consumer, generation source, test and runtime capture. Revisit the design when simulations expose impossible runs, same-strategy dominance or live player confusion.

No new reusable Base implementation is claimed. Capture project-only lessons first; promote only a proven repeated need. Deletable temporary files go to the user's recoverable deletion folder, not hard deletion.

## WG-04/05 current execution plan: encounter identity and presentation

Plan before changes:1 identify actual screen/asset needs;2 produce one bounded enemy state-family candidate;3 validate true alpha, frame bounds/continuity and Aseprite roundtrip;4 add presentation metadata and truthful threat/route descriptions with tests;5 prepare profile-aware visual consumer without replacing preserved default assets;6 native/state/input checks and two reviews. Candidate review is not final art lock. Other safe implementation continues without routine approval requests.

Screen coverage (links, not another asset canon): Main/briefing/practice/pause/settings/save-error/result have existing R2 captures and components; reuse. Expedition route/supply/ending now have real screen composition evidence; long Korean sentence wrapping and visual finishing remain. Battle owns enemy `Battle/Combat/Stage/BodyClip/BossVisual` and result owns `Result/BossVisual`; profile-specific art is missing. Player portrait4 states, icons6 and tiles4 already have consumers; preserve until targeted review. No overworld movement/building/shop/3D/network loading art: NOT_APPLICABLE, those systems are absent. Credits/audio coverage remains an explicit WG-06/05 gap, not silently excluded.

`VR-R2-WATCHTOWER-01`, P1 IDENTITY/FEEDBACK, consumer GAME_RUNTIME (planned profile binding in existing BossVisual); coverage REQUIREMENT_LINKED/state-family PARTIAL. Delete Test: without distinct silhouette, rapid ranged enemy looks like the slow hammer core, weakening recognition. Compare A common hammer with label (cheap but semantic mismatch), B distinct ranged key-pose family (chosen bounded candidate, reusable existing pose selector), C skeletal/3D animated enemy (unneeded rig/import cost and style drift). Keep anime/cel-shaded dark angular armor, readable highlights and violet rift energy; distinguish a slender armored sentinel with a long mechanical bow from broad hammer boss. Avoid copying an external character, painted background/checkerboard, text, extra limbs or inconsistent weapon. Current boss-cutout source was visually inspected for line/material language only; not an edit target and not a new final approval.

Required same-character poses: idle, anticipation, impact/release, recovery, hurt, defeat;2 columns×3 rows, equal cells, transparent RGBA, generous transparent gutters, fixed camera/scale, waist-up composition for the existing wide battle slot. No motion inbetween count invented: simulation still owns effects/timing. Aseprite selected for slice/tag/canvas validation and editable master, not as a command to make pixel art or redraw creative pixels. Final dimension/regions must use actual output measurements. Candidate stays unbound until its own promotion gate; existing runtime assets remain intact.

Research read2026-09-13: [Aseprite sheets](https://www.aseprite.org/docs/sprite-sheet/) supports grid offsets/padding and tag-aware export (ADAPT); [Godot2D animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html) supports individual frames or sheet playback (REUSE current atlas selector for six semantic poses, DEFER new animation framework). Base art/coverage/continuity owners read; legacy Notion-write and pre-generation stop text is superseded by current repository-first and image conversation owner. User's standing necessary-image/continuous-work delegation permits bounded candidate preparation, not falsely labeling final art approved. No paid API/tool or external art download.

Watchtower candidate generated with built-in image model: `.asset-vault/r2-watchtower-20260913/watchtower-source.png`, SHA256 `615eec1e3cd8fc3322f17b4921e8c5d32e6d9f2e6665165307b369ecc9f13e03`; original retained in Codex generated_images. Actual1254×1254 RGBA,912820 fully transparent pixels; alpha0–255. Restricted Aseprite copy/export: single static sheet/frame,100ms default, no tags; pixel-identical RGBA roundtrip. Editable candidate sibling `.aseprite` saved. This is NOT6-frame animation. Visual QA: lean bow identity reads, but no safe gutters and impact arrow crosses the nominal627×418 cell; several bounds touch edges. `REVISION_REQUIRED`, no runtime binding/promotion and no next-image batch. Candidate shown to user; independent content work continues under latest continuation authority. Aseprite source is a preservation master, not a remedy for bad composition.

Next bounded content implementation: expose enemy identity/story and complete four-action preview from the combat owner's computed durations, including relaxed mode. Alternatives: tooltip-only (insufficient discoverability), reuse existing route buttons plus readable description (chosen), new multi-step briefing modal (extra clicks/maintenance). Add presentation-only data separately from combat catalogue so wording changes do not invalidate save hashes. No new stats, rewards or balance changes. Tests must prove preview purity, profile/mode agreement, unknown-profile fail closed, UI identity and export inclusion; preserve original catalogue bytes.

Content slice result2026-09-13: new presentation-only JSON, real four-action preview on mouse/keyboard focus, initial enemy HP/threat card, matching cached battle name, route-specific victory prose and readable ending. GUT386/386,4043 assertions,61 scripts,exit0; tooling88/88,exit0. Native run13 at1280×720/125%: KEY_RIGHT changed focus and preview to watchtower; actual command driver then completed foundry route. Revised fork/SUPPLY/ending captures inspected. UI-only invalid-brief test reproduced crash and direct-pressed launch bypass; both fixed. Fork spacing regression reproduced276>267 then fixed by13px preview shift, test green. Exactly2 independent whole-slice reviews: second0 new blockers, CLEAN_REVIEW_EXIT. Package/exact-head publication is the next delivery gate, not omitted. Candidate art remains REVISION_REQUIRED; full art/audio/Human completion not claimed.
