import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INDEX_PATH = ROOT / "docs" / "design" / "PRODUCTION_CANON_INDEX.json"
CANON_PATH = ROOT / "docs" / "design" / "PRODUCTION_TURN_COMBAT_CANON.md"
TIME_CANON_PATH = ROOT / "docs" / "design" / "PRODUCTION_TURN_TIME_CANON.md"
PLAN_PATH = (
    ROOT
    / "docs"
    / "superpowers"
    / "plans"
    / "2026-08-21-phased-turn-production-vertical-slice.md"
)
TIME_PLAN_PATH = (
    ROOT
    / "docs"
    / "superpowers"
    / "plans"
    / "2026-08-21-shared-turn-budget-tempo.md"
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
        self.assertEqual(
            data["timing_canon"],
            "docs/design/PRODUCTION_TURN_TIME_CANON.md",
        )
        self.assertEqual(data["current_core_decision"], "TETRIS-CORE-024")
        self.assertEqual(data["current_time_decision"], "TETRIS-TIME-025")
        self.assertIn("TETRIS-CORE-021", data["retained_decisions"])
        self.assertIn("TETRIS-SKILL-022", data["retained_decisions"])
        self.assertIn("TETRIS-UX-023", data["retained_decisions"])
        self.assertIn("TETRIS-VISUAL-020", data["retained_decisions"])
        self.assertIn("continuous_enemy_combat_clock", data["superseded_contracts"])
        self.assertIn("free_manual_board_switching", data["superseded_contracts"])
        self.assertIn("tactical_run_lock", data["superseded_contracts"])
        self.assertIn(
            "independent_line_chain_action_timers",
            data["superseded_contracts"],
        )

    def test_machine_readable_index_pins_current_plans(self) -> None:
        self.assertTrue(PLAN_PATH.is_file(), "production implementation plan must exist")
        self.assertTrue(TIME_PLAN_PATH.is_file(), "shared-turn timing plan must exist")
        data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
        self.assertEqual(
            data["implementation_plan"],
            "docs/superpowers/plans/2026-08-21-phased-turn-production-vertical-slice.md",
        )
        self.assertEqual(
            data["timing_implementation_plan"],
            "docs/superpowers/plans/2026-08-21-shared-turn-budget-tempo.md",
        )
        plan = PLAN_PATH.read_text(encoding="utf-8")
        time_plan = TIME_PLAN_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS-CORE-024", plan)
        self.assertIn("DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION", plan)
        self.assertIn("TETRIS-TIME-025", time_plan)
        self.assertIn("DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION", time_plan)

    def test_shared_turn_budget_contract_is_machine_readable(self) -> None:
        data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
        turn_time = data["turn_time"]
        self.assertEqual(turn_time["model"], "SHARED_PLAYER_TURN_BUDGET")
        self.assertEqual(turn_time["budget_spans"], ["LINE", "CHAIN", "ACTION"])
        self.assertTrue(turn_time["early_finish"])
        self.assertEqual(turn_time["early_finish_reward"], "TEMPO_BONUS")
        self.assertFalse(turn_time["settle_consumes_budget"])
        self.assertFalse(turn_time["modifier_changes_tempo_reference"])
        self.assertFalse(turn_time["unused_time_banks_to_future_turn"])

    def test_human_entrypoints_point_to_current_production_canons(self) -> None:
        combat_expected = "docs/design/PRODUCTION_TURN_COMBAT_CANON.md"
        time_expected = "docs/design/PRODUCTION_TURN_TIME_CANON.md"
        agents = AGENTS_PATH.read_text(encoding="utf-8")
        readme = README_PATH.read_text(encoding="utf-8")
        self.assertIn(combat_expected, agents)
        self.assertIn(combat_expected, readme)
        self.assertIn(time_expected, agents)
        self.assertIn(time_expected, readme)

    def test_current_canons_separate_foundation_from_production_evidence(self) -> None:
        canon = CANON_PATH.read_text(encoding="utf-8")
        time_canon = TIME_CANON_PATH.read_text(encoding="utf-8")
        self.assertIn("Core Combat Foundation / Engineering Harness", canon)
        self.assertIn("TETRIS-CORE-024", canon)
        self.assertIn("Attack / Defense / Support", canon)
        self.assertIn("Tier 1–6", canon)
        self.assertIn("PASS", canon)
        self.assertIn("background resolver", canon)
        self.assertIn("TETRIS-TIME-025", time_canon)
        self.assertIn("shared", time_canon.lower())
        self.assertIn("Tempo Bonus", time_canon)
        self.assertIn("tempo reference", time_canon.lower())
        self.assertIn("NOT_PRESENT", time_canon)


if __name__ == "__main__":
    unittest.main()
