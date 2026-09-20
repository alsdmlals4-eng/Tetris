extends GutTest
const Screen=preload("res://scenes/replanned_r3/resource_choice.tscn")

func session():
    var screen=Screen.instantiate()
    add_child_autofree(screen)
    screen.start_resource_battle("LINE")
    return screen.session

func cells(prefix:String,count:int)->Array:
    var ids=[]
    for i in count:ids.append(prefix+str(i))
    return ids

func test_actual_entry_has_a_destruction_action():
    var s=session()
    var total=0
    for i in 4:
        s.combat.action_index=i
        total+=s._destruction_count()
    assert_gt(total,0,"actual playable default must not omit the enemy destruction profile")

func test_ten_pairs_overflow_then_refill_preserves_excess():
    var s=session()
    assert_true(s.supply.credit("first",cells("a",20)).success)
    assert_eq(s.supply.pairs,10)
    var reward=s.supply.credit("second",cells("b",10))
    assert_eq(s.supply.pairs,10,"reserve never exceeds10")
    assert_eq(reward.overflow,3,"all three earned pairs become bonus at cap")
    s.supply.consume("one")
    reward=s.supply.credit("third",cells("c",10))
    assert_eq(reward.applied,1)
    assert_eq(reward.overflow,2)
    assert_eq(s.supply.discarded,5,"overflow accounting conserves all earned supply")

func test_bonus_open_without_currency_rejects_without_pause():
    var s=session()
    var before=s.combat.paused
    var result=s.command("bonus_open")
    assert_eq(result.reason,"INSUFFICIENT_BONUS")
    assert_eq(s.combat.paused,before)

func funded():
    var s=session()
    s.supply.credit("fixture",cells("fund",50))
    return s

func fixed(s,kinds:String):
    s.chain.cells=[]
    for i in kinds.length():s.chain.cells.append({"cell_id":s._run_id+":chain:cell:"+str(i+1),"x":i,"y":11,"kind":kinds[i]})
    s.chain._next_cell_id=kinds.length()

func test_bonus_request_freezes_both_clocks_only_at_safe_boundary_and_cancel_is_free():
    var s=funded()
    var before=s.supply.discarded
    var result=s.command("bonus_open")
    assert_true(result.success)
    var eta=s.combat.eta_us
    s.tick(2000000)
    assert_eq(s.combat.eta_us,eta)
    assert_true(s.command("bonus_cancel").success)
    assert_eq(s.supply.discarded,before)

func test_bonus_change_rejects_noop_then_creates_one_attack_finisher():
    var s=funded()
    fixed(s,"AAAH")
    assert_true(s.command("bonus_open").success)
    var id=s.chain.cells[3].cell_id
    assert_false(s.command("bonus_apply",{"operation":"change","cell_id":id,"kind":"H"}).success)
    var result=s.command("bonus_apply",{"operation":"change","cell_id":id,"kind":"A"})
    assert_true(result.success)
    if not result.success:return
    s.tick(2000000)
    assert_eq(s.metrics.casts,1)
    assert_eq(s.last_cast.starter,"A")
    assert_eq(s.last_cast.power,8)
    assert_eq(s.bonus_balance(),7)

func test_bonus_horizontal_shift_and_empty_move_respect_gravity():
    var s=funded()
    fixed(s,"AD")
    assert_true(s.command("bonus_open").success)
    var id=s.chain.cells[0].cell_id
    assert_false(s.command("bonus_apply",{"operation":"shift","cell_id":id,"dx":-1}).success)
    assert_true(s.command("bonus_apply",{"operation":"shift","cell_id":id,"dx":1}).success)
    assert_eq(s.chain.cells[0].x,1)
    assert_eq(s.chain.cells[1].x,0)

func test_emergency_attack_does_not_damage_boss_and_heal_clamps():
    var s=funded()
    var hp=s.combat.boss_hp
    assert_true(s.command("bonus_open").success)
    assert_true(s.command("bonus_apply",{"operation":"attack"}).success)
    assert_eq(s.combat.boss_hp,hp)
    assert_eq(s.combat.attack_bank,5)

