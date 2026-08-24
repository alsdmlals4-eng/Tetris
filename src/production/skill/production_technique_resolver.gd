class_name ProductionTechniqueResolver
extends RefCounted

const RUNTIME_READY_OPS := [
    "DAMAGE_SINGLE",
    "DAMAGE_AOE",
    "TARGET_PATTERN",
    "HEAL_SELF",
    "APPLY_SELF_BUFF",
    "APPLY_ENEMY_DEBUFF",
    "MITIGATE_CURRENT_DIRECT",
    "COUNTER_FROM_PREVENTED_DAMAGE",
    "PROTECT_RESOURCE_LOSS",
    "LETHAL_SAFETY",
    "MODIFY_NEXT_TURN_BUDGET",
    "CONDITIONAL_MULTIPLIER",
]

var effect_executor: ProductionEffectExecutor

func _init(p_effect_executor: ProductionEffectExecutor) -> void:
    effect_executor = p_effect_executor

func readiness(definition: Dictionary, context: Dictionary) -> Dictionary:
    return _preflight(definition, context)

func resolve(definition: Dictionary, context: Dictionary) -> Dictionary:
    var preflight := _preflight(definition, context)
    if not bool(preflight.get("ready", false)):
        return {
            "resolved": false,
            "reason": String(preflight.get("reason", "PREFLIGHT_FAILED")),
            "technique_id": String(definition.get("id", "")),
            "effect_results": [],
        }

    var preparation := _prepare_effects(definition, context)
    if not bool(preparation.get("ready", false)):
        return {
            "resolved": false,
            "reason": String(preparation.get("reason", "EFFECT_PREPARATION_FAILED")),
            "technique_id": String(definition.get("id", "")),
            "effect_results": [],
        }

    var results: Array[Dictionary] = []
    for effect_value in preparation.get("effects", []):
        var effect: Dictionary = effect_value
        if String(effect.get("op", "")) == "CONDITIONAL_MULTIPLIER":
            continue
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

    _consume_preexisting_attack_status(definition, context, preparation)

    return {
        "resolved": true,
        "reason": "RESOLVED",
        "technique_id": String(definition.get("id", "")),
        "effect_results": results,
        "conditional_multiplier_applied": bool(preparation.get("conditional_multiplier_applied", false)),
        "conditional_multiplier": float(preparation.get("conditional_multiplier", 1.0)),
        "prepared_damage_magnitude": int(preparation.get("prepared_damage_magnitude", 0)),
    }

func _prepare_effects(definition: Dictionary, context: Dictionary) -> Dictionary:
    var prepared: Array[Dictionary] = []
    for effect_value in definition.get("effects", []):
        prepared.append((effect_value as Dictionary).duplicate(true))

    var enemy = context.get("enemy")
    var status_state = context.get("status_state")
    var breach_preexisting := false
    if status_state != null and status_state.has_method("has_status"):
        breach_preexisting = bool(status_state.has_status("BREACH", "enemy"))

    var conditional_applied := false
    var conditional_multiplier := 1.0
    for effect in prepared:
        if String(effect.get("op", "")) != "CONDITIONAL_MULTIPLIER":
            continue
        if not _conditional_matches(effect, enemy, breach_preexisting):
            continue
        conditional_applied = true
        conditional_multiplier = float(effect.get("multiplier", 1.0))

    var prepared_damage_magnitude := 0
    for effect in prepared:
        if String(effect.get("op", "")) != "DAMAGE_SINGLE":
            continue
        var base_magnitude := int(effect.get("magnitude", 0))
        if conditional_applied:
            effect["magnitude"] = roundi(float(base_magnitude) * conditional_multiplier)
        prepared_damage_magnitude = int(effect.get("magnitude", 0))

    return {
        "ready": true,
        "reason": "READY",
        "effects": prepared,
        "breach_preexisting": breach_preexisting,
        "conditional_multiplier_applied": conditional_applied,
        "conditional_multiplier": conditional_multiplier,
        "prepared_damage_magnitude": prepared_damage_magnitude,
    }

func _conditional_matches(effect: Dictionary, enemy, breach_preexisting: bool) -> bool:
    if String(effect.get("condition", "")) != "BREACH_OR_ENEMY_HP_BELOW_RATIO":
        return false
    if breach_preexisting:
        return true
    if enemy == null:
        return false
    var max_hp := int(enemy.max_hp)
    if max_hp <= 0:
        return false
    var hp_ratio := float(effect.get("hp_ratio", 0.0))
    return float(enemy.hp) / float(max_hp) <= hp_ratio

func _consume_preexisting_attack_status(definition: Dictionary, context: Dictionary, preparation: Dictionary) -> void:
    if String(definition.get("lane", "")) != "ATTACK" or not bool(preparation.get("breach_preexisting", false)):
        return
    var status_state = context.get("status_state")
    if status_state != null and status_state.has_method("consume_unbound_for_trigger"):
        status_state.consume_unbound_for_trigger("BREACH", "enemy", "QUALIFYING_PLAYER_ATTACK")

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
        "DAMAGE_AOE":
            if int(effect.get("magnitude", 0)) <= 0:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            var targets: Array = TargetPattern.resolve("ALL_ENEMIES", context)
            if targets.is_empty():
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            for target in targets:
                if target == null or not target.has_method("apply_damage"):
                    return _not_ready("EFFECT_CONTEXT_NOT_READY")
        "TARGET_PATTERN":
            var pattern := String(effect.get("pattern", ""))
            if pattern == "" or TargetPattern.resolve(pattern, context).is_empty():
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
        "CONDITIONAL_MULTIPLIER":
            var enemy = context.get("enemy")
            var multiplier := float(effect.get("multiplier", 0.0))
            var hp_ratio := float(effect.get("hp_ratio", -1.0))
            if enemy == null or String(effect.get("field", "")) != "damage" or multiplier <= 0.0:
                return _not_ready("EFFECT_CONTEXT_NOT_READY")
            if String(effect.get("condition", "")) != "BREACH_OR_ENEMY_HP_BELOW_RATIO" or hp_ratio < 0.0 or hp_ratio > 1.0:
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
