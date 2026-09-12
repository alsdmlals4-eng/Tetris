# Final follow-up integration fix report

- status: `MACHINE_VERIFIED_PARENT_NATIVE_REVIEW_PENDING`
- requirements base: `07a7007fd1c13b5a036d494baafc10e794928d75`
- execution HEAD before owned commit: `fc08fe13cb87879dea473b8f82797ba1d6ba88b4` (parent metadata-only continuation; R2 runtime source bytes still matched `07a7007`)
- owned files: `tools/windows/build_r2_local_trial.ps1`, `tests/tooling/test_r2_windows_package.py`, `src/replanned_r2/r2_screen.gd`, `tests/replanned_r2/test_r2_screen.gd`, this report
- excluded and preserved: gameplay/data/save/assets/export selection/production main, `project.godot`, parent progress/manifest metadata, unknown `.import`/`.uid` files, existing trial packages

## Work-before problems and exact reproduction

The final integration review identified two verifier defects and one dynamic-layout hypothesis. All three were reproduced before production edits.

1. A disposable otherwise-valid 18-artifact package with a real Windows Hidden-attribute `hidden-extra.txt` was accepted by the PowerShell 7 verifier (exit `0`). A second fixture with a normal `nested-extra.txt` inside a Hidden-attribute directory was also outside the prior enumeration. Root cause: `Get-ChildItem -File -Recurse` suppresses Hidden children without `-Force`.
2. The same intact fixture under Windows PowerShell `5.1.26100.9278` failed before verification with `System.IO.Path does not contain a method named 'GetRelativePath'`. PowerShell `7.6.5` passed. Root cause: the script called a newer .NET API even though the test runner intentionally supports the Windows PowerShell fallback.
3. Focused GUT at 125% with real saved-mapping mutation reproduced the Pause overflow. `ScrollLock` expanded the authored 130x36 button to 192x37 and global right x678; `CapsLock` expanded it to 186x37 and global right x672. The Puzzle pane ends x632 and the Combat pane begins x648. Root cause: Godot `Button.clip_text=false` makes the control wide enough for its text, so the fixed authored width was not retained after the long dynamic label changed.

The RED receipts were:

- package suite: `7/9` passing, two failures; the intact Windows PowerShell 5.1 fixture failed on `GetRelativePath`, and the Hidden-file verifier returned exit `0` instead of rejecting it;
- isolated Hidden test under PowerShell 7: verifier exit `0`, expected nonzero;
- focused screen GUT: `31/32`, `376/382` assertions, exit `1`, with the exact 192/186 widths and x678/x672 right edges above.

## Research, alternatives and decisions

This was a bounded correction of existing consumers, so the current Task 4/5 reports and actual implementation were reused instead of reopening broad product benchmarking. The only fresh external checks were the directly relevant official APIs:

- Godot 4.7 `Button` documents that `clip_text=true` clips oversized text horizontally and prevents text from forcing button width, while `text_overrun_behavior` selects the clipping behavior: <https://docs.godotengine.org/en/4.7/classes/class_button.html>.
- Microsoft documents `Path.GetRelativePath` on newer .NET surfaces; the actual Windows PowerShell 5.1 process proved that its .NET Framework surface does not provide it: <https://learn.microsoft.com/en-us/dotnet/api/system.io.path.getrelativepath>.

Decisions:

| Problem | Alternative | Ruling |
|---|---|---|
| Hidden package entries | keep default enumeration or drop the closed-world check | `REJECT`; both preserve the bypass |
| Hidden package entries | replace the verifier with a second filesystem stack | `REJECT`; unnecessary dependency and broader behavior change |
| Hidden package entries | retain the existing enumerator with `-Force` | `ADOPT`; smallest change, same exact closed-world comparison |
| Relative paths | require PowerShell 7 / newer .NET | `REJECT`; silently drops the recorded fallback |
| Relative paths | URI-based relative projection | `REJECT`; adds encoding and separator behavior irrelevant to this closed local root |
| Relative paths | validate the full path begins with the normalized root prefix, then substring that prefix | `ADOPT`; PowerShell 5.1 compatible, root-bounded and separator-normalized |
| Pause label | widen/reflow the left header or shrink UI typography | `REJECT`; changes the reviewed 50:50 surface or global readability |
| Pause label | maintain a new key-alias table | `REJECT_FOR_NOW`; duplicates platform key naming and can drift |
| Pause label | keep the authored width, horizontally clip with ellipsis, preserve the complete mapping in tooltip | `ADOPT`; Godot-native, local to one button, keeps keyboard/pad distinction and existing tooltip contract |

