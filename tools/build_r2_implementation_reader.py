"""Exact-source implementation supplement plus byte-preserved historical pages."""
import argparse
import hashlib
import io
import json
import re
import subprocess
from pathlib import Path
from pypdf import PdfReader, PdfWriter
from reportlab.platypus import SimpleDocTemplate, Paragraph, PageBreak, Spacer, Image, KeepTogether
import build_replanning_blueprint as b

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'docs/design/R2_IMPLEMENTATION_READER.md'
ORIGINAL = ROOT/'docs/blueprints/TETRIS_R2_COMPLETE_HUMAN_BLUEPRINT.pdf'
OUTPUT = ROOT/'docs/blueprints/TETRIS_R2_CURRENT_IMPLEMENTATION_READER.pdf'

def read_json(relative):
    return json.loads((ROOT/relative).read_text(encoding='utf-8'))

def table_lines(kind):
    rules = read_json('docs/design/autocast-r2-data.json')
    campaign = read_json('data/replanned_r2/expedition.json')
    names = read_json('data/replanned_r2/encounter-presentation.json')['encounters']
    rows = []
    if kind == 'resources':
        rows = [['LINE 소거 문양','셀 하나의 효과','CHAIN 역할'],
                ['공격',str(rules['line']['attack_per_cell'])+' 공격 준비','파동마다 선택 계열 스킬'],
                ['방어',str(rules['line']['armor_per_cell'])+' 방어도','타일 직접 보상 없음'],
                ['치유',str(rules['line']['healing_per_cell'])+' HP 회복','초과 치유 저장 없음'],
                ['모래시계',str(rules['line']['time_per_cell_seconds'])+'초','현재 확정 전 행동에만 적용']]
    elif kind == 'skills':
        rows = [['계열']+['T'+str(i) for i in range(1,7)]]
        rows += [[category]+list(map(str,rules['skills'][category])) for category in ['ATK','DEF','SUP']]
    elif kind == 'encounters':
        rows = [['전선 / 적','HP','순서대로 대기초 / 원시 피해']]
        for key, entry in campaign['encounters'].items():
            rows.append([entry['label']+' / '+names[key]['enemy_name'],str(entry['combat']['boss_hp']),
                         '; '.join(f"{a['label']} {a['seconds']}초/{a['damage']}" for a in entry['combat']['actions'])])
    elif kind == 'supplies':
        rows = [['정비','HP 회복','공격 준비','방어도']]
        rows += [[s['label'],str(s['heal']),str(s['attack_bank']),str(s['armor'])] for s in campaign['supplies'].values()]
    elif kind == 'assets':
        rows = [['자산 ID','실제 원본 경로','영역 수 / 소비']]
        for key, asset in read_json('docs/design/r2-complete-session.json')['assets'].items():
            rows.append([key,asset['path'],str(len(asset.get('regions',{})))+' / r2_assets → r2_screen'])
    elif kind == 'verification':
        log = (ROOT/'docs/validation/r2-audio-20260913/full-gut.log').read_text(encoding='utf-8')
        tests = re.findall(r'^Tests\s+(\d+)',log,re.M)[-1]
        passing = re.findall(r'^Passing Tests\s+(\d+)',log,re.M)[-1]
        asserts = re.findall(r'^Asserts\s+(\d+)',log,re.M)[-1]
        rows = [['검증 층','현재 증거','판정 상한'],['자동 게임 검사',f'{passing}/{tests} tests, {asserts} assertions','기계 검증'],
                ['실제 Godot','분기·정비·결말 / 125% / 음향 재생·음소거','기록된 실행만 확인'],
                ['배포 파일','선택 자산·JSON·음원·실제 원정 진입','로컬 시험용; 기존 종료 경고 별도'],
                ['인간·기기·재미·출시','NOT_RUN','자동 PASS로 대체 금지']]
    else: raise ValueError('Unknown table: '+kind)
    return '\n'.join('| '+' | '.join(row)+' |' for row in rows)

