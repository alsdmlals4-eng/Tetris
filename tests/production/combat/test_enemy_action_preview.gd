## Gatebreaker 행동 미리보기의 상태 비변이를 검증한다.
extends GutTest

func test_direct_preview_predicts_player_and_enemy_hp_without_consuming_response() -> void:
    var resolver := ProductionEnemyActionResolver.new()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var response := ProductionResponseState.new()
    response.configure_direct_mitigation("gatebreaker_slam_preview", 16)
    response.configure_counter("gatebreaker_slam_preview", 0.5)
    var action := {"id": "gatebreaker_slam_preview", "kind": "DIRECT_HP_RATIO", "hp_ratio": 0.35}

    var preview: Dictionary = resolver.preview(action, {
        "player": player,
        "enemy": enemy,
        "response_state": response,
    })

    assert_true(preview["ready"])
    assert_eq(preview["projected_player_hp"], 81)
    assert_eq(preview["projected_enemy_hp"], 92)
    assert_eq(preview["counter_damage"], 8)
    assert_eq(player.hp, 100)
    assert_eq(enemy.hp, 100)
    assert_eq(response.modifiers_for_action("gatebreaker_slam_preview")["direct_mitigation"], 16)

    var actual: Dictionary = resolver.resolve(action, {
        "player": player,
        "enemy": enemy,
        "response_state": response,
    })
    assert_true(actual["resolved"])
    assert_eq(player.hp, preview["projected_player_hp"])
    assert_eq(enemy.hp, preview["projected_enemy_hp"])

func test_repair_preview_predicts_post_resolve_boss_hp_without_healing_early() -> void:
    var resolver := ProductionEnemyActionResolver.new()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(200)
    enemy.apply_damage(90)
    var action := {"id": "rift_repair_preview", "kind": "ENEMY_HEAL_RATIO", "hp_ratio": 0.08}

    var preview: Dictionary = resolver.preview(action, {"player": player, "enemy": enemy})

    assert_true(preview["ready"])
    assert_eq(preview["projected_enemy_hp"], 126)
    assert_eq(preview["heal_applied"], 16)
    assert_eq(enemy.hp, 110)

    var actual: Dictionary = resolver.resolve(action, {"player": player, "enemy": enemy})
    assert_true(actual["resolved"])
    assert_eq(enemy.hp, preview["projected_enemy_hp"])

func test_resource_loss_preview_keeps_boss_hp_and_does_not_spend_player_resource() -> void:
    var resolver := ProductionEnemyActionResolver.new()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    player.apply_energy_delta(50)
    var action := {"id": "rift_siphon_preview", "kind": "ENERGY_LOSS", "amount": 20}

    var preview: Dictionary = resolver.preview(action, {"player": player, "enemy": enemy})

    assert_true(preview["ready"])
    assert_eq(preview["projected_enemy_hp"], 100)
    assert_eq(preview["projected_player_energy"], 30)
    assert_eq(player.energy, 50)
    assert_eq(enemy.hp, 100)

func test_preview_fails_closed_for_unsupported_action_without_mutation() -> void:
    var resolver := ProductionEnemyActionResolver.new()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)

    var preview: Dictionary = resolver.preview(
        {"id": "hidden_reaction", "kind": "PLAYER_READ_COUNTER"},
        {"player": player, "enemy": enemy}
    )

    assert_false(preview["ready"])
    assert_eq(preview["reason"], "UNSUPPORTED_ENEMY_ACTION_KIND")
    assert_eq(player.hp, 100)
    assert_eq(enemy.hp, 100)
