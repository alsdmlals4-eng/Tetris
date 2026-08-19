class_name PuzzleEventSource
extends RefCounted

const BoardStateScript := preload("res://src/core/board_state.gd")

var state: int = BoardStateScript.LOCKED
var advance_count: int = 0
var elapsed: float = 0.0

func advance(delta: float) -> void:
    if state != BoardStateScript.RUNNING or delta <= 0.0:
        return
    advance_count += 1
    elapsed += delta
