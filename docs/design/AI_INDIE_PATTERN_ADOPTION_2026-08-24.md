# Tetris · AI Indie Pattern Adoption — 2026-08-24

```yaml
status: USER_DIRECTED_ADAPTATION
work_mode: PLAN_REVIEW
runtime_mutation: NONE
source_base_merge: dff09d83c3892a70ba5fee86a59d36086889a6c5
production_authority: TETRIS-TIME-025 + TETRIS-CORE-024
human_production_playtest: NOT_RUN
```

## 결론

현재 Tetris 제품은 `Enemy Telegraph → Line → Chain → Action → Enemy Resolve`의 읽을 수 있는 turn decision이 핵심이다. AI/RNG novelty를 추가할 이유가 없다.

이번 적용은 **생산 AI의 범위·누락 Gate, 코어 정체성 잠금 뒤 breadth 확장, Human feedback 기반 재설계**에 한정한다.

## 판정

| Pattern | 판정 | 적용 |
|---|---|---|
| HUMAN_DIRECTED_AI_BUILD_LOOP | ADOPT | production engine 구현 시 사람 acceptance criteria + RED/GREEN + runtime 판단 |
| SILENT_OMISSION_GATE | ADOPT_HIGH | Line/Chain/Action/Enemy/UI/data/test consumer 누락 공격 |
| CONTEXT_SCOPE_AND_ARCHITECTURE_BUDGET | ADOPT | puzzle state와 combat/turn/time/Skill authority 분리 유지 |
| BREADTH_AFTER_CORE_IDENTITY_LOCK | ADOPT_HIGH | 대표 Vertical Slice 검증 전 class/enemy/content breadth 확대 금지 |
| PLAYER_FEEDBACK_REBUILD_LOOP | ADOPT_HIGH | 30/30/30·shared budget·Tempo·telegraph 이해를 Human evidence로 조정 |
| AI_VISIBLE_OUTPUT_QUALITY_GATE | ADOPT | production UI/visual은 originality/readability/rights Gate 적용 |
| RNG_AGENCY_AND_RECOVERY | REJECT_CURRENT | 현재 핵심 선택을 랜덤 시스템으로 치환하지 않음 |
| runtime generative AI | REJECT_CURRENT | deterministic authored enemy telegraph가 우선 |

## 생산 AI Gate

각 material implementation은 다음 owner map을 먼저 유지한다.

```text
Line puzzle owner
Chain puzzle owner
Turn controller
Shared time budget / Tempo
Energy / Chain Stock
Skill eligibility / execution
Enemy telegraph / resolve
UI presentation
Persistence / telemetry
Tests
```

AI가 편의를 위해 이 owner를 한 script/UI에 합치는 것은 거부한다.

## Player Feedback Rebuild

대표 production slice에서 다음을 분리한다.

```text
PUZZLE_EXECUTION_DIFFICULTY
TIME_PRESSURE
RESOURCE_COMPREHENSION
TELEGRAPH_RESPONSE_QUALITY
ACTION_SELECTION_FRICTION
CORE_TURN_FAILURE
```

예를 들어 플레이어가 기다리는 시간이 많다면 core를 다시 실시간 dual-board로 되돌리는 대신 shared-budget 배분·phase 최대시간·early READY를 먼저 조정한다. 반대로 Telegraph를 봐도 Action 선택과 연결하지 못하는 문제가 반복되면 copy만 늘리지 않고 turn information architecture를 재검토한다.

## Breadth Gate

다음이 검증되기 전에는 AI로 클래스/적/Skill Tier 콘텐츠를 대량 생성하지 않는다.

- Line이 Energy preparation으로 인식됨.
- Chain이 Stock/Tier preparation으로 인식됨.
- Telegraph가 Action 판단을 실제로 바꿈.
- shared budget과 READY carryover를 이해함.
- Tier 1~6에서 낮은 Tier도 의미가 있음.
- PASS가 rare/understandable fallback임.
- production HUD가 Foundation debug UI와 혼동되지 않음.

## RNG / runtime AI 경계

- refill/randomizer는 puzzle implementation detail로만 다루고 새로운 RNG metagame을 만들지 않는다.
- AI가 플레이어 board/resources를 보고 이미 telegraphed action을 몰래 교체하지 않는다.
- generative enemy action은 현재 authored intent ladder를 대체하지 않는다.
- AI solver/optimal move 추천은 현재 Player Value가 아니므로 도입하지 않는다.

## 다음 Codex/QA 소비

1. production Line/Chain/turn implementation 전 owner map + omission checklist.
2. deterministic timeout/settle/READY/Tempo regression.
3. representative boss에서 per-turn telemetry 수집.
4. Human play에서 “무엇을 준비했고 왜 이 Skill을 골랐는가” 설명 가능 여부 확인.
5. player promise failure만 구조 재설계로 승격.

## IRG

현재 주장 가능: AI-assisted production과 feedback Gate가 production canon을 침범하지 않도록 정의됨.

현재 주장 불가: Production Line/Chain/turn engine 구현 완료, Human production playtest PASS, 최종 phase time/Tempo balance 확정.

## 적대적 검토 5회

1. dual-board 과거 구조 부활 없음: PASS.
2. RNG/AI novelty 추가 없음: PASS.
3. puzzle/combat/time owner 분리 보존: PASS.
4. Human evidence 전 breadth 차단: PASS.
5. Foundation Green을 production PASS로 오인하지 않음: PASS.

`CLEAN_REVIEW_EXIT`.
