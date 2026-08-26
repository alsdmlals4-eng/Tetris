# Godot AI v3.2.0 Vendor Contract Reconciliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the latest-main vendor integrity gate while preserving the intentional Godot AI v3.2.0 update and its explicit project-local runtime helper extension.

**Architecture:** Keep the existing two-layer trust model: the adoption record identifies the official v3.2.0 release/tag/tree and records the project’s complete vendored-byte digest; the tooling test and Windows launcher independently enforce the same version and digest. No addon source, game rules, or production scene is changed.

**Tech Stack:** Python `unittest`, PowerShell 5.1 static contract, JSON provenance record, Godot 4.7.1, GUT 9.7.1.

**Spec:** GitHub Issue #27 and `docs/operations/HIGODOT_ADOPTION_RECORD.json`.

## Global Constraints

- Base from exact latest main `67c46e9ae4af448527357241f782a976b9e0639c`.
- Preserve the user-approved Godot AI 3.2.0 and Hera update; never rewrite the main commit.
- Preserve the project-local files `runtime/game_helper_impl.gd` and `runtime/game_helper_impl.gd.uid` as declared vendor deltas.
- No paid service, runtime-gameplay, UI, or PR #19/PR #24 mutation.

---

### Task 1: Pin official v3.2.0 provenance and the local vendor digest

**Files:**
- Modify: `tests/tooling/test_tetris_higodot_binding.py`
- Modify: `docs/operations/HIGODOT_ADOPTION_RECORD.json`
- Modify: `tools/windows/start_tetris_local_executor.ps1`
- Modify: `docs/operations/TETRIS_LOCAL_GODOT_BINDING.md`

**Interfaces:**
- Consumes: `addons/godot_ai/plugin.cfg`, the release v3.2.0 commit `42c44e4d02ca1836a0e1866361509d3a14d83b0c`, upstream addon tree `66a9df59a92f0029efcd35c22fea355c93e8fe49`, official plugin archive SHA-256 `8c4ead3c804e32e0f5b59860f4803ad26e8fff717ec44b72fb5a4fddb0a84d6e`, and canonical relative-path local vendor digest `df3856abf8ea3fd948dae66176f67cfe5e7cdd139a0815b253d640f405c0a3f6`.
- Produces: one matching v3.2.0 identity in the Python guard, adoption record, and PowerShell static self-test.

- [x] **Step 1: Write the failing contract assertions.**

```python
self.assertRegex(plugin_cfg, r'(?m)^version="3\\.2\\.0"$')
self.assertEqual(record["exact_release_or_commit"], "v3.2.0")
self.assertEqual(record["vendor_content_sha256"], _vendor_digest())
self.assertEqual(record["vendor_local_extension_files"], [
    "runtime/game_helper_impl.gd",
    "runtime/game_helper_impl.gd.uid",
])
```

- [x] **Step 2: Run the focused test and verify RED.**

Run: `python -m unittest tests.tooling.test_tetris_higodot_binding.TetrisHiGodotBindingTests.test_exact_upstream_vendor_is_present_and_integrity_locked -v`

Expected: fail because the record still pins v3.1.4 and old vendor digest.

- [x] **Step 3: Update the contract sources and user-facing binding note.**

```text
adoption record: v3.2.0 + tag commit + upstream tree + official release archive checksum + local-extension manifest + local vendor digest
Python guard: matching v3.2.0 provenance and extension manifest
PowerShell launcher: ExpectedGodotAiVersion = 3.2.0 and ExpectedGodotAiVendorSha256 = df3856…a3f6
```

- [x] **Step 4: Run the focused test and static self-test to verify GREEN.**

Run: `python -m unittest tests.tooling.test_tetris_higodot_binding.TetrisHiGodotBindingTests.test_exact_upstream_vendor_is_present_and_integrity_locked -v`

Run: `./tools/windows/start_tetris_local_executor.ps1 -StaticSelfTest`

Expected: both pass with the new local vendor digest.

- [ ] **Step 5: Run the full CI-equivalent suite and commit.**

Run: tooling 17/17, Windows static contract, Godot import/parse, strict GUT guard, complete GUT suite.

Commit: `fix: reconcile Godot AI v3.2 vendor contract`

## Plan self-review

- Scope coverage: official provenance, custom local delta, Python guard, and Windows guard are each covered by Task 1.
- Placeholder scan: no deferred or unspecified implementation steps remain.
- Interface consistency: all consumers assert the same plugin version and computed local vendor digest.