Preimplementation feasibility was `FEASIBLE`: all affected consumers and rollback boundaries were local and already covered by fixture tests. No save migration, asset, dependency, production gameplay, cost or protected-path change was required. Legacy/context classification was unchanged: Task 4/5 reports remain active evidence for this continuation; older package attempts remain preserved provenance; unknown generated metadata remains `UNKNOWN_UNVERIFIED` and untouched.

## Implemented correction

- `build_r2_local_trial.ps1`
  - enumerates package files with `Get-ChildItem ... -Force`;
  - replaces `[IO.Path]::GetRelativePath` with `Get-RootBoundedRelativePath`, which normalizes both paths, proves the file is below the package root with `OrdinalIgnoreCase`, and only then projects the suffix with `/` separators;
  - retains the exact 18-artifact set, manifest/disk exact-case comparison, duplicate/case collision rejection, safe manifest projection and SHA-256 checks.
- `test_r2_windows_package.py`
  - runs intact verification explicitly through both `pwsh` and Windows PowerShell;
  - creates real Windows Hidden attributes with `attrib +H` and rejects both a Hidden file and a normal file inside a Hidden directory;
  - keeps existing missing/tampered/extra/collision/project-preservation/diagnostic tests.
- `r2_screen.gd`
  - sets only the existing Pause button to `clip_text=true` and `OVERRUN_TRIM_ELLIPSIS`;
  - does not change its authored x position/width, board, pane, font scale, label source, mapping, action or tooltip.
- `test_r2_screen.gd`
  - applies both `ScrollLock` and `CapsLock` at 125%; verifies the actual button remains width 130, its global rect stays in the left pane and before the right pane, the full current key remains in the tooltip, bounded ellipsis is active when needed, and visible keyboard identity remains.

## Verification evidence

Commands used (working directory repository root):

```powershell
python -m unittest tests.tooling.test_r2_windows_package -v

Godot_v4.7.1-stable_win64.exe --headless --path <repo> -s addons/gut/gut_cmdln.gd `
  -gtest=res://tests/replanned_r2/test_r2_screen.gd -gexit

pwsh.exe -NoProfile -ExecutionPolicy Bypass -File tools/windows/build_r2_local_trial.ps1 `
  -OutputDirectory 'C:\Users\user\Documents\Tetris R2 Local Trial\Builds\final-07a7007-20260912' -VerifyPackageOnly

powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/windows/build_r2_local_trial.ps1 `
  -OutputDirectory 'C:\Users\user\Documents\Tetris R2 Local Trial\Builds\final-07a7007-20260912' -VerifyPackageOnly

python -m unittest discover -s tests/tooling -p 'test_*.py' -v

Godot_v4.7.1-stable_win64.exe --headless --path <repo> -s addons/gut/gut_cmdln.gd `
  -gdir=res://tests -ginclude_subdirs -gexit
```

Final results on the corrected bytes:

- focused package: exit `0`, `9/9`;
- focused screen: exit `0`, `32/32`, 382 assertions;
- existing actual package `final-07a7007-20260912`: strict verification exit `0` under PowerShell `7.6.5` and Windows PowerShell `5.1.26100.9278`;
- full tooling: exit `0`, `88/88`;
- full recursive GUT: exit `0`, 58 scripts, `344/344`, 3,656 assertions, stderr empty;
- HiGodot `script_patch`: one replacement, diagnostics `[]`; subsequent HiGodot script readback contained both Pause properties;
- `git diff --check` on owned source/tests: exit `0`;
- preserved `project.godot` SHA-256: `46ce5e3295b0807f57fd16e07573ca7f0aa470c8e55696a8f8ca360d74caf020`.

Pre-commit source hashes:

