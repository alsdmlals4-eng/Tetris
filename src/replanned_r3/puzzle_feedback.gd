## Bounded, screen-owned presentation. No gameplay writes or saved-state fields.
extends Control
const SkillFeedback=preload("res://src/replanned_r3/skill_feedback.gd")
var info=SkillFeedback.new()
var screen
var banner:Label
var detail:Label
var bursts:Array=[]
var motions:Array=[]
var notes:Array=[]
var voices:Array=[]
var sound_count=0
var muted=false
var remaining=0.0
var elapsed=0.0
var before:Dictionary={}
var seen:Dictionary={}
var bound_session
var board_key=""
var _voice=0
var _sequence=0
var _line_history=0
var _streams={}
var _banner_y=172.0

func attach(owner_screen)->void:
    screen=owner_screen
    name="Feedback"
    size=Vector2(622,620)
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    clip_contents=true
    screen.get_node("Puzzle").add_child(self)
    banner=screen._label(self,"Combo",Rect2(172,96,278,58),"",29)
    banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    banner.add_theme_color_override("font_outline_color",Color("101522"))
    banner.add_theme_constant_override("outline_size",8)
    detail=screen._label(self,"Reward",Rect2(166,154,292,62),"",16)
    detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    detail.add_theme_color_override("font_outline_color",Color("101522"))
    detail.add_theme_constant_override("outline_size",6)
    for cue in ["line","chain","confirm"]:_streams[cue]=load("res://assets/replanned_r2/audio/"+cue+".ogg")
    for i in 3:
        var voice=AudioStreamPlayer.new()
        add_child(voice)
        voice.volume_db=-22
        voices.append(voice)
    sync()

func sync()->void:
    var s=screen.session
    var key=String(s.mode)+":"+String(s.resource_mode)
    if bound_session!=s:
        reset()
        bound_session=s
        _line_history=s.line.history.size() if s.line.get("history") is Array else 0
    if key!=board_key or screen.preparing:
        reset_visuals()
        board_key=key
    var is_muted=screen.assist_ui!=null and screen.assist_ui.sound.volume_db<-70
    if is_muted!=muted:
        muted=is_muted
        if muted:stop_sound()
    if s.combat.paused:stop_sound()

func reset_visuals()->void:
    bursts.clear()
    motions.clear()
    remaining=0.0
    if banner!=null:banner.text="";detail.text=""
    stop_sound()
    queue_redraw()

func reset()->void:
    reset_visuals()
    seen.clear()
    before.clear()
    sound_count=0
    _sequence=0

func stop_sound()->void:
    notes.clear()
    for voice in voices:voice.stop()

func capture_before()->void:
    sync()
    before={}
    var s=screen.session
    if s.resource_mode=="SWAP":
        # Target selection excludes reserved matches; presentation must still see them.
        for y in 8:
            for x in 8:
                var cell={"cell_id":s.swap.ids[y][x],"x":x,"y":y,"kind":s.swap.cells[y][x]}
                before[cell.cell_id]={"board":"LINE","cell":cell}
    else:
        for cell in s.resource_candidates():before[cell.cell_id] = {"board":"LINE","cell":cell.duplicate(true)}
    for cell in s.chain.cells:before[cell.cell_id] = {"board":"CHAIN","cell":cell.duplicate(true)}

func point(board:String,cell:Dictionary)->Vector2:
    if board=="CHAIN":return Vector2(185,108)+Vector2(float(cell.x)+0.5,float(cell.y)+0.5)*42.0
    if screen.session.resource_mode=="SWAP":return Vector2(111,142)+Vector2(float(cell.x)+0.5,float(cell.y)+0.5)*50.0
    return Vector2(181,108)+Vector2(float(cell.x)+0.5,float(cell.y)-4.0+0.5)*25.0

func burst(board:String,cell:Dictionary,hostile:bool=false)->void:
    if board!=screen.session.mode:return
    if bursts.size()>=int(info.config.max_bursts):bursts.pop_front()
    var p=point(board,cell)
    if p.y<108 or p.y>610:return
    bursts.append({"at":p,"age":0.0,"hostile":hostile,"kind":String(cell.get("kind","A"))})

