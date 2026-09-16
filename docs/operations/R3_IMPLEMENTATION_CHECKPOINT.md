# R3 implementation checkpoint — 2026-09-14

## 2026-09-16 bounded input/supply correction

Latest user scope: fix Space unexpectedly pausing and apparent four-pair stall; append dated summaries to the **existing** monthly journal, then finish this slice and synchronize GitHub. This is current-task continuation on PR118, not permission to merge unrelated/draft work or declare all R3 complete.

Plan executed: reproduce through real Viewport input routing with a focused Pause button → fix reserved battle keys before GUI handling → verify four-pair exhaustion/LINE replenishment/re-entry → full regression → append existing monthly PDF → current-branch publication/readback. No balance quantities, art, normal saves, Base9.4.4, R2 entry, or user's existing project.godot changes were replaced.

Preflight (`REUSED_EVIDENCE` + directly read primary source): current r3_screen/r3_session/supply consumer and R3 specification §supply own the behavior. [Godot input routing](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html) documents `_input` before GUI before unhandled events. Compared: disable all Button focus (REJECT: harms keyboard navigation); change global ui_accept (REJECT: affects unrelated menus/R2); consume only reserved Space and running Tab at the R3 screen boundary (ADAPT: bounded fix, preserves Enter/menu focus). Existing finite supply and explicit, non-forced LINE return are ADOPT; free automatic refill is REJECT because it restores the chain-only advantage. No new framework/assets or Base promotion required (`NO_NEW_REUSE_LEARNING`).

Root causes/results:
- Space reached GUI first and activated a retained Pause focus. Space press/release/echo is now reserved to battle; only a fresh running press drops. Paused Space never resumes. Running Tab is likewise intercepted; paused Tab remains available to menu focus navigation.
- Four pairs were intentionally finite, not a spawn failure. Previously the supply text did not provide the specified emphasized return control. Exhausted CHAIN now disables placement buttons and emphasizes `LINE 보급 →`, with row-to-three-pairs and continuing enemy-timer guidance. A real LINE clear followed by re-entry resumes the fifth pair. No forced switch/reset/free refill.
- Journal owner remains the private monthly `Tetris_2026-09_AI활용_작업일지_증빙집_v1.1.pdf`. Append date summaries there; do not generate v1.2/v1.3 or daily public journals. `Tetris_원본대조_v1.1/append_daily.py` has a duplicate-entry guard and preserves pre-append bytes/source hashes privately. Existing historical pages are not rewritten as new work.

Verification: initial screen RED **11/14**, three expected failures; review-loop-1 added focused-Tab RED **14/15** and corrected it. Full corrected regression **491/491, 7212 assertions, 80 scripts, 84.561s, exit0**, empty stderr (`r3-input-full-0916.log/.err` in local Temp). Review-loop-2 reread scope, pause/release/echo routing, supply/restore invariants, old-page preservation and selected diff: no new scoped blocker. These are engine/automated input tests, **not physical-keyboard/Human UX approval**. Current Hera inventory contains only Blacksmith; no command was sent to that unrelated editor and no new Tetris native screenshot is claimed.

Monthly PDF: 9/16 one-page summary appended to the existing 12-page document, total13; all12 historical page content streams unchanged. Page13 rendered and visually checked; final SHA256 `091fa6153b8a318afb48b1d3774d2ff2ed2f9e64c94bd92cee9cf6caa2558c19`. Private sources remain outside GitHub. Historical v1.0 is preserved, not a newly created journal.

`REMAINING_WORK_COMPLETION_GATE`: bounded correction machine-verified; exact pushed HEAD/CI readback is the publication gate. `IMPLEMENTATION_CORRECTION_RESCAN` and two scoped review loops: closed. `CLEAN_REVIEW_EXIT`: scoped only. Full-game UI/tutorial/routes/motion/art/balance/Human/package gates below remain open. Rollback: revert only this screen/test/document patch; private journal pre-append backup restores its original12pages. Do not revert the user's project.godot or delete historical sources.

