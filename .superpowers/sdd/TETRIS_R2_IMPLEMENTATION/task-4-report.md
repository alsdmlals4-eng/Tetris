# Task 4 report — portable local Windows R2 trial

- status: `DONE_WITH_CONCERNS`
- implementation commits: `ed96b5ab0b2d4386ddb19fa139bc012da571f563` (`build: package native R2 local trial`), `48b644d5843cbb2119459c7c838829a373199a8c` (`fix: render raw asset folder in trial readme`)
- task continuation base: `36d2f2a`; concurrent parent documentation commits through `8bee0ebaac116632ef0173e90b754915fd00afa7` were preserved before implementation
- final package source HEAD: `48b644d5843cbb2119459c7c838829a373199a8c`
- final retained package: `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\final-48b644d-20260912-104000`
- launcher: `START_R2_LOCAL_TRIAL.cmd`
- package purpose: local Windows candidate review only; no upload, public release, art approval, rights approval, accessibility approval or user approval is claimed

## Work-before problem

The implemented R2 could run from the editor, but there was no bounded native Windows package. A plain selected-resource export was not enough:

1. The dedicated Godot executable uses self-contained `editor_data` and could not find export templates there.
2. The installed release template does not support `--path`, positional scene overrides or `--scene`; a launcher argument therefore could not safely select R2.
3. The first selected pack omitted preloaded R2 model dependencies until those scripts were selected explicitly.
4. Godot remapped the five PNGs to imported `.ctex` resources. The runtime loader's intentional `FileAccess.get_sha256(res://...png)` checks then saw empty hashes, while the screen exposed the failure only as `Main/Status.text`. Exit code and log-keyword smoke alone would have produced false confidence.

Production main, the existing helper autoload, the dirty `project.godot` blank line, generated import/UID metadata, production saves and all baseline assets had to remain untouched.

## Compared methods and ruling

| Method | Ruling | Reason |
| --- | --- | --- |
| Ship the editable repository plus editor | `REJECT` | Includes unrelated source, addons, tests and authoring state; not a focused player-facing trial. |
| Native selected-resource export plus reversible export snapshot | `ADOPT` | Packages only the R2 scene, explicit data/assets/scripts and dependencies; keeps on-disk production main unchanged and reuses installed Godot templates plus the existing helper-strip plugin. |
| Copy the project and rewrite copied settings | `REJECT` | Creates a second project authority and makes later drift/rollback harder to audit. |
| Add raw PNG bytes inside the PCK through a new `EditorExportPlugin.add_file` owner | `REJECT_FOR_THIS_TASK` | The official API can add arbitrary bytes, but it would require registering and maintaining another export plugin or changing the protected vendor plugin. The already verified sidecar keeps the original bytes directly inspectable, hashes them in the package manifest, avoids vendor mutation, and lets the release runtime locate them beside its executable. Reconsider only if a later distribution channel requires a single-file payload. |

The implementation uses Godot's normal `--export-pack`, copies the already installed matching release template and ICU data beside the same-name PCK, and starts the executable without unsupported path/scene arguments. This is template assembly, not a replacement exporter. The export-only in-memory snapshot selects `res://scenes/replanned_r2/main.tscn`; the existing Godot AI export plugin independently strips its helper autoload and restores it after export.

Godot 4.7.1's startup implementation guards path and scene overrides behind the build option used by the release template, matching the reproduced rejection: [Godot `main.cpp` 4.7.1-stable](https://raw.githubusercontent.com/godotengine/godot/4.7.1-stable/main/main.cpp). The portable launcher therefore relies only on Godot's automatic same-basename `.exe`/`.pck` discovery.

## Implemented structure

- `export_presets.cfg`
  - Adds non-runnable `Windows R2 Local Trial` selected-resource preset.
  - Selects the R2 scene, three JSON inputs, five atlas resources, eight R2 scripts and three reused production LINE scripts.
  - Excludes `addons/godot_ai/**`, `tests/**` and `.superpowers/**` from the package.
