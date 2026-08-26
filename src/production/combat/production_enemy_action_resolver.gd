class_name ProductionEnemyActionResolver
extends RefCounted

func preview(action: Dictionary, context: Dictionary) -> Dictionary:
    var action_id := String(action.get("id", ""))
    var kind := String(action.get("kind", ""))
    if action_id == "":
        return _preview_failed(kind, "INVALID_ENEMY_ACTION_ID")

    match kind:
        "DIRECT_HP_RATIO":
            return _preview_direct_hp_ratio(action_id, action, context)
        "ENERGY_LOSS":
            return _preview_energy_loss(action_id, action, context)
        "STOCK_LOSS":
            return _preview_stock_loss(action_id, action, context)
        "ENEMY_HEAL_RATIO":
            return _preview_enemy_heal_ratio(action_id, action, context)
        _:
            return _preview_failed(kind, "UNSUPPORTED_ENEMY_ACTION_KIND")

func resolve(action: Dictionary, context: Dictionary) -> Dictionary:
    var action_id := String(action.get("id", ""))
    var kind := String(action.get("kind", ""))
    if action_id == "":
        return _failed(kind, "INVALID_ENEMY_ACTION_ID")

    match kind:
        "DIRECT_HP_RATIO":
            return _resolve_direct_hp_ratio(action_id, action, context)
        "ENERGY_LOSS":
            return _resolve_energy_loss(action_id, action, context)
        "STOCK_LOSS":
            return _resolve_stock_loss(action_id, action, context)
        "ENEMY_HEAL_RATIO":
            return _resolve_enemy_heal_ratio(action_id, action, context)
        _:
            return _failed(kind, "UNSUPPORTED_ENEMY_ACTION_KIND")

func _preview_direct_hp_ratio(action_id: String, action: Dictionary, context: Dictionary) -> Dictionary:
    var player = context.get("player")
    if player == null or not player.has_method("apply_damage"):
        return _preview_failed("DIRECT_HP_RATIO", "MISSING_PLAYER_TARGET")

    var ratio := float(action.get("hp_ratio", 0.0))
    if ratio <= 0.0 or ratio > 1.0:
        return _preview_failed("DIRECT_HP_RATIO", "INVALID_HP_RATIO")

    var modifiers := _response_modifiers(action_id, context)
    var base_damage := maxi(1, roundi(float(player.max_hp) * ratio))
    var mitigation := mini(base_damage, maxi(0, int(modifiers.get("direct_mitigation", 0))))
    var pending_damage := maxi(0, base_damage - mitigation)

    var lethal_safety_triggered := false
    var lethal_floor := maxi(0, int(modifiers.get("lethal_hp_floor", 0)))
    var lethal_charges := maxi(0, int(modifiers.get("lethal_charges", 0)))
    if lethal_floor > 0 and lethal_charges > 0 and int(player.hp) - pending_damage < lethal_floor:
        pending_damage = maxi(0, int(player.hp) - lethal_floor)
        lethal_safety_triggered = true

    var counter_ratio := clampf(float(modifiers.get("counter_ratio", 0.0)), 0.0, 1.0)
    var counter_damage := roundi(float(mitigation) * counter_ratio)
    var enemy = context.get("enemy")
    if counter_damage > 0 and (enemy == null or not enemy.has_method("apply_damage")):
        return _preview_failed("DIRECT_HP_RATIO", "MISSING_ENEMY_TARGET_FOR_COUNTER")

    var damage_applied := mini(pending_damage, int(player.hp))
    var counter_applied := 0
    var projected_enemy_hp := -1
    if enemy != null:
        projected_enemy_hp = int(enemy.hp)
        counter_applied = mini(counter_damage, int(enemy.hp))
        projected_enemy_hp -= counter_applied

    return {
        "ready": true,
        "reason": "READY",
        "kind": "DIRECT_HP_RATIO",
        "action_id": action_id,
        "base_damage": base_damage,
        "mitigation_applied": mitigation,
        "damage_applied": damage_applied,
        "counter_damage": counter_applied,
        "lethal_safety_triggered": lethal_safety_triggered,
        "projected_player_hp": int(player.hp) - damage_applied,
        "projected_enemy_hp": projected_enemy_hp,
    }

