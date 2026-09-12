## Isolated first encounter view. All gameplay mutation crosses Session.command/tick.
extends Control
signal diagnostic_recorded(record: Dictionary)
const Session = preload("res://src/replanned_r2/r2_session.gd")
const Disk = preload("res://src/replanned_r2/r2_save.gd")
const PlaytestReport = preload("res://src/replanned_r2/r2_playtest_report.gd")
var report_directory := PlaytestReport.DEFAULT_DIRECTORY
var _result_practice_complete := false
const Assets = preload("res://src/replanned_r2/r2_assets.gd")
const Inputs = preload("res://src/replanned_r2/r2_input.gd")
const Catalog = preload("res://src/production/line/tetromino_catalog.gd")
@export var save_path := "user://replanned_r2/save.json"
@export var options_path := "user://replanned_r2/options.json"
var session
var assets
var disk
var inputs = Inputs.new()
var held_inputs: Dictionary:
    get: return inputs.held
var page := "main"
var run_seed := 9112026
var difficulty := "STANDARD"
var practice_stage := 0
var chain_cursor := Vector2i.ZERO
var chain_selected := Vector2i(-1,-1)
var options: Dictionary
var options_draft: Dictionary
var pose_time_us := 0
var boss_pose := "idle"
var _impact_us := 0
var _hurt_us := 0
var _portrait_hurt_us := 0
var _clock_ns := 0
var _autosave_us := 0
var _details_was_paused := false
var _options_was_paused := false
var _options_return := "main"
var _practice_start_metrics := {}
var _practice_saw_pause := false
var _last_wall_us := 0
var _catalog
var _rules: Dictionary
var _source: Dictionary
var _message := ""
var _last_line_receipt := {}
var _reported_safety_chains := {}
var _pending_save_failure := ""
var _save_failure_reason := ""
var _line_cells := []
var _active_cells := []
var _ghost_cells := []
var _chain_cells := []
var _cell_styles := []
var _preview_cells := []
var _labels := []
const GOLD = Color("#e8c879")
const CYAN = Color("#82dfda")

func _ready():
    var window = get_window()
    if get_tree().current_scene == self:
        window.content_scale_size = Vector2i(1280,720)
        window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
        window.min_size = Vector2i(1280,720)
        window.size = Vector2i(1280,720)
        window.close_requested.connect(_close_requested)
        get_tree().auto_accept_quit = false
    window.focus_exited.connect(_focus_lost)
    Input.joy_connection_changed.connect(device_connection_changed)
    assets = Assets.new()
    disk = Disk.new(save_path,options_path)
    options = disk.load_options()
    inputs.configure(options)
    _source = JSON.parse_string(FileAccess.get_file_as_string(Session.DATA_PATH))
    _rules = JSON.parse_string(FileAccess.get_file_as_string(Session.Combat.RULES_PATH))
    _catalog = Catalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(Session.Line.CATALOG_PATH)))
    _build_ui()
    _refresh_control_guidance()
    _apply_font()
    _show_page("main")
    _refresh_continue()
    _last_wall_us = Time.get_ticks_usec()
    if not assets.errors.is_empty():
        $Main/Status.text = "개발 오류: "+", ".join(assets.errors)

func _exit_tree():
    inputs.release_menu_bindings()

func _panel(parent: Node, node_name: String, rect: Rect2) -> Panel:
    var node = Panel.new()
    node.name = node_name
    parent.add_child(node)
    node.position = rect.position
    node.size = rect.size
    var style = StyleBoxFlat.new()
    style.bg_color = Color("#102231")
    style.border_color = Color("#536371")
    style.set_border_width_all(1)
    node.add_theme_stylebox_override("panel",style)
    return node
func _container(parent: Node, node_name: String, rect: Rect2) -> Control:
    var node = Control.new()
    node.name = node_name
    parent.add_child(node)
    node.position = rect.position
    node.size = rect.size
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node
func _label(parent: Node, node_name: String, rect: Rect2, text: String, font_size: int = 18, color: Color = Color.WHITE) -> Label:
    var node = Label.new()
    node.name = node_name
    parent.add_child(node)
    node.position = rect.position
    node.size = rect.size
    node.text = text
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    node.add_theme_color_override("font_color",color)
    node.set_meta("base_font",font_size)
    _labels.append(node)
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node
func _button(parent: Node, node_name: String, rect: Rect2, text: String, callback: Callable) -> Button:
    var node = Button.new()
    node.name = node_name
    parent.add_child(node)
    node.position = rect.position
    node.size = rect.size
    node.text = text
    node.focus_mode = Control.FOCUS_ALL
    node.pressed.connect(callback)
    node.set_meta("base_font",17)
    _labels.append(node)
    return node
func _image(parent: Node, node_name: String, rect: Rect2, texture: Texture2D) -> TextureRect:
    var node = TextureRect.new()
    node.name = node_name
    parent.add_child(node)
    node.position = rect.position
    node.size = rect.size
    node.texture = texture
    node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node

func _guidance_tooltip(entries: Array) -> String:
    var lines := PackedStringArray()
    for group in ["keyboard_mapping","gamepad_mapping"]:
        var parts := PackedStringArray()
        for entry in entries:
            parts.append(String(entry["label"])+" "+inputs.binding_label(String(entry["action"]),group,true))
        lines.append(("키보드" if group == "keyboard_mapping" else "게임패드")+": "+" · ".join(parts))
    return "\n".join(lines)

func _refresh_control_guidance():
    if not has_node("Battle/Puzzle/Line/Input"): return
    var group: String = inputs.presentation_group
    var line: Label = $Battle/Puzzle/Line/Input
    line.text = "%s %s/%s 이동 · %s/%s 회전 · %s 낙하 · %s 홀드" % [inputs.group_label(group),inputs.binding_label("left",group),inputs.binding_label("right",group),inputs.binding_label("rotate_left",group),inputs.binding_label("rotate_right",group),inputs.binding_label("hard_drop",group),inputs.binding_label("hold",group)]
    line.tooltip_text = _guidance_tooltip([{"label":"왼쪽","action":"left"},{"label":"오른쪽","action":"right"},{"label":"왼쪽 회전","action":"rotate_left"},{"label":"오른쪽 회전","action":"rotate_right"},{"label":"낙하","action":"hard_drop"},{"label":"HOLD","action":"hold"}])
    line.mouse_filter = Control.MOUSE_FILTER_STOP
    var chain: Label = $Battle/Puzzle/Chain/Role
    if practice_stage == 0:
        chain.text = "인접 교환 → 파동마다 자동 기술\n타일 직접 보상 없음 · %s 보드 전환" % inputs.binding_phrase("switch",group)
    chain.tooltip_text = _guidance_tooltip([{"label":"보드 전환","action":"switch"}])
    chain.mouse_filter = Control.MOUSE_FILTER_STOP
    var pause: Button = $Battle/Puzzle/Pause
    pause.text = "정지 · "+inputs.binding_phrase("pause",group)
    pause.tooltip_text = _guidance_tooltip([{"label":"전체 일시정지","action":"pause"}])

func _practice_control_tooltip() -> String:
    return _guidance_tooltip([{"label":"즉시 낙하","action":"hard_drop"},{"label":"보드 전환","action":"switch"},{"label":"DEF 선택","action":"def"},{"label":"전체 일시정지","action":"pause"}])

