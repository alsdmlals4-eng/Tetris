# HiGodot v3.2.0 Vendor Integrity Pin Incident

## Incident

On 2026-08-27, the Tetris-dedicated local launcher stopped before opening Godot because its fail-closed vendor gate expected the canonical-LF v3.2.0 digest `df3856abf8ea3fd948dae66176f67cfe5e7cdd139a0815b253d640f405c0a3f6`, while one existing worktree contained CRLF rewrites of the two project-local helper files and produced `5bb40e4c59b2c7fb4a09d98c60da949744b4a4d73aa6edebd3da142806d84058`.

## Evidence and scope boundary

- The project was at `main` `0db1a4b690500e621a47850999c00642bb0d9649` with no local changes.
- A fresh isolated worktree independently produced the pinned canonical-LF digest. File-level comparison isolated the difference to `runtime/game_helper_impl.gd` and `runtime/game_helper_impl.gd.uid`; their Git-normalized blobs remained identical in both clean worktrees.
- The vendor tree has not changed since the Godot AI v3.2.0 adoption tree `d93dcdc24592f547110d84dd7f7931992778f25d`.
- Official upstream tag `v3.2.0` resolves to `42c44e4d02ca1836a0e1866361509d3a14d83b0c`, with addon tree `66a9df59a92f0029efcd35c22fea355c93e8fe49`.
- The project retains exactly the declared project-local vendor extensions: `runtime/game_helper_impl.gd` and `runtime/game_helper_impl.gd.uid`.

## Correction

Issue #40 preserves the canonical pin and makes the Python and PowerShell digest algorithms normalize CRLF/LF only for the declared textual vendor formats. The gate remains fail-closed for changed logical source content and all non-text bytes.

The same live launch exposed a second independent empty-list bug in the port preflight: two no-listener results were added before each was materialized as an array, leaving a null row under strict mode. The preflight now materializes each query result before combining them, so an empty assigned-port state proceeds to normal startup and a real occupied-port state remains fail-closed.

## Lesson

A vendor integrity boundary must define its line-ending semantics. Both consumers must canonicalize the same declared text formats, while binary bytes remain exact; independent Python and PowerShell checks must agree before a launcher preflight is promoted.
