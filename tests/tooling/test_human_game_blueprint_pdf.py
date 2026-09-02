"""Contract checks for the human-readable, non-canonical Tetris blueprint PDF."""

from __future__ import annotations

import hashlib
import json
import unittest
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[2]
PDF_PATH = ROOT / "docs" / "blueprints" / "TETRIS_HUMAN_GAME_BLUEPRINT.pdf"
MANIFEST_PATH = ROOT / "docs" / "blueprints" / "TETRIS_HUMAN_GAME_BLUEPRINT.manifest.json"
CORE_CI_PATH = ROOT / ".github" / "workflows" / "core-poc-ci.yml"
HERO_PATH = ROOT / "docs" / "blueprints" / "assets" / "tetris_blueprint_battle_flow_v1.png"


class HumanGameBlueprintPdfTests(unittest.TestCase):
    def test_core_ci_installs_the_pdf_reader_before_running_tooling_tests(self) -> None:
        workflow = CORE_CI_PATH.read_text(encoding="utf-8")
        dependency = "pypdf==6.14.2"
        self.assertIn(dependency, workflow)
        self.assertLess(workflow.index(dependency), workflow.index("python -m unittest discover -s tests/tooling"))

    def test_blueprint_is_a_readable_derived_pdf_with_exact_source_provenance(self) -> None:
        self.assertTrue(PDF_PATH.is_file(), "human blueprint PDF must be generated")
        self.assertTrue(MANIFEST_PATH.is_file(), "human blueprint provenance manifest must be generated")

        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        self.assertEqual(manifest["artifact_role"], "HUMAN_GDD_PDF_DERIVED_VIEW")
        self.assertEqual(manifest["canonicality"], "NON_CANONICAL_DERIVED_VIEW")
        self.assertEqual(manifest["pdf"]["path"], "docs/blueprints/TETRIS_HUMAN_GAME_BLUEPRINT.pdf")
        self.assertEqual(
            manifest["pdf"]["sha256"],
            hashlib.sha256(PDF_PATH.read_bytes()).hexdigest(),
        )
        source_paths = {entry["path"] for entry in manifest["sources"]}
        self.assertTrue(
            {
                "docs/design/PROJECT_MASTER_GDD.md",
                "docs/design/PRODUCTION_REALTIME_COMBAT_CANON.md",
                "docs/design/COMBO_RESOLVED_SKILL_CONTRACT.md",
                "docs/design/CHAIN_COMBO_MP_CONTRACT.md",
                "docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md",
                "docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json",
            }.issubset(source_paths)
        )
        for source in manifest["sources"]:
            source_path = ROOT / source["path"]
            self.assertTrue(source_path.is_file(), source_path)
            self.assertEqual(
                source["sha256"], hashlib.sha256(source_path.read_bytes()).hexdigest()
            )

        reader = PdfReader(str(PDF_PATH))
        extracted = "\n".join(page.extract_text() or "" for page in reader.pages)
        self.assertIn("TETRIS HUMAN GAME BLUEPRINT", extracted)
        self.assertIn("SHARED ACTION ETA", extracted)
        self.assertIn("BATTLE SURFACE MAP", extracted)
        self.assertIn("50 / 50", extracted)
        self.assertIn("TETRIS-IMG-037", extracted)
        self.assertIn("PENDING_EXACT_HEAD_RENDER", extracted)

    def test_blueprint_registers_a_visual_battle_flow_asset_for_the_human_pdf(self) -> None:
        """Keep the visual battle map from quietly regressing back into a table-only PDF."""
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        visual_assets = manifest["planning_visual_assets"]
        self.assertEqual(len(visual_assets), 1)

        hero = visual_assets[0]
        self.assertEqual(hero["path"], "docs/blueprints/assets/tetris_blueprint_battle_flow_v1.png")
        self.assertEqual(hero["consumer"], "TETRIS_HUMAN_GAME_BLUEPRINT.pdf · visual battle-surface map")
        self.assertEqual(hero["status"], "USER_STANDING_APPROVED_PLANNING_ASSET")
        self.assertTrue(HERO_PATH.is_file(), "the registered visual battle map must be present")
        self.assertEqual(hero["sha256"], hashlib.sha256(HERO_PATH.read_bytes()).hexdigest())

        reader = PdfReader(str(PDF_PATH))
        self.assertEqual(len(reader.pages), 4, "the visual blueprint is a deliberate four-page field guide")
        extracted = "\n".join(page.extract_text() or "" for page in reader.pages)
        self.assertIn("BATTLE SURFACE MAP", extracted)


if __name__ == "__main__":
    unittest.main()
