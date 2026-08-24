class_name LineClearResult
extends RefCounted

var success: bool
var piece_id: String
var lines_cleared: int
var clear_kind: String
var energy_delta: int
var score_delta: int
var spin_kind: String = "NONE"
var combo_index: int = -1
var back_to_back: bool = false
var perfect_clear: bool = false

func _init(
    p_success: bool,
    p_piece_id: String,
    p_lines_cleared: int,
    p_clear_kind: String,
    p_energy_delta: int,
    p_score_delta: int
) -> void:
    success = p_success
    piece_id = p_piece_id
    lines_cleared = p_lines_cleared
    clear_kind = p_clear_kind
    energy_delta = p_energy_delta
    score_delta = p_score_delta

static func classify(lines: int) -> String:
    match lines:
        0:
            return "NONE"
        1:
            return "SINGLE"
        2:
            return "DOUBLE"
        3:
            return "TRIPLE"
        4:
            return "FOUR"
        _:
            return "INVALID"

static func failed(piece_id_value: String) -> LineClearResult:
    return LineClearResult.new(false, piece_id_value, 0, "NONE", 0, 0)

func to_event() -> Dictionary:
    return {
        "kind": &"production_line_resolved",
        "piece_id": piece_id,
        "lines_cleared": lines_cleared,
        "clear_kind": clear_kind,
        "energy_delta": energy_delta,
        "score_delta": score_delta,
        "spin_kind": spin_kind,
        "combo_index": combo_index,
        "back_to_back": back_to_back,
        "perfect_clear": perfect_clear,
    }
