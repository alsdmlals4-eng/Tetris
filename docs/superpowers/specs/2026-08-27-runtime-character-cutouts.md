# Runtime Character Cutouts Specification

## Goal

Create two transparent-alpha, runtime-ready source assets derived from the approved P0 Vanguard and Gatebreaker master sheets. The originals remain immutable approved references.

## Intent

The production 60/40 battle scene needs readable player and boss silhouettes that keep the approved dark hand-drawn mystic-fantasy direction while leaving puzzle and HUD information dominant.

## Source and output contract

| Derived ID | Approved source | Exact local target | Planned consumer | Geometry / import |
| --- | --- | --- | --- | --- |
| `TETRIS-IMG-033` | `IMG-P0-002` / Frontier Shield Vanguard Master | `assets/production/characters/vanguard_combat_cutout_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/CombatStage/VanguardReference` | Transparent PNG, vertical full-body crop, 1536 px maximum source dimension, lossless UI/cutout import, full-height aspect-centered stage slot |
| `TETRIS-IMG-034` | `IMG-P0-003` / Asymmetric Breach Colossus Master | `assets/production/bosses/gatebreaker_combat_cutout_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/CombatStage/GatebreakerReference` | Transparent PNG, rift-core and ram-arm safe area, 1536 px maximum source dimension, lossless UI/cutout import, full-height aspect-centered stage slot |

## Visual constraints

- Direct derivative only: retain the approved subject, silhouette, equipment, palette, and hand-drawn rendering.
- Vanguard: full body with sword and shield; no UI labels, sheet panels, portrait, alternate poses, or background.
- Gatebreaker: full body with asymmetric ram-arm and visible violet Rift Core; no labels, sheet panels, alternate poses, or background.
- No text, logos, watermarks, new costume design, new weapons, or style change.
- Runtime wiring is deliberately excluded from this asset-preparation slice. These assets are `SOURCE_ASSET_CANDIDATE` until a later latest-main scene binding and exact-head render evidence exist.

## Acceptance and verification boundary

- Both PNGs must exist at their exact local target path with a non-empty alpha channel.
- The approved source hashes must be recorded with each derivative; P0 masters must remain byte-identical.
- The asset manifest and consumer contract must state the planned consumer and `RUNTIME_INTEGRATION: NOT_IMPLEMENTED`.
- The targeted asset contract test verifies paths, alpha, dimensions, source identity, and integration status.
- Notion records the same relationship. Notion metadata does not imply binary upload or runtime integration.

## Rollback

Delete only the two versioned derived files and their associated manifest/contract entries. Do not remove or modify `IMG-P0-002` or `IMG-P0-003`.
