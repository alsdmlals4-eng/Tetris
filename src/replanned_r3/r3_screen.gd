extends Control
const Session=preload("res://src/replanned_r3/r3_session.gd")
const FinisherSession=preload("res://src/replanned_r3/r3_finisher_session.gd")
const AssistSession=preload("res://src/replanned_r3/r3_assist_session.gd")
const MasterySession=preload("res://src/replanned_r3/mastery_session.gd")
const MasteryUI=preload("res://src/replanned_r3/mastery_ui.gd")
const AssistUI=preload("res://src/replanned_r3/r3_assist_ui.gd")
const Finisher=preload("res://src/replanned_r3/r3_finisher.gd")
const Assets=preload("res://src/replanned_r2/r2_assets.gd")
const Presentation=preload("res://src/replanned_r3/r3_cast_presentation.gd")
const Performer=preload("res://src/replanned_r3/r3_performer.gd")
const Disk=preload("res://src/replanned_r3/r3_save.gd")
@export var show_preparation:bool=false
@export var use_finishers:bool=false
@export var use_assists:bool=false
@export var use_mastery:bool=false
var preparing:=false
var preference_path="user://resource_choice/preference.cfg"
var preferred_resource="LINE"
var preferred_encounter="rift_core"
var assist_ui
var mastery_ui
var feedback
var skill_feedback=preload("res://src/replanned_r3/skill_feedback.gd").new()
var _swap_tiles:Array=[]
var _swap_selected=Vector2i(-1,-1)
var _swap_cursor=Vector2i.ZERO
var session=Session.new()
var assets
var performer
var disk
var presentation=Presentation.new()
var reduced_motion=false
var _line_tiles:Array=[]
var _chain_tiles:Array=[]
var _message=""
var _fraction_us=0.0
var _pose_us=0
var _ledger_count=0
var _rules:Dictionary
const GOLD=Color("#dfbf7d")
const INK=Color("#0c1420")

