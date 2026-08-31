# Tetris · Visual Bible

- Status: `CURRENT REPOSITORY VISUAL OWNER`
- Current decisions: `TETRIS-VISUAL-043 · Obsidian Rift Tactics + Readable Puzzle Combat`; `TETRIS-IMAGE-030 · Runtime Consumer First Asset Production`
- Supersession: `TETRIS-VISUAL-041 · Parchment Field Manual` and `TETRIS-VISUAL-028` are `SUPERSEDED_FOR_GLOBAL_PRESENTATION_LANGUAGE`. Their one-active-board composition, readable threat/resource hierarchy and Vanguard/Gatebreaker identity constraints remain retained where compatible.
- Human-readable synthesis: [`PROJECT_MASTER_GDD.md`](PROJECT_MASTER_GDD.md)
- Asset records: `docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json`, `docs/assets/reference/planned/PROJECT_UNDERSTANDING_VISUAL_MANIFEST.json`, and `docs/assets/reference/planned/SCREEN_REFERENCE_MANIFEST.json`
- Evidence ceiling: a visual reference, generated exploration, imported source candidate, runtime-bound asset, runtime render and Human/player readability each prove different things. Never collapse their classes.

## 1. Visual promise

The game is an immediate **obsidian-black, antique-gold, violet-rift** tactical battle surface. The left Puzzle Surface remains the fastest place to manipulate. The right side makes the Gatebreaker feel threatening through a large boss silhouette, a luminous rift core, chained mass and a compact but readable Vanguard face portrait. Ornament clarifies the combat state; it never competes with it.

```text
Puzzle / Current ETA / resource / one confirmed choice
    outranks
large boss silhouette / Vanguard portrait / contained VFX
    outranks
frame ornament / texture / background detail
```

## 2. `TETRIS-VISUAL-043` source and adoption

| Evidence | Classification | Decision |
| --- | --- | --- |
| Latest user-provided combat, timer, skill-card and character references in the current conversation | `CURRENT_USER_VISUAL_REFERENCE` | **Adopt.** Dark fantasy combat presentation, obsidian panels, antique-gold construction, violet fracture light, a large boss, a readable face portrait, ornamental symbol tiles and one rich Skill detail card. Pictured legacy rules are reference only. |
| `TETRIS-VISUAL-041` parchment field-manual direction | `HISTORICAL_USER_REFERENCE` | **Reject for global runtime presentation.** Preserve only its readable one-board hierarchy and category-only skill rule boundary; do not retain parchment as the active battle look. |
| Current runtime source assets `TETRIS-IMG-031`, `033`, `034`, `035`, `036` | `ACTUAL_RUNTIME_EVIDENCE` | **Adapt.** Reuse approved character identity and rift assets through named Godot consumers; enlarge/recompose them only inside declared slots. Do not claim an ungenerated or unbound image is runtime-integrated. |

## 3. Global style anchor

| Layer | `TETRIS-VISUAL-043` contract |
| --- | --- |
| Rendering language | Illustrated dark-fantasy tactics: crisp ink-like silhouette edges, painterly material clusters and controlled luminous rift light. No generic glass HUD or low-contrast flat-card fallback. |
| Palette/value | **obsidian-black** carries structure; **antique-gold** frames actionable state; **violet-rift** identifies enemy threat; ember red, ward blue, emerald green, amber and cyan distinguish board/skill families. Immediate ETA, active board and resource changes retain the clearest contrast. |
| Material/lighting | Black steel, weathered gold, dark stone and contained purple energy. Glow is localized to a rift core, selected category, valid Chain tile or committed action; it must not wash out text. |
| Shape/silhouette | Vanguard remains a broad defender with shield, face and mantle. Gatebreaker remains asymmetric, heavy, chained and Rift-Core-led. The right combat stage uses an intentionally **large boss silhouette**; the resource strip uses a separate face-and-shoulders Vanguard crop. |
| Camera/framing | One large active Puzzle Surface plus persistent combat/threat context at an equal 50/50 split. The boss occupies a dedicated stage minimum height and may be compositionally cropped to preserve face, core and mass. |
| UI/icon/VFX grammar | Gold-edged dark panels, category seals and contained rift marks. ATK/DEF/SUP remain the only interactive Skill choices. A **non-interactive C1–C10 stage rail** explains the current or next stage; it must never become a manual tier selector. |

## 4. Keep, Avoid and allowed variation

### Keep

- One active large puzzle surface; live Current Telegraph + ETA; persistent combat context.
- Puzzle/HUD clarity above background, character and VFX density.
- A large Gatebreaker stage composition and a separate readable Vanguard face portrait.
- Symbolic CHAIN tiles whose color, center mark and frame remain readable under selection and resolution.
- Text, icon, number and frame-pattern redundancy for important state changes.
- Category-only Skill flow: `ATK / DEF / SUP → one Combo-Resolved preview → explicit CONFIRM`, plus a non-spending stage prebrowse.

### Avoid / Do Not Drift

