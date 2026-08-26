extends GutTest

const CYCLE_PATH := "res://src/production/line/line_piece_cycle.gd"
const CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const DATA_PATH := "res://data/production/line_tetrominoes.json"

func _catalog():
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    return load(CATALOG_PATH).from_dictionary(parsed)

func _make_cycle(seed_value: int = 12345):
    assert_true(ResourceLoader.exists(CYCLE_PATH), "LinePieceCycle script must exist")
    if not ResourceLoader.exists(CYCLE_PATH):
        return null
    return load(CYCLE_PATH).new(seed_value, _catalog(), LineBoard.new(10, 20, 4))

func test_start_spawns_one_active_piece_and_exposes_stable_next_preview() -> void:
    var cycle = _make_cycle()
    if cycle == null:
        return
    cycle.start()
    assert_not_null(cycle.active_piece)
    var first_preview: Array = cycle.peek_next(5)
    var second_preview: Array = cycle.peek_next(5)
    assert_eq(first_preview.size(), 5)
    assert_eq(second_preview, first_preview, "reading NEXT preview must not consume the stream")

func test_normal_advance_uses_preview_front_and_refreshes_preview() -> void:
    var cycle = _make_cycle()
    if cycle == null:
        return
    cycle.start()
    var before: Array = cycle.peek_next(5)
    var expected_next: String = before[0]

    cycle.complete_lock_and_spawn_next()

    assert_eq(cycle.active_piece.piece_id, expected_next)
    var after: Array = cycle.peek_next(5)
    assert_eq(after.size(), 5)
    assert_ne(after, before, "advancing a piece must move the preview stream forward")

func test_first_hold_stores_current_and_consumes_one_upcoming_piece() -> void:
    var cycle = _make_cycle()
    if cycle == null:
        return
    cycle.start()
    var original_active: String = cycle.active_piece.piece_id
    var preview: Array = cycle.peek_next(5)

    assert_true(cycle.try_hold())

    assert_eq(cycle.held_piece_id, original_active)
    assert_eq(cycle.active_piece.piece_id, preview[0])
    assert_true(cycle.hold_used_for_active)

func test_hold_is_rejected_twice_for_the_same_active_piece() -> void:
    var cycle = _make_cycle()
    if cycle == null:
        return
    cycle.start()
    assert_true(cycle.try_hold())
    var active_after_first: String = cycle.active_piece.piece_id
    var held_after_first: String = cycle.held_piece_id
    var preview_after_first: Array = cycle.peek_next(5)

    assert_false(cycle.try_hold())

    assert_eq(cycle.active_piece.piece_id, active_after_first)
    assert_eq(cycle.held_piece_id, held_after_first)
    assert_eq(cycle.peek_next(5), preview_after_first)

func test_hold_becomes_available_again_after_piece_lock_cycle_advances() -> void:
    var cycle = _make_cycle()
    if cycle == null:
        return
    cycle.start()
    assert_true(cycle.try_hold())
    assert_true(cycle.hold_used_for_active)

    cycle.complete_lock_and_spawn_next()

    assert_false(cycle.hold_used_for_active)
    assert_true(cycle.try_hold())

func test_swapping_with_existing_hold_does_not_consume_upcoming_stream() -> void:
    var cycle = _make_cycle()
    if cycle == null:
        return
    cycle.start()
    var initially_held: String = cycle.active_piece.piece_id
    assert_true(cycle.try_hold())
    cycle.complete_lock_and_spawn_next()
    var current_before_swap: String = cycle.active_piece.piece_id
    var preview_before_swap: Array = cycle.peek_next(5)

    assert_true(cycle.try_hold())

    assert_eq(cycle.active_piece.piece_id, initially_held)
    assert_eq(cycle.held_piece_id, current_before_swap)
    assert_eq(cycle.peek_next(5), preview_before_swap, "hold swap with stored piece must not draw from bag")

func test_ghost_origin_is_lowest_legal_without_mutating_active_piece() -> void:
    var cycle = _make_cycle()
    if cycle == null:
        return
    cycle.start()
    var original_origin: Vector2i = cycle.active_piece.origin
    var ghost_origin: Vector2i = cycle.get_ghost_origin()

    assert_eq(cycle.active_piece.origin, original_origin, "ghost calculation must not move the active piece")
    assert_true(cycle.board.can_place(cycle.active_piece.get_cells(), ghost_origin))
    assert_false(cycle.board.can_place(cycle.active_piece.get_cells(), ghost_origin + Vector2i.DOWN))

func test_ghost_respects_existing_locked_cells() -> void:
    var cycle = _make_cycle(777)
    if cycle == null:
        return
    cycle.start()
    for x in range(cycle.board.width):
        cycle.board.set_cell(Vector2i(x, cycle.board.total_height - 1), "X")
    var ghost_origin: Vector2i = cycle.get_ghost_origin()
    assert_true(cycle.board.can_place(cycle.active_piece.get_cells(), ghost_origin))
    assert_false(cycle.board.can_place(cycle.active_piece.get_cells(), ghost_origin + Vector2i.DOWN))
