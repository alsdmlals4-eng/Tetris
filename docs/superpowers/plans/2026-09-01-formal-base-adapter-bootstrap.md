# Formal Base Adapter Bootstrap — Execution Plan

> **Execution note:** Follow `docs/superpowers/specs/2026-09-01-formal-base-adapter-bootstrap-design.md`. This plan is an approved continuation of the user-directed formal-adapter condition closure on 2026-09-01; it does not authorize any gameplay or visual change.

## Task 1: Establish a non-self-attesting first-migration source

**Files:**

- Modify: `AGENTS.md`
- Create: `docs/operations/TETRIS_FIRST_PROJECT_ADAPTER_POLICY.json`
- Create: `tests/tooling/test_formal_base_adapter_bootstrap.py`

**Steps:**

1. Add the tooling test before policy implementation; it must fail when the source is absent.
2. Add only existing governance/canon paths to `/protected_paths`; include neither future adapter output paths nor gameplay implementation paths.
3. Route `AGENTS.md` to the policy source and state the policy commit is pre-adapter.
4. Run the focused test, then the full current tooling suite and Windows launcher self-tests.

**Acceptance:**

- Every protected path exists and is Git-tracked.
- The policy explicitly identifies `skills/PROJECT_BASE_ADAPTER.json` as a future canonical output, never an installed file.
- No project gameplay/runtime/asset path is changed by this PR.

## Task 2: Publish and verify policy prelude

**Steps:**

1. Re-fetch `origin/main`; re-check open PR overlap and intended paths.
2. Commit only Task 1 plus its design/plan files, push the branch, and create a new PR to `main`.
3. Record exact head/base, required checks, review state, and merge eligibility. Merge only if repository rules permit without bypass.
4. Re-read the merged `origin/main` SHA and exact policy blob.

**Acceptance:**

- The policy source is available at the exact `refs/remotes/origin/main` commit that will become PR B's `protected_baseline.commit`.
- Remote CI is distinguished from local checks. No merge is claimed until GitHub reports it.

## Task 3: Install the formal adapter in a separate dependent branch

**Dependency:** Task 2 merged main readback.

**Files (expected; confirm against current Base template before writing):**

- Create: `skills/PROJECT_BASE_ADAPTER.json`
- Create: `skills/SKILL_REGISTRY.json`
- Create generated: `skills/PROJECT_SKILL_SNAPSHOT.json`, project router, `docs/PROJECT_OPERATING_DASHBOARD.html`, `docs/PROJECT_OPERATING_HEALTH.json`
- Create/modify focused contract test(s) only as required for the exact v9.4.4 CLI route.

**Steps:**

1. Create a new worktree from Task 2's merged main, not from PR #85 or the policy branch.
2. Build the adapter using the released Base v9.4.4 lock identities and the policy source at that exact main SHA.
3. Use RED → GREEN validator tests; run Base contract check/build check plus target tooling and Windows checks.
4. Publish a distinct adapter PR. Do not merge until its exact head has passed required checks and reviews.

**Acceptance:**

- `check_project_operating_contract.py --check` passes against the exact Base checkout.
- Generated views are current and no protected source changes occur on the adapter branch.
- Existing open PRs and the user-local theme resource remain untouched.

## Review and evidence sequence

1. Current-canon/drift attack.
2. Baseline/source-provenance attack.
3. Self-attestation/path-traversal/weakening attack.
4. Consumer/generated-output/CI scope attack.
5. PR-head/merge/readback attack.

Repeat after each correction until the current task has five clean loops. Runtime, device, accessibility, Human and release gates remain `NOT_RUN` for this operational work.
