extends GutTest
const Screen=preload("res://scenes/replanned_r3/resource_choice.tscn")

func make_screen():
    var s=Screen.instantiate()
    s.preference_path="user://feedback-tests/preference.cfg"
    add_child_autofree(s)
    s.set_process(false)
    return s

func test_successful_four_clear_has_celebration_not_just_resource_text():
    var s=make_screen()
    s.start_line_practice("FOUR")
    s.dispatch("hard_drop")
    assert_true(s.has_node("Puzzle/Feedback"),"Actual playable entry must own a celebration consumer")
    if not s.has_node("Puzzle/Feedback"):return
    var feedback=s.get_node("Puzzle/Feedback")
    assert_true(feedback.banner.text.contains("TETRIS"))
    assert_gt(feedback.bursts.size(),0,"Cleared cells have localized feedback")
    assert_gt(feedback.sound_count,0,"Success launches a short fanfare")
    assert_eq(s.session.supply_report().mastery_units,10,"VFX must not duplicate reward")

func test_skill_name_image_and_actual_effect_survive_cut_in():
    var s=make_screen()
    s.start_chain_practice()
    s.dispatch("hard_drop")
    s._process(1.1)
    assert_true(s.get_node("Combat/CutIn/Caption").text.contains("균열 참격"),"Named skill, not only category")
    assert_true(s.get_node("Combat/CutIn/Caption").text.contains("피해"))
    assert_not_null(s.get_node("Combat/CutIn/Effect").texture)
    s._process(2.0)
    assert_true(s.get_node("Combat/Skills/Description").text.contains("균열 참격"))
    assert_true(s.get_node("Combat/Skills/Description").text.contains("18"),"Actual T2 damage receipt")

func test_same_swap_receipt_does_not_replay_fanfare():
    var s=make_screen()
    s.start_resource_battle("SWAP")
    var f=s.get_node("Puzzle/Feedback")
    s.session.swap.setup_training()
    var move=s.session.swap._teaching.swap
    assert_true(s.session.command("resource_swap",{"a":Vector2i(move[0][0],move[0][1]),"b":Vector2i(move[1][0],move[1][1])}).success)
    var events=s.session.tick(300000)
    var event={}
    for item in events:
        if item.get("effect")=="RESOURCE_SWAP_RESOLVED":event=item;break
    assert_false(event.is_empty())
    if event.is_empty():return
    f.observe([event])
    var count=f.sound_count
    f.advance(2.0)
    f.observe([event])
    assert_eq(f.sound_count,count,"Re-reading an authoritative clear must not celebrate it twice")

func test_reduced_motion_and_pause_preserve_state_and_mute_stops_all_cues():
    var s=make_screen()
    s.start_line_practice("SPIN")
    s.dispatch("rotate",{"direction":1})
    s.dispatch("hard_drop")
    var f=s.get_node("Puzzle/Feedback")
    var before=s.session.supply_report()
    s.reduced_motion=true
    f.advance(0.1)
    assert_eq(f.banner.scale,Vector2.ONE)
    var position=f.banner.position
    f.advance(0.1)
    assert_eq(f.banner.position,position)
    assert_eq(s.session.supply_report(),before)
    s.dispatch("pause")
    var remaining=f.remaining
    f.advance(3.0)
    assert_eq(f.remaining,remaining,"Pause freezes cosmetic expiry")
    assert_eq(f.notes.size(),0)
    s.assist_ui.sound.volume_db=-80
    s.refresh()
    assert_true(f.muted)
    for voice in f.voices:assert_false(voice.playing)

