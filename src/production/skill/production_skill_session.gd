## 전술 스킬 탐색과 명시적 USE를 full simulation pause 안에서 분리한다.
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
	_selected_preview = _build_preview(category, context)
	return _selected_preview.duplicate(true)

func selected_preview() -> Dictionary:
	return _selected_preview.duplicate(true)

func commit_selected(context: Dictionary) -> Dictionary:
	if _pause_token == 0 or _selected_preview.is_empty():
		return {"committed": false, "reason": "NO_SELECTION"}
	if not bool(_selected_preview.get("ready", false)):
		return {"committed": false, "reason": _selected_preview.get("reason", "NOT_READY")}
	var preflight: Dictionary = _technique_resolver.preflight_effects(Array(_selected_preview.get("effects", [])), context)
	if not bool(preflight.get("ready", false)):
		return {"committed": false, "reason": preflight.get("reason", "NOT_READY")}
	var checkpoint: Dictionary = _technique_resolver.capture_effect_checkpoint(Array(preflight.get("effects", [])), context)
	if not bool(checkpoint.get("ok", false)):
		return {"committed": false, "reason": checkpoint.get("reason", "CHECKPOINT_CAPTURE_FAILED")}
	var resource_snapshot: Dictionary = _combat_state.resource_snapshot()
	var resource_commit: Dictionary = _combat_state.try_commit_combo_skill(
		int(_selected_preview.get("mp_cost", -1)),
		int(_selected_preview.get("opening_combo", -1)),
		int(_selected_preview.get("resolved_stage", -1))
	)
	if not bool(resource_commit.get("committed", false)):
		return {"committed": false, "reason": resource_commit.get("reason", "INSUFFICIENT_RESOURCE")}
	var resolution: Dictionary = _technique_resolver.resolve_preflighted_effects(preflight, context)
	if not bool(resolution.get("ok", false)):
		var resources_restored: bool = _combat_state.restore_resource_snapshot(resource_snapshot)
		var effects_restored: bool = _technique_resolver.restore_effect_checkpoint(checkpoint, context)
		if not resources_restored or not effects_restored:
			return {"committed": false, "reason": "ROLLBACK_FAILED", "resolution_reason": resolution.get("reason", "RESOLUTION_FAILED")}
		return {"committed": false, "reason": resolution.get("reason", "RESOLUTION_FAILED")}
	var preview := _selected_preview.duplicate(true)
	cancel()
	return {"committed": true, "technique_id": String(preview.get("technique_id", "")), "preview": preview, "results": resolution.get("results", [])}

func cancel() -> Dictionary:
	if _pause_token == 0:
		return {"canceled": false, "cancelled": false, "reason": "NOT_OPEN"}
	_pause_controller.release(_pause_token)
	_pause_token = 0
	_selected_category = ""
	_selected_preview = {}
	return {"canceled": true, "cancelled": true}

func _build_preview(category: String, context: Dictionary) -> Dictionary:
	var opening_combo := _combat_state.stock
	if opening_combo < 1 or opening_combo > ProductionCombatState.COMBO_CAP:
		return {"selected": true, "ready": false, "reason": "INSUFFICIENT_COMBO", "opening_combo": opening_combo}
	var opening_definition: Dictionary = _catalog.definition_for_lane_stage(category, opening_combo)
	if opening_definition.is_empty():
		return {"selected": true, "ready": false, "reason": "MISSING_COMBO_STAGE", "opening_combo": opening_combo}
	var opening_effects: Dictionary = _catalog.resolve_effects(opening_definition, String(context.get("current_action_kind", "")))
	if not bool(opening_effects.get("ok", false)):
		return {"selected": true, "ready": false, "reason": opening_effects.get("reason", "NO_CURRENT_ACTION_VARIANT"), "opening_combo": opening_combo}
	for resolved_stage in range(opening_combo, 0, -1):
		var definition: Dictionary = _catalog.definition_for_lane_stage(category, resolved_stage)
		if definition.is_empty():
			continue
		var resolved_effects: Dictionary = opening_effects if resolved_stage == opening_combo else _catalog.resolve_effects(definition, String(context.get("current_action_kind", "")))
		if not bool(resolved_effects.get("ok", false)):
			continue
		var converted_combo := opening_combo - resolved_stage
		var available_mp := mini(ProductionCombatState.MP_CAP, _combat_state.energy + converted_combo * 5)
		var mp_cost := int(definition.get("mp_cost", -1))
		if mp_cost < 0 or available_mp < mp_cost:
			continue
		var preflight: Dictionary = _technique_resolver.preflight_effects(Array(resolved_effects.get("effects", [])), context)
		if not bool(preflight.get("ready", false)):
			return {"selected": true, "ready": false, "reason": preflight.get("reason", "EFFECT_NOT_READY"), "opening_combo": opening_combo}
		return {
			"selected": true,
			"ready": true,
			"category": category,
			"technique_id": String(definition.get("id", "")),
			"display_name": String(definition.get("display_name", "")),
			"opening_combo": opening_combo,
			"resolved_stage": resolved_stage,
			"converted_combo": converted_combo,
			"mp_cost": mp_cost,
			"preview_lines": Array(resolved_effects.get("preview_lines", [])).duplicate(true),
			"effects": Array(resolved_effects.get("effects", [])).duplicate(true),
		}
	return {"selected": true, "ready": false, "reason": "INSUFFICIENT_RESOURCE", "opening_combo": opening_combo}
