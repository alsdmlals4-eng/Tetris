## CORE-029의 퍼즐·적 ETA·전술 pause를 단일 프레임 순서로 조정한다.
class_name ProductionCombatRuntime
extends RefCounted

var _player: ProductionCombatState
var _enemy: ProductionCombatState
var _workspace_manager
var _enemy_scheduler
var _skill_session
var _pause_controller: SimulationPauseController
var _response_state
var _telemetry = null
var _board_opportunity = null
var _last_time_feedback: Dictionary = {}
var _started := false
var _terminal := false
var _system_pause_token: int = 0

func _init(player: ProductionCombatState, enemy: ProductionCombatState, workspace_manager, enemy_scheduler, skill_session, pause_controller: SimulationPauseController, response_state, telemetry = null, board_opportunity = null) -> void:
	_player = player
	_enemy = enemy
	_workspace_manager = workspace_manager
	_enemy_scheduler = enemy_scheduler
	_skill_session = skill_session
	_pause_controller = pause_controller
	_response_state = response_state
	_telemetry = telemetry
	_board_opportunity = board_opportunity

func start_battle() -> Dictionary:
	if _started or _player == null or _enemy == null or _enemy_scheduler == null:
		return {"started": false, "reason": "INVALID_START_STATE"}
	var started: Dictionary = _enemy_scheduler.start()
	if not bool(started.get("started", false)):
		return started
	_started = true
	if _telemetry != null:
		_telemetry.record("BATTLE_STARTED")
		if _workspace_manager != null:
			_telemetry.record("WORKSPACE_ENTERED", {"workspace": _workspace_manager.active_workspace()})
		_telemetry.record("ENEMY_TELEGRAPH_STARTED", {"action_id": current_action_id()})
	return {"started": true, "enemy_eta_seconds": _enemy_scheduler.remaining_seconds()}

func process_player_command(command: Dictionary) -> Dictionary:
	match String(command.get("kind", "")):
		"OPEN_SKILL":
			return open_skill()
		"CLOSE_SKILL":
			return close_skill_without_use()
		"SWITCH_WORKSPACE":
			if _workspace_manager == null:
				return {"accepted": false, "reason": "WORKSPACE_UNAVAILABLE"}
			var switch_result: Dictionary = _workspace_manager.request_switch(String(command.get("target", "")))
			if bool(switch_result.get("accepted", false)) and _telemetry != null:
				_telemetry.record("WORKSPACE_SWITCH_REQUESTED", {"target": String(command.get("target", ""))})
			return switch_result
		"TOGGLE_SYSTEM_PAUSE":
			return toggle_system_pause()
		"CHAIN_SWAP":
			return try_chain_swap(Vector2i(command.get("first", Vector2i(-1, -1))), Vector2i(command.get("second", Vector2i(-1, -1))))
		"CONFIRM_CHAIN_MP_LOCK":
			return confirm_chain_mp_lock()
		"DISCARD_CHAIN_MP_LOCK":
			return discard_chain_mp_lock()
	return {"accepted": false, "reason": "UNKNOWN_COMMAND"}

