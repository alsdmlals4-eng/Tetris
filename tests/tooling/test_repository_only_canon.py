"""Guard the user-approved repository-only current-owner boundary."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
AGENTS = ROOT / "AGENTS.md"
INDEX = ROOT / "docs" / "design" / "PRODUCTION_CANON_INDEX.json"
GDD = ROOT / "docs" / "design" / "PROJECT_MASTER_GDD.md"
VISUAL_BIBLE = ROOT / "docs" / "design" / "VISUAL_BIBLE.md"
SCREEN_INVENTORY = ROOT / "docs" / "design" / "SCREEN_SURFACE_INVENTORY.json"
SCREEN_GUIDE = ROOT / "docs" / "design" / "FULL_GAME_SCREEN_SURFACE_INVENTORY.md"
VISUAL_MANIFEST = ROOT / "docs" / "assets" / "reference" / "planned" / "PROJECT_UNDERSTANDING_VISUAL_MANIFEST.json"


class RepositoryOnlyCanonTests(unittest.TestCase):
    def test_current_owner_routing_is_repository_only(self) -> None:
        self.assertTrue(VISUAL_BIBLE.is_file(), "repository Visual Bible must exist")
        agents = AGENTS.read_text(encoding="utf-8")
        index = json.loads(INDEX.read_text(encoding="utf-8"))
        gdd = GDD.read_text(encoding="utf-8")
        visual = VISUAL_BIBLE.read_text(encoding="utf-8")

        self.assertIn("REPOSITORY_ONLY_CURRENT_OWNER", agents)
        self.assertEqual(index["project_human_facing_owner"], "REPOSITORY_ONLY")
        self.assertEqual(index["visual_bible"], "docs/design/VISUAL_BIBLE.md")
        self.assertIn("Notion is `HISTORICAL_EXTERNAL_PROVENANCE_ONLY`", gdd)
        self.assertIn("TETRIS-VISUAL-028", visual)
        self.assertIn("TETRIS-IMAGE-030", visual)
        self.assertIn("TETRIS-VIS-BOARD-001", visual)

    def test_current_visual_and_screen_records_have_repository_destinations(self) -> None:
        inventory = json.loads(SCREEN_INVENTORY.read_text(encoding="utf-8"))
        visual_manifest = json.loads(VISUAL_MANIFEST.read_text(encoding="utf-8"))
        guide = SCREEN_GUIDE.read_text(encoding="utf-8")

        self.assertEqual(inventory["project_human_facing_owner"], "REPOSITORY_ONLY")
        for screen in inventory["screens"]:
            self.assertIn("repository_owner", screen)
            self.assertNotIn("notion_destination", screen)
        board = visual_manifest["visuals"][0]
        self.assertEqual(board["repository_owner"], "docs/design/VISUAL_BIBLE.md")
        self.assertNotIn("Notion", guide)


if __name__ == "__main__":
    unittest.main()
