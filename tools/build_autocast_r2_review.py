"""Derived rules amendment; preserves R1 PDF. No synthesized raster artwork."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from reportlab.platypus import SimpleDocTemplate, Paragraph, PageBreak, Spacer, Image
from pypdf import PdfReader
import build_replanning_blueprint as common

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'docs/design/REPLANNING_AUTOCAST_R2.md'
DATA=ROOT/'docs/design/autocast-r2-data.json'
OUT=ROOT/'docs/blueprints/TETRIS_AUTOCAST_R2_REVIEW.pdf'


def build(revision):
    if not re.fullmatch('[0-9a-f]{40}',revision):
        raise ValueError('Exact source commit required')
    data=json.loads(DATA.read_text(encoding='utf-8'))
    inputs=[SOURCE,DATA,Path(__file__),ROOT/'tools/build_replanning_blueprint.py',ROOT/'docs/design/REPLANNING_FOUNDATION.md',ROOT/data['tile_asset']['path'],ROOT/data['tile_asset']['source']]
    hashes={}
    for p in inputs:
        rel=p.relative_to(ROOT).as_posix()
        raw=subprocess.run(['git','show',revision+':'+rel],cwd=ROOT,capture_output=True,check=True).stdout
        h=hashlib.sha256(p.read_bytes()).hexdigest()
        if hashlib.sha256(raw).hexdigest()!=h: raise ValueError('Uncommitted source: '+rel)
        hashes[rel]=h
    common.register_fonts()
    sections=re.split(r'^## ',SOURCE.read_text(encoding='utf-8'),flags=re.M)[1:]
    story=[]
    for n,section in enumerate(sections):
        lines=section.strip().splitlines()
        if n: story.append(PageBreak())
        story.append(Paragraph(common.rich(lines[0]),common.style('title',21,28,fontName=common.BOLD,spaceAfter=15)))
        i=1
        while i<len(lines):
            line=lines[i].strip()
            if not line: i+=1;continue
            if line.startswith('|'):
                group=[]
                while i<len(lines) and lines[i].strip().startswith('|'):
                    group.append(lines[i]);i+=1
                story.extend([common.md_table(group,common.PAGE[0]-72),Spacer(1,10)])
                continue
            if line=='@tiles':
                story.extend([Image(str(ROOT/data['tile_asset']['path']),width=165,height=165),Spacer(1,8)])
            else: story.append(common.para(line))
            i+=1
    def frame(c,doc):
        c.saveState();c.setFont(common.FONT,9)
        c.setFillColor(common.NAVY)
        c.drawString(36,common.PAGE[1]-28,'R2 · 자동 발동 규칙 개정 검토본 / 전체 최종 블루프린트 아님')
        c.setFont(common.FONT,8)
        c.drawString(36,18,f'{doc.page:02d} · source {revision[:12]} · 자산 준비 미완료 / 구현 미실시')
        c.restoreState()
    SimpleDocTemplate(str(OUT),pagesize=common.PAGE,leftMargin=36,rightMargin=36,topMargin=55,bottomMargin=40,
                      title='R2 자동 발동 규칙 개정 검토본',author='Tetris project',invariant=1).build(story,onFirstPage=frame,onLaterPages=frame)
    manifest={'source_commit':revision,'input_hashes':hashes,'pdf_sha256':hashlib.sha256(OUT.read_bytes()).hexdigest(),
              'pages':len(PdfReader(OUT).pages),'role':'HUMAN_GDD_PDF_DERIVED_AMENDMENT','complete_blueprint':False,
              'runtime':'NOT_RUN_USER_DEFERRED','human':'NOT_RUN','asset_ready':False,'render_review':'NOT_YET_REVIEWED_SEE_R2_PROGRESS'}
    OUT.with_suffix('.manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'output':str(OUT),'pages':manifest['pages'],'sha256':manifest['pdf_sha256']},ensure_ascii=False))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--source-commit',required=True)
    build(p.parse_args().source_commit)
