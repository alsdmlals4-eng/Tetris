# TETRIS-IMG-032 · Gatebreaker Stage Cutout

- Status: `LOCAL_RUNTIME_RENDER_VERIFIED / USER_APPROVED_REFERENCE_REUSE`
- Purpose: give the realtime threat area a recognizable Gatebreaker silhouette while preserving combat, puzzle, and input behavior.
- Source asset ID: `IMG-P0-003`.
- Source path: `res://docs/assets/reference/approved/TETRIS-IMG-P0-003-asymmetric-breach-colossus-master.png`.
- Source status: user-approved project-local and Notion Asset Library reference; no new image was generated for this consumer.
- Consumer scene: `res://scenes/production/battle.tscn`.
- Consumer node: `MainRow/CombatColumn/CombatStage/BossReference`.
- Consumer type: `AtlasTexture` assigned to a decorative `TextureRect`.
- Atlas region: `Rect2(0, 105, 820, 500)` from the 1448×1086 approved master sheet. The crop excludes the title band, explanatory microtext, and intent-pose row, retaining the central Gatebreaker silhouette and Rift Core.
- Geometry: full compact CombatStage, `KEEP_ASPECT_CENTERED`; background stage remains visible at side margins. `BossTopMask` covers only the 7.5% top safe margin so explanatory master-sheet microtext cannot enter the combat presentation.
- Input: `MOUSE_FILTER_IGNORE`; it cannot intercept puzzle, skill, or scene controls.
- Import/use: default Godot texture import; no new copied binary and no replacement of the approved original.

## Evidence ceiling

The scene reference proves runtime wiring. A local Godot runtime screenshot of the exact implementation head is required before calling it rendered. Human readability, appeal, and play validation remain `NOT_RUN`.
