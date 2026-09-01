# Tetris project work rules

## Canon

Read current production gameplay in this order:

1. `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md` — current combat lifecycle / continuous realtime / LINE↔CHAIN workspace switching / tactical pause / enemy scheduling / 60:40 battle composition authority (`TETRIS-CORE-029`).
2. `docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md` — current `ATK / DEF / SUP` category-only, Combo-Resolved preview/explicit CONFIRM and bounded 5-MP fallback authority (`TETRIS-SKILL-039` / `TETRIS-BALANCE-040`).
3. `docs/design/CHAIN_COMBO_MP_CONTRACT.md` — current straight-3+ diagonal CHAIN grammar, optional MP lock, Combo recovery and preserved opportunity cost (`TETRIS-CHAIN-038`); its Phase 2 implementation review is still required.
5. `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md` — production images must have an actual Godot runtime consumer (`TETRIS-IMAGE-030`).
6. `docs/design/PROJECT_WORKSPACE_INDEX.md`, `PROJECT_MASTER_GDD.md`, and `VISUAL_BIBLE.md` — repository-owned project-home structure, current picture, and visual direction.
7. Latest USER_APPROVED project Decisions recorded in GitHub issues, pull requests, and repository canon documents.
8. `docs/superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md` — current implementation plan, subject to the `TETRIS-CHAIN-038` Phase 2 review gate.
9. Actual code/data/scenes/tests/exact-head CI/runtime/Human evidence.

Machine-readable routing authority: `docs/design/PRODUCTION_CANON_INDEX.json`.

`docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md` (`TETRIS-SKILL-026`) and `docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md` (`TETRIS-BALANCE-027`) remain historical provenance for manual Tier 1–6 choice/cost grammar and selected effect-purpose ideas. Preserve their bodies; do not use them as current Skill selection authority. `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` (`TETRIS-CORE-024`) and `docs/design/PRODUCTION_TURN_TIME_CANON.md` (`TETRIS-TIME-025`) remain historical provenance where they define ordered turns, Shared Player Turn Budget, READY, timeout/PASS, or Tempo.

## TETRIS_FORMAL_BASE_ADAPTER_BOOTSTRAP

- `docs/operations/TETRIS_FIRST_PROJECT_ADAPTER_POLICY.json` is the project-owned first-migration policy source for the formal Base adapter route. It must be read at its exact merged `origin/main` commit before the adapter is installed.
- `skills/PROJECT_BASE_ADAPTER.json` is the only future canonical adapter path. It is `NOT_INSTALLED` at this policy-source commit; no task may create the adapter and claim this same feature branch as its trusted protected baseline.
- The subsequent adapter-install PR must use the merged policy commit as `protected_baseline.commit`, read `/protected_paths`, and preserve every listed path. It must not copy Base Skill bodies into this project.

## DOMAIN_SPLIT_CANON

- `REPOSITORY_HUMAN_FACING_CANON`: `PROJECT_MASTER_GDD.md`, `VISUAL_BIBLE.md`, Flow/Storyboard, visual/reference manifests, and player-facing tables.
- `REPOSITORY_STRUCTURED_CANON`: machine index, production canon, data/code/scenes/resources/config/tests.
- `REPOSITORY_RUNTIME_TRUTH`: actual Godot build/runtime/test/log/screenshot-video evidence.
- `REPOSITORY_ONLY_CURRENT_OWNER`: GitHub repository documents, GitHub issue/PR history, and runtime evidence are the only current owners. Do not read, write, sync, or require Notion for current project work.
- Historical Sheets and Notion content are external provenance only, not a default workspace or runtime authority.

Never promote a historical external mockup, generated image, branch implementation, automated test, or historical receipt beyond its actual evidence class.

## Historical Core Foundation

Preserve these as Engineering Harness evidence:

