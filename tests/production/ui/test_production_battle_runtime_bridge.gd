extends GutTest

const SCENE_PATH := "res://scenes/production/battle.tscn"
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
    return ProductionChainSession.new(
        turn,
        board,
        ChainResolver.new(board, ChainRandomizer.new(54321, ["D", "E", "F", "G"])),
        player,
        FixedChainReward.new()
    )

func _fixture() -> Dictionary:
    var packed = load(SCENE_PATH)
    assert_not_null(packed)
    if packed == null:
        return {}
    var ui = packed.instantiate()
    add_child_autofree(ui)
    await get_tree().process_frame

    var enemy_catalog := GatebreakerActionCatalog.from_dictionary(_json(ENEMY_DATA_PATH))
    var current := enemy_catalog.instantiate_action("light_smash", 1)
    var next := enemy_catalog.instantiate_action("gatebreaker_slam", 2)
    var turn := TurnController.new(TurnBudget.new())
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var battle = load(BATTLE_PATH).new(
        turn,
        player,
        enemy,
        ProductionSkillCatalog.from_dictionary(_json(SKILL_DATA_PATH)),
        GatebreakerTelegraphState.new(current, next),
        ProductionStatusState.new(),
        ProductionResponseState.new(),
        TimeEffectState.new(),
        ProductionTechniqueResolver.new(ProductionEffectExecutor.new()),
        ProductionEnemyActionResolver.new()
    )
    assert_true(battle.start_next_player_turn(TurnTimeConfig.from_dictionary(_json(TIME_DATA_PATH)), "NORMAL")["started"])

    var coordinator_script = load(COORDINATOR_PATH)
    assert_not_null(coordinator_script)
    if coordinator_script == null:
        return {}
    var line := _make_line(turn)
    var chain := _make_chain(turn, player)
    return {
        "ui": ui,
        "turn": turn,
        "player": player,
        "coordinator": coordinator_script.new(battle, line, chain, ProductionBattlePresenter.new()),
    }

func test_ready_button_routes_through_real_coordinator_and_refreshes_presentation() -> void:
    var f := await _fixture()
    if f.is_empty():
        return
    var ui = f["ui"]
    var bridge = ui.get_node_or_null("RuntimeBridge")
    assert_not_null(bridge, "Production battle scene must own a runtime bridge")
    if bridge == null:
        return

    assert_true(bridge.bind_coordinator(f["coordinator"]))
    assert_true(ui.phase_label.text.contains("LINE"))
    assert_true(ui.ready_button.visible)
    assert_false(ui.ready_button.disabled)

    ui.ready_button.pressed.emit()

    assert_eq(f["turn"].phase, TurnPhase.LINE_SETTLE)
    assert_true(ui.phase_label.text.contains("LINE_SETTLE"))
    assert_false(ui.ready_button.visible)

func test_technique_button_routes_through_real_coordinator_and_refreshes_presentation() -> void:
    var f := await _fixture()
    if f.is_empty():
        return
    var ui = f["ui"]
    var bridge = ui.get_node_or_null("RuntimeBridge")
    assert_not_null(bridge)
    if bridge == null:
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
    assert_true(bridge.bind_coordinator(coordinator))

    var button: Button = ui.skill_buttons_by_id["atk_t1_quick_cut"]
    assert_false(button.disabled)
    var energy_before := player.energy
    var stock_before := player.stock

    button.pressed.emit()

    assert_eq(player.energy, energy_before - 10)
    assert_eq(player.stock, stock_before - 1)
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)
    assert_true(ui.phase_label.text.contains("PLAYER_RESOLVE"))
    assert_true(button.disabled)