func _ready()->void:
    if use_finishers:session=(MasterySession.new() if use_mastery else AssistSession.new()) if use_assists else FinisherSession.new()
    if get_tree().current_scene==self:
        get_window().content_scale_size=Vector2i(1280,720)
        get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
        get_window().size=Vector2i(1280,720)
        get_window().min_size=Vector2i(960,540)
    get_window().focus_exited.connect(focus_lost)
    assets=Assets.new()
    performer=Performer.new()
    if disk==null:
        if use_mastery:disk=Disk.new("user://mastery_patterns/save.json","user://mastery_patterns/options.json")
        elif use_assists:disk=Disk.new("user://bonus_assist/save.json","user://bonus_assist/options.json")
        elif use_finishers:disk=Disk.new("user://starter_finisher/save.json","user://starter_finisher/options.json")
        else:disk=Disk.new("user://resource_choice/save.json","user://resource_choice/options.json") if show_preparation else Disk.new()
    _rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/replanned_r3/rules.json"))
    var left=_panel(self,"Puzzle",Rect2(12,12,622,696))
    var right=_panel(self,"Combat",Rect2(646,12,622,696))
    _label(left,"Heading",Rect2(16,8,590,38),"LINE · 자원 준비",24)
    _label(left,"Supply",Rect2(16,46,590,50),"",18)
    _make_board(left,"LineBoard",Vector2(181,108),10,20,25,_line_tiles)
    _make_board(left,"ChainBoard",Vector2(185,108),6,12,42,_chain_tiles)
    _make_board(left,"SwapBoard",Vector2(111,142),8,8,50,_swap_tiles)
    for y in 8:
        for x in 8:
            var xy=Vector2i(x,y)
            var slot=left.get_node("SwapBoard/Cell_%d_%d"%[x,y])
            slot.mouse_filter=Control.MOUSE_FILTER_STOP
            slot.gui_input.connect(func(event):
                if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:select_swap_cell(xy))
    _label(left,"Queue",Rect2(16,625,590,26),"",16)
    _button(left,"Switch",Rect2(16,656,112,32),"보드 전환",func():dispatch("switch"))
    _button(left,"Left",Rect2(136,656,55,32),"←",func():dispatch("move",{"dx":-1}))
    _button(left,"Right",Rect2(199,656,55,32),"→",func():dispatch("move",{"dx":1}))
    _button(left,"Rotate",Rect2(262,656,88,32),"회전",func():dispatch("rotate",{"direction":1}))
    _button(left,"Drop",Rect2(358,656,88,32),"낙하",func():dispatch("hard_drop"))
    _button(left,"Hold",Rect2(454,656,72,32),"HOLD",func():dispatch("hold"))
    _button(left,"Pause",Rect2(534,656,72,32),"정지",func():dispatch("resume" if session.combat.paused else "pause"))
    var stage=_panel(right,"Stage",Rect2(8,8,606,275))
    stage.clip_contents=true
    var env=assets.texture("R1-ENV","full")
    if env!=null:_image(stage,"Environment",Rect2(0,0,606,275),env)
    _image(stage,"Enemy",Rect2(30,40,546,260),assets.enemy_texture("","idle"))
    _label(stage,"HP",Rect2(18,6,575,44),"",23)
    _label(right,"SharedTimer",Rect2(14,290,590,42),"",29)
    _label(right,"Current",Rect2(16,336,590,42),"",17)
    _label(right,"Next",Rect2(16,381,590,30),"",17)
    var player=_panel(right,"Player",Rect2(8,420,606,83))
    _image(player,"Portrait",Rect2(0,-5,94,94),assets.texture("R1-PORTRAIT","neutral"))
    _label(player,"Resources",Rect2(98,10,495,68),"",19)
    var skills=_panel(right,"Skills",Rect2(8,511,606,177))
    var index=0
    for category in ([] if use_finishers else ["ATK","DEF","SUP"]):
        var selected=category
        _button(skills,category,Rect2(10+index*198,8,190,33),{"ATK":"공격 ATK","DEF":"방어 DEF","SUP":"지원 SUP"}[category],func():dispatch("category",{"category":selected}))
        index+=1
    if use_finishers:_label(skills,"Starter",Rect2(14,8,580,33),"시동 문양 → 연쇄 완성 → 스킬 1회",21)
    _label(skills,"Stage",Rect2(14,47,580,26),"",18)
    _image(skills,"Icon",Rect2(14,82,76,76),assets.texture("R1-ICONS","strike"))
    _label(skills,"Description",Rect2(101,80,490,85),"",17)
    var cut=_panel(right,"CutIn",Rect2(8,40,606,240))
    cut.mouse_filter=Control.MOUSE_FILTER_IGNORE
    cut.clip_contents=true
    (cut.get_theme_stylebox("panel") as StyleBoxFlat).bg_color=Color(0.04,0.07,0.12,0.82)
    _image(cut,"Actor",Rect2(0,-30,310,300),assets.texture("R1-PORTRAIT","neutral"))
    _image(cut,"Effect",Rect2(308,70,90,90),assets.texture("R1-ICONS","strike"))
    _label(cut,"Caption",Rect2(413,65,183,100),"",21)
    cut.visible=false
    var pause_menu=_panel(right,"PauseMenu",Rect2(8,511,606,177))
    _label(pause_menu,"Title",Rect2(14,8,580,30),"일시정지 · 전투와 연출이 멈췄습니다",21)
    _button(pause_menu,"Save",Rect2(10,48,190,36),"현재 진행 저장",save_checkpoint)
    _button(pause_menu,"Load",Rect2(208,48,190,36),"저장 기록 불러오기",restore_checkpoint)
    _button(pause_menu,"Motion",Rect2(406,48,190,36),"동작 줄이기",func():reduced_motion=not reduced_motion;refresh())
    _label(pause_menu,"Status",Rect2(14,96,580,70),"",17)
    _button(right,"ReturnToPreparation",Rect2(18,635,580,52),"전투 종료 · 자원 퍼즐 다시 선택",return_to_preparation)
    if show_preparation:
        var preference=ConfigFile.new()
        if preference.load(preference_path)==OK:
            var saved=preference.get_value("puzzle","resource","LINE")
            if saved in ["LINE","SWAP"]:preferred_resource=saved
        var prepare=_panel(self,"Preparation",Rect2(212,125,856,470))
        _label(prepare,"Title",Rect2(28,22,800,54),"전투 준비 · 자원 퍼즐 선택",30)
        _label(prepare,"Rules",Rect2(28,85,800,104),"자원 확보: 테트리스 또는 타일 교체\n스킬 사용: 뿌요형 낙하 연쇄로 고정\n전투 중에는 선택한 자원 보드 ↔ 뿌요 보드만 전환합니다.",22)
        _button(prepare,"Line",Rect2(28,213,390,64),"테트리스 · 쌓아서 한 번에",func():preferred_resource="LINE";refresh())
        _button(prepare,"Swap",Rect2(438,213,390,64),"타일 교체 · 문양을 골라 소거",func():preferred_resource="SWAP";refresh())
        _label(prepare,"Balance",Rect2(28,291,800,63),"교체: 같은 문양 2칸 → 자원 1단위 (잔여 누적)\n자원 10단위 → 3쌍 보급 · 비교용 수치 / 사람 밸런스 검증 전",18)
        _button(prepare,"Start",Rect2(28,373,390,60),"선택한 퍼즐로 전투 시작",func():start_resource_battle(preferred_resource))
        _button(prepare,"Continue",Rect2(438,373,390,60),"저장한 전투 이어하기",restore_checkpoint)
        _label(prepare,"Status",Rect2(28,440,800,26),"",14)
        preparing=true
        session.command("pause")
    if use_assists:
        assist_ui=AssistUI.new()
        assist_ui.attach(self)
    if use_mastery:
        mastery_ui=MasteryUI.new()
        mastery_ui.attach(self)
        feedback=preload("res://src/replanned_r3/puzzle_feedback.gd").new()
        feedback.attach(self)
    refresh()

