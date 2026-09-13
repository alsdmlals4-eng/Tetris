# R3 Falling Chain and Disruption Implementation Plan

## Current execution — 2026-09-14

Latest user approved the recommended implementation. Prior design-only wording is historical, not a stop instruction. Task0 safety and Task1–5 source/models are implemented and tested to the limits recorded in [current checkpoint](../../operations/R3_IMPLEMENTATION_CHECKPOINT.md); delivery gates are not all closed. Task6–8 remain. Preserve user project.godot and all previous unrelated files. Same exact checkout/dedicated branch isolation is reused because the adopted slot8 launcher is path-pinned (R2 implementation ledger109). Plan-first/reuse benchmark from the preceding design delivery is REUSED_EVIDENCE; current main/code/PR and official Godot storage + SEGA lesson sources rechecked. Base profiles are reference-only and contain stale ordered-turn identity; no Base module/adapter installation. FEASIBLE for pure model work; UI/runtime remain verification gates.

Ruling: proceed with tightly coupled tasks sequentially and use bounded independent review; no parallel source writers. Task0 safety must precede live write probes; pure model tasks do not require a live player save. Cost if wrong: delayed integration, not save migration.

Connection receipts: dedicated Tetris Godot4.7.1 / HiGodot3.2.0 was verified earlier. Latest Hera inventory does not contain Tetris; the live UI skill requires its exact editor connection before UI work. Other project editors are untouched. No new authoring provider installed or global route changed.

> **For agentic workers:** 구현 재개 시 `superpowers:executing-plans`로 항목별 수행한다. 최신 사용자가 구현을 승인했다. 이전 명세 준비 시점의 실행 금지는 과거 기록이다. 사용자 최신 지시와 프로젝트 AGENTS가 우선한다. 병렬 에이전트 실행을 자동 승인하지 않는다.

**Goal:** LINE 준비→낙하 연결 연쇄→자동 기술의 역할을 연결하고, 예고된 적 보드 파괴를 안전하게 처리한다.
**Architecture:** 새 R3 규칙/보드/세션은 R2와 격리한다. 입력/저장/원정/화면 연결은 실제 기존 소비처를 재사용하되 구형 swap 인터페이스를 새 보드처럼 위장하지 않는다.
**Tech Stack:** 현재 Godot4.7.1/GDScript/GUT9.7.1, 기존 이미지·음향 도구. 새 엔진/addon/서비스 없음.
**Design owner:** [R3 설계 명세](../../design/R3_FALLING_CHAIN_AND_DISRUPTION_SPEC.md). U1/U2는 사용자 방향, 공급량 포함 수치는 권장안이다.
**Source:** main69f4f591e038b4912d9761bf943aefd986170ace. 실행 직전에 latest main/PR/dirty 상태를 다시 읽는다. 고정 SHA를 미래 실행 권한으로 사용하지 않는다.

## A. 현재 변경과 실행 금지 경계

- 현재 미커밋 `tests/tooling/r2_probe_storage.gd`, `test_r2_probe_storage.gd`, driver/probe 변경은 이전 저장 안전 작업이다. 로컬405/405,4219 assertions 로그는 있지만 독립 검토·새커밋·remote가 미완료다. 이번 설계 PR에 섞지 않는다.
- 사용자 `project.godot` 변경, `.asset-vault`, 기존 sidecar, 저장/백업 보존. 이전 원정 파일을 추정 복원하지 않는다.
- R2교환 저장을 R3로 매핑하지 않는다. 신규 `replanned_r3` 경로만 사용한다. R2PDF/원본자산은 변경하지 않는다.
- 문서 단계는 아래 테스트를 실행했다고 주장하지 않는다. 명세 검토 뒤 구현 승인 범위에서 진행한다.

## B. 파일/책임 지도

