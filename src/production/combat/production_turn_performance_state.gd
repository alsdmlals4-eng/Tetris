class_name ProductionTurnPerformanceState
extends RefCounted

var line_qualified: bool = false
var chain_qualified: bool = false
var action_non_pass: bool = false
var timeout_occurred: bool = false
var board_break_occurred: bool = false

func record_event(event: Dictionary) -> bool:
    match StringName(event.get("kind", &"")):
        &"production_line_resolved":
            line_qualified = true
            return true
        &"production_chain_resolved":
            chain_qualified = true
            return true
        &"production_line_board_break":
            board_break_occurred = true
            return true
        _:
            return false

func mark_timeout() -> void:
    timeout_occurred = true

func mark_action(action_id: String) -> void:
    action_non_pass = action_id != "" and action_id != "PASS"

func reset_for_next_turn() -> void:
    line_qualified = false
    chain_qualified = false
    action_non_pass = false
    timeout_occurred = false
    board_break_occurred = false
