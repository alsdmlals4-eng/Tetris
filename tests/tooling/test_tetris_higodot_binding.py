from __future__ import annotations

import hashlib
import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / "addons" / "godot_ai"
ADOPTION = ROOT / "docs" / "operations" / "HIGODOT_ADOPTION_RECORD.json"
BINDING = ROOT / "docs" / "operations" / "TETRIS_LOCAL_GODOT_BINDING.md"
LAUNCHER = ROOT / "tools" / "windows" / "start_tetris_local_executor.ps1"
ENTRYPOINT = ROOT / "RUN_TETRIS_LOCAL.cmd"
PROJECT = ROOT / "project.godot"
WORKFLOW = ROOT / ".github" / "workflows" / "core-poc-ci.yml"
TEXT_VENDOR_EXTENSIONS = {".cfg", ".gd", ".md", ".uid"}
TEXT_VENDOR_FILENAMES = {"LICENSE"}


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _canonical_vendor_payload(path: Path, payload: bytes) -> bytes:
    if path.suffix.lower() in TEXT_VENDOR_EXTENSIONS or path.name in TEXT_VENDOR_FILENAMES:
        return payload.replace(b"\r\n", b"\n")
    return payload


def _vendor_digest() -> str:
    digest = hashlib.sha256()
    files = sorted(
        (path for path in ADDON.rglob("*") if path.is_file()),
        key=lambda path: path.relative_to(ADDON).as_posix(),
    )
    for path in files:
        relative = path.relative_to(ADDON).as_posix().encode("utf-8")
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        payload = _canonical_vendor_payload(path, path.read_bytes())
        digest.update(len(payload).to_bytes(8, "big"))
        digest.update(payload)
    return digest.hexdigest()


EXPECTED_VENDOR_DIGEST = "df3856abf8ea3fd948dae66176f67cfe5e7cdd139a0815b253d640f405c0a3f6"


