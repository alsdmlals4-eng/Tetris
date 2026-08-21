# Tetris Local Godot Binding

Status: `ASSIGNED_NOT_RUNTIME_VERIFIED`

## Exact slot 8 assignment

```text
project: TETRIS
repository: alsdmlals4-eng/Tetris
project_local_path: C:\Users\user\Documents\GitHub\Ninza\Tetris
godot_project_path: C:/Users/user/Documents/GitHub/Ninza/Tetris
godot_project_file: C:/Users/user/Documents/GitHub/Ninza/Tetris/project.godot
dedicated_godot: C:\Users\user\Tools\Godot-Tetris-4.7.1\Godot_v4.7.1-stable_win64.exe
HiGodot HTTP 8008: http://127.0.0.1:8008/mcp
HiGodot WS 9508: ws://127.0.0.1:9508
CODEX_HOME: C:\Users\user\.codex-tetris
```

The repository vendors exact `hi-godot/godot-ai` v3.1.4 and enables it as the sole persistent Godot authoring authority. The one-click launcher validates the full vendored-addon digest and the official Godot archive/executable SHA-256, creates or reuses a self-contained Godot 4.7.1 editor, writes only that editor's settings, clears `allow_remote_hosts`, binds HTTP 8008 and WS 9508 to loopback, disables telemetry, verifies listener addresses and owners, then verifies the live status identity (`godot-ai` / `3.1.4` / WS `9508`). It creates a Tetris-only Codex profile and never takes another port, kills an unknown process, or writes shared `.vscode/mcp.json` / `.codex/config.toml` files.

## GPT-first operating model and cost

`CLOUD_CHATGPT_CANNOT_DIAL_LOCALHOST`: cloud ChatGPT cannot directly reach `127.0.0.1` on the user's PC. The efficient boundary is therefore:

```text
ChatGPT Pro → Notion/GitHub coordination
local Codex CLI → Tetris HiGodot at 127.0.0.1:8008/mcp
Godot AI plugin → Tetris editor over WS 9508
```

This uses the user's current ChatGPT Pro entitlement plus free local Godot, free MIT-licensed Godot AI, uv, and GitHub's existing public-repository CI. `NO_ADDITIONAL_PAID_PLAN_REQUIRED`. A paid Notion plan, API billing, custom cloud relay, Figma, or a second Godot MCP is not required for this binding.

## One-click start

After PR #3 is merged and the Windows checkout is at the exact path above, double-click `RUN_TETRIS_LOCAL.cmd`. The free `uv`/`uvx` runtime used by Godot AI must already be installed; the launcher checks it immediately and links to the official installer instead of waiting for a port timeout. The launcher:

1. verifies the exact repository, `project.godot`, vendored Godot AI 3.1.4, and origin URL;
2. creates or verifies the dedicated self-contained Godot 4.7.1 installation;
3. fails closed on a concurrent launcher, non-dedicated editor, or unknown HTTP 8008 / WS 9508 owner;
4. seeds dedicated EditorSettings with 8008/9508 and `keep_server_on_exit=false`;
5. starts or reuses the exact Tetris editor;
6. waits for both loopback listeners and verifies the exact live Godot AI status/version/WS port;
7. writes the managed `C:\Users\user\.codex-tetris\config.toml` and launches Codex from the Tetris root.

Pass `-SkipCodex` to the PowerShell script only when starting the editor/server without a local MCP client.

## Implementation Reality Gate

Repository structure, exact vendor identity, project enablement, path/port constants, CI contract, and non-destructive launcher policy are statically verifiable here. An isolated Godot 4.7.1 Linux validation passed import/parse, all 5 binding-contract tests, all 50 existing GUT tests (355 assertions), and the strict log guard. The Linux run is headless, so Godot AI intentionally disables its server there.

The following remain `NOT_RUN` until the launcher runs on the user's Windows PC:

- dedicated executable exists and reports Godot 4.7.1;
- EditorSettings actually contain 8008/9508;
- HTTP 8008 and WS 9508 listeners belong to the exact Tetris Godot AI server;
- Codex attaches and returns a fresh Tetris project/session/version/readiness receipt.

Port-listen evidence alone is startup evidence, not authoring readiness. Persistent Godot mutation must wait for that fresh receipt.