func _panel(parent:Node,node_name:String,rect:Rect2)->Panel:
    var panel=Panel.new()
    panel.name=node_name
    panel.position=rect.position
    panel.size=rect.size
    var style=StyleBoxFlat.new()
    style.bg_color=INK
    style.border_color=Color("#736340")
    style.set_border_width_all(1)
    panel.add_theme_stylebox_override("panel",style)
    parent.add_child(panel)
    return panel

func _label(parent:Node,node_name:String,rect:Rect2,text:String,font_size:int)->Label:
    var label=Label.new()
    label.name=node_name
    label.position=rect.position
    label.size=rect.size
    label.text=text
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",GOLD)
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label

func _image(parent:Node,node_name:String,rect:Rect2,texture:Texture2D)->TextureRect:
    var image=TextureRect.new()
    image.name=node_name
    image.position=rect.position
    image.size=rect.size
    image.texture=texture
    image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    image.mouse_filter=Control.MOUSE_FILTER_IGNORE
    parent.add_child(image)
    return image

func _button(parent:Node,node_name:String,rect:Rect2,text:String,callback:Callable)->void:
    var button=Button.new()
    button.name=node_name
    button.position=rect.position
    button.size=rect.size
    button.text=text
    button.pressed.connect(callback)
    parent.add_child(button)

func _make_board(parent:Node,node_name:String,origin:Vector2,width:int,height:int,cell:int,tiles:Array)->void:
    var board=_panel(parent,node_name,Rect2(origin,Vector2(width*cell,height*cell)))
    for y in height:
        for x in width:
            var slot=_panel(board,"Cell_%d_%d"%[x,y],Rect2(x*cell,y*cell,cell,cell))
            var art=_image(slot,"Tile",Rect2(1,1,cell-2,cell-2),null)
            var marker=_label(slot,"Marker",Rect2(0,0,cell,cell),"",18)
            marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
            tiles.append({"art":art,"marker":marker})

func dispatch(action:String,args:Dictionary={})->Dictionary:
    if preparing:return {"success":false,"reason":"PREPARATION"}
    if feedback!=null:feedback.capture_before()
    var result:Dictionary=session.command(action,args)
    if feedback!=null:feedback.observe(result.get("events",[]),action,args,result)
    _message=String(result.get("reason",""))
    refresh()
    return result

func focus_lost()->void:
    if session.mode=="CHAIN":session.command("soft_drop",{"enabled":false})
    session.command("pause")
    _message="창을 벗어나 일시정지 · 정지 버튼 또는 Esc로 재개"
    refresh()

