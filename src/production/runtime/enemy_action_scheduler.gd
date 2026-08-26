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

func start() -> Dictionary:
    if _started or _director == null or _timing == null or _resolver == null:
        return {"started": false, "reason": "INVALID_START_STATE"}
    var opening: Dictionary = _director.bootstrap()
    var current = opening.get("current", {})
    var next = opening.get("next", {})
    if not current is Dictionary or not next is Dictionary:
        return {"started": false, "reason": "INVALID_AUTHORED_OPENING"}
    var duration := _timing.seconds_for_action(String(current.get("template_key", "")))
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

func next_action_id() -> String:
    if _telegraph == null:
        return ""
    return String(_telegraph.next_action().get("id", ""))

func remaining_seconds() -> float:
    return _remaining_seconds

func is_action_committed() -> bool:
    return _started and _timing != null and _remaining_seconds <= _timing.commit_lead_seconds

func _boss_hp_ratio(context: Dictionary) -> float:
    var enemy = context.get("enemy")
    if enemy == null or int(enemy.max_hp) <= 0:
        return 1.0
    return clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
