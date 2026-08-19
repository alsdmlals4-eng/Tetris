class_name SkillDefinition
extends RefCounted

var id: StringName
var role: StringName
var tier: int
var energy_cost: int
var magnitude: int

func _init(
    p_id: StringName = &"",
    p_role: StringName = &"",
    p_tier: int = 1,
    p_energy_cost: int = 0,
    p_magnitude: int = 0
) -> void:
    id = p_id
    role = p_role
    tier = p_tier
    energy_cost = p_energy_cost
    magnitude = p_magnitude