func _process(delta:float)->void:
    if preparing:return
    var us=0
    if not session.combat.paused:
        if feedback!=null:
            feedback.advance(delta)
            feedback.capture_before()
        _fraction_us+=delta*1000000.0
        us=int(_fraction_us)
        _fraction_us-=us
        if use_assists and assist_ui!=null:assist_ui.before_tick()
        var events=session.tick(us)
        if feedback!=null:feedback.observe(events)
        if use_assists and assist_ui!=null:assist_ui.observe(events,us)
        _pose_us+=us
    presentation.tick(us,session.combat.paused)
    refresh()

func _input(event:InputEvent)->void:
    if preparing:return
    if event is InputEventKey and session.resource_mode=="SWAP" and session.mode=="LINE" and not session.combat.paused:
        var directions={KEY_LEFT:Vector2i.LEFT,KEY_A:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT,KEY_D:Vector2i.RIGHT,KEY_UP:Vector2i.UP,KEY_W:Vector2i.UP,KEY_DOWN:Vector2i.DOWN,KEY_S:Vector2i.DOWN}
        if directions.has(event.keycode) or event.keycode in [KEY_ENTER,KEY_SPACE]:
            get_viewport().set_input_as_handled()
            if event.pressed and not event.echo:
                if directions.has(event.keycode):
                    _swap_cursor=(_swap_cursor+directions[event.keycode]).clamp(Vector2i.ZERO,Vector2i(7,7))
                    refresh()
                else:select_swap_cell(_swap_cursor)
            return
    # Space belongs to battle, even when a clicked Button retains GUI focus.
    # Consume release/echo too; paused Space must not become ui_accept/resume.
    if event is InputEventKey and event.keycode==KEY_SPACE:
        get_viewport().set_input_as_handled()
        if event.pressed and not event.echo and not session.combat.paused:
            dispatch("hard_drop")
    elif event is InputEventKey and event.keycode==KEY_TAB and not session.combat.paused:
        get_viewport().set_input_as_handled()
        if event.pressed and not event.echo:dispatch("switch")

func _unhandled_key_input(event:InputEvent)->void:
    if preparing:return
    if not event is InputEventKey:return
    if event.keycode in [KEY_DOWN,KEY_S] and not event.pressed:
        if session.mode=="CHAIN":dispatch("soft_drop",{"enabled":false})
        return
    if not event.pressed or event.echo:return
    match event.keycode:
        KEY_LEFT,KEY_A:dispatch("move",{"dx":-1})
        KEY_RIGHT,KEY_D:dispatch("move",{"dx":1})
        KEY_UP,KEY_X:dispatch("rotate",{"direction":1})
        KEY_Z:dispatch("rotate",{"direction":-1})
        KEY_DOWN,KEY_S:dispatch("soft_drop",{"enabled":true})
        KEY_C,KEY_H:dispatch("hold")
        KEY_ESCAPE:dispatch("resume" if session.combat.paused else "pause")
        _:return
    get_viewport().set_input_as_handled()