- Two mandatory full boards, shared-turn/READY/timeout rails, permanent 3×6 skill wall, manual Tier buttons, or an unconfirmed auto-commit.
- Decorative darkness that hides the active board, Current Telegraph, ETA, resource change, resolved-stage preview or explicit CONFIRM.
- Images that invent undisclosed buttons, economy states, lore, title, rules or status flows. Exact explanations stay in structured repository text, not AI pseudo-text inside an image.
- Cross-project character language, reference similarity, or unrecorded rights/provenance.

### Allowed variation

Region, threat state and encounter pressure may deepen obsidian, gold or violet values and may strengthen localized rift pulse/VFX. The variation must preserve the active puzzle, Current ETA, player resources, category-only Skill flow and functional contrast.

## 5. Current asset and consumer evidence

| ID | Current class | Repository path / consumer | What it proves |
| --- | --- | --- | --- |
| `IMG-P0-001` | `APPROVED_REFERENCE` | `docs/assets/reference/approved/TETRIS-IMG-P0-001-battle-screen-composition-mockup.png` | Historical composition reference only; old matrix/rule details are not current. |
| `IMG-P0-002` | `APPROVED_REFERENCE` | Vanguard master reference | Character identity source, not a runtime asset by itself. |
| `IMG-P0-003` | `APPROVED_REFERENCE` | Gatebreaker master reference | Boss identity source, not a runtime asset by itself. |
| `TETRIS-IMG-031` | Runtime-bound production asset | `CombatStage/StageBackdrop` | Current dark stage consumer binding, subject to runtime/render evidence ceiling. |
| `TETRIS-IMG-033/034` | Retained player source / runtime-bound boss source | `TETRIS-IMG-033` has no active consumer; `GatebreakerReference` consumes `TETRIS-IMG-034` | The full-body Vanguard source remains preserved for a future approved player surface, while the live CombatStage is boss-only. |
| `TETRIS-IMG-035/036` | Runtime-bound VFX candidates | Attack accent / active telegraph texture nodes | Bounded combat feedback binding. |
| `TETRIS-IMG-037/038/039` | User-locked category-seal runtime assets | `Attack` / `Defense` / `Support` `CategorySeal` slots | Keeps the category-only Combo-resolved skill choice scannable without restoring a Tier grid. |
| `TETRIS-IMG-040/041/042/043/044/045` | User-locked ornamental tile runtime assets | `ChainBoardView` and `LineBoardView` texture mappings | Replaces the visible flat-color fallback for the six Chain symbols and the seven existing tetromino IDs; it does not modify matching, Line clear, resolution or rewards. |
| `TETRIS-IMG-046` | User-locked Vanguard face runtime asset | `ResourceRow/VanguardPortrait` | Replaces the unreliable face crop from the full-body stage cutout while preserving the compact resource-strip role. |
| `TETRIS-IMG-047` | User-locked title runtime asset | `TitleLogo.texture` | Owns the FRACTURE FRONTIER title raster under an ID that cannot collide with the tile family. |
| `TETRIS-VIS-BOARD-001` | `SUPERSEDED_BY_TETRIS-VIS-BOARD-002` | `docs/assets/reference/planned/tetris-project-core-scene-visual-board-v1.png` | Replaced because it did not make the then-current category-resolved skill flow intelligible. It is historical and not a runtime asset. |
| `TETRIS-VIS-BOARD-002` | `USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME` | `docs/assets/reference/planned/tetris-project-core-scene-visual-board-v2.png` | User-locked AI-understanding/planning review board; `runtime_consumer: NONE`. It is still not a runtime asset. |

## 6. `PROJECT_CORE_SCENE_VISUAL_BOARD` v2 exact legend

The board is a planning visualization. It deliberately uses symbols, seals, arrows and short labels instead of long AI-generated prose. The structured legend, not pixels, owns exact rules.

| Panel | Scene / screen | Player goal and action | Choice / feedback / next connection | Status boundary |
| --- | --- | --- | --- | --- |
| 1 | Frontier Gate / first live combat context | Read Gatebreaker Current Telegraph + ETA and make a move in one active puzzle surface. | The same field manual shows threat, MP and Combo before the player opens Skill. | Combat context exists; target-resolution readability is not Human-validated. |
| 2 | CHAIN reward state | Complete an orthogonal adjacent swap whose same-symbol line reaches 3+. | Chain resolution raises Combo and shows its MP recovery, creating a meaningful current Combo state. | All-axis/MP-lock/cap/formula are implemented in the current worktree; target-resolution readability is pending. |
| 3 | Tactical Skill category choice | Full tactical pause; select exactly one of ATK/DEF/SUP seals. | The chosen seal reveals one current Combo-Resolved technique. Selection alone has no cost. | `TETRIS-SKILL-039` is implemented in the current worktree; Human comprehension is unverified. |
| 4 | Resolved technique preview and confirm | Inspect purpose, target, expected effect, current Combo Stage and MP/Combo cost. | Explicit CONFIRM resolves that one pre-authored technique; there is no manual tier/card browse. | Preview/confirm grammar is implemented in the current worktree; Human/player evidence remains `NOT_RUN`. |
| 5 | MP-insufficient fallback | Understand a lower-stage result before committing. | If the current stage lacks MP, surplus Combo converts at 5 MP each only to reach the highest feasible lower stage; then CONFIRM spends the displayed total. | Formula/runtime/data/test path is implemented in the current worktree; exact-head visual verification is pending. |
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
- obsidian-black / antique-gold / violet-rift grammar, palette/value hierarchy and localized lighting;
- camera/framing and decorative density at gameplay size;
- category seals, resolved-stage preview, fallback and CONFIRM information meaning;
- Keep, Avoid, Do Not Drift and allowed variation;
- no invented system/state/text, cross-project contamination, rights or reference-similarity concern;
- exact consumer geometry when the target is a runtime asset.

