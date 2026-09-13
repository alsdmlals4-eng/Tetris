extends GutTest
var screen
func before_each():
    if ResourceLoader.exists("res://scenes/replanned_r2/main.tscn"):
        screen = load("res://scenes/replanned_r2/main.tscn").instantiate()
        screen.save_path = "user://replanned_r2_tests/screen/save.json"
        screen.options_path = "user://replanned_r2_tests/screen/options.json"
        var test_disk=screen.Disk.new(screen.save_path,screen.options_path)
        test_disk.save_options(screen.Disk.default_options())
        add_child_autofree(screen)
        screen.set_process(false)
    else: screen = null
func test_result_export_is_manual_and_preserves_retry_and_save():
    if not ready_screen(): return
    var button = screen.get_node_or_null("Result/ExportReport")
    assert_not_null(button, "Manual report export must be visible in Result")
    if button == null: return
    var directory = "user://replanned_r2_tests/screen/reports_%s" % str(Time.get_ticks_usec())
    screen.report_directory = directory
    screen.start_run("STANDARD",42)
    screen.dispatch("switch")
    screen.advance_seconds(120.0)
    assert_eq(screen.page,"result")
    assert_false(DirAccess.dir_exists_absolute(directory))
    var before = screen.session.snapshot()
    var save_bytes = FileAccess.get_file_as_bytes(screen.save_path)
    button.pressed.emit()
    assert_true(DirAccess.dir_exists_absolute(directory))
    assert_true("저장 완료" in screen.get_node("Result/ExportStatus").text)
    assert_true(screen.get_node("Result/ExportReport").tooltip_text.is_absolute_path())
    for line in screen.get_node("Result/ExportReport").tooltip_text.split("\n"):
        assert_lt(screen.theme.default_font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x,1240.0)
    assert_eq(screen.session.snapshot(),before)
    assert_eq(FileAccess.get_file_as_bytes(screen.save_path),save_bytes)
    screen.report_directory = "res://forbidden"
    button.pressed.emit()
    assert_true("실패" in screen.get_node("Result/ExportStatus").text)
    assert_eq(screen.session.snapshot(),before)
    screen.get_node("Result/Retry").pressed.emit()
    assert_eq(screen.page,"battle")
    assert_ne(screen.session.run_id,before.identity.run_id)

func test_practice_export_and_enlarged_result_controls():
    if not ready_screen(): return
    var button = screen.get_node_or_null("Result/ExportReport")
    assert_not_null(button)
    if button == null: return
    screen.report_directory = "user://replanned_r2_tests/screen/practice_%s" % str(Time.get_ticks_usec())
    screen.start_run("STANDARD",42)
    screen.session.setup_training("CHAIN",true)
    screen._show_result(true,false)
    button.pressed.emit()
    var files = DirAccess.get_files_at(screen.report_directory)
    assert_eq(files.size(),1)
    var data = JSON.parse_string(FileAccess.get_file_as_string(screen.report_directory.path_join(files[0])))
    assert_eq(data.outcome,"PRACTICE_COMPLETE")
    assert_eq(data.practice,"CHAIN")
    screen.options.font_scale = 125
    screen._apply_font()
    for path in ["Result/ExportReport","Result/ExportStatus","Result/Retry","Result/Main"]:
        var node = screen.get_node(path)
        assert_true(screen.get_node("Result").get_global_rect().encloses(node.get_global_rect()))
    screen.get_node("Result/Main").pressed.emit()
    assert_eq(screen.page,"main")

func ready_screen() -> bool:
    assert_not_null(screen,"Separate R2 runnable main entry must exist")
    return screen != null

