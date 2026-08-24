extends GutTest

const BATTLE_PATH := "res://src/production/combat/production_battle_session.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"

func _skill_catalog() -> ProductionSkillCatalog:
    return ProductionSkillCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH)))

func _enemy_catalog() -> GatebreakerActionCatalog:
    return GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ENEMY_DATA_PATH)))

func _time_config() -> TurnTimeConfig:
    return TurnTimeConfig.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(TIME_DATA_PATH)))

func _fixture() -> Dictionary:
    var catalog := _enemy_catalog()
    var current := catalog.instantiate_action("light_smash", 1)
    var next := catalog.instantiate_action("gatebreaker_slam", 2)
    var budget := TurnBudget.new()
    var turn := TurnController.new(budget)
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var session = load(BATTLE_PATH).new(
        turn,
        player,
        enemy,
        _skill_catalog(),
        GatebreakerTelegraphState.new(current, next),
        ProductionStatusState.new(),
        ProductionResponseState.new(),
        TimeEffectState.new(),
        ProductionTechniqueResolver.new(ProductionEffectExecutor.new()),
        ProductionEnemyActionResolver.new()
    )
    assert_true(session.start_next_player_turn(_time_config(), "NORMAL")["started"])
    return {
        "session": session,
        "turn": turn,
        "player": player,
        "enemy": enemy,
    }

func _enter_action(f: Dictionary, include_line: bool = true, include_chain: bool = true, board_break: bool = false) -> void:
    var session = f["session"]
    var turn: TurnController = f["turn"]
    turn.tick_player_time(45.0)
    if include_line:
        assert_true(session.record_turn_performance_event({"kind": &"production_line_resolved", "energy_delta": 10}))
    if board_break:
        assert_true(session.record_turn_performance_event({"kind": &"production_line_board_break", "reason": "SPAWN_BLOCKED"}))
    turn.request_ready()
    turn.complete_line_settle()
    if include_chain:
        assert_true(session.record_turn_performance_event({"kind": &"production_chain_resolved", "stock_applied": 1}))
    turn.request_ready()
    turn.complete_chain_settle()
    assert_eq(turn.phase, TurnPhase.ACTION)

func test_qualified_non_pass_action_receives_evaluated_tempo_before_resolution() -> void:
    var f := _fixture()
    _enter_action(f)
    var player: ProductionCombatState = f["player"]
    player.apply_energy_delta(10)
    player.gain_stock(1)

    var selected: Dictionary = f["session"].select_technique("atk_t1_quick_cut")

    assert_true(selected["accepted"])
    assert_true(selected["tempo_eligible"])
    assert_eq(selected["tempo_saved_ratio"], 0.5)
    assert_eq(selected["tempo_potency_bonus_ratio"], 0.1)

    var resolved: Dictionary = f["session"].resolve_player_action()
    assert_true(resolved["resolved"])
    assert_eq(f["enemy"].hp, 87, "12 seed damage receives one 10% Tempo potency application")
    assert_eq(resolved["tempo_potency_bonus_ratio"], 0.1)

func test_missing_chain_qualification_keeps_legal_action_at_base_potency() -> void:
    var f := _fixture()
    _enter_action(f, true, false, false)
    var player: ProductionCombatState = f["player"]
    player.apply_energy_delta(10)
    player.gain_stock(1)

    var selected: Dictionary = f["session"].select_technique("atk_t1_quick_cut")

    assert_true(selected["accepted"])
    assert_false(selected["tempo_eligible"])
    assert_eq(selected["tempo_potency_bonus_ratio"], 0.0)
    assert_eq(selected["tempo_ineligible_reason"], "CHAIN_REQUIRED")
    assert_true(f["session"].resolve_player_action()["resolved"])
    assert_eq(f["enemy"].hp, 88)

func test_board_break_disqualifies_tempo_without_making_action_illegal() -> void:
    var f := _fixture()
    _enter_action(f, true, true, true)
    var player: ProductionCombatState = f["player"]
    player.apply_energy_delta(10)
    player.gain_stock(1)

    var selected: Dictionary = f["session"].select_technique("atk_t1_quick_cut")

    assert_true(selected["accepted"])
    assert_false(selected["tempo_eligible"])
    assert_eq(selected["tempo_potency_bonus_ratio"], 0.0)
    assert_eq(selected["tempo_ineligible_reason"], "BOARD_BREAK")
    assert_true(f["session"].resolve_player_action()["resolved"])
    assert_eq(f["enemy"].hp, 88)
