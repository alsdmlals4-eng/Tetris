import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EVIDENCE_INDEX_PATH = (
    ROOT
    / "docs"
    / "validation"
    / "PRODUCTION_HUMAN_EVIDENCE_INDEX.json"
)
EVIDENCE_PATH = (
    ROOT
    / "docs"
    / "validation"
    / "PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md"
)

EXPECTED_DIMENSIONS = [
    "REALTIME_THREAT_READABILITY",
    "WORKSPACE_SWITCH_COMPREHENSION",
    "WORKSPACE_STATE_PERSISTENCE",
    "TACTICAL_PAUSE_COMPREHENSION",
    "LINE_MP_VS_CHAIN_COMBO_AND_MP_LOCK",
    "TECHNIQUE_DECISION_QUALITY",
    "SIXTY_FORTY_LAYOUT_READABILITY",
    "PLAYER_EXPERIENCE_SIGNAL",
]


class HumanEvidenceContractTests(unittest.TestCase):
    def test_machine_readable_human_evidence_index_declares_core_029_gate(self) -> None:
        self.assertTrue(EVIDENCE_INDEX_PATH.is_file(), "human evidence index must exist")
        data = json.loads(EVIDENCE_INDEX_PATH.read_text(encoding="utf-8"))

        self.assertEqual(data["project"], "TETRIS")
        self.assertEqual(data["core_decision"], "TETRIS-CORE-029")
        self.assertEqual(data["status"], "NOT_RUN")
        self.assertEqual(
            data["contract"],
            "docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md",
        )
        self.assertEqual(data["target_session_minutes"], [6, 10])
        self.assertEqual(data["method"], "OBSERVE_THEN_PROBE")
        self.assertTrue(data["human_evidence_required"])
        self.assertEqual(data["minimum_directional_sessions_for_pass"], 3)
        for dimension in EXPECTED_DIMENSIONS:
            self.assertIn(dimension, data["dimensions"])
        self.assertNotIn("SHARED_TURN_BUDGET", data["dimensions"])
        self.assertNotIn("TEMPO", data["dimensions"])

    def test_human_evidence_contract_preserves_core_029_evidence_ceiling(self) -> None:
        self.assertTrue(EVIDENCE_PATH.is_file(), "human evidence contract must exist")
        text = EVIDENCE_PATH.read_text(encoding="utf-8")

        self.assertIn("TETRIS-CORE-029", text)
        self.assertIn("OBSERVE_FIRST", text)
        self.assertIn("DO_NOT_COACH_DURING_FIRST_ATTEMPT", text)
        self.assertIn("FUN_HYPOTHESIS", text)
        self.assertIn("TETRIS-VISUAL-041", text)
        self.assertIn("TETRIS-SKILL-039", text)
        self.assertIn("TETRIS-SKILL-042", text)
        self.assertIn("LINE", text)
        self.assertIn("CHAIN", text)
        self.assertIn("MP", text)
        self.assertIn("Combo", text)
        self.assertIn("TETRIS-CHAIN-038", text)
        self.assertIn("TACTICAL_PAUSE_SKILL", text)
        self.assertIn("50/50", text)
        self.assertIn("MEMORABLE_MOMENT", text)
        self.assertIn("THREE_SESSIONS_REQUIRED_FOR_PASS", text)
        self.assertIn("NOT_RUN", text)
        self.assertIn("PASS / REVISE / BLOCK", text)
        self.assertIn("wall-clock", text)
        self.assertIn("active combat simulation time", text)
        self.assertIn("tactical-pause duration", text)
        self.assertNotIn("### C. SHARED_BUDGET_COMPREHENSION", text)
        self.assertNotIn("### TEMPO", text)
        self.assertIn("historical provenance", text)


if __name__ == "__main__":
    unittest.main()
