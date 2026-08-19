extends GutTest

var BoardState := preload("res://src/core/board_state.gd")

func _load_script(path: String):
    var script := load(path)
    assert_not_null(script)
    return script

func test_line_source_only_advances_when_running() -> void:
    var script = _load_script("res://src/puzzle/debug_line_source.gd")
    if script == null:
        return
    var source = script.new()
    source.state = BoardState.LOCKED
    source.advance(1.0)
    assert_eq(source.advance_count, 0)
    source.state = BoardState.RUNNING
    source.advance(1.0)
    assert_eq(source.advance_count, 1)
    source.state = BoardState.SUSPENDED
    source.advance(1.0)
    assert_eq(source.advance_count, 1)

func test_line_source_emits_normalized_clear_event() -> void:
    var script = _load_script("res://src/puzzle/debug_line_source.gd")
    if script == null:
        return
    var event: Dictionary = script.new().emit_clear(2)
    assert_eq(event.kind, &"line_clear")
    assert_eq(event.lines, 2)
    assert_eq(event.energy, 22)

func test_chain_source_emits_normalized_completed_event() -> void:
    var script = _load_script("res://src/puzzle/debug_chain_source.gd")
    if script == null:
        return
    var event: Dictionary = script.new().emit_completed_chain(4, 16)
    assert_eq(event.kind, &"chain_complete")
    assert_eq(event.chain_count, 4)
    assert_eq(event.stock_value, 4)
    assert_eq(event.pieces_cleared, 16)
