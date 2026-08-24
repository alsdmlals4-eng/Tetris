# Tetris project work rules

## Canon

Read current production gameplay in this order:

1. `docs/design/PRODUCTION_TURN_TIME_CANON.md` — current player-turn timing / modifier / timeout / Tempo authority (`TETRIS-TIME-025`).
2. `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` — current ordered combat turn and non-timing production authority (`TETRIS-CORE-024`).
3. `docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md` — current Vanguard `ATK / DEF / SUP × Tier 1–6` Technique identity / tactical commitment / dominance guard authority (`TETRIS-SKILL-026`).
4. `docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md` — current Line Energy / Chain Stock opportunity cost, Tier exposure, anti-hoarding/spam, curated economy scenario and evidence boundary (`TETRIS-BALANCE-027`).
5. Latest USER_APPROVED project Decisions in GitHub Issue #10 and synced Notion owner pages.
6. `docs/superpowers/plans/2026-08-21-shared-turn-budget-tempo.md` — timing implementation handoff. **Do not execute until the explicit BUILD gate in that plan is satisfied.**
7. `docs/superpowers/plans/2026-08-21-phased-turn-production-vertical-slice.md` — broader production implementation plan except timing clauses superseded by `TETRIS-TIME-025`. **Do not execute until its BUILD gate is satisfied.**
8. `docs/superpowers/plans/2026-08-24-vanguard-tactical-tier-matrix.md` — SKILL-026 implementation handoff; economy tuning must also satisfy `TETRIS-BALANCE-027`. **Do not execute until its BUILD gate is satisfied.**
9. Actual code/data/scenes/tests/runtime evidence.

Machine-readable routing authority: `docs/design/PRODUCTION_CANON_INDEX.json`.

## DOMAIN_SPLIT_CANON

- `NOTION_HUMAN_FACING_CANON`: synced project owner pages, 사람이 읽고 비교·수정하는 전체 그림, Flow/Storyboard, visual/asset/reference surface와 사람용 표를 책임진다.
- `REPOSITORY_STRUCTURED_CANON`: `PRODUCTION_CANON_INDEX.json`, production canon 문서, data/code/scenes/resources/config/tests를 책임진다.
- `REPOSITORY_RUNTIME_TRUTH`: 실제 Godot build/runtime/test/log/screenshot-video evidence를 책임진다.
- Google Sheets가 과거 자료로 남아 있더라도 unique 미이관 자료를 위한 `MIGRATION_ONLY_UNTIL_REMOVAL` compatibility source일 뿐 신규 기본 작업공간이나 runtime 증거가 아니다.

Notion의 승인·정적 시각 자료와 repository runtime PASS를 혼동하지 않는다. 사람이 읽는 기획 변경이 structured/runtime 의미를 바꾸면 repository owner와 동기화한 뒤 구현·완료를 주장한다.

Historical Core POC authorities:

