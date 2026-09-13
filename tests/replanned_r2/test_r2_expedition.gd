extends GutTest

const PATH := "res://src/replanned_r2/r2_expedition.gd"

func test_route_brief_uses_real_profile_cycle_without_mutating_progress():
    var run = _new_run()
    assert_true(run.has_method("encounter_brief"))
    if not run.has_method("encounter_brief"): return
    var before = run.snapshot()
    var brief = run.encounter_brief("watchtower")
    assert_eq(brief.enemy_name,"감시탑 파수꾼")
    assert_eq(brief.boss_hp,160)
    assert_eq(brief.actions.size(),4)
    assert_eq(brief.actions[0].duration_us,7000000)
    assert_eq(brief.actions[2].damage,16)
    brief.actions[0].damage=999
    assert_eq(run.encounter_brief("watchtower").actions[0].damage,7)
    assert_eq(run.snapshot(),before)
    assert_eq(run.encounter_brief("unknown"),{})

func test_relaxed_route_preview_agrees_with_actual_first_action():
    var run = load(PATH).new("brief-relaxed",41,"RELAXED")
    assert_true(run.has_method("encounter_brief"))
    if not run.has_method("encounter_brief"): return
    var brief = run.encounter_brief("outer_breach")
    run.launch("outer_breach")
    var battle = run.make_battle_session()
    assert_eq(brief.actions[0].duration_us,battle.combat.eta_us)
    assert_gt(brief.actions[0].duration_us,12000000)
    assert_eq(brief.actions[0].damage,battle.combat.current_action().damage)

func _new_run():
    assert_true(ResourceLoader.exists(PATH), "Whole-game progression owner must exist")
    if not ResourceLoader.exists(PATH): return null
    return load(PATH).new("expedition-test", 41, "STANDARD")

func _win(run, hp: int = 70):
    var launch = run.view().active_battle
    return run.finish_battle({"run_id":launch.run_id,"outcome":"VICTORY","hp":hp})

func test_both_middle_routes_reach_one_final_ending():
    for middle in ["foundry", "watchtower"]:
        var run = _new_run()
        if run == null: return
        assert_eq(run.view().phase, "ROUTE")
        assert_eq(run.available_encounters(), ["outer_breach"])
        assert_true(run.launch("outer_breach").success)
        assert_true(_win(run).success)
        assert_eq(run.view().phase, "SUPPLY")
        assert_true(run.choose_supply("repair").success)
        assert_eq(run.available_encounters(), ["foundry", "watchtower"])
        assert_true(run.launch(middle).success)
        assert_eq(run.view().active_battle.hp, 90)
        assert_true(_win(run, 50).success)
        assert_true(run.choose_supply("attack").success)
        assert_true(run.launch("rift_core").success)
        assert_eq(run.view().active_battle.attack_bank, 12)
        assert_true(_win(run, 30).success)
        assert_eq(run.view().phase, "COMPLETE")
        assert_eq(run.available_encounters(), [])
        assert_eq(run.view().route, ["outer_breach", middle, "rift_core"])

func test_rejected_transition_and_foreign_result_do_not_mutate_run():
    var run = _new_run()
    if run == null: return
    var before = run.view()
    assert_false(run.launch("rift_core").success)
    assert_false(run.choose_supply("repair").success)
    assert_false(run.finish_battle({"run_id":"foreign","outcome":"VICTORY","hp":50}).success)
    assert_eq(run.view(), before)
    assert_true(run.launch("outer_breach").success)
    before = run.view()
    assert_false(run.launch("outer_breach").success)
    assert_false(run.finish_battle({"run_id":"foreign","outcome":"VICTORY","hp":50}).success)
    assert_false(run.finish_battle({"run_id":before.active_battle.run_id,"outcome":"RUNNING","hp":50}).success)
    assert_eq(run.view(), before)

func test_supply_effect_is_capped_once_and_requires_valid_choice():
    var run = _new_run()
    if run == null: return
    run.launch("outer_breach")
    _win(run, 99)
    assert_eq(run.supply_preview("repair").healing_applied, 1)
    var before = run.view()
    assert_false(run.choose_supply("unknown").success)
    assert_eq(run.view(), before)
    assert_true(run.choose_supply("repair").success)
    before = run.view()
    assert_false(run.choose_supply("repair").success)
    assert_eq(run.view(), before)
    run.launch("foundry")
    assert_eq(run.view().active_battle.hp, 100)
    assert_eq(run.view().active_battle.armor, 0)

