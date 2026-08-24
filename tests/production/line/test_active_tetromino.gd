extends GutTest

const ACTIVE_PATH := "res://src/production/line/active_tetromino.gd"
const CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const DATA_PATH := "res://data/production/line_tetrominoes.json"

func _catalog():
    if not ResourceLoader.exists(CATALOG_PATH) or not FileAccess.file_exists(DATA_PATH):
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    return load(CATALOG_PATH).from_dictionary(parsed)

func _make_piece(piece_id: String, origin: Vector2i):
    assert_true(ResourceLoader.exists(ACTIVE_PATH), "ActiveTetromino script must exist")
    var catalog = _catalog()
    assert_not_null(catalog, "TetrominoCatalog/data must exist")
    if not ResourceLoader.exists(ACTIVE_PATH) or catalog == null:
        return null
    return load(ACTIVE_PATH).new(piece_id, origin, catalog)

func test_move_changes_origin_only_when_candidate_is_legal() -> void:
    var board := LineBoard.new(10, 20, 4)
    var piece = _make_piece("O", Vector2i(3, 0))
    if piece == null:
        return
    assert_true(piece.try_move(board, Vector2i.LEFT))
    assert_eq(piece.origin, Vector2i(2, 0))
    assert_true(piece.try_move(board, Vector2i.LEFT))
    assert_eq(piece.origin, Vector2i(1, 0))
    assert_true(piece.try_move(board, Vector2i.LEFT))
    assert_eq(piece.origin, Vector2i(0, 0))
    assert_false(piece.try_move(board, Vector2i.LEFT))
    assert_eq(piece.origin, Vector2i(0, 0))

func test_hard_drop_moves_to_lowest_legal_origin_and_returns_distance() -> void:
    var board := LineBoard.new(10, 20, 4)
    var piece = _make_piece("O", Vector2i(3, 0))
    if piece == null:
        return
    var distance: int = piece.hard_drop(board)
    assert_true(distance > 0)
    assert_false(board.can_place(piece.get_cells(), piece.origin + Vector2i.DOWN))
    assert_true(board.can_place(piece.get_cells(), piece.origin))

func test_hard_drop_stops_above_existing_cells() -> void:
    var board := LineBoard.new(10, 20, 4)
    board.set_cell(Vector2i(4, board.total_height - 1), "X")
    board.set_cell(Vector2i(5, board.total_height - 1), "X")
    var piece = _make_piece("O", Vector2i(3, 0))
    if piece == null:
        return
    piece.hard_drop(board)
    assert_true(board.can_place(piece.get_cells(), piece.origin))
    assert_false(board.can_place(piece.get_cells(), piece.origin + Vector2i.DOWN))

func test_rotation_changes_orientation_on_empty_board() -> void:
    var board := LineBoard.new(10, 20, 4)
    var piece = _make_piece("T", Vector2i(3, 0))
    if piece == null:
        return
    assert_eq(piece.rotation, 0)
    assert_true(piece.try_rotate(board, 1))
    assert_eq(piece.rotation, 1)
    assert_true(board.can_place(piece.get_cells(), piece.origin))

func test_rotation_uses_project_kick_data_near_wall() -> void:
    var board := LineBoard.new(10, 20, 4)
    var piece = _make_piece("T", Vector2i(-1, 4))
    if piece == null:
        return
    piece.rotation = 1
    assert_true(board.can_place(piece.get_cells(), piece.origin))
    assert_true(piece.try_rotate(board, -1))
    assert_eq(piece.rotation, 0)
    assert_true(piece.origin.x >= 0, "kick must move the rotated piece into the board")
    assert_true(board.can_place(piece.get_cells(), piece.origin))