- `docs/design/CORE_GAMEPLAY_GDD.md`
- `docs/design/POC_RULESET_V0_1.md`
- `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- `docs/validation/POC_45S_VALIDATION.md`

These historical files and the merged PR #3 code/tests are **Core Combat Foundation / Engineering Harness evidence**. They do not override newer production Decisions.

Core terminology: HP, Energy, Line, Chain, Chain Stock, Skill, Skill Tier, Score, Turn, Phase, Enemy Telegraph, Shared Turn Budget, Tempo Bonus.
Do not introduce `Mana`, `Magic`, or `Spell` as core-system terminology.

## Runtime and testing

- Runtime implementation path: Godot 4.x + GDScript.
- Canonical REMOTE_CI pin for the existing Core Foundation: Godot `4.7.1-stable` and GUT `9.7.1`.
- The dedicated Tetris Windows Godot path recorded by the project binding is separate from CI evidence; do not claim user-local runtime PASS without a live receipt.
- Persistent Godot authoring automation follows Base's HiGodot single-authority policy.
- Deterministic GDScript behavior changes follow test-first RED → GREEN → regression verification.
- Git is repository change truth. Do not claim import, test, runtime, render, or play validation unless the evidence was actually produced.
- Foundation regression tests and future Production regression tests must remain distinguishable. A green Foundation suite does not prove the latest Production canon.

## Current production gameplay invariants

- One turn is `Enemy Telegraph → Line Phase → Line Settle → Chain Phase → Chain Settle → Action Phase → Player Action → Enemy Action`.
- Line Phase is the Energy-preparation phase.
- Chain is production **Swap-Match**, not Puyo-style falling-pair gameplay.
- Chain Phase is the Chain Stock / Tier-preparation phase.
- Current production Skill layout is Attack / Defense / Support × Tier 1–6.
- `TETRIS-SKILL-026`: Tier는 절대적인 강함 순서가 아니라 **Chain Stock commitment / tactical band**다. 낮은 Tier의 효율·가벼운 대응과 중·고Tier의 setup/control/signature가 공존해야 하며 `가능하면 최고 Tier`가 기본 최적해가 되면 실패다.
- Tier별 player-facing Technique identity는 달라도 되지만 runtime은 공통 data-driven effect primitive를 조합하며 18 bespoke subsystem/script를 만들지 않는다.
- `TETRIS-BALANCE-027`: **Line Energy와 Chain Stock은 서로 대체 불가한 이중 기회비용 자원**이다. Energy는 Technique의 유연한 throughput/utility 가격, Stock은 Tier 접근권/커밋 비용이며 Tier N은 Stock N을 소비한다.
- Production Chain Stock cap은 6을 기준으로 한다. cap 근처 hoarding은 추가 Stock gain 낭비 위험을 가지며 T6는 routine 버튼이 아니라 signature commitment 후보여야 한다.
- 첫 tutorial Turn은 숨은 무료 지급 대신 실제 production Line/Chain board의 authored seed로 의미 있는 Energy/Stock 성과를 만들고 T1을 자연스럽게 노출한다. 첫 2–3 Turn에서 T6 도달을 tutorial 목표로 만들지 않는다.
- Energy exact gain/cost/effect values와 Tier pick 분포는 `TUNE_REQUIRED`; automated simulation은 impossible state/명백한 dominance만 판정하며 최종 밸런스·재미·이해도는 Human evidence가 필요하다.
- Line / Chain / Action share **one data-driven player-turn time budget**; there is no independent timer reset at phase boundaries.
- Enemy Telegraph, forced Line/Chain settle, forced animation/transition, Enemy Resolve, and System Pause do not consume player budget.
- A legal `READY` action may end Line/Chain early and carries the remaining shared budget into the next player stage.
- Action confirmation freezes the remaining budget and ends player timing.
- Unused time does not bank into future turns. Qualified fast completion may earn `Tempo Bonus` for the current selected action plus non-currency Tempo score.
- Time modifiers from difficulty/items/equipment/Support/status/encounter effects change **Effective Budget** through one snapshot pipeline. They do not change the separate **Tempo Reference** used for speed reward.
- Haste/Slow normally apply at the next eligible turn snapshot rather than changing a visible current-turn clock mid-phase.
- If shared time expires during Line or Chain, finish only deterministic settle work, skip remaining player-input stages, resolve `PASS`, and continue; Action timeout also resolves `PASS`.
- Tempo requires meaningful Line + Chain qualification, a legal non-PASS action, no timeout, and first-slice no Board Break.
- Tempo does not directly grant Energy or Chain Stock in the first production baseline.
- When Chain input closes, no new swap may begin, but an already-triggered cascade settles to a deterministic stable board before later resolution.
- Player Action resolves before the telegraphed enemy Action.
- Normal production combat no longer uses a continuously advancing enemy Combat Clock or tactical RUN/LOCK as its core turn structure.
- Score is performance evidence and never becomes a Skill currency.
- Line/Chain board state and unspent resources persist across turns unless Board Break, spending, or an explicit enemy/system effect changes them.
- System Pause is the ordinary full-simulation pause.

## Core Foundation / Engineering Harness boundary

- Existing debug Line/Chain event sources, `RUNNING/LOCKED/SUSPENDED` tests, 45-second validation flow, and Core POC scene are preserved as historical Engineering Harness behavior.
- Do not present debug event sources as proof of production Line/Chain puzzle feel, production phased-turn behavior, shared-budget/Tempo behavior, tactical Tier viability, dual-resource balance, or human decision quality.
- Do not rewrite old PASS evidence to match new production rules.
- Production Line/Chain/turn/time/skill/economy systems require new tests and runtime evidence.

## Production scope boundary

- First player milestone remains a production-quality representative Vertical Slice, not a debug/system-only POC.
- Production Line and Chain engines own puzzle rules/state only; combat resources, turn sequencing, shared time budget, enemy action state, Tempo evaluation, Skill execution and resource economy remain outside puzzle/UI code.
- Production UI must express `LINE / CHAIN / ACTION / ENEMY` phase ownership directly, plus one continuous shared player-turn clock, rather than reusing Foundation state labels as the main player-facing model.
- Exact balance values remain data-driven and evidence-tuned unless a newer approved Decision locks them.
- AoE/target-pattern support may exist in the skill schema, but first Slice remains one Vanguard + one Gatebreaker; do not add a mob roster merely to prove AoE.
- Do not add Technique-specific currencies/cooldowns, extra classes, bosses or biomes before representative-Slice evidence justifies the breadth.

## Cost and change safety

- No additional paid dependency, API, runner, SaaS, marketplace credit, GPU/larger runner, or separately metered service without explicit user approval.
- Standard GitHub-hosted runner use is allowed only while it remains a zero-incremental-cost path for this public repository.
- Do not overwrite unrelated user changes.
- Current `open/draft/ready` PRs are read-only unless the latest user instruction and current Base continuation rules explicitly authorize the exact PR/action. Do not hard-code a historical PR number as permanently protected; query live GitHub PR state at work start.
- Keep implementation work isolated from `main` until its PR is verified and approved.
- Before completion, compare the work branch against `main` and report verified, unverified, and remaining-risk states separately.
