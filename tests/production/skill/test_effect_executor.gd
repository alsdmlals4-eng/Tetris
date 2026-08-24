extends GutTest

const EXECUTOR_PATH := "res://src/production/skill/production_effect_executor.gd"

func _make_executor():
    assert_true(ResourceLoader.exists(EXECUTOR_PATH), "ProductionEffectExecutor script must exist")
    if not ResourceLoader.exists(EXECUTOR_PATH):
        return null
    return load(EXECUTOR_PATH).new()

func test_damage_single_mutates_enemy_hp_only_and_reports_applied_damage() -> void:
    var executor = _make_executor()
    if executor == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(80)
    var status := ProductionStatusState.new()

    var result: Dictionary = executor.execute(
        {"op": "DAMAGE_SINGLE", "magnitude": 18},
        {"player": player, "enemy": enemy, "status_state": status}
    )

    assert_true(result["applied"])
    assert_eq(result["op"], "DAMAGE_SINGLE")
    assert_eq(result["amount"], 18)
    assert_eq(enemy.hp, 62)
    assert_eq(player.hp, 100)

func test_heal_self_clamps_to_player_max_hp_without_touching_resources() -> void:
    var executor = _make_executor()
    if executor == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(80)
    var status := ProductionStatusState.new()
    player.apply_damage(9)
    player.apply_energy_delta(33)
    player.gain_stock(4)

    var result: Dictionary = executor.execute(
        {"op": "HEAL_SELF", "magnitude": 14},
        {"player": player, "enemy": enemy, "status_state": status}
    )

    assert_true(result["applied"])
    assert_eq(result["amount"], 9)
    assert_eq(player.hp, 100)
    assert_eq(player.energy, 33)
    assert_eq(player.stock, 4)
    assert_eq(enemy.hp, 80)

func test_approved_self_and_enemy_status_primitives_use_bounded_status_state() -> void:
    var executor = _make_executor()
    if executor == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(80)
    var status := ProductionStatusState.new()

    var self_result: Dictionary = executor.execute(
        {"op": "APPLY_SELF_BUFF", "status": "RALLY", "stacks": 1},
        {"player": player, "enemy": enemy, "status_state": status}
    )
    var enemy_result: Dictionary = executor.execute(
        {"op": "APPLY_ENEMY_DEBUFF", "status": "BREACH", "stacks": 1},
        {"player": player, "enemy": enemy, "status_state": status}
    )

    assert_true(self_result["applied"])
    assert_true(enemy_result["applied"])
    assert_true(status.has_status("RALLY", "player"))
    assert_true(status.has_status("BREACH", "enemy"))

func test_unapproved_or_tune_required_status_fails_closed_without_inventing_runtime_semantics() -> void:
    var executor = _make_executor()
    if executor == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(80)
    var status := ProductionStatusState.new()

    var unresolved: Dictionary = executor.execute(
        {"op": "APPLY_ENEMY_DEBUFF", "status_contract": "TUNE_REQUIRED"},
        {"player": player, "enemy": enemy, "status_state": status}
    )
    var unknown: Dictionary = executor.execute(
        {"op": "APPLY_ENEMY_DEBUFF", "status": "POISON", "stacks": 99},
        {"player": player, "enemy": enemy, "status_state": status}
    )

    assert_false(unresolved["applied"])
    assert_eq(unresolved["reason"], "STATUS_CONTRACT_UNRESOLVED")
    assert_false(unknown["applied"])
    assert_eq(unknown["reason"], "STATUS_REJECTED")
    assert_false(status.has_status("POISON", "enemy"))

func test_unknown_effect_op_fails_closed_without_mutation() -> void:
    var executor = _make_executor()
    if executor == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(80)
    var status := ProductionStatusState.new()

    var result: Dictionary = executor.execute(
        {"op": "INVENTED_RUNTIME_MAGIC", "magnitude": 9999},
        {"player": player, "enemy": enemy, "status_state": status}
    )

    assert_false(result["applied"])
    assert_eq(result["reason"], "UNSUPPORTED_EFFECT_OP")
    assert_eq(player.hp, 100)
    assert_eq(enemy.hp, 80)

