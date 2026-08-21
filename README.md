# Tetris Project

퍼즐 전투 게임 프로젝트 저장소.

## 현재 Production 방향

현재 1턴의 기본 순서는 다음과 같습니다.

```text
적 행동예고
→ Line/Tetris Phase: 제한시간 동안 Energy 획득
→ Swap-Match Chain Phase: 제한시간 동안 Chain Stock / Tier 준비
→ Action Phase: Attack / Defense / Support × Tier 1–6 중 행동 선택·발동
→ 적 행동 발동
→ 다음 적 행동예고
→ 반복
```

핵심 원칙:

- Line은 Energy 준비를 담당합니다.
- Chain은 production **Swap-Match** 퍼즐이며 Chain Stock / Skill Tier 준비를 담당합니다.
- Line / Chain / Action은 각각 독립된 data-driven 제한시간을 가집니다.
- 첫 Vertical Slice의 시작 튜닝 후보는 `30s / 30s / 30s` maximum이며 최종값은 아닙니다.
- 플레이어는 합법적인 시점에 `NEXT / READY`로 각 Phase를 일찍 끝낼 수 있고, 남은 시간은 이월되지 않습니다.
- Chain 시간 종료 시 새 Swap은 금지되지만 이미 시작된 cascade는 stable까지 마무리한 뒤 보상을 확정하고 Action Phase로 이동합니다.
- 플레이어 행동이 먼저 발동한 뒤, 턴 시작에 예고된 적 행동이 발동합니다.
- 행동 선택 시간이 끝날 때까지 선택하지 않으면 `PASS` 처리 후 적 행동으로 넘어가며 게임이 멈추지 않습니다.
- 기존의 항상 흐르는 적 Combat Clock과 자유 Line↔Chain 전환 / Tactical RUN·LOCK은 현재 production turn 구조에서는 사용하지 않습니다.
- Score는 전투 자원이 아니라 performance evidence입니다.

현재 Production 정본은 `docs/design/PRODUCTION_TURN_COMBAT_CANON.md`입니다.

`docs/design/CORE_GAMEPLAY_GDD.md`, `POC_RULESET_V0_1.md`, 기존 45초 POC 및 PR #3 구현은 삭제 대상이 아니라 **Core Combat Foundation / Engineering Harness**로 보존합니다. 기존 자동 검증 PASS는 Foundation의 역사 계약을 증명하며 최신 Production turn 구현 완료를 뜻하지 않습니다.

## 현재 구현 경계

- Core Combat Foundation / Engineering Harness: **main에 존재**
- Production Line Engine: **미구현**
- Production Swap-Match Chain Engine: **미구현**
- Production Turn Controller: **미구현**
- Production Tier 1–6 Skill/HUD: **미구현**
- 사용자 Windows Production runtime / human playtest: **NOT_RUN**

## Windows Core Foundation 로컬 검증

PR #3에서 흡수된 기존 Core Foundation을 사용자 Windows PC에서 검증할 때는 저장소 루트의 `RUN_LOCAL_VALIDATION.cmd`를 **더블클릭**합니다. 이 검증은 기존 Engineering Harness 계약에 대한 증거이며 Production turn gameplay 검증으로 승격하지 않습니다.

검증기는 `%LOCALAPPDATA%\TetrisCorePocValidation` 아래 격리된 sandbox를 만들고 다음 순서로 진행합니다.

1. 검증 브랜치를 fresh clone
2. Godot `4.7.1-stable` / GUT `9.7.1` 준비
3. Windows import/parse
4. 전체 GUT suite + strict log guard
5. 기존 POC 45초 수동 검증
6. JSON 증거 저장

성공 증거:

- `local_preflight.json`
- `manual_validation_report.json`
- `local_validation_evidence.json`

실패하거나 다시 시작하려면 `%LOCALAPPDATA%\TetrisCorePocValidation` 폴더를 삭제하면 됩니다. 기존 Godot 설치/프로젝트/설정은 검증 대상이 아니며 변경하지 않습니다.

역사 Foundation 판정 기준은 `docs/validation/POC_45S_VALIDATION.md`를 따릅니다.
