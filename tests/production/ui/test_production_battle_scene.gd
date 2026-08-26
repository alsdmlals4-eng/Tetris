extends GutTest

const SCENE_PATH := "res://scenes/production/battle.tscn"

func _instantiate_scene():
    var packed = load(SCENE_PATH)
    assert_not_null(packed, "Production battle scene must exist")
    if packed == null:
        return null
    var scene = packed.instantiate()
    assert_not_null(scene)
    if scene != null:
        add_child_autofree(scene)
    return scene

func _all_buttons(root: Node) -> Array:
    var result: Array = []
    for child in root.get_children():
        if child is Button:
            result.append(child)
        result.append_array(_all_buttons(child))
    return result

func _all_labels(root: Node) -> Array:
    var result: Array = []
    for child in root.get_children():
        if child is Label:
            result.append(child)
        result.append_array(_all_labels(child))
    return result

func _action_state(readiness: Dictionary = {}) -> Dictionary:
    return {
        "current_telegraph": "Gatebreaker Slam",
        "next_forecast": "Rift Siphon",
        "phase": "ACTION",
        "remaining_seconds": 23.0,
        "player_hp": 54,
        "player_max_hp": 100,
        "energy": 40,
        "stock": 6,
        "ready_available": false,
        "tempo_eligible": true,
        "tempo_potency_bonus_ratio": 0.08,
        "technique_readiness": readiness,
    }

func test_scene_has_current_forecast_shared_clock_resources_and_puzzle_hosts() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    assert_not_null(scene.get_node("Layout/TopBar/TelegraphPanel/CurrentTelegraph"))
    assert_not_null(scene.get_node("Layout/TopBar/TelegraphPanel/NextForecast"))
    assert_not_null(scene.get_node("Layout/TopBar/TurnPanel/PhaseLabel"))
    assert_not_null(scene.get_node("Layout/TopBar/TurnPanel/SharedTimer"))
    assert_not_null(scene.get_node("Layout/ResourceBar/HPLabel"))
    assert_not_null(scene.get_node("Layout/ResourceBar/EnergyLabel"))
    assert_not_null(scene.get_node("Layout/ResourceBar/StockLabel"))
    assert_not_null(scene.get_node("Layout/MainRow/PuzzlePanel/LineBoardHost"))
    assert_not_null(scene.get_node("Layout/MainRow/PuzzlePanel/ChainBoardHost"))
    assert_not_null(scene.get_node("Layout/MainRow/ActionPanel/TempoLabel"))
    assert_not_null(scene.get_node("Layout/MainRow/ActionPanel/ReadyButton"))

func test_puzzle_surface_is_larger_than_prior_engineering_layout() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    var puzzle_panel: Control = scene.get_node("Layout/MainRow/PuzzlePanel")
    var line_host: Control = scene.get_node("Layout/MainRow/PuzzlePanel/LineBoardHost")
    var action_panel: Control = scene.get_node("Layout/MainRow/ActionPanel")
    assert_gte(puzzle_panel.custom_minimum_size.x, 600.0, "Puzzle should own the larger horizontal share")
    assert_gte(line_host.custom_minimum_size.y, 480.0, "Line surface should have enough vertical room for larger cells")
    assert_lte(action_panel.custom_minimum_size.x, 560.0, "Action menu should no longer dominate the screen width")

