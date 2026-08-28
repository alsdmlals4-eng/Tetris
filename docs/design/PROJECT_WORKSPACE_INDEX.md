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
| How do LINE, Combo and category-resolved Skill fit together? | [`COMBO_RESOLVED_SKILL_CONTRACT.md`](COMBO_RESOLVED_SKILL_CONTRACT.md), [`COMBO_STAGE_SKILL_CONTENT_GDD.md`](COMBO_STAGE_SKILL_CONTENT_GDD.md), [`CHAIN_COMBO_MP_CONTRACT.md`](CHAIN_COMBO_MP_CONTRACT.md) |
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

`TETRIS-CORE-029` is the active playable slice: continuous realtime battle with a persistent `LINE ↔ CHAIN` workspace choice, live Telegraph/ETA, full tactical Skill pause, and explicit `CONFIRM`. `TETRIS-SKILL-039` now defines the intended category-only / Combo-resolved Skill flow. The merged runtime entry is `scenes/production/battle.tscn`, but it is still a legacy manual Tier 1–6 implementation.

`TETRIS-CHAIN-038` and `TETRIS-ONBOARDING-037` are approved but only partially represented by the present runtime. Do not promote diagonal CHAIN matching, 1-MP failed-swap lock, MP/Combo caps and CHAIN MP recovery, or the BattleBriefing/embedded tutorial as implemented. Human/player evidence is `NOT_RUN`.

The current work order is:

1. Apply the user-approved C1–C10 content and target-separated time semantics from [`COMBO_STAGE_SKILL_CONTENT_GDD.md`](COMBO_STAGE_SKILL_CONTENT_GDD.md) only through its Phase 2 implementation contract. `TETRIS-VIS-BOARD-002` is already user-locked as a planning-only reference, not a runtime asset.
2. Produce one bounded Phase 2 implementation contract for CHAIN-038, SKILL-039/BALANCE-040/SKILL-042, VISUAL-041 runtime consumers and first-session handoff; no broad asset batch.
3. Implement the smallest verified sequence: deterministic CHAIN alignment → category-resolved Skill → briefing/rules/Deploy and safe live practice, reusing the same encounter.
4. Capture target-resolution and Human first-exposure evidence before expanding route, result, Codex, progression, assets or audio.

For live operational truth, read the latest completed `main`, all open/draft PRs as read-only parallel work, the relevant GitHub issue/PR, and the actual repository evidence. This index deliberately does not freeze transient PR, CI or runtime claims.

## 4. Visual and artifact continuity

- `TETRIS-VISUAL-041` owns the warm parchment / sepia ink / watercolor-violet-rift grammar in [`VISUAL_BIBLE.md`](VISUAL_BIBLE.md); `TETRIS-VISUAL-028` is superseded for global presentation language.
- `TETRIS-VIS-BOARD-002` is a `USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME`: it fixes the planning visual grammar and flow-review reference only. It is not a runtime asset, implementation, runtime render or Human/player UX PASS. `TETRIS-VIS-BOARD-001` is superseded.
- `TETRIS-SREF-001` through `TETRIS-SREF-005` are retained locally with hash, dimensions, source classification and named planned screen in `docs/assets/reference/planned/SCREEN_REFERENCE_MANIFEST.json`.
- Runtime asset candidates and their Godot consumers remain in the approved/production manifests and [`RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`](RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md).

## 5. Migration coverage

The prior external project workspace was read once, read-only, on 2026-08-28 to ensure its current structure and current artifacts had repository destinations. All project-local current pages found in that scan are accounted for in the migration receipt. Items already superseded or solely historical were not copied into current canon; their disposition is explicitly recorded rather than silently discarded.

Future project work must start from this index and the linked repository owners. Do not read, write, sync, or require the retired external workspace.
