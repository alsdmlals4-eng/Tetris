extends GutTest

func session():
    var path="res://src/replanned_r3/r3_finisher_session.gd"
    var script=load(path if FileAccess.file_exists(path) else "res://src/replanned_r3/r3_session.gd")
    return script.new("STANDARD",42,"r3:finisher-test","watchtower")

func fixture(s,lines:Array):
    s.chain.cells=[]
    s.chain._next_cell_id=0
    for row in lines.size():
        for x in 6:
            if lines[row][x]!=".":s.chain.cells.append(s.chain._new_cell(x,12-lines.size()+row,lines[row][x]))

func drop(s):
    s.command("switch")
    s.chain.active_pair.axis.kind="H"
    s.chain.active_pair.satellite.kind="T"
    for i in 3:s.command("move",{"dx":1})
    s.command("hard_drop")

func test_no_manual_category_selection():
    var s=session()
    assert_false(s.command("category",{"category":"DEF"}).success)

func test_two_waves_cast_once_after_settle_and_at_impact():
    var s=session()
    s.combat.boss_hp=100
    s.combat.attack_bank=6
    fixture(s,["HH....","AA....","AAHH.."])
    drop(s)
    s.tick(600000)
    assert_eq(s.metrics.casts,0,"collect two waves; do not apply at wave boundaries")
    assert_eq(s.combat.boss_hp,100)
    var eta=s.combat.eta_us
    s.tick(499999)
    assert_eq(s.combat.boss_hp,100,"windup has not reached contact")
    assert_eq(s.combat.eta_us,eta,"both clocks stop for the cast")
    s.tick(1)
    assert_eq(s.metrics.casts,1)
    assert_eq(s.last_cast.category,"ATK","H second wave must not change A starter")
    assert_eq(s.last_cast.wave,2)
    assert_eq(s.combat.boss_hp,84,"4+6 base, +6 bank exactly once")
    assert_eq(s.combat.attack_bank,0)
    s.tick(900000)
    assert_eq(s.metrics.casts,1)
    assert_true(s.can_checkpoint())

func test_starter_heal_does_not_default_to_attack():
    var s=session()
    s.combat.hp=50
    s.combat.boss_hp=100
    fixture(s,["HH....","HH...."])
    drop(s)
    s.tick(800000)
    assert_eq(s.combat.hp,52)
    assert_eq(s.combat.boss_hp,100)
    assert_eq(s.last_cast.category,"SUP")

func test_enemy_contact_delayed_and_board_frozen_for_whole_action():
    var s=session()
    s.combat.hp=100
    s.combat.armor=0
    s.combat.eta_us=100000
    s.tick(100000)
    assert_eq(s.combat.hp,100,"deadline commits presentation, damage comes at contact")
    var before=s.line.snapshot()
    assert_false(s.command("hard_drop").success)
    s.tick(599999)
    assert_eq(s.combat.hp,100)
    assert_eq(s.line.snapshot(),before)
    s.tick(1)
    assert_lt(s.combat.hp,100)
    var hp=s.combat.hp
    var eta=s.combat.eta_us
    s.tick(1000000)
    assert_eq(s.combat.hp,hp)
    assert_eq(s.combat.eta_us,eta)
    assert_eq(s.line.snapshot(),before)

func test_pause_and_checkpoint_reject_mid_cast():
    var s=session()
    fixture(s,["AA....","AA...."])
    drop(s)
    s.tick(300000)
    assert_false(s.can_checkpoint())
    s.command("pause")
    var hp=s.combat.boss_hp
    s.tick(5000000)
    assert_eq(s.combat.boss_hp,hp)
    s.command("resume")
    s.tick(500000)
    assert_eq(s.metrics.casts,1)

func test_same_deadline_enemy_lethal_prevents_finisher():
    var s=session()
    s.combat.hp=1
    s.combat.armor=0
    s.combat.eta_us=300000
    fixture(s,["HH....","HH...."])
    drop(s)
    s.tick(300000+1600000)
    assert_eq(s.combat.outcome,"DEFEAT")
    assert_eq(s.metrics.casts,0)

func test_four_starters_roundtrip_after_finisher_without_replay():
    for kind in ["A","D","H","T"]:
        var s=session()
        fixture(s,[kind+kind+"....",kind+kind+"...."])
        drop(s)
        s.tick(1700000)
        var state=s.snapshot()
        assert_false(state.is_empty(),kind)
        var restored=session()
        assert_true(restored.restore(state),kind+" in-memory receipt")
        assert_true(restored.restore(JSON.parse_string(JSON.stringify(state))),kind+" must restore its own exact receipt")
        assert_eq(restored.snapshot(),state)
        restored.tick(1)
        assert_eq(restored.metrics.casts,1)

