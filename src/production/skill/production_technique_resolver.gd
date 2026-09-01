## realtime에서 지원되는 전술 primitive만 사전검사 후 적용한다.
class_name ProductionTechniqueResolver
extends RefCounted

var _effect_executor

func _init(effect_executor) -> void:
	_effect_executor = effect_executor

func readiness(definition: Dictionary, context: Dictionary) -> Dictionary:
	if definition.is_empty():
		return {"ready": false, "reason": "UNKNOWN_TECHNIQUE"}
	if String(definition.get("runtime_status", "")) == "REALTIME_MIGRATION_REQUIRED":
		return {"ready": false, "reason": "REALTIME_MIGRATION_REQUIRED"}
	return preflight_effects(Array(definition.get("effects", [])), context)

func preflight_effects(effects: Array, context: Dictionary) -> Dictionary:
	if effects.is_empty():
		return {"ready": false, "reason": "INVALID_EFFECT"}
	var prepared_effects: Array = []
	for effect_variant in effects:
		if not (effect_variant is Dictionary):
			return {"ready": false, "reason": "INVALID_EFFECT"}
		var effect: Dictionary = Dictionary(effect_variant).duplicate(true)
		if not _effect_is_ready(effect, context):
			return {"ready": false, "reason": "EFFECT_NOT_READY"}
		prepared_effects.append(effect)
	return {"ready": true, "reason": "READY", "effects": prepared_effects}

func resolve(definition: Dictionary, context: Dictionary) -> Dictionary:
	var preflight := readiness(definition, context)
	if not bool(preflight.get("ready", false)):
		return {"ok": false, "reason": preflight.get("reason", "NOT_READY")}
	return resolve_preflighted_effects(preflight, context)

func resolve_preflighted_effects(preflight: Dictionary, context: Dictionary) -> Dictionary:
	if not bool(preflight.get("ready", false)) or not (preflight.get("effects") is Array):
		return {"ok": false, "reason": "INVALID_PREFLIGHT"}
	var results: Array = []
	for effect_variant in preflight["effects"]:
		if not (effect_variant is Dictionary):
			return {"ok": false, "reason": "INVALID_PREFLIGHT"}
		var result: Dictionary = _effect_executor.execute(Dictionary(effect_variant), context)
		if not bool(result.get("ok", false)):
			return {"ok": false, "reason": result.get("reason", "EFFECT_FAILED")}
		results.append(result)
	return {"ok": true, "results": results}

func capture_effect_checkpoint(effects: Array, context: Dictionary) -> Dictionary:
	var required_owners: Dictionary = {}
	for effect_variant in effects:
		if not (effect_variant is Dictionary):
			return {"ok": false, "reason": "CHECKPOINT_CAPTURE_FAILED"}
		var owner_key := _checkpoint_owner_for_effect(String(Dictionary(effect_variant).get("op", "")))
		if owner_key == "":
			return {"ok": false, "reason": "CHECKPOINT_OWNER_UNSUPPORTED"}
		required_owners[owner_key] = true
	if required_owners.is_empty():
		return {"ok": false, "reason": "CHECKPOINT_CAPTURE_FAILED"}
	var owners: Dictionary = {}
	for owner_key in required_owners:
		var snapshot: Dictionary = _capture_owner_snapshot(String(owner_key), context)
		if snapshot.is_empty():
			return {"ok": false, "reason": "CHECKPOINT_OWNER_UNAVAILABLE"}
		owners[owner_key] = snapshot.duplicate(true)
	return {"ok": true, "owners": owners}

func restore_effect_checkpoint(checkpoint: Dictionary, context: Dictionary) -> bool:
	if checkpoint.size() != 2 or not bool(checkpoint.get("ok", false)) or not (checkpoint.get("owners") is Dictionary):
		return false
	var restored := true
	for owner_key in Dictionary(checkpoint["owners"]):
		var owner_snapshot = Dictionary(checkpoint["owners"])[owner_key]
		if not (owner_snapshot is Dictionary):
			restored = false
			continue
		restored = _restore_owner_snapshot(String(owner_key), Dictionary(owner_snapshot), context) and restored
	return restored

