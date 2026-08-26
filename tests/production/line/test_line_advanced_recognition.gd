extends GutTest

const STREAK_PATH := "res://src/production/line/line_streak_state.gd"
const SPIN_PATH := "res://src/production/line/line_spin_recognizer.gd"
const CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"

func _catalog():
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(TETROMINO_DATA_PATH))
    return TetrominoCatalog.from_dictionary(parsed)

func _reward_config() -> LineRewardConfig:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(REWARD_DATA_PATH))
    return LineRewardConfig.from_dictionary(parsed)

func _streak():
    assert_true(ResourceLoader.exists(STREAK_PATH), "LineStreakState script must exist")
    if not ResourceLoader.exists(STREAK_PATH):
        return null
    return load(STREAK_PATH).new()

func test_active_piece_records_successful_rotation_for_spin_recognition() -> void:
    var board := LineBoard.new(10, 20, 4)
    var piece := ActiveTetromino.new("T", Vector2i(3, 4), _catalog())
    assert_eq(piece.last_successful_action, "NONE")
    assert_true(piece.try_rotate(board, 1))
    assert_eq(piece.last_successful_action, "ROTATE")
    assert_true(piece.try_move(board, Vector2i.LEFT))
    assert_eq(piece.last_successful_action, "MOVE")

func test_t_spin_requires_t_piece_rotation_and_three_occupied_pivot_corners() -> void:
    assert_true(ResourceLoader.exists(SPIN_PATH), "LineSpinRecognizer script must exist")
    if not ResourceLoader.exists(SPIN_PATH):
        return
    var board := LineBoard.new(10, 20, 4)
    var piece := ActiveTetromino.new("T", Vector2i(3, 6), _catalog())
    piece.last_successful_action = "ROTATE"
    var pivot := piece.origin + Vector2i(1, 1)
    board.set_cell(pivot + Vector2i(-1, -1), "X")
    board.set_cell(pivot + Vector2i(1, -1), "X")
    board.set_cell(pivot + Vector2i(-1, 1), "X")

    assert_eq(load(SPIN_PATH).classify(board, piece), "T_SPIN")

func test_spin_recognizer_rejects_non_rotation_non_t_and_two_corners() -> void:
    if not ResourceLoader.exists(SPIN_PATH):
        return
    var recognizer = load(SPIN_PATH)
    var board := LineBoard.new(10, 20, 4)
    var t_piece := ActiveTetromino.new("T", Vector2i(3, 6), _catalog())
    var pivot := t_piece.origin + Vector2i(1, 1)
    board.set_cell(pivot + Vector2i(-1, -1), "X")
    board.set_cell(pivot + Vector2i(1, -1), "X")
    t_piece.last_successful_action = "ROTATE"
    assert_eq(recognizer.classify(board, t_piece), "NONE")

    board.set_cell(pivot + Vector2i(-1, 1), "X")
    t_piece.last_successful_action = "MOVE"
    assert_eq(recognizer.classify(board, t_piece), "NONE")

    var l_piece := ActiveTetromino.new("L", t_piece.origin, _catalog())
    l_piece.last_successful_action = "ROTATE"
    assert_eq(recognizer.classify(board, l_piece), "NONE")

func test_combo_counts_consecutive_line_clears_and_resets_on_no_clear() -> void:
    var streak = _streak()
    if streak == null:
        return
    var config := _reward_config()
    var first := config.make_result("I", 1)
    var second := config.make_result("I", 2)
    var miss := config.make_result("O", 0)
    var after_miss := config.make_result("T", 1)

    streak.decorate(first)
    streak.decorate(second)
    streak.decorate(miss)
    streak.decorate(after_miss)

    assert_eq(first.combo_index, 0)
    assert_eq(second.combo_index, 1)
    assert_eq(miss.combo_index, -1)
    assert_eq(after_miss.combo_index, 0)

func test_back_to_back_marks_second_consecutive_difficult_clear_only() -> void:
    var streak = _streak()
    if streak == null:
        return
    var config := _reward_config()
    var first_four := config.make_result("I", 4)
    var no_clear := config.make_result("O", 0)
    var second_four := config.make_result("I", 4)
    var normal_single := config.make_result("I", 1)
    var third_four := config.make_result("I", 4)

    streak.decorate(first_four)
    streak.decorate(no_clear)
    streak.decorate(second_four)
    streak.decorate(normal_single)
    streak.decorate(third_four)

    assert_false(first_four.back_to_back)
    assert_false(no_clear.back_to_back)
    assert_true(second_four.back_to_back, "zero-clear placement must preserve B2B chain")
    assert_false(normal_single.back_to_back)
    assert_false(third_four.back_to_back, "ordinary line clear must break B2B chain")

func test_t_spin_line_clear_counts_as_difficult_for_back_to_back() -> void:
    var streak = _streak()
    if streak == null:
        return
    var config := _reward_config()
    var four := config.make_result("I", 4)
    var spin_single := config.make_result("T", 1)
    spin_single.spin_kind = "T_SPIN"

    streak.decorate(four)
    streak.decorate(spin_single)

    assert_true(spin_single.back_to_back)

func test_perfect_clear_is_true_when_commit_clear_leaves_board_empty() -> void:
    var cycle := LinePieceCycle.new(321, _catalog(), LineBoard.new(10, 20, 4))
    cycle.start()
    var bottom_y: int = cycle.board.total_height - 1
    for x in range(6):
        cycle.board.set_cell(Vector2i(x, bottom_y), "X")
    cycle.active_piece = ActiveTetromino.new("I", Vector2i(6, bottom_y - 1), _catalog())

    var result = cycle.commit_active_piece(_reward_config())

    assert_true(result.success)
    assert_true(result.perfect_clear)
    assert_true(cycle.board.is_empty())

func test_result_event_includes_advanced_recognition_without_changing_base_reward_fields() -> void:
    var result := _reward_config().make_result("T", 1)
    result.spin_kind = "T_SPIN"
    result.combo_index = 2
    result.back_to_back = true
    result.perfect_clear = true
    var event := result.to_event()
    assert_eq(event["spin_kind"], "T_SPIN")
    assert_eq(event["combo_index"], 2)
    assert_true(event["back_to_back"])
    assert_true(event["perfect_clear"])
    assert_eq(event["energy_delta"], 10)
    assert_eq(event["score_delta"], 100)
