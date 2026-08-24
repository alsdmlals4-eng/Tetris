extends GutTest

const CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const DATA_PATH := "res://data/production/line_tetrominoes.json"
const EXPECTED_IDS := ["I", "J", "L", "O", "S", "T", "Z"]

func _load_catalog():
    assert_true(ResourceLoader.exists(CATALOG_PATH), "TetrominoCatalog script must exist")
    assert_true(FileAccess.file_exists(DATA_PATH), "project-owned tetromino data must exist")
    if not ResourceLoader.exists(CATALOG_PATH) or not FileAccess.file_exists(DATA_PATH):
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    return load(CATALOG_PATH).from_dictionary(parsed)

func _sorted_ids(values: Array) -> Array:
    var copy := values.duplicate()
    copy.sort()
    return copy

func test_catalog_contains_exactly_seven_tetrominoes() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return
    assert_eq(_sorted_ids(catalog.get_piece_ids()), EXPECTED_IDS)

func test_each_rotation_has_four_unique_cells() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return
    for piece_id in EXPECTED_IDS:
        for rotation in range(4):
            var cells: Array = catalog.get_cells(piece_id, rotation)
            assert_eq(cells.size(), 4, "%s rotation %d must have four cells" % [piece_id, rotation])
            var unique := {}
            for cell in cells:
                unique[Vector2i(cell)] = true
            assert_eq(unique.size(), 4, "%s rotation %d cells must be unique" % [piece_id, rotation])

func test_o_piece_rotation_geometry_is_stable() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return
    var base: Array = catalog.get_cells("O", 0)
    for rotation in range(1, 4):
        assert_eq(catalog.get_cells("O", rotation), base)

func test_empty_board_accepts_every_piece_at_project_spawn_origin() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return
    var board := LineBoard.new(10, 20, 4)
    for piece_id in EXPECTED_IDS:
        var origin: Vector2i = catalog.get_spawn_origin(piece_id, board.width, board.hidden_rows)
        assert_true(board.can_place(catalog.get_cells(piece_id, 0), origin), "%s must spawn on empty board" % piece_id)

func test_rotation_kicks_are_project_owned_for_all_quarter_turns() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return
    var transitions := [[0, 1], [1, 2], [2, 3], [3, 0], [0, 3], [3, 2], [2, 1], [1, 0]]
    for piece_id in EXPECTED_IDS:
        for transition in transitions:
            var kicks: Array = catalog.get_kick_tests(piece_id, transition[0], transition[1])
            assert_true(kicks.size() >= 1, "%s %d>%d must own kick data" % [piece_id, transition[0], transition[1]])
            assert_eq(Vector2i(kicks[0]), Vector2i.ZERO, "first kick candidate must preserve origin")
