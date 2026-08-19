# Core POC 45-Second Validation Ledger

- Date opened: 2026-08-19
- Automated evidence updated: 2026-08-19
- Scope: Core dual-board combat POC only
- Canon: `docs/design/CORE_GAMEPLAY_GDD.md`, `docs/design/POC_RULESET_V0_1.md`
- Plan: `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- Canonical REMOTE_CI target: Godot `4.7.1-stable` + GUT `9.7.1`
- REMOTE_CI checkout action: `actions/checkout@v7`
- User Windows-local Godot/GUT execution: **NOT_RUN / UNVERIFIED**
- Chat execution container: Git available; Godot not installed; therefore not accepted as local Godot evidence.
- Automated evidence run: GitHub Actions `core-poc-ci` run `32260246944`, job `96091519903`, implementation head `6ed11db57cd3620ad7a119f9debb6643c98b8224`.
- Automated suite: **41/41 tests PASS, 288 assertions, Godot import/parse PASS**.
- Plan completion gate: **OPEN** — exact user-local Godot/GUT execution evidence and one human-operated continuous 45-second encounter are still required by the approved implementation plan.

## Evidence status

| Check | Status | Evidence |
|---|---|---|
| Godot/GUT REMOTE_CI preflight | PASS | Godot 4.7.1 + GUT 9.7.1 pins verified on the standard GitHub-hosted runner. |
| Godot import/parse | PASS | `godot --headless --path . --editor --quit` passed in automated evidence run. |
| GUT unit suite | PASS | 26/26 unit tests passed. |
| GUT integration suite | PASS | 15/15 integration tests passed. |
| inactive mode freeze | PASS | Integration tests and automated 45s scenario preserve inactive source state. |
| LOCK freeze | PASS | Active puzzle source advance count remains unchanged while LOCKED. |
| Combat Clock during LOCK | PASS | Combat time advances and enemy action fires while puzzle source is LOCKED. |
| mode destination requires explicit RUN | PASS | Scene/domain tests confirm switched destination remains LOCKED until explicit RUN. |
| Line event -> Energy | PASS | Double produces exactly +22 when isolated from emergency Energy timing. |
| completed Chain -> non-additive Stock | PASS | Repeated low Chains do not add; Stock caps at 5. |
| Skill -> Energy + Stock consumption | PASS | T1/T3 tests confirm configured Energy cost + exact Tier Stock consumption. |
| insufficient-resource Skill -> no mutation | PASS | Rejected T5 preserves Energy, Stock, and enemy HP. |
| Skill blocked during RESOLVING | PASS | Integration test confirms no resource/effect mutation; UI disables Skill buttons. |
| queued mode switch truthfulness | PASS | Request during RESOLVING logs queue first; actual switch logs only after resolution finishes. |
| enemy schedule visible and fires on time | PASS | HUD exposes next `attack 40`; deterministic actions resolve at 12/24/36s. |
| enemy telemetry scheduled timestamps | PASS | Coarse 45s tick still records enemy actions at 12/24/36, not 45/45/45. |
| mode-state UI honesty | PASS | LINE/CHAIN buttons expose LOCKED/RUNNING/SUSPENDED state explicitly. |
| telemetry contains performed transitions | PASS | Line, Chain, Skill use/reject, mode queue/switch, and enemy action events verified. |
| automated continuous 45-second encounter | PASS | `test_automated_forty_five_second_contract` reaches 45.0s in one session and verifies the required state/resource sequence. |
| exact user-local Godot/GUT execution | NOT_RUN | No authorized connection to the user's Windows Godot runtime exists in this session. **Completion blocker.** |
| human-operated continuous 45-second encounter | NOT_RUN | No interactive user-local runtime/input evidence was produced. **Completion blocker.** |

## Automated 45-second encounter steps

The automated integration test completes this sequence in one `PocSession`:

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

This is deterministic implementation evidence, **not** evidence of human input ergonomics, final puzzle feel, or Line-vs-Chain difficulty balance.

## Five implementation adversarial review loops

The implementation was re-attacked after tests were green. Verified fixes were added with RED -> GREEN regression tests.

1. **Economy:** removed emergency Energy fractional-time banking across Line gain / Skill spend transitions.
2. **State truth:** blocked Skill use during `RESOLVING`; distinguished queued mode-switch telemetry from an actual switch.
3. **Timing evidence:** enemy telemetry now records scheduled 12/24/36-second timestamps even when simulation ticks are coarse.
4. **UI honesty:** mode buttons expose LOCKED/RUNNING/SUSPENDED and Skill controls disable during `RESOLVING`.
5. **Governance/CI:** synchronized latest `main`, removed CI-history-only noise from the net implementation diff, and refreshed `actions/checkout` to current v7 while retaining zero-incremental-cost standard runner policy.

After loop 5 there is no known remaining automated MUST_FIX finding in the approved Core POC scope. The remaining blockers are empirical/local and are not replaced by REMOTE_CI.

## Completion verdicts

The statuses below are from observed evidence only.

- Godot import/parse: PASS (REMOTE_CI)
- GUT unit suite: PASS (26/26)
- GUT integration suite: PASS (15/15)
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
- enemy schedule visible and fires on time: PASS
- enemy scheduled telemetry time: PASS
- mode state shown in UI: PASS
- telemetry contains performed transitions: PASS
- automated continuous 45-second scenario: PASS
- exact user-local Godot/GUT execution: NOT_RUN
- human-operated continuous 45-second encounter: NOT_RUN
- overall approved-plan completion: **OPEN / NOT COMPLETE**

## Explicitly NOT_RUN production scope

These are intentionally outside the Core POC and must not be reported as finished:

- production Line falling-piece controls and rotation/kicks
- production Chain pair controls and gravity feel
- true Line-vs-Chain difficulty balance
- advanced Combo/B2B/Spin/Perfect Clear combat bonuses
- All Clear bonus design
- final top-out recovery
- class roster balance
- external tester validation
- production visual/UI polish and final art
