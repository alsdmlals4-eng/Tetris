"""Prepend a source-bound R3 amendment to the existing current reader.

Read the previous PDF/manifest from the supplied immutable source revision, not
from the output being overwritten. Re-running the same source is idempotent.
The 37-page design artifact and all 52 previous reader pages stay unchanged.
"""
import argparse
import hashlib
import io
import json
import re
import subprocess
from pathlib import Path
from pypdf import PdfReader, PdfWriter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Image
import build_replanning_blueprint as b

ROOT=Path(__file__).resolve().parents[1]
OUTPUT=ROOT/'docs/blueprints/TETRIS_R2_CURRENT_IMPLEMENTATION_READER.pdf'
SPEC=ROOT/'docs/design/R3_FALLING_CHAIN_AND_DISRUPTION_SPEC.md'
EVIDENCE=ROOT/'docs/validation/bonus-assist-20260920'

def git_bytes(revision,path):
    return subprocess.run(['git','show',revision+':'+path.relative_to(ROOT).as_posix()],cwd=ROOT,capture_output=True,check=True).stdout

def build(revision):
    if not re.fullmatch('[0-9a-f]{40}',revision):raise ValueError('Exact source commit required')
    prior_raw=git_bytes(revision,OUTPUT)
    prior_manifest=json.loads(git_bytes(revision,OUTPUT.with_suffix('.manifest.json')))
    if 'current_amendment' in prior_manifest:
        return build_mastery(revision,prior_raw,prior_manifest)
    if hashlib.sha256(prior_raw).hexdigest()!=prior_manifest['pdf_sha256']:raise ValueError('Previous publication hash mismatch')
    inputs=[SPEC,Path(__file__),ROOT/'tools/build_replanning_blueprint.py',ROOT/'scenes/replanned_r3/resource_choice.tscn',EVIDENCE/'runtime.json']
    inputs+=list((ROOT/'src/replanned_r3').glob('*.gd'))+list((ROOT/'data/replanned_r3').glob('*.json'))
    catalogue=ROOT/'docs/design/r2-complete-session.json'
    inputs += [catalogue,ROOT/'src/replanned_r2/r2_assets.gd',ROOT/'assets/replanned_r2/audio/attack.ogg',ROOT/'assets/replanned_r2/audio/impact-License.txt']
    inputs += [ROOT/a['path'] for a in json.loads(catalogue.read_text(encoding='utf-8'))['assets'].values()]
    inputs += [ROOT/'docs/assets/reference/planned/replanning/skill-performer-20260914'/name for name in ['manifest-v2.json','performer-atlas-v2.png']]
    images=[('bonus-selection','실제 보너스 획득 후 보정 선택. 대기 10쌍을 초과한 보상이 마나로 남고, 선택 중 양쪽 시간이 정지한다.'),('practice-t2-impact','실제 연습 명령 결과: 공격 뒤 치유 문양이 터져도 시동은 공격. T2 스킬이 한 번만 발동했다.'),('tier-6-presentation-fixture','T6 표현 전용 fixture. 링·광선·외곽 문양·크기 차이를 점검했다. 실제 플레이에서 6연쇄를 달성한 증거가 아니다.'),('enemy-destruction','실제 적 파괴 후 표시. 파괴된 고정 ID만 집계하며 자원·보급·스킬 보상을 지급하지 않는다.')]
    inputs += [EVIDENCE/(name+'.png') for name,_ in images]
    hashes={}
    for path in inputs:
        raw=git_bytes(revision,path)
        current=path.read_bytes()
        if current!=raw and not (path.suffix in ['.md','.gd','.py','.json','.tscn'] and current.replace(b'\r\n',b'\n')==raw):raise ValueError('Uncommitted source '+str(path))
        hashes[path.relative_to(ROOT).as_posix()]=hashlib.sha256(raw).hexdigest()
    b.register_fonts()
    story=[]
    def title(text):story.append(Paragraph(b.rich(text),b.style('title',20,26,fontName=b.BOLD,spaceAfter=12)))
    title('R3 현재 구현 - 보너스 보정과 연쇄 보상')
    story.append(b.para('2026-09-20 개정. 먼저 이 절을 읽고, 뒤의 R2 구현 15쪽과 설계 37쪽은 당시 이력으로 읽습니다. 실제 진입: scenes/replanned_r3/resource_choice.tscn. 기본 production과 기존 캠페인은 별도 경로입니다.'))
    story.append(Image(str(EVIDENCE/'bonus-selection.png'),width=640,height=360))
    story.append(b.para(images[0][1],True))
    section=SPEC.read_text(encoding='utf-8').split('## 최신 추가 결정',1)[1].split('## 현재 추가 결정',1)[0]
    chunks=re.split(r'^### ',section,flags=re.M)
    for number,chunk in enumerate(chunks):
        story.append(PageBreak())
        lines=chunk.strip().splitlines()
        title('적용 범위와 책임' if number==0 else lines[0])
        i=1
        while i<len(lines):
            line=lines[i].strip().replace('**','');i+=1
            if not line:continue
            if line.startswith('|'):
                rows=[line]
                while i<len(lines) and lines[i].strip().startswith('|'):rows.append(lines[i]);i+=1
                story.extend([b.md_table(rows,b.PAGE[0]-72),Spacer(1,8)])
            else:story.append(b.para(line))
    for name,caption in images[1:]:
        story.append(PageBreak())
        title({'practice-t2-impact':'실행 화면 - 2연쇄 학습','tier-6-presentation-fixture':'표현 비교 - T6 시각 검증','enemy-destruction':'실행 화면 - 적 파괴'}[name])
        story.append(Image(str(EVIDENCE/(name+'.png')),width=680,height=382.5))
        story.append(b.para(caption))
        story.append(b.para('자동 테스트와 실제 렌더는 확인한 실행만 증명합니다. HUMAN 재미·밸런스·물리 입력·최종 아트·출시는 NOT_RUN입니다.',True))
    buffer=io.BytesIO()
    def footer(canvas,doc):
        canvas.setFont(b.FONT,8)
        canvas.drawString(36,18,'R3 개정 / source '+revision[:12]+' / '+str(doc.page)+' / 뒤의 기존 52쪽은 역사 보존')
    SimpleDocTemplate(buffer,pagesize=b.PAGE,leftMargin=36,rightMargin=36,topMargin=30,bottomMargin=36,invariant=1).build(story,onFirstPage=footer,onLaterPages=footer)
    addition=PdfReader(buffer)
    previous=PdfReader(io.BytesIO(prior_raw))
    writer=PdfWriter()
    writer.append(addition)
    writer.append(previous)
    writer.add_metadata({'/Title':'Tetris 현재 구현 블루프린트 - R3 보너스 보정','/Subject':'R3 source '+revision+'; preserved previous publication'})
    with OUTPUT.open('wb') as stream:writer.write(stream)
    check=PdfReader(OUTPUT)
    offset=len(addition.pages)
    for i,page in enumerate(previous.pages):
        assert page.get_contents().get_data()==check.pages[offset+i].get_contents().get_data()
    manifest=dict(prior_manifest)
    manifest.update({'pages':len(check.pages),'supplement_pages':prior_manifest['supplement_pages']+offset,'pdf_sha256':hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
        'current_amendment':{'source_commit':revision,'input_hashes':hashes,'pages':offset,'preserved_pages':len(previous.pages),'previous_pdf_sha256':hashlib.sha256(prior_raw).hexdigest(),'human':'NOT_RUN','render_review':'REQUIRED'}})
    OUTPUT.with_suffix('.manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'pages':manifest['pages'],'new_pages':offset,'sha256':manifest['pdf_sha256']}))

def build_mastery(revision,prior_raw,prior_manifest):
    """Append the approved successor once while keeping every previous page."""
    if prior_manifest['current_amendment'].get('kind')=='mastery-patterns':
        raise ValueError('Already amended source; select the immutable pre-publication commit')
    if hashlib.sha256(prior_raw).hexdigest()!=prior_manifest['pdf_sha256']:
        raise ValueError('Previous publication hash mismatch')
    evidence=ROOT/'docs/validation/mastery-patterns-20260921'
    images=[('pattern-rift_core','차징 강타 준비: 실제 현재 피해45, 누적피해20으로 추가10만 취소. 기본35와 파괴4칸은 남는다.'),
            ('practice-spin-960','960x540 실제 T스핀 연습. 회전 후 Space로 소거한다. 시간 압박과 저장 영향 없이 실제 판정·보급을 연습한다.'),
            ('status-foundry','주조소가 장갑12를 획득한 실제 상태. 다음 행동까지 잔량을 표시하며 공격으로 소진할 수 있다.'),
            ('status-outer_breach','외곽 강타 후 약점 노출. 남은 공유 시간 동안 다음 공격 한 번의 자원 포함 위력을25% 늘린다.')]
    inputs=[SPEC,Path(__file__),ROOT/'tools/build_replanning_blueprint.py',ROOT/'scenes/replanned_r3/resource_choice.tscn',evidence/'runtime.json',evidence/'supply-comparison.json']
    inputs+=list((ROOT/'src/replanned_r3').glob('*.gd'))+list((ROOT/'data/replanned_r3').glob('*.json'))
    inputs += [evidence/(name+'.png') for name,_ in images]
    hashes={}
    for path in inputs:
        raw=git_bytes(revision,path)
        current=path.read_bytes()
        if current!=raw and not (path.suffix in ['.md','.gd','.py','.json','.tscn'] and current.replace(b'\r\n',b'\n')==raw):
            raise ValueError('Uncommitted source '+str(path))
        hashes[path.relative_to(ROOT).as_posix()]=hashlib.sha256(raw).hexdigest()
    b.register_fonts()
    story=[]
    def title(text):story.append(Paragraph(b.rich(text),b.style('title',20,26,fontName=b.BOLD,spaceAfter=12)))
    title('R3 현재 구현 - 테트리스 기술과 적 대응')
    story.append(b.para('2026-09-21 개정. 먼저 이 절을 읽습니다. 뒤의61쪽은 이전 구현과 설계 이력이며 삭제하지 않았습니다. 실제 진입은 resource_choice.tscn, 새 저장 경로는 mastery_patterns입니다.'))
    story.append(Image(str(evidence/images[0][0])+'.png',width=640,height=360))
    story.append(b.para(images[0][1],True))
    section=SPEC.read_text(encoding='utf-8').split('## 현행 추가 결정',1)[1].split('## 최신 추가 결정',1)[0]
    for number,chunk in enumerate(re.split(r'^### ',section,flags=re.M)):
        story.append(PageBreak())
        lines=chunk.strip().splitlines()
        title('범위와 읽기 경로' if number==0 else lines[0])
        i=1
        while i<len(lines):
            line=lines[i].strip().replace('**','');i+=1
            if not line:continue
            if line.startswith('|'):
                rows=[line]
                while i<len(lines) and lines[i].strip().startswith('|'):rows.append(lines[i]);i+=1
                story.extend([b.md_table(rows,b.PAGE[0]-72),Spacer(1,8)])
            else:story.append(b.para(line))
    for name,caption in images[1:]:
        story.append(PageBreak())
        title('실제 화면 - '+{'practice-spin-960':'짧은 기술 연습','status-foundry':'적 장갑','status-outer_breach':'약점 기회'}[name])
        story.append(Image(str(evidence/(name+'.png')),width=680,height=382.5))
        story.append(b.para(caption))
        story.append(b.para('자동 검사·실제 렌더와 HUMAN 재미 검수는 다릅니다. 이 화면은 실행 관찰이며 최종 밸런스·아트·출시 승인 증거가 아닙니다. HUMAN: NOT_RUN.',True))
    buffer=io.BytesIO()
    def footer(canvas,doc):
        canvas.setFont(b.FONT,8)
        canvas.drawString(36,18,'R3 기술/패턴 개정 / source '+revision[:12]+' / '+str(doc.page)+' / 이전61쪽 보존')
    SimpleDocTemplate(buffer,pagesize=b.PAGE,leftMargin=36,rightMargin=36,topMargin=30,bottomMargin=36,invariant=1).build(story,onFirstPage=footer,onLaterPages=footer)
    addition=PdfReader(buffer)
    previous=PdfReader(io.BytesIO(prior_raw))
    writer=PdfWriter()
    writer.append(addition)
    writer.append(previous)
    writer.add_metadata({'/Title':'Tetris 현재 구현 블루프린트 - 기술 보급과 적 패턴','/Subject':'R3 source '+revision+'; historical reader preserved'})
    with OUTPUT.open('wb') as stream:writer.write(stream)
    check=PdfReader(OUTPUT)
    offset=len(addition.pages)
    for i,page in enumerate(previous.pages):
        assert page.get_contents().get_data()==check.pages[offset+i].get_contents().get_data()
    manifest=dict(prior_manifest)
    history=list(prior_manifest.get('amendment_history',[]))+[prior_manifest['current_amendment']]
    manifest.update({'pages':len(check.pages),'supplement_pages':prior_manifest['supplement_pages']+offset,'pdf_sha256':hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),'amendment_history':history,
        'current_amendment':{'kind':'mastery-patterns','source_commit':revision,'input_hashes':hashes,'pages':offset,'preserved_pages':len(previous.pages),'previous_pdf_sha256':hashlib.sha256(prior_raw).hexdigest(),'human':'NOT_RUN','render_review':'REQUIRED'}})
    OUTPUT.with_suffix('.manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'pages':manifest['pages'],'new_pages':offset,'sha256':manifest['pdf_sha256']}))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--source-commit',required=True)
    build(parser.parse_args().source_commit)
