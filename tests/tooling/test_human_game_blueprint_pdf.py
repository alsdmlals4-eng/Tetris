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
        self.assertIn("50 / 50 BATTLE SURFACE", extracted)
        self.assertIn("TETRIS-IMG-037", extracted)
        self.assertIn("PENDING_EXACT_HEAD_RENDER", extracted)


if __name__ == "__main__":
    unittest.main()
