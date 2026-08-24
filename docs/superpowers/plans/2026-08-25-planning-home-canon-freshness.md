# Planning Home Canon Freshness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove stale pre-TIME-025 timing claims from the current combat canon, protect that boundary with a semantic contract, and synchronize the human-facing Notion Home/benchmark projection without touching Production runtime or PR #19.

**Architecture:** Keep `PRODUCTION_TURN_TIME_CANON.md` as the sole current owner of timing behavior and keep `PRODUCTION_TURN_COMBAT_CANON.md` as the non-timing ordered-turn owner. Add a regression assertion so the combat canon must explicitly defer timing to TIME-025 and may not reintroduce independent per-phase timing as current behavior. Project the same current meaning into the existing Notion Human Home and Benchmark Library; operational SHA/PR/runtime details remain in the existing System Record rather than the Home.

**Tech Stack:** Markdown/JSON canon, Python `unittest` semantic contracts, GitHub PR workflow, Notion Human Home/System Record.

**Spec:** `docs/design/PRODUCTION_TURN_TIME_CANON.md` + `docs/design/PRODUCTION_TURN_COMBAT_CANON.md` + `docs/design/PRODUCTION_CANON_INDEX.json` + current Base Human Home/domain-split contracts.

## Global Constraints

- `TETRIS-TIME-025` owns player-turn timing, time modifiers, timeout, and Tempo.
- `TETRIS-CORE-024` retains ordered combat and non-timing production rules.
- One shared active-input budget spans `LINE → CHAIN → ACTION`; READY carries remaining time forward.
- `LINE_SETTLE`, `CHAIN_SETTLE`, forced transitions/animations, Enemy Resolve, and System Pause do not consume player budget.
- Unused time never banks into a future turn.
- Production runtime BUILD is out of scope for this planning/canon cleanup.
- Open PR #19 is `ACTIVE_OTHER_WORKSTREAM` / read-only for this task.
- No new image generation; reuse the three existing approved/reference Home visuals only.
- Human Home is a self-contained game-learning surface; raw work/PR/SHA/runtime metadata stays in the AI/System surface.
- Zero incremental paid cost.

---

### Task 1: Add a semantic regression guard for timing authority

**Files:**
- Modify: `tests/tooling/test_production_canon_contract.py`
- Test: `tests/tooling/test_production_canon_contract.py`

**Interfaces:**
- Consumes: current `CANON_PATH` and `TIME_CANON_PATH` constants.
- Produces: `test_combat_canon_defers_timing_to_time_025()` guarding the owner boundary.

- [ ] **Step 1: Write the failing test**

Add a test that requires `PRODUCTION_TURN_COMBAT_CANON.md` to name `TETRIS-TIME-025`, state that the shared player-turn budget is timing authority, and not contain current-rule statements `each phase has its own timer`, `Unused phase time is not banked into another phase`, or `phase time never transfers between Line, Chain, Action`.

- [ ] **Step 2: Run the focused unittest and verify RED**

Run: `python -m unittest tests.tooling.test_production_canon_contract.ProductionCanonContractTests.test_combat_canon_defers_timing_to_time_025 -v`

Expected: FAIL on current `main` because `PRODUCTION_TURN_COMBAT_CANON.md` does not name `TETRIS-TIME-025` and still contains independent-phase timing clauses.

- [ ] **Step 3: Preserve the RED receipt before changing the canon**

Record the failing exact-head CI/workflow evidence on the current-task PR; do not edit or merge PR #19.

### Task 2: Make the combat canon defer all timing semantics to TIME-025

**Files:**
- Modify: `docs/design/PRODUCTION_TURN_COMBAT_CANON.md`
- Test: `tests/tooling/test_production_canon_contract.py`

**Interfaces:**
- Consumes: `PRODUCTION_TURN_TIME_CANON.md` timing semantics and existing CORE-024 ordered-turn structure.
- Produces: one non-contradictory combat canon whose timing references are descriptive handoffs to TIME-025, not a second timing owner.

- [ ] **Step 1: Add an explicit timing-authority boundary near the document authority section**

State that TIME-025 supersedes every independent Line/Chain/Action timer, discarded phase-time, timeout, modifier, and Tempo clause while CORE-024 keeps ordered-turn/non-timing rules.

