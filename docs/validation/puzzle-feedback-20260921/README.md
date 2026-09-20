# 기술 정보·퍼즐 성취 피드백 · 2026-09-21

승인: 직전 정보+중요 순간 집중 연출안에 사용자의 `진행해`, 콤보/팡파레 추가. 실행 계획은 R3_FALLING_CHAIN_AND_DISRUPTION_SPEC.md의 최신 절. 기준 fetched main b2b3ab91422ac03436653e3e1dd813488a036260, Base 운영 adoption23ecad5 및 release9.4.4 유지. 원래 dirty checkout, 기존 untracked imports/UIDs, Draft PR들은 건드리지 않는다.

## 구현과 검증 연결

| 요구 | 실제 consumer | 판정 경로 |
|---|---|---|
| 기술명·아이콘·역할·실효량 | presentation.json → skill_feedback → resource_choice/r3_screen | 실제 2연쇄 dispatch와 컷인/최근기술 검사, 무효/상한 formatter |
| LINE 일반/테트리스/T스핀/콤보/B2B | mastery history → puzzle_feedback | 실제 FOUR/SPIN/COMBO 연습, 보급 불변 |
| 교체·연쇄·보정·적파괴 구분 | command/tick receipts → puzzle_feedback | 실제 SWAP 중복 ID, 실패 복귀, bonus cost, 적파괴 무성공음 |
| 무음·동작감소·중단 | 기존 TierSound 버튼 → bounded3voices/64bursts/64motions | pause, scene transition, reduce, layout tests |

기존 아이콘/4문양 atlas와 Kenney line/chain/confirm 음원 재사용. 출처와 hash는 `docs/design/r2-complete-session.json`, `assets/replanned_r2/audio/SOURCES.md` 유지. 새 이미지 제작/승인 주장 없음. 기술 아이콘과 실제 performer 컷인은 독립 슬롯. 추가 미터 API/설치/글로벌 설정/게임 수치 변경 없음.

## 실행 ledger

- 계획 승인 재사용; writing-plans/executing-plans/TDD 적용. 계획은 프로젝트 규칙에 따라 기존 분야 정본에 추가, 중복 계획/PM 문서 미생성. 기존 linked worktree 재사용, codex/puzzle-celebration-20260921은 최신 main에서 시작.
- Baseline R3 158/158,3496assertions PASS. 신규 실제-entry RED2/2 (feedback 및 named skill 없음) → GREEN2/2,10assertions.
- 경계 확대: RED 중복 교체 팡파레. 기존 SWAP commit receipt에 불변 clear event_id 전달(계산/저장 변경 없음) → 실제 교체 반복 수신 검사 PASS. fixture의 first_swap 오기는 실제 데이터 키 swap으로 교정; 잘못된 짧은 적검사 시간은 기존4행동 경계에 맞춰 늘림. 이들은 제품 수정으로 주장하지 않음.
- Native 1280/960 Godot4.7.1 Compatibility RTX3050에서 actual resource_choice 실행. 초기 캡처의 보드 위 축하 문구가 플레이 칸을 가림을 확인, overlap RED → 보드 외부 여백으로 교정. 순간 팝 scale까지 경계에 포함하는 검사 유지. 원문 배치 최소치가 아닌 실제 transformed rect로 검사.
- 첫 전체 회귀570 중569 PASS/레이아웃1FAIL, tooling95/95 PASS. 실패 로그를 성공으로 취급하지 않으며 수정 후 재실행 필요.

## 전체 검토 (같은 승인 계보에서 두 번)

1. 전체 code/data/event/UI/settings/보호 경로와 승인안을 대조. 무상시스템 재구현 대신 기존 사건을 읽는 방식 유지. 중복 수신/연출 무음/체력·시간 상한/공유시계/캐릭터 아이콘 fallback/좁은창 공격을 검증. SWAP receipt ID 누락과 text-board overlap을 교정. 신규 경제/일시정지/자산 교체는 기각. 교정 후 전체 검사와 native 재확인 진행 중.
2. 교정된 전체 code/data/UI/사건 수명과 untouched production/R2/save/asset consumer를 다시 대조. 팝 확대까지 포함한 겹침 검사를 통과시켰으며, 실패 GUT 선택 옵션은 실행증거에서 제외하고 파일 전체를 다시 실행했다. 최종 전체570/570·7747assertions(87scripts,81.066s), tooling95/95 통과. 과거 결과 복구 시 재생하지 않는 session reset, 실패/적파괴 무팡파레, 보너스 비용과 실제 effect formatter 검사. native 첫 캡처의 원인·최종 여백 배치 비교 확인. 무의미한 효과 강화나 새 자산/시스템은 기각, 기존 좁은 consumer 재사용 유지. 독립 병합 검토·최종 출판/remote/main은 별도 게이트이며 두 전체 회차를 다시 초기화하지 않는다.

HUMAN 재미/최종 청취·믹스/물리기기/최종자산/출시 NOT_RUN. 에디터 연결 도구는 session0; 플러그인 설치 대신 직접 Godot native로 검증, editor-connected라고 주장하지 않는다. benchmark는 직전 제안의 공식 Tetris Effect gameplay-synchronized presentation 조사 REUSED_EVIDENCE; 현재 구현/기존 자산이 첫 비교 기준. Base 환류는 아직 후보 없음, NO_NEW_REUSE_LEARNING.

현재 REMAINING_WORK: 최종 테스트/후속 전체검토/독립검토/누적일지/PR 정상병합/main readback/사용자 실행 확인. 코드 완료나 전체게임완료로 닫지 않는다. 롤백은 본 표시 소비자와 연결만 bounded Git revert; 기존 saves/schema/rules 그대로.
