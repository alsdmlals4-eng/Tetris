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
        var action_id_key := "next_forecast_action_id" if bind_to == "VISIBLE_NEXT_FORECAST_ACTION_ID" else "current_telegraph_action_id"
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

func _failed(op: String, reason: String) -> Dictionary:
    return {
        "applied": false,
        "op": op,
        "reason": reason,
    }
