# 자원 퍼즐 선택 · 검증 기록

## 범위와 사용

사용자 승인: 자원은 LINE 또는 SWAP 선택, 기술은 고정 낙하 연쇄. 후속 명시 승인으로 PR118 head `8a3c254d97c290e3f606d2dc807a2bbb52a1029f`의 R3 코드·테스트·연결 자산을 main `b5fe1886550ef98548f0fe0c206d9047550ded0b` 기반 `codex/resource-puzzle-choice-20260920`에 선별 통합했다. PR117/118, 원래 작업 폴더의 사용자 변경, R2·production·Base9.4.4·전역 설정은 수정하지 않는다.

실행: Godot4.7.1에서 `scenes/replanned_r3/resource_choice.tscn`을 현재 씬 실행. 준비에서 LINE/SWAP 선택 → 시작 → 자원 확보 → Tab → 낙하쌍 연쇄 → 자동 기술. Esc 일시정지, 저장/불러오기, 종료 후 자원 선택으로 복귀. 기본 F6/현재 씬 실행과 프로젝트 기본 F5 실행은 다르다. 프로젝트 기본 scene을 몰래 교체하지 않았다.

SWAP 마우스 두 인접 칸 또는 방향키+Enter/Space; 유효 3매치가 없으면 원복. 보급/환산은 UI 안내와 `resource_choice.json` 기준. 빠른 첫 소거를 보상 1:1로 단정하지 않고 시험 계수를 적용한다. HUMAN 밸런스 미검증.

## 실제 증거

- 선별 통합 R3 baseline: 82 tests / 2970 assertions PASS.
- 기능 RED: 준비 선택 command 부재 3/3 실패 → 첫 연결 GREEN 3/3,15 assertions.
- 저장/종료 확장 RED: 파일 readback 및 패배 중 cascade 잔류 2건 → StringName 신규 저장키를 String 키로 교정하고 terminal 정리 → GREEN8/8,48 assertions.
- 화면 RED2/2 → 실제 준비/보드 선택/전환/정지 consumer GREEN2/2,13 assertions.
- 첫 전체 회귀: 494/494 tests,7233 assertions,81 scripts,101.79s. 이후 교정은 아래 최종 검사로 구분한다.
- 독립 read-only 코드 검토: P2 세 건(살아 있는 셀을 이미 지급한 원장으로 복원, 준비 배경 저장, 거절 명령이 선택 잠금). 직접 재현 RED 후 교정. 종료 뒤 재선택까지 GREEN13/13,71 assertions. 독립 검토를 작성자 self-review라고 표시하거나 반대로 하지 않는다.
- 실제 native OpenGL/NVIDIA RTX3050,1280×720: `preparation.png`, `swap.png`, `pair.png`, `line.png`, `runtime.json`. 실제 선택·유효 교환·자원 증가/스킬0·보드 전환·격리 저장 readback. 자동 입력/fixture evidence이며 사람 플레이가 아니다. `pair.png`의 focus-loss pause는 정상 pause 표시이며 실행 중으로 주장하지 않는다.
- 테스트 저장은 `user://resource-choice-tests/`, native probe는 `user://resource-choice-native-probe/`. 제품 새 슬롯은 `user://resource_choice/`, 기존 `replanned_r2`/`replanned_r3`는 보호한다.

## 검토와 미검증 경계

계약 전체 self-review1: 책임/저장/타이머/부정 보상 경계와 실패 처리. Self-review2: 교정본+실제 화면/전체 회귀/남은 요구 재계산. 독립 검토 finding은 회귀검사로 닫고 전체 검토 예산을 초기화하지 않는다.

현재 구현은 선택형 단일 전투 slice다. 모든 원정/메인 메뉴의 기본 진입을 대체하지 않으며, 전체 캠페인 통합·최종 모션·음향·정식 아트·사람 밸런스·기기 접근성·출시 승인·새 블루프린트 발행까지 완료한 것이 아니다. 기능 자동 검사는 재미 증거가 아니다. 기존 날짜별 누적 작업일지 정책은 유지하며 새로운 일별 PDF를 만들지 않는다.

최종 로컬 교정본: Godot4.7.1/GUT9.7.1 전체 **499/499 tests,7252 assertions,81 scripts,80.787s**, script/parse errors 없음. Python tooling **94/94**. Base adoption 원본+생성물3개 PASS/변경0, Windows PowerShell static/port self-test PASS. 마지막 준비 상태 load 실패 안내도 실제 화면 consumer 검사로 교정했다. 저장 반례 테스트 중 생성한 새 제품 namespace의 시작 전 샘플 한 개는 검증 후 `C:/Users/user/Documents/삭제검토/Tetris/resource-choice-20260920/test-preparation-save.json`으로 이동했다(SHA256 `34b288fd99c993aef92ab47110493e21dc4e5b0777b2258cd89bac3f918bbe8d`). 정상 R2/R3 진행을 삭제한 것이 아니며 사용자가 직접 삭제/복원할 수 있다.

상태/최종 SHA/필수 검사/PR·main readback은 live GitHub 기록과 아래 종료 기록으로 대조한다. 생성 이미지가 아니라 기존 승인/후보 이미지 consumer를 보존했으므로 신규 이미지 생성·최종 자산 승인 주장은 없다.
