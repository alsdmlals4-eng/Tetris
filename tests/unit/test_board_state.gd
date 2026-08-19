extends GutTest

func test_board_state_constants() -> void:
    var board_state := load("res://src/core/board_state.gd")
    assert_not_null(board_state)
    if board_state == null:
        return
    assert_eq(board_state.RUNNING, 0)
    assert_eq(board_state.LOCKED, 1)
    assert_eq(board_state.SUSPENDED, 2)
    assert_eq(board_state.RESOLVING, 3)
