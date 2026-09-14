# R3 screen and performer trial — 2026-09-14

Scope: isolated R3 battle view and receipt-driven cosmetic cast, not the full-game release. Main R2 scene, approved art and player storage remain unchanged. Local Tetris Hera enablement is separate from committed runtime source.

## Source and native evidence

- New screen: `scenes/replanned_r3/main.tscn`, `src/replanned_r3/r3_screen.gd`; equal622px regions at1280×720, one active board, finite supply/NEXT, shared ETA, current/next threat, category selection and last cast. New art resolver: `r3_performer.gd`; fallback retained if candidate fails integrity checks.
- Cosmetic clock: `r3_cast_presentation.gd`; no gameplay-effect writes. Receipts deduplicated, full620ms then bounded240ms coalesced follow-up; paused progress frozen; restored ledger produces no replay. Reduced-motion path tested in the presentation model; user-facing option not wired yet.
- RED screen/input/layout and recent-cast tests recorded before fixes. Focus loss previously moved LINE down and S release could leave CHAIN soft-drop held. Queue text initially overlapped controls. Corrected and rechecked.
- Full pre-performer regression483/483,7162assertions,79scripts; final performer-source regression **484/484,7187assertions,80scripts**,72.715s,exit0,stderr empty (`r3-performer-full.log/.err` in local Temp). The subsequently added native fixture driver is separately executed below; these are not exact-commit CI claims.
- Native Godot4.7.1 exact Tetris editor5852 via HiGodot8008; run8 helper live, no launch errors. Hera runtime26416 at1280×720, diagnostics0errors/0warnings. IDs are receipts, not future routing constants.
- `tests/tooling/r3_native_cast_probe.gd` creates an **explicit in-memory four-cell fixture**, then uses actual category/switch/move/hard-drop/tick commands. It does not save. Captured impact at160000 cosmetic microseconds, with shared ETA9700000us. ATK dealt4; DEF ward became3; SUP requested2 but applied0 at full HP (not a successful-healing claim). All actor regions matched the intended atlas row and asset errors were empty.
- `atk-impact-v2.png`, `def-impact-v2.png`, `sup-impact-v2.png` are inspected native views. Each retains the board, threat/next/timer, HP and category/last-skill text; transparent performer appears over dimmed boss stage. Earlier `def-impact-fixture.png` is pre-scale/panel correction evidence, not latest visual.

## Two scoped review loops

1. Whole source/view review found focus-release mutation, S release, bottom-label overlap, missing recent-skill display, missing environment region and source-cell clipping. Tests/renderer and one image-model correction addressed them. True RGBA and zero corrected source side contacts measured. Three key poses per category do not establish smooth motion.
2. Whole corrected slice re-read found stale candidate consumer/alpha count, stale native-connection absence, opaque/undersized performer staging and missing ward HUD. Corrected manifest/checkpoint, made staging translucent/clipped, enlarged actor and exposed ward. Full regression and3 inspected native category fixtures above close this bounded slice's findings. No full-game `CLEAN_REVIEW_EXIT` is claimed.

## Remaining and rollback

Task6 still needs tutorial, rebind/controller/focus/125% font, route/save/menu integration. Task7 needs smooth enemy/performer transitions, audio and organic timing/readability. Task8 needs strategy comparison, export/source-asset packaging, Blueprint/monthly evidence update, exact-head CI/main delivery and human/final-art gates. The3-pose candidate is not animation-quality approval. Preserve the original GIFs privately; reference characters were not copied. Roll back isolated R3 source/candidate binding without touching R2 assets or normal saves.

Project lesson: screenshot freshness needs live state correspondence and a rendered frame; a nonblank capture may be stale when the window is minimized/not drawing. Candidate cell gutters must be corrected by the image model, not hidden by padding clipped silhouettes. No new Base promotion or memory write.
