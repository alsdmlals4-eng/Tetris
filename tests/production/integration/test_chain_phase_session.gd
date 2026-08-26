extends GutTest

const SESSION_PATH := "res://src/production/chain/production_chain_session.gd"
const BOARD_PATH := "res://src/production/chain/chain_board.gd"

class ScriptedRandomizer:
    extends RefCounted

    var values: Array[String] = []
    var index: int = 0

    func _init(p_values: Array) -> void:
        for value in p_values:
            values.append(String(value))

    func next_symbol() -> String:
        if values.is_empty():
            return ""
        var value: String = values[index % values.size()]
        index += 1
        return value

class FixedRewardPolicy:
    extends RefCounted

    var stock_gain: int

    func _init(p_stock_gain: int) -> void:
        stock_gain = p_stock_gain

    func stock_for_resolution(_resolution: Dictionary) -> int:
        return stock_gain

func _board() -> ChainBoard:
    var board = load(BOARD_PATH).new(3, 3)
    var rows := [
        ["A", "A", "B"],
        ["B", "C", "A"],
        ["C", "B", "C"],
    ]
    for y in range(rows.size()):
        for x in range(rows[y].size()):
            board.set_cell(Vector2i(x, y), String(rows[y][x]))
    return board

func _turn_at_chain(seconds: float = 30.0) -> TurnController:
    var budget := TurnBudget.new()
    budget.snapshot(seconds, 0.0, 0.0, seconds)
    var turn := TurnController.new(budget)
    turn.enter_line()
    turn.request_ready()
    turn.complete_line_settle()
    assert_eq(turn.phase, TurnPhase.CHAIN)
    return turn

func _session(seconds: float = 30.0, stock_gain: int = 2):
    assert_true(ResourceLoader.exists(SESSION_PATH), "ProductionChainSession script must exist")
    if not ResourceLoader.exists(SESSION_PATH):
        return null
    var board := _board()
    var randomizer := ScriptedRandomizer.new(["D", "E", "F", "G", "H", "I"])
    var resolver := ChainResolver.new(board, randomizer)
    var combat := ProductionCombatState.new(100)
    return load(SESSION_PATH).new(_turn_at_chain(seconds), board, resolver, combat, FixedRewardPolicy.new(stock_gain))

func test_valid_swap_commits_then_resolves_without_ending_chain_phase_when_time_remains() -> void:
    var session = _session(30.0, 2)
    if session == null:
        return

    var begin: Dictionary = session.begin_swap(Vector2i(2, 0), Vector2i(2, 1))

    assert_true(begin["accepted"])
    assert_true(session.is_resolving)
    assert_eq(session.turn_controller.phase, TurnPhase.CHAIN)
    assert_false(session.can_accept_input())
    assert_eq(session.combat_state.stock, 0, "Stock commits only after the cascade reaches stable completion")

    var blocked: Dictionary = session.begin_swap(Vector2i(0, 0), Vector2i(1, 0))
    assert_false(blocked["accepted"])
    assert_eq(blocked["reason"], "RESOLVING")

    var resolved: Dictionary = session.complete_pending_resolution()

    assert_true(resolved["success"])
    assert_eq(resolved["chain_depth"], 1)
    assert_false(session.is_resolving)
    assert_eq(session.turn_controller.phase, TurnPhase.CHAIN, "Stable result with time remaining must allow more Chain input")
    assert_true(session.can_accept_input())
    assert_eq(session.combat_state.stock, 2)
    var events: Array = session.drain_events()
    assert_eq(events.size(), 1)
    assert_eq(events[0]["kind"], &"production_chain_resolved")
    assert_eq(events[0]["stock_requested"], 2)
    assert_eq(events[0]["stock_applied"], 2)
    assert_eq(events[0]["stock_lost_at_cap"], 0)

