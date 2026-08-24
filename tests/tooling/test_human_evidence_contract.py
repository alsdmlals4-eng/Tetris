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


class HumanEvidenceContractTests(unittest.TestCase):
    def test_machine_readable_human_evidence_index_declares_gate(self) -> None:
        self.assertTrue(EVIDENCE_INDEX_PATH.is_file(), "human evidence index must exist")
        data = json.loads(EVIDENCE_INDEX_PATH.read_text(encoding="utf-8"))
        self.assertEqual(data["project"], "TETRIS")
        self.assertEqual(data["status"], "NOT_RUN")
        self.assertEqual(
            data["contract"],
            "docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md",
        )
        self.assertEqual(data["target_session_minutes"], [6, 10])
        self.assertEqual(data["method"], "OBSERVE_THEN_PROBE")
        self.assertTrue(data["human_evidence_required"])
        self.assertIn("VISUAL_READABILITY", data["dimensions"])
        self.assertIn("TIER_VIABILITY", data["dimensions"])

    def test_human_evidence_contract_preserves_evidence_ceiling(self) -> None:
        self.assertTrue(EVIDENCE_PATH.is_file(), "human evidence contract must exist")
        text = EVIDENCE_PATH.read_text(encoding="utf-8")
        self.assertIn("OBSERVE_FIRST", text)
        self.assertIn("DO_NOT_COACH_DURING_FIRST_ATTEMPT", text)
        self.assertIn("FUN_HYPOTHESIS", text)
        self.assertIn("VISUAL_READABILITY", text)
        self.assertIn("TETRIS-VISUAL-020", text)
        self.assertIn("Shared Player Turn Budget", text)
        self.assertIn("Line Energy", text)
        self.assertIn("Chain Stock", text)
        self.assertIn("lower Tier", text)
        self.assertIn("NOT_RUN", text)
        self.assertIn("PASS / REVISE / BLOCK", text)
        self.assertIn("2026-08-21-phased-turn-production-vertical-slice.md", text)
        self.assertIn("superseded timing clauses", text)


if __name__ == "__main__":
    unittest.main()
