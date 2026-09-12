# R2 playtest records — implementation plan

## Direction and approval

Make existing R2 first-encounter results portable for local playtest review without changing combat, balance, art, save schema or the preserved production baseline. User approved the preceding recommendation with `좋아 권장안대로 작업진행해` on 2026-09-13; plan-first applies before implementation. This is a bounded extension of existing results, not a new analytics service.

Source main: `9972c580db4854554399424fa05bd7343e83035d`. Current rules: `docs/design/REPLANNING_AUTOCAST_R2.md`; source metrics: `src/replanned_r2/r2_session.gd`; current result consumer: `src/replanned_r2/r2_screen.gd::_show_result`. Existing implementation already displays the result metrics: do not recreate or replace that view. Open drafts 100/85/46/33/23/19 are read-only, not implementation inputs. Existing PDF and candidate artwork remain untouched. Base adapter 9.4.4 stays pinned.

## Comparison and feasibility

1. Keep screenshots alone: no new data writer, but hard to compare numerical results and rule identities. Retain as complementary visual evidence.
2. Reuse existing metrics and add an explicit local JSON export: selected. No ongoing logging, new currency, server, dependency or duplicated event counter.
3. Add cloud telemetry/full replay: reject for this scope; unnecessary privacy, storage, cost and determinism claims.

Base reuse: TETRIS profile entries are planned hints, not adopted runtime. RM-TOOL-004 contributes repository/native evidence identity boundaries; RM-TOOL-002 is not a built replay service. No cross-project code transplant is needed for this direct existing consumer.

