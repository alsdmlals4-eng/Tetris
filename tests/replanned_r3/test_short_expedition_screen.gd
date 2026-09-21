extends GutTest
func test_playable_entry_routes_to_current_combat():
    var path="res://scenes/replanned_r3/short_expedition.tscn"
    assert_true(FileAccess.file_exists(path),"playable expedition entry")
    if not FileAccess.file_exists(path):return
    var screen=load(path).instantiate()
    add_child_autofree(screen)
    screen.set_process(false)
    screen.disk=load("res://src/replanned_r3/short_expedition_save.gd").new("user://tests/short-screen.json")
    screen.start_run("SWAP","RELAXED",42)
    assert_eq(screen.run.view().phase,"ROUTE")
    screen.launch("outer_breach")
    assert_eq(screen.battle.session.resource_mode,"SWAP")
    assert_true(screen.battle.session.combat.has_method("counter_state"))
    assert_eq(screen.battle.get_node("Puzzle").size.x,screen.battle.get_node("Combat").size.x)
    screen.battle.session.command("pause")
    screen.battle.reduced_motion=true
    screen.battle.assist_ui.sound.volume_db=-80
    assert_true(screen.save_checkpoint().success)
    assert_true(screen.restore_checkpoint().success)
    assert_true(screen.battle.session.combat.paused)
    assert_true(screen.battle.reduced_motion,"restoring within a run preserves reduced motion")
    assert_lt(screen.battle.assist_ui.sound.volume_db,-70.0,"restore must not unmute")
    await get_tree().process_frame

func test_previous_mastery_save_has_explicit_compatible_entry():
    var path="res://scenes/replanned_r3/mastery_legacy.tscn"
    assert_true(FileAccess.file_exists(path))
    if not FileAccess.file_exists(path):return
    var previous=load(path).instantiate()
    add_child_autofree(previous)
    assert_false(previous.use_counter)
    assert_true(previous.use_mastery)
    assert_eq(previous.disk.save_path,"user://mastery_patterns/save.json")
