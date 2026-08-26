## 60/40 전투 화면에서 한 번에 하나의 퍼즐 workspace만 표시한다.
class_name ProductionBattle
extends Control

const LINE := "LINE"
const CHAIN := "CHAIN"

@onready var _line_view: Control = $MainRow/PuzzleColumn/PuzzleHost/LineBoardView
@onready var _chain_view: Control = $MainRow/PuzzleColumn/PuzzleHost/ChainBoardView
@onready var _current_threat: Label = $MainRow/CombatColumn/ThreatPanel/CurrentTelegraph
@onready var _next_forecast: Label = $MainRow/CombatColumn/ThreatPanel/NextForecast
@onready var _resource_bar: Label = $MainRow/CombatColumn/ResourceBar
@onready var _pause_state: Label = $MainRow/CombatColumn/SkillPanel/PauseState

var _runtime = null
var _workspace_manager = null
var _pause_bridge: SimulationPauseBridge = null
var _selected_skill_lane := ""
var _selected_chain_cell := Vector2i(-1, -1)

func _ready() -> void:
	$MainRow/PuzzleColumn/ModeBar/LineButton.pressed.connect(func(): _request_workspace(LINE))
	$MainRow/PuzzleColumn/ModeBar/ChainButton.pressed.connect(func(): _request_workspace(CHAIN))
	$MainRow/PuzzleColumn/ModeBar/SkillButton.pressed.connect(_toggle_skill)
	$MainRow/CombatColumn/SkillPanel/Attack.pressed.connect(func(): select_skill_category("ATTACK"))
	$MainRow/CombatColumn/SkillPanel/Defense.pressed.connect(func(): select_skill_category("DEFENSE"))
	$MainRow/CombatColumn/SkillPanel/Support.pressed.connect(func(): select_skill_category("SUPPORT"))
	for tier in range(1, 7):
		get_node("MainRow/CombatColumn/SkillPanel/Tier%d" % tier).pressed.connect(func(): select_skill_tier(tier))
	$MainRow/CombatColumn/SkillPanel/UseButton.pressed.connect(_use_selected_skill)
	var bootstrap = load("res://src/production/session/production_battle_bootstrap.gd").new()
	var result: Dictionary = bootstrap.build_runtime()
	_runtime = result.get("runtime")
	_workspace_manager = result.get("workspace_manager")
	var pause_controller = result.get("pause_controller")
	if pause_controller != null:
		_pause_bridge = SimulationPauseBridge.new()
		add_child(_pause_bridge)
		_pause_bridge.bind_controller(pause_controller)
	set_active_workspace(LINE)
	_refresh_runtime_labels()

func _process(delta: float) -> void:
	if _runtime == null:
		return
	_runtime.tick(delta)
	if _workspace_manager != null:
		set_active_workspace(_workspace_manager.active_workspace())
		_line_view.bind_line_session(_workspace_manager.line_session)
		_chain_view.bind_chain_session(_workspace_manager.chain_session)
	_refresh_runtime_labels()

func set_active_workspace(workspace: String) -> bool:
	if workspace != LINE and workspace != CHAIN:
		return false
	_line_view.visible = workspace == LINE
	_chain_view.visible = workspace == CHAIN
	return true

