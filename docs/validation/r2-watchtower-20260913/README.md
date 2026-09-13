# Watchtower preferred sheet runtime trial — 2026-09-13

Scope: isolated R2 watchtower enemy only. User liked the original six-pose image; this is style preference and standing bounded runtime-trial authority, NOT a final art/Human lock. Production assets, original five-asset metadata, normal saves and user project settings are preserved.

## Preparation and comparison

Completed-main input: `57c35bcd79998f8ed817233cc7e32be6e6960f9d`. Other open drafts were inspected read-only. Pinned Base9.4.4 is unchanged. Original source SHA256 `615eec1e3cd8fc3322f17b4921e8c5d32e6d9f2e6665165307b369ecc9f13e03`: 1254x1254 RGBA,912820 fully transparent pixels. Restricted Aseprite preserves a one-frame editable master; this is six semantic poses, NOT six authored animation frames/inbetweens.

REUSE_FIRST / benchmark preflight: reuse current enemy selector, immutable source and simulation-owned timing. [Godot AtlasTexture](https://docs.godotengine.org/en/stable/classes/class_atlastexture.html) documents region/margin/filter clipping; [CanvasItem shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html) supplies source UV/texture pixel coordinates. Sources read2026-09-13. ADAPT nonuniform regions plus common900x460 logical canvas and complementary source-space clipping; REJECT uniform627x418 cells because the release arrow crosses them; REJECT another redraw because it changes the preferred identity and previous revisions lost true alpha. No source pixels edited, new dependency or paid service. FEASIBLE within existing TextureRect consumers. Rollback reverts this extension and restores shared boss fallback.

## Native evidence ceiling

`final-idle.png`, `final-anticipation.png`, `final-impact.png`, `final-recovery.png`, `final-hurt.png`, `final-defeat.png`: native Godot4.7.1 run21,1280x720. All six inspected. Character is transparently composited; release arrow and neighboring-pose separation are visible. Common canvas prevents fitting-scale changes. Waist-up stage intentionally clips lower body; authored silhouette/pose differences remain, not continuous skeletal animation. These are in-memory presentation fixtures, not earned wins or human play. Battle composition, shared timer and player skill display remain present.

Automated regression and Windows package results are recorded below after execution. Final art approval, Human fun/readability, device/accessibility and release remain NOT_RUN. Original three pre-anchor captures are historical diagnostic evidence, not final frames.

Final local regression:402/402 GUT tests,4202 assertions,66 scripts,64.202s,exit0; stderr empty. Tooling90/90,27.841s,exit0. Initial added material identity assertion failed on typed-null versus null; inspecting GUT's `is_same` path identified a test-only mismatch, corrected to explicit assert_null for absent materials. Native result binding reports900x460 and material_cleared=true; `final-result.png` inspected (presentation fixture, not a victory receipt). User project.godot SHA remains46ce5e3295b0807f57fd16e07573ca7f0aa470c8e55696a8f8ca360d74caf020.

## Review / learning

Loop1 found missing JSON export include filter and stale NOT_BOUND metadata; corrected, and explicit extension consumer added. Loop2 at4d5d1b4595968f197bb0dd9ec42f310151e7c7b9 independently inspected all seven captures, source hash, diff, GUT log and actual package:0 new blocking code findings; exactly2 code/artifact review loops,CLEAN_REVIEW_EXIT for that implementation scope. Project-only learning: irregular pose sheets require source-bound region/anchor contracts and export raw-hash coverage; no Base policy promotion from one instance.

Package `Documents/Tetris R2 Local Trial/Builds/watchtower-20260913` built from4d5d1b4595968f197bb0dd9ec42f310151e7c7b9: R2_LOCAL_TRIAL_PACKAGE_VERIFIED, probe ok=true/watchtower_loaded=true, raw source hash exact. Eight existing headless teardown warnings remain explicitly listed in its manifest; not warning-clean/release evidence.

Additional native route driver reached outer-battle victory→SUPPLY→watchtower, binding R2-WATCHTOWER,HP100; `route-watchtower.png` inspected. No HP/resource override was used on this route. **Storage isolation failure:** changing screen path properties after `_ready` did not rebind its already-created disk objects, so this extra route driver wrote the normal expedition slot. Do not claim normal expedition save preservation. Existing current and .bak files were left intact; prior expedition recovery is UNVERIFIED and no guessed rollback was attempted. Standalone save hash also differs from the earlier-turn baseline, with an earlier timestamp; origin is not attributed without evidence. Options and project settings hashes remain unchanged. Subsequent pause readback first used a wrong property, then returned EVAL_GAME_NOT_READY; native pause PASS is not claimed by those attempts. Additional save-writing native probes stopped.

Remaining-work gate: watchtower presentation implementation/export verified; recovery of pre-probe expedition is UNVERIFIED. Next native tests must construct a new screen with isolated disk paths before `_ready` or explicitly rebind both disk objects, and verify normal-file before/after hashes. Whole-game foundry art/reader synchronization/Human/device/final-art/release remain open; this is not whole-game completion.