func _build_ui():
    var font = SystemFont.new()
    font.font_names = PackedStringArray(["Malgun Gothic","맑은 고딕","sans-serif"])
    theme = Theme.new()
    theme.default_font = font
    theme.default_font_size = 18
    _image(self,"Backdrop",Rect2(0,0,1280,720),assets.texture("R1-ENV","full")).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    var main = _container(self,"Main",Rect2(0,0,1280,720))
    _panel(main,"Menu",Rect2(40,40,490,640))
    _image(main,"Boss",Rect2(566,55,690,630),assets.texture("R2-BOSS","idle"))
    _label(main,"Title",Rect2(66,80,440,100),"균열에 맞서는 두 퍼즐",29,GOLD)
    _label(main,"Subtitle",Rect2(66,170,440,65),"LINE 준비 → CHAIN 자동 발동\nR2 후보 실행 · 제목은 작업 표기",18,CYAN)
    _button(main,"Continue",Rect2(66,242,426,44),"이어하기",continue_run)
    _button(main,"NewRun",Rect2(66,300,426,44),"새 도전",request_new_run)
    _button(main,"Practice",Rect2(66,358,426,44),"연습하기",func(): begin_practice(1))
    _button(main,"Settings",Rect2(66,416,426,44),"설정",open_options)
    _button(main,"Quit",Rect2(66,474,426,44),"종료",func(): get_tree().quit())
    _label(main,"Status",Rect2(66,542,426,108),"",16,CYAN)
    var briefing = _panel(self,"Briefing",Rect2(40,40,1200,640))
    _label(briefing,"Title",Rect2(26,24,680,55),"출격 · 균열 파괴자",29,GOLD)
    _label(briefing,"Rules",Rect2(26,110,690,310),"목표: 보스 HP 240 → 0 / 내 HP 100\nLINE: 검·방패·하트·시계 자원 준비\nCHAIN: 인접 교환 → 파동마다 선택 계열 자동 발동\nATK 공격 / DEF 현재 행동 방벽 / SUP 회복\n공유 타이머는 현재 적 행동까지 남은 시간입니다.\n읽는 동안 전투 시계는 흐르지 않습니다.",23)
    _image(briefing,"Boss",Rect2(745,50,420,480),assets.texture("R2-BOSS","anticipation"))
    _button(briefing,"Standard",Rect2(26,435,330,44),"표준 · STANDARD",func(): difficulty="STANDARD"; _refresh_mode())
    _button(briefing,"Relaxed",Rect2(370,435,330,44),"여유 · 준비시간 1.25배",func(): difficulty="RELAXED"; _refresh_mode())
    _button(briefing,"Deploy",Rect2(26,550,330,50),"출격",func(): start_run(difficulty,run_seed))
    _button(briefing,"Back",Rect2(370,550,330,50),"메인",func(): _show_page("main"))
    _build_battle()
    _build_modals()
    _build_options()
    var result = _panel(self,"Result",Rect2(40,30,1200,660))
    _label(result,"Title",Rect2(30,20,750,50),"전투 결과",29,GOLD)
    _image(result,"Portrait",Rect2(1030,18,96,96),assets.texture("R1-PORTRAIT","neutral"))
    _image(result,"BossVisual",Rect2(795,130,380,330),assets.texture("R2-BOSS","idle"))
    _label(result,"Metrics",Rect2(30,95,750,450),"",20)
    _button(result,"Retry",Rect2(30,575,350,50),"같은 seed로 재도전",retry_run)
    _button(result,"Main",Rect2(400,575,350,50),"메인",return_to_main)
    _label(result,"ExportStatus",Rect2(795,465,375,100),"검수 기록은 버튼을 눌러 저장합니다.\n개인정보 수집·자동 업로드 없음",16)
    _button(result,"ExportReport",Rect2(795,575,375,50),"검수 기록 저장",export_playtest_report)
    var overwrite = ConfirmationDialog.new()
    overwrite.name = "OverwriteDialog"
    overwrite.title = "새 도전"
    overwrite.dialog_text = "이어하기 기록이 있습니다. 새 도전으로 체크포인트를 바꾸시겠습니까?"
    overwrite.confirmed.connect(_open_briefing)
    add_child(overwrite)

func _build_battle():
    var battle = _container(self,"Battle",Rect2(0,0,1280,720))
    var puzzle = _panel(battle,"Puzzle",Rect2(16,16,616,688))
    _button(puzzle,"LineButton",Rect2(16,8,210,36),"LINE · 자원 준비",func(): _switch_to("LINE"))
    _button(puzzle,"ChainButton",Rect2(238,8,220,36),"CHAIN · 자동 기술",func(): _switch_to("CHAIN"))
    var pause_button := _button(puzzle,"Pause",Rect2(470,8,130,36),"정지",pause_game)
    pause_button.clip_text = true
    pause_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    var line = _container(puzzle,"Line",Rect2(0,0,616,688))
    var cells = _container(line,"Cells",Rect2(178,62,260,520))
    for y in range(20):
        for x in range(10):
            var cell = _panel(cells,"Cell_%d_%d"%[x,y],Rect2(x*26,y*26,26,26))
            _line_cells.append(_image(cell,"Art",Rect2(1,1,24,24),null))
    for kind in ["Ghost","Active"]:
        var piece_layer = _container(line,kind,Rect2(178,62,260,520))
        piece_layer.clip_contents = true
        for i in range(4):
            var tile = _image(piece_layer,"Cell%d"%i,Rect2(0,0,26,26),null)
            if kind == "Ghost":
                tile.modulate.a = 0.35
                for edge in range(4):
                    for dash in range(4):
                        var mark=ColorRect.new()
                        mark.color=CYAN
                        mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
                        mark.position=Vector2(dash*7,0 if edge==0 else 24) if edge<2 else Vector2(0 if edge==2 else 24,dash*7)
                        mark.size=Vector2(4,2) if edge<2 else Vector2(2,4)
                        tile.add_child(mark)
                _ghost_cells.append(tile)
            else: _active_cells.append(tile)
    var previews = _container(line,"Previews",Rect2(18,588,580,69))
    for i in range(6):
        var preview = _container(previews,"Hold" if i == 0 else "Next%d"%i,Rect2(i*97,0,93,69))
        _label(preview,"Label",Rect2(0,0,93,25),"HOLD" if i == 0 else "NEXT %d"%i,14,CYAN)
        var tiles := []
        for j in range(4): tiles.append(_image(preview,"Cell%d"%j,Rect2(0,29,13,13),null))
        _preview_cells.append(tiles)
    _label(line,"Receipt",Rect2(450,74,158,480),"최근 LINE 보상\n아직 없음",14,CYAN)
    _label(line,"Input",Rect2(12,659,592,27),"",14)
    var chain = _container(puzzle,"Chain",Rect2(0,0,616,688))
    var grid = _container(chain,"Cells",Rect2(52,62,512,512))
    for color in [Color("#344550"),CYAN,GOLD]:
        var style = StyleBoxFlat.new()
        style.bg_color=Color("#122434")
        style.border_color=color
        style.set_border_width_all(1 if color==Color("#344550") else 3)
        _cell_styles.append(style)
    for y in range(8):
        for x in range(8):
            var cell = _button(grid,"Cell_%d_%d"%[x,y],Rect2(x*64,y*64,64,64),"",_click_cell.bind(Vector2i(x,y)))
            _image(cell,"Art",Rect2(2,2,60,60),null)
            _chain_cells.append(cell)
    _label(chain,"State",Rect2(18,582,580,40),"",18,CYAN)
    _label(chain,"Role",Rect2(18,628,580,52),"인접 교환 → 파동마다 자동 기술\n타일 직접 보상 없음",17)
    var combat = _panel(battle,"Combat",Rect2(648,16,616,688))
    var stage = _panel(combat,"Stage",Rect2(0,0,616,300))
    _image(stage,"Backdrop",Rect2(1,1,614,298),assets.texture("R1-ENV","full")).stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    var clip = _container(stage,"BodyClip",Rect2(7,42,602,258))
    clip.clip_contents = true
    var boss = _image(clip,"BossVisual",Rect2(0,0,602,602.0*460.0/651.0),assets.texture("R2-BOSS","idle"))
    boss.pivot_offset = Vector2(602.0*325.0/651.0,602.0*448.0/651.0)
    _panel(stage,"NamePlate",Rect2(42,0,532,40))
    _label(stage,"HP",Rect2(53,2,510,34),"",22,GOLD)
    var hp_bar=ProgressBar.new()
    hp_bar.name="HealthBar"
    hp_bar.position=Vector2(12,35)
    hp_bar.size=Vector2(592,6)
    hp_bar.show_percentage=false
    hp_bar.max_value=_source.encounter.boss_hp
    stage.add_child(hp_bar)
    var threat = _panel(combat,"Threat",Rect2(0,312,616,116))
    _label(threat,"Current",Rect2(12,4,230,29),"",16)
    _image(threat,"Icon",Rect2(12,36,32,32),assets.texture("R1-ICONS","strike"))
    _label(threat,"Damage",Rect2(49,35,192,63),"",15)
    _label(threat,"TimerTitle",Rect2(235,2,145,26),"공유 타이머",16,GOLD)
    _label(threat,"ETA",Rect2(249,29,120,43),"",29,CYAN)
    _label(threat,"Extension",Rect2(226,80,175,28),"",14)
    _label(threat,"Next",Rect2(412,4,196,94),"",15)
    var hud = _panel(combat,"PlayerHUD",Rect2(0,440,616,96))
    _image(hud,"Portrait",Rect2(0,0,96,96),assets.texture("R1-PORTRAIT","neutral"))
    _label(hud,"HP",Rect2(111,5,495,39),"",22)
    _label(hud,"Resources",Rect2(111,49,495,40),"",18,CYAN)
    var dock = _panel(combat,"SkillDock",Rect2(0,548,616,140))
    for i in range(3):
        var category = ["ATK","DEF","SUP"][i]
        var button = _button(dock,category,Rect2(12+i*198,7,190,34),category+" "+["공격","방어","치유"][i],func(): dispatch("category",{"category":category}))
        button.set_meta("base_font",16)
    for i in range(6):
        var button = _button(dock,"Tier%d"%(i+1),Rect2(12+i*98,47,92,27),"T%d"%(i+1),open_details.bind(i+1))
        button.set_meta("base_font",14)
    _image(dock,"NextIcon",Rect2(12,84,44,44),assets.texture("R1-ICONS","strike"))
    _label(dock,"Next",Rect2(64,79,540,28),"",15)
    _label(dock,"Recent",Rect2(64,108,540,27),"",14,CYAN)
    _label(battle,"PracticeStatus",Rect2(28,73,145,400),"",16,CYAN)
    _button(battle,"PracticeNext",Rect2(28,485,140,42),"다음 학습",_next_practice)
    _button(battle,"PracticeRetry",Rect2(28,533,140,42),"단계 다시",func(): begin_practice(practice_stage))