func test_visible_next_forecast_debuff_requires_and_binds_exact_action_id() -> void:
    var executor = _make_executor()
    if executor == null:
        return
    var status := ProductionStatusState.new()
    var effect := {
        "op": "APPLY_ENEMY_DEBUFF",
        "status": "WEAKEN",
        "stacks": 1,
        "bind_to": "VISIBLE_NEXT_FORECAST_ACTION_ID",
    }

    var missing: Dictionary = executor.execute(effect, {"status_state": status})
    assert_false(missing["applied"])
    assert_eq(missing["reason"], "STATUS_REJECTED")
    assert_false(status.has_status("WEAKEN", "enemy"))

    var applied: Dictionary = executor.execute(effect, {
        "status_state": status,
        "next_forecast_action_id": "forecast_action_42",
    })
    assert_true(applied["applied"])
    assert_true(status.matches_bound_action("WEAKEN", "enemy", "forecast_action_42"))
    assert_false(status.matches_bound_action("WEAKEN", "enemy", "forecast_action_43"))

func test_haste_writes_next_turn_modifier_without_jumping_current_budget() -> void:
    var executor = _make_executor()
    if executor == null:
        return
    var time_state := TimeEffectState.new()
    var current_budget := TurnBudget.new()
    current_budget.snapshot(90.0, 0.0, 30.0, 120.0)
    current_budget.consume(12.0)

    var result: Dictionary = executor.execute(
        {
            "op": "MODIFY_NEXT_TURN_BUDGET",
            "seconds": 5.0,
            "tempo_scalable": false,
            "source_id": "sup_t3_haste",
            "stack_group": "haste_default",
            "stackable": false,
            "expires_after_turns": 1,
        },
        {
            "time_effect_state": time_state,
            "current_turn_budget": current_budget,
        }
    )

    assert_true(result["applied"])
    assert_eq(result["seconds"], 5.0)
    assert_false(result["tempo_scalable"])
    assert_eq(current_budget.effective_budget_seconds, 90.0, "Haste created after snapshot must not change current effective budget")
    assert_eq(current_budget.remaining_seconds, 78.0, "Haste must not jump the visible current timer")
    assert_eq(time_state.get_total_flat_seconds_for_next_turn(), 5.0)

    executor.execute(
        {
            "op": "MODIFY_NEXT_TURN_BUDGET",
            "seconds": 5.0,
            "tempo_scalable": false,
            "source_id": "sup_t3_haste",
            "stack_group": "haste_default",
            "stackable": false,
            "expires_after_turns": 1,
        },
        {"time_effect_state": time_state}
    )
    assert_eq(time_state.get_total_flat_seconds_for_next_turn(), 5.0, "same non-stackable Haste group refreshes instead of adding")

func test_haste_fails_closed_without_time_effect_state_or_with_tempo_scaling() -> void:
    var executor = _make_executor()
    if executor == null:
        return
    var missing: Dictionary = executor.execute(
        {"op": "MODIFY_NEXT_TURN_BUDGET", "seconds": 5.0, "tempo_scalable": false},
        {}
    )
    assert_false(missing["applied"])
    assert_eq(missing["reason"], "MISSING_TIME_EFFECT_STATE")

    var forbidden: Dictionary = executor.execute(
        {
            "op": "MODIFY_NEXT_TURN_BUDGET",
            "seconds": 5.0,
            "tempo_scalable": true,
            "source_id": "sup_t3_haste",
            "stack_group": "haste_default",
            "stackable": false,
            "expires_after_turns": 1,
        },
        {"time_effect_state": TimeEffectState.new()}
    )
    assert_false(forbidden["applied"])
    assert_eq(forbidden["reason"], "TEMPO_SCALING_NOT_ALLOWED")