func test_invalid_swap_rolls_back_without_resolution_or_reward() -> void:
    var session = _session()
    if session == null:
        return
    var before: Array = session.board.snapshot()

    var result: Dictionary = session.begin_swap(Vector2i(0, 1), Vector2i(1, 1))

    assert_false(result["accepted"])
    assert_eq(result["reason"], "NO_MATCH")
    assert_false(session.is_resolving)
    assert_eq(session.board.snapshot(), before)
    assert_eq(session.combat_state.stock, 0)
    assert_eq(session.drain_events().size(), 0)
    assert_eq(session.turn_controller.phase, TurnPhase.CHAIN)

func test_ready_is_legal_only_at_stable_boundary_and_then_enters_action() -> void:
    var session = _session()
    if session == null:
        return

    assert_true(session.begin_swap(Vector2i(2, 0), Vector2i(2, 1))["accepted"])
    assert_false(session.request_ready(), "READY cannot cut off a committed cascade")
    assert_eq(session.turn_controller.phase, TurnPhase.CHAIN)

    assert_true(session.complete_pending_resolution()["success"])
    var remaining: float = session.turn_controller.turn_budget.remaining_seconds
    assert_true(session.request_ready())
    assert_eq(session.turn_controller.phase, TurnPhase.CHAIN_SETTLE)
    assert_eq(session.turn_controller.turn_budget.remaining_seconds, remaining)
    assert_false(session.can_accept_input())
    assert_true(session.complete_settle())
    assert_eq(session.turn_controller.phase, TurnPhase.ACTION)

func test_timeout_without_committed_swap_closes_input_and_resolves_pass_after_stable_settle() -> void:
    var session = _session(1.0)
    if session == null:
        return
    var before: Array = session.board.snapshot()

    session.tick_player_time(1.0)

    assert_eq(session.turn_controller.phase, TurnPhase.CHAIN_SETTLE)
    assert_false(session.can_accept_input())
    var rejected: Dictionary = session.begin_swap(Vector2i(2, 0), Vector2i(2, 1))
    assert_false(rejected["accepted"])
    assert_eq(rejected["reason"], "INPUT_CLOSED")
    assert_eq(session.board.snapshot(), before)
    assert_true(session.complete_settle())
    assert_eq(session.turn_controller.pending_player_action.id, "PASS")
    assert_eq(session.turn_controller.phase, TurnPhase.PLAYER_RESOLVE)

func test_swap_committed_before_timeout_finishes_after_input_closes_and_commits_stock_before_pass() -> void:
    var session = _session(0.1, 3)
    if session == null:
        return

    assert_true(session.begin_swap(Vector2i(2, 0), Vector2i(2, 1))["accepted"])
    session.tick_player_time(0.2)

    assert_eq(session.turn_controller.phase, TurnPhase.CHAIN_SETTLE)
    assert_true(session.is_resolving)
    assert_false(session.can_accept_input())
    assert_false(session.complete_settle(), "Action/PASS transition waits for committed cascade stability")

    var resolved: Dictionary = session.complete_pending_resolution()
    assert_true(resolved["success"])
    assert_eq(session.combat_state.stock, 3)
    assert_true(session.complete_settle())
    assert_eq(session.turn_controller.pending_player_action.id, "PASS")
    assert_eq(session.turn_controller.phase, TurnPhase.PLAYER_RESOLVE)

func test_stock_cap_overflow_is_visible_in_chain_result_event() -> void:
    var session = _session(30.0, 3)
    if session == null:
        return
    session.combat_state.gain_stock(5)

    assert_true(session.begin_swap(Vector2i(2, 0), Vector2i(2, 1))["accepted"])
    assert_true(session.complete_pending_resolution()["success"])

    assert_eq(session.combat_state.stock, 6)
    var events: Array = session.drain_events()
    assert_eq(events.size(), 1)
    assert_eq(events[0]["stock_requested"], 3)
    assert_eq(events[0]["stock_applied"], 1)
    assert_eq(events[0]["stock_lost_at_cap"], 2)
