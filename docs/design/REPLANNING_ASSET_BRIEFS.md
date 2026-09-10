# R1 image production briefs

State: BRIEF_READY / candidate production authorized2026-09-11; final approval pending. This is a production brief, not an asset approval or existing scene-binding claim. Actual output geometry, hashes and regions belong to the candidate manifest. Existing runtime files are protected. New source paths live under docs/assets/reference/planned/replanning/blueprint/ until approval.

## Shared direction and alternatives

Clean cel-shaded anime illustration is recommended over painterly microtexture (weak at HUD size) and flat pictograms alone (insufficient character presence). Slim adult defender face, blue-green mantle, steel collar. Boss is a monumental original black basalt rift sentinel with violet core and massive asymmetric shoulder/hammer silhouette. Avoid copying reference characters. Dark navy interface, restrained aged gold edges, cyan focus, violet charge; effects subordinate to puzzle glyph and deadline readability. No baked text or UI values in artwork.

## Actual consumer audit and planned candidate mapping

| Asset ID | Source candidate / future target | Consumer | Geometry / display / import | Required states |
| --- | --- | --- | --- | --- |
| R1-PORTRAIT | portrait-states.png / res://assets/replanned/portrait-states.png | Existing battle.tscn::MainRow/CombatColumn/ResourceFrame/ResourceRow/VanguardPortrait; future AtlasTexture selection | 2x2 equal cells, square head portraits; opaque dark-navy background intentional for rectangular HUD; 96px face minimum at1280x720. Linear, lossless, no mipmaps, filter_clip | Neutral, hurt, resolved/victory, defeated; state swaps, not four-frame animation |
| R1-BOSS | boss-states.png / res://assets/replanned/boss-states.png | Existing battle.tscn::MainRow/CombatColumn/CombatStage/GatebreakerReference; planned region-state presenter | 2x3 landscape cells in square sheet on coherent opaque stage background; contain within right-side boss stage; no alpha needed for rectangular complete stage. Linear, no mipmaps, filter_clip | Idle, anticipation, contact, recovery, hurt, defeated; six discrete state cuts, not smooth animation |
| R1-TILES | tiles.png / res://assets/replanned/tiles.png | Existing ProductionLineBoardView and ProductionChainBoardView; planned draw_texture_rect_region replacement, not currently bound | 4x2 equal square cells. Seven LINE identities; six shared CHAIN glyphs plus empty/inactive tile. Opaque tiles intentionally cover cell; linear, no mipmaps, filter_clip. Inset region after output inspection | Normal art plus focus/selected/invalid/clearing as non-color semantic overlays and event-driven scale/opacity, not separately redrawn identities |
| R1-ICONS | icons.png / res://assets/replanned/icons.png | Existing production_battle.gd skill UI/preview; planned stable-purpose binding | 3x2 equal square cells; top Strike/Ward/Recover; bottom MP/charge/boss heavy. Opaque navy-backed icon slots; 48/64/96px display tests. Linear, no mipmaps | Normal art; selected outline+label, disabled veil+reason, amplified two-diamond badge. No icon identity substitution |
| R1-ENV | frontier.png / res://assets/replanned/frontier.png | Existing battle.tscn::MainRow/CombatColumn/CombatStage/StageBackdrop and planned scenes/replanned/main.tscn::Background | Landscape16:9; cover crop, no words/characters; quiet left-middle for menu. Linear | Static environment, dim overlay for menu; no unneeded weather variants |

## Motion and production decision

Use image model for all new creative pixels. Use installed candidate-only Aseprite for editable source, frame/layer inspection and export packaging, not as a substitute image model or pixel-style mandate. State atlases can be consumed with explicit AtlasTexture regions; a state sheet is not a completed smooth animation. Boss animation readiness requires state geometry review and transition/hold specs. Damage is owned by combat events, never image/frame arrival. On pause freeze simulation-linked playback. Missing or skipped animation cannot alter outcomes. Pure UI focus remains responsive.

Avoid oversized full-body player work: its verified consumer is a face slot. All candidate artwork will also be reproduced in the human PDF beside purpose, state and intended screen-size explanation. The PDF screen atlas is an editable layout projection using these assets and structured labels, explicitly not a runtime screenshot.

## Production and review gate

Generate bounded batches; inspect actual image and geometry before regions are recorded. Reject mixed cells, missing states, unreadable glyphs, clipped face or inconsistently scaled boss. Preserve raw source and provenance. Do not postprocess creative pixels through drawing scripts. Actual alpha is measured where required; opaque rectangular artwork is intentional and never called transparent. Final user approval precedes canonical promotion; Godot import/runtime/Human checks follow implementation.
