import importlib.util
import hashlib
import json
import subprocess
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
        for relative in ['assets/replanned_r2/audio/confirm.ogg','assets/replanned_r2/audio/SOURCES.md',
                         'assets/replanned_r2/audio/interface-License.txt','export_presets.cfg',
                         'docs/validation/r2-audio-20260913/package-probe.json',
                         'docs/validation/r2-audio-20260913/README.md']:
            self.assertIn(ROOT/relative,module.inputs())

    def test_published_reader_binds_source_and_preserves_all_historical_pages(self):
        from pypdf import PdfReader
        path=ROOT/'docs/blueprints/TETRIS_R2_CURRENT_IMPLEMENTATION_READER.pdf'
        manifest=json.loads(path.with_suffix('.manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),manifest['pdf_sha256'])
        for relative,digest in manifest['input_hashes'].items():
            raw=subprocess.run(['git','show',manifest['source_commit']+':'+relative],cwd=ROOT,capture_output=True,check=True).stdout
            self.assertEqual(hashlib.sha256(raw).hexdigest(),digest,relative)
        current=PdfReader(path)
        old=PdfReader(ROOT/'docs/blueprints/TETRIS_R2_COMPLETE_HUMAN_BLUEPRINT.pdf')
        self.assertEqual(len(current.pages),manifest['pages'])
        offset=manifest['supplement_pages']
        self.assertEqual(len(current.pages)-offset,len(old.pages))
        for i,page in enumerate(old.pages):
            self.assertEqual(current.pages[offset+i].extract_text(),page.extract_text())
        text=''.join(p.extract_text() for p in current.pages[:offset])
        for phrase in ['SWOT','393/393','모래시계','ATK','CC0','NOT_RUN','감시탑']:
            self.assertIn(phrase,text)