- `docs/design/CORE_GAMEPLAY_GDD.md`
- `docs/design/POC_RULESET_V0_1.md`
- `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- `docs/validation/POC_45S_VALIDATION.md`
- merged PR #3 implementation/tests.

They do not override CORE-029.

## Runtime and testing

- Runtime: Godot 4.x + GDScript.
- Remote CI pin: Godot `4.7.1-stable`, GUT `9.7.1`.
- User-local Windows runtime is a separate evidence class. Never claim it passed without a live receipt.
- Persistent Godot authoring follows Base HiGodot single-authority policy.
- Deterministic behavior changes use test-first RED → GREEN → regression verification.
- Unexpected failures use systematic debugging before proposing fixes.
- Foundation tests and CORE-029 Production tests remain distinguishable.

## MANDATORY_CURRENT_TASK_EVIDENCE_GATE

For every material Tetris task (L1+ planning, system, UI/UX, asset, workflow, data or Godot implementation change), complete and record this gate before claiming that the next action is safe:

1. `FRESH_SOURCE_AND_IMPLEMENTATION_READ`: read the latest completed `main`, every open/draft PR as read-only parallel work, current detailed canon, approved Decisions, and the affected actual code, data, Scene, Resource, asset, test, CI/runtime and Human evidence.
2. `TARGETED_CURRENT_INTERNET_RESEARCH`: perform fresh, decision-relevant Internet research from the appropriate current primary/official source (Godot, platform, policy, dependency or rights owner) before a material decision or implementation. External research informs feasibility; it never replaces project canon or runtime truth.
3. `PREIMPLEMENTATION_FEASIBILITY_CLASSIFICATION`: record `FEASIBLE`, `PARTIAL`, or `BLOCKED_UNVERIFIED` with affected consumers, data/Scene/code boundaries, dependencies, compatibility/performance risk, rollback boundary and evidence ceiling. A planning document or automated test alone never proves runtime or player value.
4. `FIVE_FULL_ADVERSARIAL_LOOPS_MINIMUM`: run five complete current-state attack/recheck loops covering canon drift, actual implementation/data contradiction, user-flow failure, visual/consumer evidence confusion, and validation/merge evidence. Correct each material finding before progressing, or keep it explicitly blocked.
5. `EXACT_DESTINATION_AND_HEAD_READBACK`: after a permitted write, reread its exact destination; before a completion/merge claim, test the exact head and read back the remote result.

`MECHANICAL_NO_EXTERNAL_DEPENDENCY` is permitted only for a purely mechanical non-product change where external information cannot alter the result; record the scope and reason instead of pretending Internet research occurred. This exception never applies to new gameplay, player-facing UX, runtime asset, dependency, platform, security, rights or implementation-direction work.

## Current CORE-029 gameplay invariants

- Combat runs from `BATTLE_START` until `VICTORY` or `DEFEAT` on one continuous combat timeline.
- There is no alternating player turn/enemy turn loop and no Shared Player Turn Budget.
- The left battle region is one large Puzzle Surface. It displays either LINE or CHAIN, never two mandatory full boards simultaneously.
- Player may request `LINE ↔ CHAIN` freely during `COMBAT_RUNNING`.
- LINE and CHAIN are independent persistent workspaces. Switching does not rebuild/reroll/reset the inactive workspace.
- Inactive workspace does not simulate except completion of an already-committed deterministic safe-switch boundary.
- LINE remains the primary MP source (current internal field: `energy`).
- CHAIN uses orthogonal swaps and straight horizontal/vertical/both-diagonal 3+ matches; every resolved wave adds Combo +1 and then recovers MP from `(sum maximal qualified line lengths − 3) + post-wave Combo`. Combo is the shared Tier/CHAIN-MP resource (current internal field: `stock`).
- A no-match restores by default and resets Combo; fixed **1 MP** may keep that swapped board for later setup, but also resets Combo and grants no immediate clear, Combo, or CHAIN MP recovery.
- Combo cap is **10**. Selecting a Skill category resolves the current Combo Stage; when current-stage MP is insufficient, surplus Combo converts at **5 MP each** only to reach the highest feasible lower Stage. This intentionally lowers later CHAIN MP recovery. Current merged runtime remains legacy cap-6/no-CHAIN-MP/manual-Tier-1–6 until Phase 2 implementation.
- Enemy Current Telegraph + ETA continues while the player solves LINE/CHAIN.
- Visible Next Forecast remains lower priority than Current.
- Opening SKILL enters `TACTICAL_PAUSE_SKILL` and fully stops combat simulation.
- During tactical pause: enemy ETA/resolution, puzzle simulation, status ticks, real-time cooldowns, simulation VFX/animation/audio progression stop. Only Skill/UI navigation/confirm/cancel remains active.
- Skill flow is `ATK / DEF / SUP → one current-Combo-resolved preview → explicit CONFIRM`.
- Selecting a category never spends resources. Only CONFIRM commits; the pre-confirm preview must state any 5-MP-per-Combo fallback.
- Cancel or successful USE resumes the exact paused combat time and restores the previously active puzzle workspace unchanged by reading the Skill UI.
- Manual Pause is also full simulation pause but remains a distinct state/reason.
- Same-frame Skill-open vs enemy deadline uses an explicit scheduler commit point. Skill-open may freeze an uncommitted action; it cannot retroactively cancel a committed one.
- Haste, Battle Trance, turn-only status durations, and Tempo scaling are `REALTIME_MIGRATION_REQUIRED`; do not silently translate them into seconds.
- Score remains performance evidence, not a Skill currency.

## UI / UX invariants

- Target desktop composition: approximately `60% large Puzzle Surface / 40% persistent Combat-Threat-Resource-Skill surface`.
- The ratio is a readability target, not a fixed pixel law.
- Right-side surface keeps enemy HP/phase, Current Telegraph + ETA, lower-priority Next Forecast when known, player HP/MP/Combo, and LINE/CHAIN/SKILL controls readable.
- Skill-open state visibly communicates tactical pause while retaining frozen puzzle/threat context and a category-resolved preview.
- Do not show ordered `LINE → CHAIN → ACTION → ENEMY` stage rails, Shared Turn Timer, READY, turn timeout/PASS, Tempo UI, manual Tier buttons or an unconfirmed skill auto-cast as current production behavior.
- Puzzle/HUD readability outranks decorative character, environment, and VFX detail.

## Image production contract

Production image work follows `TETRIS-IMAGE-030`.

Before generating any production image, require:

- exact `res://` target path;
- exact consumer scene;
- exact consumer node/material/UI slot;
- required size/aspect;
- alpha/crop/anchor rules;
- import/use mode.

