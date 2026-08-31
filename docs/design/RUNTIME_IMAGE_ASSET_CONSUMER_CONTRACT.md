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

`TETRIS-VISUAL-043 · Obsidian Rift Tactics + Readable Puzzle Combat` is the current visual style authority. `TETRIS-VISUAL-041` and `TETRIS-VISUAL-028` remain superseded provenance for retained one-active-board and readable threat/resource hierarchy only.

The style anchor informs rendering language, but a style-anchor image is not automatically a production asset. Runtime consumption and visual direction are separate approvals.

Puzzle/HUD readability remains higher priority than decorative texture and spectacle.

## 8. CORE-029 current state

The CORE-029 runtime has a real reusable consumer: `TETRIS-IMG-031` is consumed by `MainRow/CombatColumn/CombatStage/StageBackdrop` in the main 50/50 Battle scene and, without duplication, by `scenes/production/title.tscn` → `Backdrop` for the current worktree title atmosphere. This proves the consumer-first path is live; it does not promote reference sheets or approve a new image request by itself.

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
| `TETRIS-IMG-033` · Vanguard Combat Cutout v1 | `IMG-P0-002` | `res://assets/production/characters/vanguard_combat_cutout_v1.png` | no active consumer; retained for a later explicitly approved player-stage or loadout surface | retained `Texture2D`, deliberately unbound | transparent alpha; vertical full body, sword and shield remain preserved, but the boss-only battle stage owns no player cutout | `SOURCE_ASSET_CANDIDATE` · `RUNTIME_INTEGRATION: RETAINED_UNBOUND_AFTER_USER_DIRECTED_BOSS_ONLY_STAGE` · `RUNTIME_VERIFICATION: NO_ACTIVE_RUNTIME_CONSUMER` |
| `TETRIS-IMG-034` · Gatebreaker Combat Cutout v1 | `IMG-P0-003` | `res://assets/production/bosses/gatebreaker_combat_cutout_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/CombatStage/GatebreakerReference` | `TextureRect.texture: AtlasTexture` sourced from the approved cutout | transparent alpha; declared upper-body atlas crop retains ram-arm, face and visible Rift Core; covered boss-only stage slot with `0.0` left anchor, `-0.18–1.18` vertical overscan, and frame clipping before the shared timer | `SOURCE_ASSET_CANDIDATE` · `RUNTIME_INTEGRATION: IMPLEMENTED_ON_BRANCH` · `RUNTIME_VERIFICATION: CURRENT_WORKTREE_RUNTIME_CAPTURED_1280X720_NOT_EXACT_COMMITTED_HEAD` |

The current 50/50 composition is boss-only inside `CombatStage`: it composes the approved Gatebreaker source as an upper-body `AtlasTexture`, fills the full horizontal slot, overscans vertically only inside the clipped stage frame, and cannot cover the shared action timer. `TETRIS-IMG-033` remains preserved but is not a battle-scene consumer. A separate `ResourceRow/VanguardPortrait` consumes the direct, readable `TETRIS-IMG-046` face-and-shoulders asset in a 96×96 state-strip slot. This preserves the board, forecast, shared timer, resource and skill regions outside the art bounds. Automated scene construction proves these slots load; it does not establish Human readability or final commercial-art approval.

## 11. Authored combat VFX candidates · Issue #47

The user explicitly requested the needed production images on 2026-08-28 after the screen-coverage audit. This bounded request produces only the two named VFX assets below; it does not reopen a generic image queue or turn UI labels into baked artwork.

| Asset | Exact target | Scene consumer | Purpose | Geometry / import | Runtime behavior |
| --- | --- | --- | --- | --- | --- |
| `TETRIS-IMG-035` · Vanguard Attack Accent v1 | `res://assets/production/vfx/vanguard_attack_accent_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/CombatStage/VanguardAttackAccent` | successful `ATTACK` technique feedback | 1254×1254 RGBA; transparent square crop; keep the open centre visible; `TextureRect.texture`, aspect-centred, pointer-transparent, lossless UI/VFX import inside the boss-only stage | shown for 0.42 seconds only after a committed ATTACK technique |
| `TETRIS-IMG-036` · Gatebreaker Threat Telegraph v1 | `res://assets/production/vfx/gatebreaker_threat_telegraph_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/CombatStage/GatebreakerThreatTelegraph` | active enemy telegraph feedback | 1254×1254 RGBA; transparent square crop and hollow centre; `TextureRect.texture`, aspect-centred behind the boss, pointer-transparent, lossless UI/VFX import | subtly pulses only while a non-terminal enemy ETA is active |

