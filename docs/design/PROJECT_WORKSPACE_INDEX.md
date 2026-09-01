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
| Can I read the current human blueprint? | [`TETRIS_HUMAN_GAME_BLUEPRINT.pdf`](../blueprints/TETRIS_HUMAN_GAME_BLUEPRINT.pdf) — derived from the current repository owners; its manifest records exact inputs and evidence limits. |
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

`TETRIS-CORE-029` is the active playable slice: continuous realtime battle with a persistent `LINE ↔ CHAIN` workspace choice, live Telegraph/ETA, full tactical Skill pause, and explicit `CONFIRM`. `TETRIS-SKILL-039` is implemented as category-only/current-Combo preview, bounded 5-MP fallback and atomic confirm. The main entry is `scenes/production/battle_briefing.tscn`; it Deploys into `scenes/production/battle.tscn` and the battle keeps the same briefing as a reference popup.

`TETRIS-CHAIN-038` is implemented and machine-verified: diagonal CHAIN matching, the 1-MP failed-swap keep-or-revert lock, MP/Combo caps and per-wave CHAIN MP recovery are runtime behavior. `TETRIS-ONBOARDING-037` is also implemented and machine-verified: first-visit rules review, an actual 45-second ETA, a pre-first-CONFIRM nonterminal guard and same-encounter handoff. Human/player evidence for every surface remains `NOT_RUN`.

The current work order is:

1. Apply the user-approved Phase 2 contract: [`2026-08-29-phase2-tactical-core-alignment.md`](../superpowers/plans/2026-08-29-phase2-tactical-core-alignment.md) locks the C1–C10 content, target-separated time semantics and the capped stored board-opportunity reserve. `TETRIS-VIS-BOARD-002` remains a planning-only reference, not a runtime asset.
2. Implement the smallest verified sequence: deterministic CHAIN alignment → category-resolved Skill and target-separated timing → briefing/rules/Deploy and safe live practice, reusing the same encounter.
3. Capture target-resolution and Human first-exposure evidence before expanding route, result, Codex, progression, assets or audio.

For live operational truth, read the latest completed `main`, all open/draft PRs as read-only parallel work, the relevant GitHub issue/PR, and the actual repository evidence. This index deliberately does not freeze transient PR, CI or runtime claims.

## 4. Visual and artifact continuity

- `TETRIS-VISUAL-041` owns the warm parchment / sepia ink / watercolor-violet-rift grammar in [`VISUAL_BIBLE.md`](VISUAL_BIBLE.md); `TETRIS-VISUAL-028` is superseded for global presentation language.
- `TETRIS-VIS-BOARD-002` is a `USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME`: it fixes the planning visual grammar and flow-review reference only. It is not a runtime asset, implementation, runtime render or Human/player UX PASS. `TETRIS-VIS-BOARD-001` is superseded.
- `TETRIS-SREF-001` through `TETRIS-SREF-005` are retained locally with hash, dimensions, source classification and named planned screen in `docs/assets/reference/planned/SCREEN_REFERENCE_MANIFEST.json`.
- Runtime asset candidates and their Godot consumers remain in the approved/production manifests and [`RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`](RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md).

## 5. Migration coverage

The prior external project workspace was read once, read-only, on 2026-08-28 to ensure its current structure and current artifacts had repository destinations. All project-local current pages found in that scan are accounted for in the migration receipt. Items already superseded or solely historical were not copied into current canon; their disposition is explicitly recorded rather than silently discarded.

Future project work must start from this index and the linked repository owners. Do not read, write, sync, or require the retired external workspace.
