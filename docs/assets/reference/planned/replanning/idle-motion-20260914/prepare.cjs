// Deterministic keying/packing of model-created pixels; no painted artwork.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root='C:/Users/user/Documents/GitHub/Ninza/Tetris';
const dir=path.join(root,'docs/assets/reference/planned/replanning/idle-motion-20260914');
const source='C:/Users/user/.codex/generated_images/01a04af3-ebbf-76e1-a16a-cc5f54b88a9e/exec-c61cf006-f7a3-46cd-b341-0c5360a52a23.png';
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
(async()=>{
 fs.mkdirSync(dir,{recursive:true});
 fs.copyFileSync(source,path.join(dir,'source-chroma.png'));
 const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 let clear=0,partial=0;
 for(let i=0;i<data.length;i+=4){
  const r=data[i],g=data[i+1],b=data[i+2],excess=g-Math.max(r,b);
  const alpha=Math.max(0,Math.min(255,Math.round(255*(1-(excess-12)/75))));
  data[i+3]=alpha;
  if(alpha===0){data[i]=data[i+1]=data[i+2]=0;clear++;}
  else if(alpha<255){data[i+1]=Math.min(g,Math.max(r,b));partial++;}
 }
 const images=[],rects=[],N=320,frames=[];
 for(let f=0;f<16;f++){
  const x=Math.round((f%4)*info.width/4),y=Math.round(Math.floor(f/4)*info.height/4);
  const w=Math.round((f%4+1)*info.width/4)-x,h=Math.round((Math.floor(f/4)+1)*info.height/4)-y;
  let minx=w,miny=h,maxx=-1,maxy=-1;
  for(let yy=0;yy<h;yy++)for(let xx=0;xx<w;xx++)if(data[((y+yy)*info.width+x+xx)*4+3]>16){minx=Math.min(minx,xx);maxx=Math.max(maxx,xx);miny=Math.min(miny,yy);maxy=Math.max(maxy,yy);}
  const dx=Math.round(N/2-(minx+maxx+1)/2),dy=300-maxy;
  const raw=Buffer.alloc(N*N*4);
  for(let yy=0;yy<h;yy++)for(let xx=0;xx<w;xx++){
   const tx=xx+dx,ty=yy+dy;if(tx<0||tx>=N||ty<0||ty>=N)continue;
   data.copy(raw,(ty*N+tx)*4,((y+yy)*info.width+x+xx)*4,((y+yy)*info.width+x+xx)*4+4);
  }
  const png=await sharp(raw,{raw:{width:N,height:N,channels:4}}).png().toBuffer();
  images.push({input:png,left:(f%4)*N,top:Math.floor(f/4)*N});frames.push(raw);
  rects.push({frame:f,source:[x,y,w,h],translation:[dx,dy],region:[(f%4)*N,Math.floor(f/4)*N,N,N],duration_ms:140});
 }
 await sharp({create:{width:N*4,height:N*4,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(images).png().toFile(path.join(dir,'idle-atlas.png'));
 await sharp(Buffer.concat(frames),{raw:{width:N,height:N*16,channels:4,pageHeight:N}}).gif({delay:Array(16).fill(140),loop:0,effort:7}).toFile(path.join(dir,'idle-preview.gif'));
 const manifest={state:'CANDIDATE_CONTINUITY_REVIEW_REQUIRED',source_generation:'exec-c61cf006-f7a3-46cd-b341-0c5360a52a23',source_sha256:hash(fs.readFileSync(source)),rejected_extraction:'exec-4128f387-9a5c-4caf-9824-c0b2de21bb0b: RGB baked checkerboard; zero alpha pixels',processing:'Green excess matte, edge despill, translation-only fixed bottom/center alignment; no redrawn foreground; no invented inbetween frames',transparent_pixels:clear,partial_pixels:partial,atlas_size:[1280,1280],frame_count:16,loop_ms:2240,pivot:[160,300],frames:rects,consumer_candidate:'res://scenes/replanned_r2/main.tscn::Battle/Combat/Stage/BodyClip/BossVisual idle only; not bound until continuity review',scope:'idle only; attack/hurt/defeat transition not complete',files:{}};
 for(const f of ['source-chroma.png','idle-atlas.png','idle-preview.gif'])manifest.files[f]=hash(fs.readFileSync(path.join(dir,f)));
 fs.writeFileSync(path.join(dir,'manifest.json'),JSON.stringify(manifest,null,2));console.log(JSON.stringify(manifest));
})().catch(e=>{console.error(e);process.exit(1)});
