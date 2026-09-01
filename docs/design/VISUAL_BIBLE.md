# Tetris · Visual Bible

- Status: `CURRENT REPOSITORY VISUAL OWNER`
- Current decisions: `TETRIS-VISUAL-041 · Parchment Field Manual + Readable Puzzle Tactics`; `TETRIS-IMAGE-030 · Runtime Consumer First Asset Production`
- Supersession: `TETRIS-VISUAL-028` is `SUPERSEDED_FOR_GLOBAL_PRESENTATION_LANGUAGE`. Its one-active-board composition, readable threat/resource hierarchy and Vanguard/Gatebreaker identity constraints remain retained where compatible.
- Human-readable synthesis: [`PROJECT_MASTER_GDD.md`](PROJECT_MASTER_GDD.md)
- Asset records: `docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json`, `docs/assets/reference/planned/PROJECT_UNDERSTANDING_VISUAL_MANIFEST.json`, and `docs/assets/reference/planned/SCREEN_REFERENCE_MANIFEST.json`
- Evidence ceiling: a visual reference, generated exploration, imported source candidate, runtime-bound asset, runtime render and Human/player readability each prove different things. Never collapse their classes.

## 1. Visual promise

The game should feel like a Frontier Gate field manual drawn during a real crisis: **warm ivory parchment, sepia ink, and watercolor violet rift** energy make the world tactile, while the active board, ETA, MP, Combo and one confirmed tactical result stay faster to read than the illustration.

```text
Puzzle / ETA / resource / one confirmed choice
    outranks
character, stage and VFX illustration
    outranks
ornament, texture and annotation
```

## 2. `TETRIS-VISUAL-041` source and adoption

| Evidence | Classification | Decision |
| --- | --- | --- |
| User-provided `KakaoTalk_20260826_193206860_05.png` | `CURRENT_USER_VISUAL_REFERENCE` | Adopt its airy parchment field-manual layout, fine ink construction lines, watercolor rift washes, imperfect hand-drawn contour and annotated-character energy. Do not treat its pictured legacy UI/rules as canon. |
| User-provided `ChatGPT Image 2026년 8월 26일 오전 08_34_06 (2).png` | `CURRENT_USER_COMPARISON_REFERENCE` | Reject its dark metal-card density and permanent old skill matrix for the current visual language. Its existence does not authorize the shared timer, READY, Stock 6, old 3×6 selection or any pictured number/rule. |
| Current runtime images `TETRIS-IMG-031`, `033`, `034`, `035`, `036` | `ACTUAL_RUNTIME_EVIDENCE` | Preserve their actual consumer/provenance and character silhouettes until a separately contracted runtime art replacement. They are not evidence that the new parchment presentation is implemented. |

## 3. Global style anchor

| Layer | `TETRIS-VISUAL-041` contract |
| --- | --- |
| Rendering language | Hand-drawn field manual: fine **sepia ink** contour, loose construction marks, selective cross-hatching and limited watercolor pools. No photo-real finish, pixel treatment or generic glass UI. |
| Palette/value | **Warm ivory parchment** is the base. Charcoal/sepia owns legible text and structure; watercolor violet rift owns threat; restrained rust-red/steel-blue/moss-green distinguish ATK/DEF/SUP without relying only on hue. Puzzle cells and immediate ETA/action states take the clearest values. |
| Material/lighting | Fibrous paper grain, ink bleed and translucent wash may appear in empty/background zones. Strong light is a painted rift glow or local action wash, never a black-metal/neon interface. |
| Shape/silhouette | Vanguard remains a broad triangular defender with offset shield, face/weapon and short mantle. Gatebreaker remains asymmetric, heavy, chained and Rift-Core-led. Their current identities are retained; their shading may become sketch/wash in a future consumer-specific art pass. |
| Camera/framing | One large active puzzle surface plus persistent combat/threat context. The planned board may use a left-to-right field-note flow; runtime targets a balanced 50/50 puzzle/combat hierarchy. The Gatebreaker alone owns the oversized stage crop, while Vanguard remains a large readable HUD portrait beside player resources. |
| UI/icon/VFX grammar | UI is paper labels, ink borders, clear icon families and sparing wash highlights. ATK/DEF/SUP are category seals, not a 3×6 grid. A selected seal reveals one large resolved technique preview; confirmation gets a clear stamp/ink-slash response. |

## 4. Keep, Avoid and allowed variation

### Keep

- One active large puzzle surface; live Current Telegraph + ETA; persistent combat context.
- Puzzle/HUD clarity above background, character and VFX density.
- Warm parchment negative space around the active choice; real dark ink for contrast, not a dark full-screen UI.
- Readable Vanguard/Gatebreaker silhouette separation at gameplay scale.
- Text, icon, number and frame-pattern redundancy for important state changes.
- Category-only Skill flow: `ATK / DEF / SUP → one Combo-Resolved preview → explicit CONFIRM`.

### Avoid / Do Not Drift

- A full-screen **dark metal-card** surface, dense beveled frames, generic sci-fi glass HUD, pixel/CRT/scanline treatment, or noise/dither inside small text and puzzle cells.
- Two mandatory full boards, shared-turn/READY/timeout rails, permanent 3×6 skill wall, manual Tier buttons, or an unconfirmed auto-commit.
- Images that invent undisclosed buttons, economy states, lore, title, rules or status flows. Exact explanations stay in structured repository text, not AI pseudo-text inside an image.
- Full-screen spectacle that obscures the active puzzle, Current Telegraph, ETA, resource change, resolved-stage preview or explicit CONFIRM.
- Cross-project character language, reference similarity, or unrecorded rights/provenance.

