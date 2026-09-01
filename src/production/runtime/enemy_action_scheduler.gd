## Gatebreaker authored Telegraph를 realtime ETA로 진행하고 각 행동을 정확히 한 번 해결한다.
class_name EnemyActionScheduler
extends RefCounted

var _director: GatebreakerEncounterDirector
var _timing: GatebreakerRealtimeTimingConfig
var _resolver: ProductionEnemyActionResolver
var _telegraph: GatebreakerTelegraphState
var _remaining_seconds: float = 0.0
var _started: bool = false
var _resolution_attempted: bool = false

func _init(
    director: GatebreakerEncounterDirector,
    timing: GatebreakerRealtimeTimingConfig,
    resolver: ProductionEnemyActionResolver
) -> void:
    _director = director
    _timing = timing
    _resolver = resolver

func start(use_tutorial_opening: bool = false) -> Dictionary:
    if _started or _director == null or _timing == null or _resolver == null:
        return {"started": false, "reason": "INVALID_START_STATE"}
    var opening: Dictionary = _director.bootstrap()
    var current = opening.get("current", {})
    var next = opening.get("next", {})
    if not current is Dictionary or not next is Dictionary:
        return {"started": false, "reason": "INVALID_AUTHORED_OPENING"}
    var duration := _timing.opening_seconds_for_action(String(current.get("template_key", "")), use_tutorial_opening)
    if duration <= 0.0:
        return {"started": false, "reason": "MISSING_ACTION_TIMING"}
    _telegraph = GatebreakerTelegraphState.new(current, next)
    if not _telegraph.is_ready():
        _telegraph = null
        return {"started": false, "reason": "INVALID_TELEGRAPH"}
    _remaining_seconds = duration
    _started = true
    _resolution_attempted = false
    return {
        "started": true,
        "current_action_id": current_action_id(),
        "next_action_id": next_action_id(),
        "remaining_seconds": _remaining_seconds,
        "tutorial_opening": use_tutorial_opening,
    }

func tick_simulation(delta: float, context: Dictionary) -> Array[Dictionary]:
    var events: Array[Dictionary] = []
    if not _started or _telegraph == null or delta <= 0.0 or _resolution_attempted:
        return events
    _remaining_seconds = maxf(0.0, _remaining_seconds - delta)
    if _remaining_seconds > 0.0:
        return events
    _resolution_attempted = true
    var current := _telegraph.current_action()
    var result: Dictionary = _resolver.resolve(current, context)
    var event := {
        "kind": "ENEMY_ACTION_RESOLVED",
        "action_id": current_action_id(),
        "resolved": bool(result.get("resolved", false)),
        "result": result.duplicate(true),
    }
    events.append(event)
    if not bool(result.get("resolved", false)):
        return events
    var authored_next := _director.schedule_next_after_resolve(_boss_hp_ratio(context))
    var advance: Dictionary = _telegraph.advance_after_resolve(current_action_id(), authored_next)
    if not bool(advance.get("advanced", false)):
        event["resolved"] = false
        event["reason"] = String(advance.get("reason", "TELEGRAPH_ADVANCE_FAILED"))
        return events
    _remaining_seconds = _timing.seconds_for_action(String(_telegraph.current_action().get("template_key", "")))
    if _remaining_seconds <= 0.0:
        event["resolved"] = false
        event["reason"] = "MISSING_NEXT_ACTION_TIMING"
        return events
    _resolution_attempted = false
    return events

func current_action_id() -> String:
    if _telegraph == null:
        return ""
    return String(_telegraph.current_action().get("id", ""))

func current_action_kind() -> String:
    if _telegraph == null:
        return ""
    return String(_telegraph.current_action().get("kind", ""))

func next_action_id() -> String:
    if _telegraph == null:
        return ""
    return String(_telegraph.next_action().get("id", ""))

func remaining_seconds() -> float:
    return _remaining_seconds

func is_action_committed() -> bool:
    return _started and _timing != null and _remaining_seconds <= _timing.commit_lead_seconds

func tutorial_nonterminal_until_first_confirm() -> bool:
    return _timing != null and _timing.tutorial_nonterminal_until_first_confirm

func adjust_current_eta(action_id: String, delta_seconds: float) -> Dictionary:
    var before := _remaining_seconds
    if not _started or _telegraph == null:
        return _eta_adjustment_result(false, before, "SCHEDULER_NOT_STARTED")
    if action_id == "" or action_id != current_action_id():
        return _eta_adjustment_result(false, before, "NOT_CURRENT_ACTION")
    if is_action_committed():
        return _eta_adjustment_result(false, before, "ACTION_COMMITTED")
    if is_nan(delta_seconds) or is_inf(delta_seconds):
        return _eta_adjustment_result(false, before, "INVALID_DELTA")
    if is_zero_approx(delta_seconds):
        return _eta_adjustment_result(false, before, "ZERO_DELTA")
    _remaining_seconds = maxf(_timing.commit_lead_seconds, _remaining_seconds + delta_seconds)
    return _eta_adjustment_result(not is_equal_approx(before, _remaining_seconds), before, "")

func snapshot_current_action_state() -> Dictionary:
    if not _started or _telegraph == null:
        return {}
    return {
        "current_action_id": current_action_id(),
        "next_action_id": next_action_id(),
        "remaining_seconds": _remaining_seconds,
        "committed": is_action_committed(),
        "resolution_attempted": _resolution_attempted,
    }

func restore_current_action_state(snapshot: Dictionary) -> bool:
    var required_keys := ["current_action_id", "next_action_id", "remaining_seconds", "committed", "resolution_attempted"]
    if not _started or _telegraph == null or snapshot.size() != required_keys.size():
        return false
    for key in required_keys:
        if not snapshot.has(key):
            return false
    if not (snapshot["remaining_seconds"] is int or snapshot["remaining_seconds"] is float):
        return false
    if not (snapshot["committed"] is bool) or not (snapshot["resolution_attempted"] is bool):
        return false
    var restored_seconds := float(snapshot["remaining_seconds"])
    if is_nan(restored_seconds) or is_inf(restored_seconds) or restored_seconds < 0.0:
        return false
    var snapshot_is_committed: bool = bool(snapshot["committed"])
    var snapshot_resolution_attempted: bool = bool(snapshot["resolution_attempted"])
    if snapshot_is_committed != (restored_seconds <= _timing.commit_lead_seconds):
        return false
    if String(snapshot["current_action_id"]) != current_action_id() or String(snapshot["next_action_id"]) != next_action_id():
        return false
    if snapshot_is_committed != is_action_committed() or snapshot_resolution_attempted != _resolution_attempted:
        return false
    _remaining_seconds = restored_seconds
    return true

func _eta_adjustment_result(adjusted: bool, before_seconds: float, reason: String) -> Dictionary:
    var result := {
        "adjusted": adjusted,
        "before_seconds": before_seconds,
        "after_seconds": _remaining_seconds,
        "action_id": current_action_id(),
    }
    if reason != "":
        result["reason"] = reason
    return result

func _boss_hp_ratio(context: Dictionary) -> float:
    var enemy = context.get("enemy")
    if enemy == null or int(enemy.max_hp) <= 0:
        return 1.0
    return clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