Approved scope: R3 finite falling-pair CHAIN, LINE supply and selected enemy cell destruction. Source main `69f4f591e038b4912d9761bf943aefd986170ace`; current branch `codex/r3-runtime`, approved design commit `0937f4083eaea1fd14ce4fed474e5c4d2de210b3`. This is an implementation checkpoint, **not full-game completion**. R2 runtime, player files, existing art and protected Base9.4.4 contract remain preserved.

## Actual implementation and boundaries

Checkpoint UI follow-through: explicit pause save/load and reduced-motion switch now exist in R3. Native isolated writer/readback and487/487 full regression recorded in the screen/cast receipt. Do not treat older “no disk consumer” or “reduced-motion model only” statements below as the current view implementation. Options persistence, route/main menu/tutorial/input and full motion remain unfinished.

Latest performer follow-through: v2 chroma-derived nine-pose Vanguard now binds the isolated R3 cut-in as a candidate trial, superseding the temporary portrait-only statement below. Full regression484/484 and three native category fixtures are in [the current screen/cast receipt](../validation/r3-screen-cast-20260914/README.md). Smooth final motion, full UI and whole-game delivery remain open.

Latest continuation: separate `scenes/replanned_r3/main.tscn` now binds the actual R3 session to equal-width board/combat regions, finite falling pairs, category-only automatic skills, current/next threat and the shared ETA. Existing R2 main remains unchanged. A read-only cast presentation consumes committed unique receipts (620ms full / 240ms bounded follow-up), freezes during pause and suppresses restored receipts. The actor currently reuses the portrait as a **temporary presentation**, not the requested final animated skill performer. Full motion states, tutorial, remapping, route/save UI, audio and delivery are still required.

Screen/cut-in checks: initial screen 4/4; added focus/release/overlap regressions failed as expected, then corrected (LINE key release/focus loss must not lower a piece; CHAIN S release must end soft drop; bottom labels must not overlap boards). Actual chain clear → cast ledger → visible cut-in/recent-skill test initially failed its missing recent label, then passed. Latest R3 directory: 74/74 tests,2920 assertions,12 scripts, `r3-screen-cast-green.log`, stderr empty. This is source evidence, not whole-game completion.

Live correction: exact Tetris editor5852 was already connected through its own HiGodot8008/9508 route. Hera was enabled and verified at8773; the earlier absent-Hera blocker below is historical and resolved. R3 native run6 at1280×720 was live with no reported launch errors; actual command readback confirmed CHAIN,3 remaining pairs, pause and unchanged ETA4772639us. Asset resolver errors were empty. Screenshot initially remained stale while the window was not rendering; restoring/focusing the exact game window and forcing a frame produced the matching CHAIN view. A nonblank screenshot alone is therefore insufficient state evidence. Other editors and normal saves were not changed by the R3 screen (no disk consumer yet).

| Owner | Implemented | Remaining proof |
|---|---|---|
| Probe storage | isolated factory before ready, actual writer/path/report validation; real scene flow leaves normal save/backup hashes unchanged | Native visible probe |
| Supply | initial4/cap12, LINE10cells→3pairs, chronological credit/spawn replay, discarded overflow, atomic malformed-history rejection | UI supply feedback and Human balance |
| Falling board | NEXT2, 6×12+2 hidden, movement/kicks/lock cap, four-connected union, timed cascades, no refill, seeded queue, persistent IDs, terminal freeze | Actual R3 view/input/motion |
| LINE adapter | verified R2 collision/rotation reused; ID identity through row compression; enemy deletion without cell gravity | Native marked-target visual |
| Session/combat | candidate resource/supply transaction, one cast per player wave, category lock, finite spawn, shared ETA, inactive freeze, R3 skill hash; two scoped review loops closed | Whole-game flow/native presentation |
| Disruption | Current board lock, last2s ID reservation, sorted seeded selection, misses without reroll, no enemy rewards, wave-boundary queue, normalized receipts, profile/action/RELAXED counts | Readability and play balance |
| Save/route | separate R3 envelope/path, inherited readback/backup mechanics, R2 rejection, route progression uses R3 sessions | Both routes played to actual victory; package |
| UI/assets/PDF | isolated R3 screen and receipt-driven cut-in; existing R2 assets and main preserved | Task6–8 partial; final motion, tutorial/options/route, audio, package and updated PDF remain |

## Verification receipts

