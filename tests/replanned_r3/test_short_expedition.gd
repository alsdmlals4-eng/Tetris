extends GutTest
func route_script():
    var path="res://src/replanned_r3/short_expedition.gd"
    return load(path if FileAccess.file_exists(path) else "res://src/replanned_r3/r3_expedition.gd")

func test_current_battle_resource_choice_and_three_stage_rewards():
    var run=route_script().new("short-test",42,"RELAXED")
    assert_true(run.has_method("select_resource"),"expedition must use current selectable combat")
    if not run.has_method("select_resource"):return
    assert_true(run.select_resource("SWAP"))
    for encounter in ["outer_breach","watchtower","rift_core"]:
        assert_true(run.launch(encounter).success)
        var s=run.make_battle_session()
        assert_eq(s.resource_mode,"SWAP")
        assert_true(s.combat.has_method("counter_state"))
        assert_false(run.finish_session(s).success,"running cannot become reward")
        s.combat.boss_hp=0;s.combat.outcome="VICTORY";s._finalize_terminal()
        assert_true(run.finish_session(s).success)
        assert_false(run.finish_session(s).success,"no duplicate result")
        if run.view().phase=="SUPPLY":
            assert_true(run.choose_supply("armor").success)
            assert_false(run.choose_supply("armor").success)
    assert_eq(run.view().phase,"COMPLETE")
    assert_eq(run.summary().battles,3)
    var copy=route_script().new()
    assert_true(copy.restore(JSON.parse_string(JSON.stringify(run.snapshot()))))
    assert_eq(copy.summary(),run.summary())

func test_route_choice_rejected_after_start_and_defeat_retry_resets_guard():
    var run=route_script().new("retry",17,"STANDARD")
    if not run.has_method("select_resource"):assert_true(false,"missing expedition");return
    run.launch("outer_breach")
    assert_false(run.select_resource("SWAP"))
    var s=run.make_battle_session()
    s.combat.hp=0;s.combat.outcome="DEFEAT";s._finalize_terminal()
    assert_true(run.finish_session(s).success)
    assert_true(run.retry_battle().success)
    var retry=run.make_battle_session()
    assert_eq(retry.combat.hp,100)
    assert_eq(retry.combat.counter_state().charges,0)
    assert_eq(retry._seed,s._seed)

func test_disk_roundtrip_every_phase_and_wrong_battle_rejection():
    var Save=load("res://src/replanned_r3/short_expedition_save.gd")
    var disk=Save.new("user://tests/short-expedition-phases.json")
    var run=route_script().new("disk-short",42,"STANDARD")
    run.select_resource("SWAP")
    assert_true(disk.save_expedition(run,null).success)
    assert_true(disk.load_expedition().success)
    for encounter in ["outer_breach","foundry","rift_core"]:
        run.launch(encounter)
        var s=run.make_battle_session()
        s.command("pause")
        assert_true(disk.save_expedition(run,s,321).success)
        var resumed=disk.load_expedition()
        assert_true(resumed.success)
        assert_eq(resumed.clock_remainder_ns,321)
        assert_eq(resumed.session.snapshot(),s.snapshot())
        var other=load("res://src/replanned_r3/counter_session.gd").new("STANDARD",42,"other",encounter)
        assert_false(disk.save_expedition(run,other).success)
        s.combat.paused=false;s.combat.boss_hp=0;s.combat.outcome="VICTORY";s._finalize_terminal()
        assert_true(run.finish_session(s).success)
        assert_true(disk.save_expedition(run,s).success)
        assert_true(disk.load_expedition().success)
        var before=run.snapshot()
        var bad=before.duplicate(true)
        bad.reports[-1].metrics.casts=99
        assert_false(run.restore(bad))
        assert_eq(run.snapshot(),before)
        if run.view().phase=="SUPPLY":
            run.choose_supply("repair")
            assert_true(disk.save_expedition(run,null).success)
            assert_true(disk.load_expedition().success)

func test_losing_run_does_not_accept_live_or_other_outcome_save():
    var run=route_script().new("lost",91,"STANDARD")
    run.launch("outer_breach")
    var s=run.make_battle_session()
    s.combat.hp=0;s.combat.outcome="DEFEAT";s._finalize_terminal()
    assert_true(run.finish_session(s).success)
    var disk=load("res://src/replanned_r3/short_expedition_save.gd").new("user://tests/short-lost.json")
    assert_true(disk.save_expedition(run,s).success)
    assert_true(disk.load_expedition().success)
    var bad=run.snapshot()
    bad.state.phase="COMPLETE"
    assert_false(run.restore(bad))
    run.retry_battle()
    assert_false(disk.save_expedition(run,s).success)
