# Skill and Visual Canon Drift Incident

- Date: 2026-08-28
- Tracking: GitHub Issue #76
- Classification: `PROJECT_SPECIFIC_CANON_CORRECTION / NO_BASE_PROMOTION`

## Incident

Fresh comparison found that the previous Project Core Scene Board and current merged runtime made the project harder to understand than the user-directed design:

- the board did not clearly show the player’s new “category → current Combo result → confirm” decision;
- planning style was dark/pixel/metal-adjacent while the user’s intended reference is an airy parchment field manual with ink and watercolor rift treatment;
- actual `production_battle.gd`, catalog/session code and seed data still expose the old manual `ATK/DEF/SUP × T1–T6` grid.

## Evidence and correction

- User-provided comparison images were visually inspected and classified separately from their pictured legacy UI/rules.
- `TETRIS-SKILL-039` / `TETRIS-BALANCE-040` now own category-only selection, current-Combo Stage preview, explicit CONFIRM, 10-Combo cap and the bounded 5-MP-per-Combo lower-stage fallback.
- `TETRIS-VISUAL-041` now owns warm ivory parchment, sepia ink and watercolor violet rift presentation, while preserving the current runtime consumers as evidence rather than falsely relabeling them as new art.
- `TETRIS-VIS-BOARD-001` is superseded by a generated v2 planning board. The v2 board remains `GENERATED_EXPLORATION / NOT_RUNTIME` until user lock.
- Actual code/data remains explicitly `DOCUMENTED_NOT_IMPLEMENTED` for the new skill grammar and visual direction.

## Lesson

For this project, an image may communicate mood while still carrying superseded mechanics. A generated visual must have a structured text legend that names the actual player decision; visual resemblance must never be used to promote old UI, rules or runtime evidence.

## Base promotion decision

`NO_BASE_PROMOTION`: the specific Combo-stage fallback, Vanguard/Gatebreaker presentation and the exact visual reference are Tetris-only project facts. The general evidence-separation rule already exists in Base; this incident adds no new reusable workflow rule.
