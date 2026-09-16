extends GutTest
const PATH="res://src/replanned_r3/r3_session.gd"
func session():
    assert_true(ResourceLoader.exists(PATH))
    return load(PATH).new("STANDARD",42,"r3:test") if ResourceLoader.exists(PATH) else null

func test_chain_supply_is_finite_and_swap_input_is_retired():
    var s=session()
    if s==null: return
    assert_eq(s.supply.pairs,4)
    assert_true(s.command("switch").success)
    assert_eq(s.supply.pairs,3)
    assert_false(s.command("chain_swap",{"from":[0,0],"to":[1,0]}).success)
    for i in 4:
        assert_true(s.command("hard_drop").success)
        s.tick(1000000)
    assert_eq(s.supply.pairs,0)
    assert_true(s.chain.active_pair.is_empty())
    assert_eq(s.mode,"CHAIN")
    var eta=s.combat.eta_us
    s.tick(100000)
    assert_eq(s.combat.eta_us,eta-100000)

func test_inactive_fall_and_pause_do_not_advance_but_shared_eta_does():
    var s=session()
    if s==null: return
    var before=s.line.snapshot()
    s.command("switch")
    s.tick(300000)
    assert_eq(s.line.snapshot(),before)
    s.command("pause")
    var paused=s.snapshot()
    s.tick(5000000)
    assert_eq(s.snapshot(),paused)

func test_split_tick_and_saved_resume_match_exact_state():
    var a=session()
    var b=session()
    if a==null or b==null: return
    a.command("switch")
    b.command("switch")
    a.tick(2100000)
    for i in 7: b.tick(300000)
    assert_eq(a.snapshot(),b.snapshot())
    var saved=a.snapshot()
    var c=session()
    assert_true(c.restore(JSON.parse_string(JSON.stringify(saved))))
    a.tick(900000)
    c.tick(900000)
    for key in a.snapshot():
        assert_eq(c.snapshot()[key],a.snapshot()[key],"resume field: "+key)
    assert_eq(c.snapshot(),a.snapshot())
    var before=c.snapshot()
    var bad=before.duplicate(true)
    bad.schema="r2-save-v1"
    assert_false(c.restore(bad))
    assert_eq(c.snapshot(),before)

func test_terminal_and_long_elapsed_save_remain_restorable():
    var s=session()
    if s==null:return
    s.elapsed_simulation_us=3600000000
    var long_state=s.snapshot()
    assert_true(s.restore(JSON.parse_string(JSON.stringify(long_state))))
    s.command("switch")
    s.combat.hp=1
    s.combat.armor=0
    s.combat.ward=0
    s.combat.eta_us=1
    s.tick(1)
    assert_eq(s.combat.outcome,"DEFEAT")
    assert_true(s.can_checkpoint())
    assert_eq(s.chain.phase,"TERMINAL")
    assert_true(s.disruption.preview().is_empty())
    assert_true(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))))

func test_component_mashups_reject_without_mutation():
    var s=session()
    if s==null:return
    s.command("switch")
    var original=s.snapshot()
    var changes=[]
    var bad=original.duplicate(true)
    bad.category="SUP"
    changes.append(bad)
    bad=original.duplicate(true)
    bad.metrics.casts=1
    changes.append(bad)
    bad=original.duplicate(true)
    bad.last_cast={"category":"ATK"}
    changes.append(bad)
    bad=original.duplicate(true)
    bad.disruption.reservation.count=4
    changes.append(bad)
    bad=original.duplicate(true)
    bad.line=load("res://src/replanned_r3/r3_line.gd").new(43,"r3:test:line").snapshot()
    changes.append(bad)
    for value in changes:
        assert_false(s.restore(value))
        assert_eq(s.snapshot(),original)

func test_line_command_topout_closes_terminal_checkpoint():
    var s=session()
    if s==null:return
    s.combat.hp=1
    for cell in s.line.active_cells():
        s.line._engine.board.set_cell(Vector2i(cell[0],cell[1]),"A")
    assert_true(s.command("hard_drop").success)
    assert_eq(s.combat.outcome,"DEFEAT")
    assert_eq(s.chain.phase,"TERMINAL")
    assert_true(s.disruption.preview().is_empty())
    assert_true(s.restore(JSON.parse_string(JSON.stringify(s.snapshot()))))

func test_future_enemy_history_cannot_skip_later_attack():
    var s=session()
    if s==null:return
    var original=s.snapshot()
    var bad=original.duplicate(true)
    bad.disruption.completed=["r3:test:1000"]
    assert_false(s.restore(bad))
    assert_eq(s.snapshot(),original)
