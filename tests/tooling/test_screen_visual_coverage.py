"""Target screen/visual coverage documentation contract."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
INVENTORY = ROOT / "docs/design/TARGET_SCREEN_SURFACE_INVENTORY.md"
MATRIX = ROOT / "docs/design/SCREEN_TO_VISUAL_COVERAGE_MATRIX.md"


class ScreenVisualCoverageTests(unittest.TestCase):
    def test_inventory_covers_required_target_surface_families(self) -> None:
        text = INVENTORY.read_text(encoding="utf-8")
        for token in (
            "TETRIS-SCREEN-001",
            "TETRIS-SCREEN-002",
            "TETRIS-SCREEN-003",
            "MAIN_TITLE_MENU",
            "BATTLE_COMBAT",
            "SPECIAL_ACTION_OVERLAY",
            "RESULT_REWARD",
            "PAUSE_SETTINGS",
            "LOADING_TRANSITION_ERROR",
            "NOT_APPLICABLE",
            "P0 blocking gaps: **0",
        ):
            self.assertIn(token, text)

    def test_matrix_separates_runtime_components_from_screen_references(self) -> None:
        text = MATRIX.read_text(encoding="utf-8")
        for token in (
            "SCREEN_DESIGN_REFERENCE",
            "RUNTIME_COMPONENT_ASSET",
            "GODOT_UI",
            "NO_NEW_IMAGE_FILE_REQUIRED",
            "MainRow/CombatColumn/CombatStage/StageBackdrop",
            "VanguardReference",
            "GatebreakerReference",
            "NO_AUTOMATIC_IMAGE_GENERATION_FROM_GAPS",
        ):
            self.assertIn(token, text)


if __name__ == "__main__":
    unittest.main()