func refresh()->void:
    if not is_node_ready() or assets==null:return
    var combat=session.combat
    var exhausted=session.mode=="CHAIN" and session.supply.pairs==0 and session.chain.active_pair.is_empty() and not session.chain.is_resolving()
    $Puzzle/Heading.text="LINE · 자원 준비" if session.mode=="LINE" else "CHAIN · 낙하 연결 / 연쇄 자동 스킬"
    $Puzzle/Supply.text="보급 %d / 12쌍 · LINE 한 줄 → 3쌍\n%s"%[session.supply.pairs,"보급 소진 · LINE에서 줄을 지워 충전" if session.mode=="CHAIN" and session.supply.pairs==0 and session.chain.active_pair.is_empty() else "공격 A · 방어 D · 치유 H · 시간 T"]
    $Puzzle/LineBoard.visible=session.mode=="LINE"
    $Puzzle/ChainBoard.visible=session.mode=="CHAIN"
    $Puzzle/SwapBoard.visible=session.mode=="LINE" and session.resource_mode=="SWAP"
    if session.resource_mode=="SWAP":$Puzzle/LineBoard.visible=false
    $Puzzle/Hold.disabled=session.mode=="CHAIN"
    $Puzzle/Switch.text="LINE 보급 →" if exhausted else "보드 전환"
    $Puzzle/Switch.modulate=Color("#ffe09a") if exhausted else Color.WHITE
    for control in ["Left","Right","Rotate","Drop"]:
        get_node("Puzzle/"+control).disabled=exhausted
    if exhausted:
        $Puzzle/Supply.text="낙하쌍 0 · LINE 한 줄로 3쌍 보급\n하단 LINE 보급 → 버튼 / Tab · 적 타이머는 계속 진행"
    $Puzzle/Pause.text="재개" if combat.paused else "정지"
    $Combat/PauseMenu.visible=combat.paused and not preparing
    $Combat/ReturnToPreparation.visible=show_preparation and combat.outcome!="RUNNING" and not preparing
    $Combat/PauseMenu/Motion.text="동작 줄이기: "+("켜짐" if reduced_motion else "꺼짐")
    $Combat/PauseMenu/Status.text=_message if not _message.is_empty() else "재개 버튼 또는 Esc로 계속합니다.\n연쇄 정산 중에는 저장할 수 없습니다."
    var rows:Array=session.line.rows() if session.mode=="LINE" else session.chain.rows().slice(2)
    var tiles:Array=_line_tiles if session.mode=="LINE" else _chain_tiles
    var width=10 if session.mode=="LINE" else 6
    for i in tiles.size():
        var kind=String(rows[i/width])[i%width]
        tiles[i].art.texture=null if kind=="." else assets.tile(kind)
        tiles[i].art.modulate=Color.WHITE
        tiles[i].marker.text=""
    if session.mode=="LINE":
        var kind=String(session.line.active_pair().get("resource","A"))
        for xy in session.line.ghost_cells():_overlay(tiles,10,int(xy[0]),int(xy[1])-4,kind,0.25)
        for xy in session.line.active_cells():_overlay(tiles,10,int(xy[0]),int(xy[1])-4,kind,1.0)
        var queue:Array=[]
        for pair in session.line.next_pairs().slice(0,3):queue.append(_pair_label(pair))
        $Puzzle/Queue.text="HOLD %s   ·   NEXT %s"%[_pair_label(session.line.hold_pair()),"  /  ".join(queue)]
    else:
        for cell in session.chain.ghost_cells():_overlay(tiles,6,int(cell.x),int(cell.y),cell.kind,0.25)
        if not session.chain.active_pair.is_empty():
            for cell in [session.chain.active_pair.axis,session.chain.active_pair.satellite]:_overlay(tiles,6,int(cell.x),int(cell.y),cell.kind,1.0)
        var queue:Array=[]
        for pair in session.chain._next_pairs:queue.append("+".join(pair))
        $Puzzle/Queue.text="NEXT %s · %s"%["  /  ".join(queue),session.chain.phase]
    if session.resource_mode=="SWAP":
        $Puzzle/Supply.text="보급 %d / 12쌍 · 교체 자원 10단위 → 3쌍\n같은 문양 2칸 → 자원 1단위 · 잔여 누적 / 스킬은 뿌요에서"%session.supply.pairs
        if exhausted:$Puzzle/Switch.text="교체 보급 →"
        if session.mode=="LINE":
            $Puzzle/Heading.text="SWAP · 자원 확보 / 스킬 발동 없음"
            rows=session.swap.rows()
            tiles=_swap_tiles
            width=8
            for i in tiles.size():
                tiles[i].art.texture=assets.tile(String(rows[i/8])[i%8])
                tiles[i].marker.text="선택" if Vector2i(i%8,i/8)==_swap_selected else ("◇" if Vector2i(i%8,i/8)==_swap_cursor else "")
            $Puzzle/Queue.text="클릭 2칸 / 방향키 + Enter · 인접 교환 · 자동 연속 소거도 자원만 획득"
            for control in ["Left","Right","Rotate","Drop","Hold"]:get_node("Puzzle/"+control).disabled=true
    var threat:Dictionary=session.disruption.preview()
    if threat.get("reserved",false) and threat.target_board==session.mode:
        var cells:Array=session.resource_candidates() if session.mode=="LINE" else session.chain.target_candidates()
        for cell in cells:
            var y=int(cell.y)-(4 if session.mode=="LINE" and session.resource_mode=="LINE" else 0)
            if cell.cell_id in threat.target_ids and y>=0 and y<rows.size():tiles[y*width+int(cell.x)].marker.text="✕"
    var current:Dictionary=combat.current_action()
    var next:Dictionary=combat.next_action()
    $Combat/Stage/HP.text="%s  HP %d"%[combat.encounter_info().get("label","균열 파괴자"),combat.boss_hp]
    $Combat/SharedTimer.text="%s  %.1f초"%["일시정지" if combat.paused else "공유 타이머",float(combat.eta_us)/1000000.0]
    var destruction=" · %s %d칸 파괴"%[threat.get("target_board","-"),threat.get("count",0)] if threat.get("count",0)>0 else ""
    $Combat/Current.text="현재 · %s%s"%[current.get("label",""),destruction]
    $Combat/Next.text="다음 · "+str(next.get("label","없음"))
    $Combat/Player/Resources.text="HP %d / 100   방어 %d   보호 %d\n공격 가산 +%d   이번 연쇄 %d"%[combat.hp,combat.armor,combat.ward,combat.attack_bank,session.chain.wave_index]
    if use_finishers:
        _refresh_finisher()
    else:
        _refresh_legacy_skills()
    if has_node("Preparation"):
        $Preparation.visible=preparing
        $Preparation/Line.modulate=Color("#ffe09a") if preferred_resource=="LINE" else Color.WHITE
        $Preparation/Swap.modulate=Color("#ffe09a") if preferred_resource=="SWAP" else Color.WHITE
        $Preparation/Status.text=_message
    if use_assists and assist_ui!=null:assist_ui.refresh()
    if use_mastery and mastery_ui!=null:mastery_ui.refresh()
    if feedback!=null:
        feedback.sync()
        skill_feedback.refresh(self)

