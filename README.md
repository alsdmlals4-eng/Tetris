# Tetris Project

퍼즐 전투 게임 프로젝트 저장소.

## 현재 Production 방향

현재 production combat authority는 `TETRIS-CORE-029 · Continuous Real-Time Mode-Switch Combat + Full Tactical Pause`입니다.

```text
BATTLE_START
→ COMBAT_RUNNING
   ↔ LINE workspace
   ↔ CHAIN workspace
   ↔ SKILL / TACTICAL_PAUSE_SKILL
→ VICTORY | DEFEAT
```

핵심 원칙:

- 전투는 시작부터 승리/패배까지 실시간으로 계속 진행됩니다.
- 플레이어와 적은 같은 combat timeline을 공유하며 교대식 player/enemy turn은 없습니다.
- 화면 왼쪽 약 60%는 **하나의 큰 Puzzle Surface**, 오른쪽 약 40%는 persistent Combat/Threat/Resource/Skill surface입니다.
- 플레이어는 `LINE ↔ CHAIN`을 자유롭게 전환합니다.
- LINE과 CHAIN은 서로 독립적인 persistent workspace입니다. 전환해도 보드/queue/randomizer/진행상태를 새로 만들지 않습니다.
- LINE은 **MP** 회복을 담당합니다. 현재 구현 내부 필드명은 `energy`입니다.
- CHAIN은 상하좌우 인접 교환 뒤 가로·세로·양쪽 대각선의 직선 3칸 이상을 판정합니다. 해소 단계마다 **Combo +1** 뒤 `(최대 직선 길이 합 − 3) + 현재 Combo`만큼 MP를 회복하며, Combo는 Tier와 CHAIN MP 회복이 공유하는 자원입니다. 현재 구현 내부 필드명은 `stock`입니다.
- 매치가 없는 교환은 원상복귀하고 Combo를 0으로 만듭니다. 플레이어는 고정 **1 MP**를 써서 그 배치를 다음 설계용으로 남길 수 있으나, 이 선택도 Combo를 0으로 만들며 즉시 Combo/MP 보상을 주지 않습니다.
- MP와 Combo는 서로 대체되지 않습니다. Combo 상한은 **10**이며 Tier N은 Combo N을 소비해 이후 CHAIN MP 회복도 낮아지는 구조를 유지합니다.
- 위 CHAIN 대각선/MP-lock 규칙은 사용자 승인 정본이며, 현재 merged runtime은 가로·세로 판정과 기본 원상복귀만 구현했습니다. Phase 2 구현 검토 전에는 runtime 완료로 해석하지 않습니다.
- `ATK / DEF / SUP × T1–T6` Technique identity는 유지하지만 Tier는 단순한 강함 순서가 아니라 tactical commitment band입니다.
- 적의 Current Telegraph + ETA는 LINE/CHAIN 플레이 중 실시간으로 진행됩니다. 알려진 Next Forecast는 더 낮은 우선순위로 표시합니다.
- `SKILL`을 열면 `TACTICAL_PAUSE_SKILL`이 되어 **시뮬레이션 전체가 완전히 정지**합니다.
- Skill에서는 `ATK / DEF / SUP → 선택 lane T1–T6 → 상세 → 별도 USE`로 판단합니다.
- Technique 행 선택은 자원을 쓰지 않으며, **USE만 commit point**입니다.
- 취소 또는 USE 후에는 정확히 멈춘 combat time과 이전 active puzzle workspace로 복귀합니다.
- 수동 Pause도 full simulation pause이지만 Skill tactical pause와 player-facing state/telemetry reason은 구분합니다.
- Haste, Battle Trance, turn-only status duration, Tempo scaling은 `REALTIME_MIGRATION_REQUIRED`이며 임의로 seconds 의미로 번역하지 않습니다.
- CHAIN MP/Combo 구조와 MP-lock 비용은 승인됐지만, 정확한 밸런스 곡선, 적 cadence, effect magnitude는 `TUNE_REQUIRED / TUNING_SEED_NOT_FINAL`입니다.
- 자동 테스트는 deterministic legality/regression을 증명할 수 있지만 재미·가독성·처음 이해도·최종 밸런스는 Human evidence가 필요합니다.

## 현재 Production 정본

