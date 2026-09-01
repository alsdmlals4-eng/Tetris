"""Canonical-reader GDD and planning-board classification checks."""

from __future__ import annotations

import hashlib
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GDD_PATH = ROOT / "docs" / "design" / "PROJECT_MASTER_GDD.md"
IMAGE_CONTRACT_PATH = ROOT / "docs" / "design" / "RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md"
CANON_INDEX_PATH = ROOT / "docs" / "design" / "PRODUCTION_CANON_INDEX.json"
AGENTS_PATH = ROOT / "AGENTS.md"
VISUAL_MANIFEST_PATH = ROOT / "docs" / "assets" / "reference" / "planned" / "PROJECT_UNDERSTANDING_VISUAL_MANIFEST.json"
BOARD_PATH = ROOT / "docs" / "assets" / "reference" / "planned" / "tetris-project-core-scene-visual-board-v2.png"


class ProjectMasterGddContractTests(unittest.TestCase):
    def test_master_gdd_distinguishes_canon_from_current_runtime_reality(self) -> None:
        self.assertTrue(GDD_PATH.is_file(), "Master GDD must exist")
        text = GDD_PATH.read_text(encoding="utf-8")

        for token in (
            "TETRIS-CORE-029",
            "TETRIS-CHAIN-038",
            "TETRIS-ONBOARDING-037",
            "CONTINUOUS_REALTIME",
            "CHAIN_RESOURCE_ALIGNMENT_IMPLEMENTED_MACHINE_VERIFIED",
            "MP 60 / Combo 10",
            "USER_APPROVED_DOCUMENTED_NOT_IMPLEMENTED",
            "Human/player evidence: NOT_RUN",
            "CURRENT",
            "HISTORICAL",
            "SUPERSEDED",
            "CONFLICT",
            "UNKNOWN_UNVERIFIED",
        ):
            self.assertIn(token, text)

    def test_auto_generation_requires_lock_and_preserves_runtime_consumer_gate(self) -> None:
        index = json.loads(CANON_INDEX_PATH.read_text(encoding="utf-8"))
        image_production = index["image_production"]
        contract = IMAGE_CONTRACT_PATH.read_text(encoding="utf-8")
        agents = AGENTS_PATH.read_text(encoding="utf-8")

        self.assertEqual(
            image_production["planning_generation_policy"],
            "AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION",
        )
        self.assertEqual(
            image_production["runtime_generation_policy"],
            "EXACT_CONSUMER_REQUIRED_AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION",
        )
        self.assertFalse(image_production["one_explicit_approval_one_image"])
        self.assertIn("AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION", contract)
        self.assertIn("exact Godot runtime consumer", contract)
        self.assertIn("does not become a runtime asset", contract)
        self.assertIn("AUTO_GENERATE_THEN_USER_LOCK_CONFIRMATION", agents)
        self.assertIn("GENERATED_EXPLORATION", agents)

    def test_core_scene_board_is_a_planning_reference_not_a_runtime_asset(self) -> None:
        self.assertTrue(BOARD_PATH.is_file())
        manifest = json.loads(VISUAL_MANIFEST_PATH.read_text(encoding="utf-8"))
        visuals = {item["asset_id"]: item for item in manifest["visuals"]}
        board = visuals["TETRIS-VIS-BOARD-002"]

        self.assertEqual(board["local_path"], "docs/assets/reference/planned/tetris-project-core-scene-visual-board-v2.png")
        self.assertEqual(board["classification"], "GENERATED_EXPLORATION")
        self.assertEqual(board["runtime_consumer"], "NONE")
        self.assertEqual(board["status"], "USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME")
        self.assertEqual(board["sha256"], hashlib.sha256(BOARD_PATH.read_bytes()).hexdigest())
        self.assertEqual(visuals["TETRIS-VIS-BOARD-001"]["status"], "SUPERSEDED_BY_TETRIS-VIS-BOARD-002")


if __name__ == "__main__":
    unittest.main()
