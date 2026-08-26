class_name LineBoardBreakResult
extends RefCounted

var triggered: bool
var reason: String
var piece_id: String
var line_board_reset: bool

func _init(p_triggered: bool, p_reason: String, p_piece_id: String, p_line_board_reset: bool) -> void:
    triggered = p_triggered
    reason = p_reason
    piece_id = p_piece_id
    line_board_reset = p_line_board_reset

static func rejected(reason_value: String = "") -> LineBoardBreakResult:
    return LineBoardBreakResult.new(false, reason_value, "", false)

func to_event() -> Dictionary:
    return {
        "kind": &"production_line_board_break",
        "reason": reason,
        "piece_id": piece_id,
        "line_board_reset": line_board_reset,
    }