func _preview_energy_loss(action_id: String, action: Dictionary, context: Dictionary) -> Dictionary:
    var player = context.get("player")
    if player == null or not player.has_method("apply_energy_delta"):
        return _preview_failed("ENERGY_LOSS", "MISSING_PLAYER_TARGET")
    var amount := int(action.get("amount", 0))
    if amount <= 0:
        return _preview_failed("ENERGY_LOSS", "INVALID_RESOURCE_LOSS")

    var ward_ratio := _resource_ward_ratio(action_id, context)
    var prevented := clampi(floori(float(amount) * ward_ratio), 0, amount)
    var requested_loss := amount - prevented
    var applied := mini(requested_loss, int(player.energy))
    var enemy = context.get("enemy")

    return {
        "ready": true,
        "reason": "READY",
        "kind": "ENERGY_LOSS",
        "action_id": action_id,
        "base_loss": amount,
        "prevented_loss": prevented,
        "loss_applied": applied,
        "projected_player_energy": int(player.energy) - applied,
        "projected_enemy_hp": int(enemy.hp) if enemy != null else -1,
    }

func _preview_stock_loss(action_id: String, action: Dictionary, context: Dictionary) -> Dictionary:
    var player = context.get("player")
    if player == null or not player.has_method("lose_stock"):
        return _preview_failed("STOCK_LOSS", "MISSING_PLAYER_TARGET")
    var amount := int(action.get("amount", 0))
    if amount <= 0:
        return _preview_failed("STOCK_LOSS", "INVALID_RESOURCE_LOSS")

    var ward_ratio := _resource_ward_ratio(action_id, context)
    var prevented := clampi(floori(float(amount) * ward_ratio), 0, amount)
    var requested_loss := amount - prevented
    var applied := mini(requested_loss, int(player.stock))
    var enemy = context.get("enemy")

    return {
        "ready": true,
        "reason": "READY",
        "kind": "STOCK_LOSS",
        "action_id": action_id,
        "base_loss": amount,
        "prevented_loss": prevented,
        "loss_applied": applied,
        "projected_player_stock": int(player.stock) - applied,
        "projected_enemy_hp": int(enemy.hp) if enemy != null else -1,
    }

func _preview_enemy_heal_ratio(action_id: String, action: Dictionary, context: Dictionary) -> Dictionary:
    var enemy = context.get("enemy")
    if enemy == null or not enemy.has_method("heal"):
        return _preview_failed("ENEMY_HEAL_RATIO", "MISSING_ENEMY_TARGET")
    var ratio := float(action.get("hp_ratio", 0.0))
    if ratio <= 0.0 or ratio > 1.0:
        return _preview_failed("ENEMY_HEAL_RATIO", "INVALID_HP_RATIO")

    var requested := maxi(1, roundi(float(enemy.max_hp) * ratio))
    var applied := mini(requested, maxi(0, int(enemy.max_hp) - int(enemy.hp)))
    var player = context.get("player")
    return {
        "ready": true,
        "reason": "READY",
        "kind": "ENEMY_HEAL_RATIO",
        "action_id": action_id,
        "heal_requested": requested,
        "heal_applied": applied,
        "projected_player_hp": int(player.hp) if player != null else -1,
        "projected_enemy_hp": int(enemy.hp) + applied,
    }

func _resolve_direct_hp_ratio(action_id: String, action: Dictionary, context: Dictionary) -> Dictionary:
    var player = context.get("player")
    if player == null or not player.has_method("apply_damage"):
        return _failed("DIRECT_HP_RATIO", "MISSING_PLAYER_TARGET")

    var ratio := float(action.get("hp_ratio", 0.0))
    if ratio <= 0.0 or ratio > 1.0:
        return _failed("DIRECT_HP_RATIO", "INVALID_HP_RATIO")

    var modifiers := _response_modifiers(action_id, context)
    var base_damage := maxi(1, roundi(float(player.max_hp) * ratio))
    var mitigation := mini(base_damage, maxi(0, int(modifiers.get("direct_mitigation", 0))))
    var pending_damage := maxi(0, base_damage - mitigation)

    var lethal_safety_triggered := false
    var lethal_floor := maxi(0, int(modifiers.get("lethal_hp_floor", 0)))
    var lethal_charges := maxi(0, int(modifiers.get("lethal_charges", 0)))
    if lethal_floor > 0 and lethal_charges > 0 and int(player.hp) - pending_damage < lethal_floor:
        pending_damage = maxi(0, int(player.hp) - lethal_floor)
        lethal_safety_triggered = true

    var counter_ratio := clampf(float(modifiers.get("counter_ratio", 0.0)), 0.0, 1.0)
    var counter_damage := roundi(float(mitigation) * counter_ratio)
    if counter_damage > 0:
        var enemy = context.get("enemy")
        if enemy == null or not enemy.has_method("apply_damage"):
            return _failed("DIRECT_HP_RATIO", "MISSING_ENEMY_TARGET_FOR_COUNTER")

    var damage_applied := int(player.apply_damage(pending_damage))
    if counter_damage > 0:
        context.get("enemy").apply_damage(counter_damage)

    _consume_response(action_id, context)
    return {
        "resolved": true,
        "kind": "DIRECT_HP_RATIO",
        "action_id": action_id,
        "base_damage": base_damage,
        "mitigation_applied": mitigation,
        "damage_applied": damage_applied,
        "counter_damage": counter_damage,
        "lethal_safety_triggered": lethal_safety_triggered,
        "reason": "RESOLVED",
    }

