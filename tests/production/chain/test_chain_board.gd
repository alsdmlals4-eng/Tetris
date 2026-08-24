extends GutTest

const BOARD_PATH := "res://src/production/chain/chain_board.gd"

func _board(width: int = 3, height: int = 3):
    assert_true(ResourceLoader.exists(BOARD_PATH), "ChainBoard script must exist")
    if not ResourceLoader.exists(BOARD_PATH):
        return null
    return load(BOARD_PATH).new(width, height)

func _fill(board, rows: Array) -> void:
    for y in range(rows.size()):
        for x in range(rows[y].size()):
            board.set_cell(Vector2i(x, y), String(rows[y][x]))

func test_board_dimensions_are_configurable_and_snapshot_restores_exact_state() -> void:
    var board = _board(4, 3)
    if board == null:
        return
    _fill(board, [
        ["A", "B", "C", "D"],
        ["E", "F", "G", "H"],
        ["I", "J", "K", "L"],
    ])
    var before: Array = board.snapshot()

    assert_true(board.set_cell(Vector2i(2, 1), "X"))
    assert_ne(board.snapshot(), before)
    assert_true(board.restore(before))
    assert_eq(board.snapshot(), before)
    assert_eq(board.width, 4)
    assert_eq(board.height, 3)

func test_non_adjacent_swap_is_rejected_without_mutating_board() -> void:
    var board = _board()
    if board == null:
        return
    _fill(board, [
        ["A", "A", "B"],
        ["B", "C", "A"],
        ["C", "B", "C"],
    ])
    var before: Array = board.snapshot()

    var result: Dictionary = board.try_swap_for_match(Vector2i(0, 0), Vector2i(2, 0))

    assert_false(result["accepted"])
    assert_eq(result["reason"], "NOT_ADJACENT")
    assert_eq(board.snapshot(), before)

func test_adjacent_swap_without_resulting_match_rolls_back_atomically() -> void:
    var board = _board()
    if board == null:
        return
    _fill(board, [
        ["A", "A", "B"],
        ["B", "C", "A"],
        ["C", "B", "C"],
    ])
    var before: Array = board.snapshot()

    var result: Dictionary = board.try_swap_for_match(Vector2i(0, 1), Vector2i(1, 1))

    assert_false(result["accepted"])
    assert_eq(result["reason"], "NO_MATCH")
    assert_eq(board.snapshot(), before)

func test_adjacent_swap_that_creates_match_is_committed() -> void:
    var board = _board()
    if board == null:
        return
    _fill(board, [
        ["A", "A", "B"],
        ["B", "C", "A"],
        ["C", "B", "C"],
    ])

    var result: Dictionary = board.try_swap_for_match(Vector2i(2, 0), Vector2i(2, 1))

    assert_true(result["accepted"])
    assert_eq(result["reason"], "MATCH")
    assert_eq(board.get_cell(Vector2i(2, 0)), "A")
    assert_eq(board.get_cell(Vector2i(2, 1)), "B")
    assert_eq(result["groups"].size(), 1)
    assert_eq(result["groups"][0]["axis"], "H")
    assert_eq(result["groups"][0]["symbol"], "A")

func test_match_groups_preserve_axes_while_matched_cells_are_unique() -> void:
    var board = _board(5, 5)
    if board == null:
        return
    for y in range(5):
        for x in range(5):
            board.set_cell(Vector2i(x, y), "%d_%d" % [x, y])

    board.set_cell(Vector2i(1, 2), "X")
    board.set_cell(Vector2i(2, 2), "X")
    board.set_cell(Vector2i(3, 2), "X")
    board.set_cell(Vector2i(2, 1), "X")
    board.set_cell(Vector2i(2, 3), "X")

    var groups: Array = board.find_match_groups()
    var matched: Array = board.matched_cells()

    assert_eq(groups.size(), 2)
    assert_eq(groups[0]["axis"], "H")
    assert_eq(groups[1]["axis"], "V")
    assert_eq(matched.size(), 5, "Cross center belongs to two groups but clears once")
    assert_has(matched, Vector2i(2, 2))
