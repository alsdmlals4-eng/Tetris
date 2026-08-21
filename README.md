# Tetris Project

퍼즐 전투 게임 프로젝트 저장소.

## 현재 방향

- 두 개의 독립 퍼즐 보드: Line / Chain
- Line Clear로 Energy 획득
- Chain으로 Skill Tier 사용권 확보
- Skill은 직업 공통 전투 역할(공격 / 방어 / 치유) 위에 직업별 표현과 효과를 얹는다.
- 활성 퍼즐 보드만 진행 가능하며 비활성 보드는 정지한다.
- 퍼즐 정지와 별개로 적의 Combat Clock은 계속 진행한다.

상세 규칙과 수치는 `docs/design/`의 승인된 GDD를 정본으로 관리한다.

## Windows Core POC 로컬 검증

PR #3의 Core POC를 사용자 Windows PC에서 검증할 때는 저장소 루트의 `RUN_LOCAL_VALIDATION.cmd`를 **더블클릭**한다. 사용자가 PowerShell 명령을 직접 입력하거나 기존 Godot 설치를 변경할 필요는 없다.

검증기는 `%LOCALAPPDATA%\TetrisCorePocValidation` 아래 격리된 sandbox를 만들고 다음 순서로 진행한다.

1. 검증 브랜치를 fresh clone
2. Godot `4.7.1-stable` / GUT `9.7.1` 준비
3. Windows import/parse
4. 전체 GUT suite + strict log guard
5. POC를 열어 화면의 `NEXT:` 지시에 따라 10단계 수동 검증
6. 45초 이상 + 모든 단계 완료 시 최종 JSON 증거 저장

완료 전에는 POC를 닫지 않는다. 성공 증거는 sandbox의 다음 파일에 기록된다.

- `local_preflight.json`
- `manual_validation_report.json`
- `local_validation_evidence.json`

실패하거나 다시 시작하려면 `%LOCALAPPDATA%\TetrisCorePocValidation` 폴더를 삭제하면 된다. 기존 Godot 설치/프로젝트/설정은 검증 대상이 아니며 변경하지 않는다.

상세 판정 기준과 PASS/NOT_RUN 상태는 `docs/validation/POC_45S_VALIDATION.md`를 따른다.
