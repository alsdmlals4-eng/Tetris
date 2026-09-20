# Tetris project work rules

한국어로 결과부터 설명한다. 사용자는 1인 개발자이며 코딩에 익숙하지 않다. 중요한 변경은 역할·작동 방식·직접 시험하는 방법을 알려준다. 이 파일은 진입·보호 규칙이며 게임 규칙을 다시 소유하지 않는다.

## Current-authority read order

1. 이 파일 → `docs/design/PROJECT_WORKSPACE_INDEX.md` → 현재 결정·Active Context인 `docs/design/REPLANNING_FOUNDATION.md`의 최신 요약.
2. 최신 원격 `main`, 로컬 변경/작업 폴더, 같은 목표의 열린·최근 병합 PR과 겹치는 파일을 확인한다. 과거 SHA·PR 번호·대화·PDF는 현재 실행 권한이 아니다.
3. 이번 범위의 실제 Scene·Script·데이터·자산 consumer·테스트와 분야 정본을 대조한다. 먼저 실행 경로를 구별한다:
   - 기본 실행: `project.godot` → `scenes/production/battle_briefing.tscn`; 기존 production 규칙은 `docs/design/PRODUCTION_CANON_INDEX.json`과 연결 문서가 소유한다.
   - main에 병합된 별도 R2: `scenes/replanned_r2/`, `src/replanned_r2/`; `docs/design/REPLANNING_AUTOCAST_R2.md`와 `docs/operations/TETRIS_R2_WHOLE_GAME.md`가 규칙/실행 범위를 소유한다.
   - 후속 R3/뿌요 전환은 해당 PR·브랜치의 실제 상태를 확인한다. 열린 작업을 main에 구현된 것으로 표시하거나 과거 production 규칙으로 되돌리지 않는다.
4. `skills/PROJECT_BASE_ADAPTER.json`과 `.agents/skills/tetris-workflow-router/SKILL.md`를 통해 필요한 Base Skill·참조만 읽는다. 전체 문서/skills를 기본 로드하지 않는다.

프로젝트 결정·승인 계약·실제 consumer가 외부 사례보다 우선한다. 충돌은 책임 owner와 증거를 찾아 영향 범위만 교정한다. 파일 존재, 자동 검사, 실제 실행, 사람 검수는 서로 대체하지 않는다.

## 승인과 연속 작업

- 새 의미 있는 변경은 의도·현재 상태·변경/보호 범위·계획·완료 기준을 먼저 설명하고 승인받는다. 같은 승인 계약의 `진행해/계속해`는 반복 승인·재계획 없이 구현→검증→교정→정본 갱신→허용된 병합/재확인으로 이어간다.
- 필요한 답이 저장소에 있으면 직접 확인한다. 새 핵심 경험·게임 규칙·주요 UX·비용·보안·파괴적 변경만 별도 결정으로 올린다.
- 현재 구현·승인 자산·Base 재사용 자료를 먼저 비교한다. 유효한 같은 조건의 조사는 `REUSED_EVIDENCE`, 새 판단에 필요한 공식 원출처만 추가 조사한다. 기계 수정은 이유 있는 비적용을 허용한다.
- 전체 적대 검토는 같은 승인 계보 전체에서 **2회**를 공유한다. 단계/스킬마다 다시 시작하지 않는다. 이후 발견은 영향 범위 교정·회귀검사로 처리하며 독립 병합 검토는 별도다.
- 이미 있는 owner/기록에 짧게 연결한다. 매 변경마다 새 계획서·Skill·재미 보고서·PDF를 만들지 않는다. 월별 작업일지는 기존 누적본에 날짜별로 추가한다.

## 보호 경계와 Git

- Base release 9.4.4, Godot/GUT 버전, 엔진 설정·저장 호환성·게임 규칙·승인 자산은 운영 지침 변경으로 교체하지 않는다. 설치 플러그인·전역 설정·외부 서비스도 변경하지 않는다.
- 사용자 로컬 수정과 다른 worktree/PR은 보호한다. 열린 PR은 기본 읽기 전용이며 승인 없는 checkout/write/rebase/merge/흡수는 금지한다.
- 최신 완료 main에서 만든 단 하나의 current-task PR은 같은 승인 범위에서 exact HEAD 검사, 필수 checks/review/ruleset, unresolved thread 0 확인 후 정상 병합하고 main을 재확인한다. Draft·기존/다른 작업 PR takeover, force push, direct main push, 관리자 우회는 제외한다.
- 추가 과금은 별도 승인 대상이다. 오래된 이름만으로 삭제하지 않는다. 폐기 가능성을 사용처/참조로 검증한 파일은 사용자가 직접 지울 수 있도록 복구 가능한 정리 위치와 목록을 제공한다.
- 저장소가 현재 정본이다. Notion/Sheet를 새 필수 작업면으로 복원하지 않는다. PDF·이미지 예시는 참고이며 승인/런타임 정본을 대신하지 않는다.

## TETRIS_FORMAL_BASE_ADAPTER_BOOTSTRAP

`skills/PROJECT_BASE_ADAPTER.json`이 유일한 Base 채택 owner다. `base_release`는 배포 계약, `shared_overrides.workflow_adoption`은 별도로 검토한 운영 방법이다. 최신 원격을 확인하되 어느 쪽도 조용히 교체하지 않는다.

`docs/operations/TETRIS_FIRST_PROJECT_ADAPTER_POLICY.json`의 `NOT_INSTALLED`는 최초 이관 당시 기록이다. 설치를 다시 수행하지 않는다. 보호 경로를 유지하고 현재 승인 변경은 승인 manifest와 외부 승인 근거를 함께 검사한다. 생성물은 프로젝트 validator의 `--write/--check`만 사용한다; 스냅샷·대시보드·router를 직접 편집하지 않는다.

## 구현·표현·재미 검증

- 플레이어-facing 작업은 workspace index §7의 경험 가설→규칙/선택/표현→실제 consumer→검증 연결을 적용한다. 순수 운영 수정에는 게임 재미 실험을 강제하지 않는다.
- 자동 테스트가 기능을 증명해도 재미를 증명하지 않는다. `DOC / MACHINE / RUNTIME / HUMAN / USER_APPROVAL / RELEASE`를 분리한다. 사람 검수 전에는 `HUMAN: NOT_RUN`; 승인된 구현은 계속할 수 있다.
- Godot 변경 때만 실제 `project.godot`·편집기 연결·실행 경로를 확인한다. 테스트는 변경 영향과 필수 CI에 맞춘다. 실행하지 않은 렌더·기기·성능 검증은 `NOT_RUN`이다.
- 이미지 작업은 `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md`와 현재 버전의 자산 manifest를 읽는다. 실제 슬롯·경로·규격·투명도·상태군을 확인하고 필요한 제작은 기존 포괄 승인 범위에서 진행한다. 후보 제작, 최종 자산 승인, 정본 등록, 런타임 연결/검증을 구분한다. 기존 승인 자산의 임의 교체는 금지한다.
- production의 Human 판정은 `docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md`, R2 관찰은 `docs/operations/TETRIS_R2_PLAYTEST_RECORDS.md`를 따른다. 한 버전의 결과를 다른 버전의 증거로 승격하지 않는다.

## 마무리

현재 상태·다음 작업·변경 이유·증거 경로는 기존 Active Context에 남긴다. 완료 시 변경/유지/보류·실제 검사·남은 위험·롤백을 설명하고, 권장 사항은 **현재 상태 → 권장 조치 → 이유 → 기대효과**로 정리한다. 미실행 필수 검증을 완료로 바꾸지 않고 남은 범위를 명시한다.
