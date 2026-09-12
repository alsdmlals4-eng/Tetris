# Task 5 report — remap-aware controls and truthful Practice pause guidance

- status: `DONE_WITH_PARENT_NATIVE_QA_PENDING`
- implementation base: `9ec92bae2035184f21452524343ac8f6ad821c6e`
- implementation commits: `d38a344` (`fix: keep R2 guidance aligned with remaps`), `aacdf8a` (`fix: keep R2 practice guidance clear at 125 percent`)
- branch: `codex/r2-package-verification`
- source comparison: latest completed `origin/main` `1e272c2668e8de102552608eb0ccd5d4718e40ca`; Base `9.4.4` remains pinned
- owned implementation: `src/replanned_r2/r2_input.gd`, `src/replanned_r2/r2_screen.gd`, `tests/replanned_r2/test_r2_screen.gd`
- package builder, production `main`, gameplay/model rules, disk/save schema, assets, addons and project settings were not changed

## Work-before problem and ruling

The isolated R2 input owner already read saved keyboard and gamepad mappings, but six visible teaching surfaces separately named default keys: LINE footer, CHAIN footer, Pause button and Practice stages 1, 3 and 4. After a legitimate settings remap, the controls worked with the new mapping while the UI continued to say `Space`, `Tab`, `Esc` and `2`. Practice pause also reused the normal-combat checkpoint message even though Practice intentionally never writes its session and preserves any pre-existing ordinary checkpoint.

The brief's three alternatives were evaluated against the current input, settings, pause and save consumers:

| Alternative | Ruling | Project fit |
| --- | --- | --- |
| Remove control hints | `REJECT` | Avoids mismatch by removing discoverability and weakens teaching. |
| Prohibit remapping | `REJECT` | Regresses the existing settings/accessibility surface and expands scope into input redesign. |
| Derive labels from the saved mapping owner | `ADOPT` | One read-only presentation path, no gameplay/save migration, lowest drift risk. |

The current implementation, approved Task 5 brief, Xbox XAG107 remap-guidance requirement and Godot's read-only `OS.get_keycode_string` presentation API support deriving labels from the mapping that actually drives input. This is an `ADOPT` of existing-mapping-derived labels, not an accessibility certification or broader input redesign. XAG103 and Riot's gameplay-clarity material support retaining clear cues; neither is evidence of Human/player approval. Reduced motion, shape icons and threat previews were retained unchanged.

## Implemented structure

`r2_input.gd` now owns the small read-only label projection beside the mapping it already consumes:

- `binding_names` and `binding_label` read either the applied options or a supplied settings draft. Keyboard names use `OS.get_keycode_string`; the pre-existing gamepad button-name table was moved from the Settings view into this single helper rather than duplicated.
- `binding_phrase` and `paired_binding_phrase` add truthful device context. Gamepad presentation resolves existing semantic aliases only: LINE hard drop uses mapped `accept`, HOLD uses `cancel`, and DEF uses `category_next`. No input action or mapping value is changed.
- `presentation_group` follows the last recognized pressed keyboard/gamepad mapping, solely to choose the concise visible hint. Reading labels never mutates options, input mappings, held commands or gameplay state.

`r2_screen.gd` consumes that projection:

- LINE, CHAIN and Pause show a concise binding for the active input group; their tooltips retain complete keyboard and gamepad alternatives.
- Practice 1/3/4 instruction text names the current hard-drop, board-switch, DEF and pause bindings with explicit keyboard/gamepad pairing. The Practice instruction tooltip carries the full alternatives.
- Saving Settings reconfigures the existing input helper and refreshes every guide. Cancel reconfigures from the unchanged applied options, so draft bindings cannot leak into guidance. Scene re-entry loads the same saved mapping through the existing disk owner.
- Normal stable/unstable combat checkpoint text is byte-for-byte unchanged. Practice pause now explicitly says that Practice is not saved and either (a) the existing ordinary checkpoint remains, or (b) no new ordinary checkpoint is created. `_exit_battle`, `checkpoint()` and disk behavior were not edited.

No board rectangle, font scale, shape, art, combat clock, command boundary, pause boundary, input repeat rule, save path or serialized field changed.

## TDD evidence

The reliable runner used the dedicated Godot 4.7.1 executable with a hidden waited process and separate stdout/stderr logs. Focused arguments were:

```powershell
Start-Process -WindowStyle Hidden -Wait -PassThru `
  -FilePath C:/Users/user/Tools/Godot-Tetris-4.7.1/Godot_v4.7.1-stable_win64.exe `
  -ArgumentList @('--headless','--path','C:/Users/user/Documents/GitHub/Ninza/Tetris','-s','addons/gut/gut_cmdln.gd','-gtest=res://tests/replanned_r2/test_r2_screen.gd','-gexit') `
  -RedirectStandardOutput <unique-task-log> -RedirectStandardError <unique-task-error-log>
```

Full regression replaced `-gtest=...` with `-gdir=res://tests -ginclude_subdirs`.

