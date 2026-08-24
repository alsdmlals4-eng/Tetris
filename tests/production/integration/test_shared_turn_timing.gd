extends GutTest

const TURN_CONTROLLER_PATH := "res://src/production/turn/turn_controller.gd"
const TURN_BUDGET_PATH := "res://src/production/turn/turn_budget.gd"

func _make_turn(seconds: float):
    assert_true(ResourceLoader.exists(TURN_CONTROLLER_PATH), "production TurnController script must exist")
    if not ResourceLoader.exists(TURN_CONTROLLER_PATH):
        return null
    var budget = load(TURN_BUDGET_PATH).new()
    budget.snapshot(seconds, 0.0, 0.0, seconds)
    return load(TURN_CONTROLLER_PATH).new(budget)

func test_line_ready_carries_remaining_budget_into_chain() -> void:
    var turn = _make_turn(90.0)
    if turn == null:
        return
    turn.enter_line()
    turn.tick_player_time(20.0)
    turn.request_ready()
    assert_eq(turn.phase, TurnPhase.LINE_SETTLE)
    assert_eq(turn.turn_budget.remaining_seconds, 70.0)

    turn.tick_player_time(40.0)
    assert_eq(turn.turn_budget.remaining_seconds, 70.0, "Line Settle must not consume player budget")
    assert_eq(turn.turn_budget.active_used_seconds, 20.0)

    turn.complete_line_settle()
    assert_eq(turn.phase, TurnPhase.CHAIN)
    assert_eq(turn.turn_budget.remaining_seconds, 70.0)

func test_chain_ready_carries_remaining_budget_into_action() -> void:
    var turn = _make_turn(90.0)
    if turn == null:
        return
    turn.enter_line()
    turn.tick_player_time(20.0)
    turn.request_ready()
    turn.complete_line_settle()

    turn.tick_player_time(15.0)
    turn.request_ready()
    assert_eq(turn.phase, TurnPhase.CHAIN_SETTLE)
    assert_eq(turn.turn_budget.remaining_seconds, 55.0)

    turn.tick_player_time(100.0)
    assert_eq(turn.turn_budget.remaining_seconds, 55.0, "Chain Settle must not consume player budget")
    assert_eq(turn.turn_budget.active_used_seconds, 35.0)

    turn.complete_chain_settle()
    assert_eq(turn.phase, TurnPhase.ACTION)
    assert_eq(turn.turn_budget.remaining_seconds, 55.0)

func test_enemy_telegraph_does_not_consume_player_budget() -> void:
    var turn = _make_turn(90.0)
    if turn == null:
        return
    assert_eq(turn.phase, TurnPhase.ENEMY_TELEGRAPH)
    turn.tick_player_time(30.0)
    assert_eq(turn.turn_budget.remaining_seconds, 90.0)
    assert_eq(turn.turn_budget.active_used_seconds, 0.0)

func test_timeout_during_line_settles_then_skips_to_pass() -> void:
    var turn = _make_turn(10.0)
    if turn == null:
        return
    turn.enter_line()
    turn.tick_player_time(10.0)
    assert_eq(turn.phase, TurnPhase.LINE_SETTLE)
    turn.complete_line_settle()
    assert_true(turn.chain_input_skipped_for_timeout)
    assert_eq(turn.pending_player_action.id, "PASS")
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)

func test_timeout_during_chain_settles_then_passes() -> void:
    var turn = _make_turn(10.0)
    if turn == null:
        return
    turn.enter_line()
    turn.request_ready()
    turn.complete_line_settle()
    assert_eq(turn.phase, TurnPhase.CHAIN)

    turn.tick_player_time(10.0)
    assert_eq(turn.phase, TurnPhase.CHAIN_SETTLE)
    turn.complete_chain_settle()
    assert_eq(turn.pending_player_action.id, "PASS")
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)

func test_timeout_during_action_resolves_deterministic_pass() -> void:
    var turn = _make_turn(10.0)
    if turn == null:
        return
    turn.enter_line()
    turn.request_ready()
    turn.complete_line_settle()
    turn.request_ready()
    turn.complete_chain_settle()
    assert_eq(turn.phase, TurnPhase.ACTION)

    turn.tick_player_time(10.0)
    assert_eq(turn.pending_player_action.id, "PASS")
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)
