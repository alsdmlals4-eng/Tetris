## CORE-029 전술 스킬 정의를 검증하고 조회하는 카탈로그다.
class_name ProductionSkillCatalog
extends RefCounted

const LANES: Array[String] = ["ATTACK", "DEFENSE", "SUPPORT"]
const ALLOWED_EFFECT_OPS: Array[String] = [
	"DAMAGE_SINGLE", "DAMAGE_AOE", "MITIGATE_CURRENT_DIRECT", "COUNTER_FROM_PREVENTED_DAMAGE",
	"HEAL_SELF", "APPLY_SELF_BUFF", "APPLY_ENEMY_DEBUFF", "PROTECT_RESOURCE_LOSS",
	"CONDITIONAL_MULTIPLIER", "LETHAL_SAFETY", "TARGET_PATTERN",
]

var _definitions: Dictionary = {}

static func from_dictionary(data: Dictionary):
	if data.get("balance_status", "") == "" or not (data.get("techniques") is Array):
		return null
	var catalog = load("res://src/production/skill/production_skill_catalog.gd").new()
	for definition_variant in data["techniques"]:
		if not (definition_variant is Dictionary):
			return null
		var definition: Dictionary = definition_variant
		if not catalog._validate_definition(definition):
			return null
		var technique_id := String(definition["id"])
		if catalog._definitions.has(technique_id):
			return null
		catalog._definitions[technique_id] = definition.duplicate(true)
	return catalog

func technique_count() -> int:
	return _definitions.size()

func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for technique_id in _definitions:
		ids.append(String(technique_id))
	ids.sort()
	return ids

func all_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for technique_id in all_ids():
		definitions.append(get_by_id(technique_id))
	return definitions

func for_lane(lane: String) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for definition in all_definitions():
		if String(definition.get("lane", "")) == lane:
			definitions.append(definition)
	definitions.sort_custom(func(left: Dictionary, right: Dictionary): return int(left["tier"]) < int(right["tier"]))
	return definitions

func get_by_id(technique_id: String) -> Dictionary:
	if not _definitions.has(technique_id):
		return {}
	return Dictionary(_definitions[technique_id]).duplicate(true)

func _validate_definition(definition: Dictionary) -> bool:
	var technique_id := String(definition.get("id", ""))
	var lane := String(definition.get("lane", ""))
	var tier := int(definition.get("tier", 0))
	if technique_id == "" or not LANES.has(lane) or tier < 1 or tier > 6:
		return false
	if int(definition.get("stock_cost", -1)) != tier or int(definition.get("energy_cost", -1)) < 0:
		return false
	if not (definition.get("effects") is Array) or definition["effects"].is_empty():
		return false
	for effect_variant in definition["effects"]:
		if not (effect_variant is Dictionary):
			return false
		if not ALLOWED_EFFECT_OPS.has(String(effect_variant.get("op", ""))):
			return false
	return true
