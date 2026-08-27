# HiGodot Vendor Integrity Pin Correction Plan

> **For agentic workers:** required procedure: test the current deterministic vendor digest before changing any integrity pin, then validate the Python and PowerShell consumers independently.

**Goal:** Make the v3.2.0 local-vendor SHA-256 calculation canonical across Windows text line endings so the Tetris launcher validates the exact tracked vendor tree without weakening its fail-closed boundary.

**Issue:** #40.

**Scope:** `HIGODOT_ADOPTION_RECORD.json`, the launcher expectation, the deterministic tooling test, and the incident record. No addon bytes, game systems, ports, or other open PRs are changed.

## Implementation steps

- [x] Reproduce RED on latest main: Python and PowerShell compute the same physical-byte digest, different from the canonical pin.
- [x] Verify the clean vendor tree and official v3.2.0 tag/tree boundary, including the two declared project-local extension files.
- [x] Isolate the difference to CRLF rewrites of the two declared project-local text extensions; preserve the canonical source pin.
- [x] Add the same declared-text CRLF/LF canonicalization to Python and PowerShell, with lone-CR and binary bytes exact.
- [x] Correct the independently discovered empty port-diagnostics aggregation before re-running the ordinary launcher, with a bounded self-test for both empty and foreign-owner cases.
- [x] Run the focused tooling test and PowerShell static self-test on the exact branch head.
- [x] Run the ordinary launcher far enough to prove it passes the former vendor gate, then preserve the runtime boundary honestly.
- [ ] Run local CI-equivalent checks, independent review, exact-head CI, merge only after required checks/review/thread gates, and post-merge readback.