Human readability, target-resolution composite quality and player appeal remain `NOT_RUN` until direct receipts exist.

## 9. 2026-09-01 recovery receipt and remaining gate

- `TETRIS-VISUAL-043` recovery is `IMPLEMENTED_IN_CURRENT_WORKTREE_RUNTIME_CAPTURED`: `artifacts/runtime/tetris-recovery-line-boss-shared-timer-1280x720-20260901.png` (SHA-256 `2db52085d2f0ec7eb274415ba9540e39ebaa3623a40702583d21cb15dc163ac0`) shows the 634px / 634px 50:50 split, ornamental LINE tiles, a boss-only clipped CombatStage, the separate Vanguard face portrait, `ACTION PHASE · PLAYER WINDOW`, and the same enemy ETA rendered as `SEC · BOSS / PLAYER`. Its evidence-only folder contains `.gdignore`, so Godot neither imports nor exports the capture as game content.
- The runtime interaction receipt opened Tactical Pause, selected `ATK`, and read `ATTACK · First Edge`, `COMBO 0 / 10`, `MP 0 / 60` and `PREVIEW ONLY`. This proves category prebrowse did not spend MP or Combo at zero Combo; it does not prove a human readability or balance PASS.
- Five adversarial checks were completed for this correction: (1) canon/source drift, (2) red→green 1280×720 containment, (3) runtime category/no-spend flow, (4) candidate asset-consumer boundary, and (5) full Godot/tooling regression. No new source or layout blocker remained after the fifth pass.
- The 2026-09-01 user approval locks the six ornamental tile sources and the Vanguard face-portrait source for their declared consumers. Their compact runtime derivatives, source hashes and rollback boundaries are recorded as `TETRIS-IMG-040` through `TETRIS-IMG-046`; the title logo is separately `TETRIS-IMG-047`.

## 10. Locked Chain tile and Vanguard face implementation receipt · 2026-09-01

`FEASIBLE`: six approved 1254×1254 ornamental tile candidates and one approved 1254×1254 Vanguard face candidate have exact, existing consumers: `ProductionChainBoardView` maps its pre-existing `R/G/B/Y/P/C` symbols and `ProductionLineBoardView` maps its pre-existing `I/J/L/O/S/T/Z` tetromino IDs to those same `Texture2D` files; `ResourceRow/VanguardPortrait` owns a 96px, pointer-transparent, aspect-centred portrait slot. The runtime derivatives are mechanically reduced to 256×256 for tiles and 512×512 for the portrait, preserving the locked artwork while avoiding seven unnecessary 1254px runtime copies. No gameplay, board data, matching rule, Chain/Line reward, save key, MP rule, stage rule or input binding changes.

| Required adversarial loop | Attack / recheck | Result before runtime capture |
| --- | --- | --- |
| 1 · Canon drift | Re-read current visual/skill/Chain contracts, active branch and open PR boundary. | The locked assets preserve the one active board, 50:50 split and category-only Skill flow. Open PRs remain read-only. |
| 2 · Asset/provenance contradiction | Re-hash each source and each compact derivative; bind an exact path, scene node and rollback for every asset. | Seven manifest records own source hash, derived hash, dimensions, consumer and rollback. The high-resolution candidates remain outside the runtime target. |
| 3 · Rule and input regression | Map render-only symbols and piece IDs; preserve Chain session, Line session and existing input paths. | `get_tile_texture()` and `get_piece_texture()` have no state mutation; a missing ID retains a non-gameplay fallback tint. |
| 4 · Portrait/stage role collision | Remove `VanguardReference` from the enemy stage, preserve `TETRIS-IMG-033` unbound, and clip the enlarged Gatebreaker to its own frame. | Player identity remains a direct face asset in the resource strip; the stage is boss-only and cannot cover the shared timer. |
| 5 · Verification ceiling | Distinguish source inspection, asset hash checks, scene binding, current-worktree render capture and human readability. | Automated verification plus live 1280×720 runtime capture are complete; exact committed-head and Human/player readability remain separate gates. |