- `tools/windows/build_r2_local_trial.ps1`
  - Refuses output inside the repository and refuses to overwrite a non-empty directory.
  - Runs native export and both smoke processes with hidden windows, redirected logs and `WaitForExit()`.
  - Uses installed Godot 4.7.1 release template + `icudt_godot.dat` after a real pack export.
  - Copies exactly the five canonical PNG bytes to `r2-source-assets/<canonical path>` only after checking each source against approved metadata.
  - Creates a Korean local-trial README, a no-argument launcher, smoke/probe JSON, exact source HEAD and an 18-artifact SHA-256 manifest.
  - `-VerifyPackageOnly` verifies the required executable/PCK/ICU/evidence files, exactly one entry for every required raw atlas, approved atlas hashes, safe relative paths and every artifact byte hash.
- `tools/windows/r2_export_snapshot.gd` and `r2_export_driver.gd`
  - Change only the in-memory export snapshot main, are idempotent, and restore the previous main in `_finalize()` without calling `ProjectSettings.save()`.
- `tools/windows/r2_export_probe.gd`
  - Loads the real PCK, verifies R2 exported main, absence of helper autoload, all three JSON documents, five original source hashes, `r2_assets.errors`, five asset consumers, Korean system-font characters, R2 scene instantiation and Practice-to-battle entry.
- `src/replanned_r2/r2_assets.gd`
  - Keeps the editor/default `res://` source-hash path.
  - Accepts an explicit source root for focused tests and the pack probe.
  - In a release executable, resolves original hash bytes at the adjacent `r2-source-assets` folder while still loading textures from Godot's imported/remapped `res://` resources.
  - Keeps the existing explicit `Asset hash mismatch: <id>` and wrong-size errors; it does not bypass or downgrade integrity checks.
- tests
  - `tests/replanned_r2/test_r2_assets.gd`: valid external root, deliberately tampered bytes and missing root.
  - `tests/tooling/r2_export_snapshot_test.gd`: export-only R2 main and exact restoration, helper separation and repeated-begin safety.
  - `tests/tooling/test_r2_windows_package.py`: exact selected set, production-main preservation, exclusions, cross-platform `pwsh`/`powershell` selection, intact verifier, missing ICU, missing raw atlas and tampered package rejection.

No production main entry, production gameplay rule, source PNG, asset catalog, addon/vendor file, saved-game schema or public-release surface was changed.

## TDD and reproduced correction evidence

- Package contract RED: `0/3` because preset and builder did not exist. GREEN: `3/3`.
- Snapshot RED: initial snapshot test could not load the missing owner; the earlier idea of changing the loaded vendor export plugin was rejected when HiGodot correctly refused a crash-prone write to the loaded plugin path. GREEN: standalone process exit `0`, `R2_EXPORT_SNAPSHOT_TEST_PASS`.
- Actual pack RED at `snapshot-20260912-101539`: all five `raw_asset_hashes` were empty and `asset_errors` contained all five explicit mismatches. This was the bounded evidence required before changing `r2_assets.gd`.
- Asset-owner RED: the new test could not construct `Assets.new(source_root)` because the owner accepted no source root. GREEN: `3/3`, 17 assertions; valid root loads all five remapped textures, deliberately tampered bytes fail, and a missing root yields five named errors.
- Verifier RED: removing one raw-atlas manifest entry still returned exit `0`. GREEN: missing raw atlas is rejected, alongside missing ICU and arbitrary PCK tampering.
- Review-loop correction: the first otherwise valid README printed `$RawAssetDirectoryName` literally. Commit `48b644d` corrects it to `r2-source-assets`; the rebuilt README and exact manifest were read back.

## Actual export failures and bounded fallback

Preserved evidence folders (no files were deleted):

- `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\preflight-20260912-100001`
  - Direct `--export-release` failed because the self-contained executable searched its dedicated `editor_data/export_templates/4.7.1.stable` and found no templates.
- `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\preflight-pack-20260912-100413`
  - `--export-pack` succeeded and demonstrated helper stripping, but the release template rejected launcher/probe `--path` with `disable_path_overrides`.
- `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\snapshot-20260912-101539`
  - Export-only R2 main and dependencies succeeded; the pack-loaded probe exposed all five missing raw hashes. It also exposed an obsolete probe expectation that exported main should remain production; the corrected contract expects R2 in the exported snapshot and production in the source project.