func test_action_panel_uses_three_lane_tabs_and_only_six_visible_skill_rows() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    var attack_tab := scene.get_node_or_null("Layout/MainRow/ActionPanel/LaneTabs/AttackLaneButton") as Button
    var defense_tab := scene.get_node_or_null("Layout/MainRow/ActionPanel/LaneTabs/DefenseLaneButton") as Button
    var support_tab := scene.get_node_or_null("Layout/MainRow/ActionPanel/LaneTabs/SupportLaneButton") as Button
    var skill_list := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillList") as VBoxContainer
    assert_not_null(attack_tab)
    assert_not_null(defense_tab)
    assert_not_null(support_tab)
    assert_not_null(skill_list)
    assert_null(scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillGrid"), "Old 18-cell always-visible grid must be removed")
    if attack_tab == null or defense_tab == null or support_tab == null or skill_list == null:
        return

    var rows: Array = []
    for child in skill_list.get_children():
        if child is Button:
            rows.append(child)
    assert_eq(rows.size(), 6)
    for row_value in rows:
        var row: Button = row_value
        assert_true(String(row.get_meta("technique_id", "")).begins_with("atk_"))

    defense_tab.pressed.emit()
    for row_value in rows:
        var row: Button = row_value
        assert_true(String(row.get_meta("technique_id", "")).begins_with("def_"))

    support_tab.pressed.emit()
    for row_value in rows:
        var row: Button = row_value
        assert_true(String(row.get_meta("technique_id", "")).begins_with("sup_"))

func test_skill_row_opens_detail_without_committing_action() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    var skill_list := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillList") as VBoxContainer
    var detail_panel := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillDetailPanel") as Control
    var detail_title := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/SkillDetailTitle") as Label
    var detail_meta := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/SkillDetailMeta") as Label
    var detail_effects := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/SkillDetailEffects") as Label
    assert_not_null(skill_list)
    assert_not_null(detail_panel)
    assert_not_null(detail_title)
    assert_not_null(detail_meta)
    assert_not_null(detail_effects)
    if skill_list == null or detail_panel == null or detail_title == null or detail_meta == null or detail_effects == null:
        return

    scene.apply_presentation(_action_state({
        "atk_t1_quick_cut": {"ready": true, "reason": "READY"},
    }))

    var emitted_ids: Array[String] = []
    scene.technique_requested.connect(func(technique_id: String): emitted_ids.append(technique_id))
    var first_row := skill_list.get_child(0) as Button
    first_row.pressed.emit()

    assert_true(detail_panel.visible)
    assert_true(detail_title.text.contains("신속 베기"))
    assert_true(detail_meta.text.contains("T1"))
    assert_true(detail_meta.text.contains("Stock 1"))
    assert_true(detail_meta.text.contains("Energy 10"))
    assert_false(detail_effects.text.is_empty())
    assert_eq(emitted_ids.size(), 0, "Inspecting a technique must never spend or commit it")

func test_use_button_is_only_commit_path_and_respects_runtime_readiness() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    var skill_list := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillList") as VBoxContainer
    var use_button := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/UseTechniqueButton") as Button
    assert_not_null(skill_list)
    assert_not_null(use_button)
    if skill_list == null or use_button == null:
        return

    scene.apply_presentation(_action_state({
        "atk_t1_quick_cut": {"ready": true, "reason": "READY"},
        "atk_t2_sweeping_cut": {"ready": false, "reason": "ENERGY_SHORTAGE"},
    }))

    var emitted_ids: Array[String] = []
    scene.technique_requested.connect(func(technique_id: String): emitted_ids.append(technique_id))

    var first_row := skill_list.get_child(0) as Button
    first_row.pressed.emit()
    assert_false(use_button.disabled)
    use_button.pressed.emit()
    assert_eq(emitted_ids, ["atk_t1_quick_cut"])

    var second_row := skill_list.get_child(1) as Button
    second_row.pressed.emit()
    assert_true(use_button.disabled)
    use_button.pressed.emit()
    assert_eq(emitted_ids, ["atk_t1_quick_cut"], "Unavailable technique must not emit a second commit")

func test_tune_required_detail_is_player_safe_and_fail_closed() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    var support_tab := scene.get_node_or_null("Layout/MainRow/ActionPanel/LaneTabs/SupportLaneButton") as Button
    var skill_list := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillList") as VBoxContainer
    var detail_effects := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/SkillDetailEffects") as Label
    var use_button := scene.get_node_or_null("Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/UseTechniqueButton") as Button
    assert_not_null(support_tab)
    assert_not_null(skill_list)
    assert_not_null(detail_effects)
    assert_not_null(use_button)
    if support_tab == null or skill_list == null or detail_effects == null or use_button == null:
        return

    scene.apply_presentation(_action_state({
        "sup_t4_mark_weakness": {"ready": false, "reason": "UNRESOLVED_EFFECT_CONTRACT"},
    }))
    support_tab.pressed.emit()
    var fourth_row := skill_list.get_child(3) as Button
    fourth_row.pressed.emit()

    assert_true(detail_effects.text.contains("조정 중"))
    assert_false(detail_effects.text.contains("TUNE_REQUIRED"))
    assert_true(use_button.disabled)

func test_presentation_uses_one_continuous_shared_timer_and_phase_authority() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    scene.apply_presentation({
        "current_telegraph": "Light Smash · 예상 피해 12",
        "next_forecast": "Gatebreaker Slam",
        "phase": "LINE",
        "remaining_seconds": 72.5,
        "player_hp": 88,
        "player_max_hp": 100,
        "energy": 21,
        "stock": 3,
        "ready_available": true,
        "tempo_eligible": false,
        "tempo_potency_bonus_ratio": 0.0,
        "technique_readiness": {},
    })

    assert_true(scene.current_telegraph_label.text.contains("Light Smash"))
    assert_true(scene.next_forecast_label.text.contains("Gatebreaker Slam"))
    assert_true(scene.phase_label.text.contains("LINE"))
    assert_true(scene.shared_timer_label.text.contains("72.5"))
    assert_true(scene.hp_label.text.contains("88 / 100"))
    assert_true(scene.energy_label.text.contains("21"))
    assert_true(scene.stock_label.text.contains("3 / 6"))
    assert_true(scene.ready_button.visible)
    assert_false(scene.ready_button.disabled)
    assert_true(scene.line_board_host.visible)
    assert_false(scene.chain_board_host.visible)

    var same_timer: Label = scene.shared_timer_label
    scene.apply_presentation({
        "current_telegraph": "Light Smash · 예상 피해 12",
        "next_forecast": "Gatebreaker Slam",
        "phase": "CHAIN",
        "remaining_seconds": 61.0,
        "player_hp": 88,
        "player_max_hp": 100,
        "energy": 21,
        "stock": 3,
        "ready_available": true,
        "tempo_eligible": false,
        "tempo_potency_bonus_ratio": 0.0,
        "technique_readiness": {},
    })

    assert_eq(scene.shared_timer_label, same_timer, "Phase changes reuse the same shared timer widget")
    assert_true(scene.shared_timer_label.text.contains("61.0"))
    assert_false(scene.line_board_host.visible)
    assert_true(scene.chain_board_host.visible)

func test_action_phase_exposes_tempo_feedback_without_immediate_skill_commit() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    scene.apply_presentation(_action_state({
        "atk_t1_quick_cut": {"ready": true, "reason": "READY"},
    }))

    assert_false(scene.ready_button.visible)
    assert_true(scene.tempo_label.text.contains("+8%"))

func test_production_scene_contains_no_old_run_lock_or_enemy_eta_copy() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    for button_value in _all_buttons(scene):
        var button: Button = button_value
        var upper := button.text.to_upper()
        assert_false(upper.contains("RUN"))
        assert_false(upper.contains("LOCK"))

    for label_value in _all_labels(scene):
        var label: Label = label_value
        var upper := label.text.to_upper()
        assert_false(upper.contains("ENEMY ETA"))
        assert_false(upper.contains("COMBAT CLOCK"))
        assert_false(upper.contains("RUN/LOCK"))

    assert_true(scene.has_signal("ready_requested"))
    assert_true(scene.has_signal("technique_requested"))
