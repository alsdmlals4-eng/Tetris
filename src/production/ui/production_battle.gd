## 50/50 전투 화면에서 한 번에 하나의 퍼즐 workspace만 표시한다.
class_name ProductionBattle
extends Control

const LINE := "LINE"
const CHAIN := "CHAIN"

@onready var _line_view: Control = $MainRow/PuzzleColumn/PuzzleHost/LineBoardView
@onready var _chain_view: Control = $MainRow/PuzzleColumn/PuzzleHost/ChainBoardView
@onready var _current_threat: Label = $MainRow/CombatColumn/ThreatFrame/ThreatPanel/CurrentTelegraph
@onready var _next_forecast: Label = $MainRow/CombatColumn/ThreatFrame/ThreatPanel/NextForecast
@onready var _guided_practice_prompt: Label = $MainRow/CombatColumn/ThreatFrame/ThreatPanel/GuidedPracticePrompt
@onready var _resource_bar: Label = $MainRow/CombatColumn/ResourceFrame/ResourceRow/ResourceBar
@onready var _pause_state: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/PauseState
@onready var _skill_stage_summary: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/SkillStageSummary
@onready var _skill_stage_rail: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/SkillStageRail
@onready var _technique_name: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/SkillDetailCard/TechniqueStack/TechniqueName
@onready var _technique_purpose: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/SkillDetailCard/TechniqueStack/TechniquePurpose
@onready var _technique_cost: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/SkillDetailCard/TechniqueStack/TechniqueCost
@onready var _technique_availability: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/SkillDetailCard/TechniqueStack/TechniqueAvailability
@onready var _retry_button: Button = $MainRow/CombatColumn/SkillFrame/SkillPanel/RetryButton
@onready var _chain_lock_frame: Control = $MainRow/PuzzleColumn/ChainLockFrame
@onready var _chain_lock_keep_button: Button = $MainRow/PuzzleColumn/ChainLockFrame/LockPrompt/KeepButton
@onready var _chain_lock_discard_button: Button = $MainRow/PuzzleColumn/ChainLockFrame/LockPrompt/DiscardButton
@onready var _puzzle_feedback: Label = $MainRow/PuzzleColumn/PuzzleFeedbackFrame/FeedbackStack/PuzzleFeedback
@onready var _chain_feedback: Label = $MainRow/PuzzleColumn/PuzzleFeedbackFrame/FeedbackStack/ChainFeedback
@onready var _vanguard_attack_accent: TextureRect = $MainRow/CombatColumn/CombatStage/VanguardAttackAccent
@onready var _gatebreaker_threat_telegraph: TextureRect = $MainRow/CombatColumn/CombatStage/GatebreakerThreatTelegraph

var _runtime = null
var _workspace_manager = null
var _pause_bridge: SimulationPauseBridge = null
var _selected_skill_lane := ""
var _selected_chain_cell := Vector2i(-1, -1)
var _stage_vfx_elapsed := 0.0
var _vanguard_attack_fx_remaining := 0.0
var _last_chain_feedback := "CHAIN · 3+ in all axes · each wave grows shared Combo"

func _ready() -> void:
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/LineButton.pressed.connect(func(): _request_workspace(LINE))
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/ChainButton.pressed.connect(func(): _request_workspace(CHAIN))
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/SkillButton.pressed.connect(_toggle_skill)
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Attack.pressed.connect(func(): select_skill_category("ATTACK"))
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Defense.pressed.connect(func(): select_skill_category("DEFENSE"))
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Support.pressed.connect(func(): select_skill_category("SUPPORT"))
	$MainRow/CombatColumn/SkillFrame/SkillPanel/ConfirmButton.pressed.connect(_use_selected_skill)
	_retry_button.pressed.connect(_retry_encounter)
	_chain_lock_keep_button.pressed.connect(_confirm_chain_mp_lock)
	_chain_lock_discard_button.pressed.connect(_discard_chain_mp_lock)
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
	_refresh_chain_lock_prompt()
	_refresh_stage_vfx(0.0)

func _process(delta: float) -> void:
	if _runtime == null:
		return
	var events: Array[Dictionary] = _runtime.tick(delta)
	if _workspace_manager != null:
		set_active_workspace(_workspace_manager.active_workspace())
		_line_view.bind_line_session(_workspace_manager.line_session)
		_chain_view.bind_chain_session(_workspace_manager.chain_session)
	_refresh_runtime_labels()
	_refresh_chain_lock_prompt()
	_refresh_puzzle_feedback(events)
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
	return bool(result.get("accepted", false)) or String(result.get("reason", "")) == "NO_MATCH"

func _confirm_chain_mp_lock() -> void:
	if _runtime != null:
		_runtime.confirm_chain_mp_lock()
	_refresh_chain_lock_prompt()

func _discard_chain_mp_lock() -> void:
	if _runtime != null:
		_runtime.discard_chain_mp_lock()
	_refresh_chain_lock_prompt()

func _refresh_chain_lock_prompt() -> void:
	var has_pending_lock := false
	if _workspace_manager != null and _workspace_manager.chain_session != null:
		has_pending_lock = _workspace_manager.chain_session.has_pending_failed_swap()
	_chain_lock_frame.visible = has_pending_lock