Both assets are original generated source candidates, not derivatives of the approved masters and not a claim of human readability approval. The static geometry keeps the VFX inside the CombatStage so it cannot cover the puzzle, forecast, resource, or skill controls.

## 12. Combo-resolved category seal candidates · current user-requested work

The current user requested produced skill-icon imagery for the implemented category-only `ATK / DEF / SUP → resolved preview → CONFIRM` surface. Each request is a separate bounded consumer; no atlas, title text, gameplay number, or new skill rule is baked into the image.

| Asset | Exact final target | Scene consumer | Purpose | Geometry / import | Pre-lock fallback and current state |
| --- | --- | --- | --- | --- | --- |
| `TETRIS-IMG-037` · Attack Category Seal v1 | `res://assets/production/icons/skill_lane_attack_seal_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Attack/CategorySeal.texture` | identify current-Combo ATK preview selection | 256×256 RGBA UI derivative of user-locked 1254×1254 transparent source; central sword/ink-slash mark inside 84% safe area; `TextureRect.texture`, aspect-centred, pointer-transparent, lossless UI import | label-only `ATK` Button remains functional; `USER_APPROVED → CANON_REGISTERED → IMPLEMENTED_ON_BRANCH → AUTOMATED_SCENE_VERIFIED`, runtime render and Human/player readability remain `NOT_RUN` |
| `TETRIS-IMG-038` · Defense Category Seal v1 | `res://assets/production/icons/skill_lane_defense_seal_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Defense/CategorySeal.texture` | identify current-Combo DEF preview selection | 256×256 RGBA UI derivative of user-locked 1254×1254 transparent source; central ward-shield mark inside 84% safe area; `TextureRect.texture`, aspect-centred, pointer-transparent, lossless UI import | label-only `DEF` Button remains functional; `USER_APPROVED → CANON_REGISTERED → IMPLEMENTED_ON_BRANCH → AUTOMATED_SCENE_VERIFIED`, runtime render and Human/player readability remain `NOT_RUN` |
| `TETRIS-IMG-039` · Support Category Seal v1 | `res://assets/production/icons/skill_lane_support_seal_v1.png` | `scenes/production/battle.tscn` → `MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Support/CategorySeal.texture` | identify current-Combo SUP preview selection | 256×256 RGBA UI derivative of user-locked 1254×1254 transparent source; central beacon/compass mark inside 84% safe area; `TextureRect.texture`, aspect-centred, pointer-transparent, lossless UI import | label-only `SUP` Button remains functional; `USER_APPROVED → CANON_REGISTERED → IMPLEMENTED_ON_BRANCH → AUTOMATED_SCENE_VERIFIED`, runtime render and Human/player readability remain `NOT_RUN` |

All three candidates use the current obsidian-rift grammar: black-steel silhouette, antique-gold edge treatment, lane colour (`ember red / ward blue / emerald green`) and a contained violet fracture accent, with no letters, numerals, pseudo-interface or decorative full frame. The user approved continuation under the recommended plan on 2026-08-31, which locks this reviewed three-asset set for these exact consumers only. The original generated artwork remains a high-resolution source candidate; each 256px repository target is a mechanical UI-size derivative, not new artwork. Scene binding and automated verification are complete on this branch; runtime render and Human/player readability remain separate gates.

