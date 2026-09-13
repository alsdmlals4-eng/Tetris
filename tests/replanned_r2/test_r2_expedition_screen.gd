extends GutTest
var screen

class InvalidBriefExpedition extends "res://src/replanned_r2/r2_expedition.gd":
    func encounter_brief(_encounter_id: String) -> Dictionary:
        return {}

func before_each():
    screen = load("res://scenes/replanned_r2/main.tscn").instantiate()
    screen.save_path = "user://replanned_r2_tests/expedition-screen/standalone.json"
    screen.options_path = "user://replanned_r2_tests/expedition-screen/options.json"
    if screen.get("expedition_save_path") != null:
        screen.expedition_save_path = "user://replanned_r2_tests/expedition-screen/expedition.json"
    add_child_autofree(screen)
    screen.set_process(false)

func _ready_campaign() -> bool:
    assert_true(screen.has_method("start_expedition"), "Real screen must expose expedition flow")
    return screen.has_method("start_expedition")

func test_route_displays_enemy_and_first_threat_before_commit():
    screen.start_expedition("STANDARD",41)
    var button: Button = screen.get_node("Expedition/Choice0")
    assert_true("방벽 침식자" in button.text)
    assert_true("120" in button.text)
    assert_true("12.0" in button.text)
    assert_true("16" in button.tooltip_text)
    assert_eq(screen.expedition.view().phase,"ROUTE")
    button.pressed.emit()
    assert_true("방벽 침식자" in screen.get_node("Battle/Combat/Stage/HP").text)

func test_route_cycle_visible_on_keyboard_focus_and_cleared_outside_route():
    screen.start_expedition("STANDARD",41)
    assert_true(screen.has_node("Expedition/ThreatPreview"))
    if not screen.has_node("Expedition/ThreatPreview"): return
    screen.get_node("Expedition/Choice0").focus_entered.emit()
    var preview: Label = screen.get_node("Expedition/ThreatPreview")
    assert_true(preview.visible)
    assert_true("방벽 타격" in preview.text)
    assert_true("16.0" in preview.text)
    screen.get_node("Expedition/Choice0").pressed.emit()
    _play_chain_to_result()
    assert_false(preview.visible)

func test_invalid_brief_disables_departure_and_keeps_safe_exit():
    screen.expedition = InvalidBriefExpedition.new("invalid-brief",41,"STANDARD")
    screen._show_expedition()
    assert_true(screen.get_node("Expedition/Choice0").disabled)
    assert_true("검증 실패" in screen.get_node("Expedition/Status").text)
    assert_true(screen.get_node("Expedition/Main").visible)
    screen.get_node("Expedition/Choice0").pressed.emit()
    assert_eq(screen.page,"expedition")
    assert_eq(screen.expedition.view().phase,"ROUTE")

func test_fork_description_preview_and_buttons_have_spacing_at_125_percent():
    screen.options.font_scale=125
    screen._apply_font()
    screen.start_expedition("STANDARD",41)
    # UI-only progression fixture; not a claim of combat completion.
    var run = screen.expedition
    run.launch("outer_breach")
    run.finish_battle({"run_id":run.view().active_battle.run_id,"outcome":"VICTORY","hp":80})
    run.choose_supply("repair")
    screen._show_expedition()
    await get_tree().process_frame
    var description: Label = screen.get_node("Expedition/Description")
    var preview: Label = screen.get_node("Expedition/ThreatPreview")
    var button: Button = screen.get_node("Expedition/Choice0")
    var description_bottom = description.global_position.y+description.get_line_count()*description.get_theme_font("font").get_height(description.get_theme_font_size("font_size"))
    var preview_bottom = preview.global_position.y+preview.get_line_count()*preview.get_theme_font("font").get_height(preview.get_theme_font_size("font_size"))
    assert_lte(description_bottom,preview.global_position.y-8.0)
    assert_lte(preview_bottom,button.global_position.y-8.0)

