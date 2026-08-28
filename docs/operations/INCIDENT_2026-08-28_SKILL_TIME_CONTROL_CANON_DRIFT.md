# Project Incident · Skill Time-Control Canon Drift

- Date: 2026-08-28
- Scope: `TETRIS-SKILL-042`, Issue [#80](https://github.com/alsdmlals4-eng/Tetris/issues/80)
- Status: `OPEN_UNTIL_PHASE_2_IMPLEMENTATION_EVIDENCE`

## Incident

The current project promise has a category-resolved C1–C10 Skill system, but merged-main runtime/data remains a manual Tier 1–6 grid. Its old Haste/Battle Trance entries are correctly fail-closed as `REALTIME_MIGRATION_REQUIRED`; however, the project did not yet own a target-separated definition for player board time versus enemy pattern ETA. In addition, the catalog accepts `CONDITIONAL_MULTIPLIER` while the technique resolver skips it, so its authored C6 attack cannot honestly promise the displayed multiplier.

## Solution

`COMBO_STAGE_SKILL_CONTENT_GDD.md` now makes the user-approved semantics explicit: player acceleration/deceleration changes player board-play opportunity only; enemy acceleration/deceleration changes the visible current Telegraph ETA only. It forbids global engine time scale, preserves current-action-id binding and defers all runtime claims until a bounded Phase 2 controller/resolver/data/test contract exists. The unresolved multiplier is forbidden as a dependency for new Stage content until implemented or removed.

## Lesson

In a continuous realtime puzzle-combat game, words such as Haste and Slow are insufficient data. Every temporal effect needs a target, a time domain, a visible affected state, an unchanged comparison state, an action-binding rule and a pause rule before content balancing or UI preview can be trusted.

## Base promotion assessment

`NO_BASE_PROMOTION`: the lesson is useful but still tied to this project's dual-workspace Combo/Telegraph model and has no cross-project runtime evidence. Re-evaluate only after the Phase 2 implementation and Human evidence establish a reusable pattern.