func _resolve_energy_loss(action_id: String, action: Dictionary, context: Dictionary) -> Dictionary:
    var player = context.get("player")
    if player == null or not player.has_method("apply_energy_delta"):
        return _failed("ENERGY_LOSS", "MISSING_PLAYER_TARGET")
    var amount := int(action.get("amount", 0))
    if amount <= 0:
        return _failed("ENERGY_LOSS", "INVALID_RESOURCE_LOSS")

    var ward_ratio := _resource_ward_ratio(action_id, context)
    var prevented := clampi(floori(float(amount) * ward_ratio), 0, amount)
    var requested_loss := amount - prevented
    var applied := -int(player.apply_energy_delta(-requested_loss))

    _consume_response(action_id, context)
    return {
        "resolved": true,
        "kind": "ENERGY_LOSS",
        "action_id": action_id,
        "base_loss": amount,
        "prevented_loss": prevented,
        "loss_applied": applied,
        "reason": "RESOLVED",
    }

func _resolve_stock_loss(action_id: String, action: Dictionary, context: Dictionary) -> Dictionary:
    var player = context.get("player")
    if player == null or not player.has_method("lose_stock"):
        return _failed("STOCK_LOSS", "MISSING_PLAYER_TARGET")
    var amount := int(action.get("amount", 0))
    if amount <= 0:
        return _failed("STOCK_LOSS", "INVALID_RESOURCE_LOSS")

    var ward_ratio := _resource_ward_ratio(action_id, context)
    var prevented := clampi(floori(float(amount) * ward_ratio), 0, amount)
    var applied := int(player.lose_stock(amount - prevented))

    _consume_response(action_id, context)
    return {
        "resolved": true,
        "kind": "STOCK_LOSS",
        "action_id": action_id,
        "base_loss": amount,
        "prevented_loss": prevented,
        "loss_applied": applied,
        "reason": "RESOLVED",
    }

func _resolve_enemy_heal_ratio(action_id: String, action: Dictionary, context: Dictionary) -> Dictionary:
    var enemy = context.get("enemy")
    if enemy == null or not enemy.has_method("heal"):
        return _failed("ENEMY_HEAL_RATIO", "MISSING_ENEMY_TARGET")
    var ratio := float(action.get("hp_ratio", 0.0))
    if ratio <= 0.0 or ratio > 1.0:
        return _failed("ENEMY_HEAL_RATIO", "INVALID_HP_RATIO")

    var requested := maxi(1, roundi(float(enemy.max_hp) * ratio))
    var applied := int(enemy.heal(requested))
    _consume_response(action_id, context)
    return {
        "resolved": true,
        "kind": "ENEMY_HEAL_RATIO",
        "action_id": action_id,
        "heal_requested": requested,
        "heal_applied": applied,
        "reason": "RESOLVED",
    }

func _response_modifiers(action_id: String, context: Dictionary) -> Dictionary:
    var response_state = context.get("response_state")
    if response_state == null or not response_state.has_method("modifiers_for_action"):
        return {}
    return response_state.modifiers_for_action(action_id)

func _resource_ward_ratio(action_id: String, context: Dictionary) -> float:
    var modifiers := _response_modifiers(action_id, context)
    return clampf(float(modifiers.get("resource_ward_ratio", 0.0)), 0.0, 1.0)

func _consume_response(action_id: String, context: Dictionary) -> void:
    var response_state = context.get("response_state")
    if response_state != null and response_state.has_method("clear_after_action"):
        response_state.clear_after_action(action_id)

func _preview_failed(kind: String, reason: String) -> Dictionary:
    return {
        "ready": false,
        "kind": kind,
        "reason": reason,
    }

func _failed(kind: String, reason: String) -> Dictionary:
    return {
        "resolved": false,
        "kind": kind,
        "reason": reason,
    }