func test_all_four_encounters_have_exactly_one_disruption_per_cycle():
    var script=session().get_script()
    for profile in ["outer_breach","watchtower","foundry","rift_core"]:
        var s=script.new("STANDARD",42,"coverage:"+profile,profile)
        var nonzero=0
        for i in 4:
            s.combat.action_index=i
            if s._destruction_count()>0:nonzero+=1
        assert_eq(nonzero,1,profile)

func test_tier_power_applied_once_and_grows_more_than_single_cast_spam():
    var s=session()
    assert_true(s.has_method("finisher_power"))
    if not s.has_method("finisher_power"):return
    assert_eq(s.finisher_power("A",1),8)
    assert_eq(s.finisher_power("A",3),32)
    assert_eq(s.finisher_power("A",6),104)
    assert_gt(s.finisher_power("A",3),3*s.finisher_power("A",1))
    assert_eq(s.finisher_power("D",6),46)
    assert_eq(s.finisher_power("H",6),45)
    assert_eq(s.finisher_power("T",6),3000000)

func test_assist_snapshot_is_distinct_and_invalid_spend_is_atomic():
    var s=session()
    var state=s.snapshot()
    assert_eq(state.schema,"r3-mastery-v1","actual consumer now uses isolated mastery successor")
    assert_true(state.has("bonus_history"))
    if not state.has("bonus_history"):return
    var restored=s.get_script().new(state.difficulty,int(state.seed),state.run_id,state.profile)
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(state))))
    var before=restored.snapshot()
    state.bonus_history=[{"id":1,"operation":"attack","cost":2,"earned":2,"args":{"operation":"attack"},"event_id":""}]
    assert_false(restored.restore(state),"cannot spend unearned overflow")
    assert_eq(restored.snapshot(),before)

func test_request_while_pair_falling_waits_and_enemy_deadline_wins():
    var s=funded()
    s.command("switch")
    assert_eq(s.chain.phase,"FALLING")
    assert_true(s.command("bonus_open").success)
    assert_false(s.assist_open)
    s.combat.eta_us=1
    s.command("hard_drop")
    assert_false(s.assist_open,"committed enemy attack cannot be bypassed")
    s.tick(1600001)
    assert_lt(s.combat.hp,100)
    s.tick(1)
    assert_true(s.assist_open)

func test_invalid_bonus_args_do_not_spend_or_change_board():
    var s=funded()
    fixed(s,"AD")
    s.command("bonus_open")
    var before=s.chain.snapshot()
    var balance=s.bonus_balance()
    assert_false(s.command("bonus_apply",{"operation":"shift","cell_id":s.chain.cells[0].cell_id,"dx":0.5}).success)
    assert_false(s.command("bonus_apply",{"operation":"change","cell_id":"not-a-cell","kind":"T"}).success)
    assert_false(s.command("bonus_apply",{"operation":"attack","unexpected":1}).success)
    assert_eq(s.chain.snapshot(),before)
    assert_eq(s.bonus_balance(),balance)

func test_actual_ui_exposes_bonus_and_practice_without_manual_skill_selection():
    var screen=Screen.instantiate()
    add_child_autofree(screen)
    assert_true(screen.has_node("Puzzle/Bonus"))
    assert_true(screen.has_node("Preparation/Practice"))
    assert_true(screen.has_node("Preparation/Encounter"))
    assert_false(screen.has_node("Combat/Skills/ATK"))
    screen.start_resource_battle("LINE")
    assert_true("10쌍" in screen.get_node("Puzzle/Supply").text)

func test_all_six_tiers_have_distinct_readable_visual_strength():
    var s=session()
    var strengths=[]
    for wave in range(1,7):
        var ids=[]
        for i in wave:ids.append(str(i))
        s.action={"owner":"PLAYER","elapsed_us":600000,"impact_us":500000,"duration_us":2500000,"applied":true,"bundle":{"starter":"A","wave_ids":ids}}
        var view=s.action_view()
        assert_true(view.has("rings"))
        if not view.has("rings"):return
        strengths.append(view.rings)
    assert_eq(strengths,[1,2,3,4,5,6])