Research: Godot FileAccess official documentation was read on 2026-09-13 (https://docs.godotengine.org/en/stable/classes/class_fileaccess.html): local user data and explicit write/error/close readback, ADAPT. Mega Crit's GDC metrics-and-feedback session description read in the preceding planning turn is REUSED_EVIDENCE; this turn's repeat fetch failed, so no new full-video or interview claim. No new policy or gameplay mechanic is inferred from the source.

Feasibility: FEASIBLE data projection and manual local write using existing Godot APIs. Actual authoring, tests and runtime proof remain separate. Godot readiness recovery found MCP initialize 3.4.7 versus installed addon 3.2.0; do not author through an unverified upgrade. Restore the existing pinned 3.2.0 execution path first, without modifying global settings or project vendor files.

## Contract

- Add `src/replanned_r2/r2_playtest_report.gd`, a read-only report builder and local writer. Input is the existing stable session snapshot plus whether the result is a practice completion. Reject absent/unstable snapshots; do not mutate session or gameplay save.
- Report contains schema `r2-playtest-report-v1`, run ID, mode, encounter ID, rule-pack hash, shape seed, active simulation microseconds, outcome, practice classification, existing metrics and remaining resources. No names, machine paths, wall-clock duration claims or user identifiers are collected.
- Runtime engine version and report schema are not exact build identity. `implementation_revision` remains `UNRECORDED` unless supplied by verified packaging metadata; do not invent a SHA. Cross-build comparison requires the observer to record the delivered package/commit separately.
- Manual Result export only. No auto-write on result opening. Output folder `user://replanned_r2/playtest_reports`; filenames use report-content SHA256, never raw run IDs. Same contents resolve to the same file and exact bytes are compared before reporting an existing success. Differing existing bytes fail closed; never overwrite or delete.
- A successful write is read back; errors return an explicit reason. A report is diagnostic evidence, never a resumable save. Practice and ordinary results have explicit distinct classifications. In-progress exports are rejected unless explicitly classified practice completion.
- Existing result values and combat timing remain unchanged. Report failure must not block Retry/Main or alter the checkpoint. Local status explains success/failure and location. At 125% font size the added controls must remain inside the result panel.

## Ordered implementation and verification

### Task 1 — report projection and safe local write

Files: new `src/replanned_r2/r2_playtest_report.gd`, new `tests/replanned_r2/test_r2_playtest_report.gd`.

- [ ] RED: missing report builder; a real completed session fixture produces outcome/run/rule identity and independently expected metrics; input snapshot remains equal after report creation.
- [ ] RED: ordinary running/empty snapshots rejected; practice completion distinctly labelled.
- [ ] RED: write creates parseable bytes, repeated identical write does not change bytes, conflicting existing bytes fail without overwrite, unavailable directory fails without gameplay writes.
- [ ] Implement only those boundaries through the pinned HiGodot authority; rerun focused GUT GREEN.

### Task 2 — existing Result consumer integration

Files: `src/replanned_r2/r2_screen.gd`, `tests/replanned_r2/test_r2_screen.gd`.

- [ ] RED: Result exposes manual export; opening Result alone produces no report.
- [ ] Connect the report builder to the existing snapshot and writer; separate status text and readable button.
- [ ] Test preserved checkpoint/metrics on success and failure; existing Retry/Main remain usable.
- [ ] Native result/keyboard navigation and 100%/125% layout readback, full GUT, packaging dependency coverage and exported-run check. Do not label signal-emission tests as normal native input evidence.

### Task 3 — human observation preparation and closure

- [ ] Complete the observation instructions below and retain NOT_RUN for actual human answers.
- [ ] Exactly two whole-result review loops; fix findings and rerun affected regressions.
- [ ] Record exact commit, tests, runtime evidence, package location, source protection and remaining work in this owner. Keep the earlier five-item implementation receipt as completed history; this task has its own receipt.
- [ ] Publish only after checks/review pass; no direct main push or unrelated PR mutation.

## Human observation procedure (prepared, not performed)

Use an anonymous local participant code, package identity, input device, font setting and prior LINE/CHAIN experience. Record first exposure separately from coached/repeat attempts. Do not collect personal identifiers or upload recordings automatically.

First let the participant use the normal menu and practice with no additional coaching. Ask afterward: What does each board provide? What triggers a skill? What does the shared timer mean? When would you choose DEF or SUP? After failure, what would you change next time? Record their actual words, observer interventions and whether the answer was prompted.

Then permit same-seed retry. Save one report per result; record whether a run was fresh, restored, practice or coached. Do not compare unmatched rule hashes/builds as controlled pairs. Screen captures explain readability; JSON describes numerical outcomes. Neither alone proves enjoyment or causal balance improvements.

Initial acceptance is problem discovery: classify each misunderstanding as observed/not observed/not tested and identify at most a small evidence-backed next correction set. No fabricated fun score, win-rate target, universal sample-size claim or automatic balance changes. Mixed, CHAIN-only and LINE-heavy strategies are later comparison conditions, not new mandatory game modes.

## Preservation, rollback and learning

Preserve production, approved/frozen PDF bytes, artwork, combat/session/save schema, user options/save/backup, Base pins and unrelated work. New report files are user-owned diagnostics, not deleted automatically. Rollback only this task's report module/UI/tests after reference checks; existing saves need no migration. Project-only lesson: inspect existing result metrics before proposing a replacement analytics subsystem. No Base promotion is claimed.

## Current evidence

Planning prepared; implementation NOT_RUN, runtime NOT_RUN, Human NOT_RUN. No readiness or complete-game claim follows from this document.

2026-09-13 preflight: receipt start validation initially rejected unsupported TODO states; replaced by existing BACKLOG vocabulary. Windows cp949 could not print the report em dash; current-process PYTHONIOENCODING=utf-8 rerun exited0 with start PASS and 0/3 implemented tasks. Neither was a product-test failure.

Readiness recovery: current attached godot-ai connector twice returned sessions=[]; Hera reported no live editor. Started exact dedicated Tetris editor28852, observed project/session tetris@2ce3 and installed plugin3.2.0, but MCP initialize identified server3.4.7. Quit that task-owned editor gracefully. Existing `uvx --from godot-ai==3.2.0 godot-ai --version` reported3.2.0. Started pinned task-owned transport launcher14832 and editor27976. Subsequent direct-endpoint initialization request was rejected by execution policy; did not retry the denied operation through another shell/client or write Godot sources. Connector still has no Tetris session. Runtime implementation is DEFERRED_EXTERNAL_EXECUTOR until an allowed connector verifies exact Tetris path and pinned server/editor pair. No addon, global configuration or version lock was upgraded.

Planning review1: removed duplicate result-screen construction because _show_result already exposes metrics; retained local export only. Planning review2: kept engine version/report schema distinct from exact build revision; unbound reports must not claim controlled cross-build comparison. Stable snapshot, practice classification, failure/no-overwrite and save preservation remain explicit acceptance criteria. These are planning checks, not the implementation's required two final full-result reviews.

Final deferred state intentionally has no active executable task. The start gate must now refuse execution until the connection blocker is resolved; do not reuse the earlier pre-blocker start PASS as present authorization. Tracking shape is checked separately as information only. No implementation or runtime test has run in this follow-up. Task-owned editor27976 did not accept CloseMainWindow (returned false); no broad or forced process cleanup was attempted, and cleanup completion is not claimed. Remaining local transport/editor processes must be reidentified before resumption or shutdown.