- R2 full directory: **156/156 tests,1588 assertions**, `r3-r2-regression2.log`, stderr empty. The first run had one incorrect test-duration assumption (outer encounter not dead at120s); corrected fixture to1000s and reran. No failed receipt counted as PASS.
- R3 models and integration: **54/54 tests,2785 assertions**, `r3-terminal-integration2.log`, exit0, stderr empty. Covers terminal save, component mashups, actual command/tick supply, two-wave automatic casts and queued destruction. Later route/save additions also pass focused **2/2,62 assertions** (`r3-expedition-green.log`). Final combined regression is tracked below when complete.
- Tooling Python tests: **90/90**,23.100s, exit0.
- Combined Godot regression after route/save additions: **465/465 tests,7089 assertions,77 scripts**,83.138s, `r3-full-regression.log`, stderr empty. This proves the tested source snapshot, not UI/native/package readiness.
- Final corrected-source regression: **467/467 tests,7098 assertions,77 scripts**,70.376s, `r3-final-full.log`, stderr empty. Direct LINE topout and future completed-action injection RED→GREEN are included. No R3 source changed after this run; later edits are documentation/publication only.
- Earlier `r3-terminal-integration.log` exited0 but skipped a malformed test script; **REJECTED_EVIDENCE**, not PASS. Fixed the parenthesis and verified expected script/test count plus empty stderr.
- Focused new board verification includes20seeds/240pairs all-phase JSON resume, but is not Human play or cross-Godot-version RNG proof.
- `git diff --check`: PASS at checkpoint. User `project.godot` hash unchanged: `46ce5e3295b0807f57fd16e07573ca7f0aa470c8e55696a8f8ca360d74caf020`.

All named logs are under `C:/Users/user/AppData/Local/Temp/`; they are diagnostic evidence, not normal player saves. No files were deleted or moved in this work.

## Review and learning

Storage source review: two loops plus bounded report correction review closed. Supply/LINE two source loops found history truncation, sequence rewind and missing post-restore destruction dedup coverage; corrected with chronological replay, exact sequence=4×lock invariant and direct regression. Integration first loop found terminal closure, authored-count scope, cross-owner validation and normalized-result gaps. Second loop found direct LINE-topout finalization and future enemy-history injection. All scoped findings were corrected and re-read closed; focused final correction9/9,132assertions passes. These are source/model reviews, not whole UI/native completion.

Godot JSON key ordering: adding checksum through a dot-created key caused native/readback canonical ordering to differ. Explicit string-key insertion fixed exact readback; no weakened checksum validation. Nested JSON numbers are normalized after validation. These are project lessons; **no Base promotion** or memory write was performed.

## Live-editor boundary and remaining work

`hera status` selected urban-legend, and `hera instances` listed only urban-legend10052, GRIMOIRE8604 and Blacksmith10768. None was Tetris. **No mutation was sent to those editors.** The earlier Tetris HiGodot connection used its own8008/9508 route; that does not establish a Tetris Hera connection. Before the required live-editor UI workflow, attach/enable the expected addon for the exact Tetris editor and re-read identity. Do not claim native R3 verification from headless tests or another project.

`REMAINING_WORK_COMPLETION_GATE`: NOT COMPLETE. `IMPLEMENTATION_CORRECTION_RESCAN`: scoped source/model findings closed. `POST_COMPLETION_ADVERSARIAL_REVIEW_REQUIRED`: whole-result UI/native review not yet complete. `CLEAN_REVIEW_EXIT`: scoped model/source only, not full R3. Task6 view/input/tutorial, Task7 assets/motion/audio, Task8 strategy comparison/native/package/PDF/PR/main remain. No release or final art/Human approval claimed.

Rollback: isolated new R3 source/data/tests and the narrowly scoped R2 probe/report correction can be reverted independently. Do not delete approved R2 assets, player saves or the pre-existing draft PR117.

Workboard note: delivery statuses remain Task0 `VERIFY_REVIEW`, later tasks `BACKLOG` until predecessor publication gates close; their attached machine evidence records already-written source without falsely marking complete delivery. The initial multi-IN_PROGRESS update violated the adopted WIP limit and was corrected; current receipt start validation passes.
