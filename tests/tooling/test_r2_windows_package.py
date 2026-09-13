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
PWSH = shutil.which("pwsh")
WINDOWS_POWERSHELL = shutil.which("powershell")
POWERSHELL = PWSH or WINDOWS_POWERSHELL

EXPECTED_SELECTED = {
    "res://data/replanned_r2/expedition.json",
    "res://src/replanned_r2/r2_expedition.gd",
    "res://src/replanned_r2/r2_expedition_save.gd",
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
    "res://src/replanned_r2/r2_playtest_report.gd",
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


def _write_valid_package_fixture(package: Path):
    payloads = {
        "TetrisR2LocalTrial.exe": b"native-placeholder",
        "TetrisR2LocalTrial.pck": b"pack-placeholder",
        "START_R2_LOCAL_TRIAL.cmd": b"launcher-placeholder",
        "README_LOCAL_TRIAL.txt": "local trial 안내".encode("utf-8"),
        "r2-package-smoke.json": b'{"ok":true}',
        "r2-export-probe.json": b'{"ok":true}',
        "icudt_godot.dat": b"icu-placeholder",
        "export.stdout.log": b"export stdout",
        "export.stderr.log": b"",
        "smoke.stdout.log": b"smoke stdout",
        "smoke.stderr.log": b"",
        "probe.stdout.log": b"probe stdout",
        "probe.stderr.log": b"",
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
    return manifest, artifacts, raw_artifact_paths


def _verify_package(package: Path, shell: str = POWERSHELL):
    return subprocess.run(
        [
            shell,
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
            manifest, artifacts, raw_artifact_paths = _write_valid_package_fixture(package)

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

    def test_verify_only_rejects_missing_log_unlisted_extra_and_path_collisions(self):
        with tempfile.TemporaryDirectory() as temporary:
            package = Path(temporary)
            manifest, artifacts, _ = _write_valid_package_fixture(package)

            missing_log = dict(manifest)
            missing_log["artifacts"] = [
                item for item in artifacts if item["path"] != "export.stderr.log"
            ]
            (package / "BUILD_MANIFEST.json").write_text(
                json.dumps(missing_log), encoding="utf-8"
            )
            result = _verify_package(package)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("export.stderr.log", result.stdout + result.stderr)

            (package / "BUILD_MANIFEST.json").write_text(
                json.dumps(manifest), encoding="utf-8"
            )
            extra = package / "unlisted-extra.txt"
            extra.write_text("must be rejected", encoding="utf-8")
            result = _verify_package(package)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("unlisted", (result.stdout + result.stderr).lower())
            extra.unlink()

            duplicate = dict(manifest)
            duplicate["artifacts"] = artifacts + [dict(artifacts[0])]
            (package / "BUILD_MANIFEST.json").write_text(
                json.dumps(duplicate), encoding="utf-8"
            )
            result = _verify_package(package)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("duplicate", (result.stdout + result.stderr).lower())

            case_alias = dict(manifest)
            alias = dict(artifacts[0])
            alias["path"] = alias["path"].upper()
            case_alias["artifacts"] = artifacts + [alias]
            (package / "BUILD_MANIFEST.json").write_text(
                json.dumps(case_alias), encoding="utf-8"
            )
            result = _verify_package(package)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("case", (result.stdout + result.stderr).lower())

    @unittest.skipUnless(WINDOWS_POWERSHELL, "Windows PowerShell 5.1 is unavailable")
    def test_verify_only_accepts_intact_package_in_windows_powershell_5(self):
        with tempfile.TemporaryDirectory() as temporary:
            package = Path(temporary)
            _write_valid_package_fixture(package)

            result = _verify_package(package, WINDOWS_POWERSHELL)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("R2_LOCAL_TRIAL_PACKAGE_VERIFIED", result.stdout)

    @unittest.skipUnless(PWSH, "PowerShell 7 is unavailable")
    def test_verify_only_accepts_intact_package_in_pwsh(self):
        with tempfile.TemporaryDirectory() as temporary:
            package = Path(temporary)
            _write_valid_package_fixture(package)

            result = _verify_package(package, PWSH)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("R2_LOCAL_TRIAL_PACKAGE_VERIFIED", result.stdout)

    @unittest.skipUnless(
        WINDOWS_POWERSHELL,
        "Windows Hidden attributes require Windows PowerShell",
    )
    def test_verify_only_rejects_hidden_file_and_file_nested_in_hidden_directory(self):
        def set_hidden(path: Path):
            result = subprocess.run(
                ["attrib", "+H", str(path)],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        for case in ["hidden-file", "hidden-directory"]:
            with self.subTest(case=case), tempfile.TemporaryDirectory() as temporary:
                package = Path(temporary)
                _write_valid_package_fixture(package)
                if case == "hidden-file":
                    hidden_file = package / "hidden-extra.txt"
                    hidden_file.write_text("must be rejected", encoding="utf-8")
                    set_hidden(hidden_file)
                    expected_path = "hidden-extra.txt"
                else:
                    hidden_directory = package / "hidden-directory"
                    hidden_directory.mkdir()
                    nested_file = hidden_directory / "nested-extra.txt"
                    nested_file.write_text("must also be rejected", encoding="utf-8")
                    set_hidden(hidden_directory)
                    expected_path = "hidden-directory/nested-extra.txt"
                result = _verify_package(package, WINDOWS_POWERSHELL)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected_path, result.stdout + result.stderr)

    def test_project_preservation_check_rejects_isolated_postexport_change(self):
        with tempfile.TemporaryDirectory() as temporary:
            project_file = Path(temporary) / "project.godot"
            project_file.write_text(
                '[application]\nrun/main_scene="res://scenes/production/battle_briefing.tscn"\n',
                encoding="utf-8",
            )
            expected_hash = _sha256(project_file)
            project_file.write_text(
                '[application]\nrun/main_scene="res://scenes/replanned_r2/main.tscn"\n',
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    POWERSHELL,
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    str(BUILDER),
                    "-VerifyProjectPreservationOnly",
                    "-ProjectSettingsPath",
                    str(project_file),
                    "-ExpectedProjectSha256",
                    expected_hash,
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("project.godot preservation", result.stdout + result.stderr)

    def test_export_diagnostic_check_accepts_only_exact_known_lifecycle_warnings(self):
        known_errors = [
            "ERROR: 6 RID allocations of type 'N16RendererViewport8ViewportE' were leaked at exit.",
            "ERROR: 9 RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit.",
            "ERROR: 1 RID allocations of type 'N17RendererSceneCull8ScenarioE' were leaked at exit.",
            "ERROR: 83 RID allocations of type 'PN18TextServerAdvanced22ShapedTextDataAdvancedE' were leaked at exit.",
            "ERROR: 1 RID allocations of type 'PN18TextServerAdvanced12FontAdvancedE' were leaked at exit.",
        ]
        known_warnings = [
            'WARNING: 6 RIDs of type "Canvas" were leaked.',
            'WARNING: 36 RIDs of type "CanvasItem" were leaked.',
            "WARNING: 209 ObjectDB instances were leaked at exit (run with `--verbose` for details).",
        ]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            stdout = root / "export.stdout.log"
            stderr = root / "export.stderr.log"
            stdout.write_text(
                "Godot Engine v4.7.1.stable.official.a13da4feb\n"
                + "\n".join(known_errors)
                + "\n",
                encoding="utf-8",
            )
            stderr.write_text("\n".join(known_warnings) + "\n", encoding="utf-8")

            def check():
                return subprocess.run(
                    [
                        POWERSHELL,
                        "-NoProfile",
                        "-ExecutionPolicy",
                        "Bypass",
                        "-File",
                        str(BUILDER),
                        "-VerifyExportDiagnosticsOnly",
                        "-ExportStdoutPath",
                        str(stdout),
                        "-ExportStderrPath",
                        str(stderr),
                    ],
                    cwd=ROOT,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                )

            known = check()
            self.assertEqual(known.returncode, 0, known.stdout + known.stderr)
            self.assertIn("KNOWN_TOOLING_WARNING", known.stdout)

            stderr.write_text(
                "\n".join(known_warnings + ["WARNING: new warning must fail"]) + "\n",
                encoding="utf-8",
            )
            unexpected = check()
            self.assertNotEqual(unexpected.returncode, 0)
            self.assertIn("Unexpected export warning/error", unexpected.stdout + unexpected.stderr)


if __name__ == "__main__":
    unittest.main()
