extends GutTest

func test_real_entry_enables_guard_and_visible_description():
    var screen=load("res://scenes/replanned_r3/resource_choice.tscn").instantiate()
    add_child_autofree(screen)
    screen.start_resource_battle("LINE")
    assert_true(screen.session.combat.has_method("counter_state"),"actual user entry")
    var text=screen.skill_feedback.effect({"starter":"D","effect":"DEF_WARD","ward_before":0,"ward_after":10,"counter_granted":3})
    assert_true(text.contains("3회"))

func make_session(profile:String="outer_breach"):
    var path="res://src/replanned_r3/counter_session.gd"
    return load(path if FileAccess.file_exists(path) else "res://src/replanned_r3/mastery_session.gd").new("STANDARD",42,"counter-test",profile)

func test_defense_tier_grants_charges_and_stacks_not_percent():
    var s=make_session()
    assert_true(s.combat.has_method("counter_state"),"counter must be authoritative combat state")
    if not s.combat.has_method("counter_state"):return
    var sum=0
    for tier in range(1,7):
        var r=s._apply_finisher(s.combat,"def"+str(tier),"D",tier)
        sum+=tier
        assert_eq(r.counter_granted,tier)
        assert_eq(s.combat.counter_state().charges,sum)
    assert_false(s._apply_finisher(s.combat,"def6","D",6).success)
    assert_eq(s.combat.counter_state().charges,21)

func test_reduces_after_ward_and_armor_and_reflects_without_attack_bonus():
    var s=make_session()
    if not s.combat.has_method("counter_state"):assert_true(false,"missing counter");return
    var c=s.combat
    s._apply_finisher(c,"guard","D",2)
    c.ward=0;c.ward_target="";c.armor=1;c.attack_bank=40;c.weakness_us=100
    var raw=int(c.current_action().damage)-1
    var hp=c.hp
    var boss=c.boss_hp
    var r=c._resolve_current_action()
    assert_eq(r.counter_prevented,ceili(raw/2.0))
    assert_eq(c.hp,hp-(raw-ceili(raw/2.0)))
    assert_eq(c.boss_hp,boss-ceili(raw/2.0))
    assert_eq(c.attack_bank,40)
    assert_eq(c.counter_state().charges,1)
    assert_false(c._resolve_current_action().success)
    assert_eq(c.counter_state().charges,1)

func test_no_damage_or_full_mitigation_does_not_spend():
    for profile in ["foundry","outer_breach"]:
        var s=make_session(profile)
        if not s.combat.has_method("counter_state"):assert_true(false,"missing counter");return
        s._apply_finisher(s.combat,"guard","D",1)
        s.combat.armor=100
        var before=s.combat.boss_hp
        s.combat._resolve_current_action()
        assert_eq(s.combat.counter_state().charges,1)
        assert_eq(s.combat.boss_hp,before)

func test_actual_defense_cast_checkpoint_and_tamper_rejection():
    var s=make_session()
    if not s.combat.has_method("counter_state"):assert_true(false,"missing counter");return
    for x in 4:s.chain.cells.append(s.chain._new_cell(x,11,"D"))
    s.command("switch")
    s.chain.active_pair.axis.kind="H";s.chain.active_pair.satellite.kind="T"
    for i in 3:s.command("move",{"dx":1})
    s.command("hard_drop");s.tick(2500000)
    assert_eq(s.metrics.casts,1)
    assert_eq(s.combat.counter_state().charges,1)
    var copy=make_session()
    assert_true(copy.combat.restore(s.combat.snapshot()),"combat boundary")
    assert_true(copy._valid_cast_ledger(s.snapshot()),"cast ledger boundary")
    assert_true(copy.combat.restore(JSON.parse_string(JSON.stringify(s.combat.snapshot()))),"JSON combat")
    assert_true(copy._valid_cast_ledger(JSON.parse_string(JSON.stringify(s.snapshot()))),"JSON cast")
    assert_true(copy.restore(JSON.parse_string(JSON.stringify(s.snapshot()))))
    assert_eq(copy.snapshot(),s.snapshot())
    var bad=s.snapshot()
    bad.combat.counter.charges+=1
    var before=copy.snapshot()
    assert_false(copy.restore(bad))
    assert_eq(copy.snapshot(),before)

func test_reflection_victory_after_real_cast_saves_and_simultaneous_death_loses():
    for hp in [100,1]:
        var s=make_session()
        for x in 4:s.chain.cells.append(s.chain._new_cell(x,11,"D"))
        s.command("switch")
        s.chain.active_pair.axis.kind="H";s.chain.active_pair.satellite.kind="T"
        for i in 3:s.command("move",{"dx":1})
        s.command("hard_drop");s.tick(2500000)
        s.combat.ward=0;s.combat.ward_target="";s.combat.armor=0;s.combat.hp=hp;s.combat.boss_hp=1
        s.tick(s.combat.eta_us+600000)
        assert_eq(s.combat.outcome,"VICTORY" if hp==100 else "DEFEAT")
        assert_eq(s.action.counter_receipt.counter_reflected,1)
        assert_false(s.can_checkpoint(),"cut-in must finish before result/save")
        s.tick(1000000)
        assert_true(s.can_checkpoint())
        assert_true(make_session().restore(JSON.parse_string(JSON.stringify(s.snapshot()))))

func test_counter_grants_on_zero_damage_pattern_restore_and_do_not_expire():
    var s=make_session("foundry")
    for x in 4:s.chain.cells.append(s.chain._new_cell(x,11,"D"))
    s.command("switch")
    s.chain.active_pair.axis.kind="H";s.chain.active_pair.satellite.kind="T"
    for i in 3:s.command("move",{"dx":1})
    s.command("hard_drop");s.tick(2500000)
    assert_eq(s.last_cast.effect,"DEF_NO_TARGET")
    assert_eq(s.combat.counter_state().charges,1)
    assert_true(make_session("foundry").restore(s.snapshot()))
    s.tick(s.combat.eta_us+1600001)
    assert_eq(s.combat.counter_state().charges,1)
    assert_true(s.can_checkpoint())
    assert_true(make_session("foundry").restore(s.snapshot()))

func test_impossible_hit_arithmetic_and_hit_before_grant_are_rejected():
    var s=make_session()
    s.command("prepare_resource",{"mode":"SWAP"})
    s.tick(s.combat.eta_us+1600001)
    for x in 4:s.chain.cells.append(s.chain._new_cell(x,11,"D"))
    s.command("switch")
    s.chain.active_pair.axis.kind="H";s.chain.active_pair.satellite.kind="T"
    for i in 3:s.command("move",{"dx":1})
    s.command("hard_drop");s.tick(2500000)
    s.combat.ward=0;s.combat.ward_target="";s.combat.armor=0
    s.tick(s.combat.eta_us+1600001)
    var good=s.snapshot()
    assert_false(good.is_empty())
    assert_true(make_session().restore(good))
    var bad=good.duplicate(true)
    bad.combat.counter.hits[-1].prevented=100
    bad.combat.counter.hits[-1].reflected=100
    assert_false(make_session().restore(bad),"impossible 100/100 must not restore")
    bad=good.duplicate(true)
    bad.combat.counter.hits[-1].action_id=bad.combat.pattern_events[0]
    assert_false(make_session().restore(bad),"cannot move guarded hit before actual grant")
    bad=good.duplicate(true)
    bad.combat.counter.hits.remove_at(bad.combat.counter.hits.size()-1)
    bad.combat.counter.charges+=1
    assert_false(make_session().restore(bad),"cannot remove consumed charge history")
