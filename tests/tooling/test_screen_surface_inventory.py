"""Contract checks for the user-approved full game screen inventory."""

from __future__ import annotations

import json
import hashlib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INVENTORY = ROOT / "docs" / "design" / "SCREEN_SURFACE_INVENTORY.json"
GUIDE = ROOT / "docs" / "design" / "FULL_GAME_SCREEN_SURFACE_INVENTORY.md"
REFERENCE_MANIFEST = ROOT / "docs" / "assets" / "reference" / "planned" / "SCREEN_REFERENCE_MANIFEST.json"
REQUIRED_FIELDS = {
    "screen_id", "screen_family", "screen_name", "project_stage", "priority",
    "flow_entry", "flow_exit", "player_goal", "player_question", "consumer_kind",
    "consumer_surface", "screen_design_reference", "runtime_consumer", "existing_evidence",
    "coverage_status", "notion_destination", "repository_destination", "blockers",
}


class ScreenSurfaceInventoryTests(unittest.TestCase):
    def test_every_required_family_and_field_is_recorded(self) -> None:
        inventory = json.loads(INVENTORY.read_text(encoding="utf-8"))
        rows = inventory["screens"]
        self.assertEqual(16, len(rows))
        self.assertEqual(len(rows), len({row["screen_id"] for row in rows}))
        for row in rows:
            self.assertTrue(REQUIRED_FIELDS.issubset(row))
            self.assertIn(row["priority"], {"P0", "P1", "P2"})
            self.assertIn(row["consumer_kind"], {
                "GAME_RUNTIME", "PLANNED_GAME_SURFACE", "PLAYER_FACING_EXPLANATORY", "PRODUCT_DISTRIBUTION",
            })
            self.assertIsInstance(row["blockers"], list)

    def test_runtime_and_planned_surfaces_are_not_promoted_to_each_other(self) -> None:
        rows = {row["screen_id"]: row for row in json.loads(INVENTORY.read_text(encoding="utf-8"))["screens"]}
        self.assertEqual("GAME_RUNTIME", rows["TETRIS-SCREEN-007"]["consumer_kind"])
        self.assertEqual("COVERED_EXISTING_FOR_CORE_RUNTIME", rows["TETRIS-SCREEN-007"]["coverage_status"])
        self.assertEqual("GAME_RUNTIME", rows["TETRIS-SCREEN-008"]["consumer_kind"])
        self.assertEqual("PLANNED_GAME_SURFACE", rows["TETRIS-SCREEN-002"]["consumer_kind"])
        self.assertEqual("PRODUCT_DISTRIBUTION", rows["TETRIS-SCREEN-016"]["consumer_kind"])
        self.assertNotEqual("COVERED_EXISTING", rows["TETRIS-SCREEN-016"]["coverage_status"])

    def test_first_session_briefing_is_required_but_not_promoted_to_runtime(self) -> None:
        inventory = json.loads(INVENTORY.read_text(encoding="utf-8"))
        rows = {row["screen_id"]: row for row in inventory["screens"]}

        self.assertEqual("TETRIS-ONBOARDING-037", inventory["first_session_onboarding"]["decision"])
        self.assertEqual(
            "USER_APPROVED_DOCUMENTED_NOT_IMPLEMENTED",
            inventory["first_session_onboarding"]["status"],
        )
        self.assertEqual("PLANNED_GAME_SURFACE", rows["TETRIS-SCREEN-006"]["consumer_kind"])
        self.assertEqual("GAP_BLOCKING_FOR_INTENDED_FIRST_SESSION", rows["TETRIS-SCREEN-006"]["coverage_status"])
        self.assertEqual("GAME_RUNTIME", rows["TETRIS-SCREEN-007"]["consumer_kind"])
        self.assertEqual("COVERED_EXISTING_FOR_CORE_RUNTIME", rows["TETRIS-SCREEN-007"]["coverage_status"])
        self.assertIn("TETRIS-ONBOARDING-037", GUIDE.read_text(encoding="utf-8"))

    def test_human_guide_requires_whole_screen_evidence_and_existing_asset_reuse(self) -> None:
        text = GUIDE.read_text(encoding="utf-8")
        for token in (
            "Whole-screen evidence requirement", "TETRIS-IMG-031", "TETRIS-IMG-036",
            "no bitmap UI queue", "planned, not implemented", "not a claim that every listed screen is currently implemented",
        ):
            self.assertIn(token, text)

    def test_planning_screen_references_are_versioned_and_not_runtime_assets(self) -> None:
        manifest = json.loads(REFERENCE_MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual("USER_APPROVED_PLANNING_REFERENCES_NOT_RUNTIME_ASSETS", manifest["status"])
        self.assertEqual(5, len(manifest["references"]))
        for reference in manifest["references"]:
            path = ROOT / reference["local_path"]
            self.assertTrue(path.is_file())
            self.assertEqual([1672, 941], reference["dimensions_px"])
            self.assertEqual(reference["sha256"], hashlib.sha256(path.read_bytes()).hexdigest())
            self.assertIn(reference["consumer_kind"], {"PLANNED_GAME_SURFACE", "PLAYER_FACING_EXPLANATORY"})
            self.assertEqual("PROJECT_SCREEN_REFERENCE_APPROVED_NOT_RUNTIME", reference["status"])


if __name__ == "__main__":
    unittest.main()
