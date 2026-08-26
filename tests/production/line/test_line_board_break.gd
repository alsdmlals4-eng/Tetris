extends GutTest

const BREAK_RESULT_PATH := "res://src/production/line/line_board_break_result.gd"
const CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"

func _catalog():
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(TETROMINO_DATA_PATH))
    return TetrominoCatalog.from_dictionary(parsed)

func _cycle(seed_value: int = 12345) -> LinePieceCycle:
    var cycle := LinePieceCycle.new(seed_value, _catalog(), LineBoard.new(10, 20, 4))
    cycle.start()
    return cycle

func test_active_spawn_blocked_is_detected_without_advancing_stream() -> void:
    var cycle := _cycle(111)
    var preview_before: Array = cycle.peek_next(20)
    var active_id: String = cycle.active_piece.piece_id
    for local_cell in cycle.active_piece.get_cells():
        cycle.board.set_cell(cycle.active_piece.origin + Vector2i(local_cell), "X")

    assert_true(cycle.is_active_spawn_blocked())
    assert_eq(cycle.active_piece.piece_id, active_id)
    assert_eq(cycle.peek_next(20), preview_before)

func test_board_break_resets_field_but_preserves_active_identity_hold_and_future_stream() -> void:
    var cycle := _cycle(222)
    assert_true(cycle.try_hold())
    var active_before: String = cycle.active_piece.piece_id
    var held_before: String = cycle.held_piece_id
    var hold_lockout_before: bool = cycle.hold_used_for_active
    var preview_before: Array = cycle.peek_next(28)

    for y in range(cycle.board.visible_start_y, cycle.board.total_height):
        cycle.board.set_cell(Vector2i(0, y), "X")
    for local_cell in cycle.active_piece.get_cells():
        cycle.board.set_cell(cycle.active_piece.origin + Vector2i(local_cell), "X")
    assert_false(cycle.board.is_empty())

    var result = cycle.reset_after_board_break("SPAWN_BLOCKED")

    assert_true(result.triggered)
    assert_eq(result.reason, "SPAWN_BLOCKED")
    assert_true(cycle.board.is_empty())
    assert_eq(cycle.active_piece.piece_id, active_before)
    assert_eq(cycle.held_piece_id, held_before)
    assert_eq(cycle.hold_used_for_active, hold_lockout_before)
    assert_eq(cycle.peek_next(28), preview_before, "Board Break must not reroll NEXT or bag state")
    assert_true(cycle.board.can_place(cycle.active_piece.get_cells(), cycle.active_piece.origin))

func test_board_break_event_is_line_local_and_does_not_claim_resource_confiscation() -> void:
    assert_true(ResourceLoader.exists(BREAK_RESULT_PATH), "LineBoardBreakResult script must exist")
    if not ResourceLoader.exists(BREAK_RESULT_PATH):
        return
    var cycle := _cycle(333)
    var active_before: String = cycle.active_piece.piece_id
    var result = cycle.reset_after_board_break("TOP_OUT")
    var event: Dictionary = result.to_event()

    assert_eq(event["kind"], &"production_line_board_break")
    assert_eq(event["reason"], "TOP_OUT")
    assert_eq(event["piece_id"], active_before)
    assert_true(event["line_board_reset"])
    assert_false(event.has("energy_delta"), "Line Board Break event must not confiscate Energy")
    assert_false(event.has("stock_delta"), "Line Board Break event must not confiscate Stock")
    assert_false(event.has("hp_delta"), "HP damage belongs to battle/combat integration, not Line puzzle state")

func test_reset_without_active_piece_is_rejected_atomically() -> void:
    var cycle := LinePieceCycle.new(444, _catalog(), LineBoard.new(10, 20, 4))
    cycle.board.set_cell(Vector2i(0, cycle.board.total_height - 1), "X")
    var preview_before: Array = cycle.peek_next(20)

    var result = cycle.reset_after_board_break("SPAWN_BLOCKED")

    assert_false(result.triggered)
    assert_false(cycle.board.is_empty(), "rejected reset must not mutate board")
    assert_null(cycle.active_piece)
    assert_eq(cycle.peek_next(20), preview_before)
