"""Contract checks for approved-source runtime character cutout candidates."""

from __future__ import annotations

import json
import hashlib
import struct
import unittest
import zlib
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = REPO_ROOT / "docs/assets/reference/approved/APPROVED_REFERENCE_MANIFEST.json"
CONTRACT_PATH = REPO_ROOT / "docs/design/RUNTIME_IMAGE_ASSET_CONSUMER_CONTRACT.md"
BATTLE_SCENE_PATH = REPO_ROOT / "scenes/production/battle.tscn"
EXPECTED_ASSETS = {
    "TETRIS-IMG-034": {
        "path": "assets/production/bosses/gatebreaker_combat_cutout_v1.png",
        "source": "IMG-P0-003",
        "consumer": "MainRow/CombatColumn/CombatStage/GatebreakerReference",
        "resource_id": "7_gatebreaker_cutout",
        "node_name": "GatebreakerReference",
        "texture_reference": "SubResource(\"AtlasTexture_gatebreaker_stage\")",
        "anchor_left": "0.0",
        "anchor_top": "-0.18",
        "anchor_right": "1.0",
        "anchor_bottom": "1.18",
        "z_index": "1",
        "stretch_mode": "6",
        "geometry_phrase": "upper-body AtlasTexture region",
    },
}

RETAINED_UNBOUND_VANGUARD = {
    "asset_id": "TETRIS-IMG-033",
    "path": "assets/production/characters/vanguard_combat_cutout_v1.png",
    "source": "IMG-P0-002",
}


def read_png_header(path: Path) -> tuple[int, int, int, int]:
    """Return PNG geometry/format facts needed by this no-dependency contract."""
    header = path.read_bytes()[:29]
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise AssertionError(f"{path} is not a valid PNG with an IHDR header")
    width, height, bit_depth, color_type = struct.unpack(
        ">IIBB", header[16:26]
    )
    if bit_depth not in (8, 16):
        raise AssertionError(f"{path} uses unsupported bit depth {bit_depth}")
    return width, height, bit_depth, color_type


