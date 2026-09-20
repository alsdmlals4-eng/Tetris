extends GutTest
const Session=preload("res://src/replanned_r3/mastery_session.gd")

func test_each_encounter_exposes_a_new_pattern_and_keeps_destruction():
    for profile in ["outer_breach","foundry","watchtower","rift_core"]:
        var s=Session.new("STANDARD",42,"test",profile)
        assert_true(s.combat.has_method("pattern_state"),"actual combat must own statuses")
        if not s.combat.has_method("pattern_state"):continue
        var kinds=[]
        var destruction=0
        for i in 4:
            s.combat.action_index=i
            kinds.append(s.combat.current_action().get("pattern",""))
            destruction+=s._destruction_count()
        assert_gt(destruction,0)
        assert_true(kinds.has({"outer_breach":"weakness","foundry":"shield","watchtower":"armor_break","rift_core":"charge"}[profile]))

func test_shield_nonstacking_absorbs_then_expires_after_next_action():
    var s=Session.new("STANDARD",42,"test","foundry")
    var c=s.combat
    if not c.has_method("pattern_state"):assert_true(false,"missing patterns");return
    c._resolve_current_action()
    assert_eq(c.enemy_shield,12)
    c._schedule_next_action()
    var hp=c.boss_hp
    var hit=s._apply_finisher(c,"one","A",1)
    assert_eq(c.enemy_shield,4)
    assert_eq(c.boss_hp,hp)
    assert_eq(hit.shield_absorbed,8)
    c._resolve_current_action()
    assert_eq(c.enemy_shield,0)

func test_armor_break_removes_six_without_touching_hp_or_ward():
    var s=Session.new("STANDARD",42,"test","watchtower")
    var c=s.combat
    if not c.has_method("pattern_state"):assert_true(false,"missing patterns");return
    c.action_index=1
    c.armor=9
    c.ward=14
    c.ward_target=c.action_id()
    var hp=c.hp
    assert_eq(c.current_action().damage,0)
    c._resolve_current_action()
    assert_eq(c.armor,3)
    assert_eq(c.hp,hp)
    assert_eq(c.ward,14)

func test_charge_cancel_only_removes_bonus_and_weakness_single_use():
    var s=Session.new("STANDARD",42,"test","rift_core")
    var c=s.combat
    if not c.has_method("pattern_state"):assert_true(false,"missing patterns");return
    c.action_index=1
    assert_eq(c.current_action().damage,45)
    s._apply_finisher(c,"a","A",2)
    assert_eq(c.current_action().damage,45)
    s._apply_finisher(c,"b","A",1)
    assert_eq(c.charge_damage,20)
    assert_eq(c.current_action().damage,35)
    var outer=Session.new("STANDARD",42,"test2","outer_breach")
    outer.combat.action_index=1
    outer.combat._resolve_current_action()
    outer.combat._schedule_next_action()
    assert_eq(outer.combat.weakness_us,8000000)
    var hit=outer._apply_finisher(outer.combat,"c","A",1)
    assert_eq(hit.damage_requested,10)
    assert_eq(outer.combat.weakness_us,0)
    assert_eq(outer._apply_finisher(outer.combat,"d","A",1).damage_requested,8)

func test_real_enemy_cycles_roundtrip_and_terminal_checkpoint():
    for profile in ["outer_breach","foundry","watchtower","rift_core"]:
        var s=Session.new("STANDARD",42,"cycle",profile)
        s.command("prepare_resource",{"mode":"SWAP"})
        for i in 4:
            if s.combat.outcome!="RUNNING":break
            s.tick(s.combat.eta_us+1600001)
            var data=JSON.parse_string(JSON.stringify(s.snapshot()))
            var copy=Session.new("STANDARD",42,"cycle",profile)
            assert_false(data.is_empty())
            assert_true(copy.restore(data),profile+" cycle "+str(i))
            assert_eq(copy.snapshot(),s.snapshot())
    var s=Session.new("STANDARD",42,"terminal","rift_core")
    s.combat.hp=1
    s.tick(s.combat.eta_us+1600001)
    assert_eq(s.combat.outcome,"DEFEAT")
    assert_true(Session.new("STANDARD",42,"terminal","rift_core").restore(s.snapshot()))

func test_weakness_uses_simulation_clock_and_freezes_in_pause_and_cut_in():
    var s=Session.new("STANDARD",42,"clock","outer_breach")
    s.command("prepare_resource",{"mode":"SWAP"})
    for i in 2:s.tick(s.combat.eta_us+1600000)
    assert_eq(s.combat.weakness_us,8000000)
    s.command("pause")
    s.tick(2000000)
    assert_eq(s.combat.weakness_us,8000000)
    s.command("resume")
    s.tick(7999999)
    assert_eq(s.combat.weakness_us,1)
    s.tick(1)
    assert_eq(s.combat.weakness_us,0)

func test_defeat_during_exposure_pattern_can_restore():
    var s=Session.new("STANDARD",42,"fatal","outer_breach")
    s.command("prepare_resource",{"mode":"SWAP"})
    s.tick(s.combat.eta_us+1600001)
    s.combat.hp=1
    s.tick(s.combat.eta_us+1600001)
    assert_eq(s.combat.outcome,"DEFEAT")
    assert_true(Session.new("STANDARD",42,"fatal","outer_breach").restore(s.snapshot()))

func test_actual_attack_finisher_receipt_survives_status_and_disk_roundtrip():
    for profile in ["outer_breach","foundry","rift_core"]:
        var s=Session.new("STANDARD",42,"cast",profile)
        s.command("prepare_resource",{"mode":"SWAP"})
        var count=2 if profile=="outer_breach" else 1
        for i in count:s.tick(s.combat.eta_us+1600001)
        for x in 4:s.chain.cells.append(s.chain._new_cell(x,11,"A"))
        s.command("switch")
        s.chain.active_pair.axis.kind="H"
        s.chain.active_pair.satellite.kind="T"
        for i in 3:s.command("move",{"dx":1})
        s.command("hard_drop")
        s.tick(2500000)
        assert_eq(s.metrics.casts,1)
        var copy=Session.new("STANDARD",42,"cast",profile)
        assert_true(copy.restore(JSON.parse_string(JSON.stringify(s.snapshot()))),profile)
        assert_eq(copy.snapshot(),s.snapshot())
        var bad=s.snapshot()
        bad.casts[0].shield_absorbed+=1
        bad.last_cast=bad.casts[0].duplicate(true)
        assert_false(copy.restore(bad),"forged modifier rejected")

func test_malformed_pattern_hp_rejects_without_mutating_or_engine_errors():
    var s=Session.new()
    var before=s.snapshot()
    var bad=before.duplicate(true)
    bad.combat.boss_hp={"invalid":1}
    assert_false(s.restore(bad))
    assert_eq(s.snapshot(),before)