func _refresh_puzzle_feedback(events: Array[Dictionary] = []) -> void:
	var line_feedback := "LINE · clear lines for MP"
	if _line_view != null:
		var line_meta: Dictionary = _line_view.get_meta_snapshot()
		var last_clear := String(line_meta.get("last_clear", ""))
		if not last_clear.is_empty():
			line_feedback = "LINE RESULT · %s" % last_clear
	for event in events:
		if String(event.get("kind", "")) == "production_line_resolved":
			line_feedback = "LINE RESULT · %s" % _line_view.format_last_clear(_workspace_manager.line_session.last_line_result)
		elif String(event.get("kind", "")) == "production_chain_resolved":
			var waves: Array = Array(event.get("resource_waves", []))
			_last_chain_feedback = "CHAIN RESOLVE · %d wave%s · COMBO %d" % [waves.size(), "S" if waves.size() != 1 else "", int(_runtime.snapshot().get("player_stock", 0))]
	_puzzle_feedback.text = line_feedback
	_chain_feedback.text = _last_chain_feedback

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
	var preview: Dictionary = _runtime.select_skill_category(category)
	var preview_label: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/ResolvedPreview
	if bool(preview.get("ready", false)):
		preview_label.text = "%s · C%d · MP %d\n%s" % [String(preview.get("display_name", "")), int(preview.get("resolved_stage", 0)), int(preview.get("mp_cost", 0)), "\n".join(PackedStringArray(preview.get("preview_lines", [])))]
	else:
		preview_label.text = "NO READY TECHNIQUE · %s" % String(preview.get("reason", ""))
	_refresh_skill_surface(_runtime.snapshot(), preview)
	return bool(preview.get("selected", false))

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
		return
	var snapshot: Dictionary = _runtime.snapshot()
	var is_terminal: bool = bool(snapshot.get("terminal", false))
	_current_threat.text = "CURRENT THREAT · ETA %.1fs" % float(snapshot.get("enemy_eta_seconds", 0.0))
	_next_forecast.text = "NEXT FORECAST · realtime authored schedule"
	_resource_bar.text = "HP %d / 100    MP %d / 60    COMBO %d / 10" % [int(snapshot.get("player_hp", 0)), int(snapshot.get("player_energy", 0)), int(snapshot.get("player_stock", 0))]
	var guided: Dictionary = Dictionary(snapshot.get("guided_practice", {}))
	_guided_practice_prompt.visible = bool(guided.get("active", false))
	_guided_practice_prompt.text = String(guided.get("prompt", ""))
	_retry_button.visible = is_terminal
	if is_terminal:
		_pause_state.text = "VICTORY" if int(snapshot.get("enemy_hp", 0)) <= 0 else "DEFEAT"
	elif _runtime.is_skill_open():
		_pause_state.text = "TACTICAL PAUSE"
	elif bool(snapshot.get("paused", false)):
		_pause_state.text = "SYSTEM PAUSE"
	else:
		_pause_state.text = "COMBAT RUNNING"
	_refresh_skill_surface(snapshot)

func _refresh_skill_surface(snapshot: Dictionary, resolved_preview: Dictionary = {}) -> void:
	if _runtime == null or not _runtime.has_method("inspect_skill_stage"):
		_skill_stage_summary.text = "COMBO STAGE · unavailable"
		_skill_stage_rail.text = "C1 · C2 · C3 · C4 · C5 · C6 · C7 · C8 · C9 · C10"
		_technique_name.text = "TECHNIQUE PREVIEW · unavailable"
		_technique_purpose.text = "Runtime skill catalog is unavailable."
		_technique_cost.text = ""
		_technique_availability.text = ""
		return
	var current_combo := clampi(int(snapshot.get("player_stock", 0)), 0, 10)
	var preview_stage := maxi(1, current_combo)
	var lane := _selected_skill_lane if not _selected_skill_lane.is_empty() else "DEFENSE"
	var detail: Dictionary = resolved_preview
	var is_resolved_selection := bool(detail.get("ready", false))
	if not is_resolved_selection:
		detail = _runtime.inspect_skill_stage(lane, preview_stage)
	var active_stage := int(detail.get("resolved_stage", detail.get("stage", preview_stage)))
	_skill_stage_summary.text = "COMBO %d / 10 · %s C%d" % [current_combo, "CURRENT" if current_combo > 0 else "NEXT", active_stage]
	_skill_stage_rail.text = _format_stage_rail(active_stage)
	if not bool(detail.get("inspectable", true)) and not is_resolved_selection:
		_technique_name.text = "%s · C%d unavailable" % [lane, active_stage]
		_technique_purpose.text = "The authored technique data is not available for this context."
		_technique_cost.text = ""
		_technique_availability.text = ""
		return
	_technique_name.text = "%s · %s" % [lane, String(detail.get("display_name", "TECHNIQUE"))]
	_technique_purpose.text = " · ".join(PackedStringArray(detail.get("preview_lines", [])))
	_technique_cost.text = "COST · COMBO %d · MP %d" % [int(detail.get("combo_cost", detail.get("opening_combo", active_stage))), int(detail.get("mp_cost", 0))]
	if is_resolved_selection:
		var converted_combo := int(detail.get("converted_combo", 0))
		_technique_availability.text = "RESOLVED C%d · CONFIRM commits%s" % [active_stage, " · fallback converts %d Combo" % converted_combo if converted_combo > 0 else ""]
	else:
		_technique_availability.text = "PREVIEW ONLY · select a category, then CONFIRM. No resource is spent."

func _format_stage_rail(active_stage: int) -> String:
	var cells: Array[String] = []
	for stage in range(1, 11):
		cells.append("◆ C%d" % stage if stage == active_stage else "C%d" % stage)
	return "  ".join(cells)
