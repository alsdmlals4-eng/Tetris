import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INDEX_PATH = ROOT / "docs" / "design" / "PRODUCTION_CANON_INDEX.json"
REALTIME_CANON_PATH = ROOT / "docs" / "design" / "PRODUCTION_REALTIME_COMBAT_CANON.md"
TURN_CANON_PATH = "docs/design/PRODUCTION_TURN_COMBAT_CANON.md"
TIME_CANON_PATH = "docs/design/PRODUCTION_TURN_TIME_CANON.md"
SKILL_CANON_PATH = ROOT / "docs" / "design" / "VANGUARD_TACTICAL_SKILL_MATRIX.md"
BALANCE_CANON_PATH = ROOT / "docs" / "design" / "DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md"
PLAN_PATH = (
    ROOT
    / "docs"
    / "superpowers"
    / "plans"
    / "2026-08-26-continuous-realtime-mode-switch-combat.md"
)
AGENTS_PATH = ROOT / "AGENTS.md"
README_PATH = ROOT / "README.md"


class ProductionCanonContractTests(unittest.TestCase):
    def _index(self) -> dict:
        self.assertTrue(INDEX_PATH.is_file(), "production canon index must exist")
        return json.loads(INDEX_PATH.read_text(encoding="utf-8"))

    def test_machine_readable_index_declares_core_029_authority(self) -> None:
        data = self._index()

        self.assertEqual(data["schema_version"], 3)
        self.assertEqual(data["project"], "TETRIS")
        self.assertEqual(data["status"], "CURRENT_PRODUCTION_CANON")
        self.assertEqual(data["current_core_decision"], "TETRIS-CORE-029")
        self.assertEqual(
            data["primary_canon"],
            "docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md",
        )
        self.assertEqual(
            data["implementation_plan"],
            "docs/superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md",
        )
        self.assertEqual(data["current_skill_decision"], "TETRIS-SKILL-026")
        self.assertEqual(data["current_balance_decision"], "TETRIS-BALANCE-027")
        self.assertEqual(
            data["skill_canon"],
            "docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md",
        )
        self.assertEqual(
            data["balance_canon"],
            "docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md",
        )

    def test_continuous_realtime_time_and_workspace_contract_is_machine_readable(self) -> None:
        data = self._index()
        combat_time = data["combat_time"]

        self.assertEqual(combat_time["model"], "CONTINUOUS_REALTIME")
        self.assertEqual(combat_time["encounter_end"], "VICTORY_OR_DEFEAT")
        self.assertEqual(combat_time["active_workspaces"], ["LINE", "CHAIN"])
        self.assertTrue(combat_time["free_workspace_switching"])
        self.assertFalse(combat_time["inactive_workspace_simulates"])
        self.assertEqual(combat_time["skill_mode"], "FULL_TACTICAL_PAUSE")
        self.assertEqual(combat_time["manual_pause"], "FULL_SIMULATION_PAUSE")
        self.assertFalse(combat_time["shared_player_turn_budget"])
        self.assertFalse(combat_time["tempo_bonus"])

    def test_ui_contract_declares_one_large_puzzle_surface_without_sidecar(self) -> None:
        data = self._index()
        ui = data["ui"]

        self.assertEqual(ui["puzzle_surface_target_ratio"], 0.60)
        self.assertEqual(ui["combat_surface_target_ratio"], 0.40)
        self.assertFalse(ui["mandatory_sidecar"])

    def test_supersession_contract_reenables_realtime_clock_and_free_switching(self) -> None:
        data = self._index()
        superseded = data["superseded_contracts"]

        self.assertNotIn("continuous_enemy_combat_clock", superseded)
        self.assertNotIn("free_manual_board_switching", superseded)
        self.assertIn("ordered_line_chain_action_enemy_turn", superseded)
        self.assertIn("shared_player_turn_budget", superseded)
        self.assertIn("ready_stage_handoff", superseded)
        self.assertIn("turn_timeout_pass_flow", superseded)
        self.assertIn("tempo_turn_speed_reward", superseded)

    def test_realtime_canon_exists_and_historical_turn_canons_are_routed_as_provenance(self) -> None:
        data = self._index()
        self.assertTrue(REALTIME_CANON_PATH.is_file(), "CORE-029 realtime canon must exist")
        realtime = REALTIME_CANON_PATH.read_text(encoding="utf-8")
        historical = data["historical_production_documents"]

        self.assertIn("TETRIS-CORE-029", realtime)
        self.assertIn("CONTINUOUS_REALTIME", realtime)
        self.assertIn("TACTICAL_PAUSE_SKILL", realtime)
        self.assertIn("LINE", realtime)
        self.assertIn("CHAIN", realtime)
        self.assertIn("FULL_TACTICAL_PAUSE", realtime)
        self.assertIn(TURN_CANON_PATH, historical)
        self.assertIn(TIME_CANON_PATH, historical)
        self.assertIn("TETRIS-CORE-024", realtime)
        self.assertIn("TETRIS-TIME-025", realtime)
        self.assertIn("HISTORICAL", realtime)
        self.assertIn("SUPERSEDED", realtime)

    def test_retained_skill_and_balance_authorities_are_not_silently_rewritten(self) -> None:
        data = self._index()
        retained = data["retained_decisions"]

        self.assertIn("TETRIS-SKILL-026", retained)
        self.assertIn("TETRIS-BALANCE-027", retained)
        self.assertIn("TETRIS-VISUAL-028", retained)
        self.assertTrue(SKILL_CANON_PATH.is_file())
        self.assertTrue(BALANCE_CANON_PATH.is_file())
        self.assertIn("TETRIS-SKILL-026", SKILL_CANON_PATH.read_text(encoding="utf-8"))
        self.assertIn("TETRIS-BALANCE-027", BALANCE_CANON_PATH.read_text(encoding="utf-8"))

    def test_human_entrypoints_route_to_realtime_canon_and_plan(self) -> None:
        self.assertTrue(PLAN_PATH.is_file(), "CORE-029 implementation plan must exist")
        agents = AGENTS_PATH.read_text(encoding="utf-8")
        readme = README_PATH.read_text(encoding="utf-8")

        for text in (agents, readme):
            self.assertIn("docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md", text)
            self.assertIn("TETRIS-CORE-029", text)
            self.assertIn("docs/superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md", text)
            self.assertNotIn("One turn is `Enemy Telegraph → Line Phase → Line Settle → Chain Phase", text)


if __name__ == "__main__":
    unittest.main()
