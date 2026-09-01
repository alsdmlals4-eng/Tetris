"""Protect the pre-adapter policy source used by the formal Base migration."""

from __future__ import annotations

import json
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
POLICY_PATH = ROOT / "docs/operations/TETRIS_FIRST_PROJECT_ADAPTER_POLICY.json"
AGENTS_PATH = ROOT / "AGENTS.md"


class FormalBaseAdapterBootstrapTests(unittest.TestCase):
    def test_main_owned_policy_is_a_real_pre_adapter_source_with_tracked_coverage(self) -> None:
        policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
        self.assertEqual(policy["artifact_role"], "TETRIS_FIRST_PROJECT_ADAPTER_PROTECTED_POLICY")
        self.assertEqual(policy["adapter_state_at_policy_commit"], "NOT_INSTALLED")
        self.assertEqual(policy["future_adapter"]["canonical_path"], "skills/PROJECT_BASE_ADAPTER.json")
        self.assertEqual(policy["future_adapter"]["first_migration_policy_pointer"], "/protected_paths")

        tracked = subprocess.run(
            ["git", "-C", str(ROOT), "ls-files", "-z"],
            check=True,
            capture_output=True,
        ).stdout.decode("utf-8").split("\0")
        self.assertTrue(policy["protected_paths"])
        self.assertEqual(len(policy["protected_paths"]), len(set(policy["protected_paths"])))
        for protected_path in policy["protected_paths"]:
            self.assertIn(protected_path, tracked, protected_path)

    def test_project_entrypoint_routes_to_policy_without_claiming_adapter_installation(self) -> None:
        agents = AGENTS_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS_FORMAL_BASE_ADAPTER_BOOTSTRAP", agents)
        self.assertIn("docs/operations/TETRIS_FIRST_PROJECT_ADAPTER_POLICY.json", agents)
        self.assertIn("skills/PROJECT_BASE_ADAPTER.json", agents)


if __name__ == "__main__":
    unittest.main()
