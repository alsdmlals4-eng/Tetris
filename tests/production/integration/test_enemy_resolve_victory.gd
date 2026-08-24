extends GutTest

const BATTLE_PATH := "res://src/production/combat/production_battle_session.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"

func _turn_in_action() -> TurnController:
    var budget := TurnBudget.new()
    budget.snapshot(30.0, 0.0, 0.0, 30.0)
    var turn := TurnController.new(budget)
    turn.enter_line()
    turn.request_ready()
    turn.complete_line_settle()
    turn.request_ready()
    turn.complete_chain_settle()
    return turn

func test_counter_lethal_during_enemy_resolve_ends_battle_before_next_telegraph() -> void:
    var skill_catalog := ProductionSkillCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH)))
    var enemy_catalog := GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ENEMY_DATA_PATH)))
    var current: Dictionary = enemy_catalog.instantiate_action("gatebreaker_slam", 1)
    var next: Dictionary = enemy_catalog.instantiate_action("light_smash", 2)
    var authored_after_next: Dictionary = enemy_catalog.instantiate_action("rift_siphon", 3)
    var telegraph := GatebreakerTelegraphState.new(current, next)
    var turn := _turn_in_action()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    enemy.apply_damage(94)
    player.apply_energy_delta(100)
    player.gain_stock(6)
    var session = load(BATTLE_PATH).new(
        turn,
        player,
        enemy,
        skill_catalog,
        telegraph,
        ProductionStatusState.new(),
        ProductionResponseState.new(),
        TimeEffectState.new(),
        ProductionTechniqueResolver.new(ProductionEffectExecutor.new()),
        ProductionEnemyActionResolver.new()
    )

    assert_true(session.select_technique("def_t3_counter_stance")["accepted"])
    assert_true(session.resolve_player_action()["resolved"])
    assert_eq(enemy.hp, 6)

    var result: Dictionary = session.resolve_enemy_action(authored_after_next)

    assert_true(result["resolved"])
    assert_true(result["battle_over"])
    assert_eq(result["outcome"], "PLAYER_VICTORY")
    assert_eq(enemy.hp, 0)
    assert_eq(player.hp, 81, "the already-authored current enemy hit still resolves before the counter victory is adjudicated")
    assert_eq(session.outcome, "PLAYER_VICTORY")
    assert_eq(turn.phase, TurnPhase.ENEMY_RESOLVE, "terminal victory must not open another Telegraph")
    assert_eq(telegraph.current_action()["id"], current["id"])
    assert_eq(telegraph.next_action()["id"], next["id"])
