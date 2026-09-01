## 현재 Combo 단계와 적응형 위협 패키지를 검증·조회하는 전술 스킬 카탈로그다.
class_name ProductionSkillCatalog
extends RefCounted

const SCHEMA_VERSION: int = 2
const LANES: Array[String] = ["ATTACK", "DEFENSE", "SUPPORT"]
const ADAPTIVE_ACTION_KINDS: Array[String] = ["DIRECT_HP_RATIO", "ENERGY_LOSS", "STOCK_LOSS"]
const ALLOWED_EFFECT_OPS: Array[String] = [
	"DAMAGE_SINGLE", "HEAL_SELF", "MITIGATE_CURRENT_DIRECT", "COUNTER_FROM_PREVENTED_DAMAGE",
	"PROTECT_RESOURCE_LOSS", "LETHAL_SAFETY", "GRANT_PLAYER_BOARD_OPPORTUNITY",
	"ADJUST_CURRENT_ENEMY_ETA",
]

var _definitions: Dictionary = {}
var _definitions_by_lane_stage: Dictionary = {}

static func from_dictionary(data: Dictionary):
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		return null
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
		var lane_stage_key: String = catalog._lane_stage_key(String(definition["lane"]), int(definition["stage"]))
		if catalog._definitions.has(technique_id) or catalog._definitions_by_lane_stage.has(lane_stage_key):
			return null
		catalog._definitions[technique_id] = definition.duplicate(true)
		catalog._definitions_by_lane_stage[lane_stage_key] = technique_id
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
	definitions.sort_custom(func(left: Dictionary, right: Dictionary): return int(left["stage"]) < int(right["stage"]))
	return definitions

func get_by_id(technique_id: String) -> Dictionary:
	if not _definitions.has(technique_id):
		return {}
	return Dictionary(_definitions[technique_id]).duplicate(true)

func definition_for_lane_stage(lane: String, stage: int) -> Dictionary:
	var technique_id := String(_definitions_by_lane_stage.get(_lane_stage_key(lane, stage), ""))
	return get_by_id(technique_id)

func resolve_effects(definition: Dictionary, action_kind: String) -> Dictionary:
	if not _validate_definition(definition):
		return {"ok": false, "reason": "INVALID_DEFINITION", "effects": [], "preview_lines": []}
	var effects := _duplicated_effects(definition.get("effects", []))
	var preview_lines := _duplicated_preview_lines(definition.get("preview_lines", []))
	var action_variants: Array = definition.get("action_variants", [])
	if action_variants.is_empty():
		return {"ok": true, "effects": effects, "preview_lines": preview_lines}
	var matching_variants: Array = []
	for variant_value in action_variants:
		var variant: Dictionary = variant_value
		if Array(variant.get("action_kinds", [])).has(action_kind):
			matching_variants.append(variant)
	if matching_variants.size() != 1:
		return {"ok": false, "reason": "NO_CURRENT_ACTION_VARIANT", "effects": [], "preview_lines": []}
	var selected_variant: Dictionary = matching_variants[0]
	effects.append_array(_duplicated_effects(selected_variant.get("effects", [])))
	preview_lines.append_array(_duplicated_preview_lines(selected_variant.get("preview_lines", [])))
	return {"ok": true, "effects": effects, "preview_lines": preview_lines}

func _validate_definition(definition: Dictionary) -> bool:
	var technique_id := String(definition.get("id", ""))
	var lane := String(definition.get("lane", ""))
	var stage := int(definition.get("stage", 0))
	if technique_id == "" or not LANES.has(lane) or stage < 1 or stage > 10:
		return false
	if definition.has("tier") or definition.has("energy_cost") or definition.has("stock_cost"):
		return false
	if int(definition.get("combo_cost", -1)) != stage or int(definition.get("mp_cost", -1)) < 0:
		return false
	if String(definition.get("display_name", "")) == "" or not _validate_preview_lines(definition.get("preview_lines", [])):
		return false
	var effects: Variant = definition.get("effects", [])
	var variants: Variant = definition.get("action_variants", [])
	if not (effects is Array) or not (variants is Array):
		return false
	if effects.is_empty() and variants.is_empty():
		return false
	return _validate_effect_list(effects, true) and _validate_variants(variants)

func _validate_effect_list(effects: Array, allow_empty: bool = false) -> bool:
	if effects.is_empty() and not allow_empty:
		return false
	for effect_variant in effects:
		if not (effect_variant is Dictionary):
			return false
		var effect: Dictionary = effect_variant
		var op := String(effect.get("op", ""))
		if not ALLOWED_EFFECT_OPS.has(op) or int(effect.get("magnitude", 0)) <= 0:
			return false
		if op == "LETHAL_SAFETY" and int(effect.get("charges", 0)) <= 0:
			return false
	return true

func _validate_variants(variants: Array) -> bool:
	var seen_action_kinds: Dictionary = {}
	for variant_value in variants:
		if not (variant_value is Dictionary):
			return false
		var variant: Dictionary = variant_value
		var action_kinds: Variant = variant.get("action_kinds", [])
		if not (action_kinds is Array) or action_kinds.is_empty():
			return false
		if not _validate_effect_list(variant.get("effects", [])) or not _validate_preview_lines(variant.get("preview_lines", [])):
			return false
		for action_kind_variant in action_kinds:
			var action_kind := String(action_kind_variant)
			if not ADAPTIVE_ACTION_KINDS.has(action_kind) or seen_action_kinds.has(action_kind):
				return false
			seen_action_kinds[action_kind] = true
	return true

func _validate_preview_lines(preview_lines: Variant) -> bool:
	if not (preview_lines is Array) or preview_lines.is_empty():
		return false
	for preview_line in preview_lines:
		if String(preview_line).strip_edges() == "":
			return false
	return true

func _duplicated_effects(raw_effects: Array) -> Array:
	var copied: Array = []
	for raw_effect in raw_effects:
		copied.append(Dictionary(raw_effect).duplicate(true))
	return copied

func _duplicated_preview_lines(raw_preview_lines: Array) -> Array:
	var copied: Array = []
	for preview_line in raw_preview_lines:
		copied.append(String(preview_line))
	return copied

func _lane_stage_key(lane: String, stage: int) -> String:
	return "%s:%d" % [lane, stage]
