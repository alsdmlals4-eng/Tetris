# Tetris · Project Workspace Index

- Status: `CURRENT REPOSITORY PROJECT HOME`
- Owner: GitHub repository documents, issue/PR history, and runtime evidence only.
- Purpose: preserve the useful project-home structure in a durable repository form without making an external workspace a future dependency.
- Current status and evidence ceiling: [`PROJECT_MASTER_GDD.md`](PROJECT_MASTER_GDD.md)
- One-time migration receipt: `docs/operations/TETRIS_CURRENT_WORKSPACE_MIGRATION_2026-08-28.json`

## 1. Start here

| I need to know… | Repository owner |
| --- | --- |
| What game are we making, what is approved, what conflicts, and what is next? | [`PROJECT_MASTER_GDD.md`](PROJECT_MASTER_GDD.md) |
| What is actually running now? | `scenes/production/battle.tscn`, `src/production/**`, `data/production/**`, tests, exact-head CI and runtime receipts |
| What are the active combat rules? | [`PRODUCTION_REALTIME_COMBAT_CANON.md`](PRODUCTION_REALTIME_COMBAT_CANON.md), [`CHAIN_COMBO_MP_CONTRACT.md`](CHAIN_COMBO_MP_CONTRACT.md) |
| How do LINE, Combo/Tier, and Skill fit together? | [`DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md`](DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md), [`VANGUARD_TACTICAL_SKILL_MATRIX.md`](VANGUARD_TACTICAL_SKILL_MATRIX.md) |
| What must the first session teach? | [`FIRST_SESSION_ONBOARDING_CONTRACT.md`](FIRST_SESSION_ONBOARDING_CONTRACT.md), [`FULL_GAME_SCREEN_SURFACE_INVENTORY.md`](FULL_GAME_SCREEN_SURFACE_INVENTORY.md) |
| What should the project look and feel like? | [`VISUAL_BIBLE.md`](VISUAL_BIBLE.md), planned/approved asset manifests |
| Which planned screens exist only as references? | `SCREEN_SURFACE_INVENTORY.json`, `FULL_GAME_SCREEN_SURFACE_INVENTORY.md`, `SCREEN_REFERENCE_MANIFEST.json` |
| What evidence is still required before experience claims? | `docs/validation/PRODUCTION_HUMAN_EVIDENCE_INDEX.json`, `docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md` |

## 2. Repository project structure

```text
00 Project Home                         → this index + Master GDD
01 Direction / design / combat data     → active canon, resource and skill contracts
02 Player flow / first session          → screen inventory + onboarding contract
03 Visual / UX / assets                 → Visual Bible + asset/reference manifests
04 Production / validation / handoff    → GitHub issue/PR history + runtime and Human evidence records
05 Reference / historical provenance    → explicitly non-current material; never a substitute for active canon
```

The folders are responsibility boundaries, not a claim that all planned screens, assets or systems are implemented. A planned reference, a runtime-bound source candidate, a runtime render and Human/player evidence remain distinct classes.

## 3. Current handoff

`TETRIS-CORE-029` is the active playable slice: continuous realtime battle with a persistent `LINE ↔ CHAIN` workspace choice, live Telegraph/ETA, full tactical Skill pause, and explicit `USE`. The merged runtime entry is `scenes/production/battle.tscn`.

`TETRIS-CHAIN-038` and `TETRIS-ONBOARDING-037` are approved but only partially represented by the present runtime. Do not promote diagonal CHAIN matching, 1-MP failed-swap lock, MP/Combo caps and CHAIN MP recovery, or the BattleBriefing/embedded tutorial as implemented. Human/player evidence is `NOT_RUN`.

The current work order is:

1. Capture Human first-exposure evidence for the existing runtime and resolve the highest-risk comprehension findings.
2. Complete the Phase 2 review before implementing the approved CHAIN and first-session gaps.
3. Implement the smallest first-session boundary (briefing/rules/Deploy, then safe live practice) while reusing the same encounter.
4. Expand route, result, Codex, progression, assets or audio only after the representative experience has evidence.

For live operational truth, read the latest completed `main`, all open/draft PRs as read-only parallel work, the relevant GitHub issue/PR, and the actual repository evidence. This index deliberately does not freeze transient PR, CI or runtime claims.

## 4. Visual and artifact continuity

- `TETRIS-VISUAL-028` owns the hand-drawn mystic fantasy plus clean puzzle-UI grammar in [`VISUAL_BIBLE.md`](VISUAL_BIBLE.md).
- `TETRIS-VIS-BOARD-001` is a generated planning exploration, awaiting only a user lock decision; it is not a runtime asset or implementation.
- `TETRIS-SREF-001` through `TETRIS-SREF-005` are retained locally with hash, dimensions, source classification and named planned screen in `docs/assets/reference/planned/SCREEN_REFERENCE_MANIFEST.json`.
- Runtime asset candidates and their Godot consumers remain in the approved/production manifests and [`RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`](RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md).

## 5. Migration coverage

The prior external project workspace was read once, read-only, on 2026-08-28 to ensure its current structure and current artifacts had repository destinations. All project-local current pages found in that scan are accounted for in the migration receipt. Items already superseded or solely historical were not copied into current canon; their disposition is explicitly recorded rather than silently discarded.

Future project work must start from this index and the linked repository owners. Do not read, write, sync, or require the retired external workspace.
