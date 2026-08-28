"""콤보 단계 자동 해석 스킬 정본과 실제 런타임 경계를 검증한다."""

from __future__ import annotations

import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "docs/design/PRODUCTION_CANON_INDEX.json"
CONTRACT = ROOT / "docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md"
VISUAL_BIBLE = ROOT / "docs/design/VISUAL_BIBLE.md"
MANIFEST = ROOT / "docs/assets/reference/planned/PROJECT_UNDERSTANDING_VISUAL_MANIFEST.json"
SKILL_SESSION = ROOT / "src/production/skill/production_skill_session.gd"
BATTLE_UI = ROOT / "src/production/ui/production_battle.gd"
CATALOG = ROOT / "src/production/skill/production_skill_catalog.gd"


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

    def test_actual_runtime_is_not_misreported_as_the_new_skill_flow(self) -> None:
        contract = CONTRACT.read_text(encoding="utf-8")
        self.assertIn("DOCUMENTED_NOT_IMPLEMENTED", contract)
        self.assertIn("legacy manual Tier 1–6", contract)
        self.assertIn("tier < 1 or tier > 6", CATALOG.read_text(encoding="utf-8"))
        self.assertIn("TierGrid", BATTLE_UI.read_text(encoding="utf-8"))
        self.assertIn("select_technique", SKILL_SESSION.read_text(encoding="utf-8"))

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

    def test_new_visual_board_is_a_planning_reference_not_a_runtime_asset(self) -> None:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        visuals = {visual["asset_id"]: visual for visual in manifest["visuals"]}

        self.assertEqual("SUPERSEDED_BY_TETRIS-VIS-BOARD-002", visuals["TETRIS-VIS-BOARD-001"]["status"])
        board = visuals["TETRIS-VIS-BOARD-002"]
        self.assertEqual("GENERATED_EXPLORATION", board["classification"])
        self.assertEqual("PLANNING_VISUALIZATION", board["consumer_kind"])
        self.assertEqual("NONE", board["runtime_consumer"])
        self.assertEqual("AWAITING_USER_LOCK_CONFIRMATION_NOT_RUNTIME", board["status"])


if __name__ == "__main__":
    unittest.main()
