extends GutTest

const PATH="res://src/replanned_r3/r3_pair_board.gd"

func board(seed_value: int=100):
    assert_true(ResourceLoader.exists(PATH),"R3 finite falling pair model exists")
    return load(PATH).new(seed_value,"test") if ResourceLoader.exists(PATH) else null

func tick(b,duration: int) -> Array:
    var events=[]
    var remaining=duration
    for guard in 512:
        var due=b.next_event_us()
        if due<0 or due>remaining:
            b.advance_time(remaining)
            break
        b.advance_time(due)
        remaining-=due
        var plan=b.plan_due_event()
        if plan.is_empty(): break
        events.append(b.commit(plan))
    return events

func fixture(b, lines: Array):
    b.cells=[]
    var next_id=0
    for row in lines.size():
        for x in 6:
            if lines[row][x]==".": continue
            next_id+=1
            b.cells.append({"cell_id":"test:cell:"+str(next_id),"x":x,"y":12-lines.size()+row,"kind":lines[row][x]})
    b._next_cell_id=next_id

func begin_fixture(b, category: String="ATK"):
    # Existing fixed cells are an independent hand-authored puzzle fixture.
    b.spawn("fixture-pair")
    b.active_pair.axis.kind="H"
    b.active_pair.satellite.kind="T"
    b.command("move",{"dx":1})
    b.command("move",{"dx":1})
    b.command("move",{"dx":1})
    b.command("hard_drop",{"category":category})
    tick(b,0)

func test_orthogonal_l_group_clears_but_diagonal_and_three_do_not():
    var b=board()
    if b==null: return
    fixture(b,["A.....","AAA..."])
    assert_eq(b.matched_cells().size(),4)
    fixture(b,["A.....",".A....","..A...","...A.."])
    assert_true(b.matched_cells().is_empty())
    fixture(b,["A.....","AA...."])
    assert_true(b.matched_cells().is_empty())

func test_simultaneous_groups_one_wave_no_refill_and_category_locked():
    var b=board()
    if b==null: return
    fixture(b,["AA.DD.","AA.DD."])
    begin_fixture(b,"DEF")
    assert_eq(b.phase,"CLEAR_PENDING")
    assert_eq(b.target_candidates().size(),2,"reserved clear IDs cannot be targeted")
    assert_false(b.command("category",{"category":"ATK"}).success)
    var events=tick(b,300000)
    var waves=events.filter(func(e): return e.get("type")=="WAVE_RESOLVED")
    assert_eq(waves.size(),1)
    assert_eq(waves[0].cells.size(),8)
    assert_eq(waves[0].category,"DEF")
    assert_eq(waves[0].wave,1)
    assert_eq(b.cells.size(),2,"only the dropped pair survives; no refill")
    assert_eq(b.phase,"NEED_PAIR")

func test_horizontal_pair_splits_down_unequal_columns():
    var b=board()
    if b==null: return
    fixture(b,["..A...","..D...","..H..."])
    b.spawn("p1")
    b.command("rotate",{"direction":1})
    var axis_id=b.active_pair.axis.cell_id
    var satellite_id=b.active_pair.satellite.cell_id
    b.command("hard_drop",{"category":"ATK"})
    tick(b,0)
    var positions={}
    for c in b.cells: positions[c.cell_id]=c.y
    assert_eq(positions[axis_id],8)
    assert_eq(positions[satellite_id],11)

func test_two_wave_fixture_split_and_large_ticks_have_same_snapshot():
    var a=board()
    if a==null: return
    # A4 removes supports, two H pairs join into H4 after gravity.
    fixture(a,["HH....","AA....","AAHH.."])
    begin_fixture(a,"SUP")
    var b=board(999)
    assert_true(b.restore(JSON.parse_string(JSON.stringify(a.snapshot()))))
    var events=tick(a,600000)
    for i in 6: tick(b,100000)
    assert_eq(a.snapshot(),b.snapshot())
    var waves=events.filter(func(e): return e.get("type")=="WAVE_RESOLVED")
    assert_eq(waves.size(),2)
    assert_eq(waves[0].wave,1)
    assert_eq(waves[1].wave,2)
    assert_eq(waves[1].category,"SUP")
    assert_eq(a.cells.size(),2)