1. A first naive GUI-subsystem invocation returned immediately with empty output and no trustworthy exit/discovery; it is `NOT_EVIDENCE`. The waited-process runner was adopted before counting RED/GREEN.
2. The first test draft used an unsupported assertion helper and produced a parse diagnostic. It was corrected before the valid RED and is also `NOT_EVIDENCE`.
3. Valid RED, focused screen suite before implementation: **28/30 tests**, **316/334 assertions**, exit `1`, time `19.141s`. The new remap test found the stale `Space`/`Tab`/`Esc` guidance, and the new Practice test found the normal-combat save message on Practice pause.
4. First implementation run reached 29/30; one test expected the Korean device prefix and binding to be adjacent even though the correct concise phrase includes the action label. The assertion was corrected to inspect the device prefix, actual binding and action separately; no product text was weakened for the test.
5. GREEN after implementation: **30/30 tests**, **341 assertions**, exit `0`, time `18.768s`.
6. Focused regression after consolidating the duplicate gamepad-name presentation table: **30/30 tests**, **341 assertions**, exit `0`, time `18.403s`.
7. One malformed PowerShell command was rejected by the shell before starting Godot; it is `NOT_EVIDENCE` and was not counted as a test run.
8. One final complete GUT regression on the final implementation bytes: **342/342 tests**, **3,615 assertions**, **58 scripts**, exit `0`, time `25.322s`. The only diagnostic line was the suite's expected `[R2 safety] ... MAX_WAVES_REACHED` contract fixture; stderr was empty.

The new tests prove:

- valid unused-key remaps for hard drop, switch, DEF and pause replace stale defaults across footer/button/Practice text;
- keyboard and gamepad alternatives are both available without falsely presenting one device as the other;
- settings Save applies guidance, settings Cancel preserves applied guidance, and scene re-entry reads the saved mapping;
- label refresh and input-device presentation do not mutate the captured gameplay snapshot;
- Practice exit leaves the ordinary checkpoint file's exact SHA-256 unchanged and retains the same ordinary `run_id`;
- the unchanged normal stable checkpoint copy still appears outside Practice.

All test paths are under `user://replanned_r2_tests/...`; no ordinary user options/save file was written by this worker.

## Final source/readback and scoped self-review

The final three persistent `.gd` files were read back through the dedicated HiGodot session `tetris@89f7`, endpoint 8008, editor PID43848. HiGodot content hashes matched filesystem bytes exactly:

| File | Lines | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| `src/replanned_r2/r2_input.gd` | 130 | 5,627 | `80c75502f58d480216729b280aeccbba0ee2f0e632f8966e42791e6d87c8d317` |
| `src/replanned_r2/r2_screen.gd` | 1,066 | 53,638 | `b9fd094bba437d1cf9e1904fc73aeeb01357e1e374b68bc8f5f8911184d0ad6b` |
| `tests/replanned_r2/test_r2_screen.gd` | 751 | 37,360 | `d95632016064a0cb37fc9e047e70a2ae60c6c16f73b45a4d0ea2729bdb65b272` |

Final script patch diagnostics were `[]`. HiGodot state readback was exact project `Tetris`, scene `res://scenes/replanned_r2/main.tscn`, Godot `4.7.1-stable`, readiness `ready`, game `stopped`; the editor was then released to the parent for native QA.

Scoped adversarial review loop 1 re-read the complete owned diff and every hard-coded default-key occurrence. Result: stale defaults remain only in negative regression assertions; production guidance consumes the helper. There is one gamepad presentation-name table, located with the mapping consumer.

Scoped adversarial review loop 2 traced Settings Save/Cancel, last-device selection, normal/Practice pause and exit paths. Result: labels are read-only; Settings draft stays isolated until successful save; normal checkpoint text and behavior are unchanged; Practice performs a checkpoint existence read only and never writes its session. `git diff --check` was clean before commit. No new blocking machine finding remained.

The user-owned `project.godot` remained unstaged with its exact preserved SHA-256 `46ce5e3295b0807f57fd16e07573ca7f0aa470c8e55696a8f8ca360d74caf020`. All provenance-unknown `.import`/`.uid` files remained present and unstaged. No deletion or other-project action occurred.

## Parent native QA fixture API

The parent can run the normal R2 scene while ensuring all subsequent option/checkpoint writes use a temporary fixture. Do not add a persistent QA scene. First launch:

```json
{"name":"project_run","arguments":{"mode":"custom","scene":"res://scenes/replanned_r2/main.tscn","autosave":false,"session_id":"tetris@89f7"}}
```

After game readiness, replace the just-launched root with a runtime-only instance whose exported paths are set before `_ready()`:

