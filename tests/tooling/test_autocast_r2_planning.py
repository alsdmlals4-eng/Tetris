"""Planning arithmetic and publication evidence, not runtime implementation tests."""
import hashlib
import json
import subprocess
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
D = json.loads((ROOT/'docs/design/autocast-r2-data.json').read_text(encoding='utf-8'))


class AutocastPlanningTest(unittest.TestCase):
    def test_direction_and_boundary(self):
        self.assertFalse(D['chain']['direct_tile_rewards'])
        self.assertEqual(D['chain']['casts_per_wave'], 1)
        self.assertEqual(D['chain']['mp_cost'], 0)
        self.assertFalse(D['skills']['manual_use'])
        self.assertEqual(D['runtime'], 'NOT_RUN_USER_DEFERRED')
        self.assertEqual(D['approval_gate'], 'FULL_BLUEPRINT_AND_ASSETS_NOT_READY')

    def test_four_types_and_stage_tables(self):
        self.assertEqual(set(D['tile_types']), set(D['tile_asset']['regions']))
        self.assertEqual(set(D['line']['resource_bag']), set(D['tile_types']))
        for category in ('ATK','DEF','SUP'):
            self.assertEqual(len(D['skills'][category]), D['chain']['stage_cap'])
            self.assertEqual(sorted(D['skills'][category]), D['skills'][category])

    def test_worked_arithmetic_is_consistent_with_seed(self):
        self.assertEqual(sum(D['skills']['ATK'][:3])+7,25)
        self.assertEqual(35-max(D['skills']['DEF'][:3])-10,18)
        self.assertEqual(2*D['line']['time_per_cell_seconds'],0.5)
        self.assertEqual(min(20*D['line']['time_per_cell_seconds'],D['timer']['extension_cap_seconds']-2.5),0.5)

    def test_half_layout(self):
        x=D['layout']
        self.assertEqual(2*x['margin']+x['gap']+2*x['column_width'],x['width'])
        self.assertEqual(2*x['margin']+sum(x['right_heights']),x['height'])

    def test_asset_regions_hashes_and_explicit_failed_alpha(self):
        a=D['tile_asset']
        for path,key in [('path','sha256'),('source','source_sha256')]:
            self.assertEqual(hashlib.sha256((ROOT/a[path]).read_bytes()).hexdigest(),a[key])
        with Image.open(ROOT/a['path']) as im:
            self.assertEqual(list(im.size),a['size'])
        rects=list(a['regions'].values())
        for i,(x,y,w,h) in enumerate(rects):
            self.assertTrue(0<=x<x+w<=1254 and 0<=y<y+h<=1254)
            for xx,yy,ww,hh in rects[i+1:]:
                self.assertFalse(x<xx+ww and xx<x+w and y<yy+hh and yy<y+h)
        self.assertEqual(sum(w*h for x,y,w,h in rects),1254*1254)
        self.assertFalse(D['boss_asset']['alpha_present'])
        self.assertFalse(D['boss_asset']['runtime_adoption'])

    def test_r2_publication_when_present(self):
        p=ROOT/'docs/blueprints/TETRIS_AUTOCAST_R2_REVIEW.pdf'
        if not p.exists():
            self.skipTest('R2 PDF not built yet; this is not publication PASS')
        m=json.loads(p.with_suffix('.manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),m['pdf_sha256'])
        for path,h in m['input_hashes'].items():
            raw=subprocess.run(['git','show',m['source_commit']+':'+path],cwd=ROOT,capture_output=True,check=True).stdout
            self.assertEqual(hashlib.sha256(raw).hexdigest(),h,path)


if __name__=='__main__': unittest.main()
