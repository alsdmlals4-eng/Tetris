extends GutTest

const PATH="res://src/replanned_r3/r3_pair_board.gd"

func board(seed_value: int=100):
    assert_true(ResourceLoader.exists(PATH),"R3 finite falling pair model exists")
    return load(PATH).new(seed_value,"test") if ResourceLoader.exists(PATH) else null

func tick(b, duration: int) -> Array:
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

func test_spawn_queue_and_falling_state_do_not_reroll_on_restore():
    var b=board()
    if b==null: return
    var next=b.next_pair_kinds()
    assert_true(b.spawn("p1").success)
    assert_eq(b.active_pair.axis.kind,next[0])
    assert_eq(b.active_pair.satellite.kind,next[1])
    assert_eq(b.active_pair.axis.y,-1)
    assert_eq(b.active_pair.satellite.y,-2)
    b.advance_time(300000)
    var saved=b.snapshot()
    var restored=board(999)
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(saved))))
    assert_eq(restored.snapshot(),saved)
    assert_false(restored.spawn("p1").success)
    assert_eq(restored.snapshot(),saved)
    tick(b,2100000)
    for i in 7: tick(restored,300000)
    assert_eq(restored.snapshot(),b.snapshot())

func test_wall_ceiling_rotation_order_and_failed_input_are_atomic():
    var b=board()
    if b==null: return
    b.spawn("p1")
    b.command("move",{"dx":-1})
    b.command("move",{"dx":-1})
    assert_true(b.command("rotate",{"direction":-1}).success)
    assert_eq(b.active_pair.axis.x,1,"left-pointing satellite kicks right at wall")
    assert_eq(b.active_pair.satellite.x,0)
    var saved=b.snapshot()
    assert_false(b.command("move",{"dx":-2}).success)
    assert_false(b.command("hold",{}).success)
    assert_eq(b.snapshot(),saved)
    # DOWN orientation at the ceiling must kick only inside the two hidden rows.
    assert_true(b.command("rotate",{"direction":-1}).success)
    assert_gte(b.active_pair.axis.y,-2)
    assert_gte(b.active_pair.satellite.y,-2)

func test_grounded_move_resets_only_eight_times_and_hard_drop_locks():
    var b=board()
    if b==null: return
    b.spawn("p1")
    tick(b,8400000)
    assert_eq(b.active_pair.axis.y,11)
    for i in 8:
        b.advance_time(10000)
        assert_true(b.command("move",{"dx":1 if i%2==0 else -1}).success)
        assert_eq(b.lock_remaining_us,500000)
    b.advance_time(10000)
    b.command("move",{"dx":1})
    assert_eq(b.lock_reset_count,8)
    assert_eq(b.lock_remaining_us,490000)
    assert_true(b.command("hard_drop",{"category":"DEF"}).success)
    assert_eq(b.phase,"LOCKED_SETTLE")
    tick(b,0)
    assert_eq(b.cells.size(),2)
    assert_true(b.active_pair.is_empty())

func test_bag_produces_two_each_kind_per_four_pairs_and_ids_never_reuse():
    var b=board()
    if b==null: return
    var counts={"A":0,"D":0,"H":0,"T":0}
    var ids=[]
    for i in 4:
        assert_true(b.spawn("p"+str(i)).success)
        counts[b.active_pair.axis.kind]+=1
        counts[b.active_pair.satellite.kind]+=1
        assert_false(b.active_pair.axis.cell_id in ids)
        ids.append(b.active_pair.axis.cell_id)
        ids.append(b.active_pair.satellite.cell_id)
        b.command("move",{"dx":-1 if i%2==0 else 1})
        b.command("hard_drop",{"category":"ATK"})
        tick(b,1000000)
    assert_eq(counts,{"A":2,"D":2,"H":2,"T":2})

func test_forged_plan_and_malformed_restore_do_not_change_state():
    var b=board()
    if b==null: return
    b.spawn("p1")
    b.command("hard_drop",{"category":"SUP"})
    var plan=b.plan_due_event()
    var saved=b.snapshot()
    var bad=plan.duplicate(true)
    bad.category="ATK"
    assert_false(b.commit(bad).success)
    assert_eq(b.snapshot(),saved)
    assert_true(b.commit(plan).success)
    saved=b.snapshot()
    assert_false(b.commit(plan).success)
    for field in ["cells","next_pairs","bag","active_pair"]:
        bad=saved.duplicate(true)
        bad[field]=null
        assert_false(b.restore(bad))
        assert_eq(b.snapshot(),saved)
    bad=saved.duplicate(true)
    bad.cells.append(bad.cells[0].duplicate())
    assert_false(b.restore(bad))
    assert_eq(b.snapshot(),saved)

