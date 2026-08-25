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


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _vendor_digest() -> str:
    digest = hashlib.sha256()
    for path in sorted(p for p in ADDON.rglob("*") if p.is_file()):
        relative = path.relative_to(ADDON).as_posix().encode("utf-8")
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        payload = path.read_bytes()
        digest.update(len(payload).to_bytes(8, "big"))
        digest.update(payload)
    return digest.hexdigest()


class TetrisHiGodotBindingTests(unittest.TestCase):
    def test_exact_upstream_vendor_is_present_and_integrity_locked(self) -> None:
        self.assertTrue((ADDON / "plugin.cfg").is_file())
        plugin_cfg = _text(ADDON / "plugin.cfg")
        self.assertRegex(plugin_cfg, r'(?m)^version="3\.1\.4"$')

        record = json.loads(_text(ADOPTION))
        self.assertEqual(record["provider"], "hi-godot/godot-ai")
        self.assertEqual(record["exact_release_or_commit"], "v3.1.4")
        self.assertEqual(
            record["upstream_tag_commit"],
            "96cc8b8c3d25ce487e24801d01d5214fea150349",
        )
        self.assertEqual(
            record["upstream_addon_tree_sha"],
            "69010571e11123dfc4e09483f80cb9e6ca93511a",
        )
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

    def test_shared_fixed_binding_uses_upstream_default_loopback_ports(self) -> None:
        record = json.loads(_text(ADOPTION))
        binding = record["project_binding"]
        self.assertEqual(binding["binding_mode"], "SHARED_FIXED_LOCAL")
        self.assertNotIn("slot", binding)
        self.assertEqual(binding["project_local_path"], r"C:\Users\user\Documents\GitHub\Ninza\Tetris")
        self.assertEqual(binding["godot_project_path"], "C:/Users/user/Documents/GitHub/Ninza/Tetris")
        self.assertEqual(
            binding["shared_godot_executable"],
            r"C:\Users\user\Tools\Godot-4.7.1\Godot_v4.7.1-stable_win64.exe",
        )
        self.assertEqual(binding["http_port"], 8000)
        self.assertEqual(binding["ws_port"], 9500)
        self.assertEqual(binding["mcp_url"], "http://127.0.0.1:8000/mcp")
        self.assertEqual(binding["codex_profile"], "DEFAULT_USER_PROFILE")
        self.assertEqual(record["network_mode"], "LOOPBACK_ONLY")
        self.assertEqual(record["connection_status"], "NOT_RUN")
        self.assertEqual(record["runtime_status"], "NOT_RUN")
        self.assertFalse(record["production_readiness"])

    def test_launcher_reuses_shared_godot_ports_and_default_codex_profile(self) -> None:
        self.assertTrue(LAUNCHER.is_file())
        launcher = _text(LAUNCHER)
        required = (
            r"C:\Users\user\Documents\GitHub\Ninza\Tetris",
            r"C:\Users\user\Tools\Godot-4.7.1",
            "Godot_v4.7.1-stable_win64.exe",
            "$ExpectedGodotZipSha256 = 'c7a289051eaefb460b0106b60e9cd5bee0ef55fd102dcb2bed1eb356cf3d90a1'",
            "$ExpectedGodotExeSha256 = '323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a'",
            "$ExpectedGodotAiVendorSha256 = '59fd1325f7a361a98c382b9ba3ef47f9a7c635167b2a14479521b4102c3d7329'",
            "Get-GodotAiVendorDigest",
            "$HttpPort = 8000",
            "$WsPort = 9500",
            "godot_ai/http_port",
            "godot_ai/ws_port",
            "godot_ai/allow_remote_hosts",
            "godot_ai/telemetry_enabled",
            "http://127.0.0.1:8000/mcp",
            "GODOT_AI_DISABLE_TELEMETRY",
            "SHARED_HIGODOT_FOREIGN_PORT_CONFLICT",
            "Test-LoopbackListener",
            "Wait-ForSharedHiGodotStatus",
            "HIGODOT_STATUS_IDENTITY_MISMATCH",
            "[switch]$StaticSelfTest",
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
            "Godot-Tetris-4.7.1",
            ".codex-tetris",
            "TETRIS_DEDICATED",
            "PROJECT_DEDICATED",
            "$HttpPort = 8008",
            "$WsPort = 9508",
            "NON_DEDICATED_TETRIS_EDITOR_CONFLICT_FAIL_CLOSED",
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

    def test_one_click_entrypoint_docs_and_ci_contract_exist(self) -> None:
        self.assertTrue(ENTRYPOINT.is_file())
        self.assertIn("start_tetris_local_executor.ps1", _text(ENTRYPOINT))
        binding = _text(BINDING)
        for token in (
            "SHARED_FIXED_LOCAL",
            "HTTP 8000",
            "WS 9500",
            "UPSTREAM_DEFAULT_PORTS",
            "MULTI_EDITOR_SHARED_BACKEND_SUPPORTED",
            "ASSIGNED_NOT_RUNTIME_VERIFIED",
            "CLOUD_CHATGPT_CANNOT_DIAL_LOCALHOST",
            "NO_ADDITIONAL_PAID_PLAN_REQUIRED",
        ):
            self.assertIn(token, binding)
        for stale in ("slot 8", "8008", "9508", ".codex-tetris", "dedicated_godot"):
            self.assertNotIn(stale, binding)

        workflow = _text(WORKFLOW)
        self.assertIn("tests/tooling", workflow)
        self.assertRegex(workflow, re.compile(r"python\s+-m\s+unittest\s+discover"))
        self.assertIn("windows-powershell-contract", workflow)
        self.assertIn("shell: powershell", workflow)
        self.assertIn("-StaticSelfTest", workflow)


if __name__ == "__main__":
    unittest.main()
