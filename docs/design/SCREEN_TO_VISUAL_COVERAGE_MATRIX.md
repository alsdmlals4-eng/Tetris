# Screen to Visual Coverage Matrix

- Status: CURRENT / Issue #45
- Canonical coverage status owner: Base `GAME_VISUAL_ASSET_COVERAGE_CHECKLIST.md`.
- Rule: `NO_AUTOMATIC_IMAGE_GENERATION_FROM_GAPS`.

| Screen | Layer / required role | Actual consumer or requirement | Production mode | State family | Status |
| --- | --- | --- | --- | --- | --- |
| TETRIS-SCREEN-002 Battle | SCREEN_DESIGN_REFERENCE — 60/40 confrontation hierarchy | Approved `TETRIS-IMG-P0-001` reference only | EXISTING_APPROVED / DO_NOT_GENERATE | combat running, tactical pause, terminal | COVERED_EXISTING as reference; not a runtime bitmap |
| TETRIS-SCREEN-002 Battle | RUNTIME_COMPONENT_ASSET — stage background | `MainRow/CombatColumn/CombatStage/StageBackdrop` | RASTER_IMAGE | normal stage | COVERED_EXISTING |
| TETRIS-SCREEN-002 Battle | RUNTIME_COMPONENT_ASSET — Vanguard / Gatebreaker silhouettes | `VanguardReference`, `GatebreakerReference` direct CombatStage children | RASTER_IMAGE | full-height aspect-centered slots | COVERED_EXISTING; art state variants not required by current consumer |
| TETRIS-SCREEN-002 Battle | Puzzle, threat, resources, controls, labels | Battle `Control`, Theme, Label, Button, custom board views | GODOT_UI / TEXT_LAYER / NO_NEW_IMAGE_FILE_REQUIRED | normal, selected, disabled, tactical pause | COVERED_EXISTING; Human readability NOT_RUN |
| TETRIS-SCREEN-002 Battle | ETA / forecast / current action meaning | runtime scheduler and text layers | GODOT_UI / TEXT_LAYER | normal, warning, resolved | COVERED_EXISTING for runtime; final feedback polish GAP_NONBLOCKING |
| TETRIS-SCREEN-003 Skill | pause hierarchy, lane/tier/USE selection | `SkillFrame`, `PauseState`, `SkillCategories`, `TierGrid`, `UseButton` | GODOT_UI / TEXT_LAYER / NO_NEW_IMAGE_FILE_REQUIRED | opened, selected, disabled, cancel, committed | COVERED_EXISTING; detail comprehension needs Human validation |
| TETRIS-SCREEN-004 Result | terminal cause, retry, reward recap | Battle terminal Result/Retry | GODOT_UI / TEXT_LAYER | victory, defeat, retry | GAP_NONBLOCKING — no reward recap/progression is in slice |
| TETRIS-SCREEN-005 Pause | manual pause/system settings | `pause_game` input and pause bridge; no settings scene | GODOT_UI / TEXT_LAYER | paused, resumed | GAP_NONBLOCKING — settings family not implemented |
| TETRIS-SCREEN-001 / 006–016 | non-slice menu, save, hub, story, growth, loading, error families | No actual consumer in current direct-entry slice | NO_NEW_IMAGE_FILE_REQUIRED / DO_NOT_GENERATE | See inventory | NOT_APPLICABLE or deferred by explicit current-slice boundary |

## Technical and queue boundary

- Current raster consumers keep their manifest-defined PNG format, alpha/crop/anchor and Godot import contracts. Buttons, text, gauges, selection, warnings, and key prompts remain engine-rendered so localization and dynamic state are not baked into images.
- No image brief is queued by this matrix. Future image work requires a named screen, actual planned/runtime consumer, required fidelity, format/crop/alpha contract, and a separate Image Conversation Approval Gate.
- Next Codex implementation candidates are separate: `TETRIS-SCREEN-004` reward recap, `TETRIS-SCREEN-005` settings surface, and `TETRIS-SCREEN-013` help/tutorial. None is approved by this coverage audit.
