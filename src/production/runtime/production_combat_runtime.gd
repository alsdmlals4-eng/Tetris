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
var _started := false
var _terminal := false

func _init(player: ProductionCombatState, enemy: ProductionCombatState, workspace_manager, enemy_scheduler, skill_session, pause_controller: SimulationPauseController, response_state) -> void:
	_player = player
	_enemy = enemy
	_workspace_manager = workspace_manager
	_enemy_scheduler = enemy_scheduler
	_skill_session = skill_session
	_pause_controller = pause_controller
	_response_state = response_state

func start_battle() -> Dictionary:
	if _started or _player == null or _enemy == null or _enemy_scheduler == null:
		return {"started": false, "reason": "INVALID_START_STATE"}
	var started: Dictionary = _enemy_scheduler.start()
	if not bool(started.get("started", false)):
		return started
	_started = true
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
			return _workspace_manager.request_switch(String(command.get("target", "")))
	return {"accepted": false, "reason": "UNKNOWN_COMMAND"}

func tick(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not _started or delta <= 0.0 or _terminal or is_simulation_paused():
		return events
	if _workspace_manager != null:
		_workspace_manager.process_safe_handoff()
		_tick_active_puzzle(delta)
		_commit_puzzle_events(events)
	var context := {"player": _player, "enemy": _enemy, "response_state": _response_state, "telegraph_action_id": _enemy_scheduler.current_action_id()}
	for event in _enemy_scheduler.tick_simulation(delta, context):
		events.append(event)
	_resolve_terminal(events)
	return events

func open_skill() -> Dictionary:
	if _skill_session == null or _terminal:
		return {"opened": false, "reason": "SKILL_UNAVAILABLE"}
	return {"opened": _skill_session.open()}

func close_skill_without_use() -> Dictionary:
	if _skill_session == null:
		return {"closed": false, "reason": "SKILL_UNAVAILABLE"}
	var result: Dictionary = _skill_session.cancel()
	return {"closed": bool(result.get("canceled", false))}

func is_simulation_paused() -> bool:
	return _pause_controller != null and _pause_controller.is_paused()

func is_terminal() -> bool:
	return _terminal

func snapshot() -> Dictionary:
	return {"started": _started, "terminal": _terminal, "paused": is_simulation_paused(), "player_hp": _player.hp if _player != null else 0, "player_energy": _player.energy if _player != null else 0, "player_stock": _player.stock if _player != null else 0, "enemy_hp": _enemy.hp if _enemy != null else 0, "enemy_eta_seconds": _enemy_scheduler.remaining_seconds() if _enemy_scheduler != null else 0.0}

func _tick_active_puzzle(delta: float) -> void:
	if _workspace_manager.active_workspace() == "LINE" and _workspace_manager.line_session != null:
		_workspace_manager.line_session.tick(delta)
	elif _workspace_manager.active_workspace() == "CHAIN" and _workspace_manager.chain_session != null and _workspace_manager.chain_session.is_resolving():
		_workspace_manager.chain_session.complete_pending_resolution()

func _commit_puzzle_events(events: Array[Dictionary]) -> void:
	for event in _workspace_manager.line_session.drain_events():
		if String(event.get("kind", "")) == "production_line_resolved":
			_player.apply_line_event(event)
			events.append(event)
	for event in _workspace_manager.chain_session.drain_events():
		if String(event.get("kind", "")) == "production_chain_resolved":
			_player.gain_stock(int(event.get("stock_requested", 0)))
			events.append(event)

func _resolve_terminal(events: Array[Dictionary]) -> void:
	if _enemy.is_defeated():
		_terminal = true
		events.append({"kind": "VICTORY"})
	elif _player.is_defeated():
		_terminal = true
		events.append({"kind": "DEFEAT"})
