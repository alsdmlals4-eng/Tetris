"""Preparation evidence only; these tests do not execute the game."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import unittest
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
D=json.loads((ROOT/'docs/design/r2-complete-session.json').read_text(encoding='utf-8'))
spec=importlib.util.spec_from_file_location('fixtures',ROOT/'tools/prepare_r2_session_data.py')
f=importlib.util.module_from_spec(spec);spec.loader.exec_module(f)

class CompletePreparationTest(unittest.TestCase):
    def test_real_two_wave_fixture(self):
        x=D['chain_teaching'];b=[list(r) for r in x['rows']]
        self.assertFalse(f.matches(b))
        (ax,ay),(bx,by)=x['swap'];self.assertEqual(abs(ax-bx)+abs(ay-by),1)
        b[ay][ax],b[by][bx]=b[by][bx],b[ay][ax];stream=iter(x['refill_stream'])
        for wave in x['waves']:
            actual=f.matches(b);self.assertEqual(actual,{tuple(p) for p in wave});f.refill(b,actual,stream)
        self.assertFalse(f.matches(b));self.assertEqual([''.join(r) for r in b],x['final_rows'])
        rules=json.loads((ROOT/'docs/design/autocast-r2-data.json').read_text(encoding='utf-8'))
        self.assertEqual(sum(rules['skills']['ATK'][:x['expected_casts']])+7,x['expected_atk_damage_bank7'])

    def test_fixture_generation_repeatable(self):
        self.assertEqual(json.loads(json.dumps(f.fixture())),D['chain_teaching'])

    def test_line_clear_counts(self):
        x=D['line_teaching'];b=[list(r) for r in x['visible_rows']]
        for xx,yy in x['landing']:self.assertEqual(b[yy][xx],'.');b[yy][xx]='A'
        cleared=[r for r in b if '.' not in r];self.assertEqual(len(cleared),1)
        self.assertEqual({t:cleared[0].count(t) for t in 'ADHT'},x['expected_counts'])
        self.assertEqual(x['initial_hp']+x['expected_counts']['H'],x['expected_hp'])

    def test_atlases_have_valid_hash_and_regions(self):
        for a in D['assets'].values():
            p=ROOT/a['path'];self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),a['sha256'])
            with Image.open(p) as im:self.assertEqual(list(im.size),a['size'])
            for x,y,w,h in a['regions'].values():
                self.assertTrue(0<=x<x+w<=a['size'][0]);self.assertTrue(0<=y<y+h<=a['size'][1])

    def test_actual_alpha_and_padding(self):
        a=D['assets']['R2-BOSS']
        with Image.open(ROOT/a['path']) as im:
            self.assertEqual(im.mode,'RGBA');alpha=im.getchannel('A');hist=alpha.histogram()
            self.assertGreater(hist[0],1000000);self.assertGreater(hist[255],700000)
            for x,y,w,h in a['regions'].values():
                cell=alpha.crop((x,y,x+w,y+h));self.assertEqual(cell.crop((0,0,10,h)).getextrema(),(0,0))
                self.assertEqual(cell.crop((0,h-10,w,h)).getextrema(),(0,0))
                self.assertIsNotNone(cell.getbbox())

    def test_encounter_and_evidence_boundaries(self):
        e=D['encounter'];self.assertEqual(sum(a['seconds'] for a in e['actions']),42)
        self.assertEqual(sum(a['damage'] for a in e['actions']),59)
        self.assertEqual(D['runtime'],'NOT_RUN_USER_DEFERRED');self.assertEqual(D['human'],'NOT_RUN')
        self.assertEqual(D['asset_approval'],'PENDING_FINAL_USER_REVIEW')
        self.assertIn('NOT_SMOOTH',D['motion']['mode'])

    def test_save_contract_covers_live_state(self):
        s=D['save_contract'];g=s['required_groups']
        self.assertIn('hp',g['boss']);self.assertIn('mode',g['identity'])
        self.assertTrue({'active_x','active_y','active_rotation','gravity_accumulator_us','grounded_us','lock_reset_count','hold_available','shape_rng_state','resource_rng_state'}<=set(g['line']))
        self.assertIn('chain_rng_state',g['chain']);self.assertIn('full pause',s['restore'])
        self.assertNotEqual(s['path'],s['options_path'])

    def test_published_pdf_when_available(self):
        p=ROOT/'docs/blueprints/TETRIS_R2_COMPLETE_HUMAN_BLUEPRINT.pdf'
        if not p.exists():self.skipTest('Publication not yet built')
        m=json.loads(p.with_suffix('.manifest.json').read_text(encoding='utf-8'))
        self.assertFalse(m['draft']);self.assertGreaterEqual(m['pages'],33)
        self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),m['pdf_sha256'])
        for path,h in m['input_hashes'].items():
            self.assertEqual(hashlib.sha256((ROOT/path).read_bytes()).hexdigest(),h,path)
            raw=subprocess.run(['git','show',m['source_commit']+':'+path],cwd=ROOT,capture_output=True,check=True).stdout
            self.assertEqual(hashlib.sha256(raw).hexdigest(),h,path)

if __name__=='__main__':unittest.main()
