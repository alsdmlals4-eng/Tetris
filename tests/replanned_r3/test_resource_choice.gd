extends GutTest
const Session=preload("res://src/replanned_r3/r3_session.gd")
const Rewards=preload("res://src/replanned_r3/resource_rewards.gd")
const Disk=preload("res://src/replanned_r3/r3_save.gd")

func test_fractional_credit_survives_restore_and_rejects_replays():
    var r=Rewards.new("test")
    assert_eq(r.credit("one",[{"id":"a1","kind":"A"}]).cells.size(),0)
    var copy=Rewards.new("test")
    assert_true(copy.restore(JSON.parse_string(JSON.stringify(r.snapshot()))))
    assert_eq(copy.credit("two",[{"id":"a2","kind":"A"}]).cells.size(),1)
    assert_eq(copy.total_units(),1)
    var before=copy.snapshot()
    assert_false(copy.credit("three",[{"id":"a2","kind":"A"}]).success)
    assert_eq(copy.snapshot(),before)

func test_swap_supply_and_save_roundtrip_after_real_clears():
    var s=Session.new()
    assert_true(s.command("prepare_resource",{"mode":"SWAP"}).success)
    for attempt in 12:
        if s.resource_rewards.total_units()>=10:break
        assert_true(s.command("resource_swap",_legal_move(s.swap)).success)
        _settle(s)
    assert_gte(s.resource_rewards.total_units(),10)
    assert_gte(s.supply.pairs,7,"ten normalized resource units replenish three pairs")
    assert_eq(s.metrics.casts,0)
    var state=JSON.parse_string(JSON.stringify(s.snapshot()))
    var restored=Session.new()
    assert_true(restored.restore(state),"swap and rewards resume via actual session validator")
    assert_eq(restored.snapshot(),s.snapshot())
    var disk=Disk.new("user://resource-choice-tests/save.json","user://resource-choice-tests/options.json")
    var written=disk.save_session(s)
    assert_true(written.success,str(written))
    var loaded=disk.load_checkpoint()
    assert_true(loaded.success,str(loaded))
    var invalid=state.duplicate(true)
    invalid.resource_mode="LINE"
    var before=restored.snapshot()
    assert_false(restored.restore(invalid))
    assert_eq(restored.snapshot(),before)

func test_pair_skills_work_with_swap_resource_selection():
    var s=Session.new()
    assert_true(s.command("prepare_resource",{"mode":"SWAP"}).success)
    s.combat.boss_hp=100
    s.combat.attack_bank=0
    s.chain.cells=[]
    for i in 4:s.chain.cells.append({"cell_id":s._run_id+":chain:cell:"+str(i+1),"x":i%2,"y":10+i/2,"kind":"A"})
    s.chain._next_cell_id=4
    assert_true(s.command("switch").success)
    s.chain.active_pair.axis.kind="H"
    s.chain.active_pair.satellite.kind="T"
    for i in 3:s.command("move",{"dx":1})
    s.command("hard_drop")
    s.tick(300000)
    assert_eq(s.metrics.casts,1)
    assert_eq(s.combat.boss_hp,96)
    assert_eq(s.resource_rewards.total_units(),0,"pair clears do not pay resource rewards")

func test_defeat_during_swap_cascade_is_checkpointable():
    var s=Session.new("STANDARD",42,"terminal","watchtower")
    s.command("prepare_resource",{"mode":"SWAP"})
    s.combat.hp=1
    s.combat.armor=0
    s.combat.ward=0
    s.combat.eta_us=1
    s.command("resource_swap",_legal_move(s.swap))
    s.tick(1)
    assert_eq(s.combat.outcome,"DEFEAT")
    assert_true(s.can_checkpoint(),"terminal state must not retain an unfinishable cascade")
    var restored=Session.new("STANDARD",42,"terminal","watchtower")
    assert_true(restored.restore(s.snapshot()))

