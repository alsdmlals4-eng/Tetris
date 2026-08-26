extends GutTest

const SESSION_PATH := "res://src/production/line/production_line_session.gd"
const BOARD_PATH := "res://src/production/line/line_board.gd"
const CYCLE_PATH := "res://src/production/line/line_piece_cycle.gd"
const CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const FALL_PATH := "res://src/production/line/line_fall_state.gd"
const FEEL_CONFIG_PATH := "res://src/production/line/line_feel_config.gd"
const REWARD_CONFIG_PATH := "res://src/production/line/line_reward_config.gd"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const FEEL_DATA_PATH := "res://data/production/line_feel_config.json"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"

const SCRIPT_PATHS := [
    SESSION_PATH,
    BOARD_PATH,
    CYCLE_PATH,
    CATALOG_PATH,
    FALL_PATH,
    FEEL_CONFIG_PATH,
    REWARD_CONFIG_PATH,
]

const DATA_PATHS := [
    TETROMINO_DATA_PATH,
    FEEL_DATA_PATH,
    REWARD_DATA_PATH,
]

func _requirements_exist() -> bool:
    var ready := true
    for path in SCRIPT_PATHS:
        var exists := ResourceLoader.exists(path)
        assert_true(exists, "%s must exist for the realtime Line workspace" % path)
        ready = ready and exists
    for path in DATA_PATHS:
        var exists := FileAccess.file_exists(path)
        assert_true(exists, "%s must exist for the realtime Line workspace" % path)
        ready = ready and exists
    return ready

func _read_json(path: String):
    return JSON.parse_string(FileAccess.get_file_as_string(path))

func _has_property(instance: Object, property_name: String) -> bool:
    for property in instance.get_property_list():
        if String(property.get("name", "")) == property_name:
            return true
    return false

func _make_session():
    if not _requirements_exist():
        return null

    var catalog = load(CATALOG_PATH).from_dictionary(_read_json(TETROMINO_DATA_PATH))
    var feel_config = load(FEEL_CONFIG_PATH).from_dictionary(_read_json(FEEL_DATA_PATH))
    var reward_config = load(REWARD_CONFIG_PATH).from_dictionary(_read_json(REWARD_DATA_PATH))
    assert_not_null(catalog)
    assert_not_null(feel_config)
    assert_not_null(reward_config)
    if catalog == null or feel_config == null or reward_config == null:
        return null

    var board = load(BOARD_PATH).new(10, 20, 4)
    var cycle = load(CYCLE_PATH).new(20260824, catalog, board)
    cycle.start()
    var fall_state = load(FALL_PATH).new(feel_config)
    return load(SESSION_PATH).new(cycle, fall_state, reward_config)

func test_realtime_line_session_exists_without_turn_controller_ownership() -> void:
    var session = _make_session()
    if session == null:
        return

    assert_true(session.can_accept_input())
    assert_true(session.input_enabled)
    assert_false(_has_property(session, "turn_controller"))
    assert_true(session.has_method("set_input_enabled"))
    assert_true(session.has_method("snapshot_runtime_state"))

func test_disable_then_enable_restores_exact_legal_line_state() -> void:
    var session = _make_session()
    if session == null:
        return

    var gravity: float = session.fall_state.config.gravity_seconds_per_cell
    var first_tick = session.tick(gravity * 0.75, false)
    assert_true(first_tick is Dictionary)
    assert_true(session.try_hold(), "fixture should exercise Hold/queue state before switching away")
    assert_true(session.try_move(Vector2i.LEFT))

    var before: Dictionary = session.snapshot_runtime_state()
    var events_before: Array = session.drain_events()
    assert_eq(events_before.size(), 0)

    session.set_input_enabled(false)
    assert_false(session.can_accept_input())
    assert_false(session.try_move(Vector2i.RIGHT))
    assert_false(session.try_rotate(1))
    assert_false(session.try_hold())
    assert_null(session.hard_drop_and_commit())

    var disabled_tick = session.tick(gravity * 20.0, true)
    assert_true(disabled_tick is Dictionary)
    assert_eq(session.drain_events().size(), 0, "inactive Line must not mint rewards/events")

    session.set_input_enabled(true)
    assert_true(session.can_accept_input())
    var after: Dictionary = session.snapshot_runtime_state()
    assert_eq(after, before, "LINE → inactive → LINE must preserve the exact legal continuation state")

func test_inactive_time_does_not_reset_or_advance_gravity_lock_or_randomizer_state() -> void:
    var session = _make_session()
    if session == null:
        return

    var gravity: float = session.fall_state.config.gravity_seconds_per_cell
    session.tick(gravity * 0.75, false)
    var origin_before: Vector2i = session.piece_cycle.active_piece.origin
    var preview_before: Array = session.piece_cycle.peek_next(5).duplicate(true)
    var held_before: String = session.piece_cycle.held_piece_id
    var fall_before: Dictionary = session.snapshot_runtime_state()["fall_state"].duplicate(true)

    session.set_input_enabled(false)
    session.tick(gravity * 100.0, false)
    session.set_input_enabled(true)

    assert_eq(session.piece_cycle.active_piece.origin, origin_before)
    assert_eq(session.piece_cycle.peek_next(5), preview_before, "switching must not reroll the queue")
    assert_eq(session.piece_cycle.held_piece_id, held_before)
    assert_eq(session.snapshot_runtime_state()["fall_state"], fall_before)

    session.tick(gravity * 0.50, false)
    assert_eq(
        session.piece_cycle.active_piece.origin,
        origin_before + Vector2i.DOWN,
        "preserved 0.75 gravity interval must continue rather than restart after return"
    )
    assert_almost_eq(
        session.fall_state.gravity_accumulator_seconds,
        gravity * 0.25,
        0.0001
    )
