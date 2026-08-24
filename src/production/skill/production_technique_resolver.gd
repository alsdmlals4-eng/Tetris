class_name ProductionTechniqueResolver
extends RefCounted

const RUNTIME_READY_OPS := [
    "DAMAGE_SINGLE",
    "HEAL_SELF",
    "APPLY_SELF_BUFF",
    "APPLY_ENEMY_DEBUFF",
    "MITIGATE_CURRENT_DIRECT",
    "COUNTER_FROM_PREVENTED_DAMAGE",
    "PROTECT_RESOURCE_LOSS",
    "LETHAL_SAFETY",
    "MODIFY_NEXT_TURN_BUDGET",
]

var effect_executor: ProductionEffectExecutor

func _init(p_effect_executor: ProductionEffectExecutor) -> void:
    effect_executor = p_effect_executor

func resolve(definition: Dictionary, context: Dictionary) -> Dictionary:
    var preflight := _preflight(definition, context)
    if not bool(preflight.get("ready", false)):
        return {
            "resolved": false,
            "reason": String(preflight.get("reason", "PREFLIGHT_FAILED")),
            "technique_id": String(definition.get("id", "")),
            "effect_results": [],
        }

    var results: Array[Dictionary] = []
    for effect_value in definition.get("effects", []):
        var effect: Dictionary = effect_value
        var result: Dictionary = effect_executor.execute(effect, context)
        if not bool(result.get("applied", false)):
            return {
                "resolved": false,
                "reason": "EFFECT_EXECUTION_FAILED",
                "technique_id": String(definition.get("id", "")),
                "effect_results": results,
                "failure": result,
            }
        results.append(result)

    return {
        "resolved": true,
        "reason": "RESOLVED",
        "technique_id": String(definition.get("id", "")),
        "effect_results": results,
    }

func _preflight(definition: Dictionary, context: Dictionary) -> Dictionary:
    if definition.is_empty() or String(definition.get("id", "")) == "":
        return _not_ready("INVALID_TECHNIQUE_DEFINITION")

    var effects: Array = definition.get("effects", [])
    if effects.is_empty():
        return _not_ready("INVALID_TECHNIQUE_DEFINITION")

    var scope_check := _preflight_control_scope(String(definition.get("control_scope", "")), context)
    if not bool(scope_check.get("ready", false)):
        return scope_check

    for effect_value in effects:
        if not effect_value is Dictionary:
            return _not_ready("INVALID_EFFECT_DEFINITION")
        var effect: Dictionary = effect_value
        if String(effect.get("status_contract", "")) == "TUNE_REQUIRED":
            return _not_ready("EFFECT_CONTRACT_UNRESOLVED")

        var op := String(effect.get("op", ""))
        if not RUNTIME_READY_OPS.has(op):
            return _not_ready("EFFECT_OP_NOT_RUNTIME_READY")

        var context_check := _preflight_effect_context(effect, context)
        if not bool(context_check.get("ready", false)):
            return context_check

    return {"ready": true, "reason": "READY"}

func _preflight_control_scope(control_scope: String, context: Dictionary) -> Dictionary:
    match control_scope:
        "":
            return {"ready": true, "reason": "READY"}
        "VISIBLE_NEXT_FORECAST_DIRECT":
            var next_id := String(context.get("next_forecast_action_id", ""))
            var tags: Array = context.get("next_forecast_tags", [])
            if next_id == "" or not tags.has("DIRECT_HIT"):
                return _not_ready("FORECAST_SCOPE_MISMATCH")
            return {"ready": true, "reason": "READY"}
        "VISIBLE_NEXT_FORECAST_RIFT_UTILITY":
            var next_id := String(context.get("next_forecast_action_id", ""))
            var tags: Array = context.get("next_forecast_tags", [])
            if next_id == "" or not tags.has("RIFT_UTILITY"):
                return _not_ready("FORECAST_SCOPE_MISMATCH")
            return {"ready": true, "reason": "READY"}
        _:
            return {"ready": true, "reason": "READY"}

func _preflight_effect_context(effect: Dictionary, context: Dictionary) -> Dictionary:
    var op := String(effect.get("op", ""))
    match op:
        "DAMAGE_SINGLE":
            var enemy = context.get("enemy")
            if enemy == null or not enemy.has_method("apply_damage") or int(effect.get("magnitude", 0)) <= 0:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
        "HEAL_SELF":
            var player = context.get("player")
            if player == null or not player.has_method("heal") or int(effect.get("magnitude", 0)) <= 0:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
        "APPLY_SELF_BUFF", "APPLY_ENEMY_DEBUFF":
            var status_state = context.get("status_state")
            var status := String(effect.get("status", ""))
            if status_state == null or not status_state.has_method("apply_status") or status == "":
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            if status_state.has_method("allowed_statuses") and not status_state.allowed_statuses().has(status):
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            var bind_to := String(effect.get("bind_to", ""))
            if bind_to == "VISIBLE_NEXT_FORECAST_ACTION_ID" and String(context.get("next_forecast_action_id", "")) == "":
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            if bind_to == "CURRENT_TELEGRAPH_ACTION_ID" and String(context.get("current_telegraph_action_id", "")) == "":
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            if bind_to != "" and bind_to != "VISIBLE_NEXT_FORECAST_ACTION_ID" and bind_to != "CURRENT_TELEGRAPH_ACTION_ID":
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
        "MITIGATE_CURRENT_DIRECT":
            if not _response_ready(context) or int(effect.get("magnitude", 0)) <= 0:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
        "COUNTER_FROM_PREVENTED_DAMAGE":
            var ratio := float(effect.get("ratio", 0.0))
            if not _response_ready(context) or ratio <= 0.0 or ratio > 1.0:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
        "PROTECT_RESOURCE_LOSS":
            var ratio := float(effect.get("ratio", 0.0))
            if not _response_ready(context) or String(effect.get("bind_to", "")) != "CURRENT_TELEGRAPH_ACTION_ID" or ratio <= 0.0 or ratio > 1.0:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
        "LETHAL_SAFETY":
            if not _response_ready(context) or int(effect.get("hp_floor", 0)) < 1 or int(effect.get("charges", 0)) < 1:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
        "MODIFY_NEXT_TURN_BUDGET":
            var time_effect_state = context.get("time_effect_state")
            if time_effect_state == null or not time_effect_state.has_method("apply_effect"):
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            if bool(effect.get("tempo_scalable", true)):
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            if is_zero_approx(float(effect.get("seconds", 0.0))):
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            if String(effect.get("source_id", "")) == "" or String(effect.get("stack_group", "")) == "" or int(effect.get("expires_after_turns", 1)) == 0:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
    return {"ready": true, "reason": "READY"}

func _response_ready(context: Dictionary) -> bool:
    var response_state = context.get("response_state")
    return response_state != null and String(context.get("current_telegraph_action_id", "")) != ""

func _not_ready(reason: String) -> Dictionary:
    return {
        "ready": false,
        "reason": reason,
    }
