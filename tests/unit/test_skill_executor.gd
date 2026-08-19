extends GutTest

var CombatStateScript := preload("res://src/core/combat_state.gd")

func _load_required(path: String):
    var script := load(path)
    assert_not_null(script)
    return script

func test_tier_one_attack_spends_resources_and_damages_enemy() -> void:
    var definition_script = _load_required("res://src/skills/skill_definition.gd")
    var executor = _load_required("res://src/skills/skill_executor.gd")
    if definition_script == null or executor == null:
        return
    var state = CombatStateScript.new()
    state.energy = 15
    state.chain_stock = 1
    var skill = definition_script.new(&"attack_t1", &"attack", 1, 15, 25)
    assert_true(executor.execute(skill, state))
    assert_eq(state.enemy_hp, 275)
    assert_eq(state.energy, 0)
    assert_eq(state.chain_stock, 0)

func test_unavailable_skill_causes_no_mutation() -> void:
    var definition_script = _load_required("res://src/skills/skill_definition.gd")
    var executor = _load_required("res://src/skills/skill_executor.gd")
    if definition_script == null or executor == null:
        return
    var state = CombatStateScript.new()
    state.energy = 15
    state.chain_stock = 1
    var skill = definition_script.new(&"attack_t5", &"attack", 5, 85, 150)
    assert_false(executor.execute(skill, state))
    assert_eq(state.enemy_hp, 300)
    assert_eq(state.energy, 15)
    assert_eq(state.chain_stock, 1)

func test_defense_adds_shield_and_heal_clamps_to_max_hp() -> void:
    var definition_script = _load_required("res://src/skills/skill_definition.gd")
    var executor = _load_required("res://src/skills/skill_executor.gd")
    if definition_script == null or executor == null:
        return
    var defense_state = CombatStateScript.new()
    defense_state.energy = 15
    defense_state.chain_stock = 1
    var defense = definition_script.new(&"defense_t1", &"defense", 1, 15, 30)
    assert_true(executor.execute(defense, defense_state))
    assert_eq(defense_state.shield, 30)

    var heal_state = CombatStateScript.new()
    heal_state.player_hp = 190
    heal_state.energy = 15
    heal_state.chain_stock = 1
    var heal = definition_script.new(&"heal_t1", &"heal", 1, 15, 25)
    assert_true(executor.execute(heal, heal_state))
    assert_eq(heal_state.player_hp, 200)
