extends GutTest

const RESULT_PATH := "res://src/production/line/line_clear_result.gd"
const REWARD_CONFIG_PATH := "res://src/production/line/line_reward_config.gd"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"
const CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"

func _catalog():
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(TETROMINO_DATA_PATH))
    return load(CATALOG_PATH).from_dictionary(parsed)

func _reward_config():
    assert_true(ResourceLoader.exists(REWARD_CONFIG_PATH), "LineRewardConfig script must exist")
    assert_true(FileAccess.file_exists(REWARD_DATA_PATH), "Line reward seed data must exist")
    if not ResourceLoader.exists(REWARD_CONFIG_PATH) or not FileAccess.file_exists(REWARD_DATA_PATH):
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(REWARD_DATA_PATH))
    return load(REWARD_CONFIG_PATH).from_dictionary(parsed)

func _cycle(seed_value: int = 12345) -> LinePieceCycle:
    var cycle := LinePieceCycle.new(seed_value, _catalog(), LineBoard.new(10, 20, 4))
    cycle.start()
    return cycle

func test_clear_classification_is_explicit_from_zero_through_four() -> void:
    assert_true(ResourceLoader.exists(RESULT_PATH), "LineClearResult script must exist")
    if not ResourceLoader.exists(RESULT_PATH):
        return
    var result_script = load(RESULT_PATH)
    assert_eq(result_script.classify(0), "NONE")
    assert_eq(result_script.classify(1), "SINGLE")
    assert_eq(result_script.classify(2), "DOUBLE")
    assert_eq(result_script.classify(3), "TRIPLE")
    assert_eq(result_script.classify(4), "FOUR")
    assert_eq(result_script.classify(5), "INVALID")

func test_reward_seed_is_explicitly_non_final_and_traces_historical_source() -> void:
    var config = _reward_config()
    if config == null:
        return
    assert_eq(config.balance_status, "TUNING_SEED_NOT_FINAL")
    assert_eq(config.seed_source, "HISTORICAL_FOUNDATION_LINE_RULES")
    assert_eq(config.energy_for_kind("SINGLE"), 10)
    assert_eq(config.energy_for_kind("DOUBLE"), 22)
    assert_eq(config.energy_for_kind("TRIPLE"), 36)
    assert_eq(config.energy_for_kind("FOUR"), 52)
    assert_eq(config.score_for_kind("SINGLE"), 100)
    assert_eq(config.score_for_kind("DOUBLE"), 300)
    assert_eq(config.score_for_kind("TRIPLE"), 500)
    assert_eq(config.score_for_kind("FOUR"), 800)

func test_zero_clear_commit_locks_piece_spawns_next_and_has_zero_reward() -> void:
    var config = _reward_config()
    if config == null:
        return
    var cycle := _cycle(777)
    var original_piece_id: String = cycle.active_piece.piece_id
    var expected_next: String = cycle.peek_next(5)[0]
    cycle.active_piece.hard_drop(cycle.board)
    var locked_origin: Vector2i = cycle.active_piece.origin
    var locked_cells: Array = cycle.active_piece.get_cells().duplicate()

    var result = cycle.commit_active_piece(config)

    assert_true(result.success)
    assert_eq(result.piece_id, original_piece_id)
    assert_eq(result.lines_cleared, 0)
    assert_eq(result.clear_kind, "NONE")
    assert_eq(result.energy_delta, 0)
    assert_eq(result.score_delta, 0)
    assert_eq(cycle.active_piece.piece_id, expected_next)
    for local_cell in locked_cells:
        assert_eq(cycle.board.get_cell(locked_origin + Vector2i(local_cell)), original_piece_id)

func test_single_clear_commit_returns_separate_score_and_energy_result() -> void:
    var config = _reward_config()
    if config == null:
        return
    var cycle := _cycle(2026)
    var bottom_y: int = cycle.board.total_height - 1
    for x in range(6):
        cycle.board.set_cell(Vector2i(x, bottom_y), "X")
    cycle.active_piece = ActiveTetromino.new("I", Vector2i(6, bottom_y - 1), _catalog())

    var result = cycle.commit_active_piece(config)

    assert_true(result.success)
    assert_eq(result.lines_cleared, 1)
    assert_eq(result.clear_kind, "SINGLE")
    assert_eq(result.energy_delta, 10)
    assert_eq(result.score_delta, 100)
    for x in range(cycle.board.width):
        assert_eq(cycle.board.get_cell(Vector2i(x, bottom_y)), "")

func test_result_event_keeps_score_and_energy_as_separate_fields() -> void:
    var config = _reward_config()
    if config == null:
        return
    var result = config.make_result("T", 2)
    var event: Dictionary = result.to_event()
    assert_eq(event["kind"], &"production_line_resolved")
    assert_eq(event["piece_id"], "T")
    assert_eq(event["lines_cleared"], 2)
    assert_eq(event["clear_kind"], "DOUBLE")
    assert_eq(event["energy_delta"], 22)
    assert_eq(event["score_delta"], 300)
    assert_false(event.has("skill_currency"), "Score must never become a Skill currency")

func test_invalid_commit_is_atomic_and_does_not_advance_piece_stream() -> void:
    var config = _reward_config()
    if config == null:
        return
    var cycle := _cycle(9090)
    cycle.active_piece = ActiveTetromino.new("O", Vector2i(-2, 0), _catalog())
    var preview_before: Array = cycle.peek_next(5)
    var active_before: String = cycle.active_piece.piece_id

    var result = cycle.commit_active_piece(config)

    assert_false(result.success)
    assert_eq(result.lines_cleared, 0)
    assert_eq(result.energy_delta, 0)
    assert_eq(result.score_delta, 0)
    assert_eq(cycle.active_piece.piece_id, active_before)
    assert_eq(cycle.peek_next(5), preview_before)
    assert_eq(cycle.board.get_cell(Vector2i(0, 0)), "")
