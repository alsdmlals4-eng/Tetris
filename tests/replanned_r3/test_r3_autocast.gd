extends GutTest

const Session=preload("res://src/replanned_r3/r3_session.gd")
const Piece=preload("res://src/production/line/active_tetromino.gd")

func session():
    return Session.new("STANDARD",42,"r3:autocast-test","watchtower")

func chain_fixture(s,lines:Array):
    s.chain.cells=[]
    var ordinal=0
    for row in lines.size():
        for x in 6:
            if lines[row][x]==".":continue
            ordinal+=1
            s.chain.cells.append({"cell_id":s._run_id+":chain:cell:"+str(ordinal),"x":x,"y":12-lines.size()+row,"kind":lines[row][x]})
    s.chain._next_cell_id=ordinal

func drop_isolated_pair(s):
    assert_true(s.command("switch").success)
    # Independent H/T pair isolates authored groups from the random NEXT colors.
    s.chain.active_pair.axis.kind="H"
    s.chain.active_pair.satellite.kind="T"
    for i in 3:assert_true(s.command("move",{"dx":1}).success)
    assert_true(s.command("hard_drop").success)

func effects(events:Array,effect:String)->Array:
    return events.filter(func(e):return e.get("effect")==effect)

func test_line_six_attack_four_defense_gives_resources_and_three_pairs_once():
    var s=session()
    s.combat.attack_bank=0
    s.combat.armor=0
    s.supply.consume("fixture-consumed-1")
    s.supply.consume("fixture-consumed-2")
    var engine=s.line._engine
    for x in 6:
        engine.board.set_cell(Vector2i(x,23),"A")
        s.line._cells.append({"cell_id":s._run_id+":line:"+str(x+1),"x":x,"y":23,"kind":"A"})
    s.line._sequence=6
    engine.active=Piece.new("I",Vector2i(6,0),engine.catalog)
    engine.active_resource="D"
    var result=s.command("hard_drop")
    assert_true(result.success)
    assert_eq(s.combat.attack_bank,6)
    assert_eq(s.combat.armor,4)
    assert_eq(s.supply.pairs,5)
    assert_eq(s.metrics.line_clears,1)
    assert_eq(effects(result.events,"LINE_RESOURCES_APPLIED").size(),1)
    var eta=s.combat.eta_us
    s.tick(1)
    assert_eq(s.supply.pairs,5,"time must not replay the same LINE credit")
    assert_eq(s.combat.eta_us,eta-1)
    assert_true(s.command("switch").success)
    assert_eq(s.supply.pairs,4,"one successful spawn consumes one pair")

func test_simultaneous_four_attack_four_defense_is_one_cast_at_300ms():
    var s=session()
    s.combat.attack_bank=0
    s.combat.boss_hp=100
    chain_fixture(s,["AA.DD.","AA.DD."])
    drop_isolated_pair(s)
    assert_eq(s.chain.reserved_clear_ids.size(),8)
    s.tick(299999)
    assert_eq(s.combat.boss_hp,100)
    assert_eq(s.metrics.casts,0)
    var events=s.tick(1)
    var casts=effects(events,"ATK_DAMAGE")
    assert_eq(casts.size(),1)
    assert_eq(casts[0].wave,1)
    assert_eq(casts[0].damage_applied,4)
    assert_eq(s.combat.boss_hp,96)
    assert_eq(s.metrics.casts,1)

func test_two_wave_chain_spends_attack_bank_only_on_first_wave():
    var s=session()
    s.combat.attack_bank=6
    s.combat.boss_hp=100
    chain_fixture(s,["HH....","AA....","AAHH.."])
    drop_isolated_pair(s)
    var events=s.tick(600000)
    var casts=effects(events,"ATK_DAMAGE")
    assert_eq(casts.size(),2)
    assert_eq(casts[0].damage_applied,10)
    assert_eq(casts[0].bank_consumed,6)
    assert_eq(casts[1].damage_applied,6)
    assert_eq(casts[1].bank_consumed,0)
    assert_eq(s.combat.boss_hp,84)
    assert_eq(s.combat.attack_bank,0)
    assert_eq(s.metrics.max_combo,2)
    assert_eq(s.chain.cells.size(),2,"only the isolated dropped pair remains; no refill")

func test_category_selected_while_falling_locks_at_placement_for_entire_chain():
    var s=session()
    s.combat.hp=50
    s.combat.boss_hp=100
    chain_fixture(s,["HH....","AA....","AAHH.."])
    assert_true(s.command("category",{"category":"DEF"}).success)
    assert_true(s.command("switch").success)
    assert_true(s.command("category",{"category":"SUP"}).success)
    s.chain.active_pair.axis.kind="H"
    s.chain.active_pair.satellite.kind="T"
    for i in 3:s.command("move",{"dx":1})
    assert_true(s.command("hard_drop").success)
    assert_false(s.command("category",{"category":"ATK"}).success)
    assert_eq(s.selected_category,"SUP")
    var events=s.tick(600000)
    assert_eq(effects(events,"SUP_HEAL").size(),2)
    assert_eq(s.combat.hp,55,"SUP C1=2, C2=3")
    assert_eq(s.combat.boss_hp,100)
    assert_eq(s.last_cast.category,"SUP")
    assert_true(s.command("category",{"category":"DEF"}).success)

func test_boss_lethal_damage_at_same_microsecond_prevents_sup_heal():
    var s=session()
    s.combat.hp=1
    s.combat.armor=0
    s.combat.ward=0
    s.combat.eta_us=300000
    chain_fixture(s,["AA....","AA...."])
    assert_true(s.command("category",{"category":"SUP"}).success)
    drop_isolated_pair(s)
    var events=s.tick(300000)
    assert_eq(effects(events,"ENEMY_ACTION_RESOLVED").size(),1)
    assert_eq(effects(events,"SUP_HEAL").size(),0)
    assert_eq(s.metrics.casts,0)
    assert_eq(s.combat.hp,0)
    assert_eq(s.combat.outcome,"DEFEAT")

func test_invalid_category_and_tier_inspection_cannot_mutate_placement_or_resources():
    var s=session()
    assert_true(s.command("category",{"category":"DEF"}).success)
    assert_true(s.command("switch").success)
    var before=s.snapshot()
    assert_false(s.command("category",{"category":"T6"}).success)
    assert_false(s.command("tier",{"tier":6}).success)
    assert_eq(s.snapshot(),before)
