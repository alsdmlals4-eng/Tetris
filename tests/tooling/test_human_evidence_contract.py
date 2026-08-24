import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INDEX_PATH = ROOT / "docs" / "design" / "PRODUCTION_CANON_INDEX.json"
EVIDENCE_PATH = (
    ROOT
    / "docs"
    / "validation"
    / "PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md"
)
PLAN_PATH = (
    ROOT
    / "docs"
    / "superpowers"
    / "plans"
    / "2026-08-21-phased-turn-production-vertical-slice.md"
)


class HumanEvidenceContractTests(unittest.TestCase):
    def test_machine_routing_points_to_human_evidence_contract(self) -> None:
        data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
        self.assertEqual(
            data["human_evidence_contract"],
            "docs/validation/PRODUCTION_VERTICAL_SLICE_HUMAN_EVIDENCE_CONTRACT.md",
        )
        evidence = data["human_evidence"]
        self.assertEqual(evidence["status"], "NOT_RUN")
        self.assertEqual(evidence["target_session_minutes"], [6, 10])
        self.assertEqual(evidence["method"], "OBSERVE_THEN_PROBE")
        self.assertTrue(evidence["human_evidence_required"])
        self.assertIn("VISUAL_READABILITY", evidence["dimensions"])
        self.assertIn("TIER_VIABILITY", evidence["dimensions"])

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

    def test_vertical_slice_plan_does_not_reintroduce_superseded_phase_timers(self) -> None:
        text = PLAN_PATH.read_text(encoding="utf-8")
        self.assertIn("TETRIS-TIME-025", text)
        self.assertIn("Shared Player Turn Budget", text)
        self.assertNotIn("phase timer seed starts at 30/30/30 seconds maximum", text)
        self.assertNotIn("early finish discards unused time", text)
        self.assertNotIn("only current phase timer advances", text)
        self.assertNotIn('"bank_unused_time": false', text)


if __name__ == "__main__":
    unittest.main()
