extends GutTest

const Session=preload("res://src/replanned_r3/r3_session.gd")

func session(profile:String="watchtower"):
    return Session.new("STANDARD",42,"r3:disruption-test",profile)

func chain_fixture(s,lines:Array):
    s.chain.cells=[]
    var ordinal=0
    for row in lines.size():
        for x in 6:
            if lines[row][x]==".":continue
            ordinal+=1
            s.chain.cells.append({"cell_id":s._run_id+":chain:cell:"+str(ordinal),"x":x,"y":12-lines.size()+row,"kind":lines[row][x]})
    s.chain._next_cell_id=ordinal

func arm_tracking_shot(s,target_board:String,eta:int,ids:Array=[]):
    # Hand-authored Current tracking-shot fixture: HP8, two targets, normal ETA8s.
    s.combat.action_index=1
    s.combat.eta_us=eta
    s.disruption._reservation={"action_id":s.combat.action_id(),"target_board":target_board,
        "count":2,"reserved":not ids.is_empty(),"target_ids":ids.duplicate()}

func setup_player_chain(s):
    chain_fixture(s,["HH....","AA....","AAHH.."])
    assert_true(s.command("switch").success)
    s.chain.active_pair.axis.kind="H"
    s.chain.active_pair.satellite.kind="T"
    for i in 3:s.command("move",{"dx":1})
    return s.chain.active_pair.satellite.cell_id

func test_current_target_board_is_fixed_through_switch_and_eta_reservation():
    var s=session()
    assert_true(s.command("hard_drop").success)
    var before=s.line.target_candidates()
    assert_eq(before.size(),4)
    arm_tracking_shot(s,"LINE",2000000)
    assert_true(s.command("switch").success)
    s.tick(1)
    var preview=s.disruption.preview()
    assert_eq(preview.target_board,"LINE")
    assert_eq(preview.target_ids.size(),2)
    var selected_ids=preview.target_ids.duplicate()
    var pair_before=s.chain.active_pair.duplicate(true)
    var events=s.tick(1999999)
    assert_eq(s.line.target_candidates().size(),2)
    for c in s.line.target_candidates():
        assert_false(c.cell_id in selected_ids)
        assert_true(c in before,"LINE destruction must not compact survivor coordinates")
    assert_eq(s.chain.active_pair.id,pair_before.id)
    assert_eq(s.metrics.destroyed,2)
    assert_eq(events.filter(func(e):return e.get("origin")=="ENEMY_DESTROY").size(),1)

func test_committed_disruption_waits_for_wave_then_stops_future_paid_chain():
    var s=session()
    s.combat.hp=100
    s.combat.armor=0
    s.combat.ward=0
    s.combat.attack_bank=6
    s.combat.boss_hp=100
    var target=setup_player_chain(s)
    assert_true(s.command("hard_drop").success)
    var supply_before=s.supply.pairs
    arm_tracking_shot(s,"CHAIN",150000,[target])
    var events=s.tick(150000)
    assert_eq(s.combat.hp,92,"HP8 commits at its deadline during CLEAR_PENDING")
    assert_eq(s.combat.boss_hp,100,"the 300ms player wave has not resolved yet")
    assert_eq(s.metrics.casts,0)
    assert_eq(s.metrics.destroyed,0,"board destruction waits for the atomic wave boundary")
    assert_eq(s._pending.size(),1)
    events.append_array(s.tick(450000))
    var casts=events.filter(func(e):return e.get("effect")=="ATK_DAMAGE")
    assert_eq(casts.size(),1)
    assert_eq(casts[0].damage_applied,10,"already committed C1+bank remains paid")
    assert_eq(s.combat.boss_hp,90,"H4 formed by settling must not pay C2")
    assert_eq(s.combat.attack_bank,0)
    assert_eq(s.combat.hp,92,"HP8 deadline cannot wait for clear animation")
    assert_eq(s.metrics.casts,1)
    assert_eq(s.metrics.destroyed,1)
    assert_eq(s.supply.pairs,supply_before-1,"only the one automatic post-stability spawn consumes supply")
    assert_eq(s.chain.cells.size(),1)
    var enemy_waves=events.filter(func(e):return e.get("type")=="WAVE_RESOLVED" and e.get("cause")=="ENEMY_SETTLE")
    assert_eq(enemy_waves.size(),1)
    assert_false(enemy_waves[0].reward_eligible)

func test_committed_destruction_still_applies_when_current_wave_kills_boss():
    var s=session()
    s.combat.hp=100
    s.combat.armor=0
    s.combat.ward=0
    s.combat.attack_bank=0
    s.combat.boss_hp=4
    var target=setup_player_chain(s)
    assert_true(s.command("hard_drop").success)
    arm_tracking_shot(s,"CHAIN",150000,[target])
    s.tick(300000)
    assert_eq(s.combat.outcome,"VICTORY")
    assert_eq(s.combat.hp,92)
    assert_eq(s.metrics.casts,1)
    assert_eq(s.metrics.destroyed,1,"already committed enemy effect survives boss death while player lives")
    for cell in s.chain.cells:assert_ne(cell.cell_id,target)
    assert_true(s._pending.is_empty(),"committed destruction must not be abandoned by terminal guard")
    assert_true(s.can_checkpoint())
    assert_eq(s.chain.phase,"TERMINAL")
    assert_true(s.disruption.preview().is_empty())

func test_enemy_created_four_group_has_no_skill_supply_or_direct_resources():
    var s=session()
    s.combat.hp=100
    s.combat.armor=0
    s.combat.ward=0
    s.combat.attack_bank=6
    s.combat.boss_hp=100
    chain_fixture(s,["HH....","ADHH.."])
    assert_true(s.command("switch").success)
    # Destruction removes the bottom A/D supports; upper H2 joins the bottom H2.
    var targets=[]
    for c in s.chain.cells:
        if c.kind in ["A","D"]:targets.append(c.cell_id)
    arm_tracking_shot(s,"CHAIN",1,targets)
    var pair_before=s.chain.active_pair.duplicate(true)
    var supply_before=s.supply.snapshot()
    var events=s.tick(300001)
    assert_eq(s.metrics.casts,0)
    assert_eq(s.combat.boss_hp,100)
    assert_eq(s.combat.attack_bank,6)
    assert_eq(s.combat.armor,0)
    assert_eq(s.combat.hp,92)
    assert_eq(s.supply.snapshot(),supply_before)
    assert_eq(s.chain.active_pair,pair_before)
    assert_eq(s.chain.gravity_remaining_us,699999,"active pair advances the 1us before enemy commit, then freezes for settlement")
    assert_eq(events.filter(func(e):return e.get("type")=="WAVE_RESOLVED").size(),1)

func test_outer_breach_and_ordinary_watchtower_shot_do_not_destroy_blocks():
    for profile in ["outer_breach","watchtower"]:
        var s=session(profile)
        assert_true(s.command("hard_drop").success)
        var count=s.line.target_candidates().size()
        s.combat.eta_us=1
        s.tick(1)
        assert_eq(s.metrics.destroyed,0,profile+" first action has no authored destruction")
        assert_eq(s.line.target_candidates().size(),count)
