## Bonus HUD translates selections to session commands; it owns no game economy.
extends RefCounted
const TierVfx=preload("res://src/replanned_r3/r3_tier_vfx.gd")
var selected_id=""
var s
var vfx
var last_action_key=""
var sound
var candidates:Dictionary={}
var shattered:Array=[]
var shatter_us:=0
var destruction_note=""

func reset_presentation()->void:
    selected_id=""
    last_action_key=""
    shattered=[]
    shatter_us=0
    destruction_note=""
    if sound!=null:sound.stop()

func attach(screen)->void:
    s=screen
    var left=s.get_node("Puzzle")
    s._button(left,"Bonus",Rect2(16,568,150,43),"보너스 보정",func():s.dispatch("bonus_cancel" if s.session.assist_requested and not s.session.assist_open else "bonus_open"))
    s._label(left,"Help",Rect2(16,132,158,405),"",16)
    var panel=s._panel(left,"BonusTools",Rect2(446,126,162,464))
    s._label(panel,"Title",Rect2(8,8,146,90),"고정 뿌요 선택\n문양 변경: 2\n좌우 보정: 1",16)
    var kinds=["A","D","H","T"]
    var names=["공격","방어","치유","시계"]
    for i in 4:
        var kind=kinds[i]
        s._button(panel,"Kind"+kind,Rect2(8+(i%2)*74,100+(i/2)*40,70,36),names[i],func():apply({"operation":"change","cell_id":selected_id,"kind":kind}))
    s._button(panel,"ShiftLeft",Rect2(8,184,70,36),"← 이동",func():apply({"operation":"shift","cell_id":selected_id,"dx":-1}))
    s._button(panel,"ShiftRight",Rect2(82,184,70,36),"이동 →",func():apply({"operation":"shift","cell_id":selected_id,"dx":1}))
    for i in 3:
        var operation=["heal","attack","armor"][i]
        s._button(panel,operation,Rect2(8,236+i*40,144,36),["회복 +5 / 2","공격 +5 / 2","방어 +5 / 2"][i],func():apply({"operation":operation}))
    s._button(panel,"Cancel",Rect2(8,366,144,36),"취소 · 무료",func():selected_id="";s.dispatch("bonus_cancel"))
    s._label(panel,"State",Rect2(8,409,146,50),"",14)
    for y in 12:
        for x in 6:
            var xy=Vector2i(x,y)
            var cell=left.get_node("ChainBoard/Cell_%d_%d"%[x,y])
            cell.mouse_filter=Control.MOUSE_FILTER_STOP
            cell.gui_input.connect(func(event):
                if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:select(xy))
    vfx=TierVfx.new()
    vfx.name="TierAccents"
    vfx.size=Vector2(606,240)
    vfx.mouse_filter=Control.MOUSE_FILTER_IGNORE
    s.get_node("Combat/CutIn").add_child(vfx)
    s.get_node("Combat/CutIn").move_child(vfx,0)
    sound=AudioStreamPlayer.new()
    sound.name="TierSound"
    sound.stream=load("res://assets/replanned_r2/audio/attack.ogg")
    sound.volume_db=-18
    s.add_child(sound)
    s._button(s.get_node("Combat/PauseMenu"),"Sound",Rect2(406,132,190,34),"효과음 켜짐",func():sound.volume_db=-80 if sound.volume_db>-70 else -18; s.get_node("Combat/PauseMenu/Sound").text="효과음 꺼짐" if sound.volume_db<-70 else "효과음 켜짐")
    var prep=s.get_node("Preparation")
    prep.get_node("Title").size.x=555
    prep.get_node("Title").add_theme_font_size_override("font_size",26)
    var selector=OptionButton.new()
    selector.name="Encounter"
    selector.position=Vector2(584,26)
    selector.size=Vector2(244,42)
    var profiles=["outer_breach","watchtower","foundry","rift_core"]
    for label in ["외곽 균열 · 파괴1","감시탑 · 파괴2","주조소 · 파괴3","균열의 핵 · 파괴4"]:selector.add_item(label)
    selector.select(3)
    selector.item_selected.connect(func(index):s.preferred_encounter=profiles[index])
    prep.add_child(selector)
    prep.get_node("Start").size.x=260
    prep.get_node("Continue").position.x=298
    prep.get_node("Continue").size.x=260
    s._button(prep,"Practice",Rect2(568,373,260,60),"2연쇄 짧은 연습",s.start_chain_practice)
    s._button(left,"ExitPractice",Rect2(16,568,150,43),"연습 종료",s.end_chain_practice)
    s.get_node("Combat/CutIn/Caption").position.x=450
    s.get_node("Combat/CutIn/Caption").size.x=146

func before_tick()->void:
    candidates={}
    for cell in s.session.resource_candidates():candidates[cell.cell_id]={"board":"LINE","cell":cell.duplicate(true)}
    for cell in s.session.chain.cells:candidates[cell.cell_id]={"board":"CHAIN","cell":cell.duplicate(true)}

func observe(events:Array,delta_us:int)->void:
    shatter_us=maxi(0,shatter_us-delta_us)
    for event in events:
        if event.get("origin")!="ENEMY_DESTROY":continue
        shattered=[]
        for id in event.get("removed_ids",[]):
            if candidates.has(id):shattered.append(candidates[id])
        if not shattered.is_empty():
            shatter_us=650000
            destruction_note="%s 블록 %d개 파괴"%[event.target_board,shattered.size()]
        elif event.get("target_ids",[]).is_empty() and s.session._destruction_count()>0:
            destruction_note="파괴 가능한 고정 블록 없음"

