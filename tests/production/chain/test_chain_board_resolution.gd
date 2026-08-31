extends GutTest

const BOARD_PATH := "res://src/production/chain/chain_board.gd"

func _board(width: int = 4, height: int = 5):
    return load(BOARD_PATH).new(width, height)

func _fill(board, rows: Array) -> void:
    for y in range(rows.size()):
        for x in range(rows[y].size()):
            board.set_cell(Vector2i(x, y), String(rows[y][x]))

func test_clear_cells_is_unique_and_ignores_out_of_bounds_without_touching_other_cells() -> void:
    var board = _board(3, 3)
    _fill(board, [
        ["A", "B", "C"],
        ["D", "E", "F"],
        ["G", "H", "I"],
    ])

    var cleared: int = board.clear_cells([
        Vector2i(0, 0),
        Vector2i(1, 1),
        Vector2i(1, 1),
        Vector2i(99, 99),
    ])

    assert_eq(cleared, 2)
    assert_eq(board.get_cell(Vector2i(0, 0)), "")
    assert_eq(board.get_cell(Vector2i(1, 1)), "")
    assert_eq(board.get_cell(Vector2i(2, 2)), "I")

func test_gravity_compacts_each_column_downward_and_preserves_relative_order() -> void:
    var board = _board(3, 5)
    _fill(board, [
        ["A", "",  "P"],
        ["",  "D", ""],
        ["B", "",  "Q"],
        ["C", "E", ""],
        ["",  "F", "R"],
    ])

    var moved: int = board.apply_gravity()

    assert_true(moved > 0)
    assert_eq(board.snapshot(), [
        "", "", "",
        "", "", "",
        "A", "D", "P",
        "B", "E", "Q",
        "C", "F", "R",
    ])

func test_clear_current_matches_then_gravity_leaves_no_floating_symbol() -> void:
    var board = _board(4, 5)
    _fill(board, [
        ["R", "G", "B", "Y"],
        ["G", "B", "Y", "R"],
        ["G", "X", "Y", "G"],
        ["Y", "X", "R", "B"],
        ["R", "X", "G", "Y"],
    ])
    var matched: Array = board.matched_cells()
    assert_eq(matched.size(), 3)

    assert_eq(board.clear_cells(matched), 3)
    board.apply_gravity()

    for x in range(board.width):
        var seen_symbol := false
        for y in range(board.height):
            var value: String = board.get_cell(Vector2i(x, y))
            if value != "":
                seen_symbol = true
            elif seen_symbol:
                fail_test("Gravity left an empty cell below a symbol in column %d" % x)
