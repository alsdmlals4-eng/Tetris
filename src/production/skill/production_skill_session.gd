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
var _selected_technique_id: String = ""

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

func select_category(category: String) -> bool:
	if _pause_token == 0 or not LANES.has(category):
		return false
	_selected_category = category
	_selected_technique_id = ""
	return true

func select_technique(technique_id: String) -> Dictionary:
	var definition: Dictionary = _catalog.get_by_id(technique_id)
	if _pause_token == 0 or definition.is_empty() or String(definition.get("lane", "")) != _selected_category:
		return {"selected": false, "reason": "INVALID_TECHNIQUE"}
	_selected_technique_id = technique_id
	return {"selected": true, "technique_id": technique_id}

func selected_detail() -> Dictionary:
	return _catalog.get_by_id(_selected_technique_id)

func readiness(technique_id: String, context: Dictionary) -> Dictionary:
	var definition: Dictionary = _catalog.get_by_id(technique_id)
	if definition.is_empty():
		return {"ready": false, "reason": "UNKNOWN_TECHNIQUE"}
	if String(definition.get("runtime_status", "")) == "REALTIME_MIGRATION_REQUIRED":
		return {"ready": false, "reason": "REALTIME_MIGRATION_REQUIRED"}
	if _combat_state.energy < int(definition.get("mp_cost", 0)) or _combat_state.stock < int(definition.get("combo_cost", 0)):
		return {"ready": false, "reason": "INSUFFICIENT_RESOURCE"}
	return _technique_resolver.readiness(definition, context)

func commit_selected(context: Dictionary) -> Dictionary:
	if _pause_token == 0 or _selected_technique_id == "":
		return {"committed": false, "reason": "NO_SELECTION"}
	var definition: Dictionary = selected_detail()
	var preflight: Dictionary = readiness(_selected_technique_id, context)
	if not bool(preflight.get("ready", false)):
		return {"committed": false, "reason": preflight.get("reason", "NOT_READY")}
	var energy_cost := int(definition["mp_cost"])
	var stock_cost := int(definition["combo_cost"])
	if not _combat_state.try_spend_skill_cost(energy_cost, stock_cost):
		return {"committed": false, "reason": "INSUFFICIENT_RESOURCE"}
	var resolution: Dictionary = _technique_resolver.resolve(definition, context)
	if not bool(resolution.get("ok", false)):
		_combat_state.apply_energy_delta(energy_cost)
		_combat_state.gain_stock(stock_cost)
		return {"committed": false, "reason": resolution.get("reason", "RESOLUTION_FAILED")}
	cancel()
	return {"committed": true, "technique_id": String(definition["id"]), "results": resolution.get("results", [])}

func cancel() -> Dictionary:
	if _pause_token == 0:
		return {"canceled": false, "cancelled": false, "reason": "NOT_OPEN"}
	_pause_controller.release(_pause_token)
	_pause_token = 0
	_selected_category = ""
	_selected_technique_id = ""
	return {"canceled": true, "cancelled": true}