class TetrisHiGodotBindingTests(unittest.TestCase):
    def test_vendor_digest_canonicalizes_declared_text_line_endings_only(self) -> None:
        self.assertEqual(
            _canonical_vendor_payload(Path("plugin.gd"), b"extends EditorPlugin\r\n"),
            b"extends EditorPlugin\n",
        )
        self.assertEqual(
            _canonical_vendor_payload(Path("LICENSE"), b"MIT\r\n"),
            b"MIT\n",
        )
        self.assertEqual(
            _canonical_vendor_payload(Path("plugin.gd"), b"legacy\rline"),
            b"legacy\rline",
        )
        self.assertEqual(
            _canonical_vendor_payload(Path("asset.png"), b"\x89PNG\r\n\x1a\n"),
            b"\x89PNG\r\n\x1a\n",
        )

    def test_exact_upstream_vendor_is_present_and_integrity_locked(self) -> None:
        self.assertTrue((ADDON / "plugin.cfg").is_file())
        plugin_cfg = _text(ADDON / "plugin.cfg")
        self.assertRegex(plugin_cfg, r'(?m)^version="3\.2\.0"$')

        record = json.loads(_text(ADOPTION))
        self.assertEqual(record["provider"], "hi-godot/godot-ai")
        self.assertEqual(record["exact_release_or_commit"], "v3.2.0")
        self.assertEqual(
            record["upstream_tag_commit"],
            "42c44e4d02ca1836a0e1866361509d3a14d83b0c",
        )
        self.assertEqual(
            record["upstream_addon_tree_sha"],
            "66a9df59a92f0029efcd35c22fea355c93e8fe49",
        )
        self.assertEqual(
            record["upstream_release_archive_sha256"],
            "8c4ead3c804e32e0f5b59860f4803ad26e8fff717ec44b72fb5a4fddb0a84d6e",
        )
        self.assertEqual(
            record["vendor_local_extension_files"],
            ["runtime/game_helper_impl.gd", "runtime/game_helper_impl.gd.uid"],
        )
        self.assertEqual(record["vendor_content_sha256"], EXPECTED_VENDOR_DIGEST)
        self.assertEqual(record["vendor_content_sha256"], _vendor_digest())
        self.assertEqual(record["license"], "MIT")
        self.assertEqual(
            record["godot_distribution"]["windows_archive_sha256"],
            "c7a289051eaefb460b0106b60e9cd5bee0ef55fd102dcb2bed1eb356cf3d90a1",
        )
        self.assertEqual(
            record["godot_distribution"]["windows_executable_sha256"],
            "323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a",
        )

    def test_project_enables_only_higodot_as_persistent_godot_writer(self) -> None:
        project = _text(PROJECT)
        self.assertIn("[editor_plugins]", project)
        self.assertIn('res://addons/godot_ai/plugin.cfg', project)
        self.assertNotIn("godot_mcp", project.lower())
        self.assertFalse((ROOT / ".vscode" / "mcp.json").exists())
        self.assertFalse((ROOT / ".codex" / "config.toml").exists())

    def test_slot_eight_binding_is_exact_loopback_and_runtime_honest(self) -> None:
        record = json.loads(_text(ADOPTION))
        binding = record["project_binding"]
        self.assertEqual(binding["slot"], 8)
        self.assertEqual(binding["project_local_path"], r"C:\Users\user\Documents\GitHub\Ninza\Tetris")
        self.assertEqual(binding["godot_project_path"], "C:/Users/user/Documents/GitHub/Ninza/Tetris")
        self.assertEqual(binding["http_port"], 8008)
        self.assertEqual(binding["ws_port"], 9508)
        self.assertEqual(binding["mcp_url"], "http://127.0.0.1:8008/mcp")
        self.assertEqual(record["network_mode"], "LOOPBACK_ONLY")
        self.assertEqual(record["connection_status"], "NOT_RUN")
        self.assertEqual(record["runtime_status"], "NOT_RUN")
        self.assertFalse(record["production_readiness"])

    def test_launcher_owns_dedicated_godot_ports_and_codex_profile(self) -> None:
        self.assertTrue(LAUNCHER.is_file())
        launcher = _text(LAUNCHER)
        required = (
            r"C:\Users\user\Documents\GitHub\Ninza\Tetris",
            r"C:\Users\user\Tools\Godot-Tetris-4.7.1",
            "Godot_v4.7.1-stable_win64.exe",
            "$ExpectedGodotZipSha256 = 'c7a289051eaefb460b0106b60e9cd5bee0ef55fd102dcb2bed1eb356cf3d90a1'",
            "$ExpectedGodotExeSha256 = '323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a'",
            "$ExpectedGodotAiVersion = '3.2.0'",
            "$ExpectedGodotAiVendorSha256 = 'df3856abf8ea3fd948dae66176f67cfe5e7cdd139a0815b253d640f405c0a3f6'",
            "Get-GodotAiVendorDigest",
            "ConvertTo-CanonicalGodotAiVendorBytes",
            "$occupied = @(@(Get-PortDiagnostics $HttpPort) + @(Get-PortDiagnostics $WsPort))",
            ".Replace('\\', '/')",
            r"C:\Users\user\.codex-tetris",
            "$HttpPort = 8008",
            "$WsPort = 9508",
            "godot_ai/http_port",
            "godot_ai/ws_port",
            "godot_ai/allow_remote_hosts",
            "godot_ai/telemetry_enabled",
            "http://127.0.0.1:8008/mcp",
            "GODOT_AI_DISABLE_TELEMETRY",
            "PORT_CONFLICT_FAIL_CLOSED",
            "NON_DEDICATED_TETRIS_EDITOR_CONFLICT_FAIL_CLOSED",
            "Test-LoopbackListener",
            "Wait-ForExactHiGodotStatus",
            "HIGODOT_STATUS_IDENTITY_MISMATCH",
            "[switch]$StaticSelfTest",
            "[switch]$PortPreflightSelfTest",
            "TETRIS_LAUNCHER_PORT_PREFLIGHT_SELF_TEST_PASS",
            "UV_OR_GODOT_AI_NOT_FOUND",
            "CONCURRENT_BOOTSTRAP_FAIL_CLOSED",
            "FRESH_HIGODOT_READINESS_REQUIRED_BEFORE_MUTATION",
            "--recovery-mode",
            "--editor",
            "-C $Project",
        )
        for token in required:
            self.assertIn(token, launcher)

        for forbidden in (
            "taskkill",
            "Stop-Process",
            "git reset",
            "git restore",
            "git clean",
            "git add",
            "0.0.0.0",
            "host.docker.internal",
        ):
            self.assertNotIn(forbidden, launcher)

    def test_worktree_runtime_switch_is_explicitly_isolated_from_slot_eight(self) -> None:
        launcher = _text(LAUNCHER)
        required = (
            "[switch]$WorktreeRuntime",
            "$WorktreeRuntimeProject",
            "Tetris-phase2-runtime-resume",
            "Godot-Tetris-Phase2Runtime-4.7.1",
            ".codex-tetris-phase2-runtime",
            "$HttpPort = 8001",
            "$WsPort = 9501",
            "WORKTREE_RUNTIME_CANONICAL_PROJECT_CONFLICT_FAIL_CLOSED",
            "tetris-phase2-runtime-bootstrap.lock",
        )
        for token in required:
            self.assertIn(token, launcher)

        self.assertIn(
            r"$Project = 'C:\Users\user\Documents\GitHub\Ninza\Tetris'",
            launcher,
        )

    def test_dynamic_port_listener_pattern_uses_regex_whitespace_not_literal_backslash(self) -> None:
        launcher = _text(LAUNCHER)
        self.assertIn('"(?i)(?:^|\\s)--port\\s+"', launcher)
        self.assertIn('"(?i)(?:^|\\s)--ws-port\\s+"', launcher)
        self.assertNotIn('"(?i)(?:^|\\\\s)--port\\\\s+"', launcher)
        self.assertNotIn('"(?i)(?:^|\\\\s)--ws-port\\\\s+"', launcher)

    def test_editor_matcher_compares_parsed_absolute_project_path_exactly(self) -> None:
        launcher = _text(LAUNCHER)
        self.assertIn("function Get-ProjectPathFromGodotCommandLine", launcher)
        self.assertIn(
            "(Normalize-PathText $candidate) -eq (Normalize-PathText $ProjectPath)",
            launcher,
        )
        self.assertNotIn(
            "Contains((Normalize-PathText $ProjectPath))",
            launcher,
        )

    def test_one_click_entrypoint_docs_and_ci_contract_exist(self) -> None:
        self.assertTrue(ENTRYPOINT.is_file())
        self.assertIn("start_tetris_local_executor.ps1", _text(ENTRYPOINT))
        binding = _text(BINDING)
        for token in (
            "HTTP 8008",
            "WS 9508",
            "ASSIGNED_NOT_RUNTIME_VERIFIED",
            "CLOUD_CHATGPT_CANNOT_DIAL_LOCALHOST",
            "NO_ADDITIONAL_PAID_PLAN_REQUIRED",
        ):
            self.assertIn(token, binding)
        workflow = _text(WORKFLOW)
        self.assertIn("tests/tooling", workflow)
        self.assertRegex(workflow, re.compile(r"python\s+-m\s+unittest\s+discover"))
        self.assertIn("windows-powershell-contract", workflow)
        self.assertIn("shell: powershell", workflow)
        self.assertIn("-StaticSelfTest", workflow)
        self.assertIn("-PortPreflightSelfTest", workflow)


if __name__ == "__main__":
    unittest.main()
