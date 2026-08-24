extends GutTest

const SESSION_PATH := "res://src/production/line/production_line_session.gd"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"
const FEEL_DATA_PATH := "res://data/production/line_feel_config.json"

func _catalog() -> TetrominoCatalog:
    return TetrominoCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(TETROMINO_DATA_PATH)))

func _reward_config() -> LineRewardConfig:
    return LineRewardConfig.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(REWARD_DATA_PATH)))

func _feel_config() -> LineFeelConfig:
    return LineFeelConfig.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(FEEL_DATA_PATH)))

func _make_session(seconds: float = 90.0):
    assert_true(ResourceLoader.exists(SESSION_PATH), "ProductionLineSession script must exist")
    if not ResourceLoader.exists(SESSION_PATH):
        return null
    var budget := TurnBudget.new()
    budget.snapshot(seconds, 0.0, 0.0, seconds)
    var turn := TurnController.new(budget)
    var cycle := LinePieceCycle.new(20260824, _catalog(), LineBoard.new(10, 20, 4))
    cycle.start()
    var fall := LineFallState.new(_feel_config())
    return load(SESSION_PATH).new(turn, cycle, fall, _reward_config())

func test_line_input_is_rejected_until_line_phase_starts() -> void:
    var session = _make_session()
    if session == null:
        return
    var origin_before: Vector2i = session.piece_cycle.active_piece.origin
    assert_false(session.can_accept_input())
    assert_false(session.try_move(Vector2i.LEFT))
    assert_eq(session.piece_cycle.active_piece.origin, origin_before)

    assert_true(session.start_line())
    assert_true(session.can_accept_input())
    assert_eq(session.turn_controller.phase, TurnPhase.LINE)

func test_ready_closes_line_input_and_preserves_remaining_shared_budget() -> void:
    var session = _make_session(90.0)
    if session == null:
        return
    session.start_line()
    session.tick(20.0, false)
    var origin_before_ready: Vector2i = session.piece_cycle.active_piece.origin

    assert_true(session.request_ready())
    assert_eq(session.turn_controller.phase, TurnPhase.LINE_SETTLE)
    assert_eq(session.turn_controller.turn_budget.remaining_seconds, 70.0)
    assert_false(session.can_accept_input())
    assert_false(session.try_move(Vector2i.LEFT))
    assert_eq(session.piece_cycle.active_piece.origin, origin_before_ready)

    session.tick(50.0, false)
    assert_eq(session.turn_controller.turn_budget.remaining_seconds, 70.0, "Line Settle must not consume budget")
    assert_true(session.complete_settle())
    assert_eq(session.turn_controller.phase, TurnPhase.CHAIN)

func test_line_timeout_closes_input_then_settle_resolves_deterministic_pass() -> void:
    var session = _make_session(10.0)
    if session == null:
        return
    session.start_line()
    session.tick(10.0, false)

    assert_eq(session.turn_controller.phase, TurnPhase.LINE_SETTLE)
    assert_false(session.can_accept_input())
    assert_false(session.try_hold())
    assert_true(session.complete_settle())
    assert_true(session.turn_controller.chain_input_skipped_for_timeout)
    assert_eq(session.turn_controller.pending_player_action.id, "PASS")
    assert_eq(session.turn_controller.phase, TurnPhase.PLAYER_RESOLVE)

func test_hard_drop_commit_emits_line_result_without_mutating_combat_resources() -> void:
    var session = _make_session()
    if session == null:
        return
    session.start_line()
    var active_before: String = session.piece_cycle.active_piece.piece_id

    var result = session.hard_drop_and_commit()

    assert_not_null(result)
    assert_true(result.success)
    assert_eq(result.piece_id, active_before)
    assert_eq(session.last_line_result, result)
    assert_eq(session.turn_controller.phase, TurnPhase.LINE)
    var events: Array = session.drain_events()
    assert_eq(events.size(), 1)
    assert_eq(events[0]["kind"], &"production_line_resolved")
    assert_true(events[0].has("energy_delta"))
    assert_true(events[0].has("score_delta"))
    assert_false(events[0].has("energy_total"), "Line session emits deltas; combat state owns totals")
    assert_eq(session.drain_events().size(), 0, "drain must consume queued events")

