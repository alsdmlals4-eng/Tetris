# 시동 문양 · 연쇄 종료 1회 스킬 검증

## 구현과 실행 경로

2026-09-20 승인 범위. 시작 main `d4fe8130342d0e0714e1cc0089fb67766a3595cc`, 구현 검토 SHA `4b27904acd7386a9e5e7d420e9d8d9d2c765b72f`.
`scenes/replanned_r3/resource_choice.tscn`을 실행한다. 전투 전 LINE/SWAP 선택은 그대로이고, Tab으로 고정 낙하쌍 보드와 전환한다. 첫 문양 A/D/H/T로 스킬이 정해지고, 전체 연쇄 끝에 한 번 발동한다. production 기본 시작, R2/이전 R3 원정은 이번에 변경하지 않았다.

## 확인한 증거

| 구분 | 실제 결과와 범위 |
| --- | --- |
| 변경 전 기준선 | R3 97/97 tests, 3,050 assertions PASS |
| 실패 재현 | 새 발동/시간 검사 최초 6개 중 5개 FAIL. 기존 per-wave/manual 규칙 때문에 예상대로 실패 |
| 최종 전체 Godot | 520/520 tests, 7,365 assertions PASS; 82 scripts, 68.699s. Godot4.7.1/GUT9.7.1. script/error/warning 출력 없음 |
| 집중 검사 | 21/21, 113 assertions. A/D/H/T, 동시 문양 우선순위, 2연쇄 1회/자원 1회 소모, 3단계 합산 산술, 시간 상한, 적 방해 무보상, 동일 순간 적 우선, 키 해제, 시간 분할 결정성, 저장/변조 거부/승패 종료 |
| 도구 검사 | Python94/94 PASS; workflow adoption validator PASS; Base23ecad5 운영 채택과 release9.4.4 보존 |
| Windows 실행기 | StaticSelfTest와 PortPreflightSelfTest PASS. 타 프로젝트 편집기/포트 변경 없음 |
| 실제 화면 | NVIDIA RTX3050/OpenGL native 실행. 1280×720 착지 예고·시동 확정·플레이어/적 접촉, 960×540 pause 렌더. [runtime.json](runtime.json)과 PNG 직접 확인 |
| 실제 흐름 | 연쇄 2회→공격 1회, 기본4+6/자원6=피해16, HP100→84; 접촉/회복 구간 공유 ETA 고정; 새 파일 저장/복원 후 미재발동 |
| 독립 검토 | 읽기 전용 별도 검토자가 구현 SHA4b27904의 명세/코드/실사용/UI/저장 경계를 대조하고 집중21/113 재실행. 최종080ef08의 증거 문서·JSON·PNG5장까지 독립 확인. P0/P1/P2 blocking0, 병합 가능 판정 |
| 사람/출시 상한 | HUMAN 새 규칙의 재미·연출 피로·물리 입력·장시간 밸런스 NOT_RUN. 전 버전의 사용자 긍정 평가를 새 버전 승인으로 전용하지 않음. 최종 아트/전체 원정/출시 완료 아님 |

실행 명령(저장소 루트): `Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`.
실제 렌더 재현: `Godot --path . -s tests/tooling/finisher_native_probe.gd`. QA 저장은 `user://finisher-native-probe/`; 사용자 슬롯과 분리한다. 공개 저장소에 계정/결제/계약 원본은 넣지 않는다.

## 두 차례 전체 검토와 교정

1. 시동/효과/순서/입력/원장/저장/UI/기존 호환성을 대조. 파일 JSON의 숫자 표현 차이로 정상이 거부되는 경우를 재현·교정하고, 소수 위력의 악성 원장은 거부하도록 별도 검사. 첫 소거 시점 확정 표시 누락도 RED→GREEN. 중간 전체517/7352 PASS.
2. 같은 전체 범위를 다시 대조. 연출 중 soft-drop release 차단과 소거 후 치명적 topout의 미발동 묶음 잔존을 RED→GREEN으로 교정. 적 발동/다음 대기 표시, 완성 연쇄 수, 조작 비활성화를 실제 렌더로 재확인. 최종520/7365 PASS. 새 유효 blocking finding0, 기능 acceptance 충족. 이후 독립 검토는 이 횟수를 초기화하지 않음.

잘못 작성한 3연쇄 시험판이 실제로는 2연쇄인 것도 실행에서 확인했다. 그 판을 제품 오류로 처리하거나 기대값을 3연쇄 증거로 남기지 않았다. 3단계 합산은 순수 정책/실제 효과 검사로 확인하고 실제 화면 증거는 **2연쇄**로 한정한다. 4연쇄 이상 2초는 데이터와 분기 구현이며 현재 native capture가 4연쇄 플레이 증거인 것은 아니다.

## 유지·보호·되돌리기

- 승인 이미지/문양과 50:50 배치 유지. 시간 스킬은 기존 지원 포즈와 시간 문양을 사용; 새 이미지나 최종 아트 승인 없음.
- 새 저장 `user://starter_finisher/`와 두 새 schema만 사용. 옛 슬롯/원본 dirty worktree/열린 Draft들은 변경하지 않음.
- 현재 task 변경만 정상 revert 가능. 기존 슬롯을 삭제하거나 이전 저장을 새 schema로 몰래 변환하지 않는다.
- 재사용 학습은 PROJECT_ONLY: 연출 시간의 양방향 정지와 실제 효과의 단일 owner, 입력 release 예외, 숫자 정규화 전 정수 검증. Base 규칙·새 스킬 승격은 하지 않음.

## Repository readback / 남은 작업

[PR122](https://github.com/alsdmlals4-eng/Tetris/pull/122) 정상 squash 병합 완료. 검토한 최종 HEAD `080ef08d6c335c500ba1de429f1b0a6229e6f4e7`의 원격 검사3개 SUCCESS, CLEAN/mergeable, 미해결 thread0, 적용 rules API `[]` 확인 뒤 expected-head로 병합했다. main `a68d142764907c34ec3aa3608e678a3b88525239` fetch 및 전체 Git tree diff0 확인. 이 SHA는 구현 검증 대상이고 뒤의 문서 종료 기록 자체를 자기 검증하는 SHA가 아니다.

기존 `Tetris_2026-09_AI활용_작업일지_증빙집_v1.1.pdf`에 날짜별 후속 기록 `T-20260920-STARTER-FINISHER`를 추가하여15페이지. 이전14페이지 content stream 일치 검사, 마지막 페이지 직접 렌더 검수, 재실행 `ALREADY_APPENDED 15` 확인. SHA256 `d6faad834703321dccbc8cc61af0c7b80e54a286bad4f591cad2b9d3d2a1311b`. 원본·백업·수집시각은 사용자 비공개 증빙 폴더에 보관하며 PDF 발행 당시 원격검사 진행 중이라는 기록은 그 시점의 사실로 보존한다. 날짜/해시는 독립적인 작업시점 인증이 아니다.

완료 gate: `REMAINING_WORK_COMPLETION_GATE=PASS_FOR_APPROVED_SLICE`, `IMPLEMENTATION_CORRECTION_RESCAN=PASS`, `POST_COMPLETION_ADVERSARIAL_REVIEW_REQUIRED=PASS`, `CLEAN_REVIEW_EXIT=PASS`. 필요한 제품 후속 작업이 없다는 뜻은 아니다.
다음 제품 범위는 기존 원정/메뉴에 새 규칙 연결, LINE/SWAP 비교 수급과 연출 피로의 사람 관찰이다. 새 규칙의 기계·렌더 증거와 사람 재미 판단을 구분한다.
