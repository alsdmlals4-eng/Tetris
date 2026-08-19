class_name EnemyPattern
extends RefCounted

const SCHEDULE := [
    {"time": 12.0, "kind": &"attack", "magnitude": 40},
    {"time": 24.0, "kind": &"attack", "magnitude": 70},
    {"time": 36.0, "kind": &"heal", "magnitude": 40},
]

var _next_index: int = 0

func process_due(combat_state) -> Array:
    var resolved: Array = []
    if combat_state == null:
        return resolved
    while _next_index < SCHEDULE.size() and combat_state.combat_time >= float(SCHEDULE[_next_index].time):
        var action: Dictionary = SCHEDULE[_next_index].duplicate(true)
        _apply_action(action, combat_state)
        resolved.append(action)
        _next_index += 1
    return resolved

func next_action() -> Dictionary:
    if _next_index >= SCHEDULE.size():
        return {}
    return SCHEDULE[_next_index].duplicate(true)

func _apply_action(action: Dictionary, combat_state) -> void:
    match action.kind:
        &"attack":
            combat_state.apply_incoming_damage(int(action.magnitude))
        &"heal":
            combat_state.enemy_hp = clampi(
                combat_state.enemy_hp + int(action.magnitude),
                0,
                combat_state.enemy_max_hp
            )