func _refresh_legacy_skills()->void:
    var combat=session.combat
    var preview:Dictionary=combat.skill_preview(session.selected_category,mini(6,maxi(1,session.chain.wave_index+1)))
    $Combat/Skills/Stage.text="T1   T2   T3   T4   T5   T6    예고 T%d"%preview.get("stage",1)
    var recent="4개 연결 소거마다 자동 발동" if session.last_cast.is_empty() else "최근 %s T%d · 자동 발동"%[session.last_cast.category,session.last_cast.get("stage",1)]
    $Combat/Skills/Description.text="%s · 위력 %d\n%s\n%s"%[session.selected_category,preview.get("power",0),recent,_message if combat.outcome=="RUNNING" else combat.outcome]
    for category in ["ATK","DEF","SUP"]:
        get_node("Combat/Skills/"+category).modulate=Color("#ffe09a") if category==session.selected_category else Color.WHITE
    var icon={"ATK":"strike","DEF":"ward","SUP":"recover"}[session.selected_category]
    $Combat/Skills/Icon.texture=assets.texture("R1-ICONS",icon)
    # Cosmetic consumer reads all committed receipts, not only last_cast.
    if _ledger_count!=session._casts.size():
        presentation.sync(session._casts)
        _ledger_count=session._casts.size()
    if combat.outcome=="DEFEAT":presentation.cancel()
    var visual=presentation.view(reduced_motion)
    $Combat/CutIn.visible=not visual.is_empty()
    if not visual.is_empty():
        var actor=performer.texture(visual.category,"impact" if reduced_motion else visual.phase)
        $Combat/CutIn/Actor.texture=actor if actor!=null else assets.texture("R1-PORTRAIT","neutral")
        $Combat/CutIn.position.x=8+visual.offset_x
        $Combat/CutIn.modulate.a=visual.alpha
        $Combat/CutIn/Effect.texture=assets.texture("R1-ICONS",{"ATK":"strike","DEF":"ward","SUP":"recover"}[visual.category])
        $Combat/CutIn/Caption.text="%s T%d\n연쇄 ×%d"%[visual.category,visual.get("stage",1),visual.coalesced_count]