def inputs():
    paths = [SOURCE,ORIGINAL,Path(__file__),ROOT/'tools/build_replanning_blueprint.py',
             ROOT/'docs/operations/TETRIS_R2_WHOLE_GAME.md',ROOT/'docs/design/REPLANNING_FOUNDATION.md',
             ROOT/'docs/design/autocast-r2-data.json',ROOT/'docs/design/r2-complete-session.json',
             ROOT/'docs/validation/r2-audio-20260913/full-gut.log']
    paths += list((ROOT/'src/replanned_r2').glob('*.gd'))
    paths += list((ROOT/'data/replanned_r2').glob('*.json'))
    paths += [ROOT/p for p in re.findall(r'^@image (.+)$',SOURCE.read_text(encoding='utf-8'),re.M)]
    paths += [ROOT/a['path'] for a in read_json('docs/design/r2-complete-session.json')['assets'].values()]
    return sorted(set(paths))

def build(revision):
    if not re.fullmatch('[0-9a-f]{40}',revision): raise ValueError('Exact SHA required')
    hashes = {}
    for path in inputs():
        relative=path.relative_to(ROOT).as_posix()
        raw=subprocess.run(['git','show',revision+':'+relative],cwd=ROOT,capture_output=True,check=True).stdout
        # Git may normalize textual line endings. Bind repository object bytes,
        # and independently require current checkout text/binary content parity.
        current=path.read_bytes()
        if current!=raw and not (path.suffix in ['.md','.py','.gd','.json','.log'] and current.replace(b'\r\n',b'\n')==raw):
            raise ValueError('Uncommitted source: '+relative)
        hashes[relative]=hashlib.sha256(raw).hexdigest()
    b.register_fonts()
    story=[]
    for n,section in enumerate(re.split(r'^## ',SOURCE.read_text(encoding='utf-8'),flags=re.M)[1:]):
        if n: story.append(PageBreak())
        lines=section.strip().splitlines()
        story.append(Paragraph(b.rich(lines[0]),b.style('title',20,26,fontName=b.BOLD,spaceAfter=12)))
        i=1
        while i<len(lines):
            line=lines[i].strip();i+=1
            if not line: continue
            if line.startswith('@image '):
                block=[Image(str(ROOT/line[7:]),width=580,height=580*720/1280),Spacer(1,8)]
                while i<len(lines) and not lines[i].strip():i+=1
                if i<len(lines) and not lines[i].startswith(('@','|')):
                    block.append(b.para(lines[i]));i+=1
                story.append(KeepTogether(block))
            elif line.startswith('@'):
                story.append(b.md_table(table_lines(line[1:]).splitlines(),b.PAGE[0]-72))
                story.append(Spacer(1,10))
            elif line.startswith('|'):
                group=[line]
                while i<len(lines) and lines[i].startswith('|'):group.append(lines[i]);i+=1
                story.append(b.md_table(group,b.PAGE[0]-72))
            else:story.append(b.para(line))
    buffer=io.BytesIO()
    def footer(canvas,doc):
        canvas.setFont(b.FONT,8)
        canvas.drawString(36,20,'현재 구현 보완본 / '+revision[:12]+' / '+str(doc.page))
    SimpleDocTemplate(buffer,pagesize=b.PAGE,rightMargin=36,leftMargin=36,topMargin=30,bottomMargin=36,invariant=1).build(story,onFirstPage=footer,onLaterPages=footer)
    supplement=PdfReader(buffer)
    original=PdfReader(ORIGINAL)
    writer=PdfWriter()
    writer.append(supplement)
    writer.append(original)
    writer.add_metadata({'/Title':'R2 현재 구현과 상세 블루프린트','/Subject':'Source '+revision})
    with OUTPUT.open('wb') as stream:writer.write(stream)
    manifest={'source_commit':revision,'input_hashes':hashes,'supplement_pages':len(supplement.pages),
              'historical_pages':len(original.pages),'pages':len(writer.pages),
              'pdf_sha256':hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
              'role':'HUMAN_GDD_PDF_DERIVED_VIEW','human':'NOT_RUN','release':'NOT_RUN'}
    OUTPUT.with_suffix('.manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(manifest,ensure_ascii=False))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--source-commit',required=True)
    build(parser.parse_args().source_commit)