| Asset | Locked source / SHA-256 | Repository target / SHA-256 | Consumer state |
| --- | --- | --- | --- |
| `TETRIS-IMG-037` | `C:\\Users\\user\\.codex\\generated_images\\01a04af3-ebbf-76e1-a16a-cc5f54b88a9e\\exec-46585d71-30a2-4214-998f-52375c05789b.png` · `13989e8ef1994e0cad7657d47c017a41350249500e41901039dad6edba7f36dc` | `res://assets/production/icons/skill_lane_attack_seal_v1.png` · `cc4ba2ab63e8e163b66fdc2032371b4ef98573b7569bab7b6c2566981bb42e6a` | `Attack/CategorySeal.texture` |
| `TETRIS-IMG-038` | `C:\\Users\\user\\.codex\\generated_images\\01a04af3-ebbf-76e1-a16a-cc5f54b88a9e\\exec-7c29eaac-8cff-46a7-8944-39e9255c4758.png` · `41614f9fbb8d3a2c47732aa0bd83652aaeabbbf286aeee225d927c95d10442aa` | `res://assets/production/icons/skill_lane_defense_seal_v1.png` · `607ce2a3bde267cbc5427a054a646d27fbe766c9d026115c08ced209424a1371` | `Defense/CategorySeal.texture` |
| `TETRIS-IMG-039` | `C:\\Users\\user\\.codex\\generated_images\\01a04af3-ebbf-76e1-a16a-cc5f54b88a9e\\exec-64a26a6e-d293-4714-9906-77e9b99dd17a.png` · `7801708bd8bffed6240a068058d726e7f601bd4d01756ebdc21dd8d0f78a43eb` | `res://assets/production/icons/skill_lane_support_seal_v1.png` · `1b37ac6bb6fdaeba530c752c88fff23209d663ea0378f0b240c427e1c158fc5d` | `Support/CategorySeal.texture` |

## 13. FRACTURE FRONTIER title logo · user-locked current work

The user selected **FRACTURE FRONTIER** as the world-facing game title, then locked the exact raster artwork below for the title consumer. It reflects the existing Frontier Gate setting and violet fracture threat without making the Vanguard player job, the Gatebreaker enemy, or an unapproved faction into the game name. The prior `FRACTURE VANGUARD` source candidate is rejected by this title decision and has no runtime consumer. Title text and the exact raster logo are `USER_APPROVED`; the checked source hash was copied to the repository target and bound in the current worktree. Automated scene verification does not replace target-resolution render capture or Human/player readability evidence.

| Asset | Candidate source | Exact final target | Scene consumer | Geometry / import | State |
| --- | --- | --- | --- | --- | --- |
| `TETRIS-IMG-047` · Fracture Frontier Title Logo v1 | Built-in image generation candidate locked by the user; source `C:\\Users\\user\\.codex\\generated_images\\01a04af3-ebbf-76e1-a16a-cc5f54b88a9e\\exec-d2ffda81-d064-4965-aa0d-3d785f3c5fb8.png`; source/target SHA-256 `a160ccee4992bbbcb0f4822a42461d2dfbf7e13e0246728f3d2a0185b2444628` | `res://assets/production/branding/fracture_frontier_title_logo_v1.png` | `scenes/production/title.tscn` → `Margin/Panel/Content/TitleLogo.texture` | source 1983×793 RGBA, transparent corners; preserve wide ratio, pointer-transparent `TextureRect`, target title safe area 920×368 minimum; Godot Texture2D import with no mipmaps | `USER_APPROVED → CANON_REGISTERED → IMPLEMENTED_ON_BRANCH → AUTOMATED_SCENE_VERIFIED`; target-resolution render capture and Human/player readability remain `NOT_RUN` |

The locked logo uses engraved dark-steel serif forms, restrained antique-gold filigree, a fractured Frontier Gate halo and a contained violet fracture accent. `TitleLogo` is pointer-transparent, aspect-centred and visible; the duplicate `TitleText` rendering is hidden so the logo remains the single title mark. This binding proves scene wiring only, not rendered legibility, player comprehension, commercial-rights clearance or release readiness.

### Lock implementation receipt · 2026-08-31

