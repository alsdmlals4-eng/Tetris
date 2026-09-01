"""콤보 단계 자동 해석 스킬 정본과 실제 런타임 경계를 검증한다."""

from __future__ import annotations

import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "docs/design/PRODUCTION_CANON_INDEX.json"
CONTRACT = ROOT / "docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md"
CONTENT_GDD = ROOT / "docs/design/COMBO_STAGE_SKILL_CONTENT_GDD.md"
PHASE2_PLAN = ROOT / "docs/superpowers/plans/2026-08-29-phase2-tactical-core-alignment.md"
VISUAL_BIBLE = ROOT / "docs/design/VISUAL_BIBLE.md"
MASTER_GDD = ROOT / "docs/design/PROJECT_MASTER_GDD.md"
WORKSPACE_INDEX = ROOT / "docs/design/PROJECT_WORKSPACE_INDEX.md"
MANIFEST = ROOT / "docs/assets/reference/planned/PROJECT_UNDERSTANDING_VISUAL_MANIFEST.json"
SKILL_SESSION = ROOT / "src/production/skill/production_skill_session.gd"
BATTLE_UI = ROOT / "src/production/ui/production_battle.gd"
CATALOG = ROOT / "src/production/skill/production_skill_catalog.gd"
SKILL_SEED = ROOT / "data/production/vanguard_skill_seed.json"
AGENTS = ROOT / "AGENTS.md"


class ComboResolvedSkillContractTests(unittest.TestCase):
    def test_current_decisions_route_to_category_resolved_skill_and_parchment_visual(self) -> None:
        index = json.loads(INDEX.read_text(encoding="utf-8"))

        self.assertEqual("TETRIS-SKILL-039", index["current_skill_decision"])
        self.assertEqual("TETRIS-BALANCE-040", index["current_balance_decision"])
        self.assertEqual("TETRIS-VISUAL-041", index["current_visual_decision"])
        self.assertEqual("docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md", index["combo_resolved_skill_contract"])

    def test_category_preview_confirm_and_bounded_fallback_are_exact(self) -> None:
        text = CONTRACT.read_text(encoding="utf-8")
        for required in (
            "`ATK / DEF / SUP` only",
            "no manual Tier button",
            "explicit CONFIRM",
            "Combo cap is **10**",
            "5 MP per converted Combo",
            "highest feasible lower Stage",
            "Preview never spends MP or Combo",
            "automatic resolution after CONFIRM",
            "not unattended auto-cast",
            "Stage 1–10 content",
        ):
            self.assertIn(required, text)

    def test_user_approved_board_opportunity_mechanism_is_not_misdescribed_as_global_time(self) -> None:
        text = CONTENT_GDD.read_text(encoding="utf-8")
        for required in (
            "`12.0`-second maximum reserve",
            "LINE gravity/lock advancement",
            "LINE input stays enabled",
            "does not change the scheduler's full real delta",
            "USER_APPROVED / PHASE 2 MECHANISM LOCK / NOT IMPLEMENTED",
        ):
            self.assertIn(required, text)

    def test_phase_two_plan_preserves_formula_reserve_edges_and_atomic_effect_commit(self) -> None:
        text = PHASE2_PLAN.read_text(encoding="utf-8")
        for required in (
            "(5 + 5 - 3) + post-wave Combo 5",
            "partial-frame expiry",
            "leaves LINE input enabled",
            "preflight_effects",
            "restore_effect_checkpoint",
            'request_switch("CHAIN")',
            "FORCED_EXECUTION_FAILURE",
            "modifiers_for_action",
            "snapshot_current_action_state",
            "_catalog_with_current_stage_effects",
            "resource_restored",
            '"reason": "ROLLBACK_FAILED"',
            "test_time_owner_restore_rejects_invalid_or_advanced_state_without_mutation",
            "remaining_after_advance",
            "committed_after_advance",
            "reserve.restore_state({})",
            "git fetch origin main",
        ):
            self.assertIn(required, text)

    def test_current_skill_delivery_connects_time_primitives_to_the_category_only_runtime_flow(self) -> None:
        contract = CONTRACT.read_text(encoding="utf-8")
        self.assertIn("IMPLEMENTED_MACHINE_VERIFIED_PENDING_RUNTIME_AND_HUMAN_EVIDENCE", contract)
        self.assertIn("PlayerBoardOpportunityState", contract)
        self.assertIn("EnemyActionScheduler", contract)
        self.assertIn("TierGrid` and manual Tier selection are absent", contract)
        self.assertIn("stage < 1 or stage > 10", CATALOG.read_text(encoding="utf-8"))
        self.assertIn("definition_for_lane_stage", CATALOG.read_text(encoding="utf-8"))
        seed = json.loads(SKILL_SEED.read_text(encoding="utf-8"))
        self.assertEqual(2, seed["schema_version"])
        self.assertEqual(30, len(seed["techniques"]))
        self.assertNotIn("TierGrid", BATTLE_UI.read_text(encoding="utf-8"))
        self.assertIn("select_category", SKILL_SESSION.read_text(encoding="utf-8"))
        self.assertNotIn("select_technique", SKILL_SESSION.read_text(encoding="utf-8"))

    def test_visual_direction_rejects_the_old_dark_matrix_and_uses_the_user_reference_language(self) -> None:
        bible = VISUAL_BIBLE.read_text(encoding="utf-8")
        for required in (
            "TETRIS-VISUAL-041",
            "warm ivory parchment",
            "sepia ink",
            "watercolor violet rift",
            "permanent 3×6 skill wall",
            "dark metal-card",
        ):
            self.assertIn(required, bible)

    def test_user_locked_visual_board_remains_a_planning_reference_not_a_runtime_asset(self) -> None:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        visuals = {visual["asset_id"]: visual for visual in manifest["visuals"]}

        self.assertEqual("SUPERSEDED_BY_TETRIS-VIS-BOARD-002", visuals["TETRIS-VIS-BOARD-001"]["status"])
        board = visuals["TETRIS-VIS-BOARD-002"]
        self.assertEqual("GENERATED_EXPLORATION", board["classification"])
        self.assertEqual("PLANNING_VISUALIZATION", board["consumer_kind"])
        self.assertEqual("NONE", board["runtime_consumer"])
        self.assertEqual("USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME", board["status"])
        self.assertEqual("2026-08-28", board["user_lock"]["date"])
        self.assertEqual(
            {
                "runtime_asset",
                "Godot_scene_or_UI_implementation",
                "runtime_render",
                "Human_or_player_experience_PASS",
            },
            set(board["user_lock"]["does_not_approve"]),
        )
        for document in (VISUAL_BIBLE, MASTER_GDD, WORKSPACE_INDEX):
            text = document.read_text(encoding="utf-8")
            self.assertIn("USER_LOCKED_PLANNING_REFERENCE_NOT_RUNTIME", text)
            self.assertIn("runtime asset", text)

    def test_material_work_requires_fresh_research_feasibility_and_five_adversarial_loops(self) -> None:
        agents = AGENTS.read_text(encoding="utf-8")
        for required in (
            "MANDATORY_CURRENT_TASK_EVIDENCE_GATE",
            "TARGETED_CURRENT_INTERNET_RESEARCH",
            "PREIMPLEMENTATION_FEASIBILITY_CLASSIFICATION",
            "FIVE_FULL_ADVERSARIAL_LOOPS_MINIMUM",
            "MECHANICAL_NO_EXTERNAL_DEPENDENCY",
        ):
            self.assertIn(required, agents)


if __name__ == "__main__":
    unittest.main()
