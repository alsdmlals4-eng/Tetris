# Runtime Image Asset Consumer Contract

- Status: **CURRENT / USER_APPROVED**
- Decision: `TETRIS-IMAGE-030 · Runtime Consumer First Asset Production`
- Date: 2026-08-26
- Scope: every newly generated or commissioned production image intended for the Tetris game runtime

## 1. Core rule

Tetris does not treat images made merely to explain a design as **production images**.

A production image is valid only when it has a concrete game consumer.

Before image generation starts, the work item must identify:

```text
asset_id
→ target res:// asset path
→ consumer scene path
→ consumer node / material / UI slot
→ required pixel size or aspect
→ alpha / crop / anchor rules
→ Godot import / use mode
```

If those fields are not known, the image is not ready for production generation.

`concept sheet`, `mood sheet`, `master sheet`, `pose explanation sheet`, `combined UI sheet`, and full-screen explanatory mockups are reference artifacts only. They do not count as production image assets unless the runtime directly consumes that exact file.

## 2. Consumer-first acceptance contract

Each production image Brief must contain all of the following.

### Asset identity

- stable asset id;
- exact target path under `res://`;
- one intended gameplay purpose.

### Runtime consumer

- exact scene path;
- exact node path or material/UI property;
- whether the file is used as `Texture2D`, `AtlasTexture`, `SpriteFrames`, `NinePatchRect`, shader mask/noise/input, or another explicit Godot consumer;
- fallback/placeholder behavior before the final image is wired.

### Geometry

- pixel dimensions or bounded aspect/scale contract;
- transparent vs opaque background;
- crop-safe area;
- pivot/anchor/alignment rules;
- atlas region/frame ordering when applicable.

### Import/use mode

- filter on/off expectation;
- mipmap expectation when relevant;
- compression/lossless expectation when relevant;
- whether the asset is UI, world/background, character/cutout, icon, VFX texture, mask, or atlas.

Exact import flags may remain implementation-owned where Godot defaults are sufficient, but the consumer type must be explicit before generation.

## 3. Allowed production image categories

Examples of valid production images once a consumer exists:

- a Combat Stage background texture directly referenced by the production battle scene;
- a Vanguard or Gatebreaker cutout/sprite directly referenced by the Combat Stage;
- a Telegraph icon directly used by the Telegraph UI;
- a Technique icon directly used by the Skill UI;
- a NinePatch/UI frame texture directly used by a `NinePatchRect` or StyleBox resource;
- a VFX mask/noise/impact texture directly referenced by a shader/material/particle effect;
- a sprite atlas only when the runtime actually consumes that atlas and its region/frame contract is defined.

## 4. Rejected as production assets

The following may remain useful references, but must not be treated as production image backlog items by default:

- Battle Screen concept screenshots whose pixels are never loaded by the game;
- character turnaround/master sheets used only for explanation;
- multi-pose sheets unless the exact sheet is a runtime atlas;
- moodboards;
- explanatory diagrams;
- combined UI + character + environment sheets;
- images made only to show stakeholders what a future screen might look like;
- duplicate variants with no named runtime slot.

A high-quality image with no runtime consumer still fails this contract.

## 5. Required workflow

Production image work follows this sequence:

1. implement or precisely define the runtime consumer;
2. wire a placeholder or deterministic temporary asset where practical;
3. record the exact consumer contract;
4. derive the image Brief from that consumer rather than from a generic concept request;
5. show the text Brief only when it improves a material design decision; otherwise proceed with the bounded work item;
6. generate the candidate automatically under the approved project workflow;
7. inspect the result against the consumer geometry and style contract;
8. ask the user only whether to **lock** the inspected candidate;
9. after user lock confirmation, import/bind the approved artifact into the intended Godot consumer;
10. verify the scene references the asset and produce runtime/render evidence before calling it a production-integrated asset.

If steps 9–10 have not happened, classify the result as `SOURCE_ASSET_CANDIDATE` or `REFERENCE`, not `RUNTIME_INTEGRATED`.

## 6. Generation and lock workflow amendment · 2026-08-28

User direction: **do not request approval before generating an image; generate first, then request confirmation only to lock the selected result.**

`AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION` applies to bounded planning visualizations and to runtime image work that already has an exact Godot runtime consumer. It changes the approval timing; it does **not** remove the consumer-first gate, expand a work item into a batch, or promote an image merely because it was generated.

- A planning board or concept comparison is `GENERATED_EXPLORATION`: it has no runtime consumer and does not become a runtime asset.
- A runtime candidate still requires an exact target `res://` path, scene, node/slot, geometry, import/use mode, and user lock confirmation before it is classified as a Project Asset.
- Before that lock, an image remains `SOURCE_ASSET_CANDIDATE` or `REFERENCE`; it does not become a runtime asset, UI implementation, scene implementation, or Human/player usability PASS.
- One bounded consumer/work-item may generate one candidate at a time. A later variation requires a new bounded reason; do not silently build an unrelated image batch.

One image may contain multiple regions only when the **runtime consumer itself** requires a single atlas/sprite sheet texture. In that case the Brief must define exact region/frame layout before generation.

Do not combine unrelated consumers merely to reduce generation count.

## 7. Style authority

`TETRIS-VISUAL-041 · Parchment Field Manual + Readable Puzzle Tactics` is the current visual style authority. `TETRIS-VISUAL-028` remains superseded provenance for retained one-active-board and readable threat/resource hierarchy only.

