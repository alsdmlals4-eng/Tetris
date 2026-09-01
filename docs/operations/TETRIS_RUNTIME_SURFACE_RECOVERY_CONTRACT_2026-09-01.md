# Tetris Runtime Surface Recovery Contract — 2026-09-01

## Direction Anchor

사용자가 승인한 50:50 퍼즐·전투 구도를 실제 Godot 전투 장면에 복구한다. Gatebreaker는 전투 스테이지의 유일한 대형 인물로 남기고, Vanguard는 읽기 쉬운 HUD 초상으로 이동하며, Current ETA와 같은 값을 보여 주는 Shared Action Timer를 추가한다.

## Intake

- Work level: `L2`
- Work mode: `BUILD`, with `CONTINUOUS_WORK_ACTIVE`
- Approval reference: this session's repeated 50:50 composition, large boss, HUD-face, shared-timer directions and the latest `권장안대로 작업진행` continuation.
- Current project head: `b102a0613f95968e4a12d6b25d5a408bae272e29`.
- Protected baseline: `c2093d7796cf8948dff613c41407c7e857d7a3e2`.
- Open PRs #85, #46, #33, #23, and #19 were read as overlap evidence only. They are not edited, rebased, merged, cherry-picked, or selectively absorbed by this work.

## Current findings

1. The authoritative user direction calls for an approximately 50:50 desktop split, but current `main` still encodes 60:40 in its active scene, tests, and current production documents.
2. The current `CombatStage` displays both full-body characters. That places Vanguard in the enemy/boss zone and weakens the requested boss hierarchy.
3. The `enemy_eta_seconds` source already drives the Current Telegraph, but there is no distinct Shared Action Timer presentation alias.
4. The project already owns deterministic, transparent Vanguard/Gatebreaker runtime cutouts and an authored stage backdrop. A new image batch is neither required nor authorized for this layout repair.
5. Current CHAIN and Skill runtime gaps remain real: CHAIN-038 is partial and Skill remains a legacy manual Tier 1–6 flow. They are explicitly deferred to the separately reviewable PR A/PR B boundaries in `2026-08-29-phase2-tactical-core-alignment.md`.

## Reuse-first preflight and alternatives

| Candidate | Evidence | Disposition |
| --- | --- | --- |
| Existing `battle.tscn`, current cutouts, stage backdrop, VFX, and `ProductionBattle` snapshot | Actual `main` consumers, checked scene/script, image manifest | `REUSE_EXISTING_PROJECT_IMPLEMENTATION` — retain the approved source candidates and change only geometry/consumer slots. |
| Current Godot `Control`/`TextureRect` layout facilities | Official Godot 4.7 docs: anchors, container stretch ratios, `STRETCH_KEEP_ASPECT_COVERED` | `ADAPT_WITH_THIN_PROJECT_ADAPTER` — use ordinary anchors, clipping, an `AtlasTexture` portrait crop, and one snapshot-driven timer label. |
| Base `RM-VIS-001/002` | Base Visual Asset Material Modules and Tetris adoption profile | `REFERENCE_ONLY` — its semantic states/symbol guidance is useful, but the Tetris profile still describes superseded turn-budget rules and is not adopted as a runtime skin. |
| Merge or copy current draft PR #85 | Current GitHub PR list and diff | `REJECT` — active draft material stays read-only without named absorption authority. |
| Leave the protected documents frozen and change only the scene | Formal adapter validator behavior | `REJECT` — would knowingly create a code/canon contradiction. |
| Re-pin the adapter baseline to the branch itself | Formal adapter rules | `REJECT` — self-attested baseline movement would defeat the protected-path guard. |
| Approved protected-change gate | Base `check_approved_project_operating_contract.py` and user-approved current decision | `ADOPT` — one exact approval record reconciles only the listed current canonical paths, then the generator/readback gate runs again. |

`REUSE_FIRST_PREFLIGHT_REQUIRED` is `COMPLETE`. No cross-project code is reused. The Tetris Base profile is stale relative to `TETRIS-CORE-029`, so it is deliberately not adopted.

## Scope

### Included in this recovery PR

- Reconcile current 50:50 layout intent in active project canon and its tests through the approved protected-change gate.
- Change the Godot battle surface to a 50:50 Puzzle/Combat split.
- Keep Gatebreaker as the only visible full-stage character, enlarge its cropped covered presentation, and retain the existing threat VFX behind it.
- Move Vanguard to a larger Resource HUD portrait using an `AtlasTexture` crop of the existing runtime cutout; no new raster asset is produced.
- Add a read-only Shared Action Timer presentation. Its displayed value must equal the current `enemy_eta_seconds` that already drives the Current Telegraph.
- Add regression coverage for the composition, boss/portrait ownership, and timer-alias behavior.

