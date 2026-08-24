extends GutTest

const BATTLE_PATH := "res://src/production/combat/production_battle_session.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"

func _time_config() -> TurnTimeConfig:
    return TurnTimeConfig.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(TIME_DATA_PATH)))

func _skill_catalog() -> ProductionSkillCatalog:
    return ProductionSkillCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH)))

func _enemy_catalog() -> GatebreakerActionCatalog:
    return GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ENEMY_DATA_PATH)))

func _controller_with_budget(seconds: float = 10.0) -> TurnController:
    var budget := TurnBudget.new()
    budget.snapshot(seconds, 0.0, 0.0, seconds)
    return TurnController.new(budget)

func _battle_fixture() -> Dictionary:
    var enemy_catalog := _enemy_catalog()
    var current := enemy_catalog.instantiate_action("light_smash", 1)
    var next := enemy_catalog.instantiate_action("gatebreaker_slam", 2)
    var turn := TurnController.new(TurnBudget.new())
    var session = load(BATTLE_PATH).new(
        turn,
        ProductionCombatState.new(100),
        ProductionCombatState.new(100),
        _skill_catalog(),
        GatebreakerTelegraphState.new(current, next),
        ProductionStatusState.new(),
        ProductionResponseState.new(),
        TimeEffectState.new(),
        ProductionTechniqueResolver.new(ProductionEffectExecutor.new()),
        ProductionEnemyActionResolver.new()
    )
    assert_true(session.start_next_player_turn(_time_config(), "NORMAL")["started"])
    return {"session": session, "turn": turn}

func test_line_timeout_sets_persistent_turn_provenance_until_next_successful_start() -> void:
    var turn := _controller_with_budget(5.0)
    turn.enter_line()

    turn.tick_player_time(5.0)

    assert_true(turn.timed_out_this_turn)
    assert_eq(turn.phase, TurnPhase.LINE_SETTLE)
    turn.complete_line_settle()
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)
    assert_eq(turn.pending_player_action.id, "PASS")
    assert_true(turn.timed_out_this_turn)
    assert_true(turn.complete_player_resolve())
    assert_true(turn.complete_enemy_resolve())
    assert_true(turn.timed_out_this_turn, "timeout provenance survives through enemy resolve and telegraph")

    var started: Dictionary = turn.start_player_turn(_time_config(), "NORMAL")

    assert_true(started["started"])
    assert_false(turn.timed_out_this_turn)

func test_failed_next_turn_start_does_not_erase_timeout_provenance() -> void:
    var turn := _controller_with_budget(1.0)
    turn.enter_line()
    turn.tick_player_time(1.0)
    turn.complete_line_settle()
    assert_true(turn.complete_player_resolve())
    assert_true(turn.complete_enemy_resolve())
    assert_true(turn.timed_out_this_turn)

    var failed: Dictionary = turn.start_player_turn(_time_config(), "MISSING_PROFILE")

    assert_false(failed["started"])
    assert_true(turn.timed_out_this_turn)

func test_action_timeout_pass_reports_timeout_as_tempo_disqualifier() -> void:
    var f := _battle_fixture()
    var turn: TurnController = f["turn"]
    turn.request_ready()
    turn.complete_line_settle()
    turn.request_ready()
    turn.complete_chain_settle()
    assert_eq(turn.phase, TurnPhase.ACTION)

    turn.tick_player_time(turn.turn_budget.remaining_seconds)
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)
    assert_eq(turn.pending_player_action.id, "PASS")

    var result: Dictionary = f["session"].resolve_player_action()

    assert_true(result["resolved"])
    assert_true(result["passed"])
    assert_true(result["timeout_occurred"])
    assert_false(result["tempo_eligible"])
    assert_eq(result["tempo_ineligible_reason"], "TIMEOUT")
