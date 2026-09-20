# Bonus-assist implementation evidence - 2026-09-20

## User-testable scope

Open `scenes/replanned_r3/resource_choice.tscn` in the exact Tetris checkout and run the scene (not the preserved production default). Choose LINE or SWAP and one of four enemies, or `2연쇄 짧은 연습`. Resource progress fills at most10 waiting pairs; excess earned pairs become bonus mana. `보너스 보정` queues at a safe boundary, then choose a fixed cell and symbol/left/right, or emergency heal/attack/armor. Cancel/noop/invalid inputs are free. Action presentation and selection freeze both board time and enemy ETA. Starter symbol determines one skill after the whole chain.

New save namespace `user://bonus_assist/`; legacy/default/campaign saves and other worktrees/Drafts are preserved. New trial numbers are not measured human balance. Previous positive user feedback belongs to the preceding version, not this change.

## Verified evidence

- Gameplay source `f33f4bb643eb2ba1000f38219da256db597d1432`: full Godot4.7.1/GUT9.7.1 run, **543/543 tests, 7,548 assertions,83 scripts,85.022s**, exit0. `full-gut.log` has no error/warning/leak markers. Focused assist23tests included RED/GREEN reproductions of missing policies and review defects.
- Tooling **95/95**, including new PDF source/hash/historical page preservation. Workflow adoption validator PASS, source Base23ecad5a3084f97c4e5d1e39a9a6d70d1eeb37ef; release9.4.4 unchanged. Exact-head remote checks and postmerge readback are recorded in the execution receipt, not assumed here.
- `tests/tooling/assist_native_probe.gd` ran on **NVIDIA RTX3050 native OpenGL**. `runtime.json` records actual SWAP-earned9 bonus, cost2 correction, safe-boundary clock freeze, paid correction disk restore,2waves/one practice skill,actual enemy destruction. Dedicated userdata only. All captures use actual renderer at1280×720 and960×540. Tier1/3/6 comparison shots are **authored presentation fixtures**, not human-earned chains.
- Parent visually inspected preparation, bonus panel, practice impact, enemy aftermath and T6 at1280 plus bonus960. Corrected overlapping T6 caption and practice exit/queue. PDF new9pages rendered/inspected; final exact-source footer changed but all9page bodies were pixel-identical to inspected renders.
- Current reader is **61pages**,9new +52preserved. All52 historical page content streams match source PDF; original37page COMPLETE PDF and its frozen source are unchanged. Manifest binds new source separately from historical source. Monthly private journal appends one dated page in the same v1.1 path; old15page streams preserved, final16pages. It does not authenticate dates or imply account/payment/submission verification.

## Review and correction

Two full parent review loops share this approved scope, not repeated per phase.

1. Re-read requirements, runtime consumers, save boundary and rendered UI. Found selected enemy cut-in/load mismatch, caption/exit overlap and instance-lifetime warning from static assist rules cache. Added failing tests or native evidence, corrected exact consumer/layout/instance cache, reran focused/full/native checks. No broad legacy edits.
2. Re-read final economics/input/transactions/artifact source ownership. Invalid surplus command arguments could apply a paid effect that its own save validator rejected; RED reproduced cost and board mutation, exact-argument guard corrected before mutation. Frozen historical reader source was restored instead of loosening its byte hash test. Full543 and tooling95 passed; no remaining blocking finding within approved scope.

Independent reviewer inspected whole code at2f07c83 and reproduced P1 ward restore/resource transaction failure and P2 soft-drop release, erased spend-history refund, encounter dropdown mismatch. All four corrected at3160641; reviewer re-ran diagnostics and confirmed exhausted findings/no new blockers. Assist-only combat factory now reaches initial combat, LINE/SWAP transaction clones and receipt probes. Paired spend digests enforce ledger consistency, not cryptographic anti-cheat against rewriting the entire local save. Final surplus-argument guard is covered by an additional RED/GREEN regression.

Human beginner success rate, skill payoff, mode balance, physical input/accessibility, full campaign adoption, final art and release remain **NOT_RUN / separate product scope**. Automated and native evidence never substitute for these gates.

## Reuse and rollback

ADAPT existing supply/chain/finisher/combat/disk/UI/assets and PDF helpers. No new images/plugins/global settings/paid services. Project-only lessons: isolate authored effect validation with the new rules; input release survives modal gameplay locks; validate bonus spend and effect receipts together; preserve historical PDF source bytes. No Base promotion justified by a single project case (`NO_NEW_REUSE_LEARNING` for shared modules). Rollback: normal reviewed revert of this bounded change; no save deletion or migration. Task-specific disposable renders/logs go to user deletion-review storage, never a broad cleanup.

## Publication and postmerge readback

- [PR124](https://github.com/alsdmlals4-eng/Tetris/pull/124) normal squash merge: `67850b8969fa491b7e68fe43fb7ad4c80b9b4597`. Exact reviewed HEAD `6b7b13fff33a4246c5b078d785db523730e32994`: validate, godot-validation and windows-powershell-contract all SUCCESS; ready/mergeable, unresolved threads0, rules API[]. Complete Git trees match after fetch.
- Postmerge at67850b8: full GUT **543/543,7548assertions,83scripts,67.766s**, exit0; Python tooling **95/95,22.949s**, exit0. Commands: Godot4.7.1 `--headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`; bundled Python `-m unittest discover -s tests/tooling -p test_*.py`. No test/leak/error markers. Same approved scope, not additional full adversarial loops.
- Final independent review6b7b13f confirmed strict extra-argument guard and source/publication evidence; directly ran3PDF tests. Reviewer did not claim full543rerun or render inspection. Parent owns those distinct observations above.
- Published current-reader SHA256 `103daa0d9958740cae1fc15a127f9277af3d4e3699871f26c5ca6e325e003694`; private same-path16page journal SHA256 `607478d7f11e9f9f758539d1bd6b126635aa6488a0f58c33b418e68252f051f6`. Journal entry `T-20260920-BONUS-ASSIST`; idempotence readback ALREADY_APPENDED16. Private originals, backups and account/payment evidence remain outside repository.
- [Machine claim/acceptance mapping](review-record.json) supplements this existing evidence owner; TEST evidence only. Native captures, visual review and HUMAN exclusions remain separately stated, not upgraded by a checker.