- [ ] **Step 2: Correct stale stage wording**

Change Line/Chain/Action descriptions from per-phase timer expiry/discard semantics to shared-budget expiry, READY carryover, stable settle, and PASS fallback semantics. Preserve board persistence, resource ownership, settle behavior, and enemy telegraph rules.

- [ ] **Step 3: Replace the old `Phase-time contract`**

Replace the 30/30/30 independent timer table/rules with a short timing handoff that points to TIME-025, labels the old 30/30/30 model superseded, and states only the non-timing integration facts needed by CORE-024.

- [ ] **Step 4: Run the focused semantic test and verify GREEN**

Run: `python -m unittest tests.tooling.test_production_canon_contract.ProductionCanonContractTests.test_combat_canon_defers_timing_to_time_025 -v`

Expected: PASS.

- [ ] **Step 5: Run the full tooling semantic suite**

Run: `python -m unittest discover -s tests/tooling -p 'test_*.py' -v`

Expected: PASS with no regression in current canon routing.

### Task 3: Refresh the Notion human projection without creating another canon

**Files / destinations:**
- Modify: Notion `Tetris · Home`
- Modify: Notion `05 · Reference · Benchmark 도서관`
- Modify: Notion Tetris `SYSTEM RECORD` properties/notes only for operational metadata

**Interfaces:**
- Consumes: CORE-024, TIME-025, SKILL-026, BALANCE-027, current approved/reference Home visuals, current web benchmark evidence.
- Produces: a 30-second → 5-minute self-contained learning surface plus separate AI/System operational state.

- [ ] **Step 1: Extend the existing Home instead of creating a duplicate Player Guide**

Add a visual Mermaid full-game/turn flow, first-session learning route, system relationship table, player-choice explanation, and human edit guide before the existing overview/visual sections. Reuse the three existing visuals; do not generate new images.

- [ ] **Step 2: Keep operational state out of the Home**

Do not add PR numbers, SHA history, CI logs, raw prompt/hash/tool metadata, or work queue details to the Home. Keep only player-facing meaning and a locator to the System Record for AI/operations.

- [ ] **Step 3: Refresh Benchmark Library**

Add a dated 2026-08-25 evidence refresh using official/first-party sources where available. Mark the old `계속 흐르는 Combat Clock` synthesis as superseded and replace it with the current project-specific synthesis: telegraphed threat + sequential puzzle preparation + dual resource opportunity cost + one shared player-turn budget + tactical Tier commitment.

- [ ] **Step 4: Update System Record operational readback**

Record current merged-main identity separately from the existence of open PR #19. Do not promote PR #19 runtime into `main` runtime truth. Leave unverified local Godot bindings as observed/local metadata rather than declaring a migration without local evidence.

- [ ] **Step 5: Destination readback**

Fetch Home, Benchmark Library, and System Record after mutation and verify the intended sections/properties are durable and correctly separated.

### Task 4: Review, IRG, PR, merge, and post-merge readback

**Files:**
- Review all changed repository files and Notion destinations.

**Interfaces:**
- Consumes: exact current-task PR head, workflow checks, Notion readback.
- Produces: merged main or a precise BLOCKED_UNVERIFIED state.

- [ ] **Step 1: Run at least five full adversarial loops**

Each loop re-attacks user intent, owner/canon routing, stale timing references, untouched consumers, Notion separation, benchmark causality, implementation-reality claims, PR #19 isolation, maintenance cost, and better alternatives. Fix only validated findings, then restart the clean count after material correction.

- [ ] **Step 2: Apply the Implementation Reality Gate**

Distinguish documented/merged main truth from open-PR implementation, runtime evidence, and human/player evidence. `NOT_RUN` must remain `NOT_RUN`.

- [ ] **Step 3: Verify exact PR head**

Check changed filenames/diff, current workflow runs, combined status, review threads/rules that are observable, and ensure the exact reviewed head is the merge head.

- [ ] **Step 4: Merge the current-task PR only**

Use repository-supported squash merge after required evidence is green. Do not modify, rebase, or merge PR #19.

- [ ] **Step 5: Post-merge readback**

Fetch new `main`, re-read changed canon/test files, re-read Notion destinations, and recompute remaining required work. Report runtime/human evidence as unchanged unless actually observed.
