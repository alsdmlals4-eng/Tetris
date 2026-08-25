# Tetris Local Godot Binding

Status: `ASSIGNED_NOT_RUNTIME_VERIFIED`

## Shared fixed local binding

`SHARED_FIXED_LOCAL` replaces the historical project-dedicated slot/port model.

```text
project: TETRIS
repository: alsdmlals4-eng/Tetris
project_local_path: C:\Users\user\Documents\GitHub\Ninza\Tetris
godot_project_path: C:/Users/user/Documents/GitHub/Ninza/Tetris
godot_project_file: C:/Users/user/Documents/GitHub/Ninza/Tetris/project.godot
shared_godot: C:\Users\user\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64.exe
HiGodot HTTP 8000: http://127.0.0.1:8000/mcp
HiGodot WS 9500: ws://127.0.0.1:9500
Codex profile: DEFAULT_USER_PROFILE
```

`UPSTREAM_DEFAULT_PORTS`: HiGodot's standard HTTP `8000` and WebSocket `9500` are the fixed shared local ports. They remain loopback-only. We do not auto-select project-specific alternatives. If an incompatible foreign process owns either port, startup fails closed and the operator resolves the conflict explicitly.

`MULTI_EDITOR_SHARED_BACKEND_SUPPORTED`: upstream HiGodot supports several Godot editors connected to one backend. Therefore another project editor using the same shared Godot installation is not, by itself, a Tetris conflict. The safety boundary moves from project-specific ports to **exact session selection**: when more than one editor is connected, the Tetris project/session must be freshly identified and pinned before any persistent mutation.

The repository still vendors exact `hi-godot/godot-ai` v3.1.4 as the sole persistent Godot authoring authority. The shared launcher verifies the vendored-addon digest and exact Godot 4.7.1 distribution hashes, keeps the transport on loopback, disables telemetry, and validates the live backend identity before allowing the workflow to continue.

## Codex operating model

The project launcher no longer creates or writes a Tetris-only Codex home. It uses the normal user Codex profile. HiGodot should be configured once in that shared profile using the Godot AI dock's **Configure** action or the upstream-supported manual attach configuration for HTTP `8000` / WS `9500`.

The project launcher deliberately does **not** rewrite shared Codex configuration. Its responsibility is project identity, shared Godot/backend startup, and live readiness gating. After Codex opens in the Tetris repository, the first Godot-authoring action must obtain a fresh Tetris project/session/version/readiness receipt. When several editors are connected, select/pin the Tetris session before mutation.

`CLOUD_CHATGPT_CANNOT_DIAL_LOCALHOST`: cloud ChatGPT cannot directly reach `127.0.0.1` on the user's PC. The local boundary remains:

```text
ChatGPT → Notion/GitHub coordination
local Codex CLI → shared HiGodot at 127.0.0.1:8000/mcp
shared HiGodot backend → one or more Godot editors over WS 9500
```

Godot, Godot AI, uv and the existing local/CI toolchain remain free components for this binding. `NO_ADDITIONAL_PAID_PLAN_REQUIRED`.

## One-click start

Double-click `RUN_TETRIS_LOCAL.cmd`, or invoke `tools/windows/start_tetris_local_executor.ps1` directly. The launcher:

1. verifies the exact Tetris repository, `project.godot`, origin and vendored Godot AI v3.1.4;
2. creates or verifies the shared self-contained Godot 4.7.1 installation at the fixed common path;
3. verifies shared Editor Settings use HTTP `8000`, WS `9500`, loopback-only hosts and disabled telemetry; if settings need changing while a shared Godot editor is already running, it fails closed instead of racing the editor;
4. accepts an already-running compatible shared HiGodot backend, but rejects an incompatible foreign owner with `SHARED_HIGODOT_FOREIGN_PORT_CONFLICT` and never chooses an alternate port automatically;
5. starts or reuses the Tetris editor using the common Godot executable;
6. waits for the shared backend and verifies `godot-ai` / v3.1.4 / WS `9500` identity;
7. emits `FRESH_HIGODOT_READINESS_REQUIRED_BEFORE_MUTATION` and launches the normal Codex user profile from the Tetris root unless `-SkipCodex` was requested.

The launcher never kills an unknown process and never runs destructive Git cleanup commands.

## Implementation Reality Gate

Repository configuration, exact vendor identity, shared path/port constants, launcher syntax/static self-test and CI consumption can be verified automatically. Those checks do **not** prove the user's Windows machine currently has a live shared editor/backend.

The following remain `NOT_RUN` until an actual Windows local run supplies evidence:

- the common Godot executable exists locally and reports Godot 4.7.1;
- the shared Editor Settings actually contain HTTP `8000` / WS `9500` and the intended safety settings;
- the loopback listeners belong to a compatible HiGodot v3.1.4 backend;
- the Tetris editor session is connected and can be distinctly selected if multiple editors are present;
- Codex's shared user profile is configured for HiGodot and returns a fresh exact Tetris readiness receipt.

Port-listen evidence alone is startup evidence, not Tetris authoring readiness. Persistent mutation must wait for the exact-session readback.