func test_retry_restores_encounter_start_without_new_supply_or_route_entry():
    var run = _new_run()
    if run == null: return
    run.launch("outer_breach")
    _win(run, 60)
    run.choose_supply("armor")
    run.launch("watchtower")
    var start = run.view().active_battle
    assert_true(run.finish_battle({"run_id":start.run_id,"outcome":"DEFEAT","hp":0}).success)
    assert_eq(run.view().phase, "DEFEAT")
    assert_false(run.choose_supply("repair").success)
    assert_true(run.retry_battle().success)
    assert_eq(run.view().phase, "BATTLE")
    assert_eq(run.view().active_battle, start)
    assert_eq(run.view().route, ["outer_breach", "watchtower"])
    assert_eq(start.hp, 60)
    assert_eq(start.armor, 12)

func test_returned_data_is_not_live_state_and_invalid_hp_cannot_end_battle():
    var run = _new_run()
    if run == null: return
    run.launch("outer_breach")
    var before = run.view()
    var copy = run.view()
    copy.route.clear()
    copy.active_battle.hp = 1
    assert_eq(run.view(), before)
    for hp in [-1, 0, 101, 1.5, "90"]:
        assert_false(run.finish_battle({"run_id":before.active_battle.run_id,"outcome":"VICTORY","hp":hp}).success)
        assert_eq(run.view(), before)
    assert_false(run.finish_battle({"run_id":before.active_battle.run_id,"outcome":"DEFEAT","hp":1}).success)

func test_seed_and_run_identity_are_stable_and_terminal_is_closed():
    var run = _new_run()
    if run == null: return
    var twin = _new_run()
    run.launch("outer_breach")
    twin.launch("outer_breach")
    assert_eq(run.view().active_battle, twin.view().active_battle)
    _win(run)
    run.choose_supply("attack")
    run.launch("foundry")
    _win(run)
    run.choose_supply("armor")
    run.launch("rift_core")
    _win(run)
    var before = run.view()
    assert_false(run.retry_battle().success)
    assert_false(run.choose_supply("repair").success)
    assert_false(run.launch("outer_breach").success)
    assert_false(_win(run).success)
    assert_eq(run.view(), before)

func test_profiles_change_actual_encounter_without_rewriting_standalone_save():
    var combat_script = load("res://src/replanned_r2/r2_combat.gd")
    var baseline = combat_script.new()
    assert_true(baseline.has_method("encounter_info"), "Profile-aware combat is required")
    if not baseline.has_method("encounter_info"): return
    var original = baseline.snapshot()
    var slow = combat_script.new("STANDARD", "slow", "foundry")
    var fast = combat_script.new("STANDARD", "fast", "watchtower")
    assert_eq(slow.encounter_info().id, "foundry")
    assert_gt(slow.current_action().duration_us, fast.current_action().duration_us)
    assert_gt(slow.current_action().damage, fast.current_action().damage)
    assert_eq(baseline.snapshot(), original)
    assert_false(slow.restore(original))
    assert_false(baseline.restore(slow.snapshot()))
    var restored = combat_script.new("STANDARD", "slow", "foundry")
    assert_true(restored.restore(slow.snapshot()))
    assert_eq(restored.snapshot(), slow.snapshot())
    var relaxed = combat_script.new("RELAXED", "slow", "foundry")
    assert_eq(relaxed.eta_us, roundi(slow.eta_us*1.25))
    var invalid = combat_script.new("STANDARD", "invalid", "missing-profile")
    assert_eq(invalid.current_action(), {})

func test_profile_session_roundtrip_preserves_profile_and_puzzle_owners():
    var combat_script = load("res://src/replanned_r2/r2_combat.gd")
    assert_true(combat_script.new().has_method("encounter_info"), "Profile session requires profile combat")
    if not combat_script.new().has_method("encounter_info"): return
    var session_script = load("res://src/replanned_r2/r2_session.gd")
    var session = session_script.new("STANDARD", 41, "profile-session", "watchtower")
    session.tick(123456)
    var saved = session.snapshot()
    var restored = session_script.new("STANDARD", 41, "profile-session", "watchtower")
    assert_true(restored.restore(saved))
    assert_eq(restored.combat.encounter_info().id, "watchtower")
    assert_eq(restored.line.snapshot(), session.line.snapshot())
    assert_eq(restored.chain.snapshot(), session.chain.snapshot())
    assert_true(restored.combat.paused)
    assert_false(session_script.new().restore(saved))

