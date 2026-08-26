class_name TimeEffectState
extends RefCounted

var _effects: Array[TurnBudgetModifier] = []

func apply_effect(
    source_id: String,
    stack_group: String,
    flat_seconds: float,
    stackable: bool,
    expires_after_turns: int
) -> void:
    if not stackable:
        for index in range(_effects.size()):
            if _effects[index].stack_group == stack_group:
                _effects[index] = TurnBudgetModifier.new(
                    source_id,
                    stack_group,
                    flat_seconds,
                    stackable,
                    expires_after_turns
                )
                return

    _effects.append(TurnBudgetModifier.new(
        source_id,
        stack_group,
        flat_seconds,
        stackable,
        expires_after_turns
    ))

func get_total_flat_seconds_for_next_turn() -> float:
    var total := 0.0
    for effect in _effects:
        total += effect.flat_seconds
    return total

func advance_turn_boundary() -> void:
    var retained: Array[TurnBudgetModifier] = []
    for effect in _effects:
        if effect.advance_turn_boundary():
            retained.append(effect)
    _effects = retained
