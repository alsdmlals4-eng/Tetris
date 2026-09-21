## Thin phase coordinator; battle remains the existing 50:50 screen.
extends Control
const Route=preload("res://src/replanned_r3/short_expedition.gd")
const Save=preload("res://src/replanned_r3/short_expedition_save.gd")
const BattleScene=preload("res://scenes/replanned_r3/resource_choice.tscn")
var run=null
var battle=null
var terminal_session=null
var disk=Save.new()
var menu:VBoxContainer
var message=""
var reduced_motion:=false
var sound_muted:=false

func _ready()->void:
    if get_tree().current_scene==self:
        get_window().content_scale_size=Vector2i(1280,720)
        get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
        get_window().size=Vector2i(1280,720)
        get_window().min_size=Vector2i(960,540)
    var background=ColorRect.new()
    background.color=Color("#090f1d")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(background)
    var panel=PanelContainer.new()
    panel.name="Menu"
    panel.position=Vector2(190,50);panel.size=Vector2(900,620)
    var style=StyleBoxFlat.new()
    style.bg_color=Color("#101d30");style.border_color=Color("#bfa168");style.set_border_width_all(2)
    style.content_margin_left=32;style.content_margin_right=32;style.content_margin_top=24;style.content_margin_bottom=24
    panel.add_theme_stylebox_override("panel",style)
    add_child(panel)
    menu=VBoxContainer.new();menu.add_theme_constant_override("separation",14);panel.add_child(menu)
    show_menu()

func _text(value:String,font_size:int=22)->void:
    var label=Label.new()
    label.text=value;label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",Color("#ecd4a2"))
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    menu.add_child(label)

func _button(title:String,callback:Callable,parent:Node=null)->void:
    var b=Button.new();b.text=title;b.custom_minimum_size.y=52
    b.add_theme_font_size_override("font_size",21);b.pressed.connect(callback)
    b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    (menu if parent==null else parent).add_child(b)

func _clear_battle()->void:
    if battle!=null:
        reduced_motion=battle.reduced_motion
        sound_muted=battle.assist_ui.sound.volume_db<-70
        remove_child(battle);battle.queue_free();battle=null

func show_menu()->void:
    for child in menu.get_children():menu.remove_child(child);child.queue_free()
    $Menu.show()
    if run==null:
        _text("짧은 원정 · 균열의 핵까지",34)
        _text("외곽 → 주조소 또는 감시탑 → 균열의 핵\n자원 퍼즐을 고르고, 뿌요 시동 문양으로 스킬을 발동하세요.")
        _text("방어 시동: 보호막 + T단계만큼 반격 수호\n잔여 피해 50% 경감 · 경감한 만큼 적에게 반사",19)
        var modes=GridContainer.new();modes.columns=2
        modes.add_theme_constant_override("h_separation",14);modes.add_theme_constant_override("v_separation",14);menu.add_child(modes)
        _button("테트리스 원정 · 표준",func():start_run("LINE","STANDARD"),modes)
        _button("타일 교체 원정 · 표준",func():start_run("SWAP","STANDARD"),modes)
        _button("테트리스 원정 · 여유",func():start_run("LINE","RELAXED"),modes)
        _button("타일 교체 원정 · 여유",func():start_run("SWAP","RELAXED"),modes)
        _button("저장한 원정 이어하기",restore_checkpoint)
        _button("단일 전투 / 기술 연습",func():get_tree().change_scene_to_file("res://scenes/replanned_r3/resource_choice.tscn"))
    else:
        var state:Dictionary=run.view()
        _text("원정 %d / 3 · %s"%[mini(3,int(state.stage)+1),{"ROUTE":"다음 전장","SUPPLY":"승리 · 보급 하나 선택","COMPLETE":"균열 봉쇄 성공","DEFEAT":"원정 중단"}.get(state.phase,state.phase)],32)
        _text("HP %d / 100 · %s · %s"%[state.hp,"테트리스" if run.resource_mode=="LINE" else "타일 교체","여유" if state.difficulty=="RELAXED" else "표준"])
        if state.phase=="ROUTE":
            for id in run.available_encounters():
                var chosen=String(id);var brief:Dictionary=run.encounter_brief(id)
                _text(brief.enemy_name+" · "+brief.tactical_hint,19)
                _button("진입 · "+brief.enemy_name,func():launch(chosen))
            _button("원정 저장",save_checkpoint)
        else:
            var report:Dictionary=run.summary(terminal_session)
            _text("돌파 %d전 · 스킬 %d회 · 최고 %d연쇄\n반격 수호 경감 %d · 실제 반사 피해 %d"%[report.battles,report.casts,report.max_combo,report.prevented,report.reflected],23)
            if state.phase=="SUPPLY":
                _text("현재 전투의 보드는 초기화됩니다. 보급은 하나만 선택하세요.",18)
                for id in run.catalog().supplies:
                    var chosen=String(id);var effect:Dictionary=run.supply_preview(id)
                    var detail="HP +%d"%effect.healing_applied if id=="repair" else ("다음 전투 공격 가산 +%d"%effect.attack_bank if id=="attack" else "다음 전투 방어도 +%d"%effect.armor)
                    _button(run.catalog().supplies[id].label+" · "+detail,func():choose_supply(chosen))
            if state.phase=="DEFEAT":_button("같은 전투 다시 도전 · 시작 HP/보드로 복원",retry_battle)
            _button("새 원정 선택 화면",func():run=null;terminal_session=null;message="";show_menu())
    if not message.is_empty():_text(message,16)

