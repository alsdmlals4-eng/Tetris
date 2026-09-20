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

    def test_current_r3_amendment_is_source_bound_and_preserves_52_page_reader(self):
        import io
        from pypdf import PdfReader
        path=ROOT/'docs/blueprints/TETRIS_R2_CURRENT_IMPLEMENTATION_READER.pdf'
        manifest=json.loads(path.with_suffix('.manifest.json').read_text(encoding='utf-8'))
        self.assertIn('current_amendment',manifest)
        if 'current_amendment' not in manifest:return
        entry=manifest['current_amendment']
        for relative,digest in entry['input_hashes'].items():
            raw=subprocess.run(['git','show',entry['source_commit']+':'+relative],cwd=ROOT,capture_output=True,check=True).stdout
            self.assertEqual(hashlib.sha256(raw).hexdigest(),digest,relative)
        previous_bytes=subprocess.run(['git','show',entry['source_commit']+':'+path.relative_to(ROOT).as_posix()],cwd=ROOT,capture_output=True,check=True).stdout
        self.assertEqual(hashlib.sha256(previous_bytes).hexdigest(),entry['previous_pdf_sha256'])
        previous=PdfReader(io.BytesIO(previous_bytes))
        current=PdfReader(path)
        self.assertEqual(len(previous.pages),52)
        self.assertEqual(len(current.pages),entry['pages']+52)
        for i,page in enumerate(previous.pages):
            self.assertEqual(page.get_contents().get_data(),current.pages[entry['pages']+i].get_contents().get_data())
        text=''.join(page.extract_text() for page in current.pages[:entry['pages']])
        for phrase in ['보너스','10쌍','T6','시동','NOT_RUN','실제','파괴','HUMAN']:
            self.assertIn(phrase,text)