def png_has_transparent_rgba_pixel(path: Path) -> bool:
    """Decode non-interlaced 8-bit RGBA scanlines and find an alpha value below 255."""
    png = path.read_bytes()
    width, height, bit_depth, color_type = read_png_header(path)
    if bit_depth != 8 or color_type != 6:
        return False

    compressed = bytearray()
    offset = 8
    while offset < len(png):
        length = struct.unpack(">I", png[offset : offset + 4])[0]
        chunk_type = png[offset + 4 : offset + 8]
        chunk_data = png[offset + 8 : offset + 8 + length]
        if chunk_type == b"IDAT":
            compressed.extend(chunk_data)
        offset += 12 + length
        if chunk_type == b"IEND":
            break

    raw = zlib.decompress(compressed)
    stride = width * 4
    cursor = 0
    previous = bytearray(stride)
    for _ in range(height):
        filter_type = raw[cursor]
        cursor += 1
        encoded = raw[cursor : cursor + stride]
        cursor += stride
        row = bytearray(stride)
        for index, value in enumerate(encoded):
            left = row[index - 4] if index >= 4 else 0
            up = previous[index]
            up_left = previous[index - 4] if index >= 4 else 0
            if filter_type == 0:
                reconstructed = value
            elif filter_type == 1:
                reconstructed = value + left
            elif filter_type == 2:
                reconstructed = value + up
            elif filter_type == 3:
                reconstructed = value + ((left + up) // 2)
            elif filter_type == 4:
                pa = abs(up - up_left)
                pb = abs(left - up_left)
                pc = abs(left + up - 2 * up_left)
                predictor = left if pa <= pb and pa <= pc else (up if pb <= pc else up_left)
                reconstructed = value + predictor
            else:
                raise AssertionError(f"{path} has unsupported PNG filter {filter_type}")
            row[index] = reconstructed & 0xFF
        if any(alpha < 255 for alpha in row[3::4]):
            return True
        previous = row
    return False


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def scene_node_block(scene: str, node_name: str) -> str:
    header = f'[node name="{node_name}" type="TextureRect" parent="MainRow/CombatColumn/CombatStage"]'
    start = scene.index(header)
    next_node = scene.find("\n[node ", start + len(header))
    return scene[start:] if next_node == -1 else scene[start:next_node]


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
                self.assertEqual(asset["runtime_integration"], "IMPLEMENTED_ON_BRANCH")
                self.assertEqual(
                    asset["runtime_verification"],
                    "CURRENT_WORKTREE_RUNTIME_CAPTURED_1280X720_NOT_EXACT_COMMITTED_HEAD",
                )
                self.assertIn(expected["geometry_phrase"], asset["geometry_contract"])
                self.assertNotIn("bottom anchor", asset["geometry_contract"])
                self.assertIn("target worktree runtime capture", asset["runtime_render_evidence"])
                self.assertIn("1280x720", asset["runtime_render_evidence"])
                self.assertIn("uncommitted-worktree receipt", asset["runtime_render_evidence"])
                self.assertNotIn("Human/readability artifact", asset["runtime_render_evidence"].split("not an exact")[0])
                self.assertIn(asset_id, contract)
                self.assertIn(expected["consumer"], contract)

                image_path = REPO_ROOT / expected["path"]
                self.assertTrue(image_path.is_file(), f"missing {image_path}")
                width, height, bit_depth, color_type = read_png_header(image_path)
                self.assertEqual(sha256(image_path), asset["sha256"])
                self.assertEqual(asset["dimensions_px"], [width, height])
                self.assertGreater(width, 0)
                self.assertGreater(height, 0)
                self.assertLessEqual(max(width, height), 1536)
                self.assertEqual(bit_depth, 8)
                self.assertEqual(color_type, 6, "PNG must be RGBA, not merely alpha-capable")
                self.assertTrue(
                    png_has_transparent_rgba_pixel(image_path),
                    "PNG must contain at least one actually transparent pixel",
                )

        retained = assets_by_id[RETAINED_UNBOUND_VANGUARD["asset_id"]]
        self.assertEqual(retained["local_path"], RETAINED_UNBOUND_VANGUARD["path"])
        self.assertEqual(retained["derived_from"], RETAINED_UNBOUND_VANGUARD["source"])
        self.assertEqual(retained["runtime_consumer"], "NOT_PRESENT")
        self.assertEqual(
            retained["runtime_integration"],
            "RETAINED_UNBOUND_AFTER_USER_DIRECTED_BOSS_ONLY_STAGE",
        )
        self.assertEqual(retained["runtime_verification"], "NO_ACTIVE_RUNTIME_CONSUMER")
        self.assertIn("boss-only", retained["reference_scope"])

        self.assertIn("boss-only", contract)
        self.assertIn("no active consumer", contract)
        self.assertNotIn("centered bottom", contract)

    def test_cutouts_are_bound_inside_the_production_combat_stage(self) -> None:
        scene = BATTLE_SCENE_PATH.read_text(encoding="utf-8")
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        assets_by_id = {asset["asset_id"]: asset for asset in manifest["assets"]}

        self.assertIn('[node name="StageBackdrop" type="TextureRect" parent="MainRow/CombatColumn/CombatStage"]', scene)
        self.assertNotIn('name="VanguardReference"', scene)
        self.assertNotIn('id="6_vanguard_cutout"', scene)
        self.assertIn("clip_contents = true", scene)
        for asset_id, expected in EXPECTED_ASSETS.items():
            with self.subTest(asset_id=asset_id):
                asset = assets_by_id[asset_id]
                self.assertIn(
                    f'[ext_resource type="Texture2D" path="res://{expected["path"]}" id="{expected["resource_id"]}"]',
                    scene,
                )
                block = scene_node_block(scene, expected["node_name"])
                self.assertIn(f'texture = {expected["texture_reference"]}', block)
                self.assertIn(f'anchor_top = {expected["anchor_top"]}', block)
                self.assertIn(f'anchor_bottom = {expected["anchor_bottom"]}', block)
                self.assertIn(f'anchor_left = {expected["anchor_left"]}', block)
                self.assertIn(f'anchor_right = {expected["anchor_right"]}', block)
                self.assertIn(f'z_index = {expected["z_index"]}', block)
                self.assertIn("mouse_filter = 2", block)
                self.assertIn("expand_mode = 1", block)
                self.assertIn(f'stretch_mode = {expected["stretch_mode"]}', block)
                self.assertEqual(asset["runtime_consumer"], expected["consumer"])

        self.assertIn('[sub_resource type="AtlasTexture" id="AtlasTexture_gatebreaker_stage"]', scene)
        self.assertIn('atlas = ExtResource("7_gatebreaker_cutout")', scene)


if __name__ == "__main__":
    unittest.main()
