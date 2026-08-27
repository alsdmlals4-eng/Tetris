"""Contract checks for authored combat VFX consumed by the production battle scene."""

from __future__ import annotations

import hashlib
import json
import struct
import unittest
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "docs" / "assets" / "reference" / "approved" / "APPROVED_REFERENCE_MANIFEST.json"
SCENE_PATH = ROOT / "scenes" / "production" / "battle.tscn"
UI_SCRIPT_PATH = ROOT / "src" / "production" / "ui" / "production_battle.gd"
RENDER_PROBE_PATH = ROOT / "tests" / "tooling" / "combat_vfx_layout_probe.gd"

EXPECTED_VFX = {
    "TETRIS-IMG-035": {
        "path": "assets/production/vfx/vanguard_attack_accent_v1.png",
        "consumer": "MainRow/CombatColumn/CombatStage/VanguardAttackAccent",
        "purpose": "successful ATTACK technique feedback",
    },
    "TETRIS-IMG-036": {
        "path": "assets/production/vfx/gatebreaker_threat_telegraph_v1.png",
        "consumer": "MainRow/CombatColumn/CombatStage/GatebreakerThreatTelegraph",
        "purpose": "active enemy telegraph feedback",
    },
}


def png_facts(path: Path) -> tuple[int, int, int, int]:
    header = path.read_bytes()[:29]
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise AssertionError(f"{path} is not a PNG with an IHDR header")
    return struct.unpack(">IIBB", header[16:26])


def png_has_transparent_pixel(path: Path) -> bool:
    """Return whether a non-interlaced RGBA image has a non-opaque pixel."""
    width, height, bit_depth, color_type = png_facts(path)
    if (bit_depth, color_type) != (8, 6):
        return False
    png = path.read_bytes()
    compressed = bytearray()
    offset = 8
    while offset < len(png):
        length = struct.unpack(">I", png[offset : offset + 4])[0]
        kind = png[offset + 4 : offset + 8]
        if kind == b"IDAT":
            compressed.extend(png[offset + 8 : offset + 8 + length])
        offset += 12 + length
        if kind == b"IEND":
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
                decoded = value
            elif filter_type == 1:
                decoded = value + left
            elif filter_type == 2:
                decoded = value + up
            elif filter_type == 3:
                decoded = value + ((left + up) // 2)
            elif filter_type == 4:
                pa, pb, pc = abs(up - up_left), abs(left - up_left), abs(left + up - 2 * up_left)
                decoded = value + (left if pa <= pb and pa <= pc else up if pb <= pc else up_left)
            else:
                raise AssertionError(f"unsupported PNG filter {filter_type}")
            row[index] = decoded & 0xFF
        if any(alpha < 255 for alpha in row[3::4]):
            return True
        previous = row
    return False


class RuntimeCombatVfxAssetTests(unittest.TestCase):
    def test_manifested_authored_vfx_is_rgba_and_has_a_real_stage_consumer(self) -> None:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        scene = SCENE_PATH.read_text(encoding="utf-8")
        assets = {asset["asset_id"]: asset for asset in manifest["assets"]}

        for asset_id, expected in EXPECTED_VFX.items():
            with self.subTest(asset_id=asset_id):
                self.assertIn(asset_id, assets)
                asset = assets[asset_id]
                self.assertEqual(expected["path"], asset["local_path"])
                self.assertEqual(expected["consumer"], asset["runtime_consumer"])
                self.assertEqual(expected["purpose"], asset["gameplay_purpose"])
                image = ROOT / expected["path"]
                self.assertTrue(image.is_file())
                width, height, bit_depth, color_type = png_facts(image)
                self.assertEqual(asset["dimensions_px"], [width, height])
                self.assertEqual((bit_depth, color_type), (8, 6))
                self.assertTrue(png_has_transparent_pixel(image))
                self.assertEqual(
                    asset["sha256"], hashlib.sha256(image.read_bytes()).hexdigest()
                )
                node_name = expected["consumer"].rsplit("/", 1)[-1]
                self.assertIn(
                    f'[node name="{node_name}" type="TextureRect" parent="MainRow/CombatColumn/CombatStage"]',
                    scene,
                )

    def test_stage_vfx_feedback_follows_attack_commit_and_active_telegraph(self) -> None:
        script = UI_SCRIPT_PATH.read_text(encoding="utf-8")
        self.assertIn("_trigger_vanguard_attack_fx", script)
        self.assertIn('"ATTACK"', script)
        self.assertIn('result.get("committed", false)', script)
        self.assertIn("_refresh_stage_vfx", script)
        self.assertIn("enemy_eta_seconds", script)

    def test_render_probe_fails_cleanly_when_a_headless_viewport_cannot_capture(self) -> None:
        probe = RENDER_PROBE_PATH.read_text(encoding="utf-8")
        self.assertIn('DisplayServer.get_name() == "headless"', probe)
        self.assertIn("viewport_texture == null", probe)
        self.assertIn("viewport_image == null", probe)
        self.assertIn("display-capable renderer", probe)
        self.assertIn("quit(2)", probe)


if __name__ == "__main__":
    unittest.main()