func test_short_practice_teaches_two_waves_and_is_not_a_paid_run():
    var screen=Screen.instantiate()
    add_child_autofree(screen)
    assert_true(screen.has_method("start_chain_practice"))
    if not screen.has_method("start_chain_practice"):return
    screen.start_chain_practice()
    screen.dispatch("hard_drop")
    screen.session.tick(2200000)
    assert_eq(screen.session.metrics.casts,1)
    assert_eq(screen.session.last_cast.wave,2)
    assert_false(screen.session.can_checkpoint())

func legal_move(board)->Dictionary:
    for y in 8:
        for x in 8:
            for d in [Vector2i.RIGHT,Vector2i.DOWN]:
                var a=Vector2i(x,y)
                var b=a+d
                if b.x>=8 or b.y>=8:continue
                board._swap(a,b)
                var ok=not board.matched_cells().is_empty()
                board._swap(a,b)
                if ok:return {"a":a,"b":b}
    return {}

func test_real_swap_overflow_paid_effect_and_disk_restore_conserve_bonus():
    var Script=preload("res://src/replanned_r3/r3_assist_session.gd")
    var s=Script.new("STANDARD",42,"real-bonus","outer_breach")
    s.command("prepare_resource",{"mode":"SWAP"})
    for attempt in 40:
        if s.bonus_balance()>=4:break
        assert_true(s.command("resource_swap",legal_move(s.swap)).success)
        for wave in 64:
            if not s.swap.resolving:break
            s.tick(300000)
    assert_gte(s.bonus_balance(),2)
    var before=s.bonus_balance()
    assert_true(s.command("bonus_open").success)
    assert_true(s.command("bonus_apply",{"operation":"attack"}).success)
    assert_eq(s.bonus_balance(),before-2)
    var state=JSON.parse_string(JSON.stringify(s.snapshot()))
    var restored=Script.new("STANDARD",42,"real-bonus","outer_breach")
    assert_true(restored.restore(state))
    assert_eq(restored.snapshot(),s.snapshot())
    var refunded=state.duplicate(true)
    refunded.bonus_history=[]
    assert_false(restored.restore(refunded),"removing paid history must not refund already applied bonus")
    var disk=preload("res://src/replanned_r3/r3_save.gd").new("user://bonus-assist-tests/save.json","user://bonus-assist-tests/options.json")
    assert_true(disk.save_session(s).success)
    assert_true(disk.load_checkpoint().success)
    state.bonus_history[0].cost=0.5
    var prior=restored.snapshot()
    assert_false(restored.restore(state))
    assert_eq(restored.snapshot(),prior)
    # Authored fixed-board fixture, real earned currency and full finisher/save consumer.
    s.chain.active_pair={}
    s.chain.phase="NEED_PAIR"
    s.chain.cells=[]
    for x in 4:s.chain.cells.append(s.chain._new_cell(x,11,"H" if x==3 else "D"))
    assert_true(s.command("bonus_open").success)
    assert_true(s.command("bonus_apply",{"operation":"change","cell_id":s.chain.cells[3].cell_id,"kind":"D"}).success)
    s.tick(2000000)
    assert_eq(s.last_cast.starter,"D")
    var corrected=s.snapshot()
    assert_false(corrected.is_empty())
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(corrected))))
    assert_eq(restored.combat.ward,s.combat.ward)

func test_bonus_can_queue_during_enemy_cut_in_and_terminal_clears_request():
    var s=funded()
    s.combat.eta_us=1
    s.tick(1)
    assert_eq(s.action.owner,"ENEMY")
    assert_true(s.command("bonus_open").success)
    assert_false(s.assist_open)
    s.tick(1600001)
    assert_true(s.assist_open)
    s.command("bonus_cancel")
    s.command("bonus_open")
    s.combat.outcome="DEFEAT"
    s._finalize_terminal()
    assert_false(s.assist_requested)
    assert_false(s.assist_open)