func test_live_threat_and_skill_estimates_explain_effective_values_without_mutation():
    if not ready_screen(): return
    screen.start_run("STANDARD", 42)
    var combat = screen.session.combat
    combat.armor = 2
    combat.cast("ward-preview", "DEF", 1)
    combat.attack_bank = 7
    combat.boss_hp = 8
    var before = screen.session.snapshot()
    screen.refresh()
    var threat = screen.get_node("Battle/Combat/Threat/Damage")
    assert_true("HP -7" in threat.text, "Show actual protected HP loss, not only raw damage")
    assert_true("93" in threat.text)
    assert_ne(threat.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Breakdown tooltip must be reachable")
    assert_true("방벽 3" in threat.tooltip_text)
    assert_true("방어도 2" in threat.tooltip_text)
    var next = screen.get_node("Battle/Combat/SkillDock/Next")
    assert_true("8" in next.text)
    assert_true("가산 7" in next.tooltip_text)
    assert_eq(screen.session.snapshot(), before)
    combat.hp = 5
    combat.armor = 0
    screen.refresh()
    assert_true("치명" in threat.text)
    screen.session.selected_category = "SUP"
    combat.hp = 99
    screen.refresh()
    assert_true("회복 1 / 2" in next.text)
    screen.options.font_scale = 125
    screen._apply_font()
    for path in ["Battle/Combat/Threat/Damage", "Battle/Combat/SkillDock/Next", "Battle/Combat/SkillDock/Recent"]:
        var label = screen.get_node(path)
        assert_lte(label.get_line_height() * label.get_line_count(), int(label.size.y))

func test_line_heal_receipt_and_recent_attack_reveal_waste_and_bank_consumption():
    if not ready_screen(): return
    screen.start_run("STANDARD", 42)
    screen.session.combat.hp = 99
    var event = screen.session.combat.apply_line("preview-line", [
        {"id":"h1", "kind":"H"}, {"id":"h2", "kind":"H"}, {"id":"a1", "kind":"A"}])
    screen._events([event])
    screen.refresh()
    assert_true("회복 1 / 2" in screen.get_node("Battle/Puzzle/Line/Receipt").text)
    screen.session.last_cast = screen.session.combat.cast("preview-hit", "ATK", 1)
    screen.refresh()
    var recent = screen.get_node("Battle/Combat/SkillDock/Recent")
    assert_true("가산 1" in recent.text)
    assert_true("피해 5" in recent.text)

func test_long_forecasts_stay_inside_allocated_rows_at_both_font_scales():
    if not ready_screen(): return
    screen.start_run("STANDARD",42)
    for scale in [100,125]:
        screen.options.font_scale=scale
        screen._apply_font()
        for category in ["ATK","DEF","SUP"]:
            screen.session.selected_category=category
            screen.session.combat.attack_bank=2000000000
            screen.session.combat.eta_us=1000
            screen.session.last_cast={"effect":"ATK_DAMAGE","category":"ATK","stage":6,"power":18,"bank_consumed":2000000000,"damage_applied":160}
            screen.refresh()
            await get_tree().process_frame
            var next=screen.get_node("Battle/Combat/SkillDock/Next")
            var recent=screen.get_node("Battle/Combat/SkillDock/Recent")
            assert_lte(next.position.y+next.size.y,recent.position.y,"Forecast must not push into recent receipt")
            assert_lte(recent.position.y+recent.size.y,140.0,"Recent receipt must remain inside dock")
            assert_lte(next.size.x,540.0)

func test_recent_skill_icon_follows_actual_cast_not_next_selected_category():
    if not ready_screen(): return
    screen.start_run("STANDARD",42)
    var recent=screen.get_node_or_null("Battle/Combat/SkillDock/LastIcon")
    assert_not_null(recent,"Blueprint LastIcon consumer must exist")
    if recent==null: return
    assert_false(recent.visible,"No fabricated previous skill before a cast")
    screen.session.last_cast=screen.session.combat.cast("actual-strike","ATK",1)
    screen.session.selected_category="SUP"
    screen.refresh()
    assert_true(recent.visible)
    assert_eq(recent.texture.region,screen.assets.texture("R1-ICONS","strike").region)
    assert_eq(screen.get_node("Battle/Combat/SkillDock/NextIcon").texture.region,screen.assets.texture("R1-ICONS","recover").region)
    assert_false(recent.get_rect().intersects(screen.get_node("Battle/Combat/SkillDock/NextIcon").get_rect()))
func test_main_briefing_and_distinct_retry_identity():
    if not ready_screen(): return
    assert_eq(screen.page,"main")
    screen.get_node("Main/NewRun").pressed.emit()
    if screen.get_node("OverwriteDialog").visible: screen.get_node("OverwriteDialog").confirmed.emit()
    assert_eq(screen.page,"briefing")
    assert_null(screen.session)
    screen.get_node("Briefing/Deploy").pressed.emit()
    assert_eq(screen.page,"battle")
    var id = screen.session.run_id
    var seed = screen.run_seed
    screen.retry_run()
    assert_ne(screen.session.run_id,id)
    assert_eq(screen.run_seed,seed)
func test_exact_bounds_single_workspace_and_full_shape_previews():
    if not ready_screen(): return
    screen.start_run("STANDARD",9112026)
    assert_eq(screen.get_node("Battle/Puzzle").get_rect(),Rect2(16,16,616,688))
    assert_eq(screen.get_node("Battle/Combat").get_rect(),Rect2(648,16,616,688))
    assert_true(screen.get_node("Battle/Puzzle/Line").visible)
    assert_false(screen.get_node("Battle/Puzzle/Chain").visible)
    assert_eq(screen.get_node("Battle/Puzzle/Line/Cells").get_child_count(),200)
    assert_eq(screen.get_node("Battle/Puzzle/Line/Previews").get_child_count(),6)
    screen.dispatch("switch")
    assert_false(screen.get_node("Battle/Puzzle/Line").visible)
    assert_true(screen.get_node("Battle/Puzzle/Chain").visible)
func test_assets_roles_regions_clip_and_alpha():
    if not ready_screen(): return
    var boss = screen.assets.texture("R2-BOSS","idle")
    assert_eq(boss.region,Rect2(0,0,651,460))
    assert_true(boss.filter_clip)
    var image = boss.atlas.get_image()
    assert_not_null(image)
    if image != null:
        assert_eq(image.get_format(),Image.FORMAT_RGBA8)
        assert_eq(image.get_pixel(0,0).a,0.0)
        assert_gt(image.get_pixel(325,200).a,0.0)
    assert_eq(screen.assets.texture("R1-PORTRAIT","neutral").region,Rect2(2,2,623,623))
    assert_eq(screen.get_node("Battle/Combat/PlayerHUD/Portrait").size,Vector2(96,96))
    assert_same(screen.assets.texture("R2-TILES","attack"),screen.assets.texture("R2-TILES","attack"))
    assert_eq(screen.assets.errors,[])
func test_category_snapshot_readonly_details_and_pause_pose():
    if not ready_screen(): return
    screen.start_run("STANDARD",1)
    screen.session.setup_training("CHAIN",true)
    screen.refresh()
    screen.dispatch("category",{"category":"DEF"})
    screen.dispatch("chain_swap",{"from":[4,5],"to":[5,5]})
    assert_false(screen.dispatch("category",{"category":"SUP"}).success)
    assert_eq(screen.session.selected_category,"DEF")
    screen.open_details(6)
    var before = screen.session.chain.next_wave_remaining_us
    var pose_time = screen.pose_time_us
    screen.advance_seconds(2.0)
    assert_eq(screen.session.chain.next_wave_remaining_us,before)
    assert_eq(screen.pose_time_us,pose_time)
    screen.close_details()
    assert_false(screen.session.combat.paused)
    screen.pause_game()
    screen.open_details(2)
    screen.close_details()
    assert_true(screen.session.combat.paused)
    assert_false(screen.dispatch("cast").success)
func test_fractional_clock_partition_and_held_input_echo():
    if not ready_screen(): return
    screen.start_run("STANDARD",2)
    for i in range(10): screen.advance_seconds(0.0000004)
    assert_eq(screen.session.elapsed_simulation_us,4)
    var event = InputEventKey.new()
    event.keycode = KEY_RIGHT
    event.pressed = true
    event.echo = true
    var x = screen.session.line.active.origin.x
    screen._input(event)
    assert_eq(screen.session.line.active.origin.x,x)
func test_save_continue_clears_input_and_preserves_identity():
    if not ready_screen(): return
    screen.start_run("STANDARD",123)
    var id = screen.session.run_id
    screen.advance_seconds(0.25)
    assert_true(screen.checkpoint().success)
    screen.chain_selected = Vector2i(2,2)
    screen.held_inputs["left"] = 100
    screen.continue_run()
    assert_eq(screen.session.run_id,id)
    assert_true(screen.session.combat.paused)
    assert_eq(screen.chain_selected,Vector2i(-1,-1))
    assert_true(screen.held_inputs.is_empty())
func test_practice_stages_and_disconnect_pause():
    if not ready_screen(): return
    screen.begin_practice(1)
    assert_true(screen.session.training_boss_frozen)
    screen.begin_practice(2)
    assert_true(screen.session.training_boss_frozen)
    screen.begin_practice(3)
    assert_false(screen.session.training_boss_frozen)
    screen.device_connection_changed(0,false)
    assert_true(screen.session.combat.paused)
    assert_true(screen.get_node("PausePanel/Status").text.contains("연결"))

func test_input_das_arr_and_pause_reset_use_single_elapsed_owner():
    if not ready_screen(): return
    var helper = load("res://src/replanned_r2/r2_input.gd").new()
    helper.configure(screen.disk.default_options())
    var event = InputEventKey.new()
    event.keycode=KEY_LEFT
    event.pressed=true
    assert_eq(helper.event_intent(event).action,"left")
    assert_eq(helper.next_repeat_us(),150000)
    assert_eq(helper.elapse(149999),[])
    assert_eq(helper.elapse(1),["left"])
    assert_eq(helper.next_repeat_us(),50000)
    assert_eq(helper.elapse(50000),["left"])
    event.echo=true
    assert_eq(helper.event_intent(event),{})
    helper.clear()
    assert_eq(helper.held,{})
func test_options_cancel_reverts_and_font_scale_does_not_resize_boards():
    if not ready_screen(): return
    screen.start_run("STANDARD",1)
    var original=screen.options.duplicate(true)
    screen.open_options()
    screen.options_draft.font_scale=125
    screen.options_draft.reduced_motion=not original.reduced_motion
    screen.close_options(false)
    assert_eq(screen.options,original)
    assert_false(screen.session.combat.paused)
    screen.open_options()
    screen.options_draft.font_scale=125
    screen.close_options(true)
    assert_eq(int(screen.options.font_scale),125)
    assert_eq(screen.get_node("Battle/Puzzle").size,Vector2(616,688))
    screen.pause_game()
    screen.open_options()
    screen.close_options(false)
    assert_true(screen.session.combat.paused)
func test_saved_remaps_refresh_control_guidance_cancel_and_scene_reentry():
    if not ready_screen(): return
    screen.start_run("STANDARD",41)
    var gameplay_before=screen.session.snapshot()
    screen.open_options()
    for remap in [["hard_drop",KEY_V],["switch",KEY_B],["def",KEY_N],["pause",KEY_M]]:
        var result=screen.Disk.remap(screen.options_draft,"keyboard_mapping",remap[0],remap[1])
        assert_true(result.success,"Unused Task 5 fixture key must remap "+remap[0])
    screen.close_options(true)
    assert_eq(screen.session.snapshot(),gameplay_before,"Saving presentation mappings cannot mutate combat or puzzle state")
    var line: Label=screen.get_node("Battle/Puzzle/Line/Input")
    var chain: Label=screen.get_node("Battle/Puzzle/Chain/Role")
    var pause: Button=screen.get_node("Battle/Puzzle/Pause")
    assert_true(line.text.begins_with("키 "))
    assert_false(line.text.contains("Space"))
    assert_string_contains(chain.text,"키 B")
    assert_false(chain.text.contains("Tab"))
    assert_string_contains(pause.text,"키 M")
    assert_false(pause.text.contains("Esc"))
    assert_string_contains(line.tooltip_text,"키보드")
    assert_string_contains(line.tooltip_text,"게임패드")
    screen.practice_stage=1
    assert_string_contains(screen._practice_instruction(),"키 V / 패드 A")
    screen.practice_stage=3
    var defense_instruction=screen._practice_instruction()
    for expected in ["키 B / 패드 LB","키 N / 패드 RB"]: assert_string_contains(defense_instruction,expected)
    screen.practice_stage=4
    var pause_instruction=screen._practice_instruction()
    for expected in ["키 B / 패드 LB","키 M / 패드 Start"]: assert_string_contains(pause_instruction,expected)
    screen.practice_stage=0
    var saved_guidance=[line.text,line.tooltip_text,chain.text,chain.tooltip_text,pause.text,pause.tooltip_text]
    screen.open_options()
    assert_true(screen.Disk.remap(screen.options_draft,"keyboard_mapping","hard_drop",KEY_Q).success)
    screen.close_options(false)
    assert_eq([line.text,line.tooltip_text,chain.text,chain.tooltip_text,pause.text,pause.tooltip_text],saved_guidance,"Canceled draft cannot leak into guidance")
    var pad_event=InputEventJoypadButton.new()
    pad_event.button_index=JOY_BUTTON_START
    pad_event.pressed=true
    assert_eq(screen.inputs.event_intent(pad_event).action,"pause")
    assert_true(screen.has_method("_refresh_control_guidance"))
    if not screen.has_method("_refresh_control_guidance"): return
    screen._refresh_control_guidance()
    assert_true(line.text.begins_with("패드 "))
    assert_string_contains(chain.text,"패드 LB")
    assert_string_contains(pause.text,"패드 Start")
    assert_eq(screen.session.snapshot(),gameplay_before,"Reading another device guide cannot mutate gameplay")
    var reentry=load("res://scenes/replanned_r2/main.tscn").instantiate()
    reentry.save_path="user://replanned_r2_tests/screen/reentry-save.json"
    reentry.options_path=screen.options_path
    add_child_autofree(reentry)
    reentry.set_process(false)
    assert_string_contains(reentry.get_node("Battle/Puzzle/Line/Input").text,"V 낙하")
    assert_string_contains(reentry.get_node("Battle/Puzzle/Chain/Role").text,"키 B")
    assert_string_contains(reentry.get_node("Battle/Puzzle/Pause").text,"키 M")

func test_practice_pause_keeps_ordinary_checkpoint_without_writing_practice():
    if not ready_screen(): return
    screen.start_run("STANDARD",42)
    assert_true(screen.checkpoint().success)
    var ordinary_id=screen.session.run_id
    var ordinary_hash=FileAccess.get_sha256(screen.save_path)
    assert_false(ordinary_hash.is_empty())
    screen.pause_game()
    assert_eq(screen.get_node("PausePanel/Main").text,"체크포인트 보존 후 메인")
    assert_eq(screen.get_node("PausePanel/Checkpoint").text,"현재 전체 상태를 저장할 수 있습니다.")
    screen.resume_game()
    screen.begin_practice(4)
    screen.close_details()
    screen.pause_game()
    assert_string_contains(screen.get_node("PausePanel/Main").text,"연습 저장 안 함")
    assert_string_contains(screen.get_node("PausePanel/Main").text,"일반 체크포인트 유지")
    var practice_status=screen.get_node("PausePanel/Checkpoint").text
    assert_string_contains(practice_status,"연습 상태는 저장하지 않습니다")
    assert_string_contains(practice_status,"기존 일반 체크포인트는 그대로 유지됩니다")
    screen.get_node("PausePanel/Main").pressed.emit()
    assert_eq(screen.page,"main")
    assert_eq(FileAccess.get_sha256(screen.save_path),ordinary_hash,"Leaving Practice must not rewrite the ordinary save")
    var retained=screen.disk.load_checkpoint()
    assert_true(retained.success)
    assert_eq(retained.snapshot.identity.run_id,ordinary_id)

func test_practice_guidance_fits_above_start_button_at_125_percent():
    if not ready_screen(): return
    screen.options.font_scale=125
    screen._apply_font()
    screen.open_options()
    assert_true(screen.Disk.remap(screen.options_draft,"keyboard_mapping","hard_drop",KEY_SCROLLLOCK).success)
    assert_true(screen.Disk.remap(screen.options_draft,"keyboard_mapping","switch",KEY_R).success)
    assert_true(screen.Disk.remap(screen.options_draft,"keyboard_mapping","def",KEY_F).success)
    assert_true(screen.Disk.remap(screen.options_draft,"keyboard_mapping","pause",KEY_CAPSLOCK).success)
    screen.close_options(true)
    var safety_text={1:"이 단계는 보스 시계만 멈춥니다",2:"이 단계는 보스 시계만 멈춥니다",3:"학습 시작 뒤 보스 시계는 정상 진행합니다",4:"보스 시계는 정상 진행합니다"}
    for stage in [1,2,3,4]:
        screen.begin_practice(stage)
        await get_tree().process_frame
        var panel: Control=screen.get_node("DetailsPanel")
        var body: Label=screen.get_node("DetailsPanel/Body")
        var start: Button=screen.get_node("DetailsPanel/Close")
        assert_string_contains(body.text,safety_text[stage],"Practice keeps its clock-safety guidance")
        assert_eq(body.get_theme_font_size("font_size"),29,"Practice keeps the selected 125% text scale")
        assert_lte(body.position.y+body.get_minimum_size().y+16.0,start.position.y,"Practice %d guidance needs a 16px clear gap above Start at 125%%"%stage)
        var panel_content=Rect2(Vector2.ZERO,panel.size)
        assert_true(panel_content.encloses(body.get_rect()))
        assert_true(panel_content.encloses(start.get_rect()))
    assert_string_contains(screen._practice_instruction(),"CapsLock","Long mapped key names stay in the fitted guidance")

func test_long_pause_remap_stays_inside_fixed_left_button_at_125_percent():
    if not ready_screen(): return
    screen.options.font_scale=125
    screen._apply_font()
    for keycode in [KEY_SCROLLLOCK,KEY_CAPSLOCK]:
        screen.open_options()
        assert_true(screen.Disk.remap(screen.options_draft,"keyboard_mapping","pause",keycode).success)
        screen.close_options(true)
        await get_tree().process_frame
        var pause: Button=screen.get_node("Battle/Puzzle/Pause")
        var puzzle: Control=screen.get_node("Battle/Puzzle")
        var combat: Control=screen.get_node("Battle/Combat")
        assert_eq(pause.size.x,130.0,"Pause keeps its fixed reviewed button width")
        assert_lte(pause.get_global_rect().end.x,puzzle.get_global_rect().end.x,"Pause button stays inside the left pane")
        assert_lte(pause.get_global_rect().end.x,combat.get_global_rect().position.x,"Pause button cannot enter the right pane")
        assert_string_contains(pause.tooltip_text,OS.get_keycode_string(keycode),"Tooltip retains the complete actual pause mapping")
        var visible_text_fits := pause.get_combined_minimum_size().x<=pause.size.x
        var bounded_ellipsis := pause.clip_text and pause.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS
        assert_true(visible_text_fits or bounded_ellipsis,"Long pause labels need a bounded visible label or ellipsis")
        assert_string_contains(pause.text,"키","Visible guidance retains keyboard distinction")

func test_key_poses_follow_actual_event_clock_and_pause():
    if not ready_screen(): return
    screen.start_run("STANDARD",8)
    screen.dispatch("switch")
    screen.advance_seconds(9.5)
    assert_eq(screen.boss_pose,"anticipation")
    screen.advance_seconds(0.5)
    assert_eq(screen.boss_pose,"impact")
    var hp=screen.session.combat.hp
    screen.pause_game()
    var time=screen.pose_time_us
    screen.advance_seconds(2.0)
    assert_eq(screen.boss_pose,"impact")
    assert_eq(screen.pose_time_us,time)
    assert_eq(screen.session.combat.hp,hp)
    screen.resume_game()
    screen.advance_seconds(0.12)
    assert_eq(screen.boss_pose,"recovery")
    screen.advance_seconds(0.24)
    assert_eq(screen.boss_pose,"idle")
func test_midcascade_exit_preserves_disk_checkpoint_and_continuation_pause():
    if not ready_screen(): return
    screen.start_run("STANDARD",25)
    var saved_id=screen.session.run_id
    screen.session.setup_training("CHAIN",true)
    screen.dispatch("chain_swap",{"from":[4,5],"to":[5,5]})
    assert_false(screen.checkpoint().success)
    screen.pause_game()
    assert_true(screen.get_node("PausePanel/Main").text.contains("직전"))
    screen.get_node("PausePanel/Main").pressed.emit()
    assert_eq(screen.page,"main")
    screen.continue_run()
    assert_eq(screen.session.run_id,saved_id)
    assert_false(screen.session.chain.resolving)
    assert_true(screen.session.combat.paused)
func test_practice_uses_actual_commands_and_metrics_to_unlock_next():
    if not ready_screen(): return
    screen.begin_practice(1)
    screen.close_details()
    assert_false(screen.get_node("Battle/PracticeNext").disabled == false)
    for i in range(3): screen.dispatch("move",{"dx":1})
    screen.dispatch("hard_drop")
    assert_eq(int(screen.session.metrics.line_clears),1)
    assert_eq(screen.session.combat.attack_bank,4)
    assert_eq(screen.session.combat.armor,2)
    assert_eq(screen.session.combat.hp,82)
    assert_false(screen.get_node("Battle/PracticeNext").disabled)
    screen.get_node("Battle/PracticeNext").pressed.emit()
    assert_eq(screen.practice_stage,2)
    screen.close_details()
    screen._click_cell(Vector2i(4,5))
    screen._click_cell(Vector2i(5,5))
    screen.advance_seconds(0.6)
    assert_eq(int(screen.session.metrics.casts),2)
    assert_false(screen.get_node("Battle/PracticeNext").disabled)

func test_focus_loss_during_details_must_not_resume_on_close():
    if not ready_screen(): return
    screen.start_run("STANDARD",13)
    screen.open_details(3)
    screen._focus_lost()
    screen.close_details()
    assert_true(screen.session.combat.paused,"External focus loss remains paused after closing details")
func test_terminal_checkpoint_reopens_actual_result_not_frozen_battle():
    if not ready_screen(): return
    screen.start_run("STANDARD",7)
    screen.dispatch("switch")
    screen.advance_seconds(100.0)
    assert_eq(screen.page,"result")
    assert_eq(screen.session.combat.outcome,"DEFEAT")
    var id=screen.session.run_id
    screen.return_to_main()
    screen.continue_run()
    assert_eq(screen.session.run_id,id)
    assert_eq(screen.page,"result","Terminal complete checkpoint must return to the actual result")

func _send_accept(pad: bool):
    var event: InputEvent
    if pad:
        event=InputEventJoypadButton.new()
        event.button_index=JOY_BUTTON_A
    else:
        event=InputEventKey.new()
        event.keycode=KEY_ENTER
    event.pressed=true
    Input.parse_input_event(event)
    await get_tree().process_frame
    event=event.duplicate()
    event.pressed=false
    Input.parse_input_event(event)
    await get_tree().process_frame

func test_modal_external_pause_keeps_native_accept_inside_top_panel():
    if not ready_screen(): return
    for modal in ["DetailsPanel","Options"]:
        for pad in [false,true]:
            screen.start_run("STANDARD",14)
            if modal=="DetailsPanel": screen.open_details(2)
            else: screen.open_options()
            if pad: screen.device_connection_changed(0,false)
            else: screen._focus_lost()
            var panel=screen.get_node(modal)
            var focus=screen.get_viewport().gui_get_focus_owner()
            assert_true(focus!=null and panel.is_ancestor_of(focus),"External pause must keep focus inside the top modal")
            screen.resume_game()
            assert_true(screen.session.combat.paused,"Resume cannot bypass a visible details/settings panel")
            await _send_accept(pad)
            assert_true(screen.session.combat.paused,"Enter/pad A after external pause must not resume hidden controls")
            if panel.visible:
                if modal=="DetailsPanel": screen.close_details()
                else: screen.close_options(false)
            screen.resume_game()

func test_modal_background_click_and_nested_open_cannot_change_pause_owner():
    if not ready_screen(): return
    screen.begin_practice(1)
    var original=screen.get_node("DetailsPanel/Body").text
    var event=InputEventMouseButton.new()
    event.button_index=MOUSE_BUTTON_LEFT
    event.position=Vector2(551,42)
    event.global_position=event.position
    event.pressed=true
    Input.parse_input_event(event)
    await get_tree().process_frame
    event=event.duplicate()
    event.pressed=false
    Input.parse_input_event(event)
    await get_tree().process_frame
    assert_false(screen.get_node("PausePanel").visible,"Background Pause must not open behind teaching details")
    screen.get_node("Battle/Combat/SkillDock/Tier6").pressed.emit()
    screen.open_options()
    assert_false(screen.get_node("Options").visible,"A details modal rejects a second settings modal")
    assert_eq(screen.get_node("DetailsPanel/Body").text,original,"A background Tier button cannot replace teaching content")
    var shield=screen.get_node_or_null("ModalShield")
    assert_not_null(shield,"Full-screen pointer boundary required")
    if shield!=null:
        assert_true(shield.visible)
        assert_eq(shield.mouse_filter,Control.MOUSE_FILTER_STOP)
    screen.close_details()
    assert_false(screen.session.combat.paused,"Blocked background events do not change the original resume policy")

func test_terminal_save_failure_preserves_result_until_retry_succeeds():
    if not ready_screen(): return
    for point in ["rename","backup"]:
        screen.disk.failure_point=""
        screen.start_run("STANDARD",7)
        var id=screen.session.run_id
        screen.dispatch("switch")
        screen.disk.failure_point=point
        screen.advance_seconds(100.0)
        assert_eq(screen.page,"result")
        assert_eq(screen.session.combat.outcome,"DEFEAT")
        var failure=screen.get_node_or_null("SaveFailurePanel")
        assert_not_null(failure,"Failed terminal save must have recovery UI")
        if failure==null: return
        assert_true(failure.visible)
        assert_true(failure.get_node("Status").text.contains("저장"))
        screen.return_to_main()
        screen.retry_run()
        screen.continue_run()
        assert_eq(screen.page,"result")
        assert_eq(screen.session.run_id,id,"Failure cannot silently discard the actual result")
        screen.disk.failure_point=""
        failure.get_node("RetrySave").pressed.emit()
        assert_false(failure.visible)
        screen.return_to_main()
        screen.continue_run()
        assert_eq(screen.page,"result")
        assert_eq(screen.session.run_id,id)
        assert_eq(screen.session.combat.outcome,"DEFEAT")

func test_start_save_failure_preserves_new_run_or_explicit_previous_choice():
    if not ready_screen(): return
    for point in ["rename","backup"]:
        screen.disk.failure_point=""
        screen.start_run("STANDARD",21)
        var previous=screen.session.run_id
        screen.disk.failure_point=point
        screen.start_run("STANDARD",22)
        var new_id=screen.session.run_id
        var failure=screen.get_node_or_null("SaveFailurePanel")
        assert_not_null(failure,"Failed new-run save must have recovery UI")
        if failure==null: return
        assert_true(failure.visible)
        assert_true(screen.session.combat.paused)
        screen.continue_run()
        assert_eq(screen.session.run_id,new_id)
        failure.get_node("PreviousRecord").pressed.emit()
        assert_eq(screen.page,"main")
        screen.disk.failure_point=""
        screen.continue_run()
        assert_eq(screen.session.run_id,previous)

func test_practice_footer_regions_do_not_overlap_chain_board_or_each_other():
    if not ready_screen(): return
    for scale in [100,125]:
        screen.options.font_scale=scale
        screen._apply_font()
        screen.begin_practice(2)
        screen.close_details()
        await get_tree().process_frame
        var board=screen.get_node("Battle/Puzzle/Chain/Cells").get_global_rect()
        var state=screen.get_node("Battle/Puzzle/Chain/State").get_global_rect()
        var help=screen.get_node("Battle/Puzzle/Chain/Role").get_global_rect()
        var next=screen.get_node("Battle/PracticeNext").get_global_rect()
        var retry=screen.get_node("Battle/PracticeRetry").get_global_rect()
        var puzzle=screen.get_node("Battle/Puzzle").get_global_rect()
        assert_eq(board.size,Vector2(512,512),"Keep64px CHAIN tiles")
        assert_false(board.intersects(state))
        assert_false(state.intersects(help))
        assert_false(help.intersects(next),"Help must end before the practice button row")
        assert_false(help.intersects(retry))
        assert_false(next.intersects(retry))
        for rect in [state,help,next,retry]:
            assert_true(puzzle.encloses(rect),"Footer stays within the existing puzzle half")
        screen.begin_practice(1)
        screen.close_details()
        var line=screen.get_node("Battle/Puzzle/Line/Cells").get_global_rect()
        var previews=screen.get_node("Battle/Puzzle/Line/Previews").get_global_rect()
        for path in ["Battle/PracticeNext","Battle/PracticeRetry","Battle/PracticeStatus"]:
            var rect=screen.get_node(path).get_global_rect()
            assert_false(rect.intersects(line))
            assert_false(rect.intersects(previews))

func _send_pad(button: int):
    var event=InputEventJoypadButton.new()
    event.button_index=button
    event.pressed=true
    Input.parse_input_event(event)
    await get_tree().process_frame
    event=event.duplicate()
    event.pressed=false
    Input.parse_input_event(event)
    await get_tree().process_frame

func test_pad_accept_activates_main_and_only_top_modal_without_gameplay_leak():
    if not ready_screen(): return
    screen.get_node("Main/Practice").grab_focus()
    screen.get_node("Main/Practice").hide()
    await _send_pad(JOY_BUTTON_A)
    assert_eq(screen.page,"main","Hidden focus cannot activate")
    screen.get_node("Main/Practice").show()
    screen.get_node("Main/Practice").grab_focus()
    await _send_pad(JOY_BUTTON_A)
    assert_eq(screen.page,"battle","Native pad accept must activate Main/Practice")
    assert_true(screen.get_node("DetailsPanel").visible)
    if screen.session==null: return
    screen._focus_lost()
    await _send_pad(JOY_BUTTON_A)
    assert_false(screen.get_node("DetailsPanel").visible,"Accept must actually close the top details panel")
    assert_true(screen.session.combat.paused,"External pause stays in force")
    var locks=screen.session.line.lock_sequence
    await _send_pad(JOY_BUTTON_A)
    assert_false(screen.session.combat.paused,"Next accept activates Pause/Resume")
    assert_eq(screen.session.line.lock_sequence,locks,"Menu accept cannot also hard-drop")
    screen.pause_game()
    screen.get_node("PausePanel/Resume").disabled=true
    await _send_pad(JOY_BUTTON_A)
    assert_true(screen.session.combat.paused,"Disabled focus cannot activate")
    screen.get_node("PausePanel/Resume").disabled=false
    screen.open_options()
    await _send_pad(JOY_BUTTON_B)
    assert_false(screen.get_node("Options").visible,"Pad cancel closes Options without saving")
    assert_true(screen.session.combat.paused)

func test_pad_native_dropdown_and_overwrite_confirm_cancel():
    if not ready_screen(): return
    screen.open_options()
    screen.get_node("Options/Device").grab_focus()
    await _send_pad(JOY_BUTTON_A)
    var popup=screen.get_node("Options/Device").get_popup()
    assert_true(popup.visible,"Native OptionButton opens with pad accept")
    await _send_pad(JOY_BUTTON_B)
    assert_false(popup.visible,"Native popup cancels with pad B")
    assert_true(screen.get_node("Options").visible,"Popup cancel must not also dismiss its parent")
    await _send_pad(JOY_BUTTON_B)
    assert_false(screen.get_node("Options").visible)
    screen.close_options(false)
    screen.start_run("STANDARD",321)
    screen.return_to_main()
    screen.request_new_run()
    assert_true(screen.get_node("OverwriteDialog").visible)
    screen.get_node("OverwriteDialog").get_cancel_button().grab_focus()
    await _send_pad(JOY_BUTTON_A)
    assert_false(screen.get_node("OverwriteDialog").visible,"Pad accept activates dialog Cancel")
    assert_eq(screen.page,"main")
    screen.get_node("OverwriteDialog").hide()
    screen.request_new_run()
    await _send_pad(JOY_BUTTON_B)
    assert_false(screen.get_node("OverwriteDialog").visible,"Pad B cancels native confirmation")
    assert_eq(screen.page,"main")
    screen.get_node("OverwriteDialog").hide()
    screen.request_new_run()
    screen.get_node("OverwriteDialog").get_ok_button().grab_focus()
    await _send_pad(JOY_BUTTON_A)
    assert_eq(screen.page,"briefing","Pad accept confirms native dialog")
    screen.get_node("OverwriteDialog").hide()

func test_scoped_menu_pad_bindings_leave_existing_events_and_do_not_duplicate():
    if not ready_screen(): return
    var existing=InputEventJoypadButton.new()
    existing.button_index=JOY_BUTTON_PADDLE1
    InputMap.action_add_event("ui_accept",existing)
    var menu_count=InputMap.action_get_events("ui_accept").size()
    for i in range(3):
        screen.open_options()
        screen.close_options(false)
    assert_eq(InputMap.action_get_events("ui_accept").size(),menu_count,"Repeated modal entry cannot duplicate mappings")
    screen.start_run("STANDARD",32)
    assert_false(InputMap.event_is_action(_pad_event(JOY_BUTTON_A),"ui_accept"),"R2 mapping must be absent during gameplay")
    assert_true(InputMap.action_has_event("ui_accept",existing),"Other owners' mappings survive")
    screen.pause_game()
    assert_true(InputMap.event_is_action(_pad_event(JOY_BUTTON_A),"ui_accept"))
    screen.open_options()
    screen.options_draft.gamepad_mapping.accept=JOY_BUTTON_MISC1
    screen.close_options(true)
    assert_false(InputMap.event_is_action(_pad_event(JOY_BUTTON_A),"ui_accept"))
    assert_true(InputMap.event_is_action(_pad_event(JOY_BUTTON_MISC1),"ui_accept"),"Saved remap replaces only owned temporary binding")
    screen.open_options()
    screen.options_draft.gamepad_mapping.accept=JOY_BUTTON_A
    screen.close_options(false)
    assert_true(InputMap.event_is_action(_pad_event(JOY_BUTTON_MISC1),"ui_accept"),"Cancelled remap keeps saved mapping")
    screen.disk.save_options(screen.Disk.default_options())
    screen.queue_free()
    await get_tree().process_frame
    assert_false(InputMap.event_is_action(_pad_event(JOY_BUTTON_MISC1),"ui_accept"),"Scene exit releases owned events")
    assert_true(InputMap.action_has_event("ui_accept",existing))
    InputMap.action_erase_event("ui_accept",existing)
    screen=null

func test_gameplay_pad_actions_stay_single_and_menu_cancel_releases_action():
    if not ready_screen(): return
    screen.start_run("STANDARD",554)
    screen.pause_game()
    await _send_pad(JOY_BUTTON_B)
    assert_false(screen.session.combat.paused)
    assert_true(screen.session.line.hold_available,"Pause cancel cannot also trigger gameplay HOLD")
    assert_false(Input.is_action_pressed("ui_cancel"),"Removing temporary bindings must not leave a held native action")
    await _send_pad(JOY_BUTTON_B)
    assert_false(screen.session.line.hold_available,"Gameplay B still performs HOLD")
    await _send_pad(JOY_BUTTON_A)
    assert_eq(screen.session.line.lock_sequence,1,"Gameplay A performs exactly one hard drop")
    assert_false(InputMap.event_is_action(_pad_event(JOY_BUTTON_A),"ui_accept"))
    screen.pause_game()
    await _send_pad(JOY_BUTTON_A)
    assert_eq(screen.session.line.lock_sequence,1,"Resume A must not also drop the next piece")
    assert_false(Input.is_action_pressed("ui_accept"))

func test_menu_mapping_scene_reentry_preserves_preexisting_matching_event():
    if not ready_screen(): return
    screen.start_run("STANDARD",123)
    var existing=_pad_event(JOY_BUTTON_A)
    existing.device=-1
    InputMap.action_add_event("ui_accept",existing)
    var baseline_count=InputMap.action_get_events("ui_accept").size()
    screen.queue_free()
    await get_tree().process_frame
    for i in range(2):
        screen=load("res://scenes/replanned_r2/main.tscn").instantiate()
        screen.save_path="user://replanned_r2_tests/screen/save.json"
        screen.options_path="user://replanned_r2_tests/screen/options.json"
        add_child_autofree(screen)
        screen.set_process(false)
        assert_eq(InputMap.action_get_events("ui_accept").size(),baseline_count,"Reentry does not duplicate another owner's matching event")
        screen.get_node("Main/Practice").grab_focus()
        await _send_pad(JOY_BUTTON_A)
        assert_eq(screen.page,"battle")
        screen.queue_free()
        await get_tree().process_frame
        assert_true(InputMap.action_has_event("ui_accept",existing),"Exit cannot remove a preexisting matching event")
        assert_eq(InputMap.action_get_events("ui_accept").size(),baseline_count)
    InputMap.action_erase_event("ui_accept",existing)
    screen=null

func _pad_event(button: int) -> InputEventJoypadButton:
    var event=InputEventJoypadButton.new()
    event.button_index=button
    return event

func test_def_preview_uses_actual_target_state_before_cast_and_keeps_receipt():
    if not ready_screen(): return
    screen.start_run("STANDARD",17)
    screen.dispatch("category",{"category":"DEF"})
    var preview=screen.get_node("Battle/Combat/SkillDock/Next")
    assert_string_contains(preview.text,"대상 있음")
    assert_string_contains(preview.text,"발동 시")
    var before=screen.session.combat.snapshot()
    screen.refresh()
    assert_eq(screen.session.combat.snapshot(),before,"DEF forecast must be read-only")
    assert_eq(screen.session.combat.cast("preview-damage","DEF",1).effect,"DEF_WARD")
    screen.session.combat.tick(9999000)
    screen.refresh()
    assert_string_contains(preview.text,"행동 확정")
    var receipt=screen.session.combat.cast("preview-commit","DEF",1)
    assert_eq(receipt.effect,"DEF_NO_TARGET")
    screen.session.last_cast=receipt
    screen.refresh()
    assert_string_contains(screen.get_node("Battle/Combat/SkillDock/Recent").text,"행동 확정")
    screen.start_run("STANDARD",18)
    screen.dispatch("category",{"category":"DEF"})
    for duration in [10000000,14000000,10000000]: screen.session.combat.tick(duration)
    screen.refresh()
    assert_string_contains(preview.text,"휴식")
    receipt=screen.session.combat.cast("preview-rest","DEF",1)
    assert_eq(receipt.reason,"NO_DAMAGE_ACTION")
    screen.session.last_cast=receipt
    screen.refresh()
    assert_string_contains(screen.get_node("Battle/Combat/SkillDock/Recent").text,"휴식")

func test_line_time_receipt_survives_hard_drop_natural_lock_and_later_commands():
    if not ready_screen(): return
    var label=screen.get_node_or_null("Battle/Puzzle/Line/Receipt")
    assert_not_null(label,"Actual LINE receipt must remain visible in the active workspace")
    if label==null: return
    for scenario in ["applied","cap","committed","finished"]:
        screen.begin_practice(1)
        screen.close_details()
        for i in range(3): screen.dispatch("move",{"dx":1})
        if scenario=="cap": screen.session.combat.extension_us=2750000
        if scenario=="committed": screen.session.combat.eta_us=1000
        if scenario=="finished":
            screen.session.training_boss_frozen=false
            screen.session.combat.eta_us=500000
            while not screen.session.line.grounded(): screen.dispatch("soft_drop")
            screen.advance_seconds(0.5)
        else: screen.dispatch("hard_drop")
        assert_true(label.is_visible_in_tree())
        assert_string_contains(label.text,"시계 2")
        var applied={"applied":"0.500","cap":"0.250","committed":"0.000","finished":"0.000"}[scenario]
        var unapplied={"applied":"0.000","cap":"0.250","committed":"0.500","finished":"0.500"}[scenario]
        assert_string_contains(label.text,"적용 +"+applied+"초")
        assert_string_contains(label.text,"미적용 "+unapplied+"초")
        assert_string_contains(label.text,{"applied":"전체 적용","cap":"상한 도달","committed":"행동 확정","finished":"행동 종료"}[scenario])
        var text_before=label.text
        screen.dispatch("move",{"dx":1})
        screen.refresh()
        assert_eq(label.text,text_before,"Successful later commands cannot discard the reward receipt")
    screen.start_run("STANDARD",19)
    assert_string_contains(label.text,"아직 없음")

func test_receipt_and_def_preview_fit_existing_regions_at_125_percent():
    if not ready_screen(): return
    screen.options.font_scale=125
    screen._apply_font()
    screen.begin_practice(1)
    screen.close_details()
    for i in range(3): screen.dispatch("move",{"dx":1})
    screen.dispatch("hard_drop")
    var label=screen.get_node_or_null("Battle/Puzzle/Line/Receipt")
    assert_not_null(label)
    if label==null: return
    await get_tree().process_frame
    var rect=label.get_global_rect()
    for path in ["Battle/Puzzle/Line/Cells","Battle/Puzzle/Line/Previews","Battle/Puzzle/Line/Input","Battle/PracticeStatus","Battle/PracticeNext","Battle/PracticeRetry"]:
        assert_false(rect.intersects(screen.get_node(path).get_global_rect()),path)
    assert_true(screen.get_node("Battle/Puzzle").get_global_rect().encloses(rect))
    screen.dispatch("category",{"category":"DEF"})
    var next_label=screen.get_node("Battle/Combat/SkillDock/Next")
    assert_lte(next_label.get_theme_font("font").get_string_size(next_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,next_label.get_theme_font_size("font_size")).x,next_label.size.x)
    for duration in [10000000,14000000,10000000]: screen.session.combat.tick(duration)
    screen.refresh()
    await get_tree().process_frame
    assert_false(next_label.get_global_rect().intersects(screen.get_node("Battle/Combat/SkillDock/Recent").get_global_rect()))
    for path in ["Battle/Combat/SkillDock/Next","Battle/Combat/SkillDock/Recent"]:
        var text_label=screen.get_node(path)
        assert_lte(text_label.get_minimum_size().y,text_label.size.y)
        assert_lte(text_label.get_theme_font("font").get_string_size(text_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,text_label.get_theme_font_size("font_size")).x,text_label.size.x,"One-line DEF preview must fit")

func test_safety_recovery_emits_one_identified_diagnostic_from_real_wave_event():
    if not ready_screen(): return
    assert_true(screen.has_signal("diagnostic_recorded"),"Safety recovery needs an observable diagnostic consumer")
    if not screen.has_signal("diagnostic_recorded"): return
    var records=[]
    screen.diagnostic_recorded.connect(func(record): records.append(record))
    screen.begin_practice(2)
    screen.close_details()
    screen.session.chain.cells=[]
    for y in range(8): screen.session.chain.cells.append("AAAAAAAA")
    screen.session.chain.resolving=true
    screen.session.chain.category_snapshot="SUP"
    screen.session.chain.chain_id=7
    screen.session.chain.wave_index=63
    screen.session.chain.next_wave_remaining_us=300000
    var events=screen.session.tick(300000)
    screen._events(events)
    screen._events(events)
    assert_eq(records.size(),1,"Duplicate delivery cannot double-log recovery")
    if records.size()!=1: return
    assert_eq(records[0].run_id,screen.session.run_id)
    assert_eq(records[0].chain_id,7)
    assert_eq(records[0].wave,64)
    assert_eq(records[0].reason,"MAX_WAVES_REACHED")
    assert_false(screen.session.chain.resolving)
