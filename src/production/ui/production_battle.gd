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
@onready var _tutorial_prompt: Label = $MainRow/CombatColumn/SharedActionFrame/ActionPhaseStack/TutorialPrompt
@onready var _resource_bar: Label = $MainRow/CombatColumn/ResourceFrame/ResourceRow/ResourceBar
@onready var _chain_lock_frame: Control = $MainRow/PuzzleColumn/ChainLockFrame
@onready var _chain_lock_prompt: Label = $MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/Prompt
@onready var _keep_chain_swap_button: Button = $MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/LockActions/KeepSwapButton
@onready var _discard_chain_swap_button: Button = $MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/LockActions/DiscardSwapButton
@onready var _pause_state: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/PauseState
@onready var _retry_button: Button = $MainRow/CombatColumn/SkillFrame/SkillPanel/RetryButton
@onready var _skill_preview: RichTextLabel = $MainRow/CombatColumn/SkillFrame/SkillPanel/SkillPreview
@onready var _confirm_skill_button: Button = $MainRow/CombatColumn/SkillFrame/SkillPanel/ConfirmButton
@onready var _cancel_skill_button: Button = $MainRow/CombatColumn/SkillFrame/SkillPanel/CancelButton
@onready var _timing_feedback: Label = $MainRow/CombatColumn/SkillFrame/SkillPanel/TimingFeedback
@onready var _rules_popup: PopupPanel = $RulesReferencePopup
@onready var _rules_briefing = $RulesReferencePopup/BattleBriefing
@onready var _vanguard_attack_accent: TextureRect = $MainRow/CombatColumn/CombatStage/VanguardAttackAccent
@onready var _gatebreaker_threat_telegraph: TextureRect = $MainRow/CombatColumn/CombatStage/GatebreakerThreatTelegraph
@onready var _gatebreaker_reference: TextureRect = $MainRow/CombatColumn/CombatStage/GatebreakerReference

var _runtime = null
var _workspace_manager = null
var _pause_bridge: SimulationPauseBridge = null
var _selected_skill_lane := ""
var _selected_chain_cell := Vector2i(-1, -1)
var _stage_vfx_elapsed := 0.0
var _vanguard_attack_fx_remaining := 0.0
var _gatebreaker_base_position := Vector2.ZERO
var _gatebreaker_presence_base_captured := false
var _timing_feedback_remaining := 0.0
var _last_timing_feedback: Dictionary = {}

func _ready() -> void:
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/LineButton.pressed.connect(func(): _request_workspace(LINE))
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/ChainButton.pressed.connect(func(): _request_workspace(CHAIN))
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/SkillButton.pressed.connect(_toggle_skill)
	$MainRow/PuzzleColumn/ModeFrame/ModeBar/RulesButton.pressed.connect(_open_rules_reference)
	_keep_chain_swap_button.pressed.connect(_keep_chain_swap)
	_discard_chain_swap_button.pressed.connect(_discard_chain_swap)
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Attack.pressed.connect(func(): select_skill_category("ATTACK"))
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Defense.pressed.connect(func(): select_skill_category("DEFENSE"))
	$MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/Support.pressed.connect(func(): select_skill_category("SUPPORT"))
	_confirm_skill_button.pressed.connect(_use_selected_skill)
	_cancel_skill_button.pressed.connect(_cancel_skill)
	_rules_briefing.dismissed.connect(func(): _rules_popup.hide())
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
	call_deferred("_capture_gatebreaker_presence_base")
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
	if _timing_feedback_remaining > 0.0:
		_timing_feedback_remaining = maxf(0.0, _timing_feedback_remaining - delta)
		if is_zero_approx(_timing_feedback_remaining):
			_timing_feedback.text = ""

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
		var opened: Dictionary = _runtime.open_skill()
		if bool(opened.get("opened", false)):
			_selected_skill_lane = ""
			_skill_preview.text = "[color=#aeb7cb]Select ATK, DEF, or SUP to inspect the current Combo skill.[/color]"
			_confirm_skill_button.disabled = true
	_refresh_runtime_labels()

