# Tetris · Visual Bible

- Status: `CURRENT REPOSITORY VISUAL OWNER`
- Decisions: `TETRIS-VISUAL-028 · Hand-Drawn Mystic Fantasy + Clean Puzzle UI`; `TETRIS-IMAGE-030 · Runtime Consumer First Asset Production`
- Human-readable synthesis: [`PROJECT_MASTER_GDD.md`](PROJECT_MASTER_GDD.md)
- Asset records: `docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json`, `docs/assets/reference/planned/PROJECT_UNDERSTANDING_VISUAL_MANIFEST.json`, and `docs/assets/reference/planned/SCREEN_REFERENCE_MANIFEST.json`
- Evidence ceiling: a visual reference, generated exploration, imported source candidate, runtime-bound asset, runtime render and Human/player readability each prove different things. Never collapse their classes.

## 1. Visual promise

The game should feel like a tense Frontier Gate defense rendered in hand-drawn mystic fantasy, while the player can read the puzzle, live threat and tactical choice faster than the decoration.

```text
Puzzle / ETA / resource meaning
    outranks
character, stage and VFX spectacle
    outranks
ornament and texture
```

## 2. Global style anchor

| Layer | Current contract |
| --- | --- |
| Rendering language | Hand-drawn, ink/wash-adjacent mystic fantasy paired with clean puzzle/HUD information hierarchy. |
| Palette/value | Charcoal/navy base; restrained fractured violet rift; faint ember-crimson horizon; weathered stone. Bright value belongs first to puzzle cells, Current Telegraph/ETA and actionable resource changes. |
| Material/lighting | Weathered stone/plate and soft rift glow; light defines threat and focus, never a generic neon interface. |
| Shape/silhouette | Vanguard: broad triangular mass, offset shield, visible face/weapon and short mantle. Gatebreaker: asymmetric biped, ram-arm, support arm and exposed Rift Core. |
| Camera/framing | One large left puzzle surface, persistent right combat stage. Keep puzzle input, current threat and Skill context simultaneously readable; composition target is approximately 60/40. |
| UI/icon/VFX grammar | LINE/MP reads angular/structured; CHAIN/Combo reads linked/flow. ATK/DEF/SUP distinguish by shape/icon/text, not hue alone. VFX is layered local/meso feedback; never hide core play. |

## 3. Keep, Avoid and allowed variation

### Keep

- `TETRIS-VISUAL-028` hand-drawn mystic fantasy plus a deliberately clean puzzle UI.
- One active large puzzle surface; live Current Telegraph + ETA; persistent combat context.
- Puzzle/HUD clarity above background, character and VFX density.
- Readable Vanguard/Gatebreaker silhouette separation at gameplay scale.
- Text, icon, number and frame pattern redundancy for important status changes.

### Avoid / Do Not Drift

- Pixel/CRT/scanline treatment, generic sci-fi glass HUD, or noise/dither inside small text and puzzle cells.
- Two mandatory full boards, shared-turn/READY/timeout rails, a permanent 3×6 skill wall, or auto-commit imagery.
- Images that invent undisclosed buttons, economy states, lore, title, rules or status flows.
- Full-screen spectacle that obscures active puzzle, Current Telegraph, ETA, resource change or explicit USE.
- Cross-project character language, reference similarity, or unrecorded rights/provenance.

### Allowed variation

Region, threat state, time of day and faction/state may vary rift intensity, value balance, local material and VFX density only when the shared silhouette, UI grammar and information hierarchy remain intact.

## 4. Current asset and consumer evidence

| ID | Current class | Repository path / consumer | What it proves |
| --- | --- | --- | --- |
| `IMG-P0-001` | `APPROVED_REFERENCE` | `docs/assets/reference/approved/TETRIS-IMG-P0-001-battle-screen-composition-mockup.png` | Early composition reference only. |
| `IMG-P0-002` | `APPROVED_REFERENCE` | Vanguard master reference | Character identity source, not a runtime asset by itself. |
| `IMG-P0-003` | `APPROVED_REFERENCE` | Gatebreaker master reference | Boss identity source, not a runtime asset by itself. |
| `TETRIS-IMG-031` | Runtime-bound production asset | `CombatStage/StageBackdrop` | Scene consumer binding, subject to runtime/render evidence ceiling. |
| `TETRIS-IMG-033/034` | Runtime-bound source candidates | `VanguardReference` / `GatebreakerReference` | Scene consumer binding and derivative provenance. |
| `TETRIS-IMG-035/036` | Runtime-bound VFX candidates | Attack accent / active telegraph texture nodes | Bounded combat feedback binding. |
| `TETRIS-VIS-BOARD-001` | `GENERATED_EXPLORATION` | `docs/assets/reference/planned/tetris-project-core-scene-visual-board-v1.png` | AI project-understanding/planning review only; `runtime_consumer: NONE`. |

## 5. `PROJECT_CORE_SCENE_VISUAL_BOARD` exact legend

The board must be read with the structured text, not as a source of exact UI copy or gameplay rules.

| Panel | Required meaning | Status boundary |
| --- | --- | --- |
| 1 | Vanguard sees the immediate Gatebreaker/Frontier Gate threat and reaches Deploy context. | Minimal immediate relationship is current; wider lore is undecided. |
| 2 | A falling tetromino and line clear demonstrate LINE → MP. | 0/10/22/36/52 and 60 cap are approved rules; cap display is not implemented. |
| 3 | One orthogonal swap makes exactly one horizontal same-symbol line of three and resolves. | Board illustrates current CHAIN-038 intent; diagonals, 1-MP lock, caps/reset and formula are not runtime-complete. |
| 4 | Skill visibly pauses; the player compares a defensive response then explicitly confirms USE. | Pause/explicit USE exists; player understanding and tuning are unverified. |
| 5 | The player returns to the persistent live threat and makes the next LINE/CHAIN/Skill choice. | Current battle exists; first-session handoff is planned. |

`TETRIS-VIS-BOARD-001` is `AWAITING_USER_LOCK_CONFIRMATION_NOT_RUNTIME`. Locking it would approve a planning reference only; it would not create a Godot runtime asset, UI/scene implementation or Human/player UX PASS.

## 6. Generate-first and lock-after-inspection workflow

`AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION` applies to a bounded planning visual and to a runtime candidate whose exact consumer has already been defined. Generate the one candidate first, inspect it against this Bible and the consumer contract, then ask only whether the user locks it.

For production runtime images, generation still requires:

1. exact `res://` target path;
2. exact scene and node/material/UI consumer;
3. size/aspect, alpha/crop/anchor and import/use contract;
4. user lock confirmation after inspection; and
5. scene binding plus runtime/render evidence before promotion.

A planning exploration never bypasses these production gates.

## 7. Visual validation checklist

Before locking any candidate, check:

- Vanguard/Gatebreaker identity, proportion and silhouette;
- rendering language, palette/value hierarchy and lighting grammar;
- camera/framing and decorative density at gameplay size;
- UI/icon/VFX family and confirmed screen/flow information meaning;
- Keep, Avoid, Do Not Drift and allowed variation;
- no invented system/state/text, cross-project contamination, rights or reference-similarity concern;
- exact consumer geometry when the target is a runtime asset.

Human readability, target-resolution composite quality and player appeal remain `NOT_RUN` until direct receipts exist.