func _build_modals():
    var shield=ColorRect.new()
    shield.name="ModalShield"
    shield.position=Vector2.ZERO
    shield.size=Vector2(1280,720)
    shield.color=Color(0,0,0,0.55)
    shield.mouse_filter=Control.MOUSE_FILTER_STOP
    add_child(shield)
    var failure=_panel(self,"SaveFailurePanel",Rect2(250,150,780,420))
    _label(failure,"Title",Rect2(24,20,732,45),"기록 저장을 완료하지 못했습니다",26,GOLD)
    _label(failure,"Status",Rect2(24,86,732,160),"",20)
    _button(failure,"RetrySave",Rect2(24,270,732,48),"현재 상태 저장 다시 시도",_retry_failed_save)
    _button(failure,"PreviousRecord",Rect2(24,334,732,54),"현재 상태를 저장하지 않고 이전 기록으로 메인",_discard_unsaved_to_main)
    var pause = _panel(self,"PausePanel",Rect2(330,100,620,520))
    _label(pause,"Title",Rect2(24,20,572,45),"전체 일시정지",29,GOLD)
    _label(pause,"Status",Rect2(24,77,572,92),"ETA · 퍼즐 · 파동 · 자세 타이머가 정지했습니다.",20)
    _button(pause,"Resume",Rect2(24,180,572,44),"그대로 계속",resume_game)
    _button(pause,"Details",Rect2(24,238,278,44),"기술 설명",func(): open_details(1))
    _button(pause,"Options",Rect2(316,238,280,44),"설정",open_options)
    _button(pause,"Main",Rect2(24,300,572,48),"체크포인트 보존 후 메인",_exit_battle)
    _label(pause,"Checkpoint",Rect2(24,370,572,110),"",18,CYAN)
    var details = _panel(self,"DetailsPanel",Rect2(170,45,940,630))
    _label(details,"Title",Rect2(25,20,890,50),"기술 설명 · 전체 정지",28,GOLD)
    _label(details,"Body",Rect2(25,98,890,430),"",23)
    _button(details,"Close",Rect2(25,550,890,54),"설명 닫기 · 이전 정지 상태로",close_details)

func _build_options():
    var panel = _panel(self,"Options",Rect2(90,30,1100,660))
    _label(panel,"Title",Rect2(24,12,1020,40),"설정 · 전투 시계 정지",27,GOLD)
    _label(panel,"Language",Rect2(24,65,400,34),"언어: 한국어",19)
    _button(panel,"FontScale",Rect2(24,111,480,40),"",_toggle_font)
    _button(panel,"Motion",Rect2(24,162,480,40),"",_toggle_motion)
    _label(panel,"AudioNote",Rect2(24,218,480,56),"무음으로 모든 정보를 읽을 수 있습니다.\n현재 추가 사운드 의존성 없음",17,CYAN)
    for i in range(2):
        var key = ["effects","music"][i]
        _label(panel,key+"Label",Rect2(24,289+i*68,480,28),"효과음" if i==0 else "음악",17)
        var slider = HSlider.new()
        slider.name = key+"Level"
        slider.position = Vector2(24,322+i*68)
        slider.size = Vector2(480,28)
        slider.min_value = 0
        slider.max_value = 100
        slider.step = 1
        panel.add_child(slider)
        slider.value_changed.connect(func(value): options_draft.audio[key]=int(value))
    _label(panel,"MappingTitle",Rect2(560,62,500,40),"조작 재지정 · 키 / 패드",20,GOLD)
    var device = OptionButton.new()
    device.name = "Device"
    device.position = Vector2(560,112)
    device.size = Vector2(495,40)
    device.add_item("키보드")
    device.add_item("게임패드")
    device.item_selected.connect(func(_index): _refresh_mapping_actions())
    panel.add_child(device)
    var action = OptionButton.new()
    action.name = "Action"
    action.position = Vector2(560,164)
    action.size = Vector2(495,40)
    action.item_selected.connect(func(_index): _refresh_mapping_label())
    panel.add_child(action)
    _label(panel,"Binding",Rect2(560,217,495,58),"",18,CYAN)
    _button(panel,"Remap",Rect2(560,280,240,44),"새 입력 받기",_begin_remap)
    _button(panel,"CancelCapture",Rect2(815,280,240,44),"입력 취소",func(): inputs.cancel_capture(); _refresh_mapping_label())
    _button(panel,"Reset",Rect2(560,340,495,44),"키 / 패드 기본값 복원",_reset_mappings)
    _label(panel,"Status",Rect2(24,435,1030,115),"충돌하는 입력은 저장하지 않습니다. 취소는 변경 전 설정으로 돌아갑니다.",18,CYAN)
    _button(panel,"Save",Rect2(24,581,495,50),"저장하고 돌아가기",func(): close_options(true))
    _button(panel,"Cancel",Rect2(560,581,495,50),"취소 / 되돌리기",func(): close_options(false))

func _show_page(next: String):
    page = next
    for node_name in ["Main","Briefing","Battle","Result"]:
        get_node(node_name).visible = node_name.to_lower() == page
    for node_name in ["PausePanel","DetailsPanel","Options","SaveFailurePanel"]: get_node(node_name).hide()
    _sync_modal_boundary()
    inputs.clear()
    _last_wall_us = Time.get_ticks_usec()
    if page == "main": $Main/NewRun.grab_focus()
    elif page == "briefing": $Briefing/Deploy.grab_focus()
    elif page == "result": $Result/Retry.grab_focus()
    else:
        var focus = get_viewport().gui_get_focus_owner()
        if focus: focus.release_focus()
