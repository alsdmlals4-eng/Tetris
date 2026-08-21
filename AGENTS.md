# Tetris project work rules

## Canon

Read current production gameplay in this order:

1. `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` — current production turn/phase authority.
2. Latest USER_APPROVED project Decisions in GitHub Issue #10 and synced Notion owner pages.
3. `docs/superpowers/plans/2026-08-21-phased-turn-production-vertical-slice.md` — current production implementation plan. **Do not execute it until the explicit BUILD gate in that plan is satisfied.**
4. Actual code/data/scenes/tests/runtime evidence.

Machine-readable routing authority: `docs/design/PRODUCTION_CANON_INDEX.json`.

Historical Core POC authorities:

- `docs/design/CORE_GAMEPLAY_GDD.md`
- `docs/design/POC_RULESET_V0_1.md`
- `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`
- `docs/validation/POC_45S_VALIDATION.md`

These historical files and the merged PR #3 code/tests are **Core Combat Foundation / Engineering Harness evidence**. They do not override newer production Decisions.

Core terminology: HP, Energy, Line, Chain, Chain Stock, Skill, Skill Tier, Score, Turn, Phase, Enemy Telegraph.
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
- Player-facing puzzle/action phases use independent data-driven timers. Current first-slice candidate maximum is 30 seconds per Line / Chain / Action phase.
- A legal early-finish action may end a phase before its maximum; unused time is not banked.
- When Chain input time ends, no new swap may begin, but an already-triggered cascade settles to a deterministic stable board before Action Phase.
- Player Action resolves before the telegraphed enemy Action.
- If Action timer expires without a legal selection, resolve `PASS` and continue; do not deadlock.
- Normal production combat no longer uses a continuously advancing enemy Combat Clock or tactical RUN/LOCK as its core turn structure.
- Score is performance evidence and never becomes a Skill currency.
- Line/Chain board state and unspent resources persist across turns unless Board Break, spending, or an explicit enemy/system effect changes them.
- System Pause is the ordinary full-simulation pause.

## Core Foundation / Engineering Harness boundary

- Existing debug Line/Chain event sources, `RUNNING/LOCKED/SUSPENDED` tests, 45-second validation flow, and Core POC scene are preserved as historical Engineering Harness behavior.
- Do not present debug event sources as proof of production Line/Chain puzzle feel, production phased-turn behavior, or balance.
- Do not rewrite old PASS evidence to match new production rules.
- Production Line/Chain/turn systems require new tests and runtime evidence.

## Production scope boundary

- First player milestone remains a production-quality representative Vertical Slice, not a debug/system-only POC.
- Production Line and Chain engines own puzzle rules/state only; combat resources, turn sequencing, enemy action state and Skill execution remain outside puzzle/UI code.
- Production UI must express `LINE / CHAIN / ACTION / ENEMY` phase ownership directly rather than reusing Foundation state labels as the main player-facing model.
- Exact balance values remain data-driven and evidence-tuned unless a newer approved Decision locks them.

## Cost and change safety

- No additional paid dependency, API, runner, SaaS, marketplace credit, GPU/larger runner, or separately metered service without explicit user approval.
- Standard GitHub-hosted runner use is allowed only while it remains a zero-incremental-cost path for this public repository.
- Do not overwrite unrelated user changes.
- Open/draft/ready PRs are read-only unless the user explicitly names a PR number and allowed mutation. PR #9 remains protected by default.
- Keep implementation work isolated from `main` until its PR is verified and approved.
- Before completion, compare the work branch against `main` and report verified, unverified, and remaining-risk states separately.
