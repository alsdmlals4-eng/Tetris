extends GutTest

func _resolver() -> ProductionTechniqueResolver:
    return ProductionTechniqueResolver.new(ProductionEffectExecutor.new())

func _base_context() -> Dictionary:
    return {
        "player": ProductionCombatState.new(100),
        "enemy": ProductionCombatState.new(100),
        "status_state": ProductionStatusState.new(),
        "response_state": ProductionResponseState.new(),
        "time_effect_state": TimeEffectState.new(),
        "current_telegraph_action_id": "light_smash_1",
    }

func test_tempo_scales_attack_damage_once_before_effect_resolution() -> void:
    var context := _base_context()
    context["tempo_potency_bonus_ratio"] = 0.2
    var definition := {
        "id": "tempo_attack",
        "lane": "ATTACK",
        "effects": [{"op": "DAMAGE_SINGLE", "magnitude": 10}],
    }

    var result: Dictionary = _resolver().resolve(definition, context)

    assert_true(result["resolved"])
    assert_eq(context["enemy"].hp, 88)
    assert_eq(result["prepared_damage_magnitude"], 12)
    assert_eq(result["tempo_potency_bonus_ratio"], 0.2)

func test_tempo_scales_support_healing_without_touching_resources() -> void:
    var context := _base_context()
    context["player"].apply_damage(50)
    context["player"].apply_energy_delta(30)
    context["player"].gain_stock(4)
    context["tempo_potency_bonus_ratio"] = 0.2
    var definition := {
        "id": "tempo_heal",
        "lane": "SUPPORT",
        "effects": [{"op": "HEAL_SELF", "magnitude": 10}],
    }

    var result: Dictionary = _resolver().resolve(definition, context)

    assert_true(result["resolved"])
    assert_eq(context["player"].hp, 62)
    assert_eq(context["player"].energy, 30)
    assert_eq(context["player"].stock, 4)

func test_tempo_scales_direct_mitigation_but_not_response_identity() -> void:
    var context := _base_context()
    context["tempo_potency_bonus_ratio"] = 0.2
    var definition := {
        "id": "tempo_guard",
        "lane": "DEFENSE",
        "effects": [{"op": "MITIGATE_CURRENT_DIRECT", "magnitude": 10}],
    }

    var result: Dictionary = _resolver().resolve(definition, context)

    assert_true(result["resolved"])
    var modifiers: Dictionary = context["response_state"].modifiers_for_action("light_smash_1")
    assert_eq(modifiers["direct_mitigation"], 12)
    assert_true(context["response_state"].modifiers_for_action("other_action").is_empty())

func test_tempo_never_scales_haste_seconds() -> void:
    var context := _base_context()
    context["tempo_potency_bonus_ratio"] = 0.5
    var definition := {
        "id": "tempo_haste",
        "lane": "SUPPORT",
        "effects": [{
            "op": "MODIFY_NEXT_TURN_BUDGET",
            "seconds": 5.0,
            "tempo_scalable": false,
            "source_id": "tempo_haste",
            "stack_group": "haste_default",
            "stackable": false,
            "expires_after_turns": 1,
        }],
    }

    var result: Dictionary = _resolver().resolve(definition, context)

    assert_true(result["resolved"])
    assert_eq(context["time_effect_state"].get_total_flat_seconds_for_next_turn(), 5.0)

func test_zero_or_missing_tempo_bonus_preserves_base_potency() -> void:
    for context in [_base_context(), _base_context()]:
        if context == null:
            continue
    var no_bonus := _base_context()
    var zero_bonus := _base_context()
    zero_bonus["tempo_potency_bonus_ratio"] = 0.0
    var definition := {
        "id": "base_attack",
        "lane": "ATTACK",
        "effects": [{"op": "DAMAGE_SINGLE", "magnitude": 10}],
    }

    var no_bonus_result: Dictionary = _resolver().resolve(definition, no_bonus)
    var zero_bonus_result: Dictionary = _resolver().resolve(definition, zero_bonus)

    assert_true(no_bonus_result["resolved"])
    assert_true(zero_bonus_result["resolved"])
    assert_eq(no_bonus["enemy"].hp, 90)
    assert_eq(zero_bonus["enemy"].hp, 90)