| Path | SHA-256 |
|---|---|
| `tools/windows/build_r2_local_trial.ps1` | `61d7115082dbf627760c66e931824b358315b1f1119d387f56588215726d7caa` |
| `tests/tooling/test_r2_windows_package.py` | `d187fc1db52cef00dab9a1489ea4aa54f9a43fe181ed5ab348a39e71dcd576e4` |
| `src/replanned_r2/r2_screen.gd` | `70dc1df37aeed3b06932acca6c7e28877b4189a079eecef3f46d11cb62c45f66` |
| `tests/replanned_r2/test_r2_screen.gd` | `3117019eaa29f97e48eb7e0b9c7805aab68f6d989ebbf63fd66346e77c6dd5f8` |

## Two full owned-delta review loops

1. Re-read the complete four-file diff and attacked path containment, exact-case equality, Hidden-directory traversal, Windows PowerShell parsing, tooltip completeness, device distinction and authored pane geometry. No new valid finding; actual package verification was repeated in both PowerShell engines.
2. Re-read current source after the full suites and checked for scope leakage, duplicated key presentation, save/options mutation, global font/layout changes, package-set weakening and unowned files. No new valid finding; `git diff --check`, source hashes and `project.godot` hash were read back. `CLEAN_REVIEW_EXIT` applies only to this owned correction delta.

## Parent runtime-only visual QA setup

The parent can launch the normal R2 scene, then replace the just-launched root with this runtime-only instance. The fixture paths are assigned before `_ready()`. The long Pause mapping and 125% font are applied only to the in-memory `options` dictionary; `save_options` and Settings Save are never called, so no ordinary or fixture options file is written. Practice 4 creates no checkpoint.

```gdscript
var old = get_tree().current_scene
var qa = load("res://scenes/replanned_r2/main.tscn").instantiate()
qa.save_path = "user://replanned_r2_final_fix_parent_qa/save.json"
qa.options_path = "user://replanned_r2_final_fix_parent_qa/options.json"
get_tree().root.add_child(qa)
get_tree().current_scene = qa
old.queue_free()
await get_tree().process_frame
qa.options = qa.Disk.default_options()
qa.options.font_scale = 125
var remap = qa.Disk.remap(qa.options,"keyboard_mapping","pause",KEY_SCROLLLOCK)
qa.inputs.configure(qa.options)
qa._apply_font()
qa._refresh_control_guidance()
qa.begin_practice(4)
qa.close_details()
await get_tree().process_frame
var pause = qa.get_node("Battle/Puzzle/Pause") as Button
return {
    "remap": remap,
    "save_path": qa.save_path,
    "options_path": qa.options_path,
    "font_scale": qa.options.font_scale,
    "pause_text": pause.text,
    "pause_tooltip": pause.tooltip_text,
    "pause_rect": pause.get_global_rect(),
    "puzzle_right": qa.get_node("Battle/Puzzle").get_global_rect().end.x,
    "combat_left": qa.get_node("Battle/Combat").get_global_rect().position.x,
    "clip_text": pause.clip_text,
    "overrun": pause.text_overrun_behavior
}
```

Expected machine readback is `remap.success=true`, `font_scale=125`, Pause width 130 with right edge before x632/x648, `clip_text=true`, ellipsis overrun, visible `키` device context and a tooltip containing the full `ScrollLock` plus gamepad alternative. Hover the Pause button to inspect the full tooltip. To sample the other reproduced long name without touching OS key state, rerun the in-memory `Disk.remap` call with `KEY_CAPSLOCK`, then `inputs.configure`, `_refresh_control_guidance`, and one process frame.

After the visual check, stop the game. Do not save Settings and do not promote the fixture to ordinary player data.

## Rollback and evidence limits

Rollback is a normal revert of the owned correction commit; no migration or asset restoration is needed. Existing packages were read only and were not rebuilt, moved or deleted.

This report proves deterministic fixture rejection, both supported PowerShell verification paths, Godot automated layout bounds and the full regression suites. It does not claim a rebuilt package, fresh native visual confirmation of ellipsis/tooltip, physical-controller behavior, Human/player UX, accessibility certification, art/balance approval, public distribution or release readiness. Parent owns native QA, rebuild, scoped re-review, metadata and integration.

Reuse-learning close: the existing mapping-derived label and tooltip pattern was retained; the correction adds no new reusable Base module. `NO_NEW_REUSE_LEARNING`.
