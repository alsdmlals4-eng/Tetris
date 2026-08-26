class_name ProductionLineSession
extends RefCounted

var piece_cycle: LinePieceCycle
var fall_state: LineFallState
var reward_config: LineRewardConfig
var input_enabled: bool = true
var last_line_result: LineClearResult = null
var last_board_break_result: LineBoardBreakResult = null

var _events: Array[Dictionary] = []

func _init(
    p_piece_cycle: LinePieceCycle,
    p_fall_state: LineFallState,
    p_reward_config: LineRewardConfig
) -> void:
    piece_cycle = p_piece_cycle
    fall_state = p_fall_state
    reward_config = p_reward_config

func set_input_enabled(enabled: bool) -> void:
    input_enabled = enabled

func can_accept_input() -> bool:
    return (
        input_enabled
        and piece_cycle != null
        and piece_cycle.active_piece != null
        and fall_state != null
        and not fall_state.lock_requested
    )

func tick(delta: float, soft_drop: bool = false) -> Dictionary:
    if delta <= 0.0:
        return {"advanced": false, "reason": "INVALID_DELTA"}
    if not input_enabled:
        return {"advanced": false, "reason": "INPUT_DISABLED"}
    if not can_accept_input():
        return {"advanced": false, "reason": "INPUT_UNAVAILABLE"}

    fall_state.tick(delta, piece_cycle.board, piece_cycle.active_piece, soft_drop)
    if fall_state.lock_requested:
        var result = _commit_active_piece()
        return {
            "advanced": true,
            "reason": "PIECE_COMMITTED",
            "committed": result != null and bool(result.success),
        }

    return {"advanced": true, "reason": "FALL_ADVANCED", "committed": false}

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

func resolve_board_break(reason: String):
    if not input_enabled or piece_cycle == null:
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

func snapshot_runtime_state() -> Dictionary:
    var board_cells: Array = []
    if piece_cycle != null and piece_cycle.board != null:
        for y in range(piece_cycle.board.total_height):
            var row: Array = []
            for x in range(piece_cycle.board.width):
                row.append(piece_cycle.board.get_cell(Vector2i(x, y)))
            board_cells.append(row)

    var active_piece_state: Dictionary = {}
    if piece_cycle != null and piece_cycle.active_piece != null:
        active_piece_state = {
            "piece_id": piece_cycle.active_piece.piece_id,
            "origin": piece_cycle.active_piece.origin,
            "rotation": piece_cycle.active_piece.rotation,
            "last_successful_action": piece_cycle.active_piece.last_successful_action,
        }

    var preview: Array = []
    if piece_cycle != null and piece_cycle.active_piece != null:
        preview = piece_cycle.peek_next(LinePieceCycle.PREVIEW_MIN).duplicate(true)

    var fall_state_snapshot: Dictionary = {}
    if fall_state != null:
        fall_state_snapshot = {
            "gravity_accumulator_seconds": fall_state.gravity_accumulator_seconds,
            "grounded_seconds": fall_state.grounded_seconds,
            "lock_reset_count": fall_state.lock_reset_count,
            "lock_requested": fall_state.lock_requested,
        }

    return {
        "input_enabled": input_enabled,
        "board_cells": board_cells,
        "active_piece": active_piece_state,
        "held_piece_id": piece_cycle.held_piece_id if piece_cycle != null else "",
        "hold_used_for_active": piece_cycle.hold_used_for_active if piece_cycle != null else false,
        "next_preview": preview,
        "fall_state": fall_state_snapshot,
    }

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
