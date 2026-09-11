extends GutTest
var screen
func before_each():
    if ResourceLoader.exists("res://scenes/replanned_r2/main.tscn"):
        screen = load("res://scenes/replanned_r2/main.tscn").instantiate()
        screen.save_path = "user://replanned_r2_tests/screen/save.json"
        screen.options_path = "user://replanned_r2_tests/screen/options.json"
        add_child_autofree(screen)
        screen.set_process(false)
    else: screen = null
func ready_screen() -> bool:
    assert_not_null(screen,"Separate R2 runnable main entry must exist")
    return screen != null
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
