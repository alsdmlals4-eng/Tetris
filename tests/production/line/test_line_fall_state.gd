extends GutTest

const FEEL_CONFIG_PATH := "res://src/production/line/line_feel_config.gd"
const FALL_STATE_PATH := "res://src/production/line/line_fall_state.gd"
const DATA_PATH := "res://data/production/line_feel_config.json"
const CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"

func _load_feel_config():
    assert_true(ResourceLoader.exists(FEEL_CONFIG_PATH), "LineFeelConfig script must exist")
    assert_true(FileAccess.file_exists(DATA_PATH), "line feel config data must exist")
    if not ResourceLoader.exists(FEEL_CONFIG_PATH) or not FileAccess.file_exists(DATA_PATH):
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    return load(FEEL_CONFIG_PATH).from_dictionary(parsed)

func _catalog():
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(TETROMINO_DATA_PATH))
    return load(CATALOG_PATH).from_dictionary(parsed)

func _piece(piece_id: String = "O", origin: Vector2i = Vector2i(3, 0)) -> ActiveTetromino:
    return ActiveTetromino.new(piece_id, origin, _catalog())

func _fall_state():
    assert_true(ResourceLoader.exists(FALL_STATE_PATH), "LineFallState script must exist")
    var config = _load_feel_config()
    if not ResourceLoader.exists(FALL_STATE_PATH) or config == null:
        return null
    return load(FALL_STATE_PATH).new(config)

func test_feel_config_is_explicitly_non_final_and_bounded() -> void:
    var config = _load_feel_config()
    if config == null:
        return
    assert_eq(config.balance_status, "TUNING_SEED_NOT_FINAL")
    assert_true(config.gravity_seconds_per_cell > 0.0)
    assert_true(config.soft_drop_multiplier > 1.0)
    assert_true(config.lock_delay_seconds > 0.0)
    assert_true(config.max_lock_resets >= 0)
    assert_true(config.das_seconds >= 0.0)
    assert_true(config.arr_seconds >= 0.0)

func test_gravity_moves_only_after_interval_and_preserves_fractional_time() -> void:
    var state = _fall_state()
    if state == null:
        return
    var config = _load_feel_config()
    var board := LineBoard.new(10, 20, 4)
    var piece := _piece()

    state.tick(config.gravity_seconds_per_cell * 0.75, board, piece, false)
    assert_eq(piece.origin, Vector2i(3, 0))

    state.tick(config.gravity_seconds_per_cell * 0.50, board, piece, false)
    assert_eq(piece.origin, Vector2i(3, 1))
    assert_almost_eq(
        state.gravity_accumulator_seconds,
        config.gravity_seconds_per_cell * 0.25,
        0.0001
    )

func test_large_tick_can_advance_multiple_gravity_cells() -> void:
    var state = _fall_state()
    if state == null:
        return
    var config = _load_feel_config()
    var board := LineBoard.new(10, 20, 4)
    var piece := _piece()

    state.tick(config.gravity_seconds_per_cell * 3.2, board, piece, false)

    assert_eq(piece.origin, Vector2i(3, 3))
    assert_almost_eq(
        state.gravity_accumulator_seconds,
        config.gravity_seconds_per_cell * 0.2,
        0.0001
    )

func test_soft_drop_uses_faster_data_driven_interval() -> void:
    var state = _fall_state()
    if state == null:
        return
    var config = _load_feel_config()
    var board := LineBoard.new(10, 20, 4)
    var piece := _piece()
    var soft_interval: float = config.gravity_seconds_per_cell / config.soft_drop_multiplier

    state.tick(soft_interval * 1.1, board, piece, true)

    assert_eq(piece.origin, Vector2i(3, 1))

func test_grounded_piece_requests_lock_only_after_lock_delay() -> void:
    var state = _fall_state()
    if state == null:
        return
    var config = _load_feel_config()
    var board := LineBoard.new(10, 20, 4)
    var piece := _piece()
    piece.hard_drop(board)

    state.tick(config.lock_delay_seconds * 0.75, board, piece, false)
    assert_false(state.lock_requested)
    assert_almost_eq(state.grounded_seconds, config.lock_delay_seconds * 0.75, 0.0001)

    state.tick(config.lock_delay_seconds * 0.25, board, piece, false)
    assert_true(state.lock_requested)

func test_successful_grounded_manipulation_resets_lock_delay_within_cap() -> void:
    var state = _fall_state()
    if state == null:
        return
    var config = _load_feel_config()
    var board := LineBoard.new(10, 20, 4)
    var piece := _piece()
    piece.hard_drop(board)
    state.tick(config.lock_delay_seconds * 0.8, board, piece, false)

    assert_true(piece.try_move(board, Vector2i.LEFT))
    assert_true(state.notify_successful_manipulation(board, piece))

    assert_almost_eq(state.grounded_seconds, 0.0, 0.0001)
    assert_eq(state.lock_reset_count, 1)
    assert_false(state.lock_requested)

func test_lock_delay_reset_is_bounded() -> void:
    var state = _fall_state()
    if state == null:
        return
    var config = _load_feel_config()
    var board := LineBoard.new(10, 20, 4)
    var piece := _piece()
    piece.hard_drop(board)

    for index in range(config.max_lock_resets):
        state.tick(config.lock_delay_seconds * 0.8, board, piece, false)
        var delta := Vector2i.LEFT if index % 2 == 0 else Vector2i.RIGHT
        assert_true(piece.try_move(board, delta))
        assert_true(state.notify_successful_manipulation(board, piece))

    assert_eq(state.lock_reset_count, config.max_lock_resets)
    state.tick(config.lock_delay_seconds * 0.8, board, piece, false)
    assert_true(piece.try_move(board, Vector2i.LEFT if config.max_lock_resets % 2 == 0 else Vector2i.RIGHT))
    assert_false(state.notify_successful_manipulation(board, piece))
    assert_true(state.grounded_seconds > 0.0, "lock timer must not reset after reset cap")

func test_hard_drop_can_request_immediate_lock_without_waiting_for_delay() -> void:
    var state = _fall_state()
    if state == null:
        return
    var board := LineBoard.new(10, 20, 4)
    var piece := _piece()

    var distance: int = state.hard_drop_and_request_lock(board, piece)

    assert_true(distance > 0)
    assert_true(state.lock_requested)
    assert_false(board.can_place(piece.get_cells(), piece.origin + Vector2i.DOWN))
