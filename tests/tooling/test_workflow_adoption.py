"""Project-only projection must preserve every upstream generated output."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools/check_workflow_adoption.py"


class WorkflowAdoptionTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SCRIPT.is_file(), "Missing executable adoption/generation consumer")
        spec = importlib.util.spec_from_file_location("workflow_adoption", SCRIPT)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def test_router_projection_preserves_snapshot_and_dashboard(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            router = root / self.module.ROUTER
            snapshot = root / "skills/PROJECT_SKILL_SNAPSHOT.json"
            dashboard = root / "docs/PROJECT_OPERATING_DASHBOARD.html"
            original = {router: b"old", snapshot: b"snapshot", dashboard: b"dashboard"}
            actual = self.module.project_artifacts(root, original, b"new router")
            self.assertEqual(actual[router], b"new router")
            self.assertEqual(actual[snapshot], b"snapshot")
            self.assertEqual(actual[dashboard], b"dashboard")
            self.assertEqual(original[router], b"old")

    def test_missing_upstream_router_fails_instead_of_silently_adding_it(self):
        with self.assertRaisesRegex(ValueError, "router"):
            self.module.project_artifacts(Path("."), {}, b"router")

    def test_generated_drift_checks_every_output_and_write_repairs_it(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            outputs = {root / "router.md": b"router\n", root / "snapshot.json": b"{}\n"}
            self.assertEqual(len(self.module.sync_outputs(outputs, write=False)), 2)
            self.module.sync_outputs(outputs, write=True)
            self.assertEqual(self.module.sync_outputs(outputs, write=False), [])
            (root / "snapshot.json").write_bytes(b"manual drift")
            self.assertEqual(self.module.sync_outputs(outputs, write=False), [root / "snapshot.json"])

    def test_unsafe_reference_is_rejected(self):
        for name in ("../outside", "/absolute", "C:/outside", "a\\b"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                self.module.relative_path(name)

    def test_router_template_is_inside_repository(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            with self.assertRaises(ValueError):
                self.module.local_source(root, "../outside.md")


if __name__ == "__main__":
    unittest.main()
