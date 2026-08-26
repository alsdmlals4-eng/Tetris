# Tetris Image Work Handoff — 2026-08-25

Status: `IMAGE_WORK_ONLY / HANDOFF_READY`

## Session boundary

Until this image pass is finished, do not continue production code, CI, Godot runtime, or balance implementation. Image generation is the active task.

Operating rule:

- generate **3 images per batch**;
- each requested image must be an **independent artifact**, not a combined concept sheet;
- inspect each generated artifact against its one stated purpose before accepting it;
- rejected artifacts are not canonical references for later generation.

## Current visual authority

`TETRIS-VISUAL-028 · Hand-Drawn Mystic Fantasy + Clean Puzzle UI · USER_APPROVED`

The approved direction is hand-drawn fantasy concept art with restrained mysticism, ink/wash texture, and cleaner high-readability puzzle/UI surfaces.

Runtime-layout intent carried by the approved concept:

- puzzle area is larger than in the concept mockup;
- techniques are not 18 always-visible cells;
- player selects `Attack / Defense / Support`, then sees the selected lane's `T1–T6` list;
- selecting a technique opens detail first;
- detail shows effect, cost, condition, and target;
- a separate Use action commits the technique.

`TETRIS-VISUAL-020 · Tactical Anime Pixel Rift Fantasy` remains historical provenance. New image generation follows VISUAL-028.

The durable human-facing style anchor is the latest hand-drawn fantasy UI image attached at the top of the Notion `Tetris · Home` page.

## Existing references

Retain as reference inputs, not automatic final runtime assets:

- `IMG-P0-001 · Battle Screen Composition Mockup` — composition reference; its enemy ETA countdown numbers are obsolete visual residue.
- `IMG-P0-002 · Frontier Shield Vanguard Master` — character structure reference.
- `IMG-P0-003 · Asymmetric Breach Colossus Master` — boss structure reference.
- latest hand-drawn fantasy UI concept — current style anchor.

## Rejected latest batch

The first attempt after adopting the 3-image batch rule is rejected as a production image batch because all outputs drifted into combined UI concept sheets.

1. Battle UI request incorrectly mixed Battle UI + background + skill detail.
2. Frontier Gate background request incorrectly returned another UI composite rather than a pure background.
3. Vanguard pose-sheet request incorrectly returned another UI composite rather than a character-only pose sheet.

Treat these as `REJECTED_REFERENCE`; do not use them as canonical generation references.

## Next exact batch — three independent images

### 1. Battle Screen UI final concept

Must be a standalone battle-screen UI image.

- large puzzle focus;
- Current Telegraph + lower-priority Next Forecast;
- one Shared Player Turn Timer;
- HP / Energy / Stock;
- Attack / Defense / Support category tabs;
- selected lane exposes T1–T6 only;
- technique detail panel;
- separate Use confirmation;
- Combat Stage never occludes puzzle cells or critical HUD.

### 2. Fracture Frontier Gate background

Must be a pure environment image with **no UI, text, puzzle board, character sheet, or HUD**.

- fortified frontier gate under Rift siege;
- foreground battle plane;
- midground gate / wall;
- distant Rift sky / silhouettes;
- deliberate negative space for future puzzle/HUD and character placement.

### 3. Vanguard combat pose sheet

Must be a character-only pose sheet with **no battle UI or puzzle screen**.

Same Vanguard identity across:

- Idle / Ready;
- Heavy Strike;
- Guard;
- Counter;
- Rally;
- Hit reaction;
- Victory;
- Defeat.

Shield, weapon, face, torso proportion, and costume must not drift between poses.

## Following image backlog

1. Gatebreaker six-Intent pose sheet.
2. Line puzzle visual set.
3. Chain puzzle visual set.
4. HUD / system icon set.
5. Vanguard 18-technique icon set.
6. Gatebreaker Telegraph icon set.
7. VFX motif sheet.
8. Title / Pause / Settings / Victory / Defeat / Result-Retry support screens.
9. Final 1280×720 integrated battle key frame.

## Image QA gate

For every batch:

1. `requested_artifact_count == delivered_independent_artifact_count`.
2. Check purpose isolation before style quality.
3. Check style anchor consistency.
4. Check puzzle/HUD readability.
5. Separate `APPROVED_DIRECTION`, `REFERENCE_ONLY`, and `REJECTED_REFERENCE`.
6. Do not promote generated text or numeric values inside concept art to gameplay canon.
7. Generated art is not runtime proof; layer separation, crop, cleanup, and import remain separate work.

## Problems and lessons

### Notion upload false-unavailable judgment

Problem: an upload path was previously declared unavailable despite a successful prior Notion upload in the same project.

Lesson: if an equivalent action succeeded before, perform connector action rediscovery and an actual invocation attempt before declaring the capability unavailable. Verify the resulting page with readback.

### Multi-artifact cardinality failure

Problem: three independent image requests were satisfied as combined concept sheets.

Lesson: artifact count is a contract. N independent image requests require N independent image artifacts. Validate cardinality and purpose isolation after generation.

### Stale handoff risk

Problem: conversation handoff state can lag live GitHub/Notion state.

Lesson: on resume, fetch live project authority before acting.

### Visual canon drift

Problem: Notion Home had the approved hand-drawn style while the Visual Bible still named the earlier pixel direction as current.

Lesson: when a user locks a new visual direction, synchronize Home, Visual Bible, image production package, and handoff in the same session.

## New-chat resume sequence

1. Fetch live GitHub branch/PR state.
2. Fetch Notion `Tetris · Home`, `02 · 비주얼 바이블`, `14 · P0 이미지 제작 패키지`, and `17 · 이미지 작업 인수인계 · 2026-08-25`.
3. Confirm the Home style-anchor image exists.
4. Exclude the rejected combined sheets.
5. Generate the three exact independent artifacts listed above.
6. Upload only user-approved outputs back to Notion and verify them by readback.
