# R3 implementation checkpoint — 2026-09-14

Approved scope: R3 finite falling-pair CHAIN, LINE supply and selected enemy cell destruction. Source main `69f4f591e038b4912d9761bf943aefd986170ace`; current branch `codex/r3-runtime`, approved design commit `0937f4083eaea1fd14ce4fed474e5c4d2de210b3`. This is an implementation checkpoint, **not full-game completion**. R2 runtime, player files, existing art and protected Base9.4.4 contract remain preserved.

## Actual implementation and boundaries

| Owner | Implemented | Remaining proof |
|---|---|---|
| Probe storage | isolated factory before ready, actual writer/path/report validation; real scene flow leaves normal save/backup hashes unchanged | Native visible probe |
| Supply | initial4/cap12, LINE10cells→3pairs, chronological credit/spawn replay, discarded overflow, atomic malformed-history rejection | UI supply feedback and Human balance |
| Falling board | NEXT2, 6×12+2 hidden, movement/kicks/lock cap, four-connected union, timed cascades, no refill, seeded queue, persistent IDs, terminal freeze | Actual R3 view/input/motion |
| LINE adapter | verified R2 collision/rotation reused; ID identity through row compression; enemy deletion without cell gravity | Native marked-target visual |
| Session/combat | candidate resource/supply transaction, one cast per player wave, category lock, finite spawn, shared ETA, inactive freeze, R3 skill hash; two scoped review loops closed | Whole-game flow/native presentation |
| Disruption | Current board lock, last2s ID reservation, sorted seeded selection, misses without reroll, no enemy rewards, wave-boundary queue, normalized receipts, profile/action/RELAXED counts | Readability and play balance |
| Save/route | separate R3 envelope/path, inherited readback/backup mechanics, R2 rejection, route progression uses R3 sessions | Both routes played to actual victory; package |
| UI/assets/PDF | existing R2 assets and screen untouched | Task6–8 not implemented; no R3 main scene yet |

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