func celebrate(title:String,subtitle:String,strength:int,cue:String)->void:
    banner.text=title
    detail.text=subtitle
    remaining=float(info.config.banner_seconds)
    elapsed=0.0
    place_labels()
    banner.add_theme_color_override("font_color",Color("ffe7a2") if strength>1 else Color("a9ecff"))
    notes.clear()
    if not muted:
        for i in (int(info.config.max_notes) if strength>1 else 1):
            notes.append({"delay":float(i)*float(info.config.fanfare_note_seconds),"pitch":minf(1.6,1.0+0.07*maxi(0,strength-1)+i*0.12),"cue":cue})
        advance(0.0)

func observe(events:Array,command:String="",args:Dictionary={},result:Dictionary={})->void:
    sync()
    var s=screen.session
    for event in events:
        if not event.get("success",false):continue
        var type=String(event.get("type",event.get("effect","")))
        var identity=String(event.get("event_id",""))+":"+type
        if identity!=":" and not String(event.get("event_id","")).is_empty():
            if seen.has(identity):continue
            seen[identity]=true
            if seen.size()>256:seen.erase(seen.keys()[0])
        if event.get("origin")=="ENEMY_DESTROY":
            for id in event.get("removed_ids",[]):
                if before.has(id):burst(before[id].board,before[id].cell,true)
            continue
        if type=="CLEAR_CELLS" and event.get("cause")=="PLAYER_LOCK":
            for cell in event.cells:burst("CHAIN",cell)
            var wave=int(event.wave)
            var starter:String=s.starter_preview().get("starter","")
            var name=String(info.skill(starter).get("name","시동 확인"))
            celebrate("%d CHAIN!"%wave,"%d개 연결 · %s\n연쇄가 끝나면 스킬 1회"%[event.cells.size(),name],wave,"chain")
        elif type=="RESOURCE_SWAP_RESOLVED":
            for xy in event.cells:
                var cell={"x":xy[0],"y":xy[1],"kind":"A"}
                for item in before.values():
                    if item.board=="LINE" and int(item.cell.x)==int(xy[0]) and int(item.cell.y)==int(xy[1]):cell=item.cell;break
                burst("LINE",cell)
            celebrate("%d COMBO!"%int(event.wave),"%d칸 소거 · 자원 획득"%event.cells.size(),int(event.wave),"line")
    # LINE's existing history supplies exact T-spin/four/combo/B2B recognition.
    if s.line.get("history") is Array and s.line.history.size()>_line_history:
        _line_history=s.line.history.size()
        var last:Dictionary=s.supply_report().last
        if int(last.lines)>0:
            var title="T-SPIN!" if last.spin=="T_SPIN" else ("TETRIS!" if int(last.lines)==4 else "%d LINE CLEAR!"%int(last.lines))
            if int(last.combo)>1:title="%d COMBO!"%int(last.combo)
            var special=("T-SPIN · " if last.spin=="T_SPIN" else ("TETRIS · " if int(last.lines)==4 else ""))+("B2B · " if last.b2b else "")
            celebrate(title,"%s%d줄 · 기술 보급 +%d"%[special,last.lines,last.units],maxi(int(last.combo),2 if int(last.units)>0 else 1),"line")
            var after={}
            for cell in s.resource_candidates():after[cell.cell_id]=true
            for id in before:
                if before[id].board=="LINE" and not after.has(id):burst("LINE",before[id].cell)
    if command=="resource_swap" and (result.success or result.get("reason")=="NO_MATCH"):
        for item in before.values():
            var xy=Vector2i(item.cell.x,item.cell.y)
            if item.board=="LINE" and xy in [args.a,args.b]:
                var target=args.b if xy==args.a else args.a
                motions.append({"from":point("LINE",item.cell),"to":point("LINE",{"x":target.x,"y":target.y}),"kind":item.cell.kind,"age":0.0,"return":not result.success,"duration":0.24})
        if not result.success:
            banner.text="연결 없음"
            detail.text="인접한 다른 문양을 바꿔보세요"
            remaining=0.7
            elapsed=0.0
            place_labels()
    if command=="bonus_apply" and result.get("success",false):
        var history=s.bonus_history[-1]
        if before.has(args.get("cell_id","")):burst("CHAIN",before[args.cell_id].cell)
        celebrate("보정 완료","보너스 -%d · 남은 마나 %d"%[history.cost,result.bonus_remaining],1,"confirm")
    # Stable IDs locate falling/swap tiles without altering the board's truth.
    if command!="resource_swap":
        var cells=s.chain.cells if s.mode=="CHAIN" else s.resource_candidates()
        for cell in cells:
            if not before.has(cell.cell_id):continue
            var old=before[cell.cell_id]
            if old.board!=s.mode or (old.cell.x==cell.x and old.cell.y==cell.y):continue
            motions.append({"from":point(s.mode,old.cell),"to":point(s.mode,cell),"kind":cell.kind,"age":0.0,"return":false,"duration":0.18})
    if motions.size()>64:motions=motions.slice(-64)
    queue_redraw()