func _refresh_continue():
    var valid = disk.load_checkpoint()
    $Main/Continue.disabled = not valid.success
    if valid.success:
        $Main/Status.text = "온전한 체크포인트 · "+("백업에서 복원 가능" if valid.source=="backup" else "이어하기 가능")
    else: $Main/Status.text = valid.reason
func request_new_run():
    if disk.load_checkpoint().success: $OverwriteDialog.popup_centered(Vector2i(560,180))
    else: _open_briefing()
func _open_briefing():
    if _guard_unsaved_state(): return
    session = null
    practice_stage = 0
    _show_page("briefing")
    _refresh_mode()
func _refresh_mode():
    $Briefing/Standard.text = ("✓ " if difficulty=="STANDARD" else "")+"표준 · STANDARD"
    $Briefing/Relaxed.text = ("✓ " if difficulty=="RELAXED" else "")+"여유 · 준비시간 1.25배"
func start_run(mode: String = "STANDARD", seed_value: int = 9112026):
    if _guard_unsaved_state(): return
    difficulty = mode
    run_seed = seed_value
    practice_stage = 0
    var unique_id = "live-"+Crypto.new().generate_random_bytes(16).hex_encode()
    session = Session.new(mode,seed_value,unique_id)
    _reset_view()
    _show_page("battle")
    var saved=checkpoint()
    refresh()
    if not saved.success: _show_save_failure("START",saved.reason)
func retry_run():
    if _guard_unsaved_state(): return
    if practice_stage > 0: begin_practice(practice_stage)
    else: start_run(difficulty,run_seed)
func _reset_view():
    inputs.clear()
    chain_selected = Vector2i(-1,-1)
    chain_cursor = Vector2i.ZERO
    _clock_ns = 0
    _autosave_us = 0
    pose_time_us = 0
    _impact_us = 0
    _hurt_us = 0
    _portrait_hurt_us = 0
    _message = ""
    _last_line_receipt.clear()
    _reported_safety_chains.clear()
func continue_run():
    if _guard_unsaved_state(): return
    var saved = disk.load_checkpoint()
    if not saved.success:
        $Main/Status.text = saved.reason
        return
    var restored = Session.new()
    if not restored.restore(saved.snapshot):
        $Main/Status.text = "전체 기록 검증 실패 · 새 도전을 선택하세요."
        return
    session = restored
    difficulty = session.encounter_mode
    # The original shape RNG seed is stored by the model as a decimal string.
    run_seed = int(saved.snapshot.line.shape_seed)
    practice_stage = 0
    _reset_view()
    _clock_ns = saved.clock_remainder_ns
    _show_page("battle")
    if session.combat.outcome != "RUNNING":
        _show_result(false,false)
    else:
        pause_game("체크포인트를 복원했습니다. 입력 선택을 해제하고 전체 정지로 시작합니다.")
        refresh()
func checkpoint() -> Dictionary:
    if session == null or practice_stage > 0: return {"success":false,"reason":"연습은 일반 이어하기를 덮어쓰지 않습니다."}
    return disk.save_session(session,_clock_ns)
func return_to_main():
    if _guard_unsaved_state(): return
    if session: session.command("pause")
    session = null
    practice_stage = 0
    _show_page("main")
    _refresh_continue()
func _exit_battle():
    if _guard_unsaved_state(): return
    if not session.can_checkpoint():
        return_to_main()
        return
    if practice_stage > 0:
        return_to_main()
        return
    var saved = checkpoint()
    if saved.success: return_to_main()
    else: $PausePanel/Status.text = "저장하지 못했습니다: "+saved.reason
func _close_requested():
    if _guard_unsaved_state(): return
    if page == "battle":
        pause_game("종료 요청 · 기록을 보존하고 메인으로 이동한 뒤 종료하세요.")
    else: get_tree().quit()
func pause_game(reason: String = ""):
    if session == null: return
    session.command("pause")
    inputs.clear()
    _practice_saw_pause = true
    $PausePanel/Status.text = reason if not reason.is_empty() else "ETA · 퍼즐 · 파동 · 자세 타이머가 정지했습니다."
    if _blocking_modal()!=null:
        if not reason.is_empty(): _preserve_external_pause()
        _sync_modal_boundary()
        return
    $PausePanel.show()
    var stable: bool = session.can_checkpoint()
    if practice_stage > 0:
        var ordinary_checkpoint_exists := bool(disk.load_checkpoint().success)
        $PausePanel/Main.text = "연습 저장 안 함 · 일반 체크포인트 유지 후 메인" if ordinary_checkpoint_exists else "연습 저장 안 함 · 메인"
        $PausePanel/Checkpoint.text = "연습 상태는 저장하지 않습니다.\n"+("기존 일반 체크포인트는 그대로 유지됩니다." if ordinary_checkpoint_exists else "일반 체크포인트를 새로 만들지 않습니다.")
    else:
        $PausePanel/Main.text = "체크포인트 보존 후 메인" if stable else "직전 안정 체크포인트로 메인"
        $PausePanel/Checkpoint.text = "현재 전체 상태를 저장할 수 있습니다." if stable else "연쇄 진행 중: 부분 저장하지 않습니다. 계속하거나 직전 온전한 기록으로 돌아갑니다."
    _sync_modal_boundary()
    refresh()
func resume_game():
    if session == null or page!="battle" or _blocking_modal()!=null or not _pending_save_failure.is_empty(): return
    $PausePanel.hide()
    _sync_modal_boundary()
    session.command("resume")
    inputs.clear()
    _last_wall_us = Time.get_ticks_usec()
    var focus = get_viewport().gui_get_focus_owner()
    if focus: focus.release_focus()
    refresh()
func open_details(stage: int = 1):
    if session == null or _blocking_modal()!=null: return
    _details_was_paused = session.combat.paused
    session.command("pause")
    inputs.clear()
    $PausePanel.hide()
    $DetailsPanel.show()
    $DetailsPanel/Title.text = "기술 설명 · 전체 정지"
    $DetailsPanel/Close.text = "설명 닫기 · 이전 정지 상태로"
    $DetailsPanel/Body.tooltip_text = ""
    $DetailsPanel/Body.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $DetailsPanel/Body.text = "T%d은 설명입니다. 자동 발동 단계나 선택 계열을 바꾸지 않습니다.\n\nATK · 균열 베기: 기본 피해 %d + 준비한 공격 가산치\nDEF · 방벽: 현재 미확정 피해 행동의 목표치 %d (큰 값 유지)\nSUP · 응급 회복: HP %d, 최대 HP까지만 회복\n\n연쇄 파동 번호가 단계를 결정하며 7번째 이후에도 T6입니다." % [stage,_rules.skills.ATK[stage-1],_rules.skills.DEF[stage-1],_rules.skills.SUP[stage-1]]
    _sync_modal_boundary()
func close_details():
    if not $DetailsPanel.visible or $Options.visible or $SaveFailurePanel.visible: return
    $DetailsPanel.hide()
    _sync_modal_boundary()
    if _details_was_paused: pause_game()
    else: resume_game()

func open_options():
    if _blocking_modal()!=null: return
    options_draft = options.duplicate(true)
    _options_return = page
    _options_was_paused = session != null and session.combat.paused
    if session: session.command("pause")
    inputs.clear()
    $PausePanel.hide()
    $Options.show()
    $Options/effectsLevel.set_value_no_signal(options_draft.audio.effects)
    $Options/musicLevel.set_value_no_signal(options_draft.audio.music)
    _refresh_options()
    _sync_modal_boundary()
func close_options(save_changes: bool):
    if not $Options.visible or $SaveFailurePanel.visible: return
    inputs.cancel_capture()
    if save_changes:
        if not disk.save_options(options_draft):
            $Options/Status.text = "설정 저장 실패 · 변경 전 설정은 유지됩니다."
            return
        options = options_draft.duplicate(true)
    inputs.configure(options)
    _refresh_control_guidance()
    _apply_font()
    $Options.hide()
    _sync_modal_boundary()
    if _options_return == "battle":
        if _options_was_paused: pause_game()
        else: resume_game()
    elif _options_return == "main": $Main/Settings.grab_focus()
