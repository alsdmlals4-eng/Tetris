# Tetris project work rules

## Canon

Read current production gameplay in this order:

1. `docs/design/PRODUCTION_TURN_TIME_CANON.md` — current player-turn timing / modifier / timeout / Tempo authority (`TETRIS-TIME-025`).
2. `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` — current ordered combat turn and non-timing production authority (`TETRIS-CORE-024`).
3. Latest USER_APPROVED project Decisions in GitHub Issue #10 and synced Notion owner pages.
4. `docs/superpowers/plans/2026-08-21-shared-turn-budget-tempo.md` — timing implementation handoff. **Do not execute until the explicit BUILD gate in that plan is satisfied.**
5. `docs/superpowers/plans/2026-08-21-phased-turn-production-vertical-slice.md` — broader production implementation plan except timing clauses superseded by `TETRIS-TIME-025`. **Do not execute until its BUILD gate is satisfied.**
6. Actual code/data/scenes/tests/runtime evidence.

Machine-readable routing authority: `docs/design/PRODUCTION_CANON_INDEX.json`.

## DOMAIN_SPLIT_CANON

- `NOTION_HUMAN_FACING_CANON`: synced project owner pages, 사람이 읽고 비교·수정하는 전체 그림, Flow/Storyboard, visual/asset/reference surface와 사람용 표를 책임진다.
- `REPOSITORY_STRUCTURED_CANON`: `PRODUCTION_CANON_INDEX.json`, production canon 문서, data/code/scenes/resources/config/tests를 책임진다.
- `REPOSITORY_RUNTIME_TRUTH`: 실제 Godot build/runtime/test/log/screenshot-video evidence를 책임진다.
- Google Sheets가 과거 자료로 남아 있더라도 unique 미이관 자료를 위한 `MIGRATION_ONLY_UNTIL_REMOVAL` compatibility source일 뿐 신규 기본 작업공간이나 runtime 증거가 아니다.

Notion의 승인·정적 시각 자료와 repository runtime PASS를 혼동하지 않는다. 사람용 기획 변경이 structured/runtime 의미를 바꾸면 repository owner와 동기화한 뒤 구현·완료를 주장한다.

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
- Line / Chain / Action share **one data-driven player-turn time budget**; there is no independent timer reset at phase boundaries.
- Enemy Telegraph, forced Line/Chain settle, forced animation/transition, Enemy Resolve, and System Pause do not consume player budget.
- A legal `READY` action may end Line/Chain early and carries the remaining shared budget into the next player stage.
- Action confirmation freezes the remaining budget and ends player timing.
- Unused time does not bank into future turns. Qualified fast completion may earn `Tempo Bonus` for the current selected action plus non-currency Tempo score.
- Time modifiers from difficulty/items/equipment/Support/status/encounter effects change **Effective Budget** through one snapshot pipeline. They do not change the separate **Tempo Reference** used for speed reward.
- Haste/Slow normally apply at the next eligible turn snapshot rather than changing a visible current-turn clock mid-phase.
- If shared time expires during Line or Chain, finish only deterministic settle work, skip remaining player-input stages, resolve `PASS`, and continue; Action timeout also resolves `PASS`.
- Tempo requires meaningful Line + Chain qualification, a legal non-PASS action, no timeout, and first-slice no Board Break.
- When Chain input closes, no new swap may begin, but an already-triggered cascade settles to a deterministic stable board before later resolution.
- Player Action resolves before the telegraphed enemy Action.
- Normal production combat no longer uses a continuously advancing enemy Combat Clock or tactical RUN/LOCK as its core turn structure.
- Score is performance evidence and never becomes a Skill currency.
- Line/Chain board state and unspent resources persist across turns unless Board Break, spending, or an explicit enemy/system effect changes them.
- System Pause is the ordinary full-simulation pause.

## Core Foundation / Engineering Harness boundary

- Existing debug Line/Chain event sources, `RUNNING/LOCKED/SUSPENDED` tests, 45-second validation flow, and Core POC scene are preserved as historical Engineering Harness behavior.
- Do not present debug event sources as proof of production Line/Chain puzzle feel, production phased-turn behavior, shared-budget/Tempo behavior, or balance.
- Do not rewrite old PASS evidence to match new production rules.
- Production Line/Chain/turn/time systems require new tests and runtime evidence.

## Production scope boundary

- First player milestone remains a production-quality representative Vertical Slice, not a debug/system-only POC.
- Production Line and Chain engines own puzzle rules/state only; combat resources, turn sequencing, shared time budget, enemy action state, Tempo evaluation, and Skill execution remain outside puzzle/UI code.
- Production UI must express `LINE / CHAIN / ACTION / ENEMY` phase ownership directly, plus one continuous shared player-turn clock, rather than reusing Foundation state labels as the main player-facing model.
- Exact balance values remain data-driven and evidence-tuned unless a newer approved Decision locks them.

## Cost and change safety

- No additional paid dependency, API, runner, SaaS, marketplace credit, GPU/larger runner, or separately metered service without explicit user approval.
- Standard GitHub-hosted runner use is allowed only while it remains a zero-incremental-cost path for this public repository.
- Do not overwrite unrelated user changes.
- Current `open/draft/ready` PRs are read-only unless the latest user instruction and current Base continuation rules explicitly authorize the exact PR/action. Do not hard-code a historical PR number as permanently protected; query live GitHub PR state at work start.
- Keep implementation work isolated from `main` until its PR is verified and approved.
- Before completion, compare the work branch against `main` and report verified, unverified, and remaining-risk states separately.
