# R2 combat decision-readability implementation plan

> Execute inline with test-driven development and exactly two full result reviews. Latest user explicitly authorizes research-to-design-to-implementation continuation without routine approval questions.

## Direction and authority

Make LINE preparation, CHAIN automatic casting and the visible boss deadline understandable as one decision loop. Preserve four resources, per-wave automatic casting, voluntary persistent-board switching, encounter numbers, existing atlases, production baseline, saves and Base9.4.4. Source main: `7da62cf093197a88c75b372eb83517bd61f0b515`. Base remote readback: `d830c0f6967678eed3c208ac6b24f9cd1b262ec3`; no adoption upgrade.

Spec owners: `REPLANNING_AUTOCAST_R2.md` sections4,7–11,15–16; `R2_COMPLETE_HUMAN_BLUEPRINT.md`; actual `r2_combat.gd`, `r2_screen.gd`. Existing completed implementation/report plans are history, not unfinished tasks. Drafts100/85/46/33/23/19 remain read-only. User's blank-line change in project.godot and unknown imports/UIDs remain untouched.

## Research and alternatives — 2026-09-13

Official public descriptions are not firsthand playtests, proprietary source inspection or proof of fun.

| Source and observed pattern | Decision / fit |
|---|---|
| SEGA https://asia.sega.com/puyopuyotetris2/kr/rule.html: distinct puzzle rules, skill combat, recoverable top-out | KEEP the existing role split and recovery. REJECT forced switching and MP economy for R2. |
| https://www.tetriseffect.game/: action-centered puzzle presentation | ADAPT causal feedback in existing receipts, not its assets/music/Zone. |
| Into the Breach developer site timed out; developer-published https://store.steampowered.com/app/590380/Into_the_Breach/ subsequently read: all enemy attacks telegraphed | ADAPT known threat-to-counter decision readability, not turn order. R2's own section15 already requires expected HP after protection. No proprietary source or firsthand-play claim. |
| https://docs.godotengine.org/en/stable/classes/class_label.html: wrapping and text layout | ADOPT actual font/layout checks at100/125percent rather than assuming character counts fit. |
| Base reuse handoff/profile/registry: planned UI/explainability patterns | REUSE project combat receipts and existing UI. Base's old turn-budget identity is stale reference and must not overwrite R2. No new shared framework or cross-project module is needed. |

Compare A: explanatory text only (cheap but player still does arithmetic); B: read-only live projections from the existing combat owner (selected: precise, cheap, reversible); C: full future-chain simulator/advisor (reject for this slice: hidden refill information and false guarantees). No balance adjustment is justified by this inspection alone.

## Implementable contract

The combat model owns `threat_preview()` and `skill_preview(category,wave)`, both pure reads. UI consumes dictionaries; it never applies or reserves an effect. The threat projection describes the current state only, not guaranteed future HP: same action-bound ward, then armor, then capped HP loss. Committed actions retain already-bound ward; commitment prevents a NEW ward, not existing protection. Finished/terminal actions are inactive. Skill projections retain original categories/stage cap, effective capped damage/heal, one-time attack-bank contribution, max-not-add ward and no-target reason. Pause permits inspection without spending. Invalid category/wave returns an explicit unavailable result.

## Tasks / executable tests

- [ ] T1 combat projection: add tests in `tests/replanned_r2/test_r2_combat.gd`, observe RED, implement in `src/replanned_r2/r2_combat.gd`, GREEN. Fixtures: damage12/ward3/armor2 => HP loss7; bound ward still3 atcommit; foreign ward=>0; rest=>0; HP5=>0after; finished/terminal inactive. For skill: ATK4+bank7 with boss8 =>effective8/bank7consumed; SUPpower2 atHP99=>1; DEFtarget3 with ward7=>7not10. Snapshot before/after must match. Compare forecast against actual resolution/cast on an independent restored instance.
- [ ] T2 screen connection: extend `tests/replanned_r2/test_r2_screen.gd`, observe RED, connect existing Threat/SkillDock/LINEReceipt labels in `r2_screen.gd`. Show current-state expected HP and lethal marker, full absorption breakdown in reachable tooltip, stage read-only controls unchanged. Next skill says current-state estimate, with cap/waste and bank consumption in tooltip; recent ATK shows basic+bank and effective result. LINE receipt shows effective/wasted healing alongside its existing clock application. Check100/125percent widths/heights and no session mutation during refresh.
- [ ] T3 verification/closeout: focused then full GUT; two full adversarial reviews; actual Godot normal and controlled boundary capture; package inclusion regression and local export; exact-head PR checks, safe merge/readback, preserve user files. Human/fun/balance/device/release are separate, never auto-PASS.