func test_expedition_snapshot_roundtrip_rejects_skips_without_mutation():
    var run = _new_run()
    if run == null: return
    assert_true(run.has_method("snapshot"), "Expedition requires complete progression snapshot")
    if not run.has_method("snapshot"): return
    run.launch("outer_breach")
    _win(run, 60)
    run.choose_supply("armor")
    run.launch("watchtower")
    var saved = JSON.parse_string(JSON.stringify(run.snapshot()))
    var restored = _new_run()
    assert_true(restored.restore(saved))
    assert_eq(restored.view(), run.view())
    for field in ["stage", "hp"]:
        var bad = saved.duplicate(true)
        bad.state[field] = 99
        assert_false(restored.restore(bad))
        assert_eq(restored.view(), run.view())
    var foreign = saved.duplicate(true)
    foreign.catalog_hash = "wrong"
    assert_false(restored.restore(foreign))
    assert_eq(restored.view(), run.view())

func test_expedition_disk_binds_battle_to_route_and_preserves_recovery():
    var run = _new_run()
    if run == null: return
    var path = "res://src/replanned_r2/r2_expedition_save.gd"
    assert_true(ResourceLoader.exists(path), "Separate expedition save owner required")
    if not ResourceLoader.exists(path): return
    var disk = load(path).new("user://replanned_r2_tests/expedition-contract.json")
    var initial_save = disk.save_expedition(run, null)
    assert_true(initial_save.success, str(initial_save))
    run.launch("outer_breach")
    var meta = run.view().active_battle
    var session = load("res://src/replanned_r2/r2_session.gd").new(meta.difficulty, meta.seed, meta.run_id, meta.encounter_id)
    var battle_save = disk.save_expedition(run, session)
    assert_true(battle_save.success, str(battle_save))
    var loaded = disk.load_expedition()
    assert_true(loaded.success)
    if not loaded.success: return
    assert_eq(loaded.expedition.view(), run.view())
    assert_true(loaded.session.combat.paused)
    assert_eq(loaded.session.line.snapshot(), session.line.snapshot())
    var other = load("res://src/replanned_r2/r2_session.gd").new()
    assert_false(disk.save_expedition(run, other).success)
    assert_eq(disk.load_expedition().expedition.view(), run.view())
    disk.failure_point = "rename"
    assert_false(disk.save_expedition(run, session).success)
    assert_true(disk.load_expedition().success)

func test_battle_factory_applies_only_the_selected_opening_preparation():
    var run = _new_run()
    if run == null: return
    assert_true(run.has_method("make_battle_session"), "Campaign must construct the real session")
    if not run.has_method("make_battle_session"): return
    assert_null(run.make_battle_session())
    run.launch("outer_breach")
    _win(run, 60)
    run.choose_supply("armor")
    run.launch("watchtower")
    var session = run.make_battle_session()
    assert_not_null(session)
    assert_eq(session.combat.hp, 60)
    assert_eq(session.combat.armor, 12)
    assert_eq(session.combat.attack_bank, 0)
    assert_eq(session.combat.ward, 0)
    assert_eq(session.combat.encounter_info().id, "watchtower")

func test_campaign_save_rejects_same_identity_with_a_different_puzzle_seed():
    var run = _new_run()
    if run == null: return
    run.launch("outer_breach")
    var meta = run.view().active_battle
    var disk = load("res://src/replanned_r2/r2_expedition_save.gd").new("user://replanned_r2_tests/expedition-seed.json")
    var correct = run.make_battle_session()
    assert_true(disk.save_expedition(run,correct).success)
    var wrong = load("res://src/replanned_r2/r2_session.gd").new(meta.difficulty,int(meta.seed)+1,meta.run_id,meta.encounter_id)
    assert_false(disk.save_expedition(run,wrong).success,"Same run ID cannot authorize a different board seed")
    assert_eq(disk.load_expedition().session.line.snapshot(),correct.line.snapshot())