func test_enemy_swap_destruction_never_rewards_and_cannot_repeat():
    var s=Session.new()
    s.command("prepare_resource",{"mode":"SWAP"})
    var cells=s.swap.target_candidates()
    var targets=[cells[0].cell_id,cells[1].cell_id]
    var supply=s.supply.snapshot()
    var reward=s.resource_rewards.snapshot()
    assert_true(s.swap.destroy_cells("enemy-test",targets).success)
    assert_eq(s.supply.snapshot(),supply)
    assert_eq(s.resource_rewards.snapshot(),reward)
    assert_eq(s.metrics.casts,0)
    assert_false(s.swap.destroy_cells("enemy-test",targets).success)

func _settle(s):
    for i in 65:
        if not s.swap.resolving:break
        s.tick(300000)

func test_actual_enemy_deadline_destroys_swap_cells_without_paying_resources():
    var s=Session.new("STANDARD",42,"enemy-live","watchtower")
    s.command("prepare_resource",{"mode":"SWAP"})
    var cycle=s.combat.action_cycle()
    # Advance real first and tracking actions; no forged disruption owner state.
    for i in 2:s.tick(s.combat.eta_us)
    assert_gt(s.metrics.destroyed,0)
    assert_eq(s.resource_rewards.total_units(),0)
    assert_eq(s.supply.pairs,4)
    assert_eq(s.metrics.casts,0)
    var copy=Session.new("STANDARD",42,"enemy-live","watchtower")
    assert_true(copy.restore(s.snapshot()))

func test_resource_choice_is_preparation_only():
    var s=Session.new()
    var chosen=s.command("prepare_resource",{"mode":"SWAP"})
    assert_true(chosen.success,"approved swap resource producer can be selected before combat")
    if not chosen.success:return
    s.tick(1)
    var before=s.snapshot()
    assert_false(s.command("prepare_resource",{"mode":"LINE"}).success)
    assert_eq(s.snapshot(),before,"mid-combat selection rejection is atomic")

func test_invalid_command_does_not_consume_preparation_permission():
    var s=Session.new()
    assert_false(s.command("category",{"category":"BAD"}).success)
    assert_true(s.command("prepare_resource",{"mode":"SWAP"}).success)

func test_live_cell_cannot_already_be_in_reward_history():
    var s=Session.new()
    s.command("prepare_resource",{"mode":"SWAP"})
    s.command("resource_swap",_legal_move(s.swap))
    _settle(s)
    var data=s.snapshot()
    assert_false(data.resource_rewards.history.is_empty())
    data.resource_rewards.history[0].cells[0].id=data.swap.ids[0][0]
    var restored=Session.new()
    assert_false(restored.restore(data),"corrupt reward history cannot reserve an unconsumed live cell")

func test_swap_clear_gives_resources_but_never_casts():
    var s=Session.new()
    var chosen=s.command("prepare_resource",{"mode":"SWAP"})
    assert_true(chosen.success)
    if not chosen.success:return
    s.swap.setup_training()
    var rows=s.swap.rows()
    var move=_legal_move(s.swap)
    assert_false(move.is_empty())
    assert_true(s.command("resource_swap",move).success)
    assert_ne(s.swap.rows(),rows)
    var hp=s.combat.boss_hp
    s.tick(300000)
    assert_eq(s.metrics.casts,0)
    assert_eq(s.combat.boss_hp,hp)
    assert_gt(s.resource_rewards.total_units(),0)

func test_swap_rejected_while_pair_board_active_and_paused():
    var s=Session.new()
    var chosen=s.command("prepare_resource",{"mode":"SWAP"})
    assert_true(chosen.success)
    if not chosen.success:return
    var move=_legal_move(s.swap)
    s.command("switch")
    var before=s.swap.export_state()
    assert_false(s.command("resource_swap",move).success)
    assert_eq(s.swap.export_state(),before)
    s.command("switch")
    s.command("pause")
    assert_false(s.command("resource_swap",move).success)
    assert_eq(s.swap.export_state(),before)

func _legal_move(board)->Dictionary:
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
