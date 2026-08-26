extends GutTest

const SESSION_PATH := "res://src/production/chain/production_chain_session.gd"
const BOARD_PATH := "res://src/production/chain/chain_board.gd"

class FixedRewardPolicy:
    extends RefCounted

    func stock_for_resolution(resolution: Dictionary) -> int:
        return 2 if int(resolution.get("chain_depth", 0)) > 0 else 0

func _initial_rows() -> Array:
    return [
        ["A", "A", "B"],
        ["B", "C", "A"],
        ["C", "B", "C"],
    ]

func _make_session(seed_value: int):
    var board: ChainBoard = load(BOARD_PATH).new(3, 3)
    var rows: Array = _initial_rows()
    for y in range(rows.size()):
        for x in range(rows[y].size()):
            board.set_cell(Vector2i(x, y), String(rows[y][x]))

    var randomizer := ChainRandomizer.new(seed_value, ["D", "E", "F", "G"])
    var resolver := ChainResolver.new(board, randomizer)
    var combat := ProductionCombatState.new(100)

    var budget := TurnBudget.new()
    budget.snapshot(30.0, 0.0, 0.0, 30.0)
    var turn := TurnController.new(budget)
    turn.enter_line()
    turn.request_ready()
    turn.complete_line_settle()

    return {
        "session": load(SESSION_PATH).new(turn, board, resolver, combat, FixedRewardPolicy.new()),
        "randomizer": randomizer,
        "combat": combat,
    }

func _run_fixture(seed_value: int) -> Dictionary:
    var fixture: Dictionary = _make_session(seed_value)
    var session = fixture["session"]
    var randomizer: ChainRandomizer = fixture["randomizer"]
    var combat: ProductionCombatState = fixture["combat"]

    var rng_before: int = randomizer.get_rng_state()
    var swap: Dictionary = session.begin_swap(Vector2i(2, 0), Vector2i(2, 1))
    assert_true(swap["accepted"])
    var resolution: Dictionary = session.complete_pending_resolution()
    assert_true(resolution["success"])

    return {
        "rng_before": rng_before,
        "rng_after": randomizer.get_rng_state(),
        "board": session.board.snapshot(),
        "chain_depth": int(resolution["chain_depth"]),
        "waves": resolution["waves"].duplicate(true),
        "stock": combat.stock,
        "events": session.drain_events(),
    }

func test_same_seed_and_same_swap_reproduce_exact_chain_outcome() -> void:
    var first: Dictionary = _run_fixture(424242)
    var second: Dictionary = _run_fixture(424242)

    assert_eq(first, second)
    assert_eq(first["chain_depth"], 1)
    assert_eq(first["stock"], 2)
    assert_eq(first["events"].size(), 1)

func test_saved_rng_state_replays_refill_stream_exactly() -> void:
    var fixture: Dictionary = _make_session(777777)
    var session = fixture["session"]
    var randomizer: ChainRandomizer = fixture["randomizer"]
    var initial_board: Array = session.board.snapshot()
    var rng_state: int = randomizer.get_rng_state()

    assert_true(session.begin_swap(Vector2i(2, 0), Vector2i(2, 1))["accepted"])
    var first_resolution: Dictionary = session.complete_pending_resolution()
    var first_board: Array = session.board.snapshot()
    var first_rng_after: int = randomizer.get_rng_state()

    session.board.restore(initial_board)
    randomizer.restore_rng_state(rng_state)

    assert_true(session.begin_swap(Vector2i(2, 0), Vector2i(2, 1))["accepted"])
    var second_resolution: Dictionary = session.complete_pending_resolution()

    assert_eq(second_resolution["chain_depth"], first_resolution["chain_depth"])
    assert_eq(second_resolution["waves"], first_resolution["waves"])
    assert_eq(session.board.snapshot(), first_board)
    assert_eq(randomizer.get_rng_state(), first_rng_after)
