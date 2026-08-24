class_name ProductionEffectExecutor
extends RefCounted

func execute(effect: Dictionary, context: Dictionary) -> Dictionary:
    var op := String(effect.get("op", ""))
    match op:
        "DAMAGE_SINGLE":
            return _damage_single(effect, context)
        "HEAL_SELF":
            return _heal_self(effect, context)
        "APPLY_SELF_BUFF":
            return _apply_status(effect, context, "player")
        "APPLY_ENEMY_DEBUFF":
            return _apply_status(effect, context, "enemy")
        "MITIGATE_CURRENT_DIRECT":
            return _mitigate_current_direct(effect, context)
        "COUNTER_FROM_PREVENTED_DAMAGE":
            return _counter_from_prevented_damage(effect, context)
        "PROTECT_RESOURCE_LOSS":
            return _protect_resource_loss(effect, context)
        "LETHAL_SAFETY":
            return _lethal_safety(effect, context)
        "MODIFY_NEXT_TURN_BUDGET":
            return _modify_next_turn_budget(effect, context)
        _:
            return _failed(op, "UNSUPPORTED_EFFECT_OP")

func _damage_single(effect: Dictionary, context: Dictionary) -> Dictionary:
    var enemy = context.get("enemy")
    if enemy == null or not enemy.has_method("apply_damage"):
        return _failed("DAMAGE_SINGLE", "MISSING_ENEMY_TARGET")
    var magnitude := int(effect.get("magnitude", 0))
    if magnitude <= 0:
        return _failed("DAMAGE_SINGLE", "INVALID_MAGNITUDE")
    var applied := int(enemy.apply_damage(magnitude))
    return {
        "applied": applied > 0,
        "op": "DAMAGE_SINGLE",
        "amount": applied,
        "reason": "APPLIED" if applied > 0 else "NO_EFFECT",
    }

func _heal_self(effect: Dictionary, context: Dictionary) -> Dictionary:
    var player = context.get("player")
    if player == null or not player.has_method("heal"):
        return _failed("HEAL_SELF", "MISSING_PLAYER_TARGET")
    var magnitude := int(effect.get("magnitude", 0))
    if magnitude <= 0:
        return _failed("HEAL_SELF", "INVALID_MAGNITUDE")
    var applied := int(player.heal(magnitude))
    return {
        "applied": applied > 0,
        "op": "HEAL_SELF",
        "amount": applied,
        "reason": "APPLIED" if applied > 0 else "NO_EFFECT",
    }

func _apply_status(effect: Dictionary, context: Dictionary, target: String) -> Dictionary:
    if String(effect.get("status_contract", "")) == "TUNE_REQUIRED":
        return _failed(String(effect.get("op", "")), "STATUS_CONTRACT_UNRESOLVED")

    var status := String(effect.get("status", ""))
    var status_state = context.get("status_state")
    if status_state == null or not status_state.has_method("apply_status"):
        return _failed(String(effect.get("op", "")), "MISSING_STATUS_STATE")
    if status == "":
        return _failed(String(effect.get("op", "")), "STATUS_CONTRACT_UNRESOLVED")

    var stacks := int(effect.get("stacks", 1))
    var bind_to := String(effect.get("bind_to", ""))
    var accepted := false
    if bind_to == "":
        accepted = bool(status_state.apply_status(status, target, stacks))
    else:
        var action_id_key := ""
        match bind_to:
            "VISIBLE_NEXT_FORECAST_ACTION_ID":
                action_id_key = "next_forecast_action_id"
            "CURRENT_TELEGRAPH_ACTION_ID":
                action_id_key = "current_telegraph_action_id"
            _:
                return _failed(String(effect.get("op", "")), "STATUS_REJECTED")
        var action_id := String(context.get(action_id_key, ""))
        if status_state.has_method("apply_bound_status"):
            accepted = bool(status_state.apply_bound_status(status, target, action_id, bind_to))

    if not accepted:
        return _failed(String(effect.get("op", "")), "STATUS_REJECTED")

    return {
        "applied": true,
        "op": String(effect.get("op", "")),
        "status": status,
        "target": target,
        "reason": "APPLIED",
    }

func _mitigate_current_direct(effect: Dictionary, context: Dictionary) -> Dictionary:
    var response_state = context.get("response_state")
    if response_state == null or not response_state.has_method("configure_direct_mitigation"):
        return _failed("MITIGATE_CURRENT_DIRECT", "MISSING_RESPONSE_STATE")
    var action_id := String(context.get("current_telegraph_action_id", ""))
    if action_id == "":
        return _failed("MITIGATE_CURRENT_DIRECT", "MISSING_CURRENT_TELEGRAPH")
    var magnitude := int(effect.get("magnitude", 0))
    if magnitude <= 0:
        return _failed("MITIGATE_CURRENT_DIRECT", "INVALID_MITIGATION_MAGNITUDE")
    if not bool(response_state.configure_direct_mitigation(action_id, magnitude)):
        return _failed("MITIGATE_CURRENT_DIRECT", "RESPONSE_BINDING_REJECTED")
    return {
        "applied": true,
        "op": "MITIGATE_CURRENT_DIRECT",
        "action_id": action_id,
        "magnitude": magnitude,
        "reason": "APPLIED",
    }