`--export-pack` plus installed matching template assembly was selected because it uses the actual Godot pack pipeline and existing template bytes even when the self-contained editor cannot discover the global template directory. PCK-only output was not called a playable deliverable.

## Final package readback

- Final directory: `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\final-48b644d-20260912-104000`
- `BUILD_MANIFEST.json` source HEAD: `48b644d5843cbb2119459c7c838829a373199a8c` (exactly matched `git rev-parse HEAD` at build time)
- Source `project.godot` SHA-256 before export, in manifest and after export: `46ce5e3295b0807f57fd16e07573ca7f0aa470c8e55696a8f8ca360d74caf020`
- Source production entry readback: `res://scenes/production/battle_briefing.tscn`
- Preserved tracked dirty path recorded by final manifest: only `project.godot`
- Artifacts: 18 manifest entries, 133,160,365 aggregate bytes
- EXE: 109,212,160 bytes, SHA-256 `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07`
- PCK: 8,192,328 bytes, SHA-256 `4b9ba1748ab48f3eda4e9fd6bce57bde75b8090bd5ab198a4bf896c7cc4baff6`
- Five external original atlas hashes exactly matched canonical metadata:
  - `R1-ICONS`: `40d55313aeff152106a7bfd2a5f22615cace29ee8d4b8c483195bc02384cdbde`
  - `R1-PORTRAIT`: `cb2ea6fe04f765fe2baf6c782988f6a1346cbdd95c0bca60e875d0757bdb49e9`
  - `R1-ENV`: `982b48dcd60708440bd87fa701589c71b56d80832bc690209089a2d3d2e588c4`
  - `R2-TILES`: `6da54b7be30ff875153d0dde7611b133709f78be8cfd0b0653f6efa3f0d7a21b`
  - `R2-BOSS`: `59976e21209aac65fef13ae70c5976af4babed6ee00a11210bd8cf7bed89081f`
- Pack probe: `ok=true`; `asset_errors=[]`; three JSON documents valid; Korean characters available; helper autoload absent; R2 main instantiated; Practice entered battle.
- Native headless executable smoke: exit `0`, no forbidden-output hit; `smoke.stderr.log` empty.
- Pack-loaded external probe: exit `0`, `probe.stderr.log` empty.
- Final `-VerifyPackageOnly`: exit `0`, `R2_LOCAL_TRIAL_PACKAGE_VERIFIED`.

## Automated regression evidence

- Focused asset GUT: exit `0`, `3/3`, 17 assertions.
- Snapshot standalone test: exit `0`, `R2_EXPORT_SNAPSHOT_TEST_PASS`.
- Package Python unit tests after final fix: exit `0`, `3/3`.
- Full Python tooling suite: exit `0`, `82/82` tests.
- Full recursive GUT suite: exit `0`, 58 scripts, `340/340` tests, 3,572 assertions.
- A preceding GUT invocation omitted `-ginclude_subdirs` and emitted `Nothing was run`; it is explicitly `NOT_EVIDENCE`. The corrected recursive invocation produced the counts above.

## Native Windows UI sampling

The parent verifier launched the native executable built at `ed96b5a`; its EXE and PCK SHA-256 values are byte-for-byte identical to the final `48b644d` package, so the runtime observations apply to the final payload. The later commit changed only README interpolation and manifest/source-HEAD metadata.

- The window launched, maximized, and restored to 1280-width presentation.
- All five visual families and Korean text were visible.
- Practice 1 with Space produced the actual LINE receipt `A4 / D2 / H2 / T2`, bank 4, armor 2, HP 82, ETA 10.5.
- Practice 2 UI swap `(4,5) ↔ (5,5)` produced two automatic casts, boss HP `240 → 230`, and direct tile resource `0`, preserving the LINE/CHAIN role split.
- Pause returned to main.
- Pre-existing R2 options, primary save and backup were unchanged before/after QA. QA used Practice instead of New Run: `options.json` `9d5e9dba265f31673e311326d112ef47ea354e1da1544ce981896fd9614ab703`; `save.json` `0500831f3666bdafa102311773fa3f324db688f049ec0234d79e3b7aed2a65a7`; `save.json.bak` `6f55a6073c48d70009b03263bbebd89c71c331d2f4700c3b6bb24fb88684117c`.
- Parent-owned captures and their evidence manifest were committed in `a60bd2d`: `docs/validation/r2-package-20260912/main-1280-ed96b5a.png`, `line-receipt-ed96b5a.png`, `chain-two-casts-ed96b5a.png`, `manifest.json`.