| 신규/변경 예정 경로 | 책임 / 경계 |
|---|---|
| `data/replanned_r3/rules.json` | 보드/공급/스킬/시간/넘침 수치. 문서 예시에서 수동 추측하지 말고 명세 값을 이식 |
| `data/replanned_r3/expedition.json` | 기존분기/적HP 유지, 세 파괴행동 추가. 별도schema/hash |
| `src/replanned_r3/r3_pair_board.gd` | pair 이동/회전/접지·중력·연결/BFS·cellID. HP/자원 변경 금지 |
| `src/replanned_r3/r3_line.gd` | R2 LINE 규칙을 재사용하는 R3 어댑터. 셀 ID 격자·줄 압축·부분 파괴·저장 동기화 소유; R2 파일은 불변 |
| `src/replanned_r3/r3_pair_supply.gd` | LINE고유소거→공급,spawn차감/ID중복방지 |
| `src/replanned_r3/r3_disruption.gd` | 표적추첨·예약·적파괴원인/정리. 보드상태 입력→계획 출력 |
| `src/replanned_r3/r3_session.gd` | 명령/논리시계/원자적사건순서. LINE은 R3Line 어댑터를 통해 재사용, CHAIN은 새보드 |
| `src/replanned_r3/r3_combat.gd` | R2검증된 HP/bank/armor/ward 효과를 R3계약으로 이식,source기록; R2정본 불변 |
| `src/replanned_r3/r3_save.gd` | r3-session-v1/schema/hash/안정체크포인트/백업. R2 writer의 원자교체 유틸 재사용 검토 |
| `src/replanned_r3/r3_expedition.gd` | 기존유한원정 경로 재사용, make_battle_session과envelope는 R3생성. R2세션 생성 금지 |
| `scenes/replanned_r3/main.tscn`, `src/replanned_r3/r3_screen.gd` | 새진입과뷰조립. R2Assets/Audio/Input의 호환 기능 재사용; 8×8커서 로직은 복사하지 않음 |
| `src/replanned_r3/r3_chain_view.gd` | 6×12/숨김/active pair/NEXT/잔여수/표적표시, 게임판정 금지 |
| `tests/replanned_r3/test_*.gd` | 아래AC별 실제명령/스냅샷/경계검사 |
| `tests/tooling/r3_native_flow_probe.gd` | 격리된실제경로/전후파일hash/캡처; 합성입력임을기록 |
| `docs/assets/reference/planned/replanning/r3/manifest.json` | 신규필요시안/원본hash/alpha/사용처/상태군; 승인여부분리 |
| `tools/windows/build_r2_local_trial.ps1` 후속 별도 R3 preset지원 | R2출력 유지하며 R3구분된패키지. R2명칭으로 R3를덮지않음 |

큰 R2화면을 통째로복제하거나 범용 UI프레임워크부터 만들지 않는다. R3에 필요한 board/threat/skill binding을 먼저 분리하고 기존 자산/음향/스타일을 사용한다. 공유추출이 R2동작을 바꾸면 별도 회귀AC가 필요하다.

## C. 인터페이스와 사건 계약

새 `R3PairBoard` API:

```gdscript
# 계약 서명. 이 블록은 실행 코드/현재 API가 아니다.
spawn(pair_id: String, kinds: Array[String]) -> Dictionary
command(action: String, args: Dictionary) -> Dictionary
next_event_us() -> int
advance_time(delta_us: int) -> void
plan_due_event() -> Dictionary
commit(plan: Dictionary) -> Dictionary
snapshot() -> Dictionary
restore(snapshot: Dictionary) -> bool
```

