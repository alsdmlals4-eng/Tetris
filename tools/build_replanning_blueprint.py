"""Derived reader PDF only. No gameplay, raster editing, or asset promotion.

Reuses this project's ReportLab/Korean-font publication approach. All creative
pixels are image-model source files. Region cropping is a PDF clipping path,
not a synthesized/repainted asset. UI/flow diagrams are editable native PDF
text and geometry, explicitly labelled design projections, never screenshots.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import subprocess
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle, Flowable
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/design/REPLANNING_HUMAN_BLUEPRINT.md'
DATA = ROOT / 'docs/design/blueprint-data.json'
ASSET_DIR = ROOT / 'docs/assets/reference/planned/replanning/blueprint'
OUTPUT = ROOT / 'docs/blueprints/TETRIS_REPLANNED_HUMAN_BLUEPRINT.pdf'
MANIFEST = OUTPUT.with_suffix('.manifest.json')
INK, MUTED = colors.HexColor('#182c38'), colors.HexColor('#516572')
NAVY, GOLD, PAPER = colors.HexColor('#101722'), colors.HexColor('#b78d4f'), colors.HexColor('#f5f3ed')
CYAN = colors.HexColor('#63cde2')
PAGE = landscape(A4)
FONT, BOLD = 'BP-Korean', 'BP-Korean-Bold'


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def register_fonts():
    paths = [Path('C:/Windows/Fonts/malgun.ttf'), Path('C:/Windows/Fonts/malgunbd.ttf')]
    if not all(p.exists() for p in paths):
        raise RuntimeError('Required Korean font missing; do not silently substitute glyphs')
    pdfmetrics.registerFont(TTFont(FONT, str(paths[0])))
    pdfmetrics.registerFont(TTFont(BOLD, str(paths[1])))


def rich(text):
    escaped = html.escape(text)
    escaped = re.sub(r'`([^`]+)`', r'<font color="#385966">\1</font>', escaped)
    escaped = re.sub(r'\[([^]]+)\]\(([^)]+)\)', r'<link href="\2" color="#175a76">\1</link>', escaped)
    return escaped


def style(name, size=10.5, leading=16, **kwargs):
    options = dict(fontName=FONT, fontSize=size, leading=leading,
                   textColor=INK, wordWrap='CJK', spaceAfter=9)
    options.update(kwargs)
    return ParagraphStyle(name, **options)


def para(text, small=False):
    return Paragraph(rich(text), style('small' if small else 'body', 9 if small else 10.5, 13 if small else 16))


class Art:
    def __init__(self):
        self.manifest = json.loads((ASSET_DIR / 'manifest.json').read_text(encoding='utf-8'))
        self.assets = {a['id']: a for a in self.manifest['assets']}

    def paint(self, canvas, aid, region, x, y, w, h):
        a = self.assets[aid]
        rect = [0, 0, *a['size']] if region == 'all' else a['regions'][region]
        rx, ry, rw, rh = rect
        scale = min(w / rw, h / rh)
        dw, dh = rw * scale, rh * scale
        dx, dy = x + (w-dw)/2, y + (h-dh)/2
        canvas.saveState()
        clip = canvas.beginPath()
        clip.rect(dx, dy, dw, dh)
        canvas.clipPath(clip, stroke=0, fill=0)
        canvas.drawImage(str(ASSET_DIR/a['path']), dx-rx*scale,
                         dy-(a['size'][1]-ry-rh)*scale,
                         width=a['size'][0]*scale, height=a['size'][1]*scale)
        canvas.restoreState()


class ArtPanel(Flowable):
    def __init__(self, art, aid, region, width, height):
        super().__init__()
        self.art, self.aid, self.region = art, aid, region
        factor = min(1, 235 / float(height))
        self.width, self.height = float(width)*factor, float(height)*factor
        self.hAlign = 'CENTER'
    def draw(self):
        self.art.paint(self.canv, self.aid, self.region, 0, 0, self.width, self.height)


class ScreenPanel(Flowable):
    """Reference 1280x720 design geometry; not a rendered game."""
    def __init__(self, art, name, width=520):
        super().__init__()
        self.art, self.name = art, name
        self.width, self.height = width, width*720/1280
        self.hAlign = 'CENTER'
    def draw(self):
        c = self.canv
        c.saveState()
        c.scale(self.width/1280, self.width/1280)
        self.paint_screen(c, self.name)
        c.restoreState()

    def text(self, c, x, y, text, size=18, color=colors.white):
        c.setFont(FONT, size)
        c.setFillColor(color)
        c.drawString(x,y,text)

    def rect(self,c,x,y,w,h,fill=NAVY,stroke=GOLD):
        c.setFillColor(fill); c.setStrokeColor(stroke); c.setLineWidth(1.5)
        c.rect(x,y,w,h,fill=1,stroke=1)

    def button(self,c,x,y,w,text,active=False):
        self.rect(c,x,y,w,42,colors.HexColor('#174861') if active else NAVY)
        self.text(c,x+12,y+13,text,18)

    def paint_screen(self,c,name):
        self.rect(c,0,0,1280,720)
        if name in ('main','briefing','result'):
            self.art.paint(c,'R1-ENV','full',0,0,1280,720)
            self.rect(c,32,68,480,585)
            if name=='main':
                self.text(c,60,597,'두 개의 준비, 하나의 위협',30,GOLD)
                self.text(c,60,555,'새 기획 · 제목 확정 전',18,CYAN)
                for i,t in enumerate(['시작','연습','설정','종료']):
                    self.button(c,60,446-i*70,410,t,i==0)
                self.text(c,60,104,'LINE으로 MP · CHAIN으로 증폭',18)
            elif name=='briefing':
                self.text(c,60,590,'출격 전 · 균열 파괴자',28,GOLD)
                self.art.paint(c,'R1-BOSS','idle',558,225,660,420)
                for i,t in enumerate(['목표: 보스를 쓰러뜨리기','HP100 / MP20 / 증폭2','LINE → MP / CHAIN → 증폭','공유 ETA = 다음 보스 행동','넘침: HP25 손실 / HP0 패배','스킬을 열면 전투 전체 정지']):
                    self.text(c,60,520-i*50,t,20)
                self.button(c,60,155,192,'연습 먼저')
                self.button(c,270,155,192,'출격',True)
            else:
                self.text(c,60,590,'전투 결과 · 승리',30,GOLD)
                self.art.paint(c,'R1-PORTRAIT','victory',60,405,132,132)
                self.text(c,210,485,'결정적 행동: 증폭 강격',18)
                for i,t in enumerate(['활성 시간 / 정지 시간 따로','실제 MP·증폭 획득과 낭비','방어·회복의 실제 효과','선택 이유를 복기하기']):
                    self.text(c,60,365-i*47,t,20)
                self.button(c,60,125,192,'같은 도전 다시',True)
                self.button(c,270,125,192,'메인')
                self.art.paint(c,'R1-BOSS','defeat',558,225,660,420)
            return

        self.rect(c,16,16,616,688)
        self.rect(c,648,16,616,688)
        self.button(c,32,654,270,'LINE',name!='chain')
        self.button(c,320,654,288,'CHAIN',name=='chain')
        self.text(c,660,680,'균열 파괴자 · HP 130 / 180',23,GOLD)
        self.art.paint(c,'R1-BOSS','anticipation' if name=='timer' else 'idle',660,350,592,306)
        self.rect(c,648,224,616,104)
        self.text(c,666,296,'현재 · 균열 강타 / 직접 피해35',20)
        self.text(c,666,251,'다음 · 망치 견제 / 준비10초',16,colors.HexColor('#aab5c9'))
        self.text(c,1100,266,'1.0초' if name=='timer' else '8.4초',32,CYAN)
        self.text(c,1068,237,'공유 ETA'+(' · 정지' if name=='skill' else ''),17,CYAN)
        self.rect(c,648,104,616,104)
        self.art.paint(c,'R1-PORTRAIT','neutral',652,108,96,96)
        self.text(c,770,170,'HP 40 / 100',22)
        self.text(c,770,135,'MP 20 / 60   증폭 2 / 10',22,CYAN)
        for i,(label,icon) in enumerate([('강격','strike'),('방벽','ward'),('재정비','recover')]):
            x=656+i*201
            self.rect(c,x,16,190,72)
            self.art.paint(c,'R1-ICONS',icon,x+5,26,52,52)
            self.text(c,x+65,55,label,20)
            self.text(c,x+65,30,'MP10',16,CYAN)
        tile_names=['flame','star','leaf','drop','crescent','diamond']
        if name=='chain':
            rows=json.loads(DATA.read_text(encoding='utf-8'))['teaching']['chain_fixture']['rows']
            mapping=self.art.assets['R1-TILES']['chain_mapping']
            for y,row in enumerate(rows):
                for x,symbol in enumerate(row):
                    self.art.paint(c,'R1-TILES',mapping[symbol],76+x*60,142+(7-y)*60,58,58)
            c.setStrokeColor(CYAN);c.setLineWidth(4);c.rect(195,561,61,61,stroke=1,fill=0)
            self.text(c,55,94,'선택 → 인접 교환 · 가로/세로3개',21)
            self.text(c,55,55,'연쇄 깊이와 보유 증폭은 다릅니다',19,GOLD)
        else:
            for y in range(20):
                for x in range(10):
                    self.art.paint(c,'R1-TILES','empty',190+x*26,124+y*26,25,25)
            for y in range(7):
                for x in range(10):
                    if x==4 or (y>3 and x>6):continue
                    self.art.paint(c,'R1-TILES',tile_names[(x+2*y)%6],190+x*26,124+y*26,25,25)
            for x,y in [(4,17),(3,16),(4,16),(5,16)]:
                self.art.paint(c,'R1-TILES','crescent',190+x*26,124+y*26,25,25)
            self.text(c,59,604,'HOLD',18,CYAN)
            self.text(c,486,604,'NEXT',18,CYAN)
            for x,y in [(0,0),(1,0),(1,1),(2,1)]:
                self.art.paint(c,'R1-TILES','leaf',70+x*20,549+y*20,19,19)
            previews=[('star',[(0,0),(1,0),(0,1),(1,1)]),('drop',[(0,0),(1,0),(2,0),(3,0)]),('leaf',[(0,0),(1,0),(1,1),(2,1)]),('bolt',[(0,0),(1,0),(2,0),(2,1)]),('crescent',[(0,0),(1,0),(2,0),(1,1)])]
            for i,(tile,cells) in enumerate(previews):
                for x,y in cells:
                    self.art.paint(c,'R1-TILES',tile,480+x*20,530-i*65+y*20,19,19)
            self.text(c,46,77,'← → 이동   Z/X 회전   C 홀드',19)
            self.text(c,46,43,'Space 낙하 · 안내는 보드 아래',19,GOLD)
        if name=='skill':
            self.rect(c,648,16,616,208,colors.HexColor('#14283a'),CYAN)
            self.text(c,668,192,'전술 일시정지 · 균열 방벽',24,CYAN)
            self.art.paint(c,'R1-ICONS','ward',664,97,80,80)
            self.text(c,757,163,'현재 강타35 방어 · 기본20 / 증폭30',20)
            self.text(c,757,135,'비용: MP10 / MP10 + 증폭2',20)
            self.text(c,757,108,'예상 피해15 / 5 · HP25 / 35',20)
            self.text(c,668,79,'사용 후 MP10 · 증폭 기본2 / 증폭0',19,CYAN)
            self.button(c,672,26,168,'기본 사용')
            self.button(c,856,26,182,'증폭 사용',True)
            self.button(c,1054,26,184,'취소')


class AtlasPanel(Flowable):
    def __init__(self,art,assets=False):
        super().__init__();self.art,self.assets=art,assets
        self.width,self.height=750,320;self.hAlign='CENTER'
    def draw(self):
        c=self.canv
        names=['main','briefing','line','chain','skill','result']
        labels=['메인','안내','LINE 전투','CHAIN 전투','스킬 정지','결과·재도전']
        for i,name in enumerate(names):
            x=(i%3)*253;y=(1-i//3)*160
            c.saveState();c.translate(x,y+18);c.scale(240/1280,240/1280)
            ScreenPanel(self.art,name).paint_screen(c,name)
            c.restoreState();c.setFont(FONT,9);c.setFillColor(INK);c.drawString(x,y+4,labels[i])


def md_table(lines,width):
    rows=[]
    for line in lines:
        cells=[x.strip() for x in line.strip().strip('|').split('|')]
        if all(re.fullmatch(r':?-+:?',x) for x in cells):continue
        rows.append(cells)
    count=len(rows[0])
    cell_style=style('cell',9.5,14,spaceBefore=0)
    rows=[[Paragraph(rich(x),cell_style) for x in row] for row in rows]
    weights=[1]*count
    if count>=4:weights=[0.95]+[1.15]*(count-2)+[1.1]
    if count==3:weights=[1,1.8,1.4]
    total=sum(weights)
    table=Table(rows,colWidths=[width*x/total for x in weights],repeatRows=1,hAlign='LEFT')
    table.setStyle(TableStyle([
        ('BACKGROUND',(0,0),(-1,0),colors.HexColor('#d7e3e4')),
        ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.HexColor('#fffefd'),colors.HexColor('#edece6')]),
        ('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),9),
        ('RIGHTPADDING',(0,0),(-1,-1),9),('TOPPADDING',(0,0),(-1,-1),7),
        ('BOTTOMPADDING',(0,0),(-1,-1),5),('TOPPADDING',(0,0),(-1,-1),5),('LINEBELOW',(0,0),(-1,0),1,GOLD),
        ('LINEBELOW',(0,1),(-1,-1),0.3,colors.HexColor('#d4d8d6'))]))
    return table


def build(source_commit, draft=False):
    register_fonts();art=Art()
    inputs=[SOURCE,DATA,ASSET_DIR/'manifest.json',ROOT/'docs/design/REPLANNING_FOUNDATION.md',ROOT/'docs/design/REPLANNING_RULES_AND_FUN_SPEC.md',ROOT/'docs/design/REPLANNING_ASSET_BRIEFS.md',Path(__file__)]
    inputs += [ASSET_DIR/a['path'] for a in art.assets.values()]
    if not draft:
        for path in inputs:
            rel = path.relative_to(ROOT).as_posix()
            committed = subprocess.run(['git','show',f'{source_commit}:{rel}'],cwd=ROOT,capture_output=True,check=True).stdout
            if hashlib.sha256(committed).hexdigest() != digest(path):
                raise RuntimeError(f'Source revision does not contain current bytes: {rel}')
    raw=SOURCE.read_text(encoding='utf-8')
    sections=re.split(r'^## ',raw,flags=re.M)[1:]
    story=[]
    width=PAGE[0]-72
    for index,section in enumerate(sections):
        lines=section.strip().splitlines();title=lines.pop(0)
        if index:story.append(PageBreak())
        story.append(Paragraph(rich(title),style('heading',22,29,fontName=BOLD,spaceAfter=14)))
        i=0
        while i<len(lines):
            line=lines[i].strip()
            if not line:i+=1;continue
            if line.startswith('|'):
                group=[]
                while i<len(lines) and lines[i].strip().startswith('|'):
                    group.append(lines[i]);i+=1
                story.extend([md_table(group,width),Spacer(1,12)]);continue
            if line.startswith('@asset '):
                _,aid,region,w,h=line.split()
                story.extend([ArtPanel(art,aid,region,w,h),Spacer(1,10)])
            elif line.startswith('@screen '):
                screen_name=line.split()[1]
                screen_width=700 if screen_name=='line' else (300 if screen_name in ('briefing','timer') else 360)
                story.extend([ScreenPanel(art,screen_name,width=screen_width),Spacer(1,8),para('설계 화면 · 실제 후보 이미지 사용 / 실행 캡처 아님',True)])
            elif line.startswith('@page '):
                story.extend([PageBreak(),Paragraph(rich(line[6:]),style('heading',22,29,fontName=BOLD,spaceAfter=14))])
            elif line=='@atlas':
                story.extend([AtlasPanel(art),Spacer(1,10)])
            elif line=='@assets':
                panels=[ArtPanel(art,aid,'all',180,150) for aid in ['R1-TILES','R1-ICONS','R1-PORTRAIT','R1-BOSS']]
                story.extend([Table([panels],colWidths=[width/4]*4),Spacer(1,12)])
            elif line.startswith('@flow '):
                texts=line[6:].split('|')
                cells=[Paragraph(rich(t),style('flow',10.5,15,alignment=TA_CENTER)) for t in texts]
                t=Table([cells],colWidths=[width/len(cells)]*len(cells))
                t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),colors.HexColor('#dce8e8')),('BOX',(0,0),(-1,-1),1,GOLD),('INNERGRID',(0,0),(-1,-1),0.5,GOLD),('TOPPADDING',(0,0),(-1,-1),13),('BOTTOMPADDING',(0,0),(-1,-1),13)]))
                story.extend([t,para('왼쪽에서 오른쪽으로 진행합니다. 분기·취소 조건은 아래 표를 따릅니다.',True)])
            else:
                story.append(para(line))
            i+=1
    def frame(c,doc):
        c.saveState()
        c.setFillColor(PAPER);c.rect(0,0,*PAGE,fill=1,stroke=0)
        c.setFillColor(NAVY);c.rect(0,PAGE[1]-42,PAGE[0],42,fill=1,stroke=0)
        c.setFont(FONT,9);c.setFillColor(colors.HexColor('#e6d7bb'))
        c.drawString(36,PAGE[1]-26,'Tetris 프로젝트 / 새 기획 사람용 블루프린트')
        c.drawRightString(PAGE[0]-36,PAGE[1]-26,'최종 검토용 권장안 · 게임 구현 전')
        c.setStrokeColor(GOLD);c.line(36,31,PAGE[0]-36,31)
        c.setFillColor(MUTED);c.setFont(FONT,8)
        c.drawString(36,18,f'{doc.page:02d} · 2026.09.11 · 절 번호는 본문 제목 기준 / 그림은 후보, 실행 증거 아님')
        c.drawRightString(PAGE[0]-36,18,'DIRTY LOCAL DRAFT' if draft else f'source {source_commit[:12]}')
        c.restoreState()
    OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    doc=SimpleDocTemplate(str(OUTPUT),pagesize=PAGE,rightMargin=36,leftMargin=36,
                          topMargin=59,bottomMargin=44,title='Tetris 새 기획 사람용 블루프린트',author='Tetris project',pageCompression=1,invariant=1)
    doc.build(story,onFirstPage=frame,onLaterPages=frame)
    manifest={'document_id':'TETRIS-REPLAN-HUMAN-01','artifact_role':'HUMAN_GDD_PDF_DERIVED_VIEW','source_commit':None if draft else source_commit,
              'generated_at':'2026-09-11','status':'DIRTY_LOCAL_DRAFT' if draft else 'DERIVED_REVIEW_COPY','approval':'PENDING_FINAL_USER_REVIEW',
              'input_hashes':{str(p.relative_to(ROOT)).replace('\\','/'):digest(p) for p in inputs},
              'pdf_sha256':digest(OUTPUT),'page_count':len(PdfReader(OUTPUT).pages),'section_count':len(sections),
              'visuals':'Generated candidate art and text-native screen/flow projections; no runtime screenshots',
              'render_review':'See docs/operations/TETRIS_BLUEPRINT_PREPARATION_2026-09-11.json for hash-bound post-build review',
              'runtime':'NOT_RUN_USER_DEFERRED','human':'NOT_RUN'}
    MANIFEST.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'pdf':str(OUTPUT),'pages':manifest['page_count'],'sha256':manifest['pdf_sha256']},ensure_ascii=False))


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--source-commit',required=True)
    parser.add_argument('--draft',action='store_true',help='Uncommitted preview; never claims an exact source revision')
    args=parser.parse_args()
    if not re.fullmatch('[0-9a-f]{40}',args.source_commit):raise SystemExit('Exact 40-character source commit required')
    build(args.source_commit,args.draft)
