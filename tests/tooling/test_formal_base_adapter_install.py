"""Verify Tetris consumes the released Base adapter contract without copied Skills."""

from __future__ import annotations

import hashlib
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ADAPTER_PATH = ROOT / "skills/PROJECT_BASE_ADAPTER.json"
POLICY_PATH = ROOT / "docs/operations/TETRIS_FIRST_PROJECT_ADAPTER_POLICY.json"


class FormalBaseAdapterInstallTests(unittest.TestCase):
    def test_adapter_pins_v944_and_uses_the_merged_main_policy_source(self) -> None:
        adapter = json.loads(ADAPTER_PATH.read_text(encoding="utf-8"))
        policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
        expected_policy_hash = hashlib.sha256(
            (json.dumps(policy["protected_paths"], ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")
        ).hexdigest()

        self.assertEqual(adapter["schema_version"], 2)
        self.assertEqual(adapter["artifact_role"], "PROJECT_BASE_ADAPTER")
        self.assertEqual(adapter["project"]["project_id"], "tetris")
        self.assertEqual(adapter["base_release"]["version"], "9.4.4")
        self.assertEqual(adapter["protected_paths"], policy["protected_paths"])
        self.assertEqual(adapter["protected_baseline"], {
            "authority_kind": "REMOTE_TRACKING_REF",
            "authority_ref": "refs/remotes/origin/main",
            "commit": "c2093d7796cf8948dff613c41407c7e857d7a3e2",
            "policy_source_type": "FIRST_MIGRATION_LEGACY_SOURCE",
            "policy_source_path": "docs/operations/TETRIS_FIRST_PROJECT_ADAPTER_POLICY.json",
            "protected_paths_pointer": "/protected_paths",
            "policy_sha256": expected_policy_hash,
        })

    def test_adapter_outputs_and_remote_validation_entrypoint_are_present(self) -> None:
        expected_paths = (
            "skills/SKILL_REGISTRY.json",
            "skills/PROJECT_SKILL_SNAPSHOT.json",
            "docs/PROJECT_OPERATING_HEALTH.json",
            "docs/PROJECT_OPERATING_DASHBOARD.html",
            ".agents/skills/tetris-workflow-router/SKILL.md",
            ".github/workflows/validate-project-base-adapter.yml",
        )
        for relative in expected_paths:
            self.assertTrue((ROOT / relative).is_file(), relative)

        workflow = (ROOT / ".github/workflows/validate-project-base-adapter.yml").read_text(encoding="utf-8")
        self.assertIn("ref: 5adc196c0185951f50e49ab5e51586eff8d60886", workflow)
        self.assertIn("check_approved_project_operating_contract.py", workflow)
        self.assertIn("TETRIS_CURRENT_APPROVED_PROTECTED_CHANGE_SET.json", workflow)
        self.assertIn("--protected-base \"$PROTECTED_BASE_SHA\"", workflow)


if __name__ == "__main__":
    unittest.main()
