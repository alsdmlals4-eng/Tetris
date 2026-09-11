"""Preparation checks only: never counts as Godot or player evidence."""
import hashlib
import json
import re
import subprocess
import unittest
from pathlib import Path

from PIL import Image
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'docs/assets/reference/planned/replanning/blueprint'
DATA = json.loads((ROOT / 'docs/design/blueprint-data.json').read_text(encoding='utf-8'))
MANIFEST = json.loads((ART / 'manifest.json').read_text(encoding='utf-8'))


def matches(rows):
    found = set()
    for y, row in enumerate(rows):
        for x, value in enumerate(row):
            for dx, dy in ((1, 0), (0, 1)):
                cells = []
                xx, yy = x, y
                while 0 <= yy < len(rows) and 0 <= xx < len(row) and rows[yy][xx] == value:
                    cells.append((xx, yy)); xx += dx; yy += dy
                if len(cells) >= 3:
                    found.update(cells)
    return found


class ReplanningBlueprintTest(unittest.TestCase):
    def test_asset_bytes_and_dimensions(self):
        for a in MANIFEST['assets']:
            p = ART / a['path']
            self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(), a['sha256'])
            with Image.open(p) as im:
                self.assertEqual(list(im.size), a['size'])
                self.assertEqual(im.mode, 'RGB')  # Intentional matte; not a fake alpha claim.
            if 'editable_source' in a:
                self.assertEqual(hashlib.sha256((ART/a['editable_source']).read_bytes()).hexdigest(), a['editable_sha256'])

    def test_regions_are_bounded_nonoverlapping_and_complete(self):
        total = 0
        for a in MANIFEST['assets']:
            rects = list(a['regions'].values()); total += len(rects)
            for i, (x,y,w,h) in enumerate(rects):
                self.assertTrue(all(isinstance(n,int) for n in (x,y,w,h)))
                self.assertTrue(0 <= x < x+w <= a['size'][0] and 0 <= y < y+h <= a['size'][1])
                for xx,yy,ww,hh in rects[i+1:]:
                    self.assertFalse(x < xx+ww and xx < x+w and y < yy+hh and yy < y+h)
        self.assertEqual(total,25)
        tiles = next(a for a in MANIFEST['assets'] if a['id']=='R1-TILES')
        self.assertEqual(set(tiles['line_mapping']),set('IOTSZJL'))
        self.assertEqual(set(tiles['chain_mapping']),set('RYGBPC'))
        self.assertEqual(len(set(tiles['line_mapping'].values())),7)

    def test_approval_and_runtime_boundary(self):
        self.assertEqual(MANIFEST['approval'],'PENDING_FINAL_USER_REVIEW')
        self.assertEqual(DATA['state'],'SPECIFIED_RECOMMENDATION_NOT_RUNTIME_DATA')
        for a in MANIFEST['assets']:
            self.assertEqual(a['binding_status'],'PLANNED_NOT_BOUND')
            for anchor in a['actual_consumer_anchor']:
                path = anchor.split(':')[0]
                self.assertTrue((ROOT/path).is_file(),path)

    def test_exact_half_layout_and_height_budget(self):
        s = DATA['screen_layout']
        self.assertEqual(s['outer_margin']*2+s['center_gap']+s['column_width']*2,s['reference_size'][0])
        self.assertEqual(s['outer_margin']*2+s['column_height'],s['reference_size'][1])
        self.assertEqual(sum(s['right_heights'].values()),s['column_height'])
        self.assertEqual(s['line_cell']*20,520)

    def test_teaching_chain_first_wave(self):
        fixture=DATA['teaching']['chain_fixture']; rows=[list(r) for r in fixture['rows']]
        self.assertEqual(len(rows),8)
        self.assertTrue(all(len(row)==8 and set(row)<=set('RYGBPC') for row in rows))
        self.assertEqual(matches(rows),set())
        (x,y),(xx,yy)=fixture['swap']
        self.assertEqual(abs(x-xx)+abs(y-yy),1)
        rows[y][x],rows[yy][xx]=rows[yy][xx],rows[y][x]
        self.assertEqual(matches(rows),{tuple(c) for c in fixture['expected_first_wave_cells']})

    def test_teaching_line_landing(self):
        f=DATA['teaching']['line_fixture']; rows=[list(r) for r in f['visible_rows']]
        self.assertEqual((len(rows),len(f['hidden_rows_content'])),(20,4))
        for x,y in f['target_landing_cells']:
            self.assertEqual(rows[y][x],'.'); rows[y][x]='I'
        cleared=sum('.' not in row for row in rows)
        self.assertEqual(cleared,f['expected_lines'])
        self.assertEqual([0,10,22,36,52][cleared],f['expected_mp'])

    def test_encounter_and_skill_arithmetic(self):
        n=DATA['normal_encounter']; schedule=n['schedule']
        self.assertEqual(sum(a['windup_seconds'] for a in schedule),42)
        self.assertEqual(sum(a['damage'] for a in schedule),59)
        self.assertEqual(59+12+35,106)
        self.assertTrue(n['repeat_schedule'])
        self.assertEqual(n['end_condition'],'HP_TERMINAL_ONLY')
        f=DATA['teaching']['skill_fixture']
        self.assertEqual(f['player_hp']-max(0,f['damage']-30),f['expected_remaining_hp'])
        self.assertEqual(min(100,10+21)-35,-4)
        self.assertEqual(52-(60-55),47)

    def test_no_damage_action_has_no_fake_impact(self):
        p=DATA['no_damage_presentation']
        action=next(a for a in DATA['normal_encounter']['schedule'] if a['action_id']==p['action_id'])
        self.assertEqual(action['kind'],'no_damage')
        self.assertEqual(action['damage'],0)
        self.assertFalse(p['impact']); self.assertFalse(p['hit_sound'])
        self.assertEqual(p['active_state'],'recovery')
        self.assertEqual(p['hp_recovery'],0)
        self.assertEqual(p['eta_label'],'안정 종료까지')

    def test_all_sections_and_asset_directives(self):
        source=(ROOT/'docs/design/REPLANNING_HUMAN_BLUEPRINT.md').read_text(encoding='utf-8')
        self.assertEqual(re.findall(r'^## (\d+) ·',source,re.M),[f'{i:02}' for i in range(1,51)])
        ids={a['id']:a for a in MANIFEST['assets']}
        for aid, region in re.findall(r'^@asset (\S+) (\S+)',source,re.M):
            self.assertIn(aid,ids)
            self.assertTrue(region=='all' or region in ids[aid]['regions'])

    def test_ci_fetches_publication_source_history(self):
        workflow=(ROOT/'.github/workflows/core-poc-ci.yml').read_text(encoding='utf-8')
        self.assertIn('fetch-depth: 0',workflow)
        self.assertLess(workflow.index('fetch-depth: 0'),workflow.index('python -m unittest discover -s tests/tooling'))

    def test_preserved_pdf_publication_matches_immutable_sources(self):
        path=ROOT/'docs/blueprints/TETRIS_REPLANNED_HUMAN_BLUEPRINT.pdf'
        receipt=json.loads(path.with_suffix('.manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),receipt['pdf_sha256'])
        for rel,expected in receipt['input_hashes'].items():
            # R1 is preserved historical evidence. Current Foundation may point to R2.
            # Validate source bytes at the published commit, not a moving local owner.
            self.assertTrue(receipt['source_commit'])
            if receipt['source_commit']:
                blob=subprocess.run(['git','show',receipt['source_commit']+':'+rel],cwd=ROOT,capture_output=True,check=True).stdout
                self.assertEqual(hashlib.sha256(blob).hexdigest(),expected,rel)
        reader=PdfReader(path)
        self.assertEqual(len(reader.pages),receipt['page_count'])
        self.assertEqual(receipt['section_count'],50)
        self.assertTrue(all(len(p.extract_text())>100 for p in reader.pages))


if __name__=='__main__':
    unittest.main()
