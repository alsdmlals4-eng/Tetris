## CORE-029 continuous 전투의 simulation·pause·workspace evidence를 기록한다.
class_name ProductionTelemetry
extends RefCounted

var _events: Array[Dictionary] = []
var _active_simulation_duration := 0.0
var _line_residency_duration := 0.0
var _chain_residency_duration := 0.0
var _tactical_pause_duration := 0.0
var _manual_pause_duration := 0.0
var _tactical_pause_open := false
var _manual_pause_open := false

func record(kind: String, payload: Dictionary = {}) -> Dictionary:
	var event := {"kind": kind, "simulation_time_seconds": _active_simulation_duration, "payload": payload.duplicate(true)}
	_events.append(event)
	return event

func advance_simulation(delta: float, workspace: String) -> void:
	if delta <= 0.0:
		return
	_active_simulation_duration += delta
	if workspace == "LINE":
		_line_residency_duration += delta
	elif workspace == "CHAIN":
		_chain_residency_duration += delta

func advance_wall_clock(delta: float) -> void:
	if delta <= 0.0:
		return
	if _tactical_pause_open:
		_tactical_pause_duration += delta
	if _manual_pause_open:
		_manual_pause_duration += delta

func begin_tactical_pause() -> void:
	if not _tactical_pause_open:
		_tactical_pause_open = true
		record("TACTICAL_PAUSE_OPENED")

func end_tactical_pause() -> void:
	if _tactical_pause_open:
		_tactical_pause_open = false
		record("TACTICAL_PAUSE_CLOSED")

func events() -> Array[Dictionary]:
	return _events.duplicate(true)

func summary() -> Dictionary:
	var technique_uses := 0
	for event in _events:
		if String(event.get("kind", "")) == "TECHNIQUE_USED":
			technique_uses += 1
	return {"active_simulation_duration": _active_simulation_duration, "line_residency_duration": _line_residency_duration, "chain_residency_duration": _chain_residency_duration, "tactical_pause_duration": _tactical_pause_duration, "manual_pause_duration": _manual_pause_duration, "technique_use_count": technique_uses}