func _refresh_finisher()->void:
    var preview:Dictionary=session.starter_preview()
    var kind=String(preview.starter)
    var names={"A":"공격","D":"방어","H":"치유","T":"시간"}
    var waves=maxi(1,int(preview.waves))
    var label=names.get(kind,"아직 연결 없음")
    $Combat/Skills/Starter.text="시동 %s · %s"%[label,"확정 / 연쇄 종료 후 1회" if preview.locked else "현재 착지 예고"]
    $Combat/Skills/Stage.text="T1   T2   T3   T4   T5   T6    %s"%("%d연쇄 · T%d"%[waves,mini(waves,6)] if not kind.is_empty() else "4개 연결로 시동")
    var amount=session.finisher_power(kind,waves)
    var power_label=("시간 +%.2f초 (행동당 상한 3초)"%(amount/1000000.0)) if kind=="T" else "기본 위력 %d"%amount
    if kind=="A" and session.action.get("applied",false)==false:power_label+=" + 자원 %d"%session.combat.attack_bank
    var recent="" if session.last_cast.is_empty() else "최근 %s · %d연쇄 1회 발동"%[names.get(session.last_cast.starter,""),session.last_cast.wave]
    $Combat/Skills/Description.text="%s\n시동은 첫 소거 문양 · 이후 연쇄로 강화\n%s"%[power_label if not kind.is_empty() else "뿌요 4개를 연결하세요",recent]
    $Combat/Skills/Icon.texture=assets.tile(kind) if not kind.is_empty() else assets.texture("R1-ICONS","strike")
    var visual:Dictionary=session.action_view(reduced_motion)
    var busy=not visual.is_empty()
    $Combat/CutIn.visible=busy
    $Combat/Stage/Enemy.visible=true
    $Puzzle/Switch.disabled=busy
    if busy:
        for control in ["Left","Right","Rotate","Drop","Hold"]:get_node("Puzzle/"+control).disabled=true
    $Combat/ReturnToPreparation.visible=show_preparation and session.combat.outcome!="RUNNING" and not preparing and not busy
    if not busy:return
    $Combat/SharedTimer.text=("일시정지 · 연출" if session.combat.paused else "연출 중 · 양쪽 정지")+"  %.1f초"%(float(session.combat.eta_us)/1000000.0)
    var enemy=visual.owner=="ENEMY"
    $Combat/Stage/Enemy.visible=not enemy
    if not enemy:
        $Combat/Player/Resources.text="HP %d / 100   방어 %d   보호 %d\n공격 가산 +%d   완성 연쇄 %d"%[session.combat.hp,session.combat.armor,session.combat.ward,session.combat.attack_bank,visual.wave]
    else:
        $Combat/Current.text="발동 · "+visual.label
        $Combat/Next.text="대기 · "+str((session.combat.current_action() if visual.applied else session.combat.next_action()).get("label",""))
    var category="SUP" if visual.category=="TIME" else String(visual.category)
    $Combat/CutIn/Actor.texture=assets.enemy_texture(session._profile if use_assists else "", "idle") if enemy else performer.texture(category,"impact" if reduced_motion else visual.phase)
    $Combat/CutIn.position.x=8+visual.offset_x
    $Combat/CutIn.modulate.a=visual.alpha
    $Combat/CutIn/Effect.texture=assets.texture("R1-ICONS","strike") if enemy else assets.tile(visual.starter)
    $Combat/CutIn/Caption.text=("적 행동\n"+visual.label) if enemy else "%s T%d\n%d연쇄 · 1회"%[names[visual.starter],visual.stage,visual.wave]

func start_resource_battle(producer:String)->void:
    if not preparing or producer not in ["LINE","SWAP"]:return
    var candidate=(AssistSession.new("STANDARD",9112026,"r3:standalone",preferred_encounter) if use_assists else FinisherSession.new()) if use_finishers else Session.new()
    if use_mastery:candidate=MasterySession.new("STANDARD",9112026,"r3:standalone",preferred_encounter)
    if not candidate.command("prepare_resource",{"mode":producer}).success:return
    session=candidate
    if assist_ui!=null:assist_ui.reset_presentation()
    preferred_resource=producer
    var preference=ConfigFile.new()
    preference.set_value("puzzle","resource",producer)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(preference_path.get_base_dir()))
    var saved=preference.save(preference_path)
    _message="설정을 저장하지 못했습니다." if saved!=OK else "Tab으로 자원 보드 ↔ 뿌요 전환 · 스킬은 연쇄마다 자동 발동"
    preparing=false
    _swap_selected=Vector2i(-1,-1)
    _fraction_us=0.0
    presentation=Presentation.new()
    _ledger_count=0
    refresh()

