class_name LineFallState
extends RefCounted

var config: LineFeelConfig
var gravity_accumulator_seconds: float = 0.0
var grounded_seconds: float = 0.0
var lock_reset_count: int = 0
var lock_requested: bool = false

func _init(p_config: LineFeelConfig) -> void:
    config = p_config

func _is_grounded(board: LineBoard, piece: ActiveTetromino) -> bool:
    return not board.can_place(piece.get_cells(), piece.origin + Vector2i.DOWN)

func tick(delta: float, board: LineBoard, piece: ActiveTetromino, soft_drop: bool) -> void:
    if lock_requested or delta <= 0.0:
        return

    if _is_grounded(board, piece):
        grounded_seconds += delta
        if grounded_seconds >= config.lock_delay_seconds:
            lock_requested = true
        return

    grounded_seconds = 0.0
    var interval := config.gravity_seconds_per_cell
    if soft_drop:
        interval /= config.soft_drop_multiplier
    if interval <= 0.0:
        return

    gravity_accumulator_seconds += delta
    while gravity_accumulator_seconds >= interval:
        if not piece.try_move(board, Vector2i.DOWN):
            break
        gravity_accumulator_seconds -= interval
        if _is_grounded(board, piece):
            break

func notify_successful_manipulation(board: LineBoard, piece: ActiveTetromino) -> bool:
    if lock_requested or lock_reset_count >= config.max_lock_resets:
        return false

    var was_locking := grounded_seconds > 0.0
    var is_grounded_now := _is_grounded(board, piece)
    if not was_locking and not is_grounded_now:
        return false

    lock_reset_count += 1
    grounded_seconds = 0.0
    return true

func hard_drop_and_request_lock(board: LineBoard, piece: ActiveTetromino) -> int:
    if lock_requested:
        return 0
    var distance := piece.hard_drop(board)
    grounded_seconds = config.lock_delay_seconds
    lock_requested = true
    return distance
