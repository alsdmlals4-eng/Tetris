class_name LineSpinRecognizer
extends RefCounted

static func classify(board: LineBoard, piece: ActiveTetromino) -> String:
    if board == null or piece == null:
        return "NONE"
    if piece.piece_id != "T" or piece.last_successful_action != "ROTATE":
        return "NONE"

    var pivot := piece.origin + Vector2i(1, 1)
    var corners := [
        pivot + Vector2i(-1, -1),
        pivot + Vector2i(1, -1),
        pivot + Vector2i(-1, 1),
        pivot + Vector2i(1, 1),
    ]
    var occupied := 0
    for position in corners:
        if position.x < 0 or position.x >= board.width or position.y < 0 or position.y >= board.total_height:
            occupied += 1
        elif board.get_cell(position) != "":
            occupied += 1

    return "T_SPIN" if occupied >= 3 else "NONE"
