# 승인 전투 화면 구성 설계

## 목표

승인된 `IMG-P0-001`의 퍼즐/전투 정보 계층을 960×540 Godot 실행 화면에 적용한다. 화면은 장식용 시안이 아니라, 현재 CORE-029 실시간 전투와 실제 조작이 계속 동작하는 게임 표면이어야 한다.

## 플레이어 경험

- 왼쪽에서 현재 퍼즐, HOLD/NEXT, 조작 안내를 즉시 읽고 LINE/CHAIN/전술 스킬로 이동한다.
- 오른쪽에서 Gatebreaker의 위협, 남은 ETA, 플레이어 자원, 현재 전술 pause 상태를 한 화면에서 읽는다.
- 전술 pause 중에는 ATK/DEF/SUP의 각 T1–T6를 바로 눌러 기존 스킬 선택과 USE로 이어간다.

## 범위

- `CombatStage/BossReference`가 사용자 승인 원본 `IMG-P0-003`의 AtlasTexture 영역만 장식 레이어로 소비한다.
- `BossReadout`은 실제 enemy HP와 ETA를 반영한다.
- `ThreatTimeline`은 기존 Current/Next realtime authored data만 표시한다. 존재하지 않는 행동 순서를 만들지 않는다.
- `SkillMatrix`는 3행×6열의 실제 버튼으로 기존 `select_skill_category`와 `select_skill_tier`를 호출한다.
- 기존 가로 카테고리/3열 tier 컨트롤은 중복 조작을 만들지 않도록 행 매트릭스로 대체한다.

## 제외

- 두 번째 활성 퍼즐 보드, Match-3 사이드보드, 신규 전투 규칙/스킬/이미지 생성.
- PR #19 또는 다른 열린 PR 변경.
- 사람 플레이 검증 완료 주장.

## 수용 기준

- 960×540에서 보스 제목/HP, 보스 실루엣, current/next 위협, 자원, 3×6 스킬 행, USE가 잘리지 않고 함께 보인다.
- 18개 매트릭스 버튼은 pause 중에만 기존 선택 경로를 실행한다.
- `BossReference`는 입력을 가로채지 않으며 source/atlas region/소비 노드가 문서화된다.
- UI 장면 테스트, 전체 GUT, parse/import, 실제 Godot 런타임 스크린샷이 통과한다. 사람 검증은 `NOT_RUN`으로 남긴다.
