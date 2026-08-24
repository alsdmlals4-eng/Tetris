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

func test_action_grid_exposes_exactly_eighteen_data_bound_tactical_cells() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    var grid: GridContainer = scene.get_node("Layout/MainRow/ActionPanel/SkillGrid")
    assert_eq(grid.columns, 6)
    var cells: Array = []
    for child in grid.get_children():
        if child is Button:
            cells.append(child)
    assert_eq(cells.size(), 18)

    var ids: Dictionary = {}
    for cell_value in cells:
        var cell: Button = cell_value
        var technique_id := String(cell.get_meta("technique_id", ""))
        assert_ne(technique_id, "", "Every skill cell must be bound to structured skill data")
        ids[technique_id] = true
        assert_false(cell.text.contains("TUNE_REQUIRED"), "Player-facing cell copy must not expose internal tuning marker")
    assert_eq(ids.size(), 18)
    assert_true(ids.has("atk_t1_quick_cut"))
    assert_true(ids.has("def_t5_rift_ward"))
    assert_true(ids.has("sup_t6_battle_trance"))

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

func test_action_phase_enables_only_runtime_ready_cells_and_exposes_tempo_feedback() -> void:
    var scene = _instantiate_scene()
    if scene == null:
        return
    await get_tree().process_frame

    scene.apply_presentation({
        "current_telegraph": "Gatebreaker Slam",
        "next_forecast": "Rift Siphon",
        "phase": "ACTION",
        "remaining_seconds": 23.0,
        "player_hp": 54,
        "player_max_hp": 100,
        "energy": 12,
        "stock": 2,
        "ready_available": false,
        "tempo_eligible": true,
        "tempo_potency_bonus_ratio": 0.08,
        "technique_readiness": {
            "atk_t1_quick_cut": {"ready": true, "reason": "READY"},
            "atk_t2_sweeping_cut": {"ready": false, "reason": "ENERGY_SHORTAGE"},
        },
    })

    var t1: Button = scene.skill_buttons_by_id["atk_t1_quick_cut"]
    var t2: Button = scene.skill_buttons_by_id["atk_t2_sweeping_cut"]
    assert_false(t1.disabled)
    assert_true(t2.disabled)
    assert_true(t2.tooltip_text.contains("ENERGY_SHORTAGE"))
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
