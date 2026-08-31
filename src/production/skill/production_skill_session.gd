## 현재 Combo로 ATK·DEF·SUP 스킬을 해석하고 명시적 CONFIRM만 원자적으로 적용한다.
class_name ProductionSkillSession
extends RefCounted

const TACTICAL_SKILL := "TACTICAL_SKILL"
const LANES := ["ATTACK", "DEFENSE", "SUPPORT"]

var _pause_controller: SimulationPauseController
var _combat_state: ProductionCombatState
var _catalog
var _technique_resolver
var _pause_token: int = 0
var _selected_category: String = ""
var _selected_preview: Dictionary = {}

func _init(pause_controller: SimulationPauseController, combat_state: ProductionCombatState, catalog, technique_resolver) -> void:
	_pause_controller = pause_controller
	_combat_state = combat_state
	_catalog = catalog
	_technique_resolver = technique_resolver

func open() -> bool:
	if _pause_token != 0:
		return true
	_pause_token = _pause_controller.acquire(TACTICAL_SKILL)
	return _pause_token != 0

func is_open() -> bool:
	return _pause_token != 0

func select_category(category: String, context: Dictionary) -> Dictionary:
	if _pause_token == 0 or not LANES.has(category):
		return {"selected": false, "ready": false, "reason": "INVALID_CATEGORY"}
	_selected_category = category
	_selected_preview = _preview_for_current_combo(category, context)
	return _selected_preview.duplicate(true)

func selected_preview() -> Dictionary:
	return _selected_preview.duplicate(true)

func selected_detail() -> Dictionary:
	return selected_preview()

## 전술 정지나 자원 소비 없이 C1-C10 내용을 미리 읽는다.
func inspect_stage(category: String, stage: int, context: Dictionary) -> Dictionary:
	if not LANES.has(category) or stage < 1 or stage > 10:
		return {"inspectable": false, "reason": "INVALID_STAGE"}
	var definition: Dictionary = _catalog.definition_for_lane_stage(category, stage)
	if definition.is_empty():
		return {"inspectable": false, "reason": "MISSING_STAGE"}
	var resolved: Dictionary = _catalog.resolve_effects(definition, String(context.get("current_action_kind", "")))
	if not bool(resolved.get("ok", false)):
		return {"inspectable": false, "reason": resolved.get("reason", "INVALID_EFFECT_PACKAGE")}
	return {
		"inspectable": true,
		"id": definition["id"],
		"lane": category,
		"stage": stage,
		"display_name": definition["display_name"],
		"preview_lines": resolved["preview_lines"],
		"effects": resolved["effects"],
		"combo_cost": int(definition["combo_cost"]),
		"mp_cost": int(definition["mp_cost"]),
	}

func commit_selected(context: Dictionary) -> Dictionary:
	if _pause_token == 0 or _selected_preview.is_empty() or not bool(_selected_preview.get("ready", false)):
		return {"committed": false, "reason": "NO_READY_PREVIEW"}
	var effects: Array = Array(_selected_preview.get("effects", []))
	var preflight: Dictionary = _technique_resolver.preflight_effects(effects, context)
	if not bool(preflight.get("ok", false)):
		return {"committed": false, "reason": preflight.get("reason", "EFFECT_PREFLIGHT_FAILED")}
	var resource_snapshot: Dictionary = _combat_state.resource_snapshot()
	var effect_checkpoint: Dictionary = _technique_resolver.capture_effect_checkpoint(context)
	var transaction: Dictionary = _combat_state.try_commit_combo_skill(int(_selected_preview["mp_cost"]), int(_selected_preview["opening_combo"]), int(_selected_preview["resolved_stage"]))
	if not bool(transaction.get("committed", false)):
		return transaction
	var resolution: Dictionary = _technique_resolver.resolve_preflighted_effects(preflight, context)
	if not bool(resolution.get("ok", false)):
		var resource_restored: bool = _combat_state.restore_resource_snapshot(resource_snapshot)
		var effects_restored: bool = _technique_resolver.restore_effect_checkpoint(effect_checkpoint, context)
		if not resource_restored or not effects_restored:
			return {"committed": false, "reason": "ROLLBACK_FAILED", "resolution_reason": resolution.get("reason", "EFFECT_FAILED")}
		return {"committed": false, "reason": resolution.get("reason", "EFFECT_FAILED")}
	var preview := selected_preview()
	cancel()
	return {"committed": true, "preview": preview, "results": resolution.get("results", [])}

func cancel() -> Dictionary:
	if _pause_token == 0:
		return {"canceled": false, "cancelled": false, "reason": "NOT_OPEN"}
	_pause_controller.release(_pause_token)
	_pause_token = 0
	_selected_category = ""
	_selected_preview = {}
	return {"canceled": true, "cancelled": true}

func _preview_for_current_combo(category: String, context: Dictionary) -> Dictionary:
	var opening_combo := _combat_state.stock
	if opening_combo < 1:
		return {"selected": true, "ready": false, "reason": "NO_COMBO", "opening_combo": opening_combo}
	for stage in range(opening_combo, 0, -1):
		var definition: Dictionary = _catalog.definition_for_lane_stage(category, stage)
		if definition.is_empty():
			return {"selected": true, "ready": false, "reason": "MISSING_STAGE"}
		var converted_combo := opening_combo - stage
		var available_mp := mini(ProductionCombatState.MP_CAP, _combat_state.energy + converted_combo * 5)
		var mp_cost := int(definition.get("mp_cost", -1))
		if available_mp < mp_cost:
			continue
		var resolved: Dictionary = _catalog.resolve_effects(definition, String(context.get("current_action_kind", "")))
		if not bool(resolved.get("ok", false)):
			return {"selected": true, "ready": false, "reason": resolved.get("reason", "INVALID_EFFECT_PACKAGE")}
		var preflight: Dictionary = _technique_resolver.preflight_effects(Array(resolved["effects"]), context)
		return {
			"selected": true,
			"ready": bool(preflight.get("ok", false)),
			"reason": preflight.get("reason", "READY"),
			"id": definition["id"],
			"display_name": definition["display_name"],
			"preview_lines": resolved["preview_lines"],
			"effects": resolved["effects"],
			"opening_combo": opening_combo,
			"resolved_stage": stage,
			"converted_combo": converted_combo,
			"mp_cost": mp_cost,
		}
	return {"selected": true, "ready": false, "reason": "INSUFFICIENT_RESOURCE", "opening_combo": opening_combo}
