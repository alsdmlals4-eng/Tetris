class_name GatebreakerActionCatalog
extends RefCounted

const ALLOWED_KINDS := [
    "DIRECT_HP_RATIO",
    "ENERGY_LOSS",
    "STOCK_LOSS",
    "ENEMY_HEAL_RATIO",
]

var _templates: Dictionary = {}
var _ordered_keys: Array[String] = []

static func from_dictionary(data: Dictionary) -> GatebreakerActionCatalog:
    var catalog := GatebreakerActionCatalog.new()
    var actions: Array = data.get("actions", [])
    for action_value in actions:
        if not action_value is Dictionary:
            continue
        var action: Dictionary = action_value
        if not catalog._is_valid_template(action):
            continue
        var key := String(action.get("key", ""))
        if catalog._templates.has(key):
            continue
        catalog._templates[key] = action.duplicate(true)
        catalog._ordered_keys.append(key)
    return catalog

func keys() -> Array[String]:
    return _ordered_keys.duplicate()

func get_by_key(key: String) -> Dictionary:
    if not _templates.has(key):
        return {}
    return (_templates[key] as Dictionary).duplicate(true)

func is_allowed_in_phase(key: String, phase_id: int) -> bool:
    if phase_id < 1 or phase_id > 3 or not _templates.has(key):
        return false
    var template: Dictionary = _templates[key]
    var phases: Array = template.get("phase_ids", [])
    return phases.has(phase_id)

func instantiate_action(key: String, sequence_id: int) -> Dictionary:
    if sequence_id < 1 or not _templates.has(key):
        return {}
    var instance := get_by_key(key)
    instance["template_key"] = key
    instance["id"] = "gatebreaker:%s:%d" % [key, sequence_id]
    return instance

func _is_valid_template(action: Dictionary) -> bool:
    var key := String(action.get("key", ""))
    var kind := String(action.get("kind", ""))
    if key == "" or not ALLOWED_KINDS.has(kind):
        return false

    var phases: Array = action.get("phase_ids", [])
    var tags: Array = action.get("tags", [])
    if phases.is_empty() or tags.is_empty():
        return false
    for phase_value in phases:
        var phase_id := int(phase_value)
        if phase_id < 1 or phase_id > 3:
            return false

    match kind:
        "DIRECT_HP_RATIO", "ENEMY_HEAL_RATIO":
            var ratio := float(action.get("hp_ratio", 0.0))
            if ratio <= 0.0 or ratio > 1.0:
                return false
        "ENERGY_LOSS", "STOCK_LOSS":
            if int(action.get("amount", 0)) <= 0:
                return false
    return true
