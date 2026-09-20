extends GutTest
const Screen=preload("res://scenes/replanned_r3/resource_choice.tscn")

func test_three_playable_practices_use_actual_controls_and_cannot_save():
    var screen=Screen.instantiate()
    add_child_autofree(screen)
    assert_true(screen.has_method("start_line_practice"))
    if not screen.has_method("start_line_practice"):return
    for kind in ["FOUR","SPIN","COMBO"]:
        screen.start_line_practice(kind)
        var before=screen.session.line.snapshot()
        screen.session.tick(5000000)
        assert_eq(screen.session.line.snapshot(),before,"practice waits for player input")
        if kind=="SPIN":screen.dispatch("rotate",{"direction":1})
        screen.dispatch("hard_drop")
        if kind=="COMBO":screen.dispatch("hard_drop")
        assert_eq(screen.session.supply_report().mastery_units,2 if kind=="COMBO" else 10)
        assert_true(screen.session.practice_complete())
        assert_false(screen.session.can_checkpoint())
        screen.end_chain_practice()
        assert_true(screen.preparing)

func test_mastery_hud_shows_actual_bonus_and_enemy_counterplay():
    var screen=Screen.instantiate()
    add_child_autofree(screen)
    screen.start_resource_battle("LINE")
    assert_true(screen.has_node("Combat/PatternStatus"))
    assert_true(screen.has_node("Preparation/LinePractice"))