func _toggle_font():
    options_draft.font_scale = 125 if int(options_draft.font_scale)==100 else 100
    _refresh_options()
func _toggle_motion():
    options_draft.reduced_motion = not options_draft.reduced_motion
    _refresh_options()
func _refresh_options():
    $Options/FontScale.text = "글꼴 크기: %d%%" % options_draft.font_scale
    $Options/Motion.text = "연출 감소: "+("켜짐" if options_draft.reduced_motion else "꺼짐")
    _refresh_mapping_actions()
func _mapping_group() -> String:
    return "keyboard_mapping" if $Options/Device.selected==0 else "gamepad_mapping"
func _refresh_mapping_actions():
    var action: OptionButton = $Options/Action
    action.clear()
    var labels={"left":"왼쪽 이동","right":"오른쪽 이동","up":"위쪽 커서","down":"아래 / 소프트드롭","rotate_left":"왼쪽 회전","rotate_right":"오른쪽 회전","hard_drop":"즉시 낙하","hold":"HOLD 보관","accept":"선택 / 패드 낙하","cancel":"취소 / 패드 HOLD","switch":"보드 전환","atk":"ATK 공격 계열","def":"DEF 방어 계열","sup":"SUP 치유 계열","pause":"전체 일시정지","details":"읽기 전용 기술 설명","category_next":"다음 계열"}
    for key in options_draft[_mapping_group()]:
        action.add_item(labels.get(key,key))
        action.set_item_metadata(action.item_count-1,key)
    _refresh_mapping_label()
func _refresh_mapping_label():
    var action = String($Options/Action.get_item_metadata($Options/Action.selected))
    if action.is_empty(): return
    var group = _mapping_group()
    var names := inputs.binding_label(action,group,true,options_draft)
    $Options/Binding.text = $Options/Action.get_item_text($Options/Action.selected)+" : "+names
func _begin_remap():
    inputs.begin_capture(_mapping_group(),String($Options/Action.get_item_metadata($Options/Action.selected)))
    $Options/Status.text = "새 입력을 누르세요. 취소 버튼은 현재 지정을 유지합니다."
func _reset_mappings():
    var defaults = Disk.default_options()
    options_draft.keyboard_mapping = defaults.keyboard_mapping
    options_draft.gamepad_mapping = defaults.gamepad_mapping
    inputs.cancel_capture()
    _refresh_mapping_actions()
func _apply_font():
    for node in _labels:
        node.add_theme_font_size_override("font_size",int(round(float(node.get_meta("base_font",18))*float(options.font_scale)/100.0)))

func _process(_delta: float):
    _pump_wall()
func _pump_wall():
    var now = Time.get_ticks_usec()
    var elapsed = maxi(0,now-_last_wall_us)
    _last_wall_us = now
    if elapsed > 0: advance_seconds(float(elapsed)/1000000.0)
func advance_seconds(delta: float):
    if session == null or page != "battle" or session.combat.paused or session.combat.outcome != "RUNNING" or _blocking_modal()!=null: return
    if delta < 0.0 or not is_finite(delta): return
    # Integer nanosecond carry prevents repeated sub-microsecond frame loss.
    _clock_ns += roundi(delta*1000000000.0)
    # Deliberately truncate whole microseconds; the remainder stays in _clock_ns.
    @warning_ignore("integer_division")
    var remaining: int = _clock_ns/1000
    _clock_ns %= 1000
    while remaining > 0 and session.combat.outcome=="RUNNING" and not session.combat.paused:
        var step = mini(remaining,inputs.next_repeat_us())
        if not session.training_boss_frozen: step = mini(step,session.combat.eta_us)
        if session.chain.resolving: step = mini(step,session.chain.next_wave_remaining_us)
        if step <= 0: break
        pose_time_us += step
        _impact_us = maxi(0,_impact_us-step)
        _hurt_us = maxi(0,_hurt_us-step)
        _portrait_hurt_us = maxi(0,_portrait_hurt_us-step)
        _events(session.tick(step))
        remaining -= step
        for action in inputs.elapse(step): _action(action)
        _autosave_us += step
    if _autosave_us >= 5000000 and session.can_checkpoint() and practice_stage==0:
        var saved = checkpoint()
        _autosave_us = 0
        if not saved.success: pause_game("자동안전저장 실패: "+saved.reason)
    refresh()
    if session != null and session.combat.outcome != "RUNNING": _show_result()

func dispatch(action: String, args: Dictionary = {}) -> Dictionary:
    if session == null: return {"success":false,"reason":"NO_SESSION"}
    var result: Dictionary = session.command(action,args)
    _events(result.get("events",[]))
    if not result.success: _message = String(result.reason)
    elif not String(result.get("reason","")).is_empty(): _message = String(result.reason)
    else: _message = ""
    if action=="switch" and result.success:
        inputs.clear()
        chain_selected = Vector2i(-1,-1)
    refresh()
    if session.combat.outcome!="RUNNING": _show_result()
    return result
func _switch_to(workspace: String):
    _pump_wall()
    if session != null and session.mode != workspace: dispatch("switch")
func _events(events: Array):
    for event in events:
        if not event.get("success",false): continue
        match event.get("effect",""):
            "ENEMY_ACTION_RESOLVED":
                if int(event.damage)>0: _impact_us = 360000
                if int(event.damage_to_hp)>0: _portrait_hurt_us = 400000
                _message = "적 행동 해결 · HP 피해 %d / 방벽 %d / 방어도 %d" % [event.damage_to_hp,event.ward_absorbed,event.armor_absorbed]
            "ATK_DAMAGE":
                if int(event.damage_applied)>0: _hurt_us = 100000
            "LINE_RESOURCES_APPLIED":
                _last_line_receipt = event.duplicate(true)
                _message = "LINE 검 %d · 방패 %d · 하트 %d · 시계 %d" % [event.counts.A,event.counts.D,event.counts.H,event.counts.T]
            "CHAIN_WAVE_RESOLVED":
                if event.get("safety_recovery",false):
                    var key="%s:chain:%d"%[session.run_id,session.chain.chain_id]
                    if not _reported_safety_chains.has(key):
                        _reported_safety_chains[key]=true
                        var record={"run_id":session.run_id,"chain_id":session.chain.chain_id,"wave":event.wave,"reason":"MAX_WAVES_REACHED"}
                        print("[R2 safety] "+JSON.stringify(record))
                        diagnostic_recorded.emit(record)
            "LINE_TOPOUT_DAMAGE": _message = "LINE 넘침 · HP %d 손실"%event.damage_applied
func _input(event: InputEvent):
    if inputs == null or options == null: return
    if event is InputEventKey and event.echo: return
    if _top_modal()!=null: _sync_modal_boundary()
    _pump_wall()
    var intent = inputs.event_intent(event)
    if intent.is_empty(): return
    if intent.get("capture",false):
        var result = Disk.remap(options_draft,intent.group,intent.action,intent.code)
        $Options/Status.text = "재지정 완료 · 저장하면 적용됩니다." if result.success else result.reason
        if result.success: inputs.cancel_capture()
        _refresh_mapping_label()
        get_viewport().set_input_as_handled()
        return
    _refresh_control_guidance()
    var action = String(intent.action)
    if $SaveFailurePanel.visible:
        inputs.clear()
        return
    if $Options.visible:
        inputs.clear()
        if action in ["pause","cancel"]: close_options(false); get_viewport().set_input_as_handled()
        return
    if $DetailsPanel.visible:
        inputs.clear()
        if action in ["pause","cancel","details"]:
            close_details()
            get_viewport().set_input_as_handled()
        return
    if page != "battle":
        inputs.clear()
        return
    if action=="pause" or (action=="cancel" and session.combat.paused):
        if session.combat.paused: resume_game()
        else: pause_game()
    elif session.combat.paused:
        inputs.clear()
        return
    elif action=="details": open_details(1)
    else: _action(action,bool(intent.get("gamepad",false)))
    get_viewport().set_input_as_handled()
