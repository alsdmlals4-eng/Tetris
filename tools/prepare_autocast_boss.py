"""User-approved 2026-09-11 local background-only extraction of R2 boss.

Not a general art generator: preserve RGB character pixels, extract the near-neutral
bright checker matte, add transparent cell padding, and retain source provenance.
"""
import argparse
import hashlib
import json
from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

STATES=['idle','anticipation','impact','recovery','hurt','defeat']


def extract(source, destination):
    source=Path(source); destination=Path(destination)
    rgb=np.asarray(Image.open(source).convert('RGB'))
    if rgb.shape!=(1254,1254,3): raise ValueError('Reviewed source geometry required')
    # Connected neutral bright regions distinguish matte from dark armor/violet core.
    neutral=(rgb.max(2).astype(int)-rgb.min(2).astype(int)<20)&(rgb.min(2)>165)
    violet=(rgb[:,:,2].astype(int)-rgb[:,:,1].astype(int)>30)&(rgb[:,:,2]>130)
    visited=np.zeros(neutral.shape,dtype=bool); remove=np.zeros_like(visited)
    for y,x in zip(*np.where(neutral)):
        if visited[y,x]: continue
        q=deque([(int(y),int(x))]); visited[y,x]=True; component=[]
        while q:
            yy,xx=q.popleft(); component.append((yy,xx))
            for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
                ny,nx=yy+dy,xx+dx
                if 0<=ny<1254 and 0<=nx<1254 and neutral[ny,nx] and not visited[ny,nx]:
                    visited[ny,nx]=True;q.append((ny,nx))
        ys,xs=zip(*component)
        near_core=violet[max(0,min(ys)-8):min(1254,max(ys)+9),max(0,min(xs)-8):min(1254,max(xs)+9)].sum()>10
        if len(component)>=1000 or (len(component)>=24 and not near_core):
            for yy,xx in component: remove[yy,xx]=True
    alpha=Image.fromarray(np.where(remove,0,255).astype('uint8'))
    # One-pixel matte decontamination, then subpixel edge smoothing; no RGB repaint.
    alpha=alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(.35))
    rgba=Image.fromarray(rgb).convert('RGBA');rgba.putalpha(alpha)
    out=Image.new('RGBA',(1302,1380),(0,0,0,0));regions={}
    source_rows=[(0,435),(435,835),(835,1254)]
    for i,state in enumerate(STATES):
        x=i%2*627;y,bottom=source_rows[i//2]
        frame=rgba.crop((x,y,x+627,bottom))
        ox,oy=i%2*651,i//2*460
        out.paste(frame,(ox+12,oy+448-frame.height))
        regions[state]=[ox,oy,651,460]
    destination.parent.mkdir(parents=True,exist_ok=True)
    if destination.exists(): raise ValueError('Fresh output path required')
    out.save(destination)
    a=np.asarray(out)[:,:,3]
    receipt={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
      'output_sha256':hashlib.sha256(destination.read_bytes()).hexdigest(),'size':list(out.size),
      'mode':out.mode,'transparent_pixels':int((a==0).sum()),'opaque_pixels':int((a==255).sum()),
      'partial_alpha_pixels':int(((a>0)&(a<255)).sum()),'regions':regions,'pivot_per_cell':[325,448],
      'method':'neutral-bright connected matte >=24px with violet-neighborhood highlight protection below1000px; minfilter3, blur0.35; original RGB preserved; reviewed unequal source rows to fixed460px padded cells',
      'approval':'USER_APPROVED_BACKGROUND_ONLY_LOCAL_EXCEPTION','visual_review':'REQUIRED'}
    destination.with_suffix('.extraction.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(receipt))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('source');p.add_argument('destination');a=p.parse_args();extract(a.source,a.destination)