```json
{
  "name": "editor_manage",
  "arguments": {
    "op": "game_eval",
    "session_id": "tetris@89f7",
    "params": {
      "code": "var old=get_tree().current_scene\nvar qa=load(\"res://scenes/replanned_r2/main.tscn\").instantiate()\nqa.save_path=\"user://replanned_r2_task5_parent_qa/save.json\"\nqa.options_path=\"user://replanned_r2_task5_parent_qa/options.json\"\nget_tree().root.add_child(qa)\nget_tree().current_scene=qa\nold.queue_free()\nawait get_tree().process_frame\nreturn {\"scene\":qa.scene_file_path,\"save_path\":qa.save_path,\"options_path\":qa.options_path,\"page\":qa.page}"
    }
  }
}
```

This runtime setup reads the original root during its brief startup but cannot write the ordinary files by itself; all subsequent normal Settings Save/checkpoint operations on `qa` target only `user://replanned_r2_task5_parent_qa/...`. The parent should read back the returned paths before interacting, then perform the required normal UI flow: Settings remap → Save → Practice guidance/input/pause → main, plus 1280x720 and 125% typography inspection. No cleanup deletion is authorized by this report.

## Native finding correction — 125% Practice guidance separation

Parent native QA of `d38a344` reproduced one Important presentation regression at 1280x720 and 125%: Practice 3's retained clock-safety sentence painted through the Start button. The parent preserved the source screenshot as `docs/validation/r2-package-20260912/practice3-overlap-d38a344.jpg`; its evidence/document ownership remains outside this worker's commit.

Systematic trace found the cause in the shared Details modal geometry. The Body is a word-wrapped `Label`; at 125% its Practice 3 minimum content height was 427px, but the fixed region began at local y98 and the Start button began at y452. Label drawing was not clipped or scrolled, so content required through y525 before separation and painted into the button. A long `ScrollLock` Practice 1 binding also required through y439 and missed the intended 16px gap by 3px. Practice 2/4 and the 29px selected font size were otherwise correct.

Alternatives were compared against the actual bounded text:

- scroll the modal body: valid for unbounded content, but adds interaction and hidden safety text when all four current stages can fit;
- compact/delete the final safety sentence: rejected because it removes timing guidance the brief requires;
- enlarge the centered modal and body while preserving font and complete copy: adopted as the smallest reversible fix.

The Details modal now uses y45/height630, Body height430 and Start y550. It remains inside the 720px canvas with 45px outer margins, keeps the exact 125% body font at 29px, preserves every sentence and provides at least 16px between actual wrapped content and Start. It does not change the 50:50 battle halves, boards, gameplay, font-scale option, save/options data, or input behavior.

Correction TDD and regression evidence:

1. Final RED exercised all Practice stages at 125%, with `ScrollLock`/`CapsLock` long names plus the native R/F mapping pattern: **30/31 tests**, **365/367 assertions**, exit `1`, time `18.800s`. Practice 1 reported required y455 > Start y452; Practice 3 reported required y541 > Start y452. All safety-copy and exact 29px assertions passed.
2. Focused GREEN after the three geometry changes: **31/31 tests**, **367 assertions**, exit `0`, time `18.776s`; stderr empty.
3. Final full recursive GUT on correction bytes: **343/343 tests**, **3,641 assertions**, **58 scripts**, exit `0`, time `24.716s`; stderr empty. An immediately preceding identical full run also printed a complete 343/343 summary but its outer command exceeded the 30-second capture window before returning the process exit; it is not used as exit-code evidence.
4. Final HiGodot readback of screen/test matched filesystem SHA-256 exactly as updated in the table above; diagnostics were `[]`. Editor state remained exact Tetris, `main.tscn` open, readiness ready, game stopped.

Parent native recheck of the corrected bytes and the rebuilt package remains separate; automated minimum-size assertions do not replace that visual acceptance.

## Remaining evidence and handoff

- Native normal-UI remap/save/Practice readback, 1280x720 and 125% visual legibility, physical-controller behavior, Human/player/accessibility approval and release readiness are `NOT_RUN` by this worker. The parent owns that acceptance and must not treat GUT layout coverage as native/Human proof.
- The Task 4 package still contains its earlier source. Rebuild and package verification against final Task 5 source are parent-owned and pending. No package-builder byte was edited here.
- The visible Pause button still occupies its existing 130x36 rectangle; automated tests and source review found no geometry change, but translated/native 125% clipping requires the parent's visual check.
- Rollback is revert of implementation commits `d38a344` and `aacdf8a` plus this report commit. It changes no schema or player data and needs no migration.
- Reuse learning: keep display labels beside the existing mapping consumer and pass Settings drafts into that read-only formatter. This is a project-only application; `NO_NEW_REUSE_LEARNING` for Base, so no Base registry or memory update was made.
- `REMAINING_WORK_COMPLETION_GATE`: implementation and machine regression complete; parent native QA and package rebuild remain. `IMPLEMENTATION_CORRECTION_RESCAN`: no machine blocker. `POST_COMPLETION_ADVERSARIAL_REVIEW_REQUIRED`: two scoped loops complete with zero new valid blocking findings. Machine scope exits clean; overall Task 5 remains bounded by parent-owned native/package evidence.
