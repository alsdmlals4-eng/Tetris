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
