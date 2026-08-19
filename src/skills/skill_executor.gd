class_name SkillExecutor
extends RefCounted

static func execute(skill, combat_state) -> bool:
    if skill == null or combat_state == null:
        return false
    if skill.role != &"attack" and skill.role != &"defense" and skill.role != &"heal":
        return false
    if skill.magnitude < 0:
        return false
    if not combat_state.can_spend_skill(skill.tier, skill.energy_cost):
        return false
    if not combat_state.spend_skill(skill.tier, skill.energy_cost):
        return false

    match skill.role:
        &"attack":
            combat_state.enemy_hp = clampi(
                combat_state.enemy_hp - skill.magnitude,
                0,
                combat_state.enemy_max_hp
            )
        &"defense":
            combat_state.shield += skill.magnitude
        &"heal":
            combat_state.player_hp = clampi(
                combat_state.player_hp + skill.magnitude,
                0,
                combat_state.player_max_hp
            )
    return true
