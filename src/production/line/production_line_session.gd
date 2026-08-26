class_name ProductionLineSession
extends RefCounted

var turn_controller: TurnController
var piece_cycle: LinePieceCycle
var fall_state: LineFallState
var reward_config: LineRewardConfig
var last_line_result: LineClearResult = null
var last_board_break_result: LineBoardBreakResult = null

var _events: Array[Dictionary] = []

func _init(
    p_turn_controller: TurnController,
    p_piece_cycle: LinePieceCycle,
    p_fall_state: LineFallState,
    p_reward_config: LineRewardConfig
) -> void:
    turn_controller = p_turn_controller
    piece_cycle = p_piece_cycle
    fall_state = p_fall_state
    reward_config = p_reward_config

func start_line() -> bool:
    if turn_controller.phase != TurnPhase.ENEMY_TELEGRAPH:
        return false
    turn_controller.enter_line()
    return turn_controller.phase == TurnPhase.LINE

func can_accept_input() -> bool:
    return (
        turn_controller.phase == TurnPhase.LINE
        and piece_cycle.active_piece != null
        and not fall_state.lock_requested
    )

func tick(delta: float, soft_drop: bool = false) -> void:
    if not can_accept_input() or delta <= 0.0:
        return

    turn_controller.tick_player_time(delta)
    if turn_controller.phase != TurnPhase.LINE:
        return

    fall_state.tick(delta, piece_cycle.board, piece_cycle.active_piece, soft_drop)
    if fall_state.lock_requested:
        _commit_active_piece()

func try_move(delta: Vector2i) -> bool:
    if not can_accept_input():
        return false
    var moved := piece_cycle.active_piece.try_move(piece_cycle.board, delta)
    if moved:
        fall_state.notify_successful_manipulation(piece_cycle.board, piece_cycle.active_piece)
    return moved

func try_rotate(direction: int) -> bool:
    if not can_accept_input():
        return false
    var rotated := piece_cycle.active_piece.try_rotate(piece_cycle.board, direction)
    if rotated:
        fall_state.notify_successful_manipulation(piece_cycle.board, piece_cycle.active_piece)
    return rotated

func try_hold() -> bool:
    if not can_accept_input():
        return false
    var held := piece_cycle.try_hold()
    if held:
        _reset_fall_state_for_active_piece()
    return held

func hard_drop_and_commit():
    if not can_accept_input():
        return null
    fall_state.hard_drop_and_request_lock(piece_cycle.board, piece_cycle.active_piece)
    return _commit_active_piece()

func request_ready() -> bool:
    if not can_accept_input():
        return false
    turn_controller.request_ready()
    return turn_controller.phase == TurnPhase.LINE_SETTLE

func complete_settle() -> bool:
    if turn_controller.phase != TurnPhase.LINE_SETTLE:
        return false
    turn_controller.complete_line_settle()
    return true

func resolve_board_break(reason: String):
    if turn_controller.phase != TurnPhase.LINE:
        return null
    var result := piece_cycle.reset_after_board_break(reason)
    if not result.triggered:
        return null
    last_board_break_result = result
    _events.append(result.to_event())
    _reset_fall_state_for_active_piece()
    return result

func drain_events() -> Array:
    var drained: Array = _events.duplicate(true)
    _events.clear()
    return drained

func _commit_active_piece():
    var result := piece_cycle.commit_active_piece(reward_config)
    if not result.success:
        return result

    last_line_result = result
    _events.append(result.to_event())
    _reset_fall_state_for_active_piece()

    if piece_cycle.is_active_spawn_blocked():
        resolve_board_break("SPAWN_BLOCKED")

    return result

func _reset_fall_state_for_active_piece() -> void:
    fall_state = LineFallState.new(fall_state.config)