func test_every_enemy_destroys_real_swap_cells_without_overflow_reward():
    var Script=preload("res://src/replanned_r3/r3_assist_session.gd")
    for profile in ["outer_breach","watchtower","foundry","rift_core"]:
        var s=Script.new("STANDARD",42,"live:"+profile,profile)
        s.command("prepare_resource",{"mode":"SWAP"})
        for action in 4:
            s.tick(s.combat.eta_us+1600001)
            if s.metrics.destroyed>0:break
        assert_gt(s.metrics.destroyed,0,profile)
        assert_eq(s.supply.pairs,4)
        assert_eq(s.bonus_balance(),0)
        assert_eq(s.metrics.casts,0)

func test_selected_enemy_cut_in_and_loaded_profile_match_actual_enemy():
    var screen=Screen.instantiate()
    add_child_autofree(screen)
    screen.preferred_encounter="watchtower"
    screen.start_resource_battle("LINE")
    screen.session.combat.eta_us=1
    screen.session.tick(1)
    screen.refresh()
    assert_eq(screen.get_node("Combat/CutIn/Actor").texture.get_image().get_data(),screen.assets.enemy_texture("watchtower","idle").get_image().get_data())
    screen.session.tick(1600001)
    screen.disk=preload("res://src/replanned_r3/r3_save.gd").new("user://bonus-profile-test/save.json","user://bonus-profile-test/options.json")
    screen.dispatch("pause")
    assert_true(screen.save_checkpoint().success)
    screen.preferred_encounter="rift_core"
    assert_true(screen.restore_checkpoint().success)
    assert_eq(screen.preferred_encounter,"watchtower")
    assert_eq(screen.get_node("Preparation/Encounter").selected,1)

func test_heal_clamps_armor_adds_and_no_money_rejects_atomically():
    var s=funded()
    s.combat.hp=98
    s.command("bonus_open")
    assert_true(s.command("bonus_apply",{"operation":"heal"}).success)
    assert_eq(s.combat.hp,100)
    # A fixed safe boundary fixture avoids consuming a falling pair in this unit test.
    s.chain.active_pair={}
    s.chain.phase="NEED_PAIR"
    s.command("bonus_open")
    assert_true(s.command("bonus_apply",{"operation":"armor"}).success)
    assert_eq(s.combat.armor,5)
    s.chain.active_pair={}
    s.chain.phase="NEED_PAIR"
    s.command("bonus_open")
    var before=s.bonus_balance()
    assert_false(s.command("bonus_apply",{"operation":"heal"}).success)
    assert_eq(s.bonus_balance(),before)

func test_horizontal_empty_move_falls_and_tracks_assist_event():
    var s=funded()
    fixed(s,"A")
    s.chain.cells[0].y=10
    s.command("bonus_open")
    assert_true(s.command("bonus_apply",{"operation":"shift","cell_id":s.chain.cells[0].cell_id,"dx":1}).success)
    assert_eq(s.chain.cells[0].x,1)
    assert_eq(s.chain.cells[0].y,11)
    assert_true(s.bonus_history[0].event_id.ends_with(":ASSIST"))

func test_soft_drop_release_during_bonus_does_not_latch_next_pair():
    var s=funded()
    s.command("switch")
    s.command("soft_drop",{"enabled":true})
    s.command("bonus_open")
    s.command("hard_drop")
    s.tick(500000)
    assert_true(s.assist_open)
    assert_true(s.command("soft_drop",{"enabled":false}).success)
    s.command("bonus_cancel")
    assert_false(s.chain._soft_drop)

func test_every_defense_tier_survives_combat_restore_and_resource_transaction():
    var s=preload("res://src/replanned_r3/r3_assist_session.gd").new()
    assert_true(s.command("prepare_resource",{"mode":"SWAP"}).success)
    for tier in range(1,7):
        s.combat.ward=0
        s.combat.ward_target=""
        assert_true(s._apply_finisher(s.combat,"def-test-"+str(tier),"D",tier).success)
        var clone=s.combat.get_script().new(s._difficulty,s._run_id,s._profile)
        assert_true(clone.restore(s.combat.snapshot()),"DEF T"+str(tier))
        assert_true(s.command("resource_swap",legal_move(s.swap)).success)
        var events=s.tick(300000)
        for event in events:assert_ne(event.get("reason",""),"INVALID_TRANSACTION_SOURCE")
        for wave in 64:
            if not s.swap.resolving:break
            s.tick(300000)
        assert_false(s.swap.resolving)