func select_skill_category(category: String) -> Dictionary:
	if _runtime == null or not _runtime.is_skill_open():
		return {"selected": false, "ready": false, "reason": "SKILL_NOT_OPEN"}
	var preview: Dictionary = _runtime.select_skill_category(category)
	_selected_skill_lane = category if bool(preview.get("selected", false)) else ""
	_skill_preview.text = _format_skill_preview(preview)
	_confirm_skill_button.disabled = not bool(preview.get("ready", false))
	return preview

func _use_selected_skill() -> void:
	if _runtime != null and _runtime.is_simulation_paused():
		var result: Dictionary = _runtime.use_selected_skill()
		if bool(result.get("committed", false)) and _selected_skill_lane == "ATTACK":
			_trigger_vanguard_attack_fx()
		if bool(result.get("committed", false)):
			_confirm_skill_button.disabled = true
			_skill_preview.text = "[color=#8fcfff]Confirmed. Combat time resumes.[/color]"
	_refresh_runtime_labels()

func _cancel_skill() -> void:
	if _runtime != null and _runtime.is_skill_open():
		_runtime.close_skill_without_use()
	_selected_skill_lane = ""
	_confirm_skill_button.disabled = true
	_skill_preview.text = "[color=#aeb7cb]Tactical pause cancelled. Combat time resumes.[/color]"
	_refresh_runtime_labels()

func _open_rules_reference() -> void:
	_rules_briefing.configure(true)
	_rules_popup.popup_centered_ratio(0.9)

func _format_skill_preview(preview: Dictionary) -> String:
	if not bool(preview.get("selected", false)):
		return "[color=#ff8f8f]Skill preview unavailable · %s[/color]" % String(preview.get("reason", "INVALID_SELECTION"))
	if not bool(preview.get("ready", false)):
		return "[color=#ffcc78]Current Combo C%d cannot confirm · %s[/color]" % [int(preview.get("opening_combo", 0)), String(preview.get("reason", "NOT_READY"))]
	var resolved_stage := int(preview.get("resolved_stage", 0))
	var opening_combo := int(preview.get("opening_combo", 0))
	var converted_combo := int(preview.get("converted_combo", 0))
	var lines: Array[String] = []
	lines.append("[b]%s · C%d[/b]" % [String(preview.get("display_name", "Unknown Technique")), resolved_stage])
	lines.append("Target · %s" % _preview_target(Array(preview.get("effects", []))))
	for preview_line in Array(preview.get("preview_lines", [])):
		lines.append("Effect · %s" % String(preview_line))
	if converted_combo > 0:
		lines.append("Fallback · C%d → C%d  (%d Combo converted)" % [opening_combo, resolved_stage, converted_combo])
	else:
		lines.append("Stage · C%d held (no Combo conversion)" % resolved_stage)
	lines.append("Cost · %d MP · %d Combo" % [int(preview.get("mp_cost", 0)), opening_combo])
	lines.append("Unchanged · %s" % _preview_unchanged_domain(Array(preview.get("effects", []))))
	return "\n".join(lines)

func _preview_target(effects: Array) -> String:
	var targets: Array[String] = []
	for effect_variant in effects:
		if not (effect_variant is Dictionary):
			continue
		var op := String(Dictionary(effect_variant).get("op", ""))
		var target := ""
		if op == "DAMAGE_SINGLE":
			target = "Gatebreaker"
		elif op == "HEAL_SELF":
			target = "Vanguard"
		elif op in ["MITIGATE_CURRENT_DIRECT", "COUNTER_FROM_PREVENTED_DAMAGE", "PROTECT_RESOURCE_LOSS", "LETHAL_SAFETY", "ADJUST_CURRENT_ENEMY_ETA"]:
			target = "Current enemy action"
		elif op == "GRANT_PLAYER_BOARD_OPPORTUNITY":
			target = "Player LINE board"
		if target != "" and not targets.has(target):
			targets.append(target)
	return " / ".join(targets) if not targets.is_empty() else "Current battle state"

func _preview_unchanged_domain(effects: Array) -> String:
	var changes_board := false
	var changes_eta := false
	for effect_variant in effects:
		if not (effect_variant is Dictionary):
			continue
		var op := String(Dictionary(effect_variant).get("op", ""))
		changes_board = changes_board or op == "GRANT_PLAYER_BOARD_OPPORTUNITY"
		changes_eta = changes_eta or op == "ADJUST_CURRENT_ENEMY_ETA"
	if changes_board and changes_eta:
		return "next action ETA and non-targeted board state"
	if changes_board:
		return "Enemy ETA unchanged"
	if changes_eta:
		return "LINE board timing unchanged"
	return "shared timer and non-targeted rules"

