// Mechanical chroma extraction of model-created pixels; no authored drawing.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const dir=__dirname,suffix=process.argv[2]==='v2'?'-v2':'',source=path.join(dir,'source-chroma'+suffix+'.png');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
(async()=>{
 const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 for(let i=0;i<data.length;i+=4){
  const r=data[i],g=data[i+1],b=data[i+2],excess=g-Math.max(r,b);
  const a=Math.max(0,Math.min(255,Math.round(255*(1-(excess-12)/75))));
  data[i+3]=a;
  if(a===0)data[i]=data[i+1]=data[i+2]=0;
  else if(a<255)data[i+1]=Math.min(g,Math.max(r,b));
 }
 const N=448,frames=[],layers=[],records=[];
 for(let f=0;f<9;f++){
  const x=Math.round(f%3*info.width/3),y=Math.round(Math.floor(f/3)*info.height/3);
  const w=Math.round((f%3+1)*info.width/3)-x,h=Math.round((Math.floor(f/3)+1)*info.height/3)-y;
  const dx=Math.floor((N-w)/2),dy=N-h-14,raw=Buffer.alloc(N*N*4);
  let sideContact=0;
  for(let yy=0;yy<h;yy++)for(let xx=0;xx<w;xx++){
   const from=((y+yy)*info.width+x+xx)*4;
   if(data[from+3]>16&&(xx===0||xx===w-1))sideContact++;
   data.copy(raw,((yy+dy)*N+xx+dx)*4,from,from+4);
  }
  const png=await sharp(raw,{raw:{width:N,height:N,channels:4}}).png().toBuffer();
  layers.push({input:png,left:f%3*N,top:Math.floor(f/3)*N});frames.push(raw);
  records.push({category:['ATK','DEF','SUP'][Math.floor(f/3)],phase:['entrance','impact','exit'][f%3],region:[f%3*N,Math.floor(f/3)*N,N,N],source:[x,y,w,h],translation:[dx,dy],source_side_contact_pixels:sideContact});
 }
 const atlas=await sharp({create:{width:N*3,height:N*3,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toBuffer();
 fs.writeFileSync(path.join(dir,'performer-atlas'+suffix+'.png'),atlas);
 let transparent=0,partial=0;
 for(const frame of frames)for(let i=3;i<frame.length;i+=4){if(frame[i]===0)transparent++;else if(frame[i]<255)partial++;}
 const manifest={state:'GENERATED_CANDIDATE_NOT_RUNTIME_APPROVED',source_generation:suffix?'exec-315aa8b7-eac4-4ba2-a048-b4775470ef97':'exec-5e98adbd-dae7-4449-a386-c3f7542c7c1a',source_sha256:hash(fs.readFileSync(source)),atlas_sha256:hash(atlas),atlas_size:[N*3,N*3],alpha:{transparent,partial},frames:records,consumer:'res://scenes/replanned_r3/main.tscn::Combat/CutIn/Actor',runtime_bound:false,review_limit:'Three key poses per category are not smooth full motion. Source cell side contacts need visual review; padding does not restore clipped art. Existing portrait remains runtime fallback.'};
 fs.writeFileSync(path.join(dir,'manifest'+suffix+'.json'),JSON.stringify(manifest,null,2));
 console.log(JSON.stringify(manifest));
})().catch(e=>{console.error(e);process.exit(1)});
