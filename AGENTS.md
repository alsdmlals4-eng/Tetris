# Tetris project work rules

## Canon

Read current production gameplay in this order:

1. `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md` — current combat lifecycle / continuous realtime / LINE↔CHAIN workspace switching / tactical pause / enemy scheduling / 60:40 battle composition authority (`TETRIS-CORE-029`).
2. `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md` — retained Vanguard `ATK / DEF / SUP × Tier 1–6` Technique identity and tactical commitment authority where not turn-bound (`TETRIS-SKILL-026`).
3. `docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md` — retained Line MP / Chain Combo opportunity cost and Tier commitment structure (`TETRIS-BALANCE-027`).
4. `docs/design/CHAIN_COMBO_MP_CONTRACT.md` — current straight-3+ diagonal CHAIN grammar and optional MP lock (`TETRIS-CHAIN-038`); its Phase 2 implementation review is still required.
5. `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md` — production images must have an actual Godot runtime consumer (`TETRIS-IMAGE-030`).
6. Latest USER_APPROVED project Decisions and synced Notion owner pages.
7. `docs/superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md` — current implementation plan, subject to the `TETRIS-CHAIN-038` Phase 2 review gate.
8. Actual code/data/scenes/tests/exact-head CI/runtime/Human evidence.

Machine-readable routing authority: `docs/design/PRODUCTION_CANON_INDEX.json`.

`docs/design/PRODUCTION_TURN_COMBAT_CANON.md` (`TETRIS-CORE-024`) and `docs/design/PRODUCTION_TURN_TIME_CANON.md` (`TETRIS-TIME-025`) remain historical provenance where they define ordered turns, Shared Player Turn Budget, READY, timeout/PASS, or Tempo. Preserve their bodies; do not use them as current gameplay authority.

## DOMAIN_SPLIT_CANON

- `NOTION_HUMAN_FACING_CANON`: readable current project picture, Flow/Storyboard, visual/reference surface, player-facing tables.
- `REPOSITORY_STRUCTURED_CANON`: machine index, production canon, data/code/scenes/resources/config/tests.
- `REPOSITORY_RUNTIME_TRUTH`: actual Godot build/runtime/test/log/screenshot-video evidence.
- Historical Sheets content is migration-only compatibility material, not a default workspace or runtime authority.

Never promote a Notion mockup, generated image, branch implementation, automated test, or historical receipt beyond its actual evidence class.

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

## Current CORE-029 gameplay invariants

- Combat runs from `BATTLE_START` until `VICTORY` or `DEFEAT` on one continuous combat timeline.
- There is no alternating player turn/enemy turn loop and no Shared Player Turn Budget.
- The left battle region is one large Puzzle Surface. It displays either LINE or CHAIN, never two mandatory full boards simultaneously.
- Player may request `LINE ↔ CHAIN` freely during `COMBAT_RUNNING`.
- LINE and CHAIN are independent persistent workspaces. Switching does not rebuild/reroll/reset the inactive workspace.
- Inactive workspace does not simulate except completion of an already-committed deterministic safe-switch boundary.
- LINE remains the primary MP source (current internal field: `energy`).
- CHAIN uses orthogonal swaps and straight horizontal/vertical/both-diagonal 3+ matches; it remains the primary Combo/Tier opportunity source (current internal field: `stock`).
- A no-match restores by default; optional MP may keep that swapped board for later Combo setup without immediate clear or Combo. MP lock cost is `TUNE_REQUIRED`.
- Combo cap baseline is 6. Tier N spends Combo N under retained BALANCE-027 structure.
- Enemy Current Telegraph + ETA continues while the player solves LINE/CHAIN.
- Visible Next Forecast remains lower priority than Current.
- Opening SKILL enters `TACTICAL_PAUSE_SKILL` and fully stops combat simulation.
- During tactical pause: enemy ETA/resolution, puzzle simulation, status ticks, real-time cooldowns, simulation VFX/animation/audio progression stop. Only Skill/UI navigation/confirm/cancel remains active.
- Skill flow is `ATK / DEF / SUP → selected lane T1–T6 → detail → explicit USE`.
- Selecting a Technique row never spends resources. Only USE commits.
- Cancel or successful USE resumes the exact paused combat time and restores the previously active puzzle workspace unchanged by reading the Skill UI.
- Manual Pause is also full simulation pause but remains a distinct state/reason.
- Same-frame Skill-open vs enemy deadline uses an explicit scheduler commit point. Skill-open may freeze an uncommitted action; it cannot retroactively cancel a committed one.
- Haste, Battle Trance, turn-only status durations, and Tempo scaling are `REALTIME_MIGRATION_REQUIRED`; do not silently translate them into seconds.
- Score remains performance evidence, not a Skill currency.

## UI / UX invariants

- Target desktop composition: approximately `60% large Puzzle Surface / 40% persistent Combat-Threat-Resource-Skill surface`.
- The ratio is a readability target, not a fixed pixel law.
- Right-side surface keeps enemy HP/phase, Current Telegraph + ETA, lower-priority Next Forecast when known, player HP/MP/Combo, and LINE/CHAIN/SKILL controls readable.
- Skill-open state visibly communicates tactical pause while retaining frozen puzzle/threat context.
- Do not show ordered `LINE → CHAIN → ACTION → ENEMY` stage rails, Shared Turn Timer, READY, turn timeout/PASS, or Tempo UI as current production behavior.
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

Current image generation remains paused until the relevant CORE-029 runtime consumer exists. One explicit image approval produces exactly one image result, then stops for review.

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