This is `RUNTIME_VERIFIED` for the sampled native flows and machine-assisted visual inspection. It is not a fresh-player study, accessibility/device matrix, balance/fun conclusion, final art approval or user approval.

## Adversarial review loops

1. Full package/export loop found three blocking issues: release-template discovery, unsupported template scene/path override, and the five remapped raw hashes. The chosen fixes retained native Godot export, source hash enforcement and source production settings. Regression rerun passed.
2. Full final artifact/readme/manifest/runtime loop found one user-facing README interpolation defect and corrected it. Exact HEAD/hash readback, focused tests, package verification and byte comparison reran successfully. No new Task 4 blocking finding remained.

The export process log is intentionally **not clean**: the combined `--editor --script ... --export-pack` process exits `0` after writing and restoring the snapshot, but reports six Canvas RIDs, 36 CanvasItem RIDs, 209 ObjectDB instances and additional viewport/texture/scenario/text/font RID allocations leaked during shutdown. A comparison `--headless --editor --quit` process exited `0` without those warnings, so they are specific to this scripted editor/export termination path rather than a general headless startup baseline. The exported executable smoke and pack probe have empty stderr and the playable payload is unaffected in the sampled flows, but the warning remains a known tooling-lifecycle concern and prevents claiming a warning-clean export. Per parent direction it does not justify unrelated framework or gameplay work in Task 4.

## Preservation, rollback and retained folders

- HiGodot was the only persistent Godot writer for `.gd`/`export_presets.cfg`; the exact editor PID 37444 was released after write/readback and confirmed exited. Other project editors/processes were not touched.
- Dirty `project.godot`, untracked imports, unrelated UIDs, baseline assets and parent-owned native captures were preserved and not staged by this task.
- Rollback source changes by reverting `48b644d` then `ed96b5a`; this does not require touching production saves or deleting source assets.
- Keep as the valid user-facing trial: `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\final-48b644d-20260912-104000`.
- Exact obsolete/intermediate folders eligible for the parent's later move to `C:\Users\user\Desktop\Tetris_삭제대기_20260912` (not deleted or moved by Task 4):
  - `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\preflight-20260912-100001`
  - `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\preflight-pack-20260912-100413`
  - `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\snapshot-20260912-101539`
  - `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\rawfix-20260912-102500`
  - `C:\Users\user\Documents\Tetris R2 Local Trial\Builds\final-ed96b5a-20260912-102800`

## Remaining risks and next work

- `KNOWN_TOOLING_WARNING`: scripted editor/export termination emits leak warnings as described above.
- `TASK5_NOT_IMPLEMENTED_HERE`: native QA exposed a separate user-facing Practice pause description that says the current state is saveable even though `checkpoint()` correctly prohibits Practice saves. This belongs to the already queued Task 5 presentation/guidance correction and did not change Task 4 package behavior.
- `HUMAN_UX_NOT_RUN`: no fresh-player comprehension, accessibility/device matrix or user acceptance was performed.
- `ART_RIGHTS_RELEASE_NOT_APPROVED`: candidate art provenance status remains pending final user review; no public-release claim or upload is authorized.
- `NO_NEW_REUSE_LEARNING`: Task 4 produced project-specific evidence about this self-contained Godot installation and its release template. No Base rule, registry or shared exporter was changed. The sidecar-vs-`add_file` trade-off is recorded above for later reconsideration if a single-file distribution constraint becomes real.

`REMAINING_WORK_COMPLETION_GATE`: Task 4 acceptance is satisfied with the warning/evidence ceilings above; the separate Task 5 text correction remains. `IMPLEMENTATION_CORRECTION_RESCAN`: PASS for owned files and final package. `POST_COMPLETION_ADVERSARIAL_REVIEW_REQUIRED`: two loops completed. `CLEAN_REVIEW_EXIT`: clean of blocking Task 4 findings, but not warning-clean and not Human/art/rights/release approved.
