import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INDEX_PATH = ROOT / "docs" / "design" / "PRODUCTION_CANON_INDEX.json"
CANON_PATH = ROOT / "docs" / "design" / "PRODUCTION_TURN_COMBAT_CANON.md"
TIME_CANON_PATH = ROOT / "docs" / "design" / "PRODUCTION_TURN_TIME_CANON.md"
SKILL_CANON_PATH = ROOT / "docs" / "design" / "VANGUARD_TACTICAL_SKILL_MATRIX.md"
BALANCE_CANON_PATH = ROOT / "docs" / "design" / "DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md"
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
SKILL_PLAN_PATH = (
    ROOT
    / "docs"
    / "superpowers"
    / "plans"
    / "2026-08-24-vanguard-tactical-tier-matrix.md"
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
        self.assertEqual(
            data["skill_canon"],
            "docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md",
        )
        self.assertEqual(
            data["balance_canon"],
            "docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md",
        )
        self.assertEqual(data["current_core_decision"], "TETRIS-CORE-024")
        self.assertEqual(data["current_time_decision"], "TETRIS-TIME-025")
        self.assertEqual(data["current_skill_decision"], "TETRIS-SKILL-026")
        self.assertEqual(data["current_balance_decision"], "TETRIS-BALANCE-027")
        self.assertIn("TETRIS-CORE-021", data["retained_decisions"])
        self.assertIn("TETRIS-SKILL-022", data["retained_decisions"])
        self.assertIn("TETRIS-SKILL-026", data["retained_decisions"])
        self.assertIn("TETRIS-BALANCE-027", data["retained_decisions"])
        self.assertIn("TETRIS-UX-023", data["retained_decisions"])
        self.assertIn("TETRIS-VISUAL-020", data["retained_decisions"])
        self.assertIn("continuous_enemy_combat_clock", data["superseded_contracts"])
        self.assertIn("free_manual_board_switching", data["superseded_contracts"])
        self.assertIn("tactical_run_lock", data["superseded_contracts"])
        self.assertIn(
            "independent_line_chain_action_timers",
            data["superseded_contracts"],
        )
        self.assertIn(
            "linear_same_skill_tier_dominance",
            data["superseded_contracts"],
        )
        self.assertIn(
            "single_interchangeable_combat_resource",
            data["superseded_contracts"],
        )
        self.assertIn(
            "future_control_waits_for_hidden_unknown_intent",
            data["superseded_contracts"],
        )
        self.assertIn(
            "def_and_support_same_turn_resource_ward_overlap",
            data["superseded_contracts"],
        )

    def test_machine_readable_index_pins_current_plans(self) -> None:
        self.assertTrue(PLAN_PATH.is_file(), "production implementation plan must exist")
        self.assertTrue(TIME_PLAN_PATH.is_file(), "shared-turn timing plan must exist")
        self.assertTrue(SKILL_PLAN_PATH.is_file(), "tactical skill implementation plan must exist")
        data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
        self.assertEqual(
            data["implementation_plan"],
            "docs/superpowers/plans/2026-08-21-phased-turn-production-vertical-slice.md",
        )
        self.assertEqual(
            data["timing_implementation_plan"],
            "docs/superpowers/plans/2026-08-21-shared-turn-budget-tempo.md",
        )
        self.assertEqual(
            data["skill_implementation_plan"],
            "docs/superpowers/plans/2026-08-24-vanguard-tactical-tier-matrix.md",
        )
        plan = PLAN_PATH.read_text(encoding="utf-8")
        time_plan = TIME_PLAN_PATH.read_text(encoding="utf-8")
        skill_plan = SKILL_PLAN_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS-CORE-024", plan)
        self.assertIn("DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION", plan)
        self.assertIn("TETRIS-TIME-025", time_plan)
        self.assertIn("DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION", time_plan)
        self.assertIn("TETRIS-SKILL-026", skill_plan)
        self.assertIn("DO NOT EXECUTE UNTIL EXPLICIT BUILD AUTHORIZATION", skill_plan)

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

    def test_combat_canon_defers_timing_to_time_025(self) -> None:
        canon = CANON_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS-TIME-025", canon)
        self.assertIn("Shared Player Turn Budget", canon)
        self.assertNotIn("each phase has its own timer", canon)
        self.assertNotIn("Unused phase time is not banked into another phase", canon)
        self.assertNotIn(
            "phase time never transfers between Line, Chain, Action",
            canon,
        )

    def test_tactical_skill_canon_declares_situational_tiers(self) -> None:
        self.assertTrue(SKILL_CANON_PATH.is_file(), "tactical skill canon must exist")
        data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
        self.assertEqual(data["current_skill_decision"], "TETRIS-SKILL-026")
        self.assertEqual(
            data["skill_canon"],
            "docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md",
        )
        self.assertEqual(
            data["skill_implementation_plan"],
            "docs/superpowers/plans/2026-08-24-vanguard-tactical-tier-matrix.md",
        )
        skill = data["production_skill"]
        self.assertEqual(skill["tier_model"], "TACTICAL_COMMITMENT_BAND")
        self.assertTrue(skill["stock_cost_equals_tier"])
        self.assertTrue(skill["lower_tier_viability_required"])
        self.assertFalse(skill["highest_available_tier_is_default"])
        self.assertEqual(
            skill["implementation_model"],
            "DATA_DRIVEN_EFFECT_PRIMITIVES",
        )
        self.assertIn("DAMAGE_AOE", skill["effect_primitives"])
        self.assertIn("APPLY_SELF_BUFF", skill["effect_primitives"])
        self.assertIn("APPLY_ENEMY_DEBUFF", skill["effect_primitives"])
        self.assertIn("PROTECT_RESOURCE_LOSS", skill["effect_primitives"])
        self.assertIn("MODIFY_NEXT_TURN_BUDGET", skill["effect_primitives"])
        self.assertIn("HASTE_SECONDS", skill["tempo_non_scalable_fields"])
        self.assertEqual(
            skill["aoe_first_slice_validation"],
            "SINGLE_TARGET_FALLBACK_ONLY",
        )

        forecast = skill["forecast_control"]
        self.assertTrue(forecast["future_control_requires_visible_forecast"])
        self.assertTrue(forecast["future_control_binds_exact_action_id"])
        self.assertEqual(forecast["bound_action_invalidates_status"], "EXPIRE_NO_RETARGET")
        self.assertEqual(
            forecast["atk_t5_target"],
            "VISIBLE_NEXT_FORECAST_DIRECT_HIT",
        )
        self.assertEqual(
            forecast["def_t5_target"],
            "CURRENT_TELEGRAPH_RESOURCE_LOSS",
        )
        self.assertEqual(
            forecast["sup_t5_target"],
            "VISIBLE_NEXT_FORECAST_RESOURCE_LOSS_OR_REPAIR",
        )
        self.assertFalse(forecast["future_control_applies_to_current_telegraph"])

        canon = SKILL_CANON_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS-SKILL-026", canon)
        self.assertIn("Quick Cut", canon)
        self.assertIn("Rift Breach", canon)
        self.assertIn("Last Bastion", canon)
        self.assertIn("Battle Trance", canon)
        self.assertIn("Current vs future response ownership", canon)
        self.assertIn("visible lower-priority Next Forecast", canon)
        self.assertIn("CLEAN_REVIEW_EXIT", canon)
        self.assertIn("BUILD remains blocked", canon)

    def test_balance_canon_keeps_dual_resources_and_progressive_tier_exposure(self) -> None:
        self.assertTrue(BALANCE_CANON_PATH.is_file(), "balance canon must exist")
        data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
        self.assertEqual(data["current_balance_decision"], "TETRIS-BALANCE-027")
        self.assertEqual(
            data["balance_canon"],
            "docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md",
        )
        economy = data["resource_economy"]
        self.assertEqual(economy["model"], "DUAL_RESOURCE_OPPORTUNITY_COST")
        self.assertEqual(economy["energy_owner"], "LINE")
        self.assertEqual(economy["stock_owner"], "CHAIN")
        self.assertFalse(economy["resources_interchangeable"])
        self.assertEqual(economy["chain_stock_cap"], 6)
        self.assertTrue(economy["stock_cost_equals_tier"])
        self.assertEqual(economy["energy_cost_status"], "TUNING_SEED_NOT_FINAL")
        self.assertEqual(
            economy["tier_exposure_model"],
            "CONTEXTUAL_PROGRESSIVE_EXPOSURE",
        )
        self.assertFalse(economy["tutorial_grants_resources_directly"])
        self.assertTrue(economy["tutorial_uses_authored_production_board_seed"])
        self.assertFalse(economy["tier6_routine_per_turn_expectation"])
        self.assertFalse(economy["technique_specific_first_slice_currency"])
        self.assertFalse(economy["technique_specific_first_slice_cooldown"])
        self.assertFalse(economy["tempo_direct_resource_reward"])
        self.assertEqual(
            economy["current_resource_loss_response"],
            ["DEF_T5_RIFT_WARD", "PRESPEND_THREATENED_RESOURCE"],
        )
        self.assertEqual(
            economy["future_rift_utility_forecast_response"],
            ["SUP_T5_RIFT_SEAL", "PRESERVE_FOR_OTHER_RESPONSE"],
        )
        self.assertTrue(economy["human_balance_evidence_required"])

        canon = BALANCE_CANON_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS-BALANCE-027", canon)
        self.assertIn("DUAL-RESOURCE", canon.upper())
        self.assertIn("Current vs future control rule", canon)
        self.assertIn("DEF T5 Rift Ward", canon)
        self.assertIn("SUP T5 Rift Seal", canon)
        self.assertIn("Tier 6", canon)
        self.assertIn("CLEAN_REVIEW_EXIT", canon)
        self.assertIn("BUILD remains deferred", canon)

    def test_human_entrypoints_point_to_current_production_canons(self) -> None:
        combat_expected = "docs/design/PRODUCTION_TURN_COMBAT_CANON.md"
        time_expected = "docs/design/PRODUCTION_TURN_TIME_CANON.md"
        skill_expected = "docs/design/VANGUARD_TACTICAL_SKILL_MATRIX.md"
        balance_expected = "docs/design/DUAL_RESOURCE_TIER_EXPOSURE_CONTRACT.md"
        agents = AGENTS_PATH.read_text(encoding="utf-8")
        readme = README_PATH.read_text(encoding="utf-8")
        self.assertIn(combat_expected, agents)
        self.assertIn(combat_expected, readme)
        self.assertIn(time_expected, agents)
        self.assertIn(time_expected, readme)
        self.assertIn(skill_expected, agents)
        self.assertIn(skill_expected, readme)
        self.assertIn(balance_expected, agents)
        self.assertIn(balance_expected, readme)

    def test_current_canons_separate_foundation_from_production_evidence(self) -> None:
        canon = CANON_PATH.read_text(encoding="utf-8")
        time_canon = TIME_CANON_PATH.read_text(encoding="utf-8")
        skill_canon = SKILL_CANON_PATH.read_text(encoding="utf-8")
        balance_canon = BALANCE_CANON_PATH.read_text(encoding="utf-8")
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
        self.assertIn("TETRIS-SKILL-026", skill_canon)
        self.assertIn("Tier is a commitment/cost band", skill_canon)
        self.assertIn("Current claims forbidden", skill_canon)
        self.assertIn("TETRIS-BALANCE-027", balance_canon)
        self.assertIn("TUNE_REQUIRED", balance_canon)
        self.assertIn("Current claims forbidden", balance_canon)


if __name__ == "__main__":
    unittest.main()