`FEASIBLE`: the locked 1983×793 RGBA source exactly matches the registered target and its 920×368 safe-area contract (both are approximately 2.5:1). `TitleLogo` remains `TextureRect` with `EXPAND_IGNORE_SIZE` and `STRETCH_KEEP_ASPECT_CENTERED`; the current official Godot `TextureRect` documentation confirms that this combination permits the container to control minimum size while centring and preserving the texture aspect. No new dependency, storage model, gameplay rule, or consumer was introduced. Rollback is one isolated asset path plus the `TitleLogo` ext-resource/visibility change; it does not alter the title→briefing flow.

| Required adversarial loop | Attack / recheck | Result |
| --- | --- | --- |
| 1 · Canon drift | Compare `origin/main`, current worktree canon, user decision and active open PRs. | `CONFLICT_RETAINED`: latest `main` still describes 60:40, while this user-approved worktree owns the newer 50:50 target; logo work changes neither ratio. Open PRs #46/#33/#23/#19 stayed read-only. |
| 2 · Asset/implementation contradiction | Re-hash source and repository target; inspect target path, import product and `TitleLogo.texture`. | Source and target SHA-256 match; Godot imported the exact target and the scene resolves the `Texture2D`. |
| 3 · Player-flow failure | Instantiate the title and verify logo visibility, no duplicate title label, and the existing briefing/deploy gate. | Automated UI suite passed; title continues to enter the guarded briefing flow. |
| 4 · Visual/consumer evidence confusion | Inspect the registered raster directly and distinguish that from a rendered game frame. | Artwork was visually inspected at source resolution; it is not a target-resolution or Human/readability pass. |
| 5 · Validation/merge evidence | Run full Godot/GUT and tooling suites; compare exact branch/remote after permitted commit and push. | Completed: the checked task branch was pushed and read back as clean and equal to its remote. No `main` merge is implied. |

## 14. Category seal implementation receipt · 2026-08-31

`FEASIBLE`: the three reviewed 1254×1254 transparent generated sources retain a clear sword/ward/beacon semantic after a mechanical 256×256 UI-size derivative. They fill only the pre-existing 36px-minimum `CategorySeal` slots, remain aspect-centred and pointer-transparent, and leave the textual `ATK` / `DEF` / `SUP` Buttons as the only interactive category controls. This preserves the approved `ATK / DEF / SUP → current Combo-resolved preview → explicit CONFIRM` flow; it does not restore a Tier grid, add a cost, add an auto-cast path or alter CHAIN/LINE rewards.

| Required adversarial loop | Attack / recheck | Result |
| --- | --- | --- |
| 1 · Canon and layout drift | Re-read current branch, `origin/main`, open-PR boundary, active UI ratios and older 60:40 passages. | `CONFLICT_RECONCILED_ON_BRANCH`: the user-approved 50:50 split remains in scene/canon; the old 60:40 plan/spec examples now identify and use the current 50:50 rule. Open PRs remain read-only. |
| 2 · Asset provenance and target integrity | Inspect each source, stage a 256px target without overwriting an existing file, verify dimensions/alpha family and re-hash all source/target pairs. | Three registered assets have exact source provenance, target SHA-256, 256×256 dimensions and a manifest consumer. The UI derivatives are mechanically resized originals, not invented replacement art. |
| 3 · Input and skill-flow regression | Instantiate the battle scene; assert every `CategorySeal` has an exact texture resource, aspect-centred scaling and pointer-ignore behavior while category Buttons and explicit confirmation remain. | The focused UI suite passes 25/25. The illustration does not consume input or change category-only selection semantics. |
| 4 · Test-harness failure isolation | A first full suite observed a zero physics-tick assertion. Reproduce the runtime group three times, compare changed files, trace Godot frame ordering and use a post-physics timer boundary. | Root cause was a pre-`_physics_process()` signal race in the test, not a gameplay/pause regression. Runtime group passed 3 consecutive times after the deterministic test-boundary correction. |
| 5 · Full verification and evidence ceiling | Re-run Godot import, all GUT tests, tooling tests, JSON/hash/diff checks; attempt the managed target-editor connection without touching another project. | Godot import, 248/248 GUT assertions and 46/46 tooling tests pass. No managed listener/session exists for this worktree path, so target-resolution render and Human/player readability remain `NOT_RUN`; automated evidence is not promoted beyond that ceiling. |
