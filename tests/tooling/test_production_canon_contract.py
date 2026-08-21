import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INDEX_PATH = ROOT / "docs" / "design" / "PRODUCTION_CANON_INDEX.json"
CANON_PATH = ROOT / "docs" / "design" / "PRODUCTION_TURN_COMBAT_CANON.md"
PLAN_PATH = (
    ROOT
    / "docs"
    / "superpowers"
    / "plans"
    / "2026-08-21-phased-turn-production-vertical-slice.md"
)
AGENTS_PATH = ROOT / "AGENTS.md"
README_PATH = ROOT / "README.md"


class ProductionCanonContractTests(unittest.TestCase):
    def test_machine_readable_index_declares_current_production_authority(self) -> None:
        self.assertTrue(INDEX_PATH.is_file(), "production canon index must exist")
        data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))

        self.assertEqual(data["project"], "TETRIS")
        self.assertEqual(data["status"], "CURRENT_PRODUCTION_CANON")
        self.assertEqual(
            data["primary_canon"],
            "docs/design/PRODUCTION_TURN_COMBAT_CANON.md",
        )
        self.assertEqual(data["current_core_decision"], "TETRIS-CORE-024")
        self.assertIn("TETRIS-CORE-021", data["retained_decisions"])
        self.assertIn("TETRIS-SKILL-022", data["retained_decisions"])
        self.assertIn("TETRIS-UX-023", data["retained_decisions"])
        self.assertIn("TETRIS-VISUAL-020", data["retained_decisions"])
        self.assertIn("continuous_enemy_combat_clock", data["superseded_contracts"])
        self.assertIn("free_manual_board_switching", data["superseded_contracts"])
        self.assertIn("tactical_run_lock", data["superseded_contracts"])

    def test_machine_readable_index_pins_the_current_implementation_plan(self) -> None:
        self.assertTrue(PLAN_PATH.is_file(), "production implementation plan must exist")
        data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
        self.assertEqual(
            data["implementation_plan"],
            "docs/superpowers/plans/2026-08-21-phased-turn-production-vertical-slice.md",
        )
        plan = PLAN_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS-CORE-024", plan)
        self.assertIn("DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION", plan)

    def test_human_entrypoints_point_to_the_current_production_canon(self) -> None:
        expected = "docs/design/PRODUCTION_TURN_COMBAT_CANON.md"
        agents = AGENTS_PATH.read_text(encoding="utf-8")
        readme = README_PATH.read_text(encoding="utf-8")
        self.assertIn(expected, agents)
        self.assertIn(expected, readme)

    def test_current_canon_separates_foundation_from_production_evidence(self) -> None:
        canon = CANON_PATH.read_text(encoding="utf-8")
        self.assertIn("Core Combat Foundation / Engineering Harness", canon)
        self.assertIn("TETRIS-CORE-024", canon)
        self.assertIn("Attack / Defense / Support", canon)
        self.assertIn("Tier 1–6", canon)
        self.assertIn("30 s", canon)
        self.assertIn("PASS", canon)
        self.assertIn("background resolver", canon)


if __name__ == "__main__":
    unittest.main()