No consumer = no production generation.

Concept sheets, master sheets, pose explanation sheets, combined UI sheets, and mock screenshots are reference-only unless the runtime directly consumes that exact file. Atlas/sprite sheets are allowed only when the runtime consumes the exact atlas with a defined region/frame contract.

Planning visualizations may be generated first under `AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION`; ask the user only whether to lock the inspected result. A planning visualization remains `GENERATED_EXPLORATION`, not a runtime asset. Runtime image generation still requires the relevant CORE-029 exact Godot consumer, target path and geometry/import contract before generation; user lock plus runtime evidence are required before promotion.

## Human evidence

Human validation authority: `docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md`.

- status remains `NOT_RUN` until real first-exposure receipts exist;
- positive directional PASS requires three valid independent A/B/C first-exposure receipts;
- automated tests cannot prove fun, readability, onboarding, choice quality, or final balance;
- concept/reference art cannot substitute for runtime-rendered UI evidence;
- telemetry distinguishes wall-clock, active combat simulation time, tactical-pause duration, and manual-pause duration where available.

## Production implementation isolation

- Current implementation plan: `docs/superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md`.
- Keep implementation isolated from `main` until exact-head verification and approval.
- Draft PR #19 ordered-turn workstream remains read-only. Its pinned head may be used only as a source snapshot for explicitly selected reusable files.
- Do not merge/cherry-pick PR #19 wholesale.
- New CORE-029 runtime must own continuous combat and pause directly rather than wrapping the old TurnController as permanent architecture.

## Cost and change safety

- No new paid dependency, API, runner class, SaaS, marketplace credit, GPU/larger runner, or separately metered service without explicit approval.
- Do not overwrite unrelated user changes.
- Live open/draft/ready PRs are read-only unless the current user instruction explicitly authorizes the exact target/action.
- Query live PR state at work start; historical PR numbers are provenance, not permanent assumptions.
- Before completion compare the work branch against `main` and report verified, unverified, and remaining-risk states separately.
