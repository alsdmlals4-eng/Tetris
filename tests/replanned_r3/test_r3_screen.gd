extends GutTest
const Screen=preload("res://src/replanned_r3/r3_screen.gd")
var screen
func before_each():
    screen=Screen.new()
    add_child_autofree(screen)
    screen.set_process(false)

func test_screen_keeps_one_board_and_readable_combat_regions():
    for path in ["Puzzle","Combat","Combat/SharedTimer","Combat/Current","Combat/Next","Combat/Player","Combat/Skills","Combat/CutIn"]:
        assert_not_null(screen.get_node_or_null(path),path)
    var left=screen.get_node_or_null("Puzzle")
    var right=screen.get_node_or_null("Combat")
    if left!=null and right!=null:
        assert_eq(left.size.x,right.size.x)

func test_switch_uses_finite_pair_supply_and_never_swap_commands():
    assert_true(screen.dispatch("switch").success)
    assert_eq(screen.session.mode,"CHAIN")
    assert_eq(screen.session.supply.pairs,3)
    assert_false(screen.dispatch("chain_swap",{"a":[0,0],"b":[1,0]}).success)
    var line=screen.get_node_or_null("Puzzle/LineBoard")
    var chain=screen.get_node_or_null("Puzzle/ChainBoard")
    if line!=null and chain!=null:
        assert_false(line.visible)
        assert_true(chain.visible)
    else:fail_test("Both board views must exist")

func test_focus_loss_pauses_and_blocks_input_until_explicit_resume():
    screen.focus_lost()
    assert_true(screen.session.combat.paused)
    assert_false(screen.dispatch("switch").success)
    assert_true(screen.dispatch("resume").success)
    assert_false(screen.session.combat.paused)

func test_category_is_selection_only_not_manual_cast():
    var before=screen.session.combat.snapshot()
    assert_true(screen.dispatch("category",{"category":"DEF"}).success)
    assert_eq(screen.session.selected_category,"DEF")
    assert_eq(screen.session.combat.snapshot(),before)
    assert_false(screen.dispatch("cast").success)

func test_focus_loss_does_not_move_line_piece():
    var before=screen.session.line.active_cells().duplicate(true)
    screen.focus_lost()
    assert_eq(screen.session.line.active_cells(),before)

func test_release_never_drops_line_and_releases_chain_s_key():
    var before=screen.session.line.active_cells().duplicate(true)
    var key=InputEventKey.new()
    key.keycode=KEY_DOWN
    key.pressed=false
    screen._unhandled_key_input(key)
    assert_eq(screen.session.line.active_cells(),before)
    screen.dispatch("switch")
    screen.dispatch("soft_drop",{"enabled":true})
    key.keycode=KEY_S
    screen._unhandled_key_input(key)
    assert_false(screen.session.chain.snapshot().soft_drop)

func test_queue_does_not_overlap_either_board():
    for path in ["Puzzle/LineBoard","Puzzle/ChainBoard"]:
        var board=screen.get_node(path)
        assert_lte(board.position.y+board.size.y,screen.get_node("Puzzle/Queue").position.y)

func test_chain_clear_drives_cut_in_and_recent_skill_without_replaying_damage():
    screen.dispatch("switch")
    var s=screen.session
    s.chain.cells=[
        {"cell_id":"fixture:1","x":0,"y":10,"kind":"A"},
        {"cell_id":"fixture:2","x":1,"y":10,"kind":"A"},
        {"cell_id":"fixture:3","x":0,"y":11,"kind":"A"},
        {"cell_id":"fixture:4","x":1,"y":11,"kind":"A"}]
    s.chain._next_cell_id=4
    for i in 3:screen.dispatch("move",{"dx":1})
    screen.dispatch("hard_drop")
    s.tick(300000)
    screen.refresh()
    assert_eq(s.metrics.casts,1)
    assert_true(screen.get_node("Combat/CutIn").visible)
    assert_string_contains(screen.get_node("Combat/Skills/Description").text,"최근 ATK T1")
    var hp=s.combat.boss_hp
    for i in 4:screen.refresh()
    assert_eq(s.combat.boss_hp,hp)

func test_screen_checkpoint_uses_isolated_writer_and_restores_paused():
    var disk=load("res://src/replanned_r3/r3_save.gd").new("user://replanned_r3_tests/screen-"+Crypto.new().generate_random_bytes(8).hex_encode()+"/save.json")
    screen.disk=disk
    screen.dispatch("pause")
    var before=screen.session.line.active_cells().duplicate(true)
    assert_true(screen.save_checkpoint().success)
    screen.dispatch("resume")
    screen.dispatch("move",{"dx":1})
    screen.dispatch("pause")
    assert_true(screen.restore_checkpoint().success)
    assert_eq(screen.session.line.active_cells(),before)
    assert_true(screen.session.combat.paused)
    assert_true(screen.presentation.view().is_empty())

func test_missing_checkpoint_preserves_live_session():
    screen.disk=load("res://src/replanned_r3/r3_save.gd").new("user://replanned_r3_tests/missing-"+Crypto.new().generate_random_bytes(8).hex_encode()+"/save.json")
    screen.dispatch("pause")
    var before=screen.session.snapshot()
    assert_false(screen.restore_checkpoint().success)
    assert_eq(screen.session.snapshot(),before)

func test_paused_time_keeps_fractional_clock_and_running_save_is_rejected():
    screen._fraction_us=0.375
    screen.dispatch("pause")
    screen._process(0.1234567)
    assert_eq(screen._fraction_us,0.375)
    screen.dispatch("resume")
    assert_eq(screen.save_checkpoint().reason,"PAUSE_REQUIRED")
    assert_eq(screen.restore_checkpoint().reason,"PAUSE_REQUIRED")
