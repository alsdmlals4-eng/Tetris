# Tetris Formal Base Adapter Bootstrap — Design

## Direction Anchor

`origin/main`에 존재하지 않는 Base adapter를 같은 feature branch에서 스스로 보호 기준으로 삼지 않는다. 먼저 사용자 승인 범위 안에서 실제 main 기준 보호정책 원본을 병합하고, 다음 PR에서만 그 고정 blob을 `PROJECT_BASE_ADAPTER`의 first-migration source로 소비한다.

## Current state and problem

- Tetris `origin/main` (`5df7d359b89074c7997b6f9b155c064a311db217`)에는 `skills/PROJECT_BASE_ADAPTER.json`, project Skill Registry, generated operating views, 또는 first-migration policy source가 없다.
- Base current main (`19355b7ef065a21d0f2b685c7d9be64a4a3970f8`)의 official `tools/check_project_operating_contract.py`는 `base_release_index.py`를 설치하며 v9.4.4 release lock과 finalization pin을 지원한다. 이 항목은 더 이상 Tetris blocker가 아니다.
- 동일 목적의 draft PR #85는 read-only다. 그 브랜치의 게임·전투 구현이나 operation contract를 이 bootstrap에 흡수하지 않는다.

## Reuse-first and alternatives

| Option | Disposition | Reason |
| --- | --- | --- |
| Adapter와 policy source를 한 PR에서 함께 작성 | REJECT | feature branch가 자신이 바꾼 기준을 바로 신뢰하게 되어 Base의 external-baseline gate를 우회한다. |
| 새 Base exception/schema를 먼저 만든다 | REJECT | current Base official CLI가 v9.4.4을 이미 지원하며, missing input은 Base 기능이 아니라 Tetris main의 policy source다. 불필요한 공용 surface 확장이다. |
| main policy-prelude PR 후 adapter-install PR | ADOPT | main에 먼저 고정된 source blob과 `refs/remotes/origin/main` equality를 사용하므로 self-attestation 없이 Base의 first-migration contract를 그대로 쓴다. |

`MECHANICAL_NO_EXTERNAL_DEPENDENCY`는 적용하지 않았다. Git 조상 검사는 Base의 실제 validator가 사용하는 trust boundary와 동일한 역할만 하며, 현재 Git/GitHub 공식 문서는 PR·보호 브랜치·정확한 기준 SHA를 지켜야 한다는 운영 선택과 일치한다. 새 runtime, dependency, asset, platform, cost, gameplay, visual or player UX direction은 추가하지 않는다.

## Two-PR contract

### PR A — policy prelude (this branch)

- `docs/operations/TETRIS_FIRST_PROJECT_ADAPTER_POLICY.json` becomes the real pre-adapter policy source at the later adapter baseline commit.
- `AGENTS.md` routes future workers to that source and states that no adapter is installed at this policy commit.
- The policy protects only existing project governance/canon owners and itself; it does not protect files that PR B must create.
- A tooling test verifies that every protected path is tracked and that the policy remains a pre-adapter source.

### PR B — formal adapter install (dependent, not yet created)

- Starts from the exact merged head of PR A, never from draft PR #85.
- Creates only the canonical adapter, project registry, generated snapshot/dashboard/router, and conservative health record required by current Base v9.4.4.
- Pins the exact Base v9.4.4 release/evidence/finalization identities, records PR A's merged main SHA as `protected_baseline.commit`, and reads this policy at `/protected_paths` with `FIRST_MIGRATION_LEGACY_SOURCE` (legacy here means pre-adapter source, not a copied Base Skill).
- Runs the Base checker and artifact builder against the exact Base checkout. It may not modify any protected canon file; normal later changes must establish a new canonical adapter baseline through the validated update route.

## Before → after → expected effect

| State | Before | After PR A | Expected effect |
| --- | --- | --- | --- |
| Trust source | No Base-verifiable policy blob on Tetris main | One tracked, reviewable, exact-path policy blob on main | PR B has an external baseline instead of self-attestation. |
| Project entry | Workers know only current gameplay canon | `AGENTS.md` identifies the pre-adapter policy and canonical future adapter path | The operational route is discoverable without copying Base Skills. |
| Gameplay/runtime | No change | No change | Existing Godot scenes, assets, skills, Line/Chain behavior and Shared Action Timer evidence remain untouched. |

## Scope, protection, rollback

- Included: `AGENTS.md`, one JSON policy source, one focused tooling test, this design, and the execution plan.
- Excluded: Base repository bytes, Godot code/scenes/resources/assets, current visual direction, runtime behavior, balance, all open PR branches, user-local `production_battle_theme.tres`, and any deletion.
- Rollback: revert the merged policy-prelude commit as a normal PR before PR B is merged; no runtime save/data migration exists.

## Evidence ceiling

PR A can prove source-path presence, JSON shape, tracked coverage, local tooling regression and later exact remote PR checks. It cannot prove that an adapter is installed, runtime behavior, device behavior, Human UX, release readiness, or final acceptance. Those stay `NOT_RUN` until their owning steps execute.
