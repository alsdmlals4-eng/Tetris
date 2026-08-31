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
	for effect_variant in definition.get("effects", []):
		if not (effect_variant is Dictionary):
			return {"ready": false, "reason": "INVALID_EFFECT"}
		var effect: Dictionary = effect_variant
		if not _effect_is_ready(effect, context):
			return {"ready": false, "reason": "EFFECT_NOT_READY"}
	return {"ready": true, "reason": "READY"}

func resolve(definition: Dictionary, context: Dictionary) -> Dictionary:
	var preflight := readiness(definition, context)
	if not bool(preflight.get("ready", false)):
		return {"ok": false, "reason": preflight.get("reason", "NOT_READY")}
	var results: Array = []
	for effect_variant in definition["effects"]:
		var effect: Dictionary = effect_variant
		if String(effect.get("op", "")) == "CONDITIONAL_MULTIPLIER":
			continue
		var result: Dictionary = _effect_executor.execute(effect, context)
		if not bool(result.get("ok", false)):
			return {"ok": false, "reason": result.get("reason", "EFFECT_FAILED")}
		results.append(result)
	return {"ok": true, "results": results}

func preflight_effects(effects: Array, context: Dictionary) -> Dictionary:
	if effects.is_empty():
		return {"ok": false, "reason": "NO_EFFECTS"}
	for effect_variant in effects:
		if not effect_variant is Dictionary or not _effect_is_ready(effect_variant, context):
			return {"ok": false, "reason": "EFFECT_NOT_READY"}
	return {"ok": true, "effects": effects.duplicate(true)}

func resolve_preflighted_effects(preflight: Dictionary, context: Dictionary) -> Dictionary:
	if not bool(preflight.get("ok", false)) or not preflight.get("effects") is Array:
		return {"ok": false, "reason": "INVALID_PREFLIGHT"}
	var results: Array = []
	for effect_variant in preflight["effects"]:
		var result: Dictionary = _effect_executor.execute(effect_variant, context)
		if not bool(result.get("ok", false)):
			return {"ok": false, "reason": result.get("reason", "EFFECT_FAILED")}
		results.append(result)
	return {"ok": true, "results": results}

func capture_effect_checkpoint(context: Dictionary) -> Dictionary:
	var checkpoint: Dictionary = {}
	for owner_key in ["player", "enemy"]:
		var owner = context.get(owner_key)
		if owner != null and owner.has_method("snapshot_state"):
			checkpoint[owner_key] = owner.snapshot_state()
	for owner_key in ["response_state", "board_opportunity", "enemy_scheduler"]:
		var owner = context.get(owner_key)
		var method_name: String = String({"response_state": "snapshot_action_state", "board_opportunity": "snapshot_state", "enemy_scheduler": "snapshot_current_action_state"}[owner_key])
		if owner != null and owner.has_method(method_name):
			checkpoint[owner_key] = owner.call(method_name)
	return checkpoint

func restore_effect_checkpoint(checkpoint: Dictionary, context: Dictionary) -> bool:
	for owner_key in ["player", "enemy"]:
		if checkpoint.has(owner_key):
			var owner = context.get(owner_key)
			if owner == null or not owner.has_method("restore_state") or not owner.restore_state(checkpoint[owner_key]):
				return false
	for owner_key in ["response_state", "board_opportunity", "enemy_scheduler"]:
		if checkpoint.has(owner_key):
			var owner = context.get(owner_key)
			var method_name: String = String({"response_state": "restore_action_state", "board_opportunity": "restore_state", "enemy_scheduler": "restore_current_action_state"}[owner_key])
			if owner == null or not owner.has_method(method_name) or not owner.call(method_name, checkpoint[owner_key]):
				return false
	return true

func _effect_is_ready(effect: Dictionary, context: Dictionary) -> bool:
	var op := String(effect.get("op", ""))
	var magnitude := int(effect.get("magnitude", 0))
	if op == "CONDITIONAL_MULTIPLIER":
		return true
	if magnitude <= 0:
		return false
	if op in ["DAMAGE_SINGLE", "DAMAGE_AOE", "TARGET_PATTERN"]:
		return context.get("enemy") != null or (context.get("enemies") is Array and not context["enemies"].is_empty())
	if op == "HEAL_SELF":
		return context.get("player") != null
	if op in ["APPLY_SELF_BUFF", "APPLY_ENEMY_DEBUFF"]:
		return context.get("player_status") != null if op == "APPLY_SELF_BUFF" else context.get("enemy_status") != null
	if op in ["MITIGATE_CURRENT_DIRECT", "COUNTER_FROM_PREVENTED_DAMAGE", "PROTECT_RESOURCE_LOSS", "LETHAL_SAFETY"]:
		return context.get("response_state") != null and String(context.get("telegraph_action_id", "")) != ""
	if op == "GRANT_PLAYER_BOARD_OPPORTUNITY":
		var opportunity = context.get("board_opportunity")
		return opportunity != null and opportunity.has_method("grant")
	if op == "ADJUST_CURRENT_ENEMY_ETA":
		var scheduler = context.get("enemy_scheduler")
		return scheduler != null and scheduler.has_method("adjust_current_eta") and String(context.get("telegraph_action_id", "")) != ""
	return false
