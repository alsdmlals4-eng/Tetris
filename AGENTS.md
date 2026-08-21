# Tetris project work rules

## Canon

- Gameplay canon: `docs/design/CORE_GAMEPLAY_GDD.md` and `docs/design/POC_RULESET_V0_1.md`.
- Implementation plan: `docs/superpowers/plans/2026-08-19-core-dual-board-poc.md`.
- Core terminology: HP, Energy, Chain, Chain Stock, Skill, Skill Tier, Combo, Score.
- Do not introduce `Mana`, `Magic`, or `Spell` as core-system terminology.

## Runtime and testing

- Runtime implementation path: Godot 4.x + GDScript.
- Canonical REMOTE_CI pin for the Core POC: Godot `4.7.1-stable` and GUT `9.7.1`.
- The user's Windows-local Godot version is currently `UNVERIFIED`; do not infer it from REMOTE_CI.
- If local Godot differs from 4.7.x, verify current official GUT compatibility before running or changing the pin.
- Persistent Godot authoring automation follows Base's HiGodot single-authority policy.
- Deterministic GDScript changes follow test-first RED → GREEN → regression verification.
- Git is repository change truth. Do not claim import, test, runtime, render, or play validation unless the evidence was actually produced.

## Core gameplay invariants

- Line and Chain are separate persistent modes.
- Only the active mode may be `RUNNING`; the inactive mode is `SUSPENDED` and must not advance.
- Switching modes lands on the destination as `LOCKED`; the player must explicitly choose `RUN`.
- `LOCKED` freezes puzzle/event progression only. It never pauses the global Combat Clock.
- Line Clear produces Energy.
- Completed N-Chain updates Chain Stock with `max(current_stock, min(N, 5))`; repeated low Chains are not additive.
- Tier-N Skill requires sufficient Energy and `Chain Stock >= N`; successful activation consumes configured Energy and exactly N Stock.
- Score is performance evidence and never becomes a Skill currency.
- Attack / Defense / Heal are class-agnostic combat roles; later classes may express them differently.

## Core POC scope

- First Core POC may use deterministic replaceable Line/Chain event sources.
- Do not present debug event sources as proof of production Line/Chain puzzle feel or balance.
- Do not implement production tetromino rotation/kicks, Puyo-style pair controls, final top-out behavior, equipment, class progression, PvP, production art, or mobile controls in this POC.
- Production Line and Chain engines must attach through the event-source boundary instead of moving resource/combat mutations into puzzle or UI code.

## Cost and change safety

- No additional paid dependency, API, runner, SaaS, marketplace credit, GPU/larger runner, or separately metered service without explicit user approval.
- Standard GitHub-hosted runner use is allowed only while it remains a zero-incremental-cost path for this public repository.
- Do not overwrite unrelated user changes.
- Keep implementation work isolated from `main` until its PR is verified and approved.
- Before completion, compare the implementation branch against `main` and report verified, unverified, and remaining-risk states separately.
