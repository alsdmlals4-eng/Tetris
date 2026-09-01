## 검증된 전술 스킬 primitive를 전투 상태에 적용한다.
class_name ProductionEffectExecutor
extends RefCounted

const TARGET_PATTERN_SCRIPT = preload("res://src/production/targeting/target_pattern.gd")

func execute(effect: Dictionary, context: Dictionary) -> Dictionary:
	var op := String(effect.get("op", ""))
	var magnitude := float(effect.get("magnitude", 0.0))
	match op:
		"DAMAGE_SINGLE":
			return _damage_targets([context.get("enemy")], int(magnitude))
		"DAMAGE_AOE":
			return _damage_targets(TARGET_PATTERN_SCRIPT.resolve("ALL_ENEMIES", context), int(magnitude))
		"TARGET_PATTERN":
			return _damage_targets(TARGET_PATTERN_SCRIPT.resolve(String(effect.get("target", "SINGLE_ENEMY")), context), int(magnitude))
		"HEAL_SELF":
			var player = context.get("player")
			if player == null or not player.has_method("heal"):
				return {"ok": false, "reason": "INVALID_PLAYER"}
			return {"ok": true, "applied": player.heal(int(magnitude))}
		"APPLY_SELF_BUFF":
			return _apply_status(context.get("player_status"), String(effect.get("status", "")), int(magnitude))
		"APPLY_ENEMY_DEBUFF":
			return _apply_status(context.get("enemy_status"), String(effect.get("status", "")), int(magnitude))
		"MITIGATE_CURRENT_DIRECT":
			return _configure_response(context, "configure_direct_mitigation", int(magnitude))
		"COUNTER_FROM_PREVENTED_DAMAGE":
			return _configure_response(context, "configure_counter", int(magnitude))
		"PROTECT_RESOURCE_LOSS":
			return _configure_response(context, "configure_resource_ward", int(magnitude))
		"LETHAL_SAFETY":
			var response = context.get("response_state")
			var action_id := String(context.get("telegraph_action_id", ""))
			if response == null or not response.has_method("configure_lethal_safety"):
				return {"ok": false, "reason": "INVALID_RESPONSE_STATE"}
			return {"ok": response.configure_lethal_safety(action_id, int(magnitude), int(effect.get("charges", 1)))}
		"GRANT_PLAYER_BOARD_OPPORTUNITY":
			var board_opportunity = context.get("board_opportunity")
			if board_opportunity == null or not board_opportunity.has_method("grant"):
				return {"ok": false, "reason": "INVALID_BOARD_OPPORTUNITY"}
			var granted: Dictionary = board_opportunity.grant(magnitude)
			granted["ok"] = bool(granted.get("granted", false))
			return granted
		"ADJUST_CURRENT_ENEMY_ETA":
			var scheduler = context.get("enemy_scheduler")
			var current_action_id := String(context.get("telegraph_action_id", ""))
			if scheduler == null or not scheduler.has_method("adjust_current_eta") or current_action_id == "":
				return {"ok": false, "reason": "INVALID_ENEMY_SCHEDULER"}
			var adjusted: Dictionary = scheduler.adjust_current_eta(current_action_id, magnitude)
			adjusted["ok"] = bool(adjusted.get("adjusted", false))
			return adjusted
	return {"ok": false, "reason": "UNSUPPORTED_EFFECT"}

func _damage_targets(targets: Array, magnitude: int) -> Dictionary:
	if magnitude <= 0 or targets.is_empty():
		return {"ok": false, "reason": "INVALID_TARGET"}
	var applied := 0
	for target in targets:
		if target == null or not target.has_method("apply_damage"):
			return {"ok": false, "reason": "INVALID_TARGET"}
		applied += target.apply_damage(magnitude)
	return {"ok": true, "applied": applied}

func _apply_status(status_state, status_id: String, magnitude: int) -> Dictionary:
	if status_state == null or not status_state.has_method("apply_status") or status_id == "" or magnitude <= 0:
		return {"ok": false, "reason": "INVALID_STATUS_STATE"}
	return {"ok": status_state.apply_status(status_id, magnitude)}

func _configure_response(context: Dictionary, method_name: String, magnitude: int) -> Dictionary:
	var response = context.get("response_state")
	var action_id := String(context.get("telegraph_action_id", ""))
	if response == null or not response.has_method(method_name) or action_id == "" or magnitude <= 0:
		return {"ok": false, "reason": "INVALID_RESPONSE_STATE"}
	var value: Variant = float(magnitude) / 100.0 if method_name != "configure_direct_mitigation" else magnitude
	return {"ok": response.call(method_name, action_id, value)}
