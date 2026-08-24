class_name ProductionStatusState
extends RefCounted

const ALLOWED_STATUSES := [
    "BREACH",
    "FORTIFY",
    "RALLY",
    "WEAKEN",
    "RIFT_WARD",
    "RIFT_SEAL",
    "BATTLE_TRANCE",
]

const ALLOWED_BINDINGS := [
    "VISIBLE_NEXT_FORECAST_ACTION_ID",
    "CURRENT_TELEGRAPH_ACTION_ID",
]

var _entries: Dictionary = {}

func allowed_statuses() -> Array:
    return ALLOWED_STATUSES.duplicate()

func _key(status: String, target: String) -> String:
    return "%s|%s" % [target, status]

func _valid(status: String, target: String) -> bool:
    return ALLOWED_STATUSES.has(status) and target != ""

func apply_status(status: String, target: String, stacks: int = 1) -> bool:
    if not _valid(status, target) or stacks <= 0:
        return false
    _entries[_key(status, target)] = {
        "status": status,
        "target": target,
        "stacks": 1,
        "action_id": "",
        "binding": "",
    }
    return true

func apply_bound_status(status: String, target: String, action_id: String, binding: String) -> bool:
    if not _valid(status, target) or action_id == "" or not ALLOWED_BINDINGS.has(binding):
        return false
    _entries[_key(status, target)] = {
        "status": status,
        "target": target,
        "stacks": 1,
        "action_id": action_id,
        "binding": binding,
    }
    return true

func has_status(status: String, target: String) -> bool:
    return _entries.has(_key(status, target))

func status_stacks(status: String, target: String) -> int:
    var entry: Dictionary = _entries.get(_key(status, target), {})
    return int(entry.get("stacks", 0))

func matches_bound_action(status: String, target: String, action_id: String) -> bool:
    if action_id == "":
        return false
    var entry: Dictionary = _entries.get(_key(status, target), {})
    if entry.is_empty() or String(entry.get("binding", "")) == "":
        return false
    return String(entry.get("action_id", "")) == action_id

func consume_for_action(status: String, target: String, action_id: String) -> bool:
    if not matches_bound_action(status, target, action_id):
        return false
    _entries.erase(_key(status, target))
    return true
