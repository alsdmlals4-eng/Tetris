# Tetris Project

퍼즐 전투 게임 프로젝트 저장소.

## 현재 Production 방향

현재 1턴의 기본 순서는 다음과 같습니다.

```text
적 행동예고
→ Line/Tetris: Energy 준비
→ Swap-Match Chain: Chain Stock / Tier 준비
→ Action: Attack / Defense / Support × Tier 1–6 중 행동 선택·발동
→ 적 행동 발동
→ 다음 적 행동예고
→ 반복
```

핵심 원칙:

- Line은 **Energy** 준비를 담당하고 Chain은 **Chain Stock / Tier 접근권** 준비를 담당합니다. `TETRIS-BALANCE-027`에 따라 두 자원은 서로 대체되지 않습니다.
- Energy는 Technique의 유연한 throughput/utility 비용이고, Chain Stock은 이번 판단에 얼마나 크게 커밋할지 정하는 Tier 비용입니다. Tier N은 Stock N을 소비합니다.
- Chain Stock cap은 6을 기준으로 하므로 무조건 6까지 모으는 것도 무료가 아닙니다. cap 근처에서는 추가 Stock 획득 기회를 잃을 수 있고, resource-loss/repair/heavy/lethal Intent가 `지금 쓸지, 지킬지, 다음 Turn을 준비할지`를 바꿉니다.
- `TETRIS-SKILL-026`부터 Tier는 단순한 `상위 Tier = 더 좋은 같은 기술`이 아니라 **얼마나 많은 Stock을 현재 판단에 커밋할지 나타내는 tactical band**입니다.
- 낮은 Tier는 자원 효율·마무리·가벼운 대응, 중간 Tier는 setup/counter/debuff/ward, 높은 Tier는 조건부 signature·lethal safety·장기 setup을 담당합니다. 가능한 최고 Tier가 항상 정답이면 설계 실패로 판정합니다.
- Attack/Defense/Support 각 Tier는 player-facing Technique identity가 달라질 수 있지만 공통 effect primitive와 데이터 조합으로 구현하여 18개의 별도 subsystem/script를 만들지 않습니다.
- 첫 tutorial Turn은 숨은 무료 자원 지급 대신 실제 production Line/Chain board의 authored seed에서 의미 있는 Energy/Stock 성과를 만들고 T1을 자연스럽게 경험하게 합니다. 처음부터 T6 도달을 목표로 가르치지 않습니다.
- 정확한 Line Energy gain, Technique Energy cost, 피해/회복/상태 수치와 Tier 선택 빈도는 **TUNE_REQUIRED**입니다. 자동 simulation은 impossible state와 명백한 dominance를 찾는 데 사용하고, 재미·이해도·최종 밸런스는 Human evidence로 판정합니다.
- Chain은 production **Swap-Match** 퍼즐입니다.
- `TETRIS-TIME-025`부터 Line / Chain / Action은 **하나의 shared player-turn time budget**을 공동 소비합니다.
- Enemy Telegraph, Line/Chain settle, 강제 애니메이션/전환, Enemy Resolve, System Pause는 이 플레이어 입력 시간을 소비하지 않습니다.
- 플레이어는 합법적인 안정 상태에서 `READY`로 Line/Chain을 조기 종료할 수 있고, 남은 시간은 다음 player stage로 그대로 이어집니다.
- Action을 확정하면 공유 타이머가 즉시 정지하고, 의미 있는 Line+Chain 성과를 낸 뒤 빠르게 완료한 턴은 남은 성과 기준에 따라 **Tempo Bonus**를 받을 수 있습니다.
- Tempo 평가는 실제 사용 가능 시간과 별도의 unmodified performance reference를 사용하므로 Haste/아이템/쉬운 난이도로 시간을 늘린 것만으로 보상이 부풀지 않습니다.
- Tempo는 처음부터 Energy/Stock을 직접 지급하지 않아 자원 snowball을 만들지 않습니다.
- 난이도·아이템/장비·Support Haste·상태이상 Slow·명시적 encounter effect는 하나의 data-driven turn-budget modifier pipeline으로 처리합니다.
- 첫 migration 비교 seed는 이전 `30s / 30s / 30s` 총합과 동일한 90초 ceiling을 사용할 수 있지만 최종값은 아니며, 더 짧은 총시간/난이도별 값은 runtime·human evidence로 비교합니다.
- 공유 시간이 0이 되면 현재 퍼즐의 이미 커밋된 settle만 끝내고 남은 player-input stage는 사용할 수 없으며 `PASS` fallback으로 적 행동까지 진행해 deadlock을 막습니다.
- Chain 입력 종료 시 새 Swap은 금지되지만 이미 시작된 cascade는 stable까지 마무리한 뒤 보상을 확정합니다.
- 플레이어 행동이 먼저 발동한 뒤, 턴 시작에 예고된 적 행동이 발동합니다.
- 기존의 항상 흐르는 적 Combat Clock과 자유 Line↔Chain 전환 / Tactical RUN·LOCK / 독립 30/30/30 phase reset은 현재 production turn 구조에서 사용하지 않습니다.
- Score는 전투 자원이 아니라 performance evidence입니다.

현재 Production 정본:

1. `docs/design/PRODUCTION_TURN_TIME_CANON.md` — timing / modifier / timeout / Tempo authority.
2. `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` — ordered combat turn and remaining non-timing production rules.
3. `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md` — Vanguard tactical Tier / Technique / dominance guard authority.
4. `docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md` — Line Energy / Chain Stock opportunity cost, Tier exposure, anti-hoarding/spam, simulation/Human evidence boundary.
5. `docs/design/PRODUCTION_CANON_INDEX.json` — machine-readable routing authority.

`docs/design/CORE_GAMEPLAY_GDD.md`, `POC_RULESET_V0_1.md`, 기존 45초 POC 및 PR #3 구현은 삭제 대상이 아니라 **Core Combat Foundation / Engineering Harness**로 보존합니다. 기존 자동 검증 PASS는 Foundation의 역사 계약을 증명하며 최신 Production turn 구현 완료를 뜻하지 않습니다.

## 현재 구현 경계

- Core Combat Foundation / Engineering Harness: **main에 존재**
- Production Line Engine: **미구현**
- Production Swap-Match Chain Engine: **미구현**
- Production Turn Controller: **미구현**
- Production Shared Turn Budget / Time Modifier / Tempo: **미구현**
- Production SKILL-026 Tactical Tier Matrix / Effect Primitive runtime: **미구현**
- Production BALANCE-027 dual-resource economy / Tier exposure runtime: **미구현**
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
