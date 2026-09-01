# Tetris · Base-adapted project operation contract

- Status: `CURRENT_PROJECT_ADAPTED_OPERATION_CONTRACT`
- Machine owner: [`TETRIS_PROJECT_OPERATION_CONTRACT.json`](TETRIS_PROJECT_OPERATION_CONTRACT.json)
- Current project machine routing: [`../design/PRODUCTION_CANON_INDEX.json`](../design/PRODUCTION_CANON_INDEX.json)
- Current implementation sequence: [`../superpowers/plans/2026-08-29-phase2-tactical-core-alignment.md`](../superpowers/plans/2026-08-29-phase2-tactical-core-alignment.md)
- Historical plan retained for provenance only: [`../superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md`](../superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md)

## Direction anchor

Use the current Base operating model as a reusable safety and evidence framework, while keeping `TETRIS-CORE-029` and the repository-owned Tetris canon authoritative for product behavior. Restore one current work route without copying Base Skill bodies, silently downgrading Base, or changing approved gameplay, visual, asset or runtime behavior.

## What this changes

This contract makes the machine-readable JSON the project-owned owner for the following operating facts:

- Base was fresh-read at its observed `origin/main` revision `19355b7ef065a21d0f2b685c7d9be64a4a3970f8`.
- Tetris was fresh-read at `codex/tetris-phase2-runtime-resume` observed head `78903ef475e840f5b891dc6faf593784dfd71af1` with `origin/main` at `5df7d359b89074c7997b6f9b155c064a311db217`.
- The active Phase 2 execution plan is the 2026-08-29 plan. The 2026-08-26 plan remains a retained implementation-provenance record, not an entry route.
- The project follows Base principles through project references: repository-first canon, fresh read, bounded continuous work, evidence-class separation, consumer-first assets, read-only unrelated PRs, and exact destination readback.
- The formal Base `PROJECT_BASE_ADAPTER` is **not installed**. Its precise conditions and re-entry criteria are recorded in the machine contract rather than faked with a copied or stale adapter.

## Project-specific adaptation

Base governs how evidence and work are handled; Tetris governs what the game is. The active project canon is therefore not replaced.

| Base principle | Tetris adaptation |
| --- | --- |
| Current repository and exact evidence are the primary source | `AGENTS.md` and `PRODUCTION_CANON_INDEX.json` route to `TETRIS-CORE-029`, its skill/chain/onboarding/image owners, then actual Godot evidence. |
| Material product changes require fresh intake, feasible scope, review and exact readback | A Tetris Godot change also follows the project evidence gate, checks the actual worktree/editor identity, and protects the current 50/50 Line/Chain-versus-combat composition. |
| Continuous work continues within an approved contract | The standing user direction removes routine plan approval only. New product meaning, destructive changes, paid routes, public surface and final Human UX remain separate decisions. |
| Machine, runtime, Human and release evidence are distinct | Passing a tooling test or a document route does not prove the live Godot scene, player comprehension, accessibility, device behavior, balance or release readiness. |
| Reuse before new construction | This document-only route correction uses the existing Base and Tetris owners. A non-mechanical feature, UI, system, asset, tool or dependency change must run its own reuse-first preflight. |

## Current work order

1. **O0 — route refresh (this change):** make the machine index, human entrypoints and workspace handoff name the same current Phase 2 plan and project operation contract.
2. **O1 — formal Base adapter:** deferred as `BLOCKED_UNVERIFIED`; do not manufacture `skills/PROJECT_BASE_ADAPTER.json` until the recorded baseline policy and checker-version prerequisites are genuinely met.
3. **O2 — product work:** for a later gameplay, Godot, UX, visual, asset, dependency or data change, start with the active Tetris canon and fresh current implementation/PR read, then use the required reuse-first and evidence gates.
4. **O3 — machine/runtime review:** after a product change, validate the exact head with deterministic tests, import/parse and relevant runtime evidence. This is not run merely because a document changed.
5. **O4 — Human acceptance:** retain the first-exposure, device, accessibility, balance and final UX gates as `NOT_RUN` until real evidence exists.

## Formal adapter boundary

The current Base adapter checker needs an existing protected-path policy source from the target baseline, but Tetris `origin/main` has neither that JSON policy source nor a pre-existing formal adapter. Base’s current documentation is in the v9.4.4 family, while the observed checker only recognizes v9.1.0–v9.3.0 release locks. Installing a pretend v9.4 adapter or silently pinning the project to v9.3 would both make the contract less trustworthy.

The safe route is to keep the thin project owner above current, then resume the formal-adapter task only when:

1. a versioned first-migration protected-path source exists on the target baseline (or a separately approved migration source is provided);
2. the exact selected Base checker supports the selected current release-lock family; and
3. a fresh isolated branch is created for that explicit bootstrap task and validates at its exact revision.

## Scope and evidence ceiling

This is a `NONCODING_BUILD` operational route correction. It intentionally uses `MECHANICAL_NO_EXTERNAL_DEPENDENCY`: external research cannot change which already-existing Base/Tetris owners are current, nor remove the observed adapter preconditions. It changes no Godot scene, GDScript, resource, asset, balance, Chain rule, Skill rule, title, shared-ETA presentation, board layout or player-facing visual.

For this task, the relevant evidence is contract test, tooling test, static diff/readback and remote branch readback. Godot runtime, Human/player UX, device, release, economy and formal Base adapter validation remain separate and are not upgraded by this document.

## Protected items and rollback

- Preserve the pre-existing, unowned change in `resources/production/production_battle_theme.tres`.
- Treat open/draft PRs #46, #33, #23 and #19 as read-only parallel work.
- Do not touch Base worktree artifacts or remove assets/files outside the named project paths.
- Roll back only by reverting this contract-routing commit; never reset, clean, force-push or discard unrelated user work.