func _trigger_vanguard_attack_fx() -> void:
	_vanguard_attack_fx_remaining = 0.42
	_vanguard_attack_accent.visible = true
	_vanguard_attack_accent.modulate = Color(1.0, 1.0, 1.0, 0.9)

func _refresh_stage_vfx(delta: float) -> void:
	var simulation_delta := 0.0 if _runtime != null and _runtime.is_simulation_paused() else maxf(0.0, delta)
	_stage_vfx_elapsed += simulation_delta
	_refresh_gatebreaker_presence()
	if _vanguard_attack_fx_remaining > 0.0:
		_vanguard_attack_fx_remaining = maxf(0.0, _vanguard_attack_fx_remaining - simulation_delta)
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

func _capture_gatebreaker_presence_base() -> void:
	if not is_instance_valid(_gatebreaker_reference):
		return
	_gatebreaker_base_position = _gatebreaker_reference.position
	_gatebreaker_reference.pivot_offset = _gatebreaker_reference.size * 0.5
	_gatebreaker_presence_base_captured = true
	_refresh_gatebreaker_presence()

func _refresh_gatebreaker_presence() -> void:
	if not is_instance_valid(_gatebreaker_reference):
		return
	if not _gatebreaker_presence_base_captured:
		_gatebreaker_base_position = _gatebreaker_reference.position
		_gatebreaker_reference.pivot_offset = _gatebreaker_reference.size * 0.5
		_gatebreaker_presence_base_captured = true
	var bob := sin(_stage_vfx_elapsed * 1.25)
	var breath := 0.5 + 0.5 * sin(_stage_vfx_elapsed * 0.9)
	_gatebreaker_reference.position = _gatebreaker_base_position + Vector2(0.0, bob * 4.0)
	_gatebreaker_reference.scale = Vector2.ONE * (1.0 + breath * 0.012)
	_gatebreaker_reference.modulate = Color(1.0, 1.0, 1.0, 0.94 + breath * 0.06)

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
	_tutorial_prompt.text = _tutorial_prompt_text(String(snapshot.get("tutorial_step", "")), bool(snapshot.get("tutorial_free_play", false)))
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
	_refresh_timing_feedback(snapshot)
	_refresh_chain_lock_prompt()

func _refresh_timing_feedback(snapshot: Dictionary) -> void:
	var feedback_value = snapshot.get("last_time_feedback", {})
	if not (feedback_value is Dictionary):
		return
	var feedback: Dictionary = feedback_value
	if String(feedback.get("target", "")) == "" or String(feedback.get("changed", "")) == "" or String(feedback.get("unchanged", "")) == "":
		return
	if feedback != _last_timing_feedback:
		_last_timing_feedback = feedback.duplicate(true)
		_timing_feedback_remaining = 4.0
	if _timing_feedback_remaining > 0.0:
		_timing_feedback.text = "%s · %s\nUnchanged · %s" % [String(feedback["target"]), String(feedback["changed"]), String(feedback["unchanged"])]

func _tutorial_prompt_text(step: String, free_play: bool) -> String:
	if free_play:
		return "FREE PLAY · THE AUTHORED ENCOUNTER CONTINUES"
	match step:
		"READ_THREAT":
			return "LIVE PRACTICE · READ THE CURRENT TELEGRAPH AND ETA"
		"LINE_REWARD":
			return "LIVE PRACTICE · CLEAR LINE TO RECOVER MP"
		"CHAIN_REWARD":
			return "LIVE PRACTICE · MAKE A STRAIGHT 3+ CHAIN FOR COMBO"
		"SKILL_PREVIEW":
			return "LIVE PRACTICE · OPEN SKILL AND INSPECT A CATEGORY PREVIEW"
		"SKILL_CONFIRM":
			return "LIVE PRACTICE · CONFIRM ONE DISPLAYED COMBO SKILL"
	return ""

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
