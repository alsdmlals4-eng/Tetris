extends Control
const Session=preload("res://src/replanned_r3/r3_session.gd")
const Assets=preload("res://src/replanned_r2/r2_assets.gd")
const Presentation=preload("res://src/replanned_r3/r3_cast_presentation.gd")
const Performer=preload("res://src/replanned_r3/r3_performer.gd")
var session=Session.new()
var assets
var performer
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
    if get_tree().current_scene==self:
        get_window().content_scale_size=Vector2i(1280,720)
        get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
        get_window().size=Vector2i(1280,720)
        get_window().min_size=Vector2i(960,540)
    get_window().focus_exited.connect(focus_lost)
    assets=Assets.new()
    performer=Performer.new()
    _rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/replanned_r3/rules.json"))
    var left=_panel(self,"Puzzle",Rect2(12,12,622,696))
    var right=_panel(self,"Combat",Rect2(646,12,622,696))
    _label(left,"Heading",Rect2(16,8,590,38),"LINE · 자원 준비",24)
    _label(left,"Supply",Rect2(16,46,590,50),"",18)
    _make_board(left,"LineBoard",Vector2(181,108),10,20,25,_line_tiles)
    _make_board(left,"ChainBoard",Vector2(185,108),6,12,42,_chain_tiles)
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
    for category in ["ATK","DEF","SUP"]:
        var selected=category
        _button(skills,category,Rect2(10+index*198,8,190,33),{"ATK":"공격 ATK","DEF":"방어 DEF","SUP":"지원 SUP"}[category],func():dispatch("category",{"category":selected}))
        index+=1
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
    var result:Dictionary=session.command(action,args)
    _message=String(result.get("reason",""))
    refresh()
    return result

func focus_lost()->void:
    if session.mode=="CHAIN":session.command("soft_drop",{"enabled":false})
    session.command("pause")
    _message="창을 벗어나 일시정지 · 정지 버튼 또는 Esc로 재개"
    refresh()

func _process(delta:float)->void:
    _fraction_us+=delta*1000000.0
    var us=int(_fraction_us)
    _fraction_us-=us
    if not session.combat.paused:
        session.tick(us)
        _pose_us+=us
    presentation.tick(us,session.combat.paused)
    refresh()

func _unhandled_key_input(event:InputEvent)->void:
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
        KEY_SPACE:dispatch("hard_drop")
        KEY_C,KEY_H:dispatch("hold")
        KEY_TAB:dispatch("switch")
        KEY_ESCAPE:dispatch("resume" if session.combat.paused else "pause")
        _:return
    get_viewport().set_input_as_handled()

func refresh()->void:
    if not is_node_ready() or assets==null:return
    var combat=session.combat
    $Puzzle/Heading.text="LINE · 자원 준비" if session.mode=="LINE" else "CHAIN · 낙하 연결 / 연쇄 자동 스킬"
    $Puzzle/Supply.text="보급 %d / 12쌍 · LINE 한 줄 → 3쌍\n%s"%[session.supply.pairs,"보급 소진 · LINE에서 줄을 지워 충전" if session.mode=="CHAIN" and session.supply.pairs==0 and session.chain.active_pair.is_empty() else "공격 A · 방어 D · 치유 H · 시간 T"]
    $Puzzle/LineBoard.visible=session.mode=="LINE"
    $Puzzle/ChainBoard.visible=session.mode=="CHAIN"
    $Puzzle/Hold.disabled=session.mode=="CHAIN"
    $Puzzle/Pause.text="재개" if combat.paused else "정지"
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
    var threat:Dictionary=session.disruption.preview()
    if threat.get("reserved",false) and threat.target_board==session.mode:
        var cells:Array=session.line.target_candidates() if session.mode=="LINE" else session.chain.target_candidates()
        for cell in cells:
            var y=int(cell.y)-(4 if session.mode=="LINE" else 0)
            if cell.cell_id in threat.target_ids and y>=0 and y<rows.size():tiles[y*width+int(cell.x)].marker.text="✕"
    var current:Dictionary=combat.current_action()
    var next:Dictionary=combat.next_action()
    $Combat/Stage/HP.text="%s  HP %d"%[combat.encounter_info().get("label","균열 파괴자"),combat.boss_hp]
    $Combat/SharedTimer.text="%s  %.1f초"%["일시정지" if combat.paused else "공유 타이머",float(combat.eta_us)/1000000.0]
    var destruction=" · %s %d칸 파괴"%[threat.get("target_board","-"),threat.get("count",0)] if threat.get("count",0)>0 else ""
    $Combat/Current.text="현재 · %s%s"%[current.get("label",""),destruction]
    $Combat/Next.text="다음 · "+str(next.get("label","없음"))
    $Combat/Player/Resources.text="HP %d / 100   방어 %d   보호 %d\n공격 가산 +%d   이번 연쇄 %d"%[combat.hp,combat.armor,combat.ward,combat.attack_bank,session.chain.wave_index]
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
        var actor=performer.texture(visual.category,visual.phase)
        $Combat/CutIn/Actor.texture=actor if actor!=null else assets.texture("R1-PORTRAIT","neutral")
        $Combat/CutIn.position.x=8+visual.offset_x
        $Combat/CutIn.modulate.a=visual.alpha
        $Combat/CutIn/Effect.texture=assets.texture("R1-ICONS",{"ATK":"strike","DEF":"ward","SUP":"recover"}[visual.category])
        $Combat/CutIn/Caption.text="%s T%d\n연쇄 ×%d"%[visual.category,visual.get("stage",1),visual.coalesced_count]

func _overlay(tiles:Array,width:int,x:int,y:int,kind:String,alpha:float)->void:
    if x<0 or x>=width or y<0 or y>=tiles.size()/width:return
    tiles[y*width+x].art.texture=assets.tile(kind)
    tiles[y*width+x].art.modulate.a=alpha

func _pair_label(pair:Dictionary)->String:
    return "비어 있음" if String(pair.get("shape","")).is_empty() else "%s:%s"%[pair.shape,pair.resource]
