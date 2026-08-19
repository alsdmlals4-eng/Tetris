extends GutTest

var BoardState := preload("res://src/core/board_state.gd")

func _new_modes():
    var script := load("res://src/core/mode_controller.gd")
    assert_not_null(script)
    if script == null:
        return null
    return script.new()

func test_default_state_starts_line_locked_chain_suspended() -> void:
    var modes = _new_modes()
    if modes == null:
        return
    assert_eq(modes.active_mode, &"line")
    assert_eq(modes.line_state, BoardState.LOCKED)
    assert_eq(modes.chain_state, BoardState.SUSPENDED)

func test_switch_lands_destination_locked() -> void:
    var modes = _new_modes()
    if modes == null:
        return
    modes.set_running()
    assert_true(modes.request_switch(&"chain"))
    assert_eq(modes.active_mode, &"chain")
    assert_eq(modes.line_state, BoardState.SUSPENDED)
    assert_eq(modes.chain_state, BoardState.LOCKED)

func test_only_active_mode_can_run() -> void:
    var modes = _new_modes()
    if modes == null:
        return
    assert_true(modes.set_running())
    assert_eq(modes.line_state, BoardState.RUNNING)
    assert_eq(modes.chain_state, BoardState.SUSPENDED)

func test_switch_during_resolution_is_queued() -> void:
    var modes = _new_modes()
    if modes == null:
        return
    assert_true(modes.begin_resolution())
    assert_true(modes.request_switch(&"chain"))
    assert_eq(modes.active_mode, &"line")
    assert_eq(modes.queued_mode, &"chain")
    assert_true(modes.finish_resolution())
    assert_eq(modes.active_mode, &"chain")
    assert_eq(modes.chain_state, BoardState.LOCKED)

func test_invalid_or_same_mode_switch_does_nothing() -> void:
    var modes = _new_modes()
    if modes == null:
        return
    assert_false(modes.request_switch(&"line"))
    assert_false(modes.request_switch(&"invalid"))
    assert_eq(modes.active_mode, &"line")
    assert_eq(modes.line_state, BoardState.LOCKED)
    assert_eq(modes.chain_state, BoardState.SUSPENDED)