func select(xy:Vector2i)->void:
    if not s.session.assist_open or s.session.combat.paused:return
    selected_id=""
    for cell in s.session.chain.cells:
        if Vector2i(cell.x,cell.y)==xy:selected_id=cell.cell_id
    s.refresh()

func apply(args:Dictionary)->void:
    var result=s.dispatch("bonus_apply",args)
    if result.success:selected_id=""
    s.refresh()

func refresh()->void:
    var session=s.session
    var profile_index=["outer_breach","watchtower","foundry","rift_core"].find(s.preferred_encounter)
    if profile_index>=0:s.get_node("Preparation/Encounter").select(profile_index)
    var chain_mode=session.mode=="CHAIN"
    var balance=session.bonus_balance()
    s.get_node("Puzzle/Supply").text="보관 %d / 10쌍 · 보너스 마나 %d\n자원 10단위 → 3쌍 · 초과 1쌍 → 보너스 1"%[session.supply.pairs,balance]
    s.get_node("Puzzle/Bonus").disabled=balance<1 or session.combat.paused or session.combat.outcome!="RUNNING" or session.practice_mode
    s.get_node("Puzzle/Bonus").visible=not session.practice_mode
    s.get_node("Puzzle/Bonus").text="보정 예약 취소" if session.assist_requested and not session.assist_open else "보너스 보정 (%d)"%balance
    s.get_node("Puzzle/BonusTools").visible=session.assist_open
    s.get_node("Puzzle/BonusTools/State").text="잔여 %d · %s"%[balance,"대상 선택됨" if not selected_id.is_empty() else "보드 칸 클릭"]
    if not s._message.is_empty() and session.assist_open:
        var reasons={"NO_CHANGE":"같은 문양입니다","INVALID_CELL":"고정 뿌요 선택","OUTSIDE_BOARD":"보드 밖 이동 불가","INSUFFICIENT_BONUS":"마나가 부족합니다","HP_FULL":"체력이 가득합니다"}
        s.get_node("Puzzle/BonusTools/State").text=reasons.get(s._message,s._message)
    s.get_node("Puzzle/Help").visible=chain_mode
    s.get_node("Puzzle/Help").text="같은 문양 4개 연결\n\n첫 소거 = 스킬 종류\n연쇄 수 = 스킬 티어\n끝나면 한 번 발동\n\nTab: 자원 보드\nSpace: 즉시 낙하\n\n"+("보정 선택 중\n양쪽 시간 정지" if session.assist_open else ("현재 쌍을 놓으면\n보정 창이 열립니다" if session.assist_requested else "보관 10쌍을 채운 뒤\n초과 보상을 모아\n배치를 고쳐보세요"))
    if session.assist_open:
        s.get_node("Combat/SharedTimer").text="보정 중 · 양쪽 정지  %.1f초"%(session.combat.eta_us/1000000.0)
        for cell in session.chain.cells:
            if cell.cell_id==selected_id and cell.y>=0:s._chain_tiles[int(cell.y)*6+int(cell.x)].marker.text="◎"
        for control in ["Switch","Left","Right","Rotate","Drop","Hold"]:s.get_node("Puzzle/"+control).disabled=true
    var preview=session.starter_preview()
    if chain_mode and not session.assist_open and not preview.locked:
        s.get_node("Puzzle/Queue").text+=" · 착지 연결 %d/4"%preview.get("matched_count",0)
    s.get_node("Puzzle/ExitPractice").visible=session.practice_mode
    if session.practice_mode:
        s.get_node("Puzzle/Help").text="2연쇄 연습\n\n① Space로 내려놓기\n② 공격 문양 소거\n③ 위의 치유가 낙하\n④ 치유 문양 소거\n⑤ 공격 T2 한 번!\n\n첫 문양은 공격이라\n치유로 안 바뀌어요.\n연습은 저장 안 됨"
        s.get_node("Combat/SharedTimer").text="연습 · 적 공격 없음"
    if shatter_us>0:
        for item in shattered:
            if item.board!=session.mode:continue
            var cell=item.cell
            var width=6 if session.mode=="CHAIN" else (8 if session.resource_mode=="SWAP" else 10)
            var y=int(cell.y)-(4 if session.mode=="LINE" and session.resource_mode=="LINE" else 0)
            var tiles=s._chain_tiles if session.mode=="CHAIN" else (s._swap_tiles if session.resource_mode=="SWAP" else s._line_tiles)
            if y>=0 and y*width+int(cell.x)<tiles.size():tiles[y*width+int(cell.x)].marker.text="✦"
        s.get_node("Combat/Next").text=destruction_note+" · "+s.get_node("Combat/Next").text
    var view=session.action_view(s.reduced_motion)
    vfx.present(view,s.reduced_motion)
    if not view.is_empty():
        var scale=float(view.effect_scale)
        var effect=s.get_node("Combat/CutIn/Effect")
        effect.size=Vector2(78,78)*scale
        effect.position=Vector2(335,117)-effect.size/2
        var key=(str(session.action.bundle.wave_ids[-1]) if view.owner=="PLAYER" else str(session.combat.action_index))+view.owner
        if view.phase=="impact" and key!=last_action_key:
            last_action_key=key
            sound.pitch_scale=0.85+0.055*int(view.rings)
            if sound.volume_db>-70:
                sound.volume_db=-22+int(view.rings)
                sound.play()
    sound.stream_paused=session.combat.paused
    var enemy_texture=s.assets.enemy_texture(session._profile,"idle")
    s.get_node("Combat/Stage/Enemy").texture=enemy_texture