func _action(action: String, gamepad: bool = false):
    if session == null or session.combat.paused or session.combat.outcome!="RUNNING": return
    if action in ["left","right","up","down"] and session.mode=="CHAIN":
        var directions = {"left":Vector2i.LEFT,"right":Vector2i.RIGHT,"up":Vector2i.UP,"down":Vector2i.DOWN}
        chain_cursor = (chain_cursor+directions[action]).clamp(Vector2i.ZERO,Vector2i(7,7))
        refresh()
        return
    match action:
        "left": dispatch("move",{"dx":-1})
        "right": dispatch("move",{"dx":1})
        "down": dispatch("soft_drop")
        "rotate_left": dispatch("rotate",{"direction":-1})
        "rotate_right": dispatch("rotate",{"direction":1})
        "hard_drop": dispatch("hard_drop")
        "hold": dispatch("hold")
        "accept":
            if session.mode=="CHAIN": _click_cell(chain_cursor)
            elif gamepad: dispatch("hard_drop")
        "cancel":
            if session.mode=="CHAIN": chain_selected=Vector2i(-1,-1); refresh()
            else: dispatch("hold")
        "switch": dispatch("switch")
        "atk": dispatch("category",{"category":"ATK"})
        "def": dispatch("category",{"category":"DEF"})
        "sup": dispatch("category",{"category":"SUP"})
        "category_next":
            var categories = ["ATK","DEF","SUP"]
            dispatch("category",{"category":categories[(categories.find(session.selected_category)+1)%3]})
func _click_cell(cell: Vector2i):
    _pump_wall()
    if session == null or session.mode!="CHAIN" or session.combat.paused or session.chain.resolving: return
    chain_cursor = cell
    if chain_selected == cell: chain_selected = Vector2i(-1,-1)
    elif chain_selected == Vector2i(-1,-1): chain_selected = cell
    else:
        var from = chain_selected
        chain_selected = Vector2i(-1,-1)
        dispatch("chain_swap",{"from":[from.x,from.y],"to":[cell.x,cell.y]})
    refresh()
func _focus_lost():
    inputs.clear()
    if session != null and page=="battle":
        _preserve_external_pause()
        pause_game("창 포커스를 잃어 전체 정지했습니다.")
func device_connection_changed(_device: int, connected: bool):
    inputs.clear()
    if session == null or page!="battle": return
    _preserve_external_pause()
    pause_game("조작 장치가 다시 연결되었습니다. 계속을 선택하세요." if connected else "조작 장치 연결이 끊겼습니다. 전체 정지했습니다.")

func _preserve_external_pause():
    if $DetailsPanel.visible: _details_was_paused=true
    if $Options.visible: _options_was_paused=true

func refresh():
    if session == null or not has_node("Battle"): return
    $Battle/Puzzle/Line.visible = session.mode=="LINE"
    $Battle/Puzzle/Chain.visible = session.mode=="CHAIN"
    $Battle/Puzzle/Line.modulate.a = 0.55 if session.combat.paused else 1.0
    $Battle/Puzzle/Chain.modulate.a = 0.55 if session.combat.paused else 1.0
    _render_line()
    _render_chain()
    var combat = session.combat
    var current: Dictionary = combat.current_action()
    var next: Dictionary = combat.next_action()
    $Battle/Combat/Stage/HP.text = "균열 파괴자   HP %d / %d" % [combat.boss_hp,_source.encounter.boss_hp]
    $Battle/Combat/Stage/HealthBar.value=combat.boss_hp
    $Battle/Combat/Threat/Current.text = "현재 · "+current.label
    $Battle/Combat/Threat/Icon.texture = assets.texture("R1-ICONS","heavy" if current.id=="slam" else "strike")
    $Battle/Combat/Threat/Icon.visible = int(current.damage)>0
    $Battle/Combat/Threat/Damage.text = ("직접 피해 %d\n현재 행동 방벽 적용"%current.damage) if int(current.damage)>0 else "공격 없음\n균열핵 안정"
    $Battle/Combat/Threat/ETA.text = "%.1f초"%(float(combat.eta_us)/1000000.0)
    $Battle/Combat/Threat/Extension.text = "연장 %.2f / 3초"%(float(combat.extension_us)/1000000.0)
    $Battle/Combat/Threat/Next.text = "다음 · %s\n피해 %d\n순서 예고" % [next.label,next.damage]
    $Battle/Combat/PlayerHUD/HP.text = "HP %d / 100    방어도 %d" % [combat.hp,combat.armor]
    $Battle/Combat/PlayerHUD/Resources.text = "다음 공격 +%d    현재 방벽 %d" % [combat.attack_bank,combat.ward]
    var portrait = "neutral"
    if combat.outcome=="VICTORY": portrait="victory"
    elif combat.outcome=="DEFEAT": portrait="defeat"
    elif _portrait_hurt_us>0: portrait="hurt"
    $Battle/Combat/PlayerHUD/Portrait.texture=assets.texture("R1-PORTRAIT",portrait)
    _render_skills()
    _render_pose()
    _render_practice()
func _render_line():
    var receipt: Label=$Battle/Puzzle/Line/Receipt
    receipt.text="최근 LINE 보상\n아직 없음"
    if not _last_line_receipt.is_empty():
        var event=_last_line_receipt
        var unapplied=int(event.time_requested_us)-int(event.time_applied_us)
        var reason="전체 적용" if String(event.time_reason).is_empty() else _target_reason_text(String(event.time_reason))
        receipt.text="최근 LINE 보상\n검 %d / 방패 %d\n하트 %d / 시계 %d\n\n시계 결과\n적용 +%.3f초\n미적용 %.3f초\n%s"%[event.counts.A,event.counts.D,event.counts.H,event.counts.T,float(event.time_applied_us)/1000000.0,float(unapplied)/1000000.0,reason]
    var rows: Array = session.line.rows()
    for y in range(20):
        for x in range(10):
            var symbol: String = rows[y][x]
            _line_cells[y*10+x].texture = null if symbol=="." else assets.tile(symbol)
    for kind in ["active","ghost"]:
        var coords: Array = session.line.active_cells() if kind=="active" else session.line.ghost_cells()
        var visuals: Array = _active_cells if kind=="active" else _ghost_cells
        for i in range(4):
            var visual: TextureRect = visuals[i]
            visual.visible = i<coords.size() and coords[i][1]>=4
            if i<coords.size():
                visual.position=Vector2(coords[i][0]*26,(coords[i][1]-4)*26)
                visual.texture=assets.tile(session.line.active_pair().resource)
    var pairs: Array = [session.line.hold_pair()]
    pairs.append_array(session.line.next_queue)
    for i in range(6):
        var pair: Dictionary=pairs[i]
        var coords: Array = _catalog.get_cells(pair.shape,0)
        for j in range(4):
            var visual: TextureRect = _preview_cells[i][j]
            visual.visible=j<coords.size()
            if j<coords.size():
                visual.position=Vector2(10+coords[j].x*13,29+coords[j].y*13)
                visual.texture=assets.tile(pair.resource)
        if i==0: $Battle/Puzzle/Line/Previews/Hold.modulate.a=1.0 if session.line.hold_available else 0.55
func _render_chain():
    var rows: Array=session.chain.rows()
    var matched: Array=session.chain.matched_cells()
    for y in range(8):
        for x in range(8):
            var cell: Button=_chain_cells[y*8+x]
            cell.get_node("Art").texture=assets.tile(rows[y][x])
            var point=Vector2i(x,y)
            var style=_cell_styles[2 if point==chain_selected else (1 if point==chain_cursor else 0)]
            cell.add_theme_stylebox_override("normal",style)
            cell.add_theme_stylebox_override("disabled",style)
            cell.disabled=session.chain.resolving or session.combat.paused
            cell.get_node("Art").modulate.a=0.55 if [x,y] in matched else 1.0
    $Battle/Puzzle/Chain/State.text = ("%s 고정 · C%d · 입력 잠금%s" % [session.chain.category_snapshot,session.chain.wave_index," · 전환 예약" if not session.queued_workspace.is_empty() else ""]) if session.chain.resolving else "인접 두 칸 선택 · 같은 칸은 취소"
    if not _message.is_empty() and not session.chain.resolving: $Battle/Puzzle/Chain/State.text=_message
