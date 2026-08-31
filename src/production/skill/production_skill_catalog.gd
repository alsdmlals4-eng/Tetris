## C1–C10 전술 스킬 정의를 검증하고 현재 행동에 맞는 효과 묶음을 조회한다.
class_name ProductionSkillCatalog
extends RefCounted

const LANES: Array[String] = ["ATTACK", "DEFENSE", "SUPPORT"]
const ACTION_KINDS: Array[String] = ["DIRECT_HP_RATIO", "ENERGY_LOSS", "STOCK_LOSS"]
const SOURCE_CONTRACT := "TETRIS-SKILL-039 / TETRIS-BALANCE-040 / TETRIS-SKILL-042"
const ALLOWED_EFFECT_OPS: Array[String] = [
	"DAMAGE_SINGLE", "HEAL_SELF", "MITIGATE_CURRENT_DIRECT", "COUNTER_FROM_PREVENTED_DAMAGE",
	"PROTECT_RESOURCE_LOSS", "LETHAL_SAFETY", "GRANT_PLAYER_BOARD_OPPORTUNITY", "ADJUST_CURRENT_ENEMY_ETA",
]

var _definitions: Dictionary = {}
var _definitions_by_lane_stage: Dictionary = {}

static func from_dictionary(data: Dictionary):
	if String(data.get("balance_status", "")) == "" or String(data.get("source_contract", "")) != SOURCE_CONTRACT:
		return null
	if not data.get("techniques") is Array:
		return null

	var catalog := ProductionSkillCatalog.new()
	for definition_variant in data["techniques"]:
		if not definition_variant is Dictionary:
			return null
		var definition: Dictionary = definition_variant
		if not catalog._validate_definition(definition):
			return null
		var technique_id := String(definition["id"])
		var lane_stage_key := "%s:%d" % [String(definition["lane"]), int(definition["stage"])]
		if catalog._definitions.has(technique_id) or catalog._definitions_by_lane_stage.has(lane_stage_key):
			return null
		catalog._definitions[technique_id] = definition.duplicate(true)
		catalog._definitions_by_lane_stage[lane_stage_key] = technique_id

	if catalog.technique_count() != LANES.size() * 10:
		return null
	for lane in LANES:
		for stage in range(1, 11):
			if catalog.definition_for_lane_stage(lane, stage).is_empty():
				return null
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
	if not LANES.has(lane) or stage < 1 or stage > 10:
		return {}
	var technique_id := String(_definitions_by_lane_stage.get("%s:%d" % [lane, stage], ""))
	return get_by_id(technique_id)

func resolve_effects(definition: Dictionary, action_kind: String) -> Dictionary:
	if definition.is_empty() or not _validate_definition(definition):
		return {"ok": false, "reason": "INVALID_DEFINITION", "effects": [], "preview_lines": []}

	var effects: Array = Array(definition["effects"]).duplicate(true)
	var preview_lines: Array = Array(definition["preview_lines"]).duplicate(true)
	var variants: Array = Array(definition.get("action_variants", []))
	if variants.is_empty():
		return {"ok": true, "effects": effects, "preview_lines": preview_lines}

	var matched_variants: Array = []
	for raw_variant in variants:
		var variant: Dictionary = raw_variant
		if String(variant.get("action_kind", "")) == action_kind:
			matched_variants.append(variant)
	if matched_variants.size() != 1:
		return {"ok": false, "reason": "ACTION_VARIANT_UNAVAILABLE", "effects": [], "preview_lines": []}

	var matched: Dictionary = matched_variants[0]
	effects.append_array(Array(matched["effects"]).duplicate(true))
	preview_lines.append_array(Array(matched["preview_lines"]).duplicate(true))
	return {"ok": true, "effects": effects, "preview_lines": preview_lines}

func _validate_definition(definition: Dictionary) -> bool:
	var technique_id := String(definition.get("id", ""))
	var lane := String(definition.get("lane", ""))
	var stage_value = _integer_value(definition.get("stage", null))
	var combo_cost_value = _integer_value(definition.get("combo_cost", null))
	var mp_cost_value = _integer_value(definition.get("mp_cost", null))
	if technique_id == "" or not LANES.has(lane) or stage_value == null or combo_cost_value == null or mp_cost_value == null:
		return false
	var stage := int(stage_value)
	if stage < 1 or stage > 10 or int(combo_cost_value) != stage or int(mp_cost_value) < 0:
		return false
	if String(definition.get("display_name", "")) == "":
		return false
	if not _validate_preview_lines(definition.get("preview_lines", null)):
		return false
	var raw_effects = definition.get("effects", null)
	var raw_variants = definition.get("action_variants", [])
	if not raw_effects is Array or not raw_variants is Array:
		return false
	if raw_effects.is_empty() and raw_variants.is_empty():
		return false
	if not raw_effects.is_empty() and not _validate_effect_list(raw_effects):
		return false
	return _validate_action_variants(raw_variants)

func _validate_action_variants(raw_variants) -> bool:
	if not raw_variants is Array:
		return false
	if raw_variants.is_empty():
		return true
	if raw_variants.size() != ACTION_KINDS.size():
		return false
	var seen_kinds: Array[String] = []
	for raw_variant in raw_variants:
		if not raw_variant is Dictionary:
			return false
		var variant: Dictionary = raw_variant
		var action_kind := String(variant.get("action_kind", ""))
		if not ACTION_KINDS.has(action_kind) or seen_kinds.has(action_kind):
			return false
		if not _validate_preview_lines(variant.get("preview_lines", null)):
			return false
		if not _validate_effect_list(variant.get("effects", null)):
			return false
		seen_kinds.append(action_kind)
	return true

func _validate_preview_lines(raw_lines) -> bool:
	if not raw_lines is Array or raw_lines.is_empty():
		return false
	for raw_line in raw_lines:
		if String(raw_line).strip_edges() == "":
			return false
	return true

func _validate_effect_list(raw_effects) -> bool:
	if not raw_effects is Array or raw_effects.is_empty():
		return false
	for raw_effect in raw_effects:
		if not raw_effect is Dictionary:
			return false
		var effect: Dictionary = raw_effect
		var magnitude = _integer_value(effect.get("magnitude", null))
		if not ALLOWED_EFFECT_OPS.has(String(effect.get("op", ""))) or magnitude == null or int(magnitude) <= 0:
			return false
	return true

static func _integer_value(raw):
	if not (raw is int or raw is float):
		return null
	var numeric := float(raw)
	var converted := int(numeric)
	if not is_equal_approx(numeric, float(converted)):
		return null
	return converted
