# Core POC 45-Second Validation Ledger

- Date opened: 2026-08-19
- Scope: Core dual-board combat POC only
- Canon: `docs/design/CORE_GAMEPLAY_GDD.md`, `docs/design/POC_RULESET_V0_1.md`
- Plan: `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- Canonical REMOTE_CI target: Godot `4.7.1-stable` + GUT `9.7.1`
- User Windows-local Godot version: **UNVERIFIED**
- Chat execution container: Git available; Godot not installed; therefore not accepted as local Godot evidence.

## Evidence status

| Check | Status | Evidence |
|---|---|---|
| Godot/GUT REMOTE_CI preflight | NOT_RUN | Workflow added with pinned official versions; no completed run yet. |
| Godot import/parse | NOT_RUN | No engine run yet. |
| GUT unit suite | NOT_RUN | No test run yet. |
| GUT integration suite | NOT_RUN | No test run yet. |
| inactive mode freeze | NOT_RUN | No implementation/run yet. |
| LOCK freeze | NOT_RUN | No implementation/run yet. |
| Combat Clock during LOCK | NOT_RUN | No implementation/run yet. |
| mode destination requires explicit RUN | NOT_RUN | No implementation/run yet. |
| Line event -> Energy | NOT_RUN | No implementation/run yet. |
| completed Chain -> non-additive Stock | NOT_RUN | No implementation/run yet. |
| Skill -> Energy + Stock consumption | NOT_RUN | No implementation/run yet. |
| insufficient-resource Skill -> no mutation | NOT_RUN | No implementation/run yet. |
| enemy schedule visible and fires on time | NOT_RUN | No implementation/run yet. |
| telemetry contains performed transitions | NOT_RUN | No implementation/run yet. |
| continuous 45-second encounter | NOT_RUN | Requires runnable POC. |

## Required 45-second encounter steps

1. Start Line in `LOCKED`.
2. `RUN` Line and create at least one Energy event.
3. `LOCK` Line while Combat Clock continues.
4. Switch Line -> Chain and confirm Chain lands `LOCKED`.
5. Explicitly `RUN` Chain and complete at least one Chain event.
6. Use one successful Skill.
7. Attempt one Skill lacking Energy or Stock and confirm no resource mutation.
8. Allow at least one enemy action while active puzzle source is `LOCKED`.
9. Switch back to Line and confirm its saved state did not advance while inactive.

## Completion verdicts

Every verdict below must be updated from observed evidence only, using exactly `PASS`, `FAIL`, or `NOT_RUN`.

- Godot import/parse: NOT_RUN
- GUT unit suite: NOT_RUN
- GUT integration suite: NOT_RUN
- inactive mode freeze: NOT_RUN
- LOCK freeze: NOT_RUN
- Combat Clock during LOCK: NOT_RUN
- mode destination requires explicit RUN: NOT_RUN
- Line event -> Energy: NOT_RUN
- completed Chain -> non-additive Stock: NOT_RUN
- Skill -> Energy + Stock consumption: NOT_RUN
- insufficient-resource Skill -> no mutation: NOT_RUN
- enemy schedule visible and fires on time: NOT_RUN
- telemetry contains the performed transitions: NOT_RUN

## Explicitly NOT_RUN after Core POC

These are not completion requirements for this slice and must not be reported as finished:

- production Line falling-piece controls and rotation/kicks
- production Chain pair controls and gravity feel
- true Line-vs-Chain difficulty balance
- advanced Combo/B2B/Spin/Perfect Clear combat bonuses
- All Clear bonus design
- final top-out recovery
- class roster balance
- external tester validation
