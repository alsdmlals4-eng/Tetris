## 현재와 다음 Gatebreaker Telegraph를 immutable 복사본으로 유지한다.
class_name GatebreakerTelegraphState
extends RefCounted

var _current: Dictionary = {}
var _next: Dictionary = {}

func _init(current_action: Dictionary, next_action: Dictionary) -> void:
    if _is_valid_authored_action(current_action):
        _current = current_action.duplicate(true)
    if _is_valid_authored_action(next_action):
        _next = next_action.duplicate(true)

func current_action() -> Dictionary:
    return _current.duplicate(true)

func next_action() -> Dictionary:
    return _next.duplicate(true)

func is_ready() -> bool:
    return not _current.is_empty() and not _next.is_empty()

func advance_readiness(resolved_action_id: String, authored_next: Dictionary) -> Dictionary:
    if _current.is_empty() or resolved_action_id == "" or resolved_action_id != String(_current.get("id", "")):
        return {
            "ready": false,
            "reason": "RESOLVED_ACTION_ID_MISMATCH",
        }
    if not _is_valid_authored_action(authored_next):
        return {
            "ready": false,
            "reason": "INVALID_NEXT_AUTHORED_ACTION",
        }
    if _next.is_empty():
        return {
            "ready": false,
            "reason": "MISSING_LOCKED_NEXT_ACTION",
        }
    return {
        "ready": true,
        "reason": "READY",
    }

func advance_after_resolve(resolved_action_id: String, authored_next: Dictionary) -> Dictionary:
    var readiness := advance_readiness(resolved_action_id, authored_next)
    if not bool(readiness.get("ready", false)):
        return {
            "advanced": false,
            "reason": String(readiness.get("reason", "ADVANCE_NOT_READY")),
        }

    var prior_next := _next.duplicate(true)
    _current = prior_next
    _next = authored_next.duplicate(true)
    return {
        "advanced": true,
        "reason": "ADVANCED",
        "resolved_action_id": resolved_action_id,
        "current_action_id": String(_current.get("id", "")),
        "next_action_id": String(_next.get("id", "")),
    }

func forecast_context() -> Dictionary:
    if not is_ready():
        return {}
    return {
        "current_telegraph_action_id": String(_current.get("id", "")),
        "current_telegraph_tags": Array(_current.get("tags", [])).duplicate(true),
        "next_forecast_action_id": String(_next.get("id", "")),
        "next_forecast_tags": Array(_next.get("tags", [])).duplicate(true),
    }

func _is_valid_authored_action(action: Dictionary) -> bool:
    if String(action.get("id", "")) == "":
        return false
    if String(action.get("template_key", "")) == "":
        return false
    if String(action.get("kind", "")) == "":
        return false
    var tags = action.get("tags", [])
    return tags is Array and not tags.is_empty()
