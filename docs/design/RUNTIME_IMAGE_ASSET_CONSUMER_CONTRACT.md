# Runtime Image Asset Consumer Contract

- Status: **CURRENT / USER_APPROVED**
- Decision: `TETRIS-IMAGE-030 · Runtime Consumer First Asset Production`
- Date: 2026-08-26
- Scope: every newly generated or commissioned production image intended for the Tetris game runtime

## 1. Core rule

Tetris does not produce images merely to explain a design.

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
5. show the text Brief and stop;
6. wait for explicit user image-generation approval;
7. generate exactly one requested artifact;
8. inspect the result against the consumer geometry and style contract;
9. import/bind the approved artifact into the intended Godot consumer;
10. verify the scene references the asset and produce runtime/render evidence before calling it a production-integrated asset.

If steps 9–10 have not happened, classify the result as `SOURCE_ASSET_CANDIDATE` or `REFERENCE`, not `RUNTIME_INTEGRATED`.

## 6. Cardinality

One explicit image-generation approval produces exactly one image result and then stops for review.

One image may contain multiple regions only when the **runtime consumer itself** requires a single atlas/sprite sheet texture. In that case the Brief must define exact region/frame layout before generation.

Do not combine unrelated consumers merely to reduce generation count.

## 7. Style authority

`TETRIS-VISUAL-028 · Hand-Drawn Mystic Fantasy + Clean Puzzle UI` remains the current visual style authority.

The style anchor informs rendering language, but a style-anchor image is not automatically a production asset. Runtime consumption and visual direction are separate approvals.

Puzzle/HUD readability remains higher priority than decorative texture and spectacle.

## 8. CORE-029 current state

At the time this contract is adopted, CORE-029 production runtime consumers for the new 60/40 battle composition are still being implemented.

Therefore:

- new image generation remains **PAUSED**;
- the previous `Battle Screen UI final concept`, character master/pose sheet, and generic environment concept backlog is **HISTORICAL / REFERENCE ONLY**;
- image production resumes only after the relevant runtime consumer has an explicit contract.

## 9. Evidence ceiling

- written consumer contract → proves intended use only;
- generated source image → proves candidate visual content only;
- imported Godot asset + scene/resource reference → proves runtime wiring;
- exact-head runtime/render evidence → proves that tested build consumed/rendered the asset;
- Human evidence → required for readability, comprehension, appeal, and experience claims.

Never promote a concept/reference sheet into runtime proof merely because it visually resembles the target game screen.