func test_main_launch_defeat_retry_and_resume_preserve_standalone_save():
    if not _ready_campaign(): return
    screen.start_run("STANDARD",41)
    var old_save = FileAccess.get_file_as_bytes(screen.save_path)
    screen.return_to_main()
    screen.start_expedition("STANDARD",41)
    assert_eq(screen.page,"expedition")
    screen.get_node("Expedition/Choice0").pressed.emit()
    assert_eq(screen.page,"battle")
    assert_eq(screen.session.combat.encounter_info().id,"outer_breach")
    assert_true("120" in screen.get_node("Battle/Combat/Stage/HP").text)
    screen.dispatch("switch")
    screen.advance_seconds(200.0)
    assert_eq(screen.page,"result")
    assert_eq(screen.expedition.view().phase,"DEFEAT")
    screen.get_node("Result/Retry").pressed.emit()
    assert_eq(screen.page,"battle")
    assert_eq(screen.session.combat.hp,100)
    screen.pause_game()
    screen._exit_battle()
    assert_eq(screen.page,"main")
    screen.continue_expedition()
    assert_eq(screen.page,"battle")
    assert_true(screen.session.combat.paused)
    assert_eq(FileAccess.get_file_as_bytes(screen.save_path),old_save)

func test_route_save_failure_is_retryable_without_live_battle():
    if not _ready_campaign(): return
    screen.expedition_disk.failure_point = "rename"
    screen.start_expedition("STANDARD",41)
    assert_true(screen.get_node("SaveFailurePanel").visible)
    assert_null(screen.session)
    screen.expedition_disk.failure_point = ""
    screen.get_node("SaveFailurePanel/RetrySave").pressed.emit()
    assert_false(screen.get_node("SaveFailurePanel").visible)
    assert_true(screen.expedition_disk.load_expedition().success)

## A zero-deliberation deterministic input driver verifies wiring, NOT human balance.
func _play_chain_to_result():
    var driver = load("res://tests/tooling/r2_expedition_runtime_driver.gd").new()
    var result = driver.drive_one_battle(screen)
    assert_true(result.success,str(result))

func test_real_puzzle_actions_connect_supply_fork_finale_and_saved_ending():
    if not _ready_campaign(): return
    screen.start_expedition("STANDARD",41)
    screen.get_node("Expedition/Choice0").pressed.emit()
    _play_chain_to_result()
    assert_eq(screen.expedition.view().phase,"SUPPLY")
    assert_eq(screen.page,"expedition")

    assert_false(screen.get_node("SaveFailurePanel").visible)
    screen.get_node("Expedition/Choice1").pressed.emit()
    assert_eq(screen.expedition.view().phase,"ROUTE")
    screen.get_node("Expedition/Choice1").pressed.emit()
    assert_eq(screen.session.combat.encounter_info().id,"watchtower")
    assert_eq(screen.session.combat.attack_bank,12)
    _play_chain_to_result()
    assert_eq(screen.expedition.view().phase,"SUPPLY")
    screen.get_node("Expedition/Choice0").pressed.emit()
    screen.get_node("Expedition/Choice0").pressed.emit()
    _play_chain_to_result()
    assert_eq(screen.expedition.view().phase,"COMPLETE")
    assert_true("봉쇄 완료" in screen.get_node("Expedition/Title").text)
    assert_false(screen.get_node("Expedition/Choice0").visible)
    assert_false(screen.get_node("SaveFailurePanel").visible)
    screen.return_to_main()
    screen.continue_expedition()
    assert_eq(screen.expedition.view().phase,"COMPLETE")
    assert_eq(screen.page,"expedition")

func test_route_guidance_keeps_clear_of_main_at_enlarged_font():
    if not _ready_campaign(): return
    screen.options.font_scale = 125
    screen._apply_font()
    screen.start_expedition("STANDARD",42)
    await get_tree().process_frame
    var label: Label = screen.get_node("Expedition/Status")
    var main: Button = screen.get_node("Expedition/Main")
    var line_height = label.get_theme_font("font").get_height(label.get_theme_font_size("font_size"))
    var rendered_bottom = label.global_position.y + label.get_line_count()*line_height
    assert_lte(rendered_bottom,main.global_position.y-8.0,"Guidance must not overlap the exit action")

func test_expedition_heavy_action_uses_heavy_icon():
    if not _ready_campaign(): return
    screen.start_expedition("STANDARD",41)
    screen.get_node("Expedition/Choice0").pressed.emit()
    screen.dispatch("switch")
    screen.advance_seconds(12.0)
    assert_eq(screen.session.combat.current_action().id,"heavy")
    assert_eq(screen.get_node("Battle/Combat/Threat/Icon").texture.region,screen.assets.texture("R1-ICONS","heavy").region)