func return_to_preparation()->void:
    if not show_preparation or session.combat.outcome=="RUNNING":return
    if use_finishers and not session.action.is_empty():return
    preparing=true
    session.combat.paused=true
    _message=""
    refresh()

func start_chain_practice()->void:
    if not preparing or not use_assists:return
    session=AssistSession.new("STANDARD",42,"practice","outer_breach")
    session.setup_practice()
    assist_ui.reset_presentation()
    preparing=false
    _message="연습: Space를 눌러 공격 → 치유 2연쇄를 확인하세요."
    refresh()

func start_line_practice(kind:String)->void:
    if not preparing or not use_mastery or kind not in ["FOUR","SPIN","COMBO"]:return
    session=MasterySession.new("STANDARD",42,"practice","outer_breach")
    session.setup_line_practice(kind)
    assist_ui.reset_presentation()
    preparing=false
    _message="테트리스 기술 연습 · 저장과 전투에 영향 없음"
    refresh()

func end_chain_practice()->void:
    if not use_assists or not session.practice_mode:return
    session.command("pause")
    preparing=true
    _message="연습 완료 · 실제 전투는 기존 자원 규칙으로 시작합니다."
    refresh()

func select_swap_cell(xy:Vector2i)->void:
    if use_finishers and not session.action.is_empty():return
    if preparing or session.resource_mode!="SWAP" or session.mode!="LINE" or session.combat.paused or session.combat.outcome!="RUNNING" or session.swap.resolving:return
    if xy.x<0 or xy.x>=8 or xy.y<0 or xy.y>=8:return
    _swap_cursor=xy
    if _swap_selected.x<0:_swap_selected=xy
    elif _swap_selected==xy:_swap_selected=Vector2i(-1,-1)
    elif absi(_swap_selected.x-xy.x)+absi(_swap_selected.y-xy.y)==1:
        dispatch("resource_swap",{"a":_swap_selected,"b":xy})
        _swap_selected=Vector2i(-1,-1)
    else:_swap_selected=xy
    refresh()

func _overlay(tiles:Array,width:int,x:int,y:int,kind:String,alpha:float)->void:
    if x<0 or x>=width or y<0 or y>=tiles.size()/width:return
    tiles[y*width+x].art.texture=assets.tile(kind)
    tiles[y*width+x].art.modulate.a=alpha

func _pair_label(pair:Dictionary)->String:
    return "비어 있음" if String(pair.get("shape","")).is_empty() else "%s:%s"%[pair.shape,pair.resource]

func save_checkpoint()->Dictionary:
    if preparing:return {"success":false,"reason":"PREPARATION"}
    if not session.combat.paused:return {"success":false,"reason":"PAUSE_REQUIRED"}
    var result:Dictionary=disk.save_session(session,clampi(roundi(_fraction_us*1000.0),0,999))
    _message="진행을 저장했습니다." if result.success else "저장하지 못했습니다: "+str(result.get("reason",""))
    refresh()
    return result

func restore_checkpoint()->Dictionary:
    if not session.combat.paused:return {"success":false,"reason":"PAUSE_REQUIRED"}
    var result:Dictionary=disk.load_checkpoint()
    if result.success:
        var state:Dictionary=result.snapshot
        var script=(AssistSession if use_assists else FinisherSession) if use_finishers else Session
        if use_mastery:script=MasterySession
        var candidate=script.new(state.difficulty,int(state.seed),state.run_id,state.profile)
        if not candidate.restore(state):return {"success":false,"reason":"INVALID_CHECKPOINT"}
        candidate.command("pause")
        session=candidate
        if use_assists:
            preferred_encounter=state.profile
            assist_ui.reset_presentation()
        preparing=false
        _swap_selected=Vector2i(-1,-1)
        _fraction_us=float(result.clock_remainder_ns)/1000.0
        presentation.sync(session._casts,true)
        _ledger_count=session._casts.size()
        _message="기록을 불러왔습니다. 재개를 눌러 계속하세요."+(" (백업 복구)" if result.source=="backup" else "")
    else:_message="불러오지 못했습니다: "+str(result.get("reason",""))
    refresh()
    return result
