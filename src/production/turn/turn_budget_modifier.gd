class_name TurnBudgetModifier
extends RefCounted

var source_id: String
var stack_group: String
var flat_seconds: float
var stackable: bool
var remaining_turns: int

func _init(
    p_source_id: String,
    p_stack_group: String,
    p_flat_seconds: float,
    p_stackable: bool,
    p_remaining_turns: int
) -> void:
    source_id = p_source_id
    stack_group = p_stack_group
    flat_seconds = p_flat_seconds
    stackable = p_stackable
    remaining_turns = p_remaining_turns

func is_permanent() -> bool:
    return remaining_turns < 0

func advance_turn_boundary() -> bool:
    if is_permanent():
        return true
    remaining_turns -= 1
    return remaining_turns > 0