func test_rejected_swap_never_rewards_or_plays_success():
    var s=make_screen()
    s.start_resource_battle("SWAP")
    var f=s.get_node("Puzzle/Feedback")
    var before=s.session.supply.snapshot()
    var rejected=false
    for y in 8:
        for x in 7:
            var result=s.dispatch("resource_swap",{"a":Vector2i(x,y),"b":Vector2i(x+1,y)})
            if not result.success:
                rejected=true
                assert_eq(f.sound_count,0)
                assert_eq(s.session.supply.snapshot(),before)
                assert_true(f.banner.text.contains("연결 없음"))
                break
            # Do not continue from a successful clear; test a deterministic reject directly below.
            s.preparing=true
            s.start_resource_battle("SWAP")
            f=s.get_node("Puzzle/Feedback")
        if rejected:break
    assert_true(rejected)

func test_paid_change_failure_has_no_success_but_applied_change_has_cost():
    var s=make_screen()
    s.start_resource_battle("LINE")
    var session=s.session
    session.mode="CHAIN"
    session.chain.cells=[{"cell_id":"fixture","x":0,"y":11,"kind":"A"}]
    session.supply.discarded=3
    session.assist_open=true
    var result=s.dispatch("bonus_apply",{"operation":"change","cell_id":"fixture","kind":"A"})
    assert_false(result.success)
    assert_eq(s.get_node("Puzzle/Feedback").sound_count,0)
    result=s.dispatch("bonus_apply",{"operation":"change","cell_id":"fixture","kind":"H"})
    assert_true(result.success)
    assert_true(s.get_node("Puzzle/Feedback").detail.text.contains("-2"))
    assert_eq(session.bonus_balance(),1)

func test_actual_effect_formatter_handles_caps_and_absorption():
    var info=preload("res://src/replanned_r3/skill_feedback.gd").new()
    assert_true(info.effect({"starter":"A","damage_applied":7,"damage_requested":50,"shield_absorbed":12,"bank_consumed":4}).contains("피해 7"))
    assert_false(info.effect({"starter":"A","damage_applied":7,"damage_requested":50}).contains("50"))
    assert_true(info.effect({"starter":"D","effect":"DEF_NO_TARGET"}).contains("대상 없음"))
    assert_true(info.effect({"starter":"D","ward_before":30,"ward_after":30}).contains("+0"))
    assert_true(info.effect({"starter":"H","healing_applied":0}).contains("체력 가득"))
    assert_true(info.effect({"starter":"T","time_applied_us":0,"reason":"EXTENSION_CAP_REACHED"}).contains("상한"))
    assert_true(info.effect({"starter":"T","time_applied_us":0,"reason":"ACTION_COMMITTED"}).contains("행동 확정"))

func test_enemy_destruction_never_celebrates_or_gives_supply():
    var s=make_screen()
    s.preferred_encounter="outer_breach"
    s.start_resource_battle("SWAP")
    var f=s.get_node("Puzzle/Feedback")
    for i in 800:
        s._process(0.05)
        if s.session.metrics.destroyed>0:break
    assert_gt(s.session.metrics.destroyed,0)
    assert_eq(f.sound_count,0)
    assert_eq(s.session.supply.pairs,4)

func test_session_transition_clears_visuals_and_never_replays_history():
    var s=make_screen()
    s.start_line_practice("FOUR")
    s.dispatch("hard_drop")
    var f=s.get_node("Puzzle/Feedback")
    assert_gt(f.remaining,0.0)
    s.end_chain_practice()
    assert_eq(f.remaining,0.0)
    s.start_resource_battle("LINE")
    assert_eq(f.sound_count,0)
    assert_eq(f.bursts.size(),0)

func test_celebration_text_does_not_cover_playable_cells():
    var s=make_screen()
    for mode in ["LINE","SWAP"]:
        s.start_resource_battle(mode)
        var f=s.get_node("Puzzle/Feedback")
        f.celebrate("4 COMBO!","자원 획득",4,"line")
        await get_tree().process_frame
        var board=s.get_node("Puzzle/LineBoard" if mode=="LINE" else "Puzzle/SwapBoard")
        assert_false(f.banner.get_rect().intersects(board.get_rect()),"%s banner=%s board=%s"%[mode,f.banner.get_rect(),board.get_rect()])
        assert_false(f.detail.get_rect().intersects(board.get_rect()))
        s.preparing=true
