"""Contract checks for approved-source runtime character cutout candidates."""

from __future__ import annotations

import json
import hashlib
import struct
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = REPO_ROOT / "docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json"
CONTRACT_PATH = REPO_ROOT / "docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md"
EXPECTED_ASSETS = {
    "TETRIS-IMG-033": {
        "path": "assets/production/characters/vanguard_combat_cutout_v1.png",
        "source": "IMG-P0-002",
        "consumer": "MainRow/CombatColumn/CombatStage/VanguardReference",
    },
    "TETRIS-IMG-034": {
        "path": "assets/production/bosses/gatebreaker_combat_cutout_v1.png",
        "source": "IMG-P0-003",
        "consumer": "MainRow/CombatColumn/CombatStage/GatebreakerReference",
    },
}


def read_png_header(path: Path) -> tuple[int, int, int]:
    """Return PNG width, height, and color type without optional dependencies."""
    header = path.read_bytes()[:29]
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise AssertionError(f"{path} is not a valid PNG with an IHDR header")
    width, height, bit_depth, color_type = struct.unpack(
        ">IIBB", header[16:26]
    )
    if bit_depth not in (8, 16):
        raise AssertionError(f"{path} uses unsupported bit depth {bit_depth}")
    return width, height, color_type


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class RuntimeCharacterAssetContractTests(unittest.TestCase):
    def test_approved_source_derivatives_are_present_and_transparent(self) -> None:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        assets_by_id = {asset["asset_id"]: asset for asset in manifest["assets"]}
        contract = CONTRACT_PATH.read_text(encoding="utf-8")

        for source_id in ("IMG-P0-002", "IMG-P0-003"):
            with self.subTest(approved_source=source_id):
                source = assets_by_id[source_id]
                self.assertEqual(
                    sha256(REPO_ROOT / source["local_path"]), source["sha256"]
                )

        for asset_id, expected in EXPECTED_ASSETS.items():
            with self.subTest(asset_id=asset_id):
                self.assertIn(asset_id, assets_by_id)
                asset = assets_by_id[asset_id]
                self.assertEqual(asset["local_path"], expected["path"])
                self.assertEqual(asset["derived_from"], expected["source"])
                self.assertEqual(asset["planned_consumer_node"], expected["consumer"])
                self.assertEqual(asset["approval_status"], "SOURCE_ASSET_CANDIDATE")
                self.assertEqual(asset["runtime_integration"], "NOT_IMPLEMENTED")
                self.assertEqual(asset["runtime_verification"], "NOT_RUN")
                self.assertIn(asset_id, contract)
                self.assertIn(expected["consumer"], contract)

                image_path = REPO_ROOT / expected["path"]
                self.assertTrue(image_path.is_file(), f"missing {image_path}")
                width, height, color_type = read_png_header(image_path)
                self.assertEqual(sha256(image_path), asset["sha256"])
                self.assertEqual(asset["dimensions_px"], [width, height])
                self.assertGreater(width, 0)
                self.assertGreater(height, 0)
                self.assertLessEqual(max(width, height), 1536)
                self.assertIn(color_type, (4, 6), "PNG must encode alpha")


if __name__ == "__main__":
    unittest.main()