func test_starter_axis_then_count_then_top_left_independent_of_array_order():
    var policy=load("res://src/replanned_r3/r3_finisher.gd")
    var cells=[]
    for i in 4:cells.append({"cell_id":"a%d"%i,"x":i%2,"y":i/2,"kind":"A"})
    for i in 5:cells.append({"cell_id":"d%d"%i,"x":3+i%2,"y":i/2,"kind":"D"})
    assert_eq(policy.starter(cells,"a0"),"A","axis wins even against larger D")
    assert_eq(policy.starter(cells,"absent"),"D","largest count wins without axis")
    cells.pop_back()
    assert_eq(policy.starter(cells,"absent"),"A","leftmost first in top-row tie")
    cells.reverse()
    assert_eq(policy.starter(cells,"absent"),"A")

func test_time_cap_and_duplicate_effect_are_not_animation_bonuses():
    var policy=load("res://src/replanned_r3/r3_finisher.gd")
    var s=session()
    s.combat.extension_us=2900000
    var eta=s.combat.eta_us
    var result=policy.apply(s.combat,"fixture:time","T",6)
    assert_eq(result.time_applied_us,100000)
    assert_eq(s.combat.eta_us,eta+100000)
    assert_eq(s.combat.extension_us,3000000)
    assert_false(policy.apply(s.combat,"fixture:time","T",6).success)
    s.combat.eta_us=1000
    result=policy.apply(s.combat,"fixture:committed","T",1)
    assert_eq(result.time_applied_us,0)
    assert_eq(result.reason,"ACTION_COMMITTED")

func test_ghost_starter_matches_actual_split_landing_and_is_read_only():
    var s=session()
    fixture(s,["..AA..","..A..."])
    s.command("switch")
    s.chain.active_pair.axis.kind="A"
    var before=s.chain.snapshot()
    var preview=s.starter_preview()
    assert_eq(preview.starter,"A")
    assert_eq(s.chain.snapshot(),before)
    s.command("hard_drop")
    s.tick(300000)
    assert_eq(s.starter_preview().starter,preview.starter)
    assert_true(s.starter_preview().locked)

func test_new_save_namespace_and_legacy_schema_rejection():
    var disk=load("res://src/replanned_r3/r3_save.gd").new("user://finisher-tests/save.json","user://finisher-tests/options.json")
    var s=session()
    assert_true(disk.save_session(s).success,"disk validator must recognize new opt-in schema")
    assert_true(disk.load_checkpoint().success)
    var legacy=load("res://src/replanned_r3/r3_session.gd").new("STANDARD",42,"r3:finisher-test","watchtower")
    assert_false(s.restore(legacy.snapshot()))
    assert_false(legacy.restore(s.snapshot()))

func test_native_entry_uses_starter_ui_without_category_buttons():
    var screen=load("res://scenes/replanned_r3/resource_choice.tscn").instantiate()
    screen.preference_path="user://finisher-tests/preference.cfg"
    add_child_autofree(screen)
    screen.set_process(false)
    screen.start_resource_battle("LINE")
    assert_false(screen.dispatch("category",{"category":"DEF"}).success)
    for category in ["ATK","DEF","SUP"]:
        assert_false(screen.has_node("Combat/Skills/"+category),"manual selection must be absent")
    assert_true(screen.get_node("Combat/Skills/Description").text.contains("시동"))

func test_starter_locks_when_first_symbols_pop_not_after_settle():
    var s=session()
    fixture(s,["HH....","AA....","AAHH.."])
    drop(s)
    s.tick(180000)
    assert_eq(s.starter_preview().starter,"A")
    assert_true(s.starter_preview().locked)
    assert_eq(s.metrics.casts,0)

func test_fractional_receipt_rejected_atomically():
    var s=session()
    fixture(s,["AA....","AA...."])
    drop(s)
    s.tick(1700000)
    var state=s.snapshot()
    var bad=state.duplicate(true)
    bad.casts[0].power=float(bad.casts[0].power)+0.5
    bad.last_cast=bad.casts[0].duplicate(true)
    assert_false(s.restore(bad))
    assert_eq(s.snapshot(),state)