func _render_skills():
    var category: String=session.chain.category_snapshot if session.chain.resolving else session.selected_category
    var stage: int=mini(session.chain.wave_index+1,6) if session.chain.resolving else 1
    for key in ["ATK","DEF","SUP"]:
        var button: Button=get_node("Battle/Combat/SkillDock/"+key)
        button.disabled=session.chain.resolving or session.combat.paused
        button.text=("✓ " if key==category else "")+key+" "+{"ATK":"공격","DEF":"방어","SUP":"치유"}[key]
        button.tooltip_text="연쇄가 끝날 때까지 "+category+" 고정" if session.chain.resolving else "다음 연쇄의 계열 선택"
    var power=int(_rules.skills[category][stage-1])
    var effect=""
    if category=="ATK": effect="기본 피해 %d + 가산 %d"%[power,session.combat.attack_bank]
    elif category=="DEF": effect="방벽 목표 %d · 현재 %d 유지"%[power,session.combat.ward]
    else: effect="회복 %d · HP 상한까지"%power
    $Battle/Combat/SkillDock/Next.text="다음 %s T%d · %s"%[category,stage,effect]
    if category=="DEF":
        var reason=session.combat.def_target_reason()
        var target="방벽 %d · 대상 있음"%power if reason.is_empty() else "무효 예고: "+_target_reason_text(reason)
        $Battle/Combat/SkillDock/Next.text="DEF T%d %s · 발동 시 무효 가능"%[stage,target]
    $Battle/Combat/SkillDock/NextIcon.texture=assets.texture("R1-ICONS",{"ATK":"strike","DEF":"ward","SUP":"recover"}[category])
    var last: Dictionary=session.last_cast
    var recent="최근: 없음 · 연쇄 시작 전 계열 선택"
    if not last.is_empty():
        var result=""
        match last.effect:
            "ATK_DAMAGE": result="실제 피해 %d"%last.damage_applied
            "DEF_WARD": result="현재 방벽 %d"%last.ward_after
            "DEF_NO_TARGET": result="대상 없음 · "+_target_reason_text(String(last.reason))
            "SUP_HEAL": result="실제 회복 %d"%last.healing_applied
        recent="최근 %s T%d · %s"%[last.category,last.stage,result]
    $Battle/Combat/SkillDock/Recent.text=recent
func _target_reason_text(reason: String) -> String:
    return {"ACTION_FINISHED":"행동 종료","ACTION_COMMITTED":"행동 확정","NO_DAMAGE_ACTION":"휴식","EXTENSION_CAP_REACHED":"상한 도달"}.get(reason,reason)
func _render_pose():
    var combat=session.combat
    var action: Dictionary=combat.current_action()
    boss_pose="idle"
    if combat.boss_hp==0: boss_pose="defeat"
    elif _impact_us>240000: boss_pose="impact"
    elif int(action.damage)>0 and combat.eta_us<=roundi(float(action.anticipation)*1000000.0): boss_pose="anticipation"
    elif _impact_us>0 or int(action.damage)==0: boss_pose="recovery"
    elif _hurt_us>0: boss_pose="hurt"
    var boss: TextureRect=$Battle/Combat/Stage/BodyClip/BossVisual
    boss.texture=assets.texture("R2-BOSS",boss_pose)
    boss.scale=Vector2.ONE
    boss.position=Vector2.ZERO
    if not options.reduced_motion:
        if boss_pose=="idle": boss.scale.y=1.0+0.006*(1.0-cos(TAU*float(pose_time_us)/2400000.0))
        elif boss_pose=="impact": boss.position.x=4.0*sin(TAU*float(_impact_us)/120000.0)

func begin_practice(stage: int = 1):
    practice_stage=clampi(stage,1,4)
    session=Session.new(difficulty,run_seed,"practice-"+Crypto.new().generate_random_bytes(16).hex_encode())
    session.setup_training("CHAIN" if practice_stage==2 else "LINE",practice_stage<=2)
    _reset_view()
    _practice_start_metrics=session.metrics.duplicate()
    _practice_saw_pause=false
    _show_page("battle")
    refresh()
    _details_was_paused=false
    session.command("pause")
    $DetailsPanel.show()
    $DetailsPanel/Title.text="연습 %d / 4 · 안내 중 전체 정지"%practice_stage
    $DetailsPanel/Body.text=_practice_instruction()
    $DetailsPanel/Body.tooltip_text=_practice_control_tooltip()
    $DetailsPanel/Body.mouse_filter=Control.MOUSE_FILTER_STOP
    $DetailsPanel/Close.text="학습 시작 · 정상 입력 사용"
    _sync_modal_boundary()
func _practice_instruction() -> String:
    match practice_stage:
        1: return "LINE · 자원 준비\n\n공격 I 조각을 오른쪽 네 빈칸에 놓고 %s로 낙하하세요.\n검4 · 방패2 · 하트2 · 시계2를 실제로 소거합니다.\n\n이 단계는 보스 시계만 멈춥니다. 퍼즐은 정상 동작합니다.\n줄을 지운 뒤 실제 자원 변화를 보고 다음 학습을 누르세요." % inputs.paired_binding_phrase("hard_drop")
        2: return "CHAIN · 파동마다 한 번 자동 발동\n\n좌상단을 (0,0)으로 (4,5)와 (5,5)를 교환하세요.\n두 그룹 동시 매치는 C1 한 번, 보충 매치는 C2 한 번입니다.\n타일 직접 보상은 0입니다. 최근 실제 발동을 확인하세요.\n\n이 단계는 보스 시계만 멈춥니다."
        3: return "DEF · 공유 ETA에 대응\n\nLINE으로 방어·시간을 준비하고, %s로 CHAIN에 전환하세요.\n%s로 DEF를 고른 뒤 연쇄를 만들어 현재 행동에 방벽을 묶으세요.\n첫 견제 뒤에는 강타가 옵니다. 실제 방벽 흡수 후 다음 단계로 갑니다.\n\n학습 시작 뒤 보스 시계는 정상 진행합니다." % [inputs.paired_binding_phrase("switch"),inputs.paired_binding_phrase("def")]
        _: return "정지와 보드 전환\n\n%s로 보드를 바꾸고 %s로 전체 정지한 뒤 계속을 선택하세요.\nETA·계열·보드가 그대로 보존되는지 확인하세요.\n\n보스 시계는 정상 진행합니다. 실패하면 이 단계만 다시 시작합니다." % [inputs.paired_binding_phrase("switch"),inputs.paired_binding_phrase("pause")]
func _practice_complete() -> bool:
    if session==null: return false
    match practice_stage:
        1: return int(session.metrics.line_clears)>0
        2: return int(session.metrics.casts)>=2 and not session.chain.resolving
        3: return int(session.metrics.ward_absorbed)>0
        4: return _practice_saw_pause and int(session.metrics.switches)>0
    return false
func _next_practice():
    if not _practice_complete(): return
    if practice_stage<4: begin_practice(practice_stage+1)
    else:
        session.command("pause")
        _show_result(true)
