import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PRESET = ROOT / "export_presets.cfg"
BUILDER = ROOT / "tools" / "windows" / "build_r2_local_trial.ps1"
POWERSHELL = shutil.which("pwsh") or shutil.which("powershell")

EXPECTED_SELECTED = {
    "res://scenes/replanned_r2/main.tscn",
    "res://docs/design/r2-complete-session.json",
    "res://docs/design/autocast-r2-data.json",
    "res://data/production/line_tetrominoes.json",
    "res://docs/assets/reference/planned/replanning/blueprint/icons.png",
    "res://docs/assets/reference/planned/replanning/blueprint/portrait-states.png",
    "res://docs/assets/reference/planned/replanning/blueprint/frontier.png",
    "res://docs/assets/reference/planned/replanning/autocast/tiles.png",
    "res://docs/assets/reference/planned/replanning/autocast/boss-cutout.png",
    "res://src/replanned_r2/r2_screen.gd",
    "res://src/replanned_r2/r2_session.gd",
    "res://src/replanned_r2/r2_combat.gd",
    "res://src/replanned_r2/r2_line.gd",
    "res://src/replanned_r2/r2_chain.gd",
    "res://src/replanned_r2/r2_save.gd",
    "res://src/replanned_r2/r2_assets.gd",
    "res://src/replanned_r2/r2_input.gd",
    "res://src/production/line/line_board.gd",
    "res://src/production/line/active_tetromino.gd",
    "res://src/production/line/tetromino_catalog.gd",
}


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class R2WindowsPackageContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if POWERSHELL is None:
            raise unittest.SkipTest("PowerShell is unavailable; Windows packaging verifier cannot run")

    def test_selected_resource_preset_covers_exact_dynamic_inputs(self):
        text = PRESET.read_text(encoding="utf-8")
        self.assertIn('name="Windows R2 Local Trial"', text)
        self.assertIn('platform="Windows Desktop"', text)
        self.assertIn('export_filter="resources"', text)
        match = re.search(r"export_files=PackedStringArray\(([^\n]+)\)", text)
        self.assertIsNotNone(match)
        selected = set(re.findall(r'"([^"]+)"', match.group(1)))
        self.assertEqual(selected, EXPECTED_SELECTED)
        for resource_path in EXPECTED_SELECTED:
            self.assertTrue((ROOT / resource_path.removeprefix("res://")).is_file())

    def test_preset_preserves_production_main_and_excludes_editor_helper(self):
        project = (ROOT / "project.godot").read_text(encoding="utf-8")
        preset = PRESET.read_text(encoding="utf-8")
        self.assertIn(
            'run/main_scene="res://scenes/production/battle_briefing.tscn"',
            project,
        )
        self.assertIn('exclude_filter="addons/godot_ai/**,tests/**,.superpowers/**"', preset)
        self.assertNotIn("run/main_scene", preset)

    def test_verify_only_accepts_intact_package_and_rejects_tampering(self):
        with tempfile.TemporaryDirectory() as temporary:
            package = Path(temporary)
            payloads = {
                "TetrisR2LocalTrial.exe": b"native-placeholder",
                "TetrisR2LocalTrial.pck": b"pack-placeholder",
                "START_R2_LOCAL_TRIAL.cmd": b"launcher-placeholder",
                "README_LOCAL_TRIAL.txt": "local trial 안내".encode("utf-8"),
                "r2-package-smoke.json": b'{"ok":true}',
                "r2-export-probe.json": b'{"ok":true}',
                "icudt_godot.dat": b"icu-placeholder",
            }
            artifacts = []
            for name, payload in payloads.items():
                path = package / name
                path.write_bytes(payload)
                artifacts.append({"path": name, "sha256": _sha256(path)})
            asset_manifest = json.loads(
                (ROOT / "docs" / "design" / "r2-complete-session.json").read_text(
                    encoding="utf-8"
                )
            )
            raw_artifact_paths = []
            for entry in asset_manifest["assets"].values():
                relative = Path("r2-source-assets") / entry["path"]
                source = ROOT / entry["path"]
                destination = package / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, destination)
                manifest_path = relative.as_posix()
                raw_artifact_paths.append(manifest_path)
                artifacts.append({"path": manifest_path, "sha256": _sha256(destination)})
            manifest = {
                "schema_version": 1,
                "package_kind": "TETRIS_R2_LOCAL_TRIAL_NOT_FOR_RELEASE",
                "repository_head": "a" * 40,
                "entry_scene": "res://scenes/replanned_r2/main.tscn",
                "launcher": "START_R2_LOCAL_TRIAL.cmd",
                "artifacts": artifacts,
            }
            (package / "BUILD_MANIFEST.json").write_text(
                json.dumps(manifest, ensure_ascii=False), encoding="utf-8"
            )

            intact = subprocess.run(
                [
                    POWERSHELL,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(BUILDER),
                    "-OutputDirectory",
                    str(package),
                    "-VerifyPackageOnly",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            self.assertEqual(intact.returncode, 0, intact.stdout + intact.stderr)
            self.assertIn("R2_LOCAL_TRIAL_PACKAGE_VERIFIED", intact.stdout)

            without_icu = dict(manifest)
            without_icu["artifacts"] = [
                item for item in artifacts if item["path"] != "icudt_godot.dat"
            ]
            (package / "BUILD_MANIFEST.json").write_text(
                json.dumps(without_icu, ensure_ascii=False), encoding="utf-8"
            )
            missing_icu = subprocess.run(
                [
                    POWERSHELL,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(BUILDER),
                    "-OutputDirectory",
                    str(package),
                    "-VerifyPackageOnly",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            self.assertNotEqual(missing_icu.returncode, 0)
            self.assertIn("required artifact", missing_icu.stdout + missing_icu.stderr)

            without_raw_atlas = dict(manifest)
            without_raw_atlas["artifacts"] = [
                item for item in artifacts if item["path"] != raw_artifact_paths[0]
            ]
            (package / "BUILD_MANIFEST.json").write_text(
                json.dumps(without_raw_atlas, ensure_ascii=False), encoding="utf-8"
            )
            missing_raw = subprocess.run(
                [
                    POWERSHELL,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(BUILDER),
                    "-OutputDirectory",
                    str(package),
                    "-VerifyPackageOnly",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            self.assertNotEqual(missing_raw.returncode, 0)
            self.assertIn("raw atlas", missing_raw.stdout + missing_raw.stderr)

            (package / "BUILD_MANIFEST.json").write_text(
                json.dumps(manifest, ensure_ascii=False), encoding="utf-8"
            )

            (package / "TetrisR2LocalTrial.pck").write_bytes(b"tampered")
            tampered = subprocess.run(
                [
                    POWERSHELL,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(BUILDER),
                    "-OutputDirectory",
                    str(package),
                    "-VerifyPackageOnly",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            self.assertNotEqual(tampered.returncode, 0)
            self.assertIn("SHA-256 mismatch", tampered.stdout + tampered.stderr)


if __name__ == "__main__":
    unittest.main()