Run focused tests with installed Godot4.7.1 `--headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/replanned_r2/test_r2_combat.gd -gexit`; then screen file; full `-gdir=res://tests -ginclude_subdirs -gexit`.

## Scope scan and next queue

Already implemented: main/briefing/result, save/options, four practice stages, LINE/HOLD/NEXT, CHAIN/cascades, automatic casts, shared ETA, local report export. First missing connection: live protection/effective-skill explanation (this slice). Later reassess actual tutorial-to-normal transfer and combat event feedback from runtime evidence; do not invent progression, jobs or balancing changes just to keep a task queue full. Audio, first-exposure humans, physical controllers, final art/rights and long-duration tests remain separately unverified.

Feasibility: FEASIBLE from existing combat owner; no dependency, save-schema or asset change. Risk: forecast mistaken for a promise; mitigate with current-state wording and transaction-time revalidation. Rollback: revert only this feature commit. Derived published PDF bytes remain unchanged; this repository-native follow-up records implementation status without forging a new blueprint approval.

Initial evidence: source/research inspection only. Implementation and runtime NOT_RUN. AgentMemory tools unavailable; local memory only supplied search hints and current repository wins. Reuse learning: project-only until verified across contexts; no Base promotion action.

## Implementation and review readback

Model RED5 missing forecast tests -> GREEN26/26; screen forecast RED9assertions and receipt RED2assertions -> GREEN36/36; full suite361/361,3804assertions. First independent full review found a layout-evidence gap, not a proven overlap: added neighbor/parent-bound checks at100/125percent, all categories and bank2billion; PASS19assertions. A subsequent blueprint consumer rescan identified missing LastIcon. REDmissing node -> added existing strike/ward/recover atlas consumer, independently bound to last actual cast, not next selected category. No new art bytes or export dependency.

Native1280x720: controlled DEF atcommit/HP5/ward3/armor2 shows lethal HP0; practice2 real engine mouse press/release atcells(4,5)/(5,5), then deterministic1second advancement gives2casts/bossHP230/recentT2damage6; controlled SUP atHP99 shows1of2effective. Captures def-125/chain-125/sup-100 in docs/validation/r2-readability-20260913. These diagnostic setups are not first-exposure Human evidence. Final icon runtime recapture and exact-head full/package verification follow. Actual server session expired and was reinitialized successfully; no version/dependency change. One diagnostic eval compile failure was recovered by stopping/relaunching the exact R2 game, not altering game logic.

Latest user clarification expands the continuing objective to whole-game completion. This slice is only one completed dependency; next work must establish a research-backed whole-game plan and implement gaps. Do not close the overall objective because this PR merges. Changes to excluded first-slice items now belong to a separately specified full-game implementation sequence, not a silent edit to the frozen blueprint.

### Verified slice closeout

T1/T2/T3 implementation and local evidence complete at35c6dca1117391a54391693acb9f8b7c13bb294f: full GUT363/363,3830assertions59scripts; tooling88/88; Windows local package `C:/Users/user/Documents/Tetris R2 Local Trial/Builds/readability-35c6dca-20260913` returns R2_LOCAL_TRIAL_PACKAGE_VERIFIED. Existing8 bounded export teardown warnings remain known tooling diagnostics, not warning-clean/release evidence. `final-icons-125.png` verifies the final two-icon layout; earlier screenshots are pre-icon-change samples. Exactly2full independent review loops, no remaining code/layout blocking finding. Initial/pending statements above are chronological records, superseded by this closeout and sibling machine receipt.

Repository-native implementation view and Current Foundation route updated. No source PNG, production contract, save schema, Base adapter or paid dependency changed. User project.godot hash46ce5e3295b0807f57fd16e07573ca7f0aa470c8e55696a8f8ca360d74caf020, ordinary save0500831f3666bdafa102311773fa3f324db688f049ec0234d79e3b7aed2a65a7 and options9d5e9dba265f31673e311326d112ef47ea354e1da1544ce981896fd9614ab703 remain unchanged. Reuse outcome: existing combat/atlas/UI; lesson: bound forecast and recent effect to distinct source identities and validate actual neighbor bounds; PROJECT_ONLY, no Base promotion.

Publication is verified against the live current-task PR rather than a guessed future SHA. Whole-game goal remains ACTIVE after this slice; first-exposure Human, balance, final art/rights and release are not marked PASS.
