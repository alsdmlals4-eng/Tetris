class_name ProductionSkillCatalog
extends RefCounted

const LANES := ["ATTACK", "DEFENSE", "SUPPORT"]
const ALLOWED_EFFECT_OPS := [
    "DAMAGE_SINGLE",
    "DAMAGE_AOE",
    "MITIGATE_CURRENT_DIRECT",
    "COUNTER_FROM_PREVENTED_DAMAGE",
    "HEAL_SELF",
    "APPLY_SELF_BUFF",
    "APPLY_ENEMY_DEBUFF",
    "PROTECT_RESOURCE_LOSS",
    "MODIFY_NEXT_TURN_BUDGET",
    "CONDITIONAL_MULTIPLIER",
    "LETHAL_SAFETY",
    "TARGET_PATTERN",
]

var balance_status: String = ""
var _definitions: Array[Dictionary] = []
var _by_id: Dictionary = {}

static func from_dictionary(data: Dictionary):
    var status := String(data.get("balance_status", ""))
    var raw_definitions = data.get("techniques", [])
    if status == "" or typeof(raw_definitions) != TYPE_ARRAY:
        return null

    var catalog := ProductionSkillCatalog.new()
    catalog.balance_status = status

    for raw_definition in raw_definitions:
        if typeof(raw_definition) != TYPE_DICTIONARY:
            return null
        var definition: Dictionary = raw_definition.duplicate(true)
        if not catalog._definition_is_valid(definition):
            return null
        var technique_id := String(definition["id"])
        if catalog._by_id.has(technique_id):
            return null
        catalog._definitions.append(definition)
        catalog._by_id[technique_id] = definition

    return catalog

func _definition_is_valid(definition: Dictionary) -> bool:
    var technique_id := String(definition.get("id", ""))
    var lane := String(definition.get("lane", ""))
    var tier := int(definition.get("tier", -1))
    var stock_cost := int(definition.get("stock_cost", -1))
    var energy_cost := int(definition.get("energy_cost", -1))
    var effects = definition.get("effects", [])

    if technique_id == "" or not LANES.has(lane):
        return false
    if tier < 1 or tier > 6 or stock_cost != tier or energy_cost < 0:
        return false
    if typeof(effects) != TYPE_ARRAY or effects.is_empty():
        return false

    for raw_effect in effects:
        if typeof(raw_effect) != TYPE_DICTIONARY:
            return false
        if not ALLOWED_EFFECT_OPS.has(String(raw_effect.get("op", ""))):
            return false

    return true

func technique_count() -> int:
    return _definitions.size()

func all_ids() -> Array:
    return _by_id.keys()

func all_definitions() -> Array:
    return _definitions.duplicate(true)

func for_lane(lane: String) -> Array:
    var result: Array = []
    for definition in _definitions:
        if String(definition.get("lane", "")) == lane:
            result.append(definition.duplicate(true))
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["tier"]) < int(b["tier"]))
    return result

func get_by_id(technique_id: String) -> Dictionary:
    if not _by_id.has(technique_id):
        return {}
    return Dictionary(_by_id[technique_id]).duplicate(true)
