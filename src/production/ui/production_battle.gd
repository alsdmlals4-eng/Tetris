## 50/50 전투 화면에서 한 번에 하나의 퍼즐 workspace만 표시한다.
class_name ProductionBattle
extends Control

const LINE := "LINE"
const CHAIN := "CHAIN"

@onready var _line_view: Control = $MainRow/PuzzleColumn/PuzzleHost/LineBoardView
@onready var _chain_view: Control = $MainRow/PuzzleColumn/PuzzleHost/ChainBoardView
@onready var _current_threat: Label = $MainRow/CombatColumn/ThreatFrame/ThreatPanel/CurrentTelegraph
@onready var _next_forecast: Label = $MainRow/CombatColumn/ThreatFrame/ThreatPanel/NextForecast
@onready var _shared_timer_value: Label = $MainRow/CombatColumn/SharedActionFrame/ActionPhaseStack/SharedTimerRow/SharedTimerCore/SharedTimerValue
@onready var _shared_timer_caption: Label = $MainRow/CombatColumn/SharedActionFrame/ActionPhaseStack/SharedTimerRow/SharedTimerCore/SharedTimerCaption
@onready var _current_action_frame: Label = $MainRow/CombatColumn/SharedActionFrame/ActionPhaseStack/SharedTimerRow/CurrentActionFrame
@onready var _next_action_frame: Label = $MainRow/CombatColumn/SharedActionFrame/ActionPhaseStack/SharedTimerRow/NextActionFrame
@onready var _resource_bar: Label = $MainRow/CombatColumn/ResourceFrame/ResourceRow/ResourceBar
@onready var _chain_lock_frame: Control = $MainRow/PuzzleColumn/ChainLockFrame
@onready var _chain_lock_prompt: Label = $MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/Prompt
@onready var _keep_chain_swap_button: Button = $MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/LockActions/KeepSwapButton
@onready var _discard_chain_swap_button: Button = $MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/LockActions/DiscardSwapButton
@onready var _pause_state: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/PauseState
@onready var _retry_button: Button = $MainRow/CombatColumn/SkillFrame/SkillPanel/RetryButton
@onready var _vanguard_attack_accent: TextureRect = $MainRow/CombatColumn/CombatStage/VanguardAttackAccent
@onready var _gatebreaker_threat_telegraph: TextureRect = $MainRow/CombatColumn/CombatStage/GatebreakerThreatTelegraph

var _runtime = null
var _workspace_manager = null
var _pause_bridge: SimulationPauseBridge = null
var _selected_skill_lane := ""
var _selected_chain_cell := Vector2i(-1, -1)
var _stage_vfx_elapsed := 0.0
var _vanguard_attack_fx_remaining := 0.0

func _ready() -> void:
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/LineButton.pressed.connect(func(): _request_workspace(LINE))
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/ChainButton.pressed.connect(func(): _request_workspace(CHAIN))
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/SkillButton.pressed.connect(_toggle_skill)
	_keep_chain_swap_button.pressed.connect(_keep_chain_swap)
	_discard_chain_swap_button.pressed.connect(_discard_chain_swap)
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Attack.pressed.connect(func(): select_skill_category("ATTACK"))
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Defense.pressed.connect(func(): select_skill_category("DEFENSE"))
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Support.pressed.connect(func(): select_skill_category("SUPPORT"))
	for tier in range(1, 7):
		get_node("MainRow/CombatColumn/SkillFrame/SkillPanel/TierGrid/Tier%d" % tier).pressed.connect(func(): select_skill_tier(tier))
	$MainRow/CombatColumn/SkillFrame/SkillPanel/UseButton.pressed.connect(_use_selected_skill)
	_retry_button.pressed.connect(_retry_encounter)
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
	_refresh_stage_vfx(0.0)

func _process(delta: float) -> void:
	if _runtime == null:
		return
	_runtime.tick(delta)
	if _workspace_manager != null:
		set_active_workspace(_workspace_manager.active_workspace())
		_line_view.bind_line_session(_workspace_manager.line_session)
		_chain_view.bind_chain_session(_workspace_manager.chain_session)
	_refresh_runtime_labels()
	_refresh_stage_vfx(delta)

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
	var result: Dictionary = _runtime.try_chain_swap(first, selected)
	_refresh_chain_lock_prompt()
	return bool(result.get("accepted", false))

func _keep_chain_swap() -> void:
	if _runtime != null:
		_runtime.confirm_chain_mp_lock()
	_refresh_chain_lock_prompt()

func _discard_chain_swap() -> void:
	if _runtime != null:
		_runtime.discard_chain_mp_lock()
	_refresh_chain_lock_prompt()

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
	var ids := {"atk": ["first_edge", "rift_snare", "fracture_cut", "shieldbreaker", "severing_drive", "execution_edge"], "def": ["brace", "supply_guard", "riposte_guard", "bulwark", "last_guard", "aegis_relay"], "sup": ["first_aid", "rally_step", "second_wind", "anchor_pulse", "field_mend", "breather"]}
	return _runtime.select_skill_technique("%s_c%d_%s" % [prefix, tier, ids[prefix][tier - 1]])

