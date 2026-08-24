extends GutTest

const BOARD_PATH := "res://src/production/line/line_board.gd"

func _make_board():
    assert_true(ResourceLoader.exists(BOARD_PATH), "production LineBoard script must exist")
    if not ResourceLoader.exists(BOARD_PATH):
        return null
    return load(BOARD_PATH).new(10, 20, 4)

func test_board_exposes_visible_and_hidden_dimensions() -> void:
    var board = _make_board()
    if board == null:
        return
    assert_eq(board.width, 10)
    assert_eq(board.visible_height, 20)
    assert_eq(board.hidden_rows, 4)
    assert_eq(board.total_height, 24)
    assert_eq(board.visible_start_y, 4)

func test_empty_board_accepts_in_bounds_cells_and_rejects_out_of_bounds() -> void:
    var board = _make_board()
    if board == null:
        return
    var cells := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
    assert_true(board.can_place(cells, Vector2i(3, 4)))
    assert_false(board.can_place(cells, Vector2i(-1, 4)))
    assert_false(board.can_place(cells, Vector2i(7, 24)))

func test_locked_cells_block_future_placement() -> void:
    var board = _make_board()
    if board == null:
        return
    var cells := [Vector2i(0, 0), Vector2i(1, 0)]
    assert_true(board.lock_cells(cells, Vector2i(4, 23), "T"))
    assert_eq(board.get_cell(Vector2i(4, 23)), "T")
    assert_eq(board.get_cell(Vector2i(5, 23)), "T")
    assert_false(board.can_place(cells, Vector2i(4, 23)))

func test_invalid_lock_is_atomic_and_does_not_mutate_board() -> void:
    var board = _make_board()
    if board == null:
        return
    var cells := [Vector2i(0, 0), Vector2i(1, 0)]
    assert_false(board.lock_cells(cells, Vector2i(9, 23), "I"))
    assert_eq(board.get_cell(Vector2i(9, 23)), "")

func test_full_row_clear_compacts_rows_downward() -> void:
    var board = _make_board()
    if board == null:
        return
    var bottom_y := board.total_height - 1
    for x in range(board.width):
        board.set_cell(Vector2i(x, bottom_y), "X")
    board.set_cell(Vector2i(2, bottom_y - 1), "M")

    var cleared := board.clear_full_rows()

    assert_eq(cleared, 1)
    assert_eq(board.get_cell(Vector2i(2, bottom_y)), "M")
    assert_eq(board.get_cell(Vector2i(2, bottom_y - 1)), "")

func test_multiple_full_rows_clear_in_one_atomic_compaction() -> void:
    var board = _make_board()
    if board == null:
        return
    var bottom_y := board.total_height - 1
    for x in range(board.width):
        board.set_cell(Vector2i(x, bottom_y), "A")
        board.set_cell(Vector2i(x, bottom_y - 1), "B")
    board.set_cell(Vector2i(0, bottom_y - 2), "M")

    assert_eq(board.clear_full_rows(), 2)
    assert_eq(board.get_cell(Vector2i(0, bottom_y)), "M")
