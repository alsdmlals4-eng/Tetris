"""Source-bound complete R2 reader. Real candidate atlases; no runtime claims."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from reportlab.platypus import SimpleDocTemplate, Paragraph, PageBreak, Spacer, Image
from pypdf import PdfReader
import build_replanning_blueprint as b
from r2_blueprint_visuals import Screen, AssetSheet, DATA

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'docs/design/R2_COMPLETE_HUMAN_BLUEPRINT.md'
OUT=ROOT/'docs/blueprints/TETRIS_R2_COMPLETE_HUMAN_BLUEPRINT.pdf'

def build(revision,draft=False):
    if not re.fullmatch('[0-9a-f]{40}',revision): raise ValueError('Exact source commit required')
    paths=[SOURCE,Path(__file__),ROOT/'tools/r2_blueprint_visuals.py',ROOT/'tools/build_replanning_blueprint.py',
           ROOT/'tools/prepare_r2_session_data.py',ROOT/'tools/prepare_autocast_boss.py',
           ROOT/'docs/design/r2-complete-session.json',ROOT/'docs/design/autocast-r2-data.json',
           ROOT/'docs/design/REPLANNING_AUTOCAST_R2.md',ROOT/'docs/design/REPLANNING_FOUNDATION.md']
    paths += [ROOT/a['path'] for a in DATA['assets'].values()]
    paths += [ROOT/'docs/assets/reference/planned/replanning/autocast'/n for n in ['boss-source.png','boss-cutout.aseprite','boss-cutout.extraction.json','tiles.aseprite']]
    hashes={}
    for p in paths:
        rel=p.relative_to(ROOT).as_posix();h=hashlib.sha256(p.read_bytes()).hexdigest()
        if not draft:
            raw=subprocess.run(['git','show',revision+':'+rel],cwd=ROOT,capture_output=True,check=True).stdout
            if hashlib.sha256(raw).hexdigest()!=h: raise ValueError('Uncommitted source: '+rel)
        hashes[rel]=h
    rules={s[:2]:s.split('\n',1)[1] for s in re.split(r'^## ',(ROOT/'docs/design/REPLANNING_AUTOCAST_R2.md').read_text(encoding='utf-8'),flags=re.M)[1:]}
    source=re.sub(r'^@rule (\d+)$',lambda m:rules[m[1]],SOURCE.read_text(encoding='utf-8'),flags=re.M)
    b.register_fonts();story=[]
    for n,section in enumerate(re.split(r'^## ',source,flags=re.M)[1:]):
        lines=section.strip().splitlines()
        if n: story.append(PageBreak())
        story.append(Paragraph(b.rich(lines[0]),b.style('title',20,26,fontName=b.BOLD,spaceAfter=12)))
        i=1
        while i<len(lines):
            line=lines[i].strip();i+=1
            if not line: continue
            if line.startswith('|'):
                group=[line]
                while i<len(lines) and lines[i].strip().startswith('|'): group.append(lines[i]);i+=1
                story.extend([b.md_table(group,b.PAGE[0]-72),Spacer(1,8)]);continue
            if line.startswith('@screen '): story.extend([Screen(line.split()[1],690),Spacer(1,8)])
            elif line.startswith('@newpage '): story.extend([PageBreak(),b.para(line[9:])])
            elif line=='@boss': story.append(AssetSheet('R2-BOSS',list(DATA['assets']['R2-BOSS']['regions'])))
            elif line=='@portrait': story.append(AssetSheet('R1-PORTRAIT',list(DATA['assets']['R1-PORTRAIT']['regions'])))
            elif line=='@icons': story.append(AssetSheet('R1-ICONS',['strike','ward','recover','heavy']))
            elif line=='@tiles': story.append(Image(str(ROOT/DATA['assets']['R2-TILES']['path']),width=270,height=270))
            elif line=='@fixture':
                f=DATA['chain_teaching'];rows=['| 행(y) | 시작 | 두 번째 연쇄 후 |','|---|---|---|']
                rows += [f'| {y} | {a} | {z} |' for y,(a,z) in enumerate(zip(f['rows'],f['final_rows']))]
                story.extend([b.md_table(rows,b.PAGE[0]-72),b.para(f"교환 {f['swap']} / 웨이브별 제거 {f['waves']} / 자동 발동 {f['expected_casts']}회")])
            elif line=='@encounter':
                rows=['| 순서 | 행동 | 기본 대기 | 피해 | 예고 모션 |','|---|---|---|---|---|']
                rows += [f"| {j+1} | {a['label']} | {a['seconds']}초 | {a['damage']} | {a['anticipation']}초 |" for j,a in enumerate(DATA['encounter']['actions'])]
                story.append(b.md_table(rows,b.PAGE[0]-72))
            elif line=='@save':
                rows=['| 그룹 | 반드시 저장할 상태 |','|---|---|']
                rows += [f"| {group} | {', '.join(fields)} |" for group,fields in DATA['save_contract']['required_groups'].items()]
                story.append(b.md_table(rows,b.PAGE[0]-72))
            elif line.startswith('@'): raise ValueError('Unknown directive: '+line)
            else: story.append(b.para(line))
    def frame(c,doc):
        c.saveState();c.setFillColor(b.NAVY);c.setFont(b.FONT,9)
        c.drawString(36,b.PAGE[1]-28,'R2 통합 사람용 블루프린트 · 기획/자산 최종 검토용 · 실행 화면 아님')
        c.setFont(b.FONT,8);c.drawString(36,18,f'{doc.page:02d} · '+('DRAFT' if draft else 'source '+revision[:12])+' · 구현/플레이 검증은 승인 후')
        c.restoreState()
    SimpleDocTemplate(str(OUT),pagesize=b.PAGE,leftMargin=36,rightMargin=36,topMargin=52,bottomMargin=36,
                      title='R2 통합 사람용 블루프린트',author='Tetris project',invariant=1).build(story,onFirstPage=frame,onLaterPages=frame)
    m={'source_commit':revision,'draft':draft,'input_hashes':hashes,'pdf_sha256':hashlib.sha256(OUT.read_bytes()).hexdigest(),
       'pages':len(PdfReader(OUT).pages),'role':'HUMAN_GDD_PDF_DERIVED_VIEW','asset_approval':DATA['asset_approval'],
       'runtime':'NOT_RUN_USER_DEFERRED','human':'NOT_RUN','render_review':'SEE_COMPLETE_PUBLICATION_RECEIPT'}
    OUT.with_suffix('.manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'output':str(OUT),'pages':m['pages'],'sha256':m['pdf_sha256']},ensure_ascii=False))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--source-commit',required=True);p.add_argument('--draft',action='store_true');a=p.parse_args();build(a.source_commit,a.draft)
