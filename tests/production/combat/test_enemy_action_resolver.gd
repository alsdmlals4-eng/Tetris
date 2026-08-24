extends GutTest

const RESOLVER_PATH := "res://src/production/combat/production_enemy_action_resolver.gd"

func _make_resolver():
    assert_true(ResourceLoader.exists(RESOLVER_PATH), "ProductionEnemyActionResolver script must exist")
    if not ResourceLoader.exists(RESOLVER_PATH):
        return null
    return load(RESOLVER_PATH).new()

func test_light_smash_ratio_damage_uses_player_max_hp_and_exact_action_id() -> void:
    var resolver = _make_resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(200)
    var enemy := ProductionCombatState.new(300)
    var response := ProductionResponseState.new()

    var result: Dictionary = resolver.resolve(
        {"id": "light_smash_1", "kind": "DIRECT_HP_RATIO", "hp_ratio": 0.12},
        {"player": player, "enemy": enemy, "response_state": response}
    )

    assert_true(result["resolved"])
    assert_eq(result["base_damage"], 24)
    assert_eq(result["damage_applied"], 24)
    assert_eq(player.hp, 176)
    assert_eq(enemy.hp, 300)

func test_current_direct_mitigation_and_counter_use_only_exact_telegraph_response() -> void:
    var resolver = _make_resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var response := ProductionResponseState.new()
    response.configure_direct_mitigation("gatebreaker_slam_2", 16)
    response.configure_counter("gatebreaker_slam_2", 0.5)

    var result: Dictionary = resolver.resolve(
        {"id": "gatebreaker_slam_2", "kind": "DIRECT_HP_RATIO", "hp_ratio": 0.35},
        {"player": player, "enemy": enemy, "response_state": response}
    )

    assert_eq(result["base_damage"], 35)
    assert_eq(result["mitigation_applied"], 16)
    assert_eq(result["damage_applied"], 19)
    assert_eq(result["counter_damage"], 8)
    assert_eq(player.hp, 81)
    assert_eq(enemy.hp, 92)
    assert_true(response.modifiers_for_action("gatebreaker_slam_2").is_empty(), "current response is consumed after that exact authored action resolves")

func test_response_bound_to_another_action_does_not_modify_current_action() -> void:
    var resolver = _make_resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var response := ProductionResponseState.new()
    response.configure_direct_mitigation("future_slam", 28)

    var result: Dictionary = resolver.resolve(
        {"id": "light_smash_now", "kind": "DIRECT_HP_RATIO", "hp_ratio": 0.12},
        {"player": player, "enemy": enemy, "response_state": response}
    )

    assert_eq(result["mitigation_applied"], 0)
    assert_eq(result["damage_applied"], 12)
    assert_eq(player.hp, 88)
    assert_eq(response.modifiers_for_action("future_slam")["direct_mitigation"], 28)

func test_lethal_safety_caps_current_direct_hit_at_configured_hp_floor() -> void:
    var resolver = _make_resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var response := ProductionResponseState.new()
    player.apply_damage(70)
    response.configure_lethal_safety("siege_charge_1", 1, 1)

    var result: Dictionary = resolver.resolve(
        {"id": "siege_charge_1", "kind": "DIRECT_HP_RATIO", "hp_ratio": 0.55},
        {"player": player, "enemy": enemy, "response_state": response}
    )

    assert_eq(result["base_damage"], 55)
    assert_eq(result["damage_applied"], 29)
    assert_true(result["lethal_safety_triggered"])
    assert_eq(player.hp, 1)

func test_rift_siphon_applies_energy_loss_after_current_resource_ward() -> void:
    var resolver = _make_resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var response := ProductionResponseState.new()
    player.apply_energy_delta(50)
    response.configure_resource_ward("rift_siphon_1", 0.6)

    var result: Dictionary = resolver.resolve(
        {"id": "rift_siphon_1", "kind": "ENERGY_LOSS", "amount": 20},
        {"player": player, "enemy": enemy, "response_state": response}
    )

    assert_eq(result["base_loss"], 20)
    assert_eq(result["prevented_loss"], 12)
    assert_eq(result["loss_applied"], 8)
    assert_eq(player.energy, 42)

func test_chain_fracture_loses_stock_without_touching_energy() -> void:
    var resolver = _make_resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    player.gain_stock(6)
    player.apply_energy_delta(40)

    var result: Dictionary = resolver.resolve(
        {"id": "chain_fracture_1", "kind": "STOCK_LOSS", "amount": 2},
        {"player": player, "enemy": enemy}
    )

    assert_eq(result["loss_applied"], 2)
    assert_eq(player.stock, 4)
    assert_eq(player.energy, 40)

func test_rift_repair_heals_enemy_by_ratio_of_enemy_max_hp() -> void:
    var resolver = _make_resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(200)
    enemy.apply_damage(80)

    var result: Dictionary = resolver.resolve(
        {"id": "rift_repair_1", "kind": "ENEMY_HEAL_RATIO", "hp_ratio": 0.08},
        {"player": player, "enemy": enemy}
    )

    assert_eq(result["heal_applied"], 16)
    assert_eq(enemy.hp, 136)
    assert_eq(player.hp, 100)

func test_unknown_enemy_action_fails_closed_without_mutation() -> void:
    var resolver = _make_resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    player.apply_energy_delta(30)
    player.gain_stock(4)

    var result: Dictionary = resolver.resolve(
        {"id": "invented", "kind": "HIDDEN_RUBBER_BAND_COUNTER", "amount": 999},
        {"player": player, "enemy": enemy}
    )

    assert_false(result["resolved"])
    assert_eq(result["reason"], "UNSUPPORTED_ENEMY_ACTION_KIND")
    assert_eq(player.hp, 100)
    assert_eq(player.energy, 30)
    assert_eq(player.stock, 4)
    assert_eq(enemy.hp, 100)
