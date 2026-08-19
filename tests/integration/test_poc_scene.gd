extends GutTest

func _instantiate_scene():
    var packed := load("res://scenes/poc_battle.tscn")
    assert_not_null(packed)
    if packed == null:
        return null
    var scene = packed.instantiate()
    assert_not_null(scene)
    if scene != null:
        add_child_autofree(scene)
    return scene

func test_poc_scene_instantiates_with_required_controls() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame
    assert_not_null(scene.get_node("Layout/HUD/PlayerStatus"))
    assert_not_null(scene.get_node("Layout/HUD/EnemyStatus"))
    assert_not_null(scene.get_node("Layout/HUD/NextAction"))
    assert_not_null(scene.get_node("Layout/HUD/ResourceStatus"))
    assert_not_null(scene.get_node("Layout/ModeControls/LineButton"))
    assert_not_null(scene.get_node("Layout/ModeControls/ChainButton"))
    assert_not_null(scene.get_node("Layout/ModeControls/RunLockButton"))
    assert_not_null(scene.get_node("Layout/DebugControls/Debug1"))
    assert_not_null(scene.get_node("Layout/SkillControls/AttackButton"))
    assert_not_null(scene.get_node("Layout/SkillControls/DefenseButton"))
    assert_not_null(scene.get_node("Layout/SkillControls/HealButton"))

func test_scene_starts_line_locked_and_switch_requires_explicit_run() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame
    assert_eq(scene.session.modes.active_mode, &"line")
    assert_eq(scene.session.modes.line_state, BoardState.LOCKED)
    scene._on_chain_mode_pressed()
    assert_eq(scene.session.modes.active_mode, &"chain")
    assert_eq(scene.session.modes.chain_state, BoardState.LOCKED)
    assert_eq(scene.session.chain_source.advance_count, 0)
    scene.session.tick(1.0)
    assert_eq(scene.session.chain_source.advance_count, 0)
    scene._on_run_lock_pressed()
    scene.session.tick(1.0)
    assert_eq(scene.session.chain_source.advance_count, 1)

func test_next_enemy_action_is_visible_in_hud() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame
    var next_label: Label = scene.get_node("Layout/HUD/NextAction")
    assert_true(next_label.text.contains("attack 40"))

func test_mode_buttons_show_locked_running_and_suspended_states() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame
    assert_true(scene.line_button.text.contains("LOCKED"))
    assert_true(scene.chain_button.text.contains("SUSPENDED"))
    scene._on_run_lock_pressed()
    assert_true(scene.line_button.text.contains("RUNNING"))
    assert_true(scene.chain_button.text.contains("SUSPENDED"))
    scene._on_chain_mode_pressed()
    assert_true(scene.line_button.text.contains("SUSPENDED"))
    assert_true(scene.chain_button.text.contains("LOCKED"))

func test_skill_buttons_are_disabled_during_resolution() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame
    scene.session.combat.energy = 15
    scene.session.combat.chain_stock = 1
    scene.session.run_active()
    assert_true(scene.session.begin_active_resolution())
    scene._refresh_ui()
    assert_true(scene.attack_button.disabled)
    assert_true(scene.defense_button.disabled)
    assert_true(scene.heal_button.disabled)
