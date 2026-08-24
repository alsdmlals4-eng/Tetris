# Vertical Slice Human Evidence Gate Plan

> **For execution:** use test-first RED → GREEN → verification, preserve evidence classes, and keep open Draft Production BUILD work read-only.

## Goal

Make the first 6–10 minute representative Vertical Slice testable as a player experience before any claim about fun, readability, tactical comprehension, memorable payoff, or final balance is promoted.

## Architecture

Keep Human validation routing separate from gameplay canon routing:

- `docs/design/PRODUCTION_CANON_INDEX.json` continues to route current gameplay authority.
- `docs/validation/PRODUCTION_HUMAN_EVIDENCE_INDEX.json` routes Human evidence state and dimensions.
- `docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md` owns the qualitative playtest procedure and evidence ceiling.
- Notion `Production · Validation` owns the human-readable operational/evidence surface.
- Notion Home receives only the concise player/planner meaning: what the actual playtest must prove.

This avoids mixing dynamic validation state into gameplay authority and avoids duplicating the full contract across GitHub and Notion.

## Constraints

- No Production runtime code changes in this workstream.
- Do not edit, rebase, or merge the independent Draft Production BUILD PR.
- No paid dependency, service, runner upgrade, or marketplace cost.
- No image generation or image editing. Existing visual samples remain reference material.
- `TETRIS-TIME-025`, `TETRIS-CORE-024`, `TETRIS-SKILL-026`, `TETRIS-BALANCE-027`, and `TETRIS-VISUAL-020` remain authority.
- The older 2026-08-21 broader implementation plan contains superseded timing clauses; quarantine those clauses explicitly rather than allowing them to override TIME-025.
- Human evidence status remains `NOT_RUN` until real session receipts exist.
- Directional Human Gate `PASS` requires three valid independent A/B/C first-exposure receipts. One or two sessions can produce preliminary findings only; `REVISE` / `BLOCK` may be issued earlier when already supported.

## Task 1 · RED semantic evidence contract

**Files:**
- Create `tests/tooling/test_human_evidence_contract.py`.

Require a machine-readable evidence index and a Human evidence contract that preserve the claim ceiling, visual-readability dimension, Shared Budget, dual-resource choice, lower-Tier viability, player-experience signal, three-session PASS floor, and `PASS / REVISE / BLOCK` gate.

**RED evidence:** GitHub Actions must fail specifically because the index/contract do not yet exist or required fields are absent while pre-existing tooling tests remain green.

## Task 2 · GREEN Human evidence authority

**Files:**
- Create `docs/validation/PRODUCTION_HUMAN_EVIDENCE_INDEX.json`.
- Create `docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md`.

Define:

- 6–10 minute representative scope;
- `OBSERVE_FIRST` / `DO_NOT_COACH_DURING_FIRST_ATTEMPT`;
- observation followed by non-leading probes;
- three required valid A/B/C independent first-exposure receipts before `PASS`;
- onboarding, Telegraph, Shared Budget, dual-resource, Tier viability, forecast-control, visual readability, result-feedback, and pressure → deliberate choice → readable payoff / memorable-moment evidence dimensions;
- minimum evidence receipt;
- `PASS / REVISE / BLOCK` severity/gate;
- IRG evidence ceilings;
- external Games User Research method references as discovery, not canon.

## Task 3 · Human-facing Notion projection

**Pages:**
- `04 · Production · Validation`
- new child `Vertical Slice · Human Evidence Gate`
- `Tetris · Home`

Create a readable validation page with the session flow, dimensions, observation checklist, visual-readability checklist, experience-signal checks, probes, the three-session PASS floor, and the gate. Home gets only a compact “실제 플레이에서 확인할 것” learning section; raw PR/SHA/CI/work state stays out of Home.

## Task 4 · Verify and adversarially review

Verify exact branch head:

- semantic tooling tests;
- Windows PowerShell contract;
- Godot import/parse and GUT regression if CI reaches those stages;
- compare branch against current `main`;
- confirm Draft Production BUILD PR remains unchanged.

Run at least five whole-state adversarial loops over:

1. authority/evidence separation;
2. observer bias, three-session evidence floor, and session feasibility;
3. visual readability vs subjective art preference;
4. IRG/claim ceiling/NOT_RUN honesty and experience-signal overclaiming;
5. maintainability, cost, reversibility, and PR isolation.

Any material correction resets the clean-loop count.

## Task 5 · Merge and read back

After exact-head GREEN and clean review:

- update PR evidence;
- mark ready;
- squash merge with expected head SHA;
- verify post-merge `main` and push CI;
- update Notion AI/System/Production operational truth and Issue #10 append-only readback;
- keep Human status `NOT_RUN` until real player receipts exist.
