# Tetris · Project Workspace Index

- Status: `CURRENT REPOSITORY PROJECT HOME`
- Owner: GitHub repository documents, issue/PR history, and runtime evidence only.
- Purpose: preserve the useful project-home structure in a durable repository form without making an external workspace a future dependency.
- Current status and evidence ceiling: [`REPLANNING_FOUNDATION.md`](REPLANNING_FOUNDATION.md); the Master GDD below owns the preserved production baseline.
- One-time migration receipt: `docs/operations/TETRIS_CURRENT_WORKSPACE_MIGRATION_2026-08-28.json`

## 1. Start here

Current restart direction and next work: [`REPLANNING_FOUNDATION.md`](REPLANNING_FOUNDATION.md), `TETRIS-REPLAN-043`. The tables and detailed contracts below describe the preserved playable baseline unless explicitly marked as a new proposal. Existing images are references for replanning, not new visual locks. The linked PDF remains the baseline-derived edition, not the new proposal's blueprint.

Current-authority readback (2026-09-20, source main `69f4f591e038b4912d9761bf943aefd986170ace`): default `project.godot` still opens production briefing; standalone R2 scenes/code and automatic-cast implementation are also merged. R3 falling-pair/board-disruption work is in open Draft PRs [117](https://github.com/alsdmlals4-eng/Tetris/pull/117) / [118](https://github.com/alsdmlals4-eng/Tetris/pull/118), not merged-main evidence. Requery these states on the next task. Original R3 worktree and its local `project.godot` changes are outside this operating-rule task.

For R2 read [automatic-cast rules](REPLANNING_AUTOCAST_R2.md), [whole-game execution owner](../operations/TETRIS_R2_WHOLE_GAME.md), `src/replanned_r2/`, `scenes/replanned_r2/`, and their tests. Older implementation-deferred/CORE-029-only statements are dated history, not instructions to undo R2 or merge R3. Sections 2–5 below retain production/migration provenance; §6 owns operational adoption and §7 connects fun verification.

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

## 3. Preserved production handoff (not the R2/R3 rule owner)

`TETRIS-CORE-029` is the active playable slice: continuous realtime battle with a persistent `LINE ↔ CHAIN` workspace choice, live Telegraph/ETA, full tactical Skill pause, and explicit `CONFIRM`. `TETRIS-SKILL-039` is implemented as category-only/current-Combo preview, bounded 5-MP fallback and atomic confirm. The main entry is `scenes/production/battle_briefing.tscn`; it Deploys into `scenes/production/battle.tscn` and the battle keeps the same briefing as a reference popup.

`TETRIS-CHAIN-038` is implemented and machine-verified: diagonal CHAIN matching, the 1-MP failed-swap keep-or-revert lock, MP/Combo caps and per-wave CHAIN MP recovery are runtime behavior. `TETRIS-ONBOARDING-037` is also implemented and machine-verified: first-visit rules review, an actual 45-second ETA, a pre-first-CONFIRM nonterminal guard and same-encounter handoff. Human/player evidence for every surface remains `NOT_RUN`.

The following is the historical baseline implementation order (CHAIN, category-resolved Skill and onboarding are already present). Do not restart these as missing implementations; the current work order is in `REPLANNING_FOUNDATION.md` section 7:

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

## 6. Base operational adoption

Decision `TETRIS-OPS-LEAN-20260920`: user approved selective instruction slimming, route/CI correction and normal current-task PR delivery; subsequently requested Base #885 fun criteria too. Scope is workflow and evidence linkage, not game implementation. First-migration policy, release 9.4.4 identity/registry hashes, protected game contracts, engine/save/assets, plugins and global settings remain unchanged. The protected comparison baseline advances to this task's trusted main; old approvals remain in Git history, not a renewed game-change grant.

Machine owner: `skills/PROJECT_BASE_ADAPTER.json#shared_overrides.workflow_adoption`. Reviewed Base main: `23ecad5a3084f97c4e5d1e39a9a6d70d1eeb37ef`; [#883](https://github.com/alsdmlals4-eng/Base/pull/883) is merged and its slimming is included; [#885](https://github.com/alsdmlals4-eng/Base/pull/885) is also merged and now selectively adopted. This is a reproducibility record, not a permanent latest-main assumption. At each new task fetch/re-read main and relevant drift, then keep or explicitly revise the scoped adoption. No blanket Base release upgrade.

| Previous state / comparison | Decision and effect |
| --- | --- |
| Two-vs-five full reviews; fresh external research on every material edit | ADAPT #883: share two full review loops across the approved lineage; reuse valid evidence; investigate only new decision-relevant gaps. Independent merge review remains separate. |
| Old game rules duplicated in always-on AGENTS | Keep the original domain owners; route by actual production/R2/R3 consumer. Removes an instruction-driven rollback risk without deleting game history. |
| Whole latest-Base reinstall | REJECT: unnecessary lock/registry/product migration and future maintenance cost. |
| Text-only router edit | REJECT: Base generator overwrites it; cannot survive generation/check. |
| Existing Base validator + narrow local router projection | ADAPT: reuse full schema/release/registry/route/protected-path validation and upstream snapshot/dashboard bytes; substitute only the generated project router from its adapter-selected template. |
| New fun supervisor/report/server | REJECT: use existing R2 planning/playtest owners and §7; no new dependency, score or approval stage. |

Execution entry: `tools/check_workflow_adoption.py --help`. Use `python` and a **clean separate Base checkout** at the adopted source commit. Pass an externally verified project baseline and verified approval, as specified in `.agents/skills/tetris-workflow-router/SKILL.md`. `--check` is read-only; `--write` regenerates the same three existing outputs. Do not invoke the generic Base generator directly: its default v9.1 router template is deliberately replaced by the project projection. Base contract errors are never suppressed; generated snapshot/dashboard and router are all compared byte-for-byte. Base source checkout itself is not modified.

Legacy classification: AGENTS/index/foundation/adapter/router are `ACTIVE_OWNER`; first-policy and release identity are `COMPATIBILITY`; dated gameplay prose and old plans remain `ARCHIVE` provenance for their versions. No file is an approved deletion candidate here. Unread unrelated assets/worktrees remain `UNKNOWN_UNVERIFIED` and preserved.

Validation and closure: tooling suite, full approved Base contract, generated drift/repair tests, source/references and CI coverage, two contract-wide reviews and independent read-only retrieval/review; then exact-head CI/ruleset/readback. Product runtime/Human/art/release checks are `NOT_RUN` for this documentation/tooling-only change. No new reusable Base module is promoted; the project-specific generated-router mismatch is a future Base improvement candidate only. Rollback is a scoped Git revert of this operational change; no save migration or asset restoration is needed.

## 7. Fun verification — project binding, not a FUN_PASS

Adopted methods at the §6 source commit: [experience lifecycle](https://github.com/alsdmlals4-eng/Base/blob/23ecad5a3084f97c4e5d1e39a9a6d70d1eeb37ef/skills/analyzing-and-refining-game-concepts/references/concept-evidence-and-gates.md#fun-verification-lifecycle), [experience → effects/visual/UI](https://github.com/alsdmlals4-eng/Base/blob/23ecad5a3084f97c4e5d1e39a9a6d70d1eeb37ef/docs/knowledge/game-development/EXPERIENCE_TO_PRESENTATION_GUIDE.md), and [project-specific binding §10–11](https://github.com/alsdmlals4-eng/Base/blob/23ecad5a3084f97c4e5d1e39a9a6d70d1eeb37ef/skills/auditing-and-refining-ui-art/references/project-adapter-contract.md). Read only the affected part. Base references are not a new game-spec owner.

Project experience owner: [R2 rules §02–06](REPLANNING_AUTOCAST_R2.md) and current foundation. Hypothesis: preparing resources in LINE and selecting a category before CHAIN waves makes preparation, execution and reaction to a visible enemy deadline meaningfully connected. This is **HYPOTHESIS**, not evidence that players enjoy it. R3 pairs/disruption require their actual branch rules/consumers and later evidence; R2 swap-board results cannot establish R3 fun.

| Requirement / intended experience | Existing rule and actual main consumer | Failure/counterevidence and verification question |
| --- | --- | --- |
| FUN-R2-01 preparation matters (`AMPLIFY`, hypothesis) | R2 rules §04–06 → `src/replanned_r2/r2_session.gd`, `r2_line.gd`, `r2_chain.gd`; `tests/replanned_r2/test_r2_puzzles.gd`, `test_r2_combat.gd` | Machine: resource awards/cast costs match authoritative events, no duplicate reward. Runtime: displayed gain and cast correspond. Human: can the player explain why they return to LINE? CHAIN-only dominance or LINE perceived as chores is counterevidence, not an automatic rebalance instruction. |
| FUN-R2-02 pressure is legible (`SUPPORT`, hypothesis) | R2 rules §03–04 → session scheduling and `src/replanned_r2/r2_screen.gd`; `test_r2_combat.gd`, `test_r2_screen.gd` | Machine: pause/deadline/time-tile boundary. Runtime: Current/Next and shared action ETA agree; skill VFX must not hide danger. Human: can the player predict the next threat and explain the timer? Misreading it as a separate turn budget or missing warnings is counterevidence. |
| FUN-R2-03 my choice explains the skill (`AMPLIFY`, hypothesis) | R2 rules §06 and session category/automatic-cast result → `r2_screen.gd`, `r2_assets.gd`; existing combat/screen/asset tests | Specify selected/available/committed/result/interrupted states, category input and return focus, actual result event and icon slot. UI must not recalculate damage or spend resources on preview. Human: can the player connect a wave, chosen category and effect? Unclear causality or repeated cut-ins causing fatigue is counterevidence. |
| FUN-R2-04 retry suggests a new approach (`SUPPORT`, hypothesis) | `src/replanned_r2/r2_playtest_report.gd`, result screen; `tests/replanned_r2/test_r2_playtest_report.gd`; [existing observation procedure](../operations/TETRIS_R2_PLAYTEST_RECORDS.md#human-observation-procedure-prepared-not-performed) | Compare same build/rule hash/seed/settings; separate first exposure, coaching and repeat attempts. Ask what they would change and why. Longer play/retry count alone is not enjoyment; exports are diagnostics, not HUMAN PASS. |

Before a player-facing change, add **purpose → relevant states/expressions → actual consumer → machine/runtime/human question → counterevidence → next decision** to its existing owner. Effects distinguish authoritative gameplay result from presentation; document trigger, signal, actual timing/intensity, readable priority, interruption/reentry/cleanup and muted/reduced-motion alternatives where supported. Missing values must point to the current rule/data owner or be `HYPOTHESIS/PLANNED`, never invented from Base examples. Trace requirement → implementation/asset → evidence and back from evidence to its actual requirement.

Use the existing playtest procedure and reports; no new report per feature. Record exact build, scenario/seed, input, display/language/settings, observation and actual words, intervention and limitations. Classification: not noticed → visibility; seen but misunderstood → meaning; understood but uninteresting/tiring → choice/rhythm; broken on return/settings → state/lifetime. Apply the smallest evidence-backed KEEP/CHANGE/DEFER/RETEST decision within approval; core rule/UX/art changes still require a decision.

This adoption verifies **DOC/routing only**. Per-row new MACHINE/RUNTIME/HUMAN experiments: `NOT_RUN`; prior tests may be reused only after checking build/consumer equivalence. There is no universal fun score, forced sample size, automatic FUN_PASS or new runtime Director. Missing HUMAN results do not halt already-approved implementation, but cannot be reported as completed fun validation.