func start_run(producer:String,difficulty:String,seed_value:int=-1)->void:
    var actual_seed=seed_value if seed_value>=0 else int(Time.get_unix_time_from_system())
    var candidate=Route.new("short:"+str(actual_seed),actual_seed,difficulty)
    if not candidate.select_resource(producer):return
    _clear_battle();run=candidate;terminal_session=null;message="";show_menu()

func launch(id:String)->void:
    if run==null or not run.launch(id).success:return
    _show_battle(run.make_battle_session(),false)

func _show_battle(session,paused:bool,clock_remainder_ns:int=0)->void:
    if session==null:message="전투를 준비하지 못했습니다.";show_menu();return
    _clear_battle();$Menu.hide()
    battle=BattleScene.instantiate()
    battle.initial_session=session;battle.checkpoint_owner=self
    add_child(battle)
    battle.reduced_motion=reduced_motion
    battle.assist_ui.sound.volume_db=-80 if sound_muted else -18
    battle.get_node("Combat/PauseMenu/Sound").text="효과음 꺼짐" if sound_muted else "효과음 켜짐"
    battle.preparing=false
    session.command("pause" if paused else "resume")
    battle._fraction_us=float(clock_remainder_ns)/1000.0
    battle.presentation.sync(session._casts,true);battle._ledger_count=session._casts.size()
    battle.refresh()

func _process(_delta:float)->void:
    if battle==null or battle.session.combat.outcome=="RUNNING" or not battle.session.can_checkpoint():return
    terminal_session=battle.session
    var result:Dictionary=run.finish_session(terminal_session)
    if not result.success:
        battle.session.command("pause");battle._message="결과 검증 실패 · "+result.reason;battle.refresh();return
    _clear_battle()
    var saved:Dictionary=disk.save_expedition(run,terminal_session)
    message="원정 자동 저장 완료" if saved.success else "저장 실패 · "+saved.reason
    show_menu()

func choose_supply(id:String)->void:
    if run==null or not run.choose_supply(id).success:return
    terminal_session=null
    var saved:Dictionary=disk.save_expedition(run,null)
    message="보급 선택 저장 완료" if saved.success else "저장 실패 · "+saved.reason
    show_menu()

func retry_battle()->void:
    if run==null or not run.retry_battle().success:return
    terminal_session=null;_show_battle(run.make_battle_session(),false)

func save_checkpoint()->Dictionary:
    if run==null:return {"success":false,"reason":"NO_RUN"}
    if battle!=null and not battle.session.combat.paused:return {"success":false,"reason":"PAUSE_REQUIRED"}
    var result:Dictionary=disk.save_expedition(run,battle.session if battle!=null else terminal_session,clampi(roundi(battle._fraction_us*1000.0),0,999) if battle!=null else 0)
    message="원정을 저장했습니다." if result.success else "저장 실패 · "+result.reason
    if battle!=null:battle._message=message;battle.refresh()
    else:show_menu()
    return result

func restore_checkpoint()->Dictionary:
    if battle!=null and not battle.session.combat.paused:return {"success":false,"reason":"PAUSE_REQUIRED"}
    var result:Dictionary=disk.load_expedition()
    if result.success:
        _clear_battle();run=result.expedition;terminal_session=null
        message="원정 복원 완료"+(" · 백업 복구" if result.source=="backup" else "")
        if run.view().phase=="BATTLE":_show_battle(result.session,true,result.clock_remainder_ns)
        else:terminal_session=result.session;show_menu()
    else:
        message=result.reason
        if battle!=null:battle._message=message;battle.refresh()
        else:show_menu()
    return result
