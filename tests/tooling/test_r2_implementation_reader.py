import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

class ImplementationReaderTests(unittest.TestCase):
    def test_reader_uses_live_catalogues_and_preserves_original(self):
        path = ROOT / 'tools/build_r2_implementation_reader.py'
        self.assertTrue(path.is_file())
        if not path.is_file(): return
        sys.path.insert(0, str(ROOT / 'tools'))
        spec = importlib.util.spec_from_file_location('r2_reader', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertIn('180', module.table_lines('encounters'))
        self.assertIn('ATK', module.table_lines('skills'))
        self.assertIn('0.25', module.table_lines('resources'))
        self.assertIn('R2-BOSS', module.table_lines('assets'))
        self.assertNotEqual(module.OUTPUT, module.ORIGINAL)
        self.assertIn(module.ORIGINAL, module.inputs())
        self.assertIn(ROOT/'src/replanned_r2/r2_audio.gd', module.inputs())