func test_chunk_partition_does_not_change_battle_or_presentation():
    var a=session()
    var b=session()
    for s in [a,b]:
        fixture(s,["HH....","AA....","AAHH.."])
        drop(s)
    a.tick(2500000)
    for i in 250:b.tick(10000)
    assert_eq(a.snapshot(),b.snapshot())
    assert_false(a.snapshot().is_empty())
    for s in [a,b]:s.combat.eta_us=123456
    a.tick(1000000)
    for i in 100:b.tick(10000)
    assert_eq(a.action,b.action)
    assert_eq(a.combat.snapshot(),b.combat.snapshot())
    assert_eq(a.chain.snapshot(),b.chain.snapshot())

func arm_disruption(s,targets:Array):
    s.combat.action_index=1
    s.combat.eta_us=150000
    s.combat.armor=0
    s.disruption._reservation={"action_id":s.combat.action_id(),"target_board":"CHAIN","count":2,"reserved":true,"target_ids":targets}

func test_interrupted_chain_keeps_only_earned_player_waves():
    var s=session()
    s.combat.attack_bank=6
    s.combat.boss_hp=100
    fixture(s,["HH....","AA....","AAHH.."])
    drop(s)
    var targets=s.chain.target_candidates().filter(func(c):return c.x==5)
    arm_disruption(s,[targets[0].cell_id])
    s.tick(3600000)
    assert_eq(s.metrics.casts,1)
    assert_eq(s.last_cast.wave,1)
    assert_eq(s.combat.boss_hp,90,"enemy-settle H wave cannot add paid power")
    assert_eq(s.metrics.destroyed,1)

func test_enemy_created_group_never_starts_skill():
    var s=session()
    fixture(s,["HH....","ADHH.."])
    s.command("switch")
    var targets=[]
    for c in s.chain.cells:
        if c.kind in ["A","D"]:targets.append(c.cell_id)
    arm_disruption(s,targets)
    var supply=s.supply.snapshot()
    s.tick(2050000)
    assert_eq(s.metrics.casts,0)
    assert_eq(s.supply.snapshot(),supply)
    assert_true(s.action.is_empty())

func test_terminal_presentation_finishes_before_checkpoint_and_does_not_replay():
    for lethal in [false,true]:
        var s=session()
        if lethal:
            s.combat.hp=1
            s.combat.armor=0
            s.combat.eta_us=1
            s.tick(600001)
        else:
            s.combat.boss_hp=1
            fixture(s,["AA....","AA...."])
            drop(s)
            s.tick(800000)
        assert_false(s.action.is_empty())
        assert_false(s.can_checkpoint())
        s.command("pause")
        var before=s.action.duplicate(true)
        s.tick(3000000)
        assert_eq(s.action,before)
        s.command("resume")
        s.tick(1000000)
        assert_true(s.can_checkpoint())
        var saved=s.snapshot()
        var restored=session()
        assert_true(restored.restore(JSON.parse_string(JSON.stringify(saved))))
        restored.tick(9000000)
        assert_eq(restored.snapshot(),saved)

func test_soft_drop_release_during_cinematic_does_not_latch_next_pair():
    var s=session()
    fixture(s,["AA....","AA...."])
    drop(s)
    s.chain._soft_drop=true # represents held key on just-locked pair
    s.tick(300000)
    assert_true(s.command("soft_drop",{"enabled":false}).success)
    assert_false(s.chain.snapshot().soft_drop)
    assert_false(s.command("soft_drop",{"enabled":true}).success)

func test_three_chain_attack_and_heal_accumulate_but_ward_does_not_sum():
    var policy=load("res://src/replanned_r3/r3_finisher.gd")
    assert_eq(policy.power("A",3),18)
    assert_eq(policy.power("H",3),9)
    assert_eq(policy.power("D",3),7)
    var s=session()
    s.combat.attack_bank=0
    s.combat.boss_hp=100
    var effect=policy.apply(s.combat,"fixture:three","A",3)
    assert_eq(effect.wave,3)
    assert_eq(effect.power,18)
    assert_eq(s.combat.boss_hp,82)

func test_lethal_topout_after_clear_cancels_bundle_and_allows_terminal_save():
    var s=session()
    var rows=[]
    for y in 14:rows.append(("A" if y%2==0 else "D")+(".AA.." if y>=12 else "....."))
    fixture(s,rows)
    s.combat.hp=1
    drop(s)
    s.tick(300000)
    assert_eq(s.combat.outcome,"DEFEAT")
    assert_eq(s.metrics.casts,0)
    assert_true(s.can_checkpoint())
    assert_false(s.snapshot().is_empty())