func test_enemy_settle_preserves_active_pair_and_has_no_player_wave():
    var b=board()
    if b==null: return
    fixture(b,["HH....","DA....","ADHH.."])
    b.spawn("p1")
    b.advance_time(123456)
    var pair=b.active_pair.duplicate(true)
    var gravity=b.gravity_remaining_us
    var ids=[]
    for c in b.cells:
        if c.kind in ["A","D"]: ids.append(c.cell_id)
    var plan=b.plan_disruption("enemy1",ids)
    assert_true(b.commit(plan).success)
    var events=tick(b,300000)
    assert_eq(b.active_pair,pair)
    assert_eq(b.gravity_remaining_us,gravity)
    assert_eq(b.cells.size(),0)
    for event in events:
        assert_ne(event.get("cause"),"PLAYER_LOCK")
        assert_false(event.get("reward_eligible",false))
    assert_eq(b.phase,"FALLING")

func test_hidden_survivors_topout_after_rescue_opportunity():
    var b=board()
    if b==null: return
    var lines=[]
    for y in 14: lines.append("A....." if y%2==0 else "D.....")
    fixture(b,lines)
    begin_fixture(b)
    var events=tick(b,0)
    assert_true(b.cells.is_empty(),"stable hidden survivors overflow")
    assert_eq(b.phase,"NEED_PAIR")
    assert_true(events.is_empty(),"initial zero tick already committed overflow once")

func test_hidden_match_can_rescue_before_topout_and_wave_cap_stops_without_refill():
    var b=board()
    if b==null: return
    var lines=[]
    for y in 14: lines.append("A.....")
    fixture(b,lines)
    begin_fixture(b)
    assert_eq(b.phase,"CLEAR_PENDING")
    var events=tick(b,300000)
    assert_eq(events.filter(func(e):return e.type=="TOP_OUT").size(),0)
    assert_eq(b.cells.size(),2)
    fixture(b,["AA....","AA...."])
    b.wave_index=21
    b.phase="LOCKED_SETTLE"
    b.category_snapshot="ATK"
    var before=b.cells.duplicate(true)
    var result=b.commit(b.plan_due_event())
    assert_true(result.success)
    assert_eq(b.phase,"ERROR")
    assert_eq(b.error,"MAX_WAVES_EXCEEDED")
    assert_eq(b.cells,before)
    assert_eq(b.next_event_us(),-1)
    assert_false(result.reward_eligible)

func test_disruption_interrupts_only_after_current_wave_and_ends_player_chain():
    var b=board()
    if b==null: return
    fixture(b,["HH....","AA....","AAHH.."])
    begin_fixture(b)
    var pair=b.target_candidates().filter(func(c):return c.x==5)
    var target_ids=[pair[0].cell_id]
    assert_true(b.plan_disruption("enemy1",target_ids).is_empty())
    b.advance_time(180000)
    assert_true(b.commit(b.plan_due_event()).success)
    assert_eq(b.phase,"FALL_SETTLE")
    assert_true(b.plan_disruption("enemy1",target_ids).is_empty())
    var restored=board(999)
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(b.snapshot()))))
    assert_eq(restored.snapshot(),b.snapshot())
    b.advance_time(120000)
    var wave=b.commit(b.plan_due_event())
    assert_eq(wave.wave,1)
    assert_true(wave.reward_eligible)
    assert_true(b.commit(b.plan_disruption("enemy1",target_ids)).success)
    var events=tick(b,300000)
    var waves=events.filter(func(e):return e.type=="WAVE_RESOLVED")
    assert_eq(waves.size(),1)
    assert_eq(waves[0].cause,"ENEMY_SETTLE")
    assert_false(waves[0].reward_eligible)
    assert_true(b.plan_disruption("enemy1",target_ids).is_empty())

func test_forged_clear_reservation_and_active_pair_history_restore_rejected():
    var b=board()
    if b==null: return
    fixture(b,["AA....","AA...."])
    begin_fixture(b)
    var saved=b.snapshot()
    var bad=saved.duplicate(true)
    bad.reserved_clear_ids[0]=b.target_candidates()[0].cell_id
    assert_false(b.restore(bad),"four arbitrary IDs cannot become a reward wave")
    assert_eq(b.snapshot(),saved)
    b=board()
    b.spawn("p1")
    saved=b.snapshot()
    bad=saved.duplicate(true)
    bad.spawn_ids=[]
    assert_false(b.restore(bad))
    assert_eq(b.snapshot(),saved)

