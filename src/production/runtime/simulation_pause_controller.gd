class_name SimulationPauseController
extends RefCounted

signal pause_state_changed(paused: bool)

const TACTICAL_SKILL := "TACTICAL_SKILL"
const SYSTEM_MENU := "SYSTEM_MENU"
const RUNTIME_TRANSITION := "RUNTIME_TRANSITION"

const _REASON_ORDER: Array[String] = [
    TACTICAL_SKILL,
    SYSTEM_MENU,
    RUNTIME_TRANSITION,
]

var _next_token: int = 1
var _reason_by_token: Dictionary = {}

func acquire(reason: String) -> int:
    if not _is_supported_reason(reason):
        return 0

    var was_paused := is_paused()
    var token := _next_token
    _next_token += 1
    _reason_by_token[token] = reason
    if not was_paused:
        pause_state_changed.emit(true)
    return token

func release(token: int) -> bool:
    if not _reason_by_token.has(token):
        return false

    _reason_by_token.erase(token)
    if not is_paused():
        pause_state_changed.emit(false)
    return true

func is_paused() -> bool:
    return not _reason_by_token.is_empty()

func has_reason(reason: String) -> bool:
    return _reason_by_token.values().has(reason)

func active_reasons() -> Array[String]:
    var reasons: Array[String] = []
    for reason in _REASON_ORDER:
        if has_reason(reason):
            reasons.append(reason)
    return reasons

func _is_supported_reason(reason: String) -> bool:
    return _REASON_ORDER.has(reason)