func test_normal_tick_can_lock_grounded_piece_and_emit_result() -> void:
    var session = _make_session()
    if session == null:
        return
    session.start_line()
    session.piece_cycle.active_piece.hard_drop(session.piece_cycle.board)
    var lock_delay: float = session.fall_state.config.lock_delay_seconds

    session.tick(lock_delay, false)

    assert_not_null(session.last_line_result)
    assert_true(session.last_line_result.success)
    assert_eq(session.drain_events().size(), 1)
    assert_eq(session.turn_controller.phase, TurnPhase.LINE)

func test_manipulation_resets_grounded_lock_delay_only_when_move_succeeds() -> void:
    var session = _make_session()
    if session == null:
        return
    session.start_line()
    session.piece_cycle.active_piece.hard_drop(session.piece_cycle.board)
    session.tick(session.fall_state.config.lock_delay_seconds * 0.5, false)
    assert_true(session.fall_state.grounded_seconds > 0.0)

    assert_true(session.try_move(Vector2i.LEFT))
    assert_almost_eq(session.fall_state.grounded_seconds, 0.0, 0.0001)
    assert_eq(session.fall_state.lock_reset_count, 1)

func test_spawn_block_after_commit_resets_line_board_and_emits_board_break_without_reroll() -> void:
    var session = _make_session()
    if session == null:
        return
    session.start_line()
    var preview_before: Array = session.piece_cycle.peek_next(28)
    var next_id: String = preview_before[0]

    # Move the current active piece clear of the hidden spawn zone before
    # constructing the next-piece spawn block. Otherwise the fixture itself
    # can overlap the current piece and prevent the commit under test.
    session.piece_cycle.active_piece.hard_drop(session.piece_cycle.board)

    var next_spawn: Vector2i = session.piece_cycle.catalog.get_spawn_origin(next_id, session.piece_cycle.board.width, session.piece_cycle.board.hidden_rows)
    var next_cells: Array = session.piece_cycle.catalog.get_cells(next_id, 0)
    for cell in next_cells:
        session.piece_cycle.board.set_cell(next_spawn + Vector2i(cell), "X")

    assert_false(session.piece_cycle.board.can_place(next_cells, next_spawn), "fixture must block the exact next spawn")
    assert_eq(session.piece_cycle.peek_next(1)[0], next_id, "fixture must not advance the upcoming stream")

    var result = session.hard_drop_and_commit()

    assert_not_null(result)
    assert_true(result.success)
    assert_eq(session.piece_cycle.active_piece.piece_id, next_id, "commit must spawn preview front")
    assert_not_null(session.last_board_break_result)
    if session.last_board_break_result == null:
        return
    assert_true(session.last_board_break_result.triggered)
    assert_eq(session.last_board_break_result.reason, "SPAWN_BLOCKED")
    assert_true(session.piece_cycle.board.is_empty())
    assert_true(session.piece_cycle.board.can_place(session.piece_cycle.active_piece.get_cells(), session.piece_cycle.active_piece.origin), "Board Break reset must restore a legal spawn")
    assert_eq(session.piece_cycle.active_piece.piece_id, next_id)
    assert_eq(session.turn_controller.phase, TurnPhase.LINE, "Board Break with time remaining resumes same Line phase")
    var events: Array = session.drain_events()
    assert_eq(events.size(), 2)
    assert_eq(events[0]["kind"], &"production_line_resolved")
    assert_eq(events[1]["kind"], &"production_line_board_break")

func test_board_break_api_is_rejected_outside_line_phase() -> void:
    var session = _make_session()
    if session == null:
        return
    var board_before_empty: bool = session.piece_cycle.board.is_empty()
    assert_null(session.resolve_board_break("MANUAL_TEST"))
    assert_eq(session.piece_cycle.board.is_empty(), board_before_empty)
