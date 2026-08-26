class_name TurnBudget
extends RefCounted

var effective_budget_seconds: float = 0.0
var remaining_seconds: float = 0.0
var active_used_seconds: float = 0.0
var frozen: bool = true

func snapshot(base_seconds: float, flat_modifier_seconds: float, min_seconds: float, max_seconds: float) -> void:
    effective_budget_seconds = clampf(base_seconds + flat_modifier_seconds, min_seconds, max_seconds)
    remaining_seconds = effective_budget_seconds
    active_used_seconds = 0.0
    frozen = false

func consume(delta: float) -> void:
    if frozen or delta <= 0.0 or remaining_seconds <= 0.0:
        return
    var spent := minf(delta, remaining_seconds)
    remaining_seconds -= spent
    active_used_seconds += spent

func is_expired() -> bool:
    return remaining_seconds <= 0.0

func freeze() -> void:
    frozen = true