func _request_workspace(workspace: String) -> void:
	if _runtime != null:
		_runtime.process_player_command({"kind": "SWITCH_WORKSPACE", "target": workspace})

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("workspace_line"):
		_request_workspace(LINE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("workspace_chain"):
		_request_workspace(CHAIN)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_skill"):
		_toggle_skill()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_game") and _runtime != null:
		_runtime.process_player_command({"kind": "TOGGLE_SYSTEM_PAUSE"})
		_refresh_runtime_labels()
		get_viewport().set_input_as_handled()
	else:
		for action_name in ["line_left", "line_right", "line_soft_drop", "line_rotate_cw", "line_rotate_ccw", "line_hold", "line_hard_drop"]:
			if event.is_action_pressed(action_name):
				_handle_line_action(action_name)
				get_viewport().set_input_as_handled()
				return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_chain_click(event.position)

func _handle_line_action(action_name: String) -> bool:
	if _runtime == null or _workspace_manager == null or _runtime.is_simulation_paused() or _workspace_manager.active_workspace() != LINE:
		return false
	var line_session = _workspace_manager.line_session
	if line_session == null:
		return false
	match action_name:
		"line_left":
			return line_session.try_move(Vector2i.LEFT)
		"line_right":
			return line_session.try_move(Vector2i.RIGHT)
		"line_soft_drop":
			return line_session.try_move(Vector2i.DOWN)
		"line_rotate_cw":
			return line_session.try_rotate(1)
		"line_rotate_ccw":
			return line_session.try_rotate(-1)
		"line_hold":
			return line_session.try_hold()
		"line_hard_drop":
			return line_session.hard_drop_and_commit() != null
	return false

func _handle_chain_click(global_position: Vector2) -> bool:
	if _runtime == null or _workspace_manager == null or _runtime.is_simulation_paused() or _workspace_manager.active_workspace() != CHAIN:
		return false
	var local_position := global_position - _chain_view.global_position
	var selected: Vector2i = _chain_view.cell_at_local_position(local_position)
	if selected.x < 0:
		_selected_chain_cell = Vector2i(-1, -1)
		_chain_view.set_selected_cell(_selected_chain_cell)
		return false
	if _selected_chain_cell.x < 0:
		_selected_chain_cell = selected
		_chain_view.set_selected_cell(selected)
		return true
	var first := _selected_chain_cell
	_selected_chain_cell = Vector2i(-1, -1)
	_chain_view.set_selected_cell(_selected_chain_cell)
	if abs(first.x - selected.x) + abs(first.y - selected.y) != 1:
		return false
	return bool(_workspace_manager.chain_session.begin_swap(first, selected).get("accepted", false))

func _toggle_skill() -> void:
	if _runtime == null:
		return
	if _runtime.is_skill_open():
		_runtime.close_skill_without_use()
	else:
		_runtime.open_skill()
	_refresh_runtime_labels()

func select_skill_category(category: String) -> bool:
	if _runtime == null or not _runtime.is_simulation_paused():
		return false
	_selected_skill_lane = category
	return _runtime.select_skill_category(category)

func select_skill_tier(tier: int) -> Dictionary:
	if _runtime == null or _selected_skill_lane == "" or tier < 1 or tier > 6:
		return {"selected": false, "reason": "INVALID_SELECTION"}
	var prefix: String = String({"ATTACK": "atk", "DEFENSE": "def", "SUPPORT": "sup"}.get(_selected_skill_lane, ""))
	if prefix == "":
		return {"selected": false, "reason": "INVALID_SELECTION"}
	var ids := {"atk": ["quick_cut", "sweeping_arc", "rift_breach", "crushing_strike", "suppressive_break", "execution_edge"], "def": ["guard", "fortify", "counter", "bulwark", "rift_ward", "last_bastion"], "sup": ["second_wind", "rally", "haste", "mark_weakness", "rift_seal", "battle_trance"]}
	return _runtime.select_skill_technique("%s_t%d_%s" % [prefix, tier, ids[prefix][tier - 1]])

func _use_selected_skill() -> void:
	if _runtime != null and _runtime.is_simulation_paused():
		_runtime.use_selected_skill()
	_refresh_runtime_labels()

func _refresh_runtime_labels() -> void:
	if _runtime == null:
		_current_threat.text = "CURRENT THREAT · unavailable"
		return
	var snapshot: Dictionary = _runtime.snapshot()
	_current_threat.text = "CURRENT THREAT · ETA %.1fs" % float(snapshot.get("enemy_eta_seconds", 0.0))
	_next_forecast.text = "NEXT FORECAST · realtime authored schedule"
	_resource_bar.text = "HP %d / 100    ENERGY %d    STOCK %d / 6" % [int(snapshot.get("player_hp", 0)), int(snapshot.get("player_energy", 0)), int(snapshot.get("player_stock", 0))]
	if _runtime.is_skill_open():
		_pause_state.text = "TACTICAL PAUSE"
	elif bool(snapshot.get("paused", false)):
		_pause_state.text = "SYSTEM PAUSE"
	else:
		_pause_state.text = "COMBAT RUNNING"