1. `docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md` — CORE-029 current combat authority.
2. `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md` — retained SKILL-026 Technique identity, subject to realtime migration boundaries.
3. `docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md` — retained BALANCE-027 MP/Combo/Tier structure.
4. `docs/design/CHAIN_COMBO_MP_CONTRACT.md` — `TETRIS-CHAIN-038`, CHAIN rule and MP-lock contract.
5. `docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md` — `TETRIS-IMAGE-030`, runtime-consumer-first image production.
6. `docs/design/PRODUCTION_CANON_INDEX.json` — machine-readable routing authority.
7. `docs/superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md` — current implementation plan, requiring a `TETRIS-CHAIN-038` Phase 2 amendment before Godot work.

Historical provenance:

- `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` — CORE-024 ordered-turn history.
- `docs/design/PRODUCTION_TURN_TIME_CANON.md` — TIME-025 Shared Turn Budget history.
- `docs/design/CORE_GAMEPLAY_GDD.md`, `POC_RULESET_V0_1.md`, PR #3 — Core Combat Foundation / Engineering Harness.

Historical PASS evidence remains historical; it is not relabeled as CORE-029 runtime evidence.

## 이미지 제작 원칙

Production 이미지는 설명용 시트가 아니라 **실제 Godot 소비처가 있는 asset**만 만듭니다.

이미지 생성 전에 반드시 다음을 고정합니다.

```text
res:// target asset path
consumer scene
consumer node / material / UI slot
required size / aspect
alpha / crop / anchor
Godot import / use mode
```

소비처가 없으면 production image를 생성하지 않습니다.

따라서 Battle UI concept sheet, character master/pose explanation sheet, combined UI sheet, generic mood/reference sheet는 runtime이 그 파일 자체를 직접 소비하지 않는 한 production backlog가 아닙니다. Sprite atlas도 실제 runtime이 해당 atlas를 소비할 때만 허용합니다.

CORE-029 baseline에는 `TETRIS-IMG-031` StageBackdrop이라는 실제 runtime consumer가 main에 구현되어 있습니다. 신규 이미지 생성은 별도 승인 범위가 구체적인 consumer gap을 지정할 때까지 **PAUSED**이며, 기존 승인 reference는 자동으로 runtime asset이 되지 않습니다.

## 현재 구현 경계

- Core Combat Foundation / Engineering Harness: **main에 존재**.
- CORE-029 written canon/spec/implementation plan: **main 구현과 함께 유지**.
- CORE-029 Production runtime: **main에 구현됨**; `AUTOMATED_VERTICAL_SLICE_READY` 근거는 runtime baseline main `1a5c5aab84d7b6e11c3a4431a71eecb27b0ea55a`와 tree-equivalent인 source head `92b59bccd2ea45f772003b4abac2d9aa84672307`의 CI/runtime 증거입니다. 이 문서 정정 PR의 기준 main은 `fb55b96f2612497f356bae6586429b944d35d7a8`이며, 별도 main-commit runtime 영수증은 아직 없습니다.
- Draft PR #19 ordered-turn implementation: **READ_ONLY source snapshot**, wholesale merge/cherry-pick 금지.
- Production Line/Chain reusable deterministic components, full tactical pause runtime, realtime enemy scheduler, persistent workspace manager, 60/40 production scene: **main에 구현됨**.
- CORE-029 runtime-consumed image assets: `TETRIS-IMG-031` StageBackdrop이 main에서 소비됩니다. Draft PR #33의 Gatebreaker composition은 branch-only evidence이며 병합 전 main 사실을 바꾸지 않습니다.
- 사용자 Windows Production runtime / first-exposure Human playtest: **NOT_RUN**.

## Human evidence

Human validation contract:

`docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md`

첫 대표 Slice는 real-time threat readability, LINE↔CHAIN switching comprehension, workspace-state persistence, Skill tactical-pause comprehension, MP vs Combo와 MP-lock 이해, Technique decision quality, 60/40 layout readability, player experience signal을 검증합니다.

Positive directional PASS는 세 개의 독립 first-exposure A/B/C receipt가 필요합니다. Concept art나 자동 test를 Human readability/fun evidence로 승격하지 않습니다.

## Windows Core Foundation 로컬 검증

기존 Core Foundation을 사용자 Windows PC에서 검증할 때 저장소 루트의 `RUN_LOCAL_VALIDATION.cmd`를 사용할 수 있습니다. 이 검증은 Historical Engineering Harness evidence이며 CORE-029 gameplay validation으로 승격하지 않습니다.

Canonical CI pins:

- Godot `4.7.1-stable`
- GUT `9.7.1`

Runtime / Human evidence는 실제 실행 receipt 없이 PASS로 주장하지 않습니다.
