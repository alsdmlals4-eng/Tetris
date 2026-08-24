extends GutTest

const COORDINATOR_PATH := "res://src/production/session/production_battle_coordinator.gd"
const BATTLE_PATH := "res://src/production/combat/production_battle_session.gd"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const FEEL_DATA_PATH := "res://data/production/line_feel_config.json"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"

class FixedChainReward:
    extends RefCounted

    func stock_for_resolution(resolution: Dictionary) -> int:
        return 2 if int(resolution.get("chain_depth", 0)) > 0 else 0

func _json(path: String) -> Dictionary:
    var value = JSON.parse_string(FileAccess.get_file_as_string(path))
    return value if value is Dictionary else {}

func _skill_catalog() -> ProductionSkillCatalog:
    return ProductionSkillCatalog.from_dictionary(_json(SKILL_DATA_PATH))

func _enemy_catalog() -> GatebreakerActionCatalog:
    return GatebreakerActionCatalog.from_dictionary(_json(ENEMY_DATA_PATH))

func _make_line(turn: TurnController) -> ProductionLineSession:
    var board := LineBoard.new()
    var catalog := TetrominoCatalog.from_dictionary(_json(TETROMINO_DATA_PATH))
    var cycle := LinePieceCycle.new(12345, catalog, board)
    cycle.start()
    var feel := LineFeelConfig.from_dictionary(_json(FEEL_DATA_PATH))
    var reward := LineRewardConfig.from_dictionary(_json(REWARD_DATA_PATH))
    return ProductionLineSession.new(turn, cycle, LineFallState.new(feel), reward)

func _make_chain(turn: TurnController, player: ProductionCombatState) -> ProductionChainSession:
    var board := ChainBoard.new(3, 3)
    var rows := [
        ["A", "A", "B"],
        ["B", "C", "A"],
        ["C", "B", "C"],
    ]
    for y in range(rows.size()):
        for x in range(rows[y].size()):
            board.set_cell(Vector2i(x, y), String(rows[y][x]))
    var randomizer := ChainRandomizer.new(54321, ["D", "E", "F", "G"])
    return ProductionChainSession.new(
        turn,
        board,
        ChainResolver.new(board, randomizer),
        player,
        FixedChainReward.new()
    )

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
    assert_true(battle.start_next_player_turn(TurnTimeConfig.from_dictionary(_json(TIME_DATA_PATH)), "NORMAL")["started"])

    var coordinator_script = load(COORDINATOR_PATH)
    assert_not_null(coordinator_script, "ProductionBattleCoordinator must exist")
    if coordinator_script == null:
        return {}

    var line := _make_line(turn)
    var chain := _make_chain(turn, player)
    return {
        "coordinator": coordinator_script.new(battle, line, chain, ProductionBattlePresenter.new()),
        "battle": battle,
        "turn": turn,
        "player": player,
        "enemy": enemy,
        "line": line,
        "chain": chain,
    }

func test_snapshot_uses_real_puzzle_session_as_ready_authority() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    var coordinator = f["coordinator"]
    var turn: TurnController = f["turn"]

    var line_snapshot: Dictionary = coordinator.snapshot()
    assert_eq(line_snapshot["phase"], "LINE")
    assert_true(line_snapshot["ready_available"])

    assert_true(coordinator.request_ready())
    assert_eq(turn.phase, TurnPhase.LINE_SETTLE)
    assert_false(coordinator.snapshot()["ready_available"])
    assert_true(coordinator.complete_settle())
    assert_eq(turn.phase, TurnPhase.CHAIN)
    assert_true(coordinator.snapshot()["ready_available"])

func test_line_result_event_is_committed_once_to_combat_and_performance_state() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    var coordinator = f["coordinator"]
    var player: ProductionCombatState = f["player"]
    var battle = f["battle"]

    var energy_before := player.energy
    var result = coordinator.line_hard_drop()

    assert_not_null(result)
    assert_true(result.success)
    assert_true(battle.turn_performance_state.line_qualified)
    assert_eq(player.energy, energy_before + result.energy_delta)
    assert_eq(coordinator.drain_routed_events().size(), 1)
    assert_eq(coordinator.drain_routed_events().size(), 0, "Routed events are not double-applied")

func test_chain_resolution_commits_stock_in_chain_then_reports_performance_once() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    var coordinator = f["coordinator"]
    var turn: TurnController = f["turn"]
    var player: ProductionCombatState = f["player"]
    var battle = f["battle"]

    assert_true(coordinator.request_ready())
    assert_true(coordinator.complete_settle())
    assert_eq(turn.phase, TurnPhase.CHAIN)

    var swap: Dictionary = coordinator.chain_swap(Vector2i(2, 0), Vector2i(2, 1))
    assert_true(swap["accepted"])
    var resolution: Dictionary = coordinator.complete_chain_resolution()

    assert_true(resolution["success"])
    assert_gt(player.stock, 0)
    assert_true(battle.turn_performance_state.chain_qualified)
    var events: Array = coordinator.drain_routed_events()
    assert_eq(events.size(), 1)
    assert_eq(events[0]["kind"], &"production_chain_resolved")

func test_named_action_intent_delegates_to_battle_session_without_ui_resource_mutation() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    var coordinator = f["coordinator"]
    var turn: TurnController = f["turn"]
    var player: ProductionCombatState = f["player"]

    player.apply_energy_delta(20)
    player.gain_stock(1)
    assert_true(coordinator.request_ready())
    assert_true(coordinator.complete_settle())
    assert_true(coordinator.request_ready())
    assert_true(coordinator.complete_settle())
    assert_eq(turn.phase, TurnPhase.ACTION)

    var before_energy := player.energy
    var before_stock := player.stock
    var selected: Dictionary = coordinator.select_technique("atk_t1_quick_cut")

    assert_true(selected["accepted"])
    assert_eq(player.energy, before_energy - 10)
    assert_eq(player.stock, before_stock - 1)
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)

func test_wrong_phase_named_intents_fail_closed() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    var coordinator = f["coordinator"]
    var player: ProductionCombatState = f["player"]
    var energy_before := player.energy
    var stock_before := player.stock

    assert_false(coordinator.chain_swap(Vector2i.ZERO, Vector2i.RIGHT)["accepted"])
    assert_false(coordinator.select_technique("atk_t1_quick_cut")["accepted"])
    assert_eq(player.energy, energy_before)
    assert_eq(player.stock, stock_before)
