class_name ModeController
extends RefCounted

const BoardStateScript := preload("res://src/core/board_state.gd")

var active_mode: StringName = &"line"
var line_state: int = BoardStateScript.LOCKED
var chain_state: int = BoardStateScript.SUSPENDED
var queued_mode: StringName = &""

func request_switch(target_mode: StringName) -> bool:
    if target_mode != &"line" and target_mode != &"chain":
        return false
    if target_mode == active_mode:
        return false
    if _active_state() == BoardStateScript.RESOLVING:
        queued_mode = target_mode
        return true
    _set_mode_state(active_mode, BoardStateScript.SUSPENDED)
    active_mode = target_mode
    _set_mode_state(active_mode, BoardStateScript.LOCKED)
    queued_mode = &""
    return true

func set_running() -> bool:
    if _active_state() == BoardStateScript.RESOLVING:
        return false
    _set_mode_state(active_mode, BoardStateScript.RUNNING)
    _force_inactive_suspended()
    return true

func set_locked() -> bool:
    if _active_state() == BoardStateScript.RESOLVING:
        return false
    _set_mode_state(active_mode, BoardStateScript.LOCKED)
    _force_inactive_suspended()
    return true

func begin_resolution() -> bool:
    if _active_state() == BoardStateScript.RESOLVING:
        return false
    _set_mode_state(active_mode, BoardStateScript.RESOLVING)
    _force_inactive_suspended()
    return true

func finish_resolution() -> bool:
    if _active_state() != BoardStateScript.RESOLVING:
        return false
    _set_mode_state(active_mode, BoardStateScript.LOCKED)
    var pending := queued_mode
    queued_mode = &""
    if pending != &"":
        return request_switch(pending)
    return true

func state_for(mode: StringName) -> int:
    if mode == &"line":
        return line_state
    if mode == &"chain":
        return chain_state
    return -1

func _active_state() -> int:
    return state_for(active_mode)

func _set_mode_state(mode: StringName, value: int) -> void:
    if mode == &"line":
        line_state = value
    elif mode == &"chain":
        chain_state = value

func _force_inactive_suspended() -> void:
    if active_mode == &"line":
        chain_state = BoardStateScript.SUSPENDED
    else:
        line_state = BoardStateScript.SUSPENDED
