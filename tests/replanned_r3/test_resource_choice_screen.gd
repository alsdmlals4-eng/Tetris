extends GutTest
const Screen=preload("res://src/replanned_r3/r3_screen.gd")
const Session=preload("res://src/replanned_r3/r3_session.gd")
const Disk=preload("res://src/replanned_r3/r3_save.gd")

func test_preparation_selects_swap_and_locks_it_for_battle():
    var screen=Screen.new()
    screen.disk=Disk.new("user://resource-choice-tests/ui-save.json","user://resource-choice-tests/ui-options.json")
    assert_true(screen.has_method("start_resource_battle"),"resource selection must have a real screen consumer")
    if not screen.has_method("start_resource_battle"):screen.free();return
    screen.show_preparation=true
    screen.preference_path="user://resource-choice-tests/preference.cfg"
    add_child_autofree(screen)
    screen.set_process(false)
    assert_true(screen.preparing)
    assert_false(screen.get_node("Combat/PauseMenu").visible,"preparation must not expose save controls")
    assert_false(screen.save_checkpoint().success,"unstarted default battle must not overwrite a checkpoint")
    var eta=screen.session.combat.eta_us
    screen._process(0.5)
    assert_eq(screen.session.combat.eta_us,eta,"preparation is not combat time")
    screen.start_resource_battle("SWAP")
    screen.set_process(false)
    assert_false(screen.preparing)
    assert_true(screen.get_node("Puzzle/SwapBoard").visible)
    assert_false(screen.get_node("Puzzle/LineBoard").visible)
    assert_false(screen.get_node("Puzzle/ChainBoard").visible)
    var active=screen.session
    screen.start_resource_battle("LINE")
    assert_same(screen.session,active,"cannot restart/replace live combat through selection API")
    screen.dispatch("switch")
    assert_true(screen.get_node("Puzzle/ChainBoard").visible)
    assert_false(screen.get_node("Puzzle/SwapBoard").visible)
    assert_true(screen.get_node("Puzzle/Supply").text.contains("교체"))

func test_screen_click_uses_resource_session_and_pause_blocks_it():
    var screen=Screen.new()
    assert_true(screen.has_method("start_resource_battle"))
    if not screen.has_method("start_resource_battle"):screen.free();return
    screen.show_preparation=true
    screen.preference_path="user://resource-choice-tests/preference.cfg"
    add_child_autofree(screen)
    screen.start_resource_battle("SWAP")
    screen.set_process(false)
    screen.session.command("pause")
    var before=screen.session.swap.export_state()
    screen.select_swap_cell(Vector2i(0,0))
    screen.select_swap_cell(Vector2i(1,0))
    assert_eq(screen.session.swap.export_state(),before)

func test_terminal_can_return_to_selection_without_replacing_live_battle():
    var screen=Screen.new()
    assert_true(screen.has_method("return_to_preparation"))
    if not screen.has_method("return_to_preparation"):screen.free();return
    screen.show_preparation=true
    screen.preference_path="user://resource-choice-tests/preference.cfg"
    add_child_autofree(screen)
    screen.start_resource_battle("LINE")
    screen.set_process(false)
    screen.return_to_preparation()
    assert_false(screen.preparing)
    screen.session.combat.outcome="DEFEAT"
    screen.return_to_preparation()
    assert_true(screen.preparing)
    screen.start_resource_battle("SWAP")
    assert_eq(screen.session.resource_mode,"SWAP")

func test_preparation_load_failure_is_visible_without_starting_combat():
    var screen=Screen.new()
    screen.show_preparation=true
    screen.preference_path="user://resource-choice-tests/preference.cfg"
    screen.disk=Disk.new("user://resource-choice-tests/absent-"+str(Time.get_ticks_usec())+".json")
    add_child_autofree(screen)
    screen.set_process(false)
    assert_false(screen.restore_checkpoint().success)
    assert_true(screen.preparing)
    assert_true(screen.has_node("Preparation/Status"))
    if screen.has_node("Preparation/Status"):
        assert_true(screen.get_node("Preparation/Status").text.contains("불러오지 못했습니다"))