func _checkpoint_owner_for_effect(op: String) -> String:
	if op in ["DAMAGE_SINGLE", "DAMAGE_AOE", "TARGET_PATTERN"]:
		return "enemy"
	if op == "HEAL_SELF":
		return "player"
	if op in ["MITIGATE_CURRENT_DIRECT", "COUNTER_FROM_PREVENTED_DAMAGE", "PROTECT_RESOURCE_LOSS", "LETHAL_SAFETY"]:
		return "response"
	if op == "GRANT_PLAYER_BOARD_OPPORTUNITY":
		return "board"
	if op == "ADJUST_CURRENT_ENEMY_ETA":
		return "scheduler"
	return ""

func _capture_owner_snapshot(owner_key: String, context: Dictionary) -> Dictionary:
	var owner = null
	var method_name := ""
	match owner_key:
		"player":
			owner = context.get("player")
			method_name = "snapshot_state"
		"enemy":
			owner = context.get("enemy")
			method_name = "snapshot_state"
		"response":
			owner = context.get("response_state")
			method_name = "snapshot_action_state"
		"board":
			owner = context.get("board_opportunity")
			method_name = "snapshot_state"
		"scheduler":
			owner = context.get("enemy_scheduler")
			method_name = "snapshot_current_action_state"
		_:
			return {}
	if owner == null or not owner.has_method(method_name):
		return {}
	var snapshot = owner.call(method_name)
	return Dictionary(snapshot) if snapshot is Dictionary else {}

func _restore_owner_snapshot(owner_key: String, snapshot: Dictionary, context: Dictionary) -> bool:
	var owner = null
	var method_name := ""
	match owner_key:
		"player":
			owner = context.get("player")
			method_name = "restore_state"
		"enemy":
			owner = context.get("enemy")
			method_name = "restore_state"
		"response":
			owner = context.get("response_state")
			method_name = "restore_action_state"
		"board":
			owner = context.get("board_opportunity")
			method_name = "restore_state"
		"scheduler":
			owner = context.get("enemy_scheduler")
			method_name = "restore_current_action_state"
		_:
			return false
	return owner != null and owner.has_method(method_name) and bool(owner.call(method_name, snapshot))

func _effect_is_ready(effect: Dictionary, context: Dictionary) -> bool:
	var op := String(effect.get("op", ""))
	var raw_magnitude = effect.get("magnitude", 0)
	if not (raw_magnitude is int or raw_magnitude is float):
		return false
	var magnitude := float(raw_magnitude)
	if is_nan(magnitude) or is_inf(magnitude) or magnitude <= 0.0:
		return false
	if op in ["DAMAGE_SINGLE", "DAMAGE_AOE", "TARGET_PATTERN"]:
		return context.get("enemy") != null or (context.get("enemies") is Array and not context["enemies"].is_empty())
	if op == "HEAL_SELF":
		return context.get("player") != null
	if op in ["MITIGATE_CURRENT_DIRECT", "COUNTER_FROM_PREVENTED_DAMAGE", "PROTECT_RESOURCE_LOSS", "LETHAL_SAFETY"]:
		return context.get("response_state") != null and String(context.get("telegraph_action_id", "")) != ""
	if op == "GRANT_PLAYER_BOARD_OPPORTUNITY":
		var board_opportunity = context.get("board_opportunity")
		return board_opportunity != null and board_opportunity.has_method("grant") and board_opportunity.has_method("snapshot_state") and board_opportunity.has_method("restore_state")
	if op == "ADJUST_CURRENT_ENEMY_ETA":
		var scheduler = context.get("enemy_scheduler")
		return scheduler != null and scheduler.has_method("adjust_current_eta") and scheduler.has_method("snapshot_current_action_state") and scheduler.has_method("restore_current_action_state") and String(context.get("telegraph_action_id", "")) != "" and not scheduler.is_action_committed()
	return false