func test_terminal_finalization_freezes_falling_clear_and_settle_without_effects():
    for starting_phase in ["FALLING","CLEAR_PENDING","FALL_SETTLE"]:
        var b=board()
        if b==null:return
        assert_true(b.has_method("finalize_terminal"),"Session needs an explicit effect-free terminal board API")
        if not b.has_method("finalize_terminal"):continue
        if starting_phase=="FALLING":
            b.spawn("p1")
            b.command("soft_drop",{"enabled":true})
            b.advance_time(12345)
        else:
            fixture(b,["HH....","AA....","AAHH.."])
            begin_fixture(b,"SUP")
            if starting_phase=="FALL_SETTLE":
                b.advance_time(180000)
                b.commit(b.plan_due_event())
        b.advance_time(b.next_event_us())
        var before=b.snapshot()
        var stale=b.plan_due_event()
        assert_false(stale.is_empty(),"a cached due plan must become unusable after terminal finalization")
        var result=b.finalize_terminal()
        assert_true(result.success)
        assert_false(result.get("reward_eligible",false))
        assert_eq(b.phase,"TERMINAL")
        assert_eq(b.cells,before.cells,"finalization preserves currently visible settled cells without gravity/refill")
        assert_eq(b.active_pair,before.active_pair)
        assert_eq(b.snapshot().next_pairs,before.next_pairs)
        assert_eq(b.snapshot().rng_state,before.rng_state)
        assert_eq(b.reserved_clear_ids,[])
        assert_eq(b.snapshot().cleared,[])
        assert_eq(b.wave_index,0)
        assert_eq(b.wave_remaining_us,0)
        assert_eq(b.category_snapshot,"")
        assert_eq(b.next_event_us(),-1)
        assert_false(b.is_resolving())
        assert_true(b.plan_due_event().is_empty())
        assert_true(b.plan_disruption("late-enemy",[]).is_empty())
        var frozen=b.snapshot()
        assert_false(b.command("move",{"dx":1}).success)
        assert_false(b.command("soft_drop",{"enabled":false}).success)
        assert_false(b.spawn("late-pair").success)
        assert_false(b.commit(stale).success)
        assert_eq(tick(b,99999999),[])
        assert_true(b.finalize_terminal().success,"terminal finalization is idempotent")
        assert_eq(b.snapshot(),frozen)
        var restored=board(999)
        assert_true(restored.restore(JSON.parse_string(JSON.stringify(frozen))))
        assert_eq(restored.snapshot(),frozen)
        assert_eq(tick(restored,99999999),[])

func test_terminal_restore_preserves_hidden_matches_but_rejects_pending_effect_state():
    var b=board()
    if b==null:return
    assert_true(b.has_method("finalize_terminal"))
    if not b.has_method("finalize_terminal"):return
    var lines=[]
    for y in 14:lines.append("A.....")
    fixture(b,lines)
    begin_fixture(b)
    assert_eq(b.phase,"CLEAR_PENDING")
    assert_eq(b.cells.size(),16)
    b.finalize_terminal()
    var frozen=b.snapshot()
    var restored=board(999)
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(frozen))))
    assert_eq(restored.cells,frozen.cells)
    assert_eq(restored.matched_cells().size(),14)
    assert_eq(restored.rows()[0],"A.....")
    for field in ["wave_index","wave_remaining_us","category_snapshot","reserved_clear_ids","cleared","soft_drop"]:
        var bad=frozen.duplicate(true)
        match field:
            "wave_index":bad.wave_index=1
            "wave_remaining_us":bad.wave_remaining_us=1
            "category_snapshot":bad.category_snapshot="ATK"
            "reserved_clear_ids":bad.reserved_clear_ids=[frozen.cells[0].cell_id]
            "cleared":bad.cleared=[frozen.cells[0]]
            "soft_drop":bad.soft_drop=true
        assert_false(restored.restore(bad),field+" may not restore outstanding terminal effects")
        assert_eq(restored.snapshot(),frozen)