### Allowed variation

Region, threat state, time of day and faction/state may vary wash intensity, paper temperature, local material and VFX density only when the shared silhouettes, category seals and information hierarchy remain intact. A decisive threat may deepen violet and charcoal; a safe planning/briefing surface may use more ivory space. Variation must not return to a dark metal-card UI or remove necessary functional contrast.

## 5. Current asset and consumer evidence

| ID | Current class | Repository path / consumer | What it proves |
| --- | --- | --- | --- |
| `IMG-P0-001` | `APPROVED_REFERENCE` | `docs/assets/reference/approved/TETRIS-IMG-P0-001-battle-screen-composition-mockup.png` | Historical composition reference only; old matrix/rule details are not current. |
| `IMG-P0-002` | `APPROVED_REFERENCE` | Vanguard master reference | Character identity source, not a runtime asset by itself. |
| `IMG-P0-003` | `APPROVED_REFERENCE` | Gatebreaker master reference | Boss identity source, not a runtime asset by itself. |
| `TETRIS-IMG-031` | Runtime-bound production asset | `CombatStage/StageBackdrop` | Current dark stage consumer binding, subject to runtime/render evidence ceiling. |
| `TETRIS-IMG-033/034` | Runtime-bound source candidates | `VanguardPortrait` HUD / `GatebreakerReference` boss stage | Separate player-readability and boss-hierarchy bindings; identity provenance remains unchanged. |
| `TETRIS-IMG-035/036` | Runtime-bound VFX candidates | Attack accent / active telegraph texture nodes | Bounded combat feedback binding. |
| `TETRIS-VIS-BOARD-001` | `SUPERSEDED_BY_TETRIS-VIS-BOARD-002` | `docs/assets/reference/planned/tetris-project-core-scene-visual-board-v1.png` | Replaced because it did not make the current category-resolved skill flow or the intended parchment style intelligible. Not a runtime asset. |
| `TETRIS-VIS-BOARD-002` | `USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME` | `docs/assets/reference/planned/tetris-project-core-scene-visual-board-v2.png` | User-locked AI-understanding/planning review board; `runtime_consumer: NONE`. It is still not a runtime asset. |

## 6. `PROJECT_CORE_SCENE_VISUAL_BOARD` v2 exact legend

The board is a planning visualization. It deliberately uses symbols, seals, arrows and short labels instead of long AI-generated prose. The structured legend, not pixels, owns exact rules.

| Panel | Scene / screen | Player goal and action | Choice / feedback / next connection | Status boundary |
| --- | --- | --- | --- | --- |
| 1 | Frontier Gate / first live combat context | Read Gatebreaker Current Telegraph + ETA and make a move in one active puzzle surface. | The same field manual shows threat, MP and Combo before the player opens Skill. | Combat context exists; target-resolution readability is not Human-validated. |
| 2 | CHAIN reward state | Complete an orthogonal adjacent swap whose same-symbol line reaches 3+. | Chain resolution raises Combo and shows its MP recovery, creating a meaningful current Combo state. | All-axis/MP-lock/cap/formula are approved but runtime remains partial. |
| 3 | Tactical Skill category choice | Full tactical pause; select exactly one of ATK/DEF/SUP seals. | The chosen seal reveals one current Combo-Resolved technique. Selection alone has no cost. | `TETRIS-SKILL-039` is documented, not implemented. |
| 4 | Resolved technique preview and confirm | Inspect purpose, target, expected effect, current Combo Stage and MP/Combo cost. | Explicit CONFIRM resolves that one pre-authored technique; there is no manual tier/card browse. | Preview/confirm grammar is planned; actual runtime remains legacy manual Tier 1–6. |
| 5 | MP-insufficient fallback | Understand a lower-stage result before committing. | If the current stage lacks MP, surplus Combo converts at 5 MP each only to reach the highest feasible lower stage; then CONFIRM spends the displayed total. | Formula is current Phase 1 canon; runtime/data/test proof is pending Phase 2. |
| 6 | Outcome and return to threat | See the action stamp/impact, changed resource state and same frozen context resume. | The result answers or alters the threat, prompting the next LINE/CHAIN/Skill preparation. | Player comprehension, balance and fun remain `NOT_RUN`. |

The user locked `TETRIS-VIS-BOARD-002` as `USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME` on 2026-08-28. The lock approves only this planning reference; it does not create a Godot runtime asset, UI/scene implementation, runtime render or Human/player UX PASS.

## 7. Generate-first and lock-after-inspection workflow

`AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION` applies to a bounded planning visual and to a runtime candidate whose exact consumer has already been defined. Generate the candidate first, inspect it against this Bible and the consumer contract, then ask only whether the user locks it.

For production runtime images, generation still requires:

1. exact `res://` target path;
2. exact scene and node/material/UI consumer;
3. size/aspect, alpha/crop/anchor and import/use contract;
4. user lock confirmation after inspection; and
5. scene binding plus runtime/render evidence before promotion.

A planning exploration never bypasses these production gates.

## 8. Visual validation checklist

Before locking any candidate, check:

- Vanguard/Gatebreaker identity, proportion and silhouette;
- warm ivory parchment / sepia ink / watercolor violet rift grammar, palette/value hierarchy and lighting;
- camera/framing and decorative density at gameplay size;
- category seals, resolved-stage preview, fallback and CONFIRM information meaning;
- Keep, Avoid, Do Not Drift and allowed variation;
- no invented system/state/text, cross-project contamination, rights or reference-similarity concern;
- exact consumer geometry when the target is a runtime asset.

Human readability, target-resolution composite quality and player appeal remain `NOT_RUN` until direct receipts exist.