plan은 `{event_id, revision, cause, phase, cells, wave, category}`. cells는 `{cell_id,x,y,kind}` 배열, 중복ID/범위밖/낡은revision이면 무변경실패. Board는 순수 배치·소거계획만 반환. Session이 HP/스킬과 함께 확정한 뒤 revision증가. Board 단독 commit으로 자원을 지급하지 않는다.
Session command는 기존 move/rotate/soft_drop/hard_drop/switch/category/pause/resume를 유지하되 활성보드로 dispatch. `hold`는 LINE에서만 허용, `chain_swap`는 `UNSUPPORTED_R3_COMMAND`. frame `_process`가 아닌 `tick(delta_us:int)`이 논리 시간을 소유.
Supply API `credit(clear_id:String,unique_cell_ids:Array[String])->Dictionary`, `consume(spawn_id:String)->Dictionary`, `snapshot/restore`. 반환 `{success,applied,overflow,reason}`. 고유LINE event만 전달; 적파괴event는 세션단에서 라우팅하지 않음.
Disruption actual API: constructor(seed), `begin(action_id,board,count)`, `reserve(eta_us,candidates)`, `preview()`, `commit()`, `cancel_uncommitted()`, snapshot/restore. Session merges the committed reservation and actual board result into `{event_id,target_board,target_ids,removed_ids,missing_ids,cause}`. This separates Current board binding from the last2s cell selection. RNG별도스트림/정렬후추첨; 중복action은재처리하지않음.

## D. 구현 작업 순서 / 독립 완료조건

각 작업은 **실패 테스트 작성→실패 원인 확인→최소 구현→해당 회귀 통과→문서/커밋** 순서. 다음 작업으로 넘어가기 전 예상과 실제 증거를 기록한다. 테스트 이름은 예정 이름이며 현재 존재하는 것으로 인용하지 않는다.

### Task 0 — 안전한 실행 기반 마무리 (AC15)

대상: 기존 저장안전helper/probe와 `test_r2_probe_storage.gd`. 목표: 화면속성과 실제disk불일치가 있으면 native probe진입 거부. 새 scene을 트리에 넣기 전 모든경로설정, 정상저장files/.bak의 존재여부+SHA 전후동일.

- [ ] 직전405검사 결과와 현재dirty를대조하고 별도변경단위로검토.
- [ ] 안전factory 생성→start/중간save/continue/options저장/결과report→종료를 실제로 실행.
- [ ] 일반save/options/expedition/.bak가 하나라도 달라지면 실패, 자동복원금지.
- [ ] 두전체검토,정확한HEAD검사와보호된출판. 게임규칙의R3승인으로위장하지않음.

### Task 1 — 규칙 데이터와 공급 (AC03~05)

대상: rules.json, r3_pair_supply.gd, `test_r3_pair_supply.gd`.

독립 fixture/기대값:

```text
initial_pairs=4; cap=12; per_10_line_cells=3
consume("p1") -> 3; consume("p1") -> 3, duplicate
credit("l1", 10 distinct ids) -> 6; duplicate l1 -> 6
state pairs=11; credit("l2",20 distinct ids) ->12, overflow5
state pairs=0; consume("p2") ->success false,NO_PAIR_SUPPLY
```

- [ ] 위수치검사와중복cellID/negative/잘못된원인거부검사를먼저실패시킴.
- [ ] 공급과랜덤색생성을분리하여구현. cap초과값은통계에남기고재사용하지않음.
- [ ] RNG/bag/NEXT저장원본을정의하고중복spawn소비0검사.
- [ ] 커밋후다음보드구현에 API인계.

### Task 2 — 낙하 pair와 연결 해소 (AC01/02/06/12)

대상: r3_pair_board.gd, `test_r3_pair_board.gd`, `test_r3_pair_chain.gd`.

손으로검산한바닥fixture(위10행EMPTY):

```text
A.....
AAA...  => A4, single wave, no refill

A.....
.A....
..A...
...A..  => diagonal only, no group

AA.DD.
AA.DD.  => two groups, one wave
```

- [ ] 연결BFS(상하좌우)와동시집합union,4미만거부를실패→구현.
- [ ] 이동/회전후보순서/수평쌍분리낙하/벽천장/접지8회상한실패→구현.
- [ ] 300ms분할tick과큰tick의동일snapshot,신규보충0,21wave초과정지검사.
- [ ] 공급없음,spawn실패,소거후숨김생존,topout한번만/환급0검사.
- [ ] 전체상태 저장/복원동일성과기존R2보드불변회귀후커밋.

