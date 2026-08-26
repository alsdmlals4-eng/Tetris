extends GutTest

const PRESENTER_PATH := "res://src/production/ui/production_battle_presenter.gd"
const BATTLE_PATH := "res://src/production/combat/production_battle_session.gd"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"

func _enemy_catalog() -> GatebreakerActionCatalog:
    return GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ENEMY_DATA_PATH)))

func _skill_catalog() -> ProductionSkillCatalog:
    return ProductionSkillCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH)))

func _time_config() -> TurnTimeConfig:
    return TurnTimeConfig.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(TIME_DATA_PATH)))

func _fixture() -> Dictionary:
    var enemy_catalog := _enemy_catalog()
    var current := enemy_catalog.instantiate_action("light_smash", 1)
    var next := enemy_catalog.instantiate_action("gatebreaker_slam", 2)
    var turn := TurnController.new(TurnBudget.new())
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var battle = load(BATTLE_PATH).new(
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
    assert_true(battle.start_next_player_turn(_time_config(), "NORMAL")["started"])
    return {
        "battle": battle,
        "turn": turn,
        "player": player,
        "enemy": enemy,
    }

func _presenter():
    var script = load(PRESENTER_PATH)
    assert_not_null(script, "ProductionBattlePresenter must exist")
    if script == null:
        return null
    return script.new()

func test_snapshot_reads_authoritative_telegraph_phase_budget_and_resources() -> void:
    var presenter = _presenter()
    if presenter == null:
        return
    var f := _fixture()
    var snapshot: Dictionary = presenter.snapshot(f["battle"])

    assert_eq(snapshot["phase"], "LINE")
    assert_eq(snapshot["remaining_seconds"], 90.0)
    assert_true(String(snapshot["current_telegraph"]).contains("Light Smash"))
    assert_true(String(snapshot["current_telegraph"]).contains("12"))
    assert_true(String(snapshot["next_forecast"]).contains("Gatebreaker Slam"))
    assert_eq(snapshot["player_hp"], 100)
    assert_eq(snapshot["player_max_hp"], 100)
    assert_eq(snapshot["energy"], 0)
    assert_eq(snapshot["stock"], 0)
    assert_false(snapshot["ready_available"])

func test_action_snapshot_uses_public_runtime_readiness_for_all_eighteen_cells() -> void:
    var presenter = _presenter()
    if presenter == null:
        return
    var f := _fixture()
    var battle = f["battle"]
    var turn: TurnController = f["turn"]
    var player: ProductionCombatState = f["player"]

    player.apply_energy_delta(100)
    player.gain_stock(ProductionCombatState.STOCK_CAP)
    turn.tick_player_time(45.0)
    assert_true(battle.record_turn_performance_event({"kind": &"production_line_resolved", "energy_delta": 10}))
    turn.request_ready()
    turn.complete_line_settle()
    assert_true(battle.record_turn_performance_event({"kind": &"production_chain_resolved", "stock_applied": 1}))
    turn.request_ready()
    turn.complete_chain_settle()
    assert_eq(turn.phase, TurnPhase.ACTION)

    var snapshot: Dictionary = presenter.snapshot(battle)
    var readiness: Dictionary = snapshot["technique_readiness"]

    assert_eq(readiness.size(), 18)
    assert_true(readiness["atk_t1_quick_cut"]["ready"])
    assert_true(readiness["atk_t5_suppressive_break"]["ready"], "visible next direct Forecast makes ATK T5 runtime-applicable")
    assert_false(readiness["sup_t5_rift_seal"]["ready"])
    assert_eq(readiness["sup_t5_rift_seal"]["reason"], "FORECAST_SCOPE_MISMATCH")
    assert_false(readiness["sup_t4_mark_weakness"]["ready"])
    assert_eq(readiness["sup_t4_mark_weakness"]["reason"], "EFFECT_CONTRACT_UNRESOLVED")

func test_action_snapshot_exposes_provisional_tempo_without_mutating_turn_or_resources() -> void:
    var presenter = _presenter()
    if presenter == null:
        return
    var f := _fixture()
    var battle = f["battle"]
    var turn: TurnController = f["turn"]
    var player: ProductionCombatState = f["player"]

    player.apply_energy_delta(30)
    player.gain_stock(3)
    turn.tick_player_time(45.0)
    assert_true(battle.record_turn_performance_event({"kind": &"production_line_resolved", "energy_delta": 10}))
    turn.request_ready()
    turn.complete_line_settle()
    assert_true(battle.record_turn_performance_event({"kind": &"production_chain_resolved", "stock_applied": 1}))
    turn.request_ready()
    turn.complete_chain_settle()

    var hp_before := player.hp
    var energy_before := player.energy
    var stock_before := player.stock
    var phase_before := turn.phase
    var snapshot: Dictionary = presenter.snapshot(battle)

    assert_true(snapshot["tempo_eligible"])
    assert_eq(snapshot["tempo_saved_ratio"], 0.5)
    assert_eq(snapshot["tempo_potency_bonus_ratio"], 0.1)
    assert_eq(player.hp, hp_before)
    assert_eq(player.energy, energy_before)
    assert_eq(player.stock, stock_before)
    assert_eq(turn.phase, phase_before)

func test_non_action_snapshot_disables_every_technique_and_null_session_fails_closed() -> void:
    var presenter = _presenter()
    if presenter == null:
        return
    assert_true(presenter.snapshot(null).is_empty())

    var f := _fixture()
    var snapshot: Dictionary = presenter.snapshot(f["battle"])
    var readiness: Dictionary = snapshot["technique_readiness"]
    assert_eq(readiness.size(), 18)
    for entry_value in readiness.values():
        var entry: Dictionary = entry_value
        assert_false(entry["ready"])
        assert_eq(entry["reason"], "WRONG_PHASE")