func test_spawn_blocked_returns_single_topout_without_queue_refill():
    var b=board()
    if b==null: return
    b.cells=[{"cell_id":"fixture:1","x":2,"y":-1,"kind":"A"}]
    var queue=b.snapshot().next_pairs
    assert_eq(b.spawn("blocked").reason,"TOP_OUT")
    var plan=b.plan_due_event()
    assert_eq(plan.type,"TOP_OUT")
    var result=b.commit(plan)
    assert_true(result.success)
    assert_eq(result.type,"TOP_OUT")
    assert_true(b.cells.is_empty())
    assert_eq(b.snapshot().next_pairs,queue)
    assert_false(b.commit(plan).success)
    assert_true(b.plan_due_event().is_empty())

func test_restore_rejects_id_reuse_false_reservations_and_impossible_phase():
    var b=board()
    if b==null: return
    b.spawn("p1")
    b.command("hard_drop",{})
    tick(b,0)
    var saved=b.snapshot()
    for mutation in ["counter","phase","cell_namespace","cleared","bag","timer"]:
        var bad=saved.duplicate(true)
        match mutation:
            "counter": bad.next_cell_id=0
            "phase": bad.phase="CLEAR_PENDING"; bad.reserved_clear_ids=[bad.cells[0].cell_id,bad.cells[1].cell_id,"fake1","fake2"]
            "cell_namespace": bad.cells[0].cell_id="another-battle:cell:1"
            "cleared": bad.cleared=[{"cell_id":"test:cell:3","x":0,"y":0,"kind":"A"}]
            "bag": bad.bag=["A"]
            "timer": bad.wave_remaining_us=100
        assert_false(b.restore(bad),mutation)
        assert_eq(b.snapshot(),saved,mutation+" must fail without mutation")

func test_soft_drop_and_rotation_kicks_respect_first_valid_candidate():
    var b=board()
    if b==null: return
    b.spawn("p1")
    assert_true(b.command("soft_drop",{"enabled":true}).success)
    tick(b,49999)
    assert_eq(b.active_pair.axis.y,-1)
    tick(b,1)
    assert_eq(b.active_pair.axis.y,0)
    # Zero kick blocked to the right; left must be preferred over right/up.
    b.cells=[{"cell_id":"obstacle","x":3,"y":0,"kind":"A"}]
    assert_true(b.command("rotate",{"direction":1}).success)
    assert_eq(b.active_pair.axis.x,1)
    assert_eq(b.active_pair.axis.y,0)
    assert_eq(b.active_pair.satellite.x,2)
    var saved=b.snapshot()
    b.cells.append({"cell_id":"left","x":0,"y":0,"kind":"D"})
    assert_eq(b.ghost_cells().size(),2)
    assert_eq(saved.active_pair.orientation,1)

func test_no_supply_is_a_session_gate_and_board_does_not_autospawn():
    var b=board()
    if b==null: return
    var supply=load("res://src/replanned_r3/r3_pair_supply.gd").new()
    for i in 4: supply.consume("spent"+str(i))
    var before=b.snapshot()
    if supply.pairs>0: b.spawn("must-not-spawn")
    tick(b,99999999)
    assert_eq(b.snapshot(),before)
    assert_eq(supply.pairs,0)

func test_soft_drop_release_during_settlement_does_not_latch_next_pair():
    var b=board()
    if b==null: return
    b.spawn("p1")
    b.command("soft_drop",{"enabled":true})
    b.command("hard_drop",{})
    assert_true(b.command("soft_drop",{"enabled":false}).success)
    tick(b,600000)
    assert_true(b.spawn("p2").success)
    tick(b,50000)
    assert_eq(b.active_pair.axis.y,-1,"released soft drop must use normal gravity on next pair")

func test_every_phase_json_restore_and_seeded_commands_remain_deterministic():
    for seed_value in 20:
        var b=board(seed_value)
        if b==null: return
        var restored=board(9000)
        for pair_number in 12:
            assert_true(b.spawn("p"+str(pair_number)).success)
            b.command("move",{"dx":1 if pair_number%2==0 else -1})
            b.command("rotate",{"direction":1 if pair_number%3==0 else -1})
            b.advance_time(12345)
            assert_true(restored.restore(JSON.parse_string(JSON.stringify(b.snapshot()))))
            assert_eq(restored.snapshot(),b.snapshot())
            b.command("hard_drop",{"category":"ATK"})
            for guard in 150:
                var due=b.next_event_us()
                if due<0: break
                assert_true(restored.restore(JSON.parse_string(JSON.stringify(b.snapshot()))))
                assert_eq(restored.snapshot(),b.snapshot())
                b.advance_time(due)
                restored.advance_time(due)
                var before=b.cells.size()
                var plan=b.plan_due_event()
                var result=b.commit(plan)
                assert_true(result.success)
                assert_eq(restored.commit(restored.plan_due_event()),result)
                assert_eq(restored.snapshot(),b.snapshot())
                if plan.type=="CLEAR_CELLS": assert_lte(b.cells.size(),before-4)
                elif plan.type!="LOCK_PAIR": assert_lte(b.cells.size(),before)