### Task 3 — 세션/기술/보급 연결 (AC03/06/10)

대상: r3_line.gd,r3_session.gd,r3_combat.gd, `test_r3_line_identity.gd`, `test_r3_session.gd`, `test_r3_autocast.gd`.

```text
LINE A6,D4 => bank6,armor4,pairs+3
pair lock with ATK; waves1,2 => damage10 then6; bank0
same wave has A4,D4 => one cast, not two
select DEF during resolving => rejected; inspect T5 => no mutation
boss lethal event and SUP due same microsecond => DEFEAT, heal0
```

- [ ] Session publiccommand에서위시나리오실패확인.
- [ ] LINE 착지 시 고유 셀 ID를 부여하고 줄 소거/압축 시 문양과 ID를 함께 이동. 부분 파괴 시 해당 ID만 제거. 새 전투 namespace와 단조 증가 카운터를 저장하고 제거 ID를 재사용하지 않음.
- [ ] 표적 셀이 아래 줄 소거로 이동해도 동일 ID를 파괴하며, 표적 자체 선소거 시 빗나가는 테스트. ID 격자와 문양 격자의 불일치/중복 ID 스냅샷은 무변경 거부. Session 밖의 R2Line 직접 변경 경로 차단.
- [ ] 보드계획과HP효과를원자commit,스크린이직접상태변경하지않게연결.
- [ ] inactive낙하정지,ETA진행,전환queued,전체pause와분할tick검사.
- [ ] R2효과이식의차이는R3rulehash로구분,구형save는바꾸지않음.
- [ ] 기존R2+새R3전체회귀통과후커밋.

### Task 4 — 적 파괴/예고/정리 (AC07~11)

대상: r3_disruption.gd, r3_session.gd, expedition.json, `test_r3_disruption.gd`.

```text
reservation ids=[c1,c2,c3]; c2 player-cleared => removed[c1,c3], no replacement
duplicate action/event => no extra deletion/damage
target LINE then switch CHAIN => target still LINE
ENEMY_DESTROY causes four connected cells => 0 cast,0 supply,0 resource
no occupied eligible cells => 0 board deletion, authored HP damage remains
```

- [ ] 후보 배열 순서가 달라도 동일 seed/action이면 표적이 같은지 검사. 후보는 ID 정렬 후 시드 추첨.
- [ ] 예약2초와현재active보드lock,cellID표식,이미소거예정셀제외구현.
- [ ] ETA피해와원자파동경계사이pendingdisruptionqueue구현.
- [ ] Enemy원인 전파중player캐스트취소/기지급효과취소없음,무보상정리/빈보드검사.
- [ ] 완화모드계산값이예고·실제피해/파괴수와일치하는지회귀후커밋.

### Task 5 — 저장/원정 연결 (AC11/13/15)

대상: r3_save.gd,r3_expedition.gd, `test_r3_save.gd`, `test_r3_expedition.gd`.

- [ ] R2save입력을R3복원에주면명시적거부하고파일bytes유지하는실패테스트.
- [ ] 별도R3경로/envelope/hash/백업writer연결. 안정시점만checkpoint.
- [ ] 예고IDs/RNG/NEXT/공급/접지시간/누적ID복원후같은입력동일결과검사.
- [ ] 두분기 모두시작→3전투→보급→결말,패배/재도전/완화모드/손상복구검사.
- [ ] 반복새원정이과거원정pair/ID를재사용하지않는지검사후커밋.

### Task 6 — 실제 UI·입력·학습 (AC04/06/14)

대상: main.tscn,r3_screen.gd,r3_chain_view.gd, `test_r3_screen.gd`.

