import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
IA_PATH = ROOT / "docs" / "validation" / "PROJECT_HOME_LIVING_GDD_IA_CONTRACT.json"


class ProjectHomeIaContractTests(unittest.TestCase):
    def test_tetris_home_and_ai_workspace_roles_are_machine_readable(self) -> None:
        self.assertTrue(IA_PATH.is_file(), "project-home IA contract must exist")
        data = json.loads(IA_PATH.read_text(encoding="utf-8"))
        self.assertEqual(data["project"], "TETRIS")
        self.assertEqual(data["human_home_role"], "PROJECT_LIVING_GDD_VISUAL_DASHBOARD")
        self.assertEqual(data["ai_workspace_root"], "EXISTING_TETRIS_SYSTEM_RECORD")
        self.assertEqual(data["visual_authority"], "TETRIS-VISUAL-020")
        self.assertEqual(data["schema_version"], 2)
        self.assertEqual(data["core_combat_authority"], "TETRIS-CORE-029")
        self.assertEqual(data["historical_timing_authority"], "TETRIS-TIME-025")
        self.assertEqual(data["historical_combat_authority"], "TETRIS-CORE-024")
        self.assertEqual(data["skill_authority"], "TETRIS-SKILL-026")
        self.assertEqual(data["balance_authority"], "TETRIS-BALANCE-027")
        self.assertEqual(data["human_evidence_state"], "NOT_RUN")
        self.assertTrue(data["protect_draft_build_pr_19"])
        self.assertIn("PROJECT_NORTH_STAR", data["home_reading_order"])
        self.assertIn("CORE_GAMEPLAY_DATA", data["home_reading_order"])
        self.assertIn("DEVELOPMENT_REALITY", data["home_reading_order"])
        self.assertIn("DETAIL_LIBRARY", data["home_reading_order"])
        self.assertIn("RAW_PR_SHA_CI_LOGS", data["home_forbidden_operational_content"])
        self.assertEqual(
            data["image_state"],
            "VISUAL_REFERENCE_NORTH_STAR_NOT_RUNTIME_PROOF",
        )

    def test_home_contract_keeps_visual_gdd_above_link_library(self) -> None:
        data = json.loads(IA_PATH.read_text(encoding="utf-8"))
        order = data["home_reading_order"]
        self.assertLess(order.index("PROJECT_NORTH_STAR"), order.index("DETAIL_LIBRARY"))
        self.assertLess(order.index("HOW_THE_GAME_WORKS"), order.index("DETAIL_LIBRARY"))
        self.assertLess(order.index("HOW_IT_SHOULD_LOOK"), order.index("DETAIL_LIBRARY"))


if __name__ == "__main__":
    unittest.main()