func _counter_from_prevented_damage(effect: Dictionary, context: Dictionary) -> Dictionary:
    var response_state = context.get("response_state")
    if response_state == null or not response_state.has_method("configure_counter"):
        return _failed("COUNTER_FROM_PREVENTED_DAMAGE", "MISSING_RESPONSE_STATE")
    var action_id := String(context.get("current_telegraph_action_id", ""))
    if action_id == "":
        return _failed("COUNTER_FROM_PREVENTED_DAMAGE", "MISSING_CURRENT_TELEGRAPH")
    var ratio := float(effect.get("ratio", 0.0))
    if ratio <= 0.0 or ratio > 1.0:
        return _failed("COUNTER_FROM_PREVENTED_DAMAGE", "INVALID_COUNTER_RATIO")
    if not bool(response_state.configure_counter(action_id, ratio)):
        return _failed("COUNTER_FROM_PREVENTED_DAMAGE", "RESPONSE_BINDING_REJECTED")
    return {
        "applied": true,
        "op": "COUNTER_FROM_PREVENTED_DAMAGE",
        "action_id": action_id,
        "ratio": ratio,
        "reason": "APPLIED",
    }

func _protect_resource_loss(effect: Dictionary, context: Dictionary) -> Dictionary:
    var response_state = context.get("response_state")
    if response_state == null or not response_state.has_method("configure_resource_ward"):
        return _failed("PROTECT_RESOURCE_LOSS", "MISSING_RESPONSE_STATE")
    var action_id := String(context.get("current_telegraph_action_id", ""))
    if action_id == "":
        return _failed("PROTECT_RESOURCE_LOSS", "MISSING_CURRENT_TELEGRAPH")
    if String(effect.get("bind_to", "")) != "CURRENT_TELEGRAPH_ACTION_ID":
        return _failed("PROTECT_RESOURCE_LOSS", "INVALID_RESOURCE_WARD_BINDING")
    var ratio := float(effect.get("ratio", 0.0))
    if ratio <= 0.0 or ratio > 1.0:
        return _failed("PROTECT_RESOURCE_LOSS", "INVALID_RESOURCE_WARD_RATIO")
    if not bool(response_state.configure_resource_ward(action_id, ratio)):
        return _failed("PROTECT_RESOURCE_LOSS", "RESPONSE_BINDING_REJECTED")
    return {
        "applied": true,
        "op": "PROTECT_RESOURCE_LOSS",
        "action_id": action_id,
        "ratio": ratio,
        "reason": "APPLIED",
    }

func _lethal_safety(effect: Dictionary, context: Dictionary) -> Dictionary:
    var response_state = context.get("response_state")
    if response_state == null or not response_state.has_method("configure_lethal_safety"):
        return _failed("LETHAL_SAFETY", "MISSING_RESPONSE_STATE")
    var action_id := String(context.get("current_telegraph_action_id", ""))
    if action_id == "":
        return _failed("LETHAL_SAFETY", "MISSING_CURRENT_TELEGRAPH")
    var hp_floor := int(effect.get("hp_floor", 0))
    var charges := int(effect.get("charges", 0))
    if hp_floor < 1 or charges < 1:
        return _failed("LETHAL_SAFETY", "INVALID_LETHAL_SAFETY_CONFIG")
    if not bool(response_state.configure_lethal_safety(action_id, hp_floor, charges)):
        return _failed("LETHAL_SAFETY", "RESPONSE_BINDING_REJECTED")
    return {
        "applied": true,
        "op": "LETHAL_SAFETY",
        "action_id": action_id,
        "hp_floor": hp_floor,
        "charges": charges,
        "reason": "APPLIED",
    }

func _modify_next_turn_budget(effect: Dictionary, context: Dictionary) -> Dictionary:
    var time_effect_state = context.get("time_effect_state")
    if time_effect_state == null or not time_effect_state.has_method("apply_effect"):
        return _failed("MODIFY_NEXT_TURN_BUDGET", "MISSING_TIME_EFFECT_STATE")
    if bool(effect.get("tempo_scalable", true)):
        return _failed("MODIFY_NEXT_TURN_BUDGET", "TEMPO_SCALING_NOT_ALLOWED")

    var seconds := float(effect.get("seconds", 0.0))
    var source_id := String(effect.get("source_id", ""))
    var stack_group := String(effect.get("stack_group", ""))
    var stackable := bool(effect.get("stackable", false))
    var expires_after_turns := int(effect.get("expires_after_turns", 1))
    if is_zero_approx(seconds) or source_id == "" or stack_group == "" or expires_after_turns == 0:
        return _failed("MODIFY_NEXT_TURN_BUDGET", "INVALID_TIME_EFFECT_CONFIG")

    time_effect_state.apply_effect(
        source_id,
        stack_group,
        seconds,
        stackable,
        expires_after_turns
    )
    return {
        "applied": true,
        "op": "MODIFY_NEXT_TURN_BUDGET",
        "seconds": seconds,
        "tempo_scalable": false,
        "source_id": source_id,
        "stack_group": stack_group,
        "reason": "APPLIED",
    }

func _failed(op: String, reason: String) -> Dictionary:
    return {
        "applied": false,
        "op": op,
        "reason": reason,
    }
