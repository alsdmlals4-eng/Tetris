# 짧은 원정과 반격 수호 검증 · 2026-09-21

승인: 직전 권장안(짧은 완결 원정·중간 강화·결과) 및 방어 T회 50% 경감/동량 반사. 기준 main `2a71290154a565e0a461504bf27cb6bb62f35e04`; Base 채택23ecad5/release9.4.4 유지. 현재 범위 상태는 [실행 계약](../../operations/SHORT_EXPEDITION_EXECUTION.json), 의미 정본은 [R3 명세](../../design/R3_FALLING_CHAIN_AND_DISRUPTION_SPEC.md#short-expedition-counter-guard).

## 실제 연결

| 요구 | 실제 소비자 | 검증 |
|---|---|---|
| 방어 T회 수호, 경감·반사 | counter_session → counter_combat → 기존 enemy impact | test_counter_guard: T1~6/누적/중복/잔여0/상태행동/동시사망/반사승리/저장 |
| 기존 보호막 유지·읽히는 효과 | skill_feedback / r3_screen / 기존 performer | defense-impact 및 counter-impact native 캡처 |
| 최신 퍼즐로 3전투 완주 | short_expedition → 기존 R2 route/supply + Counter battle | test_short_expedition: route/reward/restore/retry |
| 자원 선택/결과/이어하기 | short_expedition_screen / short_expedition_save | phase별 디스크 roundtrip, 실제 screen save/load |
| 이전 저장 보호 | 새 short_expedition 및 counter_guard namespace; mastery_legacy 진입 | 기존 전체 회귀 + 명시 이전 진입 검사 |

새 원정은 기존 3종 보급(응급 정비/공격 준비/방벽 보강)을 재사용한다. 새 영구 성장/직업/메타게임 아님. 뿌요시동·단일최종발동·4문양·LINE/SWAP 보정·공유시간·파괴·기존 자산 유지. 기본 production 진입/다른 Drafts/원본 dirty checkout/Base 설정은 변경하지 않는다.

## 실행 ledger와 판정 근거

- planning/TDD/executing-plans 사용, 기존 worktree 재사용. 실행 계획은 기존 R3 정본에 넣고 root receipt start gate 실행. 첫 cp949 출력 실패는 UTF-8을 이 실행에만 지정해 재실행 PASS; 전역 설정 수정 없음.
- 최초 counter4검사 RED(기능 없음) → 구현 후 JSON ledger 복원 실패. 디버깅 스킬로 combat/raw/JSON cast 경계를 나눠 **JSON float/int 사전 비교**를 특정, 정규화 후 GREEN4/4. 검사 자체를 약화하지 않음.
- 원정2검사 RED(기존 R3 경로가 최신 전투를 만들지 않음) → 기존 route/supply 어댑터로 GREEN. 실제 entry/설명/화면 진입 RED → 연결 후 GREEN.
- Ruling: 방어 경감은 기존 보호막/방어도 후 잔여 피해의 올림 절반, 반사는 적 장갑/약점/가산 없는 직접 피해. 재사용 횟수 누적, 새 전투 초기화. 잘못되면 밸런스 조정/신규 schema 검토가 필요하며 사람 검증 전이다.
- Ruling: 원정 보상은 기존 3종 carry enhancement를 재사용. 새 영구 특성 경제는 승인된 작은 완주 범위에 불필요. 향후 빌드 다양성은 사용자 경험 관찰 후 별도 판단.
- Ruling: 테스트의 적 컷인 종료 정확한 경계는 파괴 pending이 남는 불안정 상태. 기존 계약대로 +1us 안정 처리 후 저장 검사, 미처리 정산을 저장 가능하게 바꾸지 않았다. actual entry schema 검사만 counter successor로 갱신, 기존 Mastery 테스트는 보호.
- 첫 전체 회귀 **583/583·7895assertions·90scripts·108.002s**, tooling **95/95·28.982s**. 이후 검토 교정분은 최종 재실행 대상.

## 전체 검토 1 / 2

전체 코드·저장·route/보급·UI·승인 자산/기본/other PR 경계를 읽고 3대안(재작성/구형 제자리 변경/격리 어댑터)을 재비교. 어댑터가 기존 회귀·복구 비용을 줄이므로 유지. 무조건 최신 Base 이관/새 자산/영구 성장 강제는 기각.

유효 finding: (1) 작은 창의 D 설명 overflow → 실제 캡처로 확인, 최근 요약 압축. (2) 화면 교체 시 무음·동작감소 초기화 → 실제 restore 테스트 RED, run coordinator가 선택 보존. (3) 이전 Mastery 저장 파일은 남지만 GUI 진입 누락 → legacy 규칙 entry와 명시 링크 추가. 반격 승리의 eta0 terminal과 simultaneous defeat는 모델/저장 검사로 재확인. 전체 회귀 재실행 예정.

## 증거 상한과 남은 작업

## 전체 검토 2 / 2

교정된 전체 승인 범위를 다시 읽었다. `counter_combat`의 HP 순서·반사/적 장갑·중복 행동·T6/초과연쇄·상태패턴과 `counter_session`의 실제 cast 검증, 3전투 route replay·중복 보급·실패 재도전·phase별 save 검증, 실제 UI 진입과 previous Mastery 접근을 대조했다. 코드/자산/설정의 영향 지도는 위 표이며 production·old schema·old save consumers는 호환 경로로 유지한다. index의 9/20 migration 설명은 역사로 남기고 최신 R3 locator를 추가했다. 68쪽 기존 reader는 이전 Mastery 시점 파생본, 이번 규칙/화면은 이 정본과 native evidence가 소유하며 과거 PDF를 새 결과로 표시하지 않는다.

세 대안 재검토에서도 기존 route/atomic save/actor reuse가 최소 변경·복구성에 적합했다. Full suite **584/584·7901assertions·90scripts·92.411s**, 오류/실패0; tooling95/95(변경 없는 tooling), native18장 재실행 exit0. 960 방어 설명 클리핑 교정 직접 확인. 무음/동작감소는 같은 원정 화면 재생성에서 보존하며 앱 재시작의 별도 설정 영속성까지 검증했다고 주장하지 않는다. 다른 Draft118/117/100/85/46/33/23/19 및 origin/main 재조회에서 충돌/중복 신규변경 없음. 이번 두 전체 회차를 더 초기화하지 않는다. 독립 검토/발행/원격/병합은 별도 남은 gate.

Hera 조회에서 현재 연결된 편집기는 Blacksmith/GRIMOIRE이며 수정하지 않았다. Tetris native standalone Godot4.7.1 Compatibility / RTX3050를 직접 실행, 1280×720·960×540에서 18장 캡처. [runtime.json](runtime.json)은 실제 scene/dispatch/process/render지만 전투 종료 HP는 단계 커버리지 fixture로 설정했다. 자동 플레이 완주/사람 입력·재미·최종 청취·최종아트·출시 승인으로 승격하지 않는다. 사용자 직전 긍정 피드백은 이전 버전에 대한 개별 관찰이지 이번 신규 밸런스 승인 아님.

남은 필수: 최종 회귀/두 번째 전체 검토/독립 검토/누적 작업일지/원격 PR/main readback. 새 이미지 제작 없음, 기존 승인 자산 재사용. 파일 삭제 없음. 롤백: 새 entry/successor 연결을 bounded revert, 모든 저장 namespace 보존. 프로젝트별 반격·route 연결 교훈이며 Base 승격 후보 없음 (`NO_NEW_REUSE_LEARNING`).
