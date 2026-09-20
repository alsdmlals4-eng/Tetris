# Idle motion candidate / 2026-09-14

User asked to enable Tetris connectivity and make enemies move continuously like their GIF, then added player skill performer cut-ins. Existing combat art and gameplay are preserved. This folder is a candidate, not a final visual lock.

## Inputs and comparison

- Enemy reference: user local `KakaoTalk_20260914_095733117.gif`, SHA256 `1d45e211746fd42ece23132f9079f057f64c5bff566b2344887f101c0287a027`, 56 frames at40ms,2240ms. Read multiple temporal samples. It informs motion continuity, not asset redistribution rights.
- Existing R2 boss six-state atlas: identity reference only. Those six poses are semantic states, not continuous inbetweens.
- [Godot sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html): ADAPT separate frame resources and explicit playback timing. Static whole-image scaling is insufficient for articulated movement; a complete skeletal rig is deferred pending separated artwork. Current bounded trial uses16 model-created frames with translation-only alignment, not56 newly authored frames.
- Skill reference: `Skill_1714356970996.gif`,172×40ms=6880ms, a multiple-action montage. Its actor entrance/cast/impact/exit vocabulary is adopted in R3 Task7, not its complete duration or copyrighted character pixels.

## Production and rejection

Built-in image generation produced `source-chroma.png` (actual1254×1254, not requested2048). Row-major4×4 boundaries use rounded source coordinates. Prompt required same dark armored hammer guardian, violet diamond core, subtle breathing idle, constant framing and solid green background. Generation ID and hashes are in manifest.json.

An image-model extraction attempt `exec-4128f387-9a5c-4caf-9824-c0b2de21bb0b` returned RGB with baked checkerboard and zero alpha pixels: REJECTED. Original green source was keyed mechanically with green-excess matte and edge despill, then translated to common320×320 cells/bottom pivot. `prepare.cjs` records processing; it creates no painted artwork or interpolated motion.

`idle-atlas.png` has845190 fully transparent pixels and15802 partial-alpha pixels; `idle-preview.gif` has16 frames,140ms each,2240ms loop. GIF palette transparency is only a preview; PNG is the alpha-quality consumer. Frame identity drift and smoothness are still REVIEW_REQUIRED, not natural-motion PASS.

Aseprite restricted tools rejected GIF import (unsupported extension); PNG atlas copied successfully into `idle-atlas-master.aseprite`,1280×1280 RGB, one editor frame. This is an editable atlas master, **not16 authored Aseprite animation frames**. Do not claim GIF roundtrip or native timeline authorship.

## Actual consumer and native checks

Actual isolated consumer: `res://scenes/replanned_r3/enemy_motion_preview.tscn::Enemy` AnimatedSprite2D,16 AtlasTexture regions,7.142857fps. Main combat screen is NOT rebound. Preview has no gameplay/save writer.

Tetris HiGodot3.2.0 session and Godot4.7.1 editor5852 were verified. Existing Hera1.0.0 enabled through HiGodot following explicit user instruction; exact Tetris path verified at8773. These numbers are receipts, not routing constants. Other editors unchanged.

Loop1: first preview run failed because new PNG had not imported. Explicit editor filesystem scan fixed that. Native screenshot then showed clipping at960×540; candidate placement/text corrected to fit actual viewport.

Loop2: corrected scene starts with helper_live=true, no startup errors. Native probe returned count16, playing=true, frame1→3 after300ms. Fresh Hera screenshot960×540 inspected: no edge clipping; diagnostics errors0/warnings0. Earlier multi-line evals failed compilation (mixed whitespace); a flat timed probe succeeded. Do not count failed probes as PASS.

Evidence ceiling: native animation playback and candidate alpha inspection, not full cycle aesthetic approval, combat integration, attack/recovery/hurt/defeat motion, player cut-in implementation, full R3 tests or release. R3 Task6–8 remains open. No Base promotion from this one attempt.

Rollback: remove only this isolated candidate/preview binding if rejected; restore local Hera plugin enablement only if requested. Preserve user project.godot whitespace and existing saves/art. Monthly evidence PDF update for this later motion work is still pending; earlier v1.0 predates it.