The style anchor informs rendering language, but a style-anchor image is not automatically a production asset. Runtime consumption and visual direction are separate approvals.

Puzzle/HUD readability remains higher priority than decorative texture and spectacle.

## 8. CORE-029 current state

The merged CORE-029 baseline has a real consumer: `TETRIS-IMG-031` is consumed by `MainRow/CombatColumn/CombatStage/StageBackdrop` in the balanced 50/50 Battle scene. This proves the consumer-first path is live; it does not promote reference sheets or approve a new image request by itself.

Therefore:

- runtime image generation is blocked until a concrete consumer gap has an exact contract; planning exploration may proceed under `AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION`;
- the previous `Battle Screen UI final concept`, character master/pose sheet, and generic environment concept backlog is **HISTORICAL / REFERENCE ONLY**;
- image production resumes only after the relevant runtime consumer has an explicit contract. A later Draft PR may provide branch-only consumer evidence; it does not rewrite merged-main status.

## 9. Evidence ceiling

- written consumer contract → proves intended use only;
- generated source image → proves candidate visual content only;
- imported Godot asset + scene/resource reference → proves runtime wiring;
- exact-head runtime/render evidence → proves that tested build consumed/rendered the asset;
- Human evidence → required for readability, comprehension, appeal, and experience claims.

Never promote a concept/reference sheet into runtime proof merely because it visually resembles the target game screen.

## 10. Approved-source character cutout preparation · Issue #38

The user has approved bounded derivation of two runtime source-asset candidates from existing P0 masters. This is not a new character-design request and does not alter the approved originals.

| Derived asset | Approved source | Exact target | Planned scene consumer | Consumer type | Geometry / anchor | Current evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `TETRIS-IMG-033` · Vanguard Combat Cutout v1 | `IMG-P0-002` | `res://assets/production/characters/vanguard_combat_cutout_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/ResourceFrame/ResourceRow/VanguardPortrait` | `TextureRect.texture: AtlasTexture` | transparent alpha; source cutout preserved; deterministic 400×400 face/shoulder crop into a `128×96` HUD portrait, aspect-centred and pointer-transparent | `SOURCE_ASSET_CANDIDATE` · `RUNTIME_INTEGRATION: IMPLEMENTED_ON_BRANCH` · `RUNTIME_VERIFICATION: PENDING_EXACT_HEAD_RENDER` |
| `TETRIS-IMG-034` · Gatebreaker Combat Cutout v1 | `IMG-P0-003` | `res://assets/production/bosses/gatebreaker_combat_cutout_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/CombatStage/GatebreakerReference` | `TextureRect.texture: AtlasTexture` | transparent alpha; deterministic 932×1128 boss-focused stage crop with the Rift Core and ram-arm safe area; full CombatStage width, vertically enlarged and clipped, pointer-transparent | `SOURCE_ASSET_CANDIDATE` · `RUNTIME_INTEGRATION: IMPLEMENTED_ON_BRANCH` · `RUNTIME_VERIFICATION: PENDING_EXACT_HEAD_RENDER` |

Issue #42 now keeps the combat roles separate: the Gatebreaker alone occupies the boss-focused, aspect-covered `CombatStage` crop, while the Vanguard appears only as a large readable HUD portrait beside player resources. This preserves the stage backdrop, gives the boss a clear hierarchy and keeps the puzzle, forecast, resource and skill regions outside the art bounds. An earlier Godot 4.7.1 scene-tree-equivalent result confirmed that the StageBackdrop and both cutouts visible in the prior same-stage layout; it is retained solely as historical source-asset evidence. The changed consumers require an exact-head render before their `PENDING_EXACT_HEAD_RENDER` status can advance. Neither record establishes Human readability or final commercial-art approval.

## 11. Authored combat VFX candidates · Issue #47

The user explicitly requested the needed production images on 2026-08-28 after the screen-coverage audit. This bounded request produces only the two named VFX assets below; it does not reopen a generic image queue or turn UI labels into baked artwork.

| Asset | Exact target | Scene consumer | Purpose | Geometry / import | Runtime behavior |
| --- | --- | --- | --- | --- | --- |
| `TETRIS-IMG-035` · Vanguard Attack Accent v1 | `res://assets/production/vfx/vanguard_attack_accent_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/CombatStage/VanguardAttackAccent` | successful `ATTACK` technique feedback | 1254×1254 RGBA; transparent square crop; keep the open centre visible; `TextureRect.texture`, aspect-centred, pointer-transparent, lossless UI/VFX import | shown for 0.42 seconds only after a committed ATTACK technique |
| `TETRIS-IMG-036` · Gatebreaker Threat Telegraph v1 | `res://assets/production/vfx/gatebreaker_threat_telegraph_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/CombatStage/GatebreakerThreatTelegraph` | active enemy telegraph feedback | 1254×1254 RGBA; transparent square crop and hollow centre; `TextureRect.texture`, aspect-centred behind the boss, pointer-transparent, lossless UI/VFX import | subtly pulses only while a non-terminal enemy ETA is active |

Both assets are original generated source candidates, not derivatives of the approved masters and not a claim of human readability approval. The static geometry keeps the VFX inside the CombatStage so it cannot cover the puzzle, forecast, resource, or skill controls.
