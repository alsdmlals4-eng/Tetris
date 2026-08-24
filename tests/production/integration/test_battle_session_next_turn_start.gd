extends GutTest

const BATTLE_PATH := "res://src/production/combat/production_battle_session.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"

func _skill_catalog():
    return ProductionSkillCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH)))

func _enemy_catalog():
    return GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ENEMY_DATA_PATH)))

func _time_config():
    return TurnTimeConfig.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(TIME_DATA_PATH)))

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

func _fixture() -> Dictionary:
    var enemy_catalog = _enemy_catalog()
    var current: Dictionary = enemy_catalog.instantiate_action("light_smash", 1)
    var next: Dictionary = enemy_catalog.instantiate_action("gatebreaker_slam", 2)
    var turn := _turn_in_action()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var effects := TimeEffectState.new()
    var session = load(BATTLE_PATH).new(
        turn,
        player,
        enemy,
        _skill_catalog(),
        GatebreakerTelegraphState.new(current, next),
        ProductionStatusState.new(),
        ProductionResponseState.new(),
        effects,
        ProductionTechniqueResolver.new(ProductionEffectExecutor.new()),
        ProductionEnemyActionResolver.new()
    )
    return {
        "session": session,
        "turn": turn,
        "player": player,
        "enemy": enemy,
        "enemy_catalog": enemy_catalog,
        "effects": effects,
    }

func _finish_enemy_resolve(fixture: Dictionary) -> void:
    var turn: TurnController = fixture["turn"]
    var session = fixture["session"]
    assert_true(turn.select_player_action("PASS"))
    assert_true(session.resolve_player_action()["resolved"])
    var authored_next: Dictionary = fixture["enemy_catalog"].instantiate_action("rift_siphon", 3)
    assert_true(session.resolve_enemy_action(authored_next)["resolved"])
    assert_eq(turn.phase, TurnPhase.ENEMY_TELEGRAPH)

func test_session_starts_fresh_normal_player_turn_after_enemy_resolve() -> void:
    var f := _fixture()
    _finish_enemy_resolve(f)

    var result: Dictionary = f["session"].start_next_player_turn(_time_config(), "NORMAL")

    assert_true(result["started"])
    assert_eq(f["turn"].phase, TurnPhase.LINE)
    assert_eq(f["turn"].turn_budget.effective_budget_seconds, 90.0)
    assert_eq(result["tempo_reference_seconds"], 90.0)

func test_haste_selected_this_turn_flows_into_exactly_next_player_turn_then_expires() -> void:
    var f := _fixture()
    var player: ProductionCombatState = f["player"]
    var session = f["session"]
    var turn: TurnController = f["turn"]
    player.apply_energy_delta(100)
    player.gain_stock(6)

    assert_true(session.select_technique("sup_t3_haste")["accepted"])
    assert_true(session.resolve_player_action()["resolved"])
    assert_eq(f["effects"].get_total_flat_seconds_for_next_turn(), 5.0)
    var authored_next: Dictionary = f["enemy_catalog"].instantiate_action("rift_siphon", 3)
    assert_true(session.resolve_enemy_action(authored_next)["resolved"])
    assert_eq(turn.phase, TurnPhase.ENEMY_TELEGRAPH)

    var next_turn: Dictionary = session.start_next_player_turn(_time_config(), "NORMAL")

    assert_true(next_turn["started"])
    assert_eq(turn.turn_budget.effective_budget_seconds, 95.0)
    assert_eq(next_turn["flat_modifier_seconds"], 5.0)
    assert_eq(next_turn["tempo_reference_seconds"], 90.0)
    assert_eq(f["effects"].get_total_flat_seconds_for_next_turn(), 0.0)

func test_session_does_not_start_another_turn_after_terminal_battle() -> void:
    var f := _fixture()
    var session = f["session"]
    var turn: TurnController = f["turn"]
    session.battle_over = true
    session.outcome = "PLAYER_VICTORY"
    turn.phase = TurnPhase.ENEMY_TELEGRAPH
    var old_budget := turn.turn_budget
    f["effects"].apply_effect("haste", "haste_default", 5.0, false, 1)

    var result: Dictionary = session.start_next_player_turn(_time_config(), "NORMAL")

    assert_false(result["started"])
    assert_eq(result["reason"], "BATTLE_OVER")
    assert_same(turn.turn_budget, old_budget)
    assert_eq(f["effects"].get_total_flat_seconds_for_next_turn(), 5.0)

func test_wrong_phase_is_rejected_without_consuming_pending_time_effects() -> void:
    var f := _fixture()
    f["effects"].apply_effect("haste", "haste_default", 5.0, false, 1)
    var old_budget := f["turn"].turn_budget

    var result: Dictionary = f["session"].start_next_player_turn(_time_config(), "NORMAL")

    assert_false(result["started"])
    assert_eq(result["reason"], "WRONG_PHASE")
    assert_same(f["turn"].turn_budget, old_budget)
    assert_eq(f["effects"].get_total_flat_seconds_for_next_turn(), 5.0)
