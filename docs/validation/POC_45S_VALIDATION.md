# Core POC 45-Second Validation Ledger

- Date opened: 2026-08-19
- Automated evidence updated: 2026-08-19
- Scope: Core dual-board combat POC only
- Canon: `docs/design/CORE_GAMEPLAY_GDD.md`, `docs/design/POC_RULESET_V0_1.md`
- Plan: `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- Canonical validation pins: Godot `4.7.1-stable` + GUT `9.7.1`
- CI checkout action: `actions/checkout@v7`
- Windows user entry point: repository-root `RUN_LOCAL_VALIDATION.cmd` (double-click; no manual PowerShell command is required)
- User Windows-local Godot/GUT execution: **NOT_RUN / UNVERIFIED**
- Human-operated continuous 45-second encounter: **NOT_RUN**
- Chat execution container: no authorized interactive connection to the user's Windows desktop; therefore it is not accepted as user-local or human-play evidence.
- Latest pre-handoff automated evidence: GitHub Actions `core-poc-ci` run `32266365328`, implementation head `8a8d3374a58a7a8f03d0a1332fd4449b234d03e4`.
- Linux Godot job: `96111857702` — import/parse PASS, full GUT PASS.
- Windows validator smoke job: `96111857573` — isolated Windows clone/import/GUT path PASS and validated the same implementation head.
- Automated suite observed on both Linux and Windows: **50/50 tests PASS, 355 assertions**.
- Plan completion gate: **OPEN** — exact user-local execution plus one human-operated continuous 45-second encounter are still required.

## Evidence status

| Check | Status | Evidence |
|---|---|---|
| Godot/GUT Linux REMOTE_CI preflight | PASS | Godot 4.7.1 + GUT 9.7.1 pins verified in job `96111857702`. |
| Linux Godot import/parse | PASS | Headless import/parse completed without a parse/load failure. |
| Linux full GUT suite | PASS | 50/50 tests, 355 assertions, strict GUT log guard PASS. |
| Windows local-validator smoke | PASS | Windows Server 2025 job `96111857573` invoked root `RUN_LOCAL_VALIDATION.cmd --ci`, created a fresh isolated clone, installed pinned Godot/GUT, passed import and the complete GUT suite. |
| Windows smoke commit identity | PASS | Validator fresh clone reported commit `8a8d3374a58a7a8f03d0a1332fd4449b234d03e4`, equal to the workflow head. |
| inactive mode freeze | PASS | Integration tests and automated 45s scenario preserve inactive source state. |
| LOCK freeze | PASS | Active puzzle source advance count remains unchanged while LOCKED. |
| Combat Clock during LOCK | PASS | Combat time advances and enemy action fires while puzzle source is LOCKED. |
| mode destination requires explicit RUN | PASS | Scene/domain tests confirm switched destination remains LOCKED until explicit RUN. |
| Line event -> Energy | PASS | Double produces exactly +22 when isolated from emergency Energy timing. |
| completed Chain -> non-additive Stock | PASS | Repeated low Chains do not add; Stock caps at 5. |
| Skill -> Energy + Stock consumption | PASS | Tests confirm configured Energy cost + exact Tier Stock consumption. |
| insufficient-resource Skill -> no mutation | PASS | Rejected high-tier Skill preserves Energy, Stock, and target HP. |
| Skill blocked during RESOLVING | PASS | Integration test confirms no resource/effect mutation; UI disables Skill buttons. |
| queued mode switch truthfulness | PASS | Request during RESOLVING logs queue first; actual switch logs only after resolution finishes. |
| enemy schedule visible and fires on time | PASS | HUD exposes next action; deterministic actions resolve at 12/24/36s. |
| enemy telemetry scheduled timestamps | PASS | Coarse tick still records enemy actions at scheduled timestamps rather than the end-of-tick time. |
| enemy telemetry state context | PASS | Enemy events record active mode and board state, allowing LOCK-during-enemy-action evidence to be audited. |
| mode-state UI honesty | PASS | LINE/CHAIN buttons expose LOCKED/RUNNING/SUSPENDED state explicitly. |
| manual-validation tracker false-PASS guard | PASS | Incomplete or out-of-order validation cannot write PASS evidence; all 10 ordered steps and >=45 seconds are required. |
| manual-validation UI contract | PASS | Validation controls are hidden normally and expose ordered `NEXT` guidance only in validation mode. |
| automated continuous 45-second encounter | PASS | Deterministic integration test reaches 45.0s in one session and verifies required state/resource transitions. |
| exact user-local Godot/GUT execution | NOT_RUN | Windows CI proves the validator path works on Windows, but it is not the user's own PC. **Completion blocker.** |
| human-operated continuous 45-second encounter | NOT_RUN | CI smoke intentionally skips interactive play. **Completion blocker.** |

## Windows user-local validation handoff

No manual terminal or PowerShell command is required.

1. On the user's Windows PC, obtain the repository/branch containing PR #3 (`impl/core-dual-board-poc`).
2. In the repository root, double-click `RUN_LOCAL_VALIDATION.cmd`.
3. The validator creates an isolated sandbox under `%LOCALAPPDATA%\TetrisCorePocValidation` and does not modify the user's existing Godot installation, projects, or settings.
4. It fresh-clones the validation branch, downloads pinned Godot 4.7.1 and GUT 9.7.1 into the sandbox, then runs Windows import/parse and the complete GUT suite.
5. If preflight passes, the POC window opens automatically in manual-validation mode.
6. Follow the on-screen `NEXT:` instruction in order. Do not close the POC until it shows `PASS | EVIDENCE SAVED`.
7. The contract requires all 10 ordered actions plus at least 45 continuous seconds.
8. On success, evidence remains under `%LOCALAPPDATA%\TetrisCorePocValidation`:
   - `local_preflight.json`
   - `manual_validation_report.json`
   - `local_validation_evidence.json`
9. Return `local_validation_evidence.json` (ideally all three files) for final verification. Do not mark these user-local gates PASS from CI evidence alone.

Rollback is deletion of `%LOCALAPPDATA%\TetrisCorePocValidation`; the validator is intentionally isolated from the user's normal Godot environment.

## Manual 45-second ordered contract

The manual validation tracker requires these observations in order:

1. Start/explicitly RUN Line.
2. Produce a Line Energy event.
3. LOCK Line while Combat Clock remains live.
4. Switch Line -> Chain and observe Chain arriving LOCKED.
5. Explicitly RUN Chain.
6. Complete a Chain event.
7. Use one successful Skill.
8. Attempt one intentionally rejected/insufficient Skill and preserve resources.
9. Allow an enemy action while the puzzle is LOCKED.
10. Return to Line and confirm its saved puzzle-source progress did not advance while inactive.

The report is not writable as PASS until the 10 ordered steps are complete and elapsed time is at least 45 seconds.

## Automated 45-second encounter

The automated integration test remains deterministic implementation evidence, not human-play evidence. It verifies the same core state/resource sequence, including Line Energy, Chain Stock, successful/rejected Skill behavior, LOCK/inactive freeze, enemy timing, mode return, and 45-second continuity.

## Five implementation adversarial review loops

The Core POC was re-attacked after tests were green. Verified fixes were added with regression tests.

1. **Economy:** removed emergency Energy fractional-time banking across Line gain / Skill spend transitions.
2. **State truth:** blocked Skill use during `RESOLVING`; distinguished queued mode-switch telemetry from an actual switch.
3. **Timing evidence:** enemy telemetry records scheduled 12/24/36-second timestamps even when simulation ticks are coarse, and now captures active mode/board state for auditable LOCK evidence.
4. **UI honesty:** mode buttons expose LOCKED/RUNNING/SUSPENDED; Skill controls disable during RESOLVING; manual validation uses ordered on-screen guidance rather than hidden assumptions.
5. **Governance/validation:** Linux strict GUT guard, isolated Windows validator smoke, pinned Windows console/GUI Godot paths, exact commit evidence, and a single root double-click entry point prevent duplicate/ambiguous validation routes.

No automated result substitutes for the two remaining empirical gates: the user's actual Windows execution and the user's actual 45-second interaction.

## Completion verdicts

Observed evidence at this ledger update:

- Linux Godot import/parse: PASS
- Linux full GUT suite: PASS (50/50, 355 assertions)
- Windows isolated validator smoke: PASS (50/50, 355 assertions)
- Windows smoke validated exact workflow head: PASS
- inactive mode freeze: PASS
- LOCK freeze: PASS
- Combat Clock during LOCK: PASS
- mode destination requires explicit RUN: PASS
- Line event -> Energy: PASS
- completed Chain -> non-additive Stock: PASS
- Skill -> Energy + Stock consumption: PASS
- insufficient-resource Skill -> no mutation: PASS
- Skill blocked during RESOLVING: PASS
- queued switch telemetry correctness: PASS
- enemy schedule visible/fires on time: PASS
- enemy telemetry scheduled time + mode/state context: PASS
- mode state shown in UI: PASS
- manual-validation false-PASS guard: PASS
- automated continuous 45-second scenario: PASS
- exact user-local Godot/GUT execution: NOT_RUN
- human-operated continuous 45-second encounter: NOT_RUN
- overall approved-plan completion: **OPEN / NOT COMPLETE**

## Explicitly NOT_RUN production scope

These remain outside the Core POC and must not be reported as finished:

- production Line falling-piece controls and rotation/kicks
- production Chain pair controls and gravity feel
- true Line-vs-Chain difficulty balance
- advanced Combo/B2B/Spin/Perfect Clear combat bonuses
- All Clear bonus design
- final top-out recovery
- class roster balance
- external tester validation
- production visual/UI polish and final art
