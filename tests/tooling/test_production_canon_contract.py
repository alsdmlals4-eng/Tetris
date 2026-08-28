import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INDEX_PATH = ROOT / "docs" / "design" / "PRODUCTION_CANON_INDEX.json"
REALTIME_CANON_PATH = ROOT / "docs" / "design" / "PRODUCTION_REALTIME_COMBAT_CANON.md"
IMAGE_CONTRACT_PATH = ROOT / "docs" / "design" / "RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md"
TURN_CANON_PATH = "docs/design/PRODUCTION_TURN_COMBAT_CANON.md"
TIME_CANON_PATH = "docs/design/PRODUCTION_TURN_TIME_CANON.md"
SKILL_CANON_PATH = ROOT / "docs" / "design" / "VANGUARD_TACTICAL_SKILL_MATRIX.md"
BALANCE_CANON_PATH = ROOT / "docs" / "design" / "DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md"
ONBOARDING_CONTRACT_PATH = ROOT / "docs" / "design" / "FIRST_SESSION_ONBOARDING_CONTRACT.md"
CHAIN_CONTRACT_PATH = ROOT / "docs" / "design" / "CHAIN_COMBO_MP_CONTRACT.md"
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
        self.assertEqual(data["current_onboarding_decision"], "TETRIS-ONBOARDING-037")
        self.assertEqual(data["current_chain_decision"], "TETRIS-CHAIN-038")
        self.assertEqual(
            data["skill_canon"],
            "docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md",
        )
        self.assertEqual(
            data["balance_canon"],
            "docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md",
        )
        self.assertEqual(
            data["onboarding_contract"],
            "docs/design/FIRST_SESSION_ONBOARDING_CONTRACT.md",
        )
        self.assertEqual(
            data["chain_combo_mp_contract"],
            "docs/design/CHAIN_COMBO_MP_CONTRACT.md",
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
        self.assertIn("TETRIS-ONBOARDING-037", retained)
        self.assertIn("TETRIS-CHAIN-038", retained)
        self.assertTrue(SKILL_CANON_PATH.is_file())
        self.assertTrue(BALANCE_CANON_PATH.is_file())
        self.assertIn("TETRIS-SKILL-026", SKILL_CANON_PATH.read_text(encoding="utf-8"))
        self.assertIn("TETRIS-BALANCE-027", BALANCE_CANON_PATH.read_text(encoding="utf-8"))

    def test_chain_contract_keeps_line_mp_and_chain_combo_distinct(self) -> None:
        data = self._index()
        chain = data["production_chain"]
        economy = data["resource_economy"]
        resources = data["resource_economy"]["player_facing_resources"]
        text = CHAIN_CONTRACT_PATH.read_text(encoding="utf-8")

        self.assertTrue(CHAIN_CONTRACT_PATH.is_file())
        self.assertEqual(chain["swap_adjacency"], "ORTHOGONAL_ONLY")
        self.assertEqual(
            chain["match_axes"],
            ["HORIZONTAL", "VERTICAL", "DIAGONAL_DOWN_RIGHT", "DIAGONAL_DOWN_LEFT"],
        )
        self.assertEqual(chain["invalid_swap_default"], "RESTORE_PRE_SWAP_STATE")
        self.assertEqual(chain["mp_lock_cost"], 1)
        self.assertEqual(economy["mp_lock_cost_status"], "USER_APPROVED_FIXED_1_MP")
        self.assertEqual(resources["mp"]["owner"], "LINE")
        self.assertEqual(resources["mp"]["runtime_field"], "energy")
        self.assertEqual(resources["combo"]["owner"], "CHAIN")
        self.assertEqual(resources["combo"]["runtime_field"], "stock")
        for token in (
            "TETRIS-CHAIN-038",
            "DIAGONAL_DOWN_RIGHT",
            "DIAGONAL_DOWN_LEFT",
            "fixed **1 MP**",
            "TUNE_REQUIRED",
        ):
            self.assertIn(token, text)

    def test_first_session_contract_is_approved_but_not_runtime_proof(self) -> None:
        data = self._index()
        reality = data["implementation_reality"]
        onboarding = ONBOARDING_CONTRACT_PATH.read_text(encoding="utf-8")

        self.assertTrue(ONBOARDING_CONTRACT_PATH.is_file())
        self.assertEqual(
            reality["first_session_briefing_and_tutorial"],
            "USER_APPROVED_DOCUMENTED_NOT_IMPLEMENTED",
        )
        for token in (
            "TETRIS-ONBOARDING-037",
            "Vanguard",
            "Frontier Gate",
            "Gatebreaker",
            "Current Telegraph and ETA",
            "USER_APPROVED / PHASE 1 CANON / DOCUMENTED_NOT_IMPLEMENTED",
        ):
            self.assertIn(token, onboarding)
        self.assertIn("Shared Turn Timer", onboarding)
        self.assertIn("3×6", onboarding)

    def test_image_production_requires_a_runtime_consumer_contract(self) -> None:
        data = self._index()
        image_production = data["image_production"]
        self.assertEqual(
            data["image_asset_contract"],
            "docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md",
        )
        self.assertEqual(
            image_production["generation_status"],
            "PAUSED_PENDING_APPROVED_CONSUMER_GAP",
        )
        self.assertTrue(IMAGE_CONTRACT_PATH.is_file())
        text = IMAGE_CONTRACT_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS-IMAGE-030", text)
        self.assertIn("target res:// asset path", text)
        self.assertIn("consumer scene path", text)
        self.assertIn("consumer node / material / UI slot", text)
        self.assertIn("concept sheet", text)
        self.assertIn("new image generation remains **PAUSED**", text)

    def test_current_main_reality_does_not_describe_core_029_as_unimplemented(self) -> None:
        data = self._index()
        reality = data["implementation_reality"]
        readme = README_PATH.read_text(encoding="utf-8")
        image_contract = IMAGE_CONTRACT_PATH.read_text(encoding="utf-8")

        for key in (
            "core_029_runtime",
            "production_line_workspace",
            "production_chain_workspace",
            "simulation_pause_controller",
            "enemy_realtime_scheduler",
            "skill_tactical_pause_runtime",
            "production_60_40_ui",
            "runtime_image_consumers",
        ):
            self.assertEqual(reality[key], "IMPLEMENTED_ON_MERGED_MAIN")
        self.assertEqual(
            reality["merged_main_runtime"],
            "RUNTIME_BASELINE_1A5C5AA_AUTOMATED_READY_TREE_EQUIVALENT_SOURCE_HEAD",
        )
        self.assertEqual(
            reality["runtime_evidence_identity"],
            "RUNTIME_BASELINE_1A5C5AA_SOURCE_HEAD_CI_AND_RUNTIME_EVIDENCE",
        )
        self.assertEqual(
            reality["runtime_baseline_main_sha"],
            "1a5c5aab84d7b6e11c3a4431a71eecb27b0ea55a",
        )
        self.assertEqual(
            reality["runtime_evidence_source_head_sha"],
            "92b59bccd2ea45f772003b4abac2d9aa84672307",
        )
        self.assertEqual(
            reality["documentation_reconciliation_base_sha"],
            "fb55b96f2612497f356bae6586429b944d35d7a8",
        )
        self.assertEqual(reality["production_human_playtest"], "NOT_RUN")
        self.assertIn("CORE-029 Production runtime: **main에 구현됨**", readme)
        self.assertIn("1a5c5aab84d7b6e11c3a4431a71eecb27b0ea55a", readme)
        self.assertIn("92b59bccd2ea45f772003b4abac2d9aa84672307", readme)
        self.assertIn("fb55b96f2612497f356bae6586429b944d35d7a8", readme)
        self.assertNotIn("CORE-029 Production runtime: **아직 NOT_PRESENT**", readme)
        self.assertIn("TETRIS-IMG-031", image_contract)
        self.assertIn(
            "MainRow/CombatColumn/CombatStage/StageBackdrop", image_contract
        )

    def test_human_entrypoints_route_to_realtime_canon_and_plan(self) -> None:
        self.assertTrue(PLAN_PATH.is_file(), "CORE-029 implementation plan must exist")
        agents = AGENTS_PATH.read_text(encoding="utf-8")
        readme = README_PATH.read_text(encoding="utf-8")

        for text in (agents, readme):
            self.assertIn("docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md", text)
            self.assertIn("docs/design/CHAIN_COMBO_MP_CONTRACT.md", text)
            self.assertIn("TETRIS-CORE-029", text)
            self.assertIn("docs/superpowers/plans/2026-08-26-continuous-realtime-mode-switch-combat.md", text)
            self.assertNotIn("One turn is `Enemy Telegraph → Line Phase → Line Settle → Chain Phase", text)
        self.assertIn("TETRIS-CHAIN-038 amendment", PLAN_PATH.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