func _render_practice():
    var active=practice_stage>0
    $Battle/PracticeStatus.visible=active and session.mode=="LINE"
    $Battle/PracticeNext.visible=active
    $Battle/PracticeRetry.visible=active
    var state: Label=$Battle/Puzzle/Chain/State
    var help: Label=$Battle/Puzzle/Chain/Role
    if not active:
        state.position=Vector2(18,582)
        state.size=Vector2(580,40)
        help.position=Vector2(18,628)
        help.size=Vector2(580,52)
        help.text="인접 교환 → 파동마다 자동 기술\n타일 직접 보상 없음 · %s 보드 전환" % inputs.binding_phrase("switch")
        state.add_theme_font_size_override("font_size",roundi(18.0*float(options.font_scale)/100.0))
        help.add_theme_font_size_override("font_size",roundi(17.0*float(options.font_scale)/100.0))
        return
    $Battle/PracticeNext.disabled=not _practice_complete()
    $Battle/PracticeStatus.text="연습 %d / 4\n%s\n\n%s"%[practice_stage,"보스 시계 정지" if session.training_boss_frozen else "보스 시계 진행","단계 조건 완료" if _practice_complete() else "안내대로 실제 입력"]
    if session.mode=="CHAIN":
        # Board ends at global590; status/help/buttons occupy separate footer rows.
        state.position=Vector2(18,580)
        state.size=Vector2(580,28)
        help.position=Vector2(18,611)
        help.size=Vector2(580,28)
        state.add_theme_font_size_override("font_size",roundi(16.0*float(options.font_scale)/100.0))
        help.add_theme_font_size_override("font_size",roundi(15.0*float(options.font_scale)/100.0))
        $Battle/PracticeNext.position=Vector2(68,660)
        $Battle/PracticeRetry.position=Vector2(225,660)
        $Battle/PracticeNext.size=Vector2(140,38)
        $Battle/PracticeRetry.size=Vector2(140,38)
        $Battle/Puzzle/Chain/Role.text="연습 %d · %s"%( [practice_stage,"실제 기술 %d회 / 타일 직접 보상 0"%session.metrics.casts])
    else:
        $Battle/PracticeNext.position=Vector2(28,485)
        $Battle/PracticeRetry.position=Vector2(28,533)
        $Battle/PracticeNext.size=Vector2(140,42)
        $Battle/PracticeRetry.size=Vector2(140,42)
func export_playtest_report():
    if page != "result" or session == null or _blocking_modal() != null: return
    var result := PlaytestReport.new().write_snapshot(session.snapshot(),_result_practice_complete,report_directory)
    if result.success:
        $Result/ExportStatus.text = "저장 완료 · 로컬 검수 기록\n" + report_directory
        $Result/ExportReport.tooltip_text = ProjectSettings.globalize_path(result.path.get_base_dir()) + "\n" + result.path.get_file()
        if result.has("warning"):
            $Result/ExportStatus.text += "\n잠금 정리 실패 · 재시도 전 확인 필요"
    else:
        $Result/ExportStatus.text = "저장 실패 · 재도전과 메인은 사용 가능\n" + result.reason
        $Result/ExportReport.tooltip_text = result.reason

func _show_result(training_complete: bool = false, persist: bool = true):
    if session==null: return
    _result_practice_complete = training_complete
    $Result/ExportStatus.text = "검수 기록은 버튼을 눌러 저장합니다.\n개인정보 수집·자동 업로드 없음"
    $Result/ExportReport.tooltip_text = ""
    inputs.clear()
    _show_page("result")
    $Result/Portrait.texture=assets.texture("R1-PORTRAIT","victory" if session.combat.outcome=="VICTORY" or training_complete else "defeat")
    $Result/BossVisual.texture=assets.texture("R2-BOSS","defeat" if session.combat.outcome=="VICTORY" else "idle")
    var metrics: Dictionary=session.metrics
    var outcome="연습 완료" if training_complete else ("승리" if session.combat.outcome=="VICTORY" else "패배")
    $Result/Title.text=("연습 · " if practice_stage>0 else "")+"전투 결과 · "+outcome
    $Result/Metrics.text=("활성 전투 %.2f초 · 최대 연쇄 %d · 자동 발동 %d회\nLINE 소거 %d줄 · 전환 %d회 · 넘침 %d회\n\n실제 피해 %d / 초과 피해 %d\n사용한 공격 가산치 %d / 가산 기여 피해 %d\n방벽 흡수 %d / 방어도 흡수 %d / HP 피해 %d\n실제 회복 %d / 넘친 회복 %d\n시간 연장 %.2f초 / 적용 못 한 시간 %.2f초\n\n%s"%
        [float(session.elapsed_simulation_us)/1000000.0,metrics.max_combo,metrics.casts,
        metrics.line_clears,metrics.switches,metrics.topouts,metrics.damage_dealt,metrics.damage_overkill,
        metrics.attack_bank_consumed,metrics.attack_bank_marginal_damage,metrics.ward_absorbed,metrics.armor_absorbed,
        metrics.hp_damage_taken,metrics.healing_effective,metrics.healing_wasted,
        float(metrics.time_applied_us)/1000000.0,float(metrics.time_wasted_us)/1000000.0,
        "연습 기록은 일반 전투 통계·체크포인트와 분리됩니다." if practice_stage>0 else "같은 seed 재도전은 새 실행 ID와 초기 전투 자원으로 시작합니다."])
    $Result/Retry.text="이 학습 단계 다시" if practice_stage>0 else "같은 seed로 재도전"
    if practice_stage==0 and persist:
        var saved=checkpoint()
        if not saved.success: _show_save_failure("RESULT",saved.reason)

## One pointer/focus boundary for the top panel; gameplay beneath never receives GUI input.
func _blocking_modal() -> Control:
    for path in ["SaveFailurePanel","Options","DetailsPanel"]:
        var panel=get_node_or_null(path) as Control
        if panel!=null and panel.visible: return panel
    return null
func _top_modal() -> Control:
    var blocking=_blocking_modal()
    if blocking!=null: return blocking
    var pause=get_node_or_null("PausePanel") as Control
    return pause if pause!=null and pause.visible else null
func _sync_modal_boundary():
    var top=_top_modal()
    inputs.set_menu_bindings(page!="battle" or top!=null)
    var shield=get_node_or_null("ModalShield") as Control
    if shield==null: return
    shield.visible=top!=null
    if top!=null:
        move_child(shield,get_child_count()-1)
        move_child(top,get_child_count()-1)
    for control in find_children("*","Control",true,false):
        if not control.has_meta("original_focus_mode"):
            control.set_meta("original_focus_mode",control.focus_mode)
        control.focus_mode=int(control.get_meta("original_focus_mode")) if top==null or control==top or top.is_ancestor_of(control) else Control.FOCUS_NONE
    if top==null: return
    var focus=get_viewport().gui_get_focus_owner()
    if focus==null or not top.is_ancestor_of(focus):
        var target={"DetailsPanel":"Close","Options":"Save","PausePanel":"Resume","SaveFailurePanel":"RetrySave"}[String(top.name)]
        top.get_node(target).grab_focus()

func _guard_unsaved_state() -> bool:
    if _pending_save_failure.is_empty(): return false
    _show_save_failure(_pending_save_failure,_save_failure_reason)
    return true
func _show_save_failure(context: String, reason: String):
    _pending_save_failure=context
    _save_failure_reason=reason
    if session: session.command("pause")
    inputs.clear()
    $PausePanel.hide()
    $DetailsPanel.hide()
    $Options.hide()
    $SaveFailurePanel.show()
    var subject="실제 전투 결과" if context=="RESULT" else "새 도전의 초기 상태"
    $SaveFailurePanel/Status.text=subject+"를 저장하지 못했습니다.\n현재 상태는 이 화면에 보존되어 있습니다.\n저장을 다시 시도하거나, 현재 상태를 버리고 이전 기록으로 돌아갈 수 있습니다.\n오류: "+reason
    _sync_modal_boundary()
func _retry_failed_save():
    if _pending_save_failure.is_empty() or session==null: return
    var saved=checkpoint()
    if not saved.success:
        _show_save_failure(_pending_save_failure,saved.reason)
        return
    _pending_save_failure=""
    _save_failure_reason=""
    $SaveFailurePanel.hide()
    _sync_modal_boundary()
    if page=="battle": pause_game("현재 상태 저장을 완료했습니다. 계속을 선택하세요.")
    elif page=="result": $Result/Retry.grab_focus()
func _discard_unsaved_to_main():
    if _pending_save_failure.is_empty(): return
    _pending_save_failure=""
    _save_failure_reason=""
    $SaveFailurePanel.hide()
    _sync_modal_boundary()
    return_to_main()