### Explicitly excluded from this recovery PR

- No CHAIN-038 resolver/resource change, no 1-MP lock, no diagonal implementation, and no Combo cap mutation.
- No C1–C10 data, category-only Skill resolver, fallback transaction, or target-separated time control.
- No onboarding/tutorial, balance claim, Human/player-experience claim, new paid dependency, or generated image batch.
- No modification, rebase, closure, merge, or copy-in of any open PR.

## Protected-change boundary

The exact approved canonical paths are recorded in `TETRIS_RUNTIME_SURFACE_RECOVERY_PROTECTED_CHANGE_APPROVAL.json`. The Base approved-change checker must see **only** those protected-path changes; any extra protected path remains a failure.

## Before / after / effect / risk

| Current state | Change | Expected effect | Risk and mitigation |
| --- | --- | --- | --- |
| 60:40 scene and stale active documents | 50:50 scene, test, and canon reconciliation | Board and combat surface receive equal first-read weight, as user requested. | Width pressure at 1280×720; use `HBoxContainer` ratios and bounded stage minimum height, then import/run visual checks. |
| Vanguard and Gatebreaker share `CombatStage` | Gatebreaker remains in stage; Vanguard becomes a cropped HUD portrait | Boss reads as the sole looming threat; player identity remains readable near HP/MP/Combo. | Crop can hide the face; assert a deterministic `AtlasTexture` region and inspect a runtime capture before any Human claim. |
| ETA only appears in Current Telegraph | Shared Action frame formats the same snapshot ETA | Communicates one shared reaction window without recreating turns, READY, PASS, or a second timer. | A second state source could drift; both labels read the same `snapshot()["enemy_eta_seconds"]` in one refresh method and are unit-tested. |
| Protected adapter rejects canonical updates | Exact approval manifest + approved checker | Protects all unrelated canonical paths while allowing this user-approved correction. | Manifest could overreach; schema and checker require the exact detected protected-path set. |

## Acceptance and evidence ceiling

1. `battle.tscn` gives PuzzleColumn and CombatColumn a 0.5 stretch ratio.
2. `CombatStage` contains Gatebreaker, backdrop, and VFX, but no visible Vanguard full-body stage consumer; the Resource HUD owns the named Vanguard portrait consumer.
3. The shared timer, Current Telegraph ETA, and current-action indicator display the same snapshot ETA value.
4. The approved protected-change validator, generated-view check, Python tooling suite, Godot import/parse, focused GUT UI tests, and exact-head CI must pass before merge.
5. Runtime rendering, target-device layout, accessibility, Human readability, and player-experience evidence remain `NOT_RUN` until actually observed and recorded.

## Pre-commit machine evidence

| Gate | Result | Exact scope / ceiling |
| --- | --- | --- |
| Approved protected-path contract | `PASS` | Base `check_approved_project_operating_contract.py` accepted the exact `c2093d7` baseline, seven approved protected paths and explicit external user approval. |
| Python tooling suite | `PASS` | 50 tests, including the 50/50 canonical index, separate cutout consumers, shared-timer workflow and adapter workflow contract. |
| Godot import / parse | `PASS` | Godot `4.7.1.stable` loaded the modified project in headless editor mode with no scene or GDScript parse error. |
| GUT runtime suite | `PASS` | 214 tests across 46 scripts; the focused battle-surface tests include 50/50 stretch ratios, no Vanguard in `CombatStage`, AtlasTexture consumers and same-snapshot ETA aliasing. |
| Runtime visual capture | `NOT_RUN` | The only live Hera editor belongs to a different GRIMOIRE project. It was preserved; no Tetris live editor was launched into its ports. Headless parse/GUT do not prove final pixels, device layout or Human readability. |

## Rollback

Revert this PR's scene/script/test/document commits together. It changes no source raster bytes, no save format, no economy, and no unrelated worktree; restoring the previous 60:40 surface is a single Git revert until a better user-approved layout replacement exists.

## Continuous sequence after this PR

1. `PR A` — deterministic CHAIN/resource alignment from the existing Phase 2 plan.
2. `PR B` — Combo-resolved C1–C10 Skill preview/CONFIRM and target-separated time control.
3. `PR C` — first-session briefing and safe continuous tutorial handoff.

Each begins from the latest merged `main`, retains other PRs read-only, and repeats the task evidence gate.
