# TETRIS-IMG-031 · Fracture Frontier Combat Stage

- Status: `RUNTIME_CONSUMER_READY / GENERATION_APPROVED_BY_USER`
- Purpose: the Combat Stage receives a restrained, readable environmental identity without competing with the puzzle surface or tactical controls.
- Asset path: `res://assets/production/backgrounds/fracture_frontier_combat_stage_v1.png`
- Consumer scene: `res://scenes/production/battle.tscn`
- Consumer node: `MainRow/CombatColumn/CombatStage/StageBackdrop`
- Consumer type: opaque `Texture2D` in a `TextureRect`; `KEEP_ASPECT_COVERED`; decorative mouse input ignored.
- Consumer geometry: compact wide stage strip; source may crop at top and bottom, so the safe content area is the center 70% of the image.
- Import/use: background texture; default filtering/compression is acceptable for this first runtime slice.
- Runtime state: the production PNG is wired directly; no placeholder texture remains in the scene.

## Visual brief

Keep the approved hand-drawn mystic-fantasy Tetris reference language: a dark charcoal/navy frontier, restrained fractured violet rift glow, faint ember-crimson horizon, and weathered stone silhouette. It must be an environment only: no character, boss, UI, text, logo, symbols, readable letters, frame, or foreground object. Reserve visual contrast for the game’s puzzle cells, Telegraph/ETA, resource text, and skill controls.

## Acceptance

1. The exact texture path is loaded by `StageBackdrop` in the production battle scene.
2. It remains non-interactive and never changes runtime rules or layout.
3. Runtime screenshot shows the asset without clipping or new Godot diagnostics.
4. The source image is stored at the project path and recorded in Notion before it is called runtime-integrated.