func tick(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not _started or delta <= 0.0 or _terminal or is_simulation_paused():
		if _telemetry != null and is_simulation_paused():
			_telemetry.advance_wall_clock(delta)
		return events
	if _telemetry != null:
		_telemetry.advance_simulation(delta, _workspace_manager.active_workspace() if _workspace_manager != null else "")
	if _workspace_manager != null:
		var previous_workspace: String = _workspace_manager.active_workspace()
		var handoff: Dictionary = _workspace_manager.process_safe_handoff()
		if bool(handoff.get("switched", false)) and _telemetry != null:
			var active_workspace: String = _workspace_manager.active_workspace()
			_telemetry.record("WORKSPACE_EXITED", {"workspace": previous_workspace})
			_telemetry.record("WORKSPACE_SWITCH_COMMITTED", {"workspace": active_workspace})
			_telemetry.record("WORKSPACE_ENTERED", {"workspace": active_workspace})
		_tick_active_puzzle(delta)
		_commit_puzzle_events(events)
	var context := _effect_context()
	var action_before: String = current_action_id()
	for event in _enemy_scheduler.tick_simulation(delta, context):
		events.append(event)
		if _telemetry != null and String(event.get("kind", "")) == "ENEMY_ACTION_RESOLVED":
			_telemetry.record("ENEMY_ACTION_RESOLVED", event)
	if _telemetry != null and action_before != "" and current_action_id() != action_before:
		_telemetry.record("ENEMY_TELEGRAPH_STARTED", {"action_id": current_action_id()})
	_resolve_terminal(events)
	return events

func open_skill() -> Dictionary:
	if _skill_session == null or _terminal:
		return {"opened": false, "reason": "SKILL_UNAVAILABLE"}
	var opened: bool = _skill_session.open()
	if opened and _telemetry != null:
		_telemetry.begin_tactical_pause()
	return {"opened": opened}

func close_skill_without_use() -> Dictionary:
	if _skill_session == null:
		return {"closed": false, "reason": "SKILL_UNAVAILABLE"}
	var result: Dictionary = _skill_session.cancel()
	if bool(result.get("canceled", false)) and _telemetry != null:
		_telemetry.end_tactical_pause()
	return {"closed": bool(result.get("canceled", false))}

func toggle_system_pause() -> Dictionary:
	if _pause_controller == null:
		return {"changed": false, "reason": "PAUSE_UNAVAILABLE"}
	if _system_pause_token == 0:
		_system_pause_token = _pause_controller.acquire(SimulationPauseController.SYSTEM_MENU)
		if _system_pause_token == 0:
			return {"changed": false, "reason": "PAUSE_UNAVAILABLE"}
		if _telemetry != null:
			_telemetry.begin_manual_pause()
		return {"changed": true, "paused": true}
	var released := _pause_controller.release(_system_pause_token)
	_system_pause_token = 0
	if released and _telemetry != null:
		_telemetry.end_manual_pause()
	return {"changed": released, "paused": false}

func is_skill_open() -> bool:
	return _skill_session != null and _skill_session.is_open()

func select_skill_category(category: String) -> bool:
	return _skill_session != null and _skill_session.select_category(category)

func select_skill_technique(technique_id: String) -> Dictionary:
	if _skill_session == null:
		return {"selected": false, "reason": "SKILL_UNAVAILABLE"}
	return _skill_session.select_technique(technique_id)

func use_selected_skill() -> Dictionary:
	if _skill_session == null:
		return {"committed": false, "reason": "SKILL_UNAVAILABLE"}
	var result: Dictionary = _skill_session.commit_selected(_effect_context())
	if bool(result.get("committed", false)) and _telemetry != null:
		_telemetry.record("TECHNIQUE_USED", result)
		_telemetry.end_tactical_pause()
	return result

func try_chain_swap(first: Vector2i, second: Vector2i) -> Dictionary:
	if _terminal or is_simulation_paused() or _workspace_manager == null or _workspace_manager.active_workspace() != "CHAIN" or _workspace_manager.chain_session == null:
		return {"accepted": false, "reason": "CHAIN_INPUT_UNAVAILABLE"}
	var result: Dictionary = _workspace_manager.chain_session.begin_swap(first, second)
	if String(result.get("reason", "")) == "NO_MATCH_PENDING_LOCK":
		var combo_before := _player.reset_combo() if _player != null else 0
		result["combo_reset"] = combo_before
	return result

func confirm_chain_mp_lock() -> Dictionary:
	if _terminal or is_simulation_paused():
		return {"accepted": false, "reason": "CHAIN_LOCK_INPUT_UNAVAILABLE"}
	if _player == null or _workspace_manager == null or _workspace_manager.chain_session == null:
		return {"accepted": false, "reason": "CHAIN_LOCK_UNAVAILABLE"}
	if not _workspace_manager.chain_session.has_pending_failed_swap():
		return {"accepted": false, "reason": "NO_PENDING_FAILED_SWAP"}
	if not _player.try_spend_mp(1):
		return {"accepted": false, "reason": "INSUFFICIENT_MP", "mp_cost": 1}
	var locked: Dictionary = _workspace_manager.chain_session.keep_pending_failed_swap()
	if not bool(locked.get("accepted", false)):
		_player.apply_energy_delta(1)
		return locked
	locked["mp_cost"] = 1
	return locked

func discard_chain_mp_lock() -> Dictionary:
	if _terminal or is_simulation_paused():
		return {"accepted": false, "reason": "CHAIN_LOCK_INPUT_UNAVAILABLE"}
	if _workspace_manager == null or _workspace_manager.chain_session == null:
		return {"accepted": false, "reason": "CHAIN_LOCK_UNAVAILABLE"}
	return _workspace_manager.chain_session.discard_pending_failed_swap()

func is_simulation_paused() -> bool:
	return _pause_controller != null and _pause_controller.is_paused()

func is_terminal() -> bool:
	return _terminal

func current_action_id() -> String:
	return _enemy_scheduler.current_action_id() if _enemy_scheduler != null else ""

func grant_player_board_opportunity(seconds: float) -> Dictionary:
	if _terminal:
		return {"granted": false, "reason": "COMBAT_TERMINAL", "remaining_seconds": 0.0}
	if _board_opportunity == null or not _board_opportunity.has_method("grant"):
		return {"granted": false, "reason": "BOARD_OPPORTUNITY_UNAVAILABLE", "remaining_seconds": 0.0}
	var granted: Dictionary = _board_opportunity.grant(seconds)
	_last_time_feedback = granted.duplicate(true)
	return granted

func snapshot() -> Dictionary:
	return {
		"started": _started,
		"terminal": _terminal,
		"paused": is_simulation_paused(),
		"player_hp": _player.hp if _player != null else 0,
		"player_energy": _player.energy if _player != null else 0,
		"player_stock": _player.stock if _player != null else 0,
		"enemy_hp": _enemy.hp if _enemy != null else 0,
		"enemy_eta_seconds": _enemy_scheduler.remaining_seconds() if _enemy_scheduler != null else 0.0,
		"player_board_opportunity_seconds": _board_opportunity.remaining_seconds() if _board_opportunity != null and _board_opportunity.has_method("remaining_seconds") else 0.0,
		"last_time_feedback": _last_time_feedback.duplicate(true),
	}

func _tick_active_puzzle(delta: float) -> void:
	if _workspace_manager.active_workspace() == "LINE" and _workspace_manager.line_session != null:
		var line_delta := delta
		if _board_opportunity != null and _board_opportunity.has_method("consume_line_delta"):
			var opportunity_budget: Dictionary = _board_opportunity.consume_line_delta(delta)
			line_delta = float(opportunity_budget.get("line_delta", delta))
			_last_time_feedback = opportunity_budget.duplicate(true)
		_workspace_manager.line_session.tick(line_delta)
	elif _workspace_manager.active_workspace() == "CHAIN" and _workspace_manager.chain_session != null and _workspace_manager.chain_session.is_resolving():
		_workspace_manager.chain_session.complete_pending_resolution()

func _commit_puzzle_events(events: Array[Dictionary]) -> void:
	for event in _workspace_manager.line_session.drain_events():
		var kind: String = String(event.get("kind", ""))
		if kind == "production_line_resolved":
			_player.apply_line_event(event)
			events.append(event)
			if _telemetry != null:
				_telemetry.record("LINE_REWARD", event)
		elif kind == "production_line_board_break":
			events.append(event)
			if _telemetry != null:
				_telemetry.record("BOARD_BREAK", event)
	for event in _workspace_manager.chain_session.drain_events():
		if String(event.get("kind", "")) == "production_chain_resolved":
			var wave_rewards: Array = []
			for raw_wave in event.get("waves", []):
				if raw_wave is Dictionary:
					var lengths: Array[int] = []
					for raw_length in raw_wave.get("qualified_line_lengths", []):
						lengths.append(int(raw_length))
					wave_rewards.append(_player.apply_chain_wave(lengths))
			event["wave_rewards"] = wave_rewards
			events.append(event)
			if _telemetry != null:
				_telemetry.record("CHAIN_REWARD", event)

func _resolve_terminal(events: Array[Dictionary]) -> void:
	if _enemy.is_defeated():
		_terminal = true
		events.append({"kind": "VICTORY"})
		if _telemetry != null:
			_telemetry.record("VICTORY")
	elif _player.is_defeated():
		_terminal = true
		events.append({"kind": "DEFEAT"})
		if _telemetry != null:
			_telemetry.record("DEFEAT")

func _effect_context() -> Dictionary:
	return {
		"player": _player,
		"enemy": _enemy,
		"response_state": _response_state,
		"telegraph_action_id": _enemy_scheduler.current_action_id() if _enemy_scheduler != null else "",
		"board_opportunity": _board_opportunity,
		"enemy_scheduler": _enemy_scheduler,
	}