func advance(delta:float)->void:
    sync()
    if screen.session.combat.paused or screen.preparing:return
    remaining=maxf(0.0,remaining-delta)
    elapsed+=delta
    banner.visible=remaining>0
    detail.visible=remaining>0
    banner.position.y=_banner_y if screen.reduced_motion else _banner_y-minf(elapsed,0.2)*20.0
    banner.scale=Vector2.ONE if screen.reduced_motion else Vector2.ONE*(1.0+maxf(0.0,0.12-elapsed*0.5))
    for b in bursts:b.age+=delta
    bursts=bursts.filter(func(b):return b.age<float(info.config.burst_seconds))
    for m in motions:m.age+=delta
    motions=motions.filter(func(m):return m.age<m.duration)
    var pending=[]
    for note in notes:
        note.delay-=delta
        if note.delay<=0 and not muted:
            var voice=voices[_voice]
            _voice=(_voice+1)%voices.size()
            voice.stream=_streams[note.cue]
            voice.pitch_scale=note.pitch
            voice.play()
            sound_count+=1
        elif note.delay>0:pending.append(note)
    notes=pending
    queue_redraw()

func place_labels()->void:
    var swap=screen.session.mode=="LINE" and screen.session.resource_mode=="SWAP"
    _banner_y=96.0 if swap else 172.0
    banner.position=Vector2(158,96) if swap else Vector2(445,172)
    banner.size=Vector2(306,36) if swap else Vector2(165,92)
    banner.add_theme_font_size_override("font_size",26)
    detail.position=Vector2(174,548) if swap else Vector2(449,276)
    detail.size=Vector2(352,64) if swap else Vector2(158,170)

func _draw()->void:
    if screen==null:return
    if screen.session.mode=="CHAIN" and screen.session.chain.phase=="CLEAR_PENDING":
        for cell in screen.session.chain.cells:
            if cell.cell_id in screen.session.chain.reserved_clear_ids and cell.y>=0:
                draw_rect(Rect2(point("CHAIN",cell)-Vector2(20,20),Vector2(40,40)),Color("fff0a7"),false,2)
    for b in bursts:
        var t=clampf(float(b.age)/float(info.config.burst_seconds),0,1)
        var color=Color("9d74c7") if b.hostile else Color(info.skill(b.kind).get("color","f8d27b"))
        color.a=1.0-t
        if screen.reduced_motion:
            draw_rect(Rect2(b.at-Vector2(10,10),Vector2(20,20)),color,false,2)
            continue
        draw_arc(b.at,5.0+t*24,0,TAU,20,color,2,true)
        for ray in (4 if b.hostile else 6):
            var direction=Vector2.from_angle(float(ray)*TAU/6.0+0.3)
            var p=b.at+direction*(8+t*35)+Vector2(0,t*t*12)
            draw_line(p-direction*3,p+direction*3,color,2,true)
    if screen.reduced_motion:return
    for m in motions:
        var t=clampf(m.age/m.duration,0,1)
        var progress=sin(t*PI) if m["return"] else 1.0-pow(1.0-t,3)
        var p:Vector2=m.from.lerp(m.to,progress)
        var texture=screen.assets.tile(m.kind)
        if texture!=null:draw_texture_rect(texture,Rect2(p-Vector2(17,17),Vector2(34,34)),false,Color(1,1,1,1.0-t*0.7))