- [ ] 6×12보드영역/NEXT2/잔여쌍/공유ETA/Current표적보드·수/스킬최근·예고표시의경계검사작성.
- [ ] 교환클릭/드래그와3매치문구를새R3경로에서제거. LINE HOLD만표시.
- [ ] 3단계연습: LINE한줄보급→쌍회전/4연결→적표식선소거와2연쇄.
- [ ] 키재배치/마우스/패드focus/창복귀후명시resume/긴한국어/125%글꼴검사.
- [ ] no-supply상태의오해·색각보조문양·무음예고를실제화면검토후커밋.

### Task 7 — 이미지/모션/음향 (AC14)

대상: R3시안manifest,실제R3뷰소비처,기존r2_assets/r2_audio의검증된재사용면.

- [ ] 기존4문양타일/감시탑/초상/스킬아이콘소비처와statefamily를다시대조.
- [ ] 필요한룬석4문양및표적/clear/hit만이미지모델로제작;Aseprite선택지침에따라동일RGBAroundtrip/atlas영역/pivot검증. 새전체화면그림으로구현을대체하지않음.
- [ ] 낙하/연결/파괴동작은Session사건의표현만담당. 모션스킵/효과축소/저장재개가보상재실행을만들지않는지검사.
- [ ] 주조소전용적상태군,원정/메인/결과의실제미충족이미지만제작. 모든필수상태제작후소비처와hash등록.
- [ ] 원본투명도/경계/축/글자가시성/native스크린·청취검토. 최종사용자비주얼승인별도.

### Task 8 — 비교 검증·패키지·블루프린트 (전체AC)

- [ ] 20seed 합성명령검사와세전략계측표작성. 0사고시간봇의승리를Human재미로표시하지않음.
- [ ] R2 vs R3무한공급 vs R3LINE보급 비교; 새공급량외변수를고정하고사용자방향과맞는지검토.
- [ ] 정상저장전후hash불변의native두경로,1280/1920×100/125%/pause·failure·resume캡처.
- [ ] R3Windows별도패키지/폰트/JSON/이미지rawhash/입력/세이브목적지검증. 종료경고는별도기록.
- [ ] 정본명세·실데이터표·SWOT·아틀라스·모션표·실제화면·flow·미검증목록을새PDF로발행. 기존52p보존,새판에exactsource와구형rule충돌을명시.
- [ ] 정확히2회전체검토후잔여문제교정,실제HEAD검사/PR/정상병합/mainreadback. 승인요청이필요한최종디자인/출시gate와구현완료구분.

## E. 실행 검사 방법

프로젝트root에서 Godot headless GUT를 새 `tests/replanned_r3`부터 실행하고 이후 `tests` 전체를 실행한다. Windows에서는 프로세스 종료를 기다리고 stdout/stderr/exitcode를 함께 보존한다. 단순 프로세스 시작은PASS가 아니다.

```text
Godot4.7.1 --headless --path <exact checkout> -s addons/gut/gut_cmdln.gd -gdir=res://tests/replanned_r3 -ginclude_subdirs -gexit
Godot4.7.1 --headless --path <exact checkout> -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
python -m unittest discover -s tests/tooling -p test_*.py
```

새판은 기존R2사용자세이브/보호production/현재이미지와독립해rollback가능해야 한다. 구형swap코드는 새판검증전삭제하지않는다. 실제consumer가0인임시파일만사용자삭제대기폴더로옮기고원래경로/해시/복원설명을제공한다.

## F. 승인 후 재개 체크

- [ ] 공급쌍 추가안을 명확히 승인된상태로기록(현재는권장안).
- [ ] 파괴가HP방어와별개라는상세안을 명확히기록.
- [ ] 실제latestmain/작업중첩/보호scope를fresh-read.
- [ ] Task0부터종속순서진행. 기존미커밋작업은별도출판,이설계문서만으로완료처리금지.

설계자체검토: 명세AC01~15가Task0~8에연결됨. 현재실행API와신규예정API를구분. 이미지/저장/원정/학습/PDF를후속작업에서누락하지않음. 구현·자동검사·runtime·Human의R3상태는모두NOT_RUN이다.
