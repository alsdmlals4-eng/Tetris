class_name LineStreakState
extends RefCounted

var _combo_index: int = -1
var _back_to_back_active: bool = false

func decorate(result: LineClearResult) -> void:
    if result == null:
        return

    if result.lines_cleared > 0:
        _combo_index += 1
        result.combo_index = _combo_index
    else:
        _combo_index = -1
        result.combo_index = -1

    var difficult_clear := result.clear_kind == "FOUR" or (
        result.spin_kind == "T_SPIN" and result.lines_cleared > 0
    )
    if difficult_clear:
        result.back_to_back = _back_to_back_active
        _back_to_back_active = true
    elif result.lines_cleared > 0:
        result.back_to_back = false
        _back_to_back_active = false
    else:
        result.back_to_back = false