func _use_selected_skill() -> void:
	if _runtime != null and _runtime.is_simulation_paused():
		var result: Dictionary = _runtime.use_selected_skill()
		if bool(result.get("committed", false)) and _selected_skill_lane == "ATTACK":
			_trigger_vanguard_attack_fx()
	_refresh_runtime_labels()

func _trigger_vanguard_attack_fx() -> void:
	_vanguard_attack_fx_remaining = 0.42
	_vanguard_attack_accent.visible = true
	_vanguard_attack_accent.modulate = Color(1.0, 1.0, 1.0, 0.9)

func _refresh_stage_vfx(delta: float) -> void:
	_stage_vfx_elapsed += maxf(0.0, delta)
	if _vanguard_attack_fx_remaining > 0.0:
		_vanguard_attack_fx_remaining = maxf(0.0, _vanguard_attack_fx_remaining - delta)
		var slash_alpha := 0.9 * (_vanguard_attack_fx_remaining / 0.42)
		_vanguard_attack_accent.visible = slash_alpha > 0.0
		_vanguard_attack_accent.modulate = Color(1.0, 1.0, 1.0, slash_alpha)
	else:
		_vanguard_attack_accent.visible = false
	if _runtime == null:
		_gatebreaker_threat_telegraph.visible = false
		return
	var snapshot: Dictionary = _runtime.snapshot()
	var active_telegraph := not bool(snapshot.get("terminal", false)) and float(snapshot.get("enemy_eta_seconds", 0.0)) > 0.0
	_gatebreaker_threat_telegraph.visible = active_telegraph
	if active_telegraph:
		var pulse := 0.22 + 0.08 * (0.5 + 0.5 * sin(_stage_vfx_elapsed * 3.0))
		_gatebreaker_threat_telegraph.modulate = Color(1.0, 1.0, 1.0, pulse)

func _retry_encounter() -> void:
	get_tree().reload_current_scene()

func _refresh_runtime_labels() -> void:
	if _runtime == null:
		_current_threat.text = "CURRENT THREAT · unavailable"
		_shared_timer_value.text = "--"
		_shared_timer_caption.text = "BOSS / PLAYER ETA"
		_current_action_frame.text = "CURRENT · unavailable"
		_next_action_frame.text = "NEXT · forecast"
		return
	var snapshot: Dictionary = _runtime.snapshot()
	var is_terminal: bool = bool(snapshot.get("terminal", false))
	var eta_seconds := float(snapshot.get("enemy_eta_seconds", 0.0))
	_current_threat.text = "CURRENT THREAT · ETA %.1fs" % eta_seconds
	_next_forecast.text = "NEXT FORECAST · realtime authored schedule"
	_shared_timer_value.text = "%.1f" % eta_seconds
	_shared_timer_caption.text = "BOSS / PLAYER ETA · SAME WINDOW"
	_current_action_frame.text = "CURRENT · ETA %.1fs" % eta_seconds
	_next_action_frame.text = "NEXT · authored forecast"
	_resource_bar.text = "HP %d / 100    MP %d / 60    COMBO %d / 10" % [int(snapshot.get("player_hp", 0)), int(snapshot.get("player_energy", 0)), int(snapshot.get("player_stock", 0))]
	_retry_button.visible = is_terminal
	if is_terminal:
		_pause_state.text = "VICTORY" if int(snapshot.get("enemy_hp", 0)) <= 0 else "DEFEAT"
	elif _runtime.is_skill_open():
		_pause_state.text = "TACTICAL PAUSE"
	elif bool(snapshot.get("paused", false)):
		_pause_state.text = "SYSTEM PAUSE"
	else:
		_pause_state.text = "COMBAT RUNNING"
	_refresh_chain_lock_prompt()

func _refresh_chain_lock_prompt() -> void:
	var pending := false
	var current_mp := 0
	var input_available := _runtime != null
	if input_available and _runtime.has_method("is_simulation_paused"):
		input_available = not _runtime.is_simulation_paused()
	if _workspace_manager != null and _workspace_manager.chain_session != null:
		pending = _workspace_manager.chain_session.has_pending_failed_swap()
	if _runtime != null:
		current_mp = int(_runtime.snapshot().get("player_energy", 0))
	_chain_lock_frame.visible = pending and input_available
	if not pending or not input_available:
		return
	_chain_lock_prompt.text = "NO STRAIGHT 3+ MATCH · COMBO RESET\nKEEP THIS SETUP FOR 1 MP?"
	_keep_chain_swap_button.disabled = current_mp < 1
	_keep_chain_swap_button.text = "KEEP SWAP · 1 MP"
	_discard_chain_swap_button.text = "REVERT SWAP · FREE"
