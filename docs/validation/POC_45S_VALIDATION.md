# Core POC 45-Second Validation Ledger

- Date opened: 2026-08-19
- Last automated validation: 2026-08-19
- Scope: Core dual-board combat POC only
- Canon: `docs/design/CORE_GAMEPLAY_GDD.md`, `docs/design/POC_RULESET_V0_1.md`
- Plan: `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- Canonical REMOTE_CI target: Godot `4.7.1-stable` + GUT `9.7.1`
- User Windows-local Godot version: **UNVERIFIED**
- Chat execution container: Git available; Godot not installed; therefore not accepted as local Godot evidence.
- Final automated evidence run: GitHub Actions `core-poc-ci` run `32258493276`, job `96085780213`.
- Final automated suite: **35/35 tests PASS, 243 assertions, Godot import/parse PASS**.

## Evidence status

| Check | Status | Evidence |
|---|---|---|
| Godot/GUT REMOTE_CI preflight | PASS | Final run used Godot 4.7.1 and GUT 9.7.1; pin checks passed. |
| Godot import/parse | PASS | `godot --headless --path . --editor --quit` passed in final run. |
| GUT unit suite | PASS | 25/25 unit tests passed as part of final 35-test suite. |
| GUT integration suite | PASS | 10/10 integration tests passed as part of final 35-test suite. |
| inactive mode freeze | PASS | `test_lock_and_inactive_mode_freeze_sources_but_not_combat_clock` and 45s scenario. |
| LOCK freeze | PASS | Active puzzle source advance count remains unchanged while LOCKED. |
| Combat Clock during LOCK | PASS | Combat time advances and enemy action fires while source is LOCKED. |
| mode destination requires explicit RUN | PASS | Scene/domain tests confirm switched destination remains LOCKED until RUN. |
| Line event -> Energy | PASS | Double produces exactly +22 when isolated from emergency recovery timing. |
| completed Chain -> non-additive Stock | PASS | Repeated low Chains do not add; Stock caps at 5. |
| Skill -> Energy + Stock consumption | PASS | T1/T3 tests confirm Energy cost + exact Tier Stock consumption. |
| insufficient-resource Skill -> no mutation | PASS | Rejected T5 preserves Energy, Stock, and enemy HP. |
| enemy schedule visible and fires on time | PASS | HUD exposes next `attack 40`; deterministic actions resolve at 12/24/36s. |
| telemetry contains performed transitions | PASS | Line, Chain, Skill use/reject, mode switch, enemy action events verified. |
| automated continuous 45-second encounter | PASS | `test_automated_forty_five_second_contract` reaches 45.0s in one session and verifies all required transitions. |
| human-operated 45-second play session | NOT_RUN | No interactive Godot runtime/input tool was available in this execution environment. |

## Automated 45-second encounter steps

The final automated integration test completed this sequence in one `PocSession`:

1. Start Line in `LOCKED`.
2. Explicitly `RUN` Line and submit a Double, producing 22 Energy.
3. `LOCK` Line and verify its source freezes while Combat Clock continues.
4. Switch Line -> Chain and confirm Chain lands `LOCKED`.
5. Explicitly `RUN` Chain and submit a completed 3-Chain, producing Stock 3.
6. Use a successful T1 Attack, consuming 15 Energy + 1 Stock.
7. Attempt unavailable T5 Attack and confirm no resource/HP mutation.
8. Keep Chain `LOCKED` through the 12-second enemy attack and confirm puzzle source remains frozen.
9. Switch back to Line and confirm its saved progress did not advance while inactive.
10. Continue the same session to 45.0 seconds; 12/24/36-second enemy actions all resolve and telemetry remains intact.

## Completion verdicts

The statuses below are from observed REMOTE_CI evidence only.

- Godot import/parse: PASS
- GUT unit suite: PASS
- GUT integration suite: PASS
- inactive mode freeze: PASS
- LOCK freeze: PASS
- Combat Clock during LOCK: PASS
- mode destination requires explicit RUN: PASS
- Line event -> Energy: PASS
- completed Chain -> non-additive Stock: PASS
- Skill -> Energy + Stock consumption: PASS
- insufficient-resource Skill -> no mutation: PASS
- enemy schedule visible and fires on time: PASS
- telemetry contains the performed transitions: PASS
- automated continuous 45-second scenario: PASS
- human-operated 45-second play session: NOT_RUN

## Explicitly NOT_RUN after Core POC

These are not completion requirements for this slice and must not be reported as finished:

- user Windows-local Godot/GUT execution
- human-operated 45-second play session
- production Line falling-piece controls and rotation/kicks
- production Chain pair controls and gravity feel
- true Line-vs-Chain difficulty balance
- advanced Combo/B2B/Spin/Perfect Clear combat bonuses
- All Clear bonus design
- final top-out recovery
- class roster balance
- external tester validation
- production visual/UI polish and final art
