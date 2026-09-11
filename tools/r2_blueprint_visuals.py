"""Text-native layout projections using real candidate artwork, not game captures."""
import json
from pathlib import Path
from reportlab.lib import colors
from reportlab.platypus import Flowable
import build_replanning_blueprint as b

ROOT=Path(__file__).resolve().parents[1]
DATA=json.loads((ROOT/'docs/design/r2-complete-session.json').read_text(encoding='utf-8'))


class Art:
    def paint(self,c,aid,region,x,y,w,h,cover=False):
        a=DATA['assets'][aid];rx,ry,rw,rh=a['regions'][region]
        scale=(max if cover else min)(w/rw,h/rh)
        dx=x+(w-rw*scale)/2;dy=y+h-rh*scale if cover else y+(h-rh*scale)/2
        c.saveState();p=c.beginPath();p.rect(*( (x,y,w,h) if cover else (dx,dy,rw*scale,rh*scale) ));c.clipPath(p,stroke=0,fill=0)
        c.drawImage(str(ROOT/a['path']),dx-rx*scale,dy-(a['size'][1]-ry-rh)*scale,
                    width=a['size'][0]*scale,height=a['size'][1]*scale,mask='auto')
        c.restoreState()


class Screen(Flowable):
    def __init__(self,name,width=730):
        super().__init__();self.name=name;self.width=width;self.height=width*720/1280;self.hAlign='CENTER';self.art=Art()
    def draw(self):
        c=self.canv;c.saveState();c.scale(self.width/1280,self.width/1280);self.paint(c);c.restoreState()
    def text(self,c,x,y,t,size=18,color=colors.white):
        c.setFillColor(color);c.setFont(b.FONT,size);c.drawString(x,y,t)
    def box(self,c,x,y,w,h,active=False):
        c.setFillColor(colors.HexColor('#123449') if active else b.NAVY);c.setStrokeColor(b.GOLD);c.setLineWidth(1.5);c.rect(x,y,w,h,fill=1,stroke=1)
    def button(self,c,x,y,w,t,active=False):
        self.box(c,x,y,w,36,active);self.text(c,x+12,y+10,t,17)
    def paint(self,c):
        name=self.name;a=self.art;self.box(c,0,0,1280,720)
        if name in ['main','briefing','result','settings']:
            a.paint(c,'R1-ENV','full',0,0,1280,720,True);self.box(c,40,50,480,620)
            self.text(c,66,615,{'main':'균열에 맞서는 두 퍼즐','briefing':'출격 · 균열 파괴자','result':'전투 결과 · 승리','settings':'설정 · 일시정지'}[name],29,b.GOLD)
            self.text(c,66,574,'R2 기획 화면 · 제목은 작업 표기',17,b.CYAN)
            if name=='main':
                for i,t in enumerate(['도전 시작','연습하기','설정','종료']): self.button(c,66,454-i*74,426,t,i==0)
                self.text(c,66,106,'LINE 준비 → CHAIN 자동 발동',21)
                a.paint(c,'R2-BOSS','idle',570,80,650,580)
            elif name=='briefing':
                for i,t in enumerate(['목표: 보스 HP 240 → 0','내 HP 100 · 공격 가산 0 · 방어도 0','현재: 망치 견제 / 피해 12 / 10초','다음: 균열 강타 / 피해 35','4타일은 LINE 자원 / CHAIN 매칭','계열을 선택하고 연쇄로 자동 발동']): self.text(c,66,512-i*49,t,19)
                self.button(c,66,100,198,'연습 먼저');self.button(c,278,100,214,'출격',True);a.paint(c,'R2-BOSS','anticipation',570,80,650,580)
            elif name=='result':
                a.paint(c,'R1-PORTRAIT','victory',66,410,128,128)
                for i,t in enumerate(['활성 시간 96초 / 정지 12초','최대 연쇄 4 · 자동 발동 32회','LINE 기여 피해 48 / 방어 26','회복 실효 22 / 시간 연장 5.5초','수치는 화면 설명용 예시']):self.text(c,66,365-i*42,t,21)
                self.button(c,66,83,198,'같은 도전 다시');self.button(c,278,83,214,'메인');a.paint(c,'R2-BOSS','defeat',570,80,650,580)
            else:
                for i,t in enumerate(['전체 일시정지 · ETA / 파동 정지','효과음 70% / 음악 50%','연출 감소 켜기','문양 + 색상 항상 표시','키 재지정 / 기본값 복원','진행 보존 후 메인으로']):self.text(c,66,504-i*54,t,21)
                self.button(c,66,105,426,'그대로 계속',True)
            return
        self.box(c,16,16,616,688);self.box(c,648,16,616,688)
        self.button(c,32,658,278,'LINE · 자원 준비',name=='line');self.button(c,322,658,294,'CHAIN · 스킬 발동',name!='line')
        if name=='line':
            for y in range(20):
                for x in range(10):
                    self.box(c,194+x*26,117+y*26,25,25)
                    if y<6 and not(x==4 or y>3 and x>6):a.paint(c,'R2-TILES',['attack','defense','healing','time'][(x+y)%4],194+x*26,117+y*26,25,25)
            for x,y in [(3,15),(4,15),(5,15),(4,16)]:a.paint(c,'R2-TILES','attack',194+x*26,117+y*26,25,25)
            self.text(c,42,92,'HOLD     NEXT 1     NEXT 2     NEXT 3     NEXT 4     NEXT 5',17,b.CYAN)
            shapes=[[(0,0),(1,0),(1,1),(2,1)],[(0,0),(1,0),(2,0),(3,0)],[(0,0),(1,0),(0,1),(1,1)],[(0,0),(1,0),(2,0),(1,1)],[(0,0),(1,0),(2,0),(2,1)],[(1,0),(2,0),(0,1),(1,1)]]
            for i,shape in enumerate(shapes):
                for x,y in shape:a.paint(c,'R2-TILES',['attack','defense','healing','time'][i%4],52+i*91+x*13,48+y*13,12,12)
            self.text(c,43,29,'← → 이동 · Z/X 회전 · Space 낙하 · C 홀드',17)
        else:
            rows=DATA['chain_teaching']['rows'];mapping=dict(zip('ADHT',['attack','defense','healing','time']))
            for y,row in enumerate(rows):
                for x,v in enumerate(row):a.paint(c,'R2-TILES',mapping[v],68+x*64,118+(7-y)*64,62,62)
            for x,y in DATA['chain_teaching']['swap']:
                c.setStrokeColor(b.CYAN);c.setLineWidth(3);c.rect(68+x*64,118+(7-y)*64,62,62,fill=0,stroke=1)
            self.text(c,42,78,'인접 교환 → 파동마다 자동 기술',21,b.CYAN)
            self.text(c,42,42,'타일 직접 보상 없음 · Tab 보드 전환',19)
        a.paint(c,'R1-ENV','full',648,404,616,300,True)
        # Boss upper silhouette may crop skirt only; full atlas is shown separately.
        a.paint(c,'R2-BOSS','anticipation' if name=='threat' else 'idle',655,404,602,258,True)
        self.box(c,704,662,504,39);self.text(c,719,677,'균열 파괴자   HP 183 / 240',23,b.GOLD)
        self.box(c,660,675-34,592,9);c.setFillColor(colors.HexColor('#bf3b50'));c.rect(662,643,446,5,fill=1,stroke=0)
        self.box(c,648,276,616,116)
        self.text(c,661,365,'현재 · 균열 강타',17);self.text(c,661,328,'직접 피해 35',19);self.text(c,661,294,'방벽 적용 가능',16,b.CYAN)
        self.text(c,883,369,'공유 타이머',17,b.GOLD)
        c.setStrokeColor(b.CYAN);c.setLineWidth(4);c.circle(951,335,28,stroke=1,fill=0)
        self.text(c,930,327,'8.4',25,b.CYAN);self.text(c,891,284,'연장 0.5 / 3초',15)
        self.text(c,1074,365,'다음 · 망치 견제',17);self.text(c,1074,328,'직접 피해 12',19);self.text(c,1074,294,'순서 예고',16)
        self.box(c,648,168,616,96);a.paint(c,'R1-PORTRAIT','neutral',648,168,96,96)
        self.text(c,761,229,'HP 82 / 100     방어도 10',23);self.text(c,761,191,'다음 공격 +7     현재 방벽 7',21,b.CYAN)
        self.box(c,648,16,616,140)
        for i,t in enumerate(['ATK 공격','DEF 방어','SUP 치유']):self.button(c,660+i*198,114,190,t,i==(1 if name=='skill' else 0))
        for i in range(6):
            self.box(c,660+i*98,81,92,26,i==0);self.text(c,687+i*98,87,f'T{i+1}',17)
        icon='ward' if name=='skill' else 'strike';a.paint(c,'R1-ICONS',icon,660,25,48,48)
        self.text(c,720,61,'다음: 방벽 T1 · 목표 3 → 현재 7 유지' if name=='skill' else '다음: 균열 베기 T1 · 4 + 가산 7',18)
        self.text(c,720,32,'최근 발동: 없음 · 연쇄 시작 전 계열 선택',16,b.CYAN)


class AssetSheet(Flowable):
    def __init__(self,aid,regions):
        super().__init__();self.aid=aid;self.regions=regions;self.width=740;self.height=320
    def draw(self):
        for i,region in enumerate(self.regions):
            x=(i%3)*247;y=(1-i//3)*160
            self.canv.setFillColor(b.NAVY);self.canv.rect(x,y+18,238,140,fill=1,stroke=0)
            Art().paint(self.canv,self.aid,region,x,y+18,238,140)
            self.canv.setFont(b.FONT,10);self.canv.setFillColor(b.INK);self.canv.drawString(x,y+3,region)
