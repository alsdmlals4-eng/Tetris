"""Runtime-asset checks for the user-locked Chain tiles and Vanguard face portrait."""

from __future__ import annotations

import hashlib
import json
import struct
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = REPO_ROOT / "docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json"
RUNTIME_EVIDENCE_DIR = REPO_ROOT / "artifacts" / "runtime"
RUNTIME_RECOVERY_CAPTURE = RUNTIME_EVIDENCE_DIR / "tetris-recovery-line-boss-shared-timer-1280x720-20260901.png"

EXPECTED_ASSETS = {
    "TETRIS-IMG-040": {
        "path": "assets/production/tiles/chain_tile_red_v1.png",
        "source_sha256": "b7342dbe2a3aa76eb0f51435052022e7a6064d7aa5210c861cf6a74297201046",
        "dimensions": [256, 256],
        "consumer": "MainRow/PuzzleColumn/PuzzleHost/ChainBoardView; MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
    },
    "TETRIS-IMG-041": {
        "path": "assets/production/tiles/chain_tile_green_v1.png",
        "source_sha256": "bd7e7fe17dcd481f6970ebfc8f00da6d7e3fa8c00d1aa5fa2af6521273e5759b",
        "dimensions": [256, 256],
        "consumer": "MainRow/PuzzleColumn/PuzzleHost/ChainBoardView; MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
    },
    "TETRIS-IMG-042": {
        "path": "assets/production/tiles/chain_tile_blue_v1.png",
        "source_sha256": "a37348a24d1c67bdb74579b813acb6bec59540fe2067a960f6d20ffe518894c0",
        "dimensions": [256, 256],
        "consumer": "MainRow/PuzzleColumn/PuzzleHost/ChainBoardView; MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
    },
    "TETRIS-IMG-043": {
        "path": "assets/production/tiles/chain_tile_yellow_v1.png",
        "source_sha256": "43ae43e2e3548dd93f249cdc5e738cd475a99ce4e8e57a82b97ade6489f786c8",
        "dimensions": [256, 256],
        "consumer": "MainRow/PuzzleColumn/PuzzleHost/ChainBoardView; MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
    },
    "TETRIS-IMG-044": {
        "path": "assets/production/tiles/chain_tile_purple_v1.png",
        "source_sha256": "1eff7a0c30c3dd8d4ab59a5653fea9f302f115f5ca38380d57d25427e3e83d09",
        "dimensions": [256, 256],
        "consumer": "MainRow/PuzzleColumn/PuzzleHost/ChainBoardView; MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
    },
    "TETRIS-IMG-045": {
        "path": "assets/production/tiles/chain_tile_cyan_v1.png",
        "source_sha256": "523a7205c145290a4ec9c34b01cc49d1baafab56d5035446585d7cefdbceb4fa",
        "dimensions": [256, 256],
        "consumer": "MainRow/PuzzleColumn/PuzzleHost/ChainBoardView; MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
    },
    "TETRIS-IMG-046": {
        "path": "assets/production/characters/vanguard_face_portrait_v1.png",
        "source_sha256": "5cbaf2109aceeb581e4479beb39c7622f5db5a08637b4454889147cab3b399c9",
        "dimensions": [512, 512],
        "consumer": "MainRow/CombatColumn/ResourceFrame/ResourceRow/VanguardPortrait",
    },
}


def png_dimensions(path: Path) -> list[int]:
    header = path.read_bytes()[:29]
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise AssertionError(f"{path} is not a PNG with an IHDR header")
    return list(struct.unpack(">II", header[16:24]))


class RuntimeChainTileAssetContractTests(unittest.TestCase):
    def test_every_locked_asset_is_a_compact_hash_registered_runtime_consumer(self) -> None:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        assets_by_id = {asset["asset_id"]: asset for asset in manifest["assets"]}

        for asset_id, expected in EXPECTED_ASSETS.items():
            with self.subTest(asset_id=asset_id):
                self.assertIn(asset_id, assets_by_id)
                asset = assets_by_id[asset_id]
                path = REPO_ROOT / expected["path"]
                self.assertTrue(path.is_file(), f"missing runtime asset {path}")
                self.assertEqual(asset["local_path"], expected["path"])
                self.assertEqual(asset["source_candidate_sha256"], expected["source_sha256"])
                self.assertEqual(asset["dimensions_px"], expected["dimensions"])
                self.assertEqual(png_dimensions(path), expected["dimensions"])
                self.assertEqual(asset["sha256"], hashlib.sha256(path.read_bytes()).hexdigest())
                self.assertEqual(asset["approval_status"], "PROJECT_ASSET_APPROVED")
                self.assertEqual(asset["runtime_consumer"], expected["consumer"])
                if asset_id != "TETRIS-IMG-046":
                    self.assertIn("ProductionLineBoardView", asset["consumer_type"])

    def test_title_logo_uses_a_unique_manifest_id_after_the_tile_set(self) -> None:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        assets_by_id = {asset["asset_id"]: asset for asset in manifest["assets"]}
        self.assertEqual(len(assets_by_id), len(manifest["assets"]), "asset ids must remain unique")
        title_logo = assets_by_id["TETRIS-IMG-047"]
        self.assertEqual(title_logo["local_path"], "assets/production/branding/fracture_frontier_title_logo_v1.png")
        self.assertEqual(title_logo["sha256"], "a160ccee4992bbbcb0f4822a42461d2dfbf7e13e0246728f3d2a0185b2444628")
        self.assertEqual(title_logo["dimensions_px"], [1983, 793])
        self.assertEqual(title_logo["runtime_consumer"], "Margin/Panel/Content/TitleLogo.texture")

    def test_runtime_capture_is_retained_as_evidence_not_imported_game_content(self) -> None:
        self.assertTrue(RUNTIME_RECOVERY_CAPTURE.is_file())
        self.assertTrue((RUNTIME_EVIDENCE_DIR / ".gdignore").is_file())
        self.assertEqual(list(RUNTIME_EVIDENCE_DIR.glob("*.import")), [])


if __name__ == "__main__":
    unittest.main()
