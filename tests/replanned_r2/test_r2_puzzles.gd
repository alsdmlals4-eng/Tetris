extends GutTest

const SESSION_PATH := "res://src/replanned_r2/r2_session.gd"
const FIXTURE_PATH := "res://docs/design/r2-complete-session.json"

func _session():
    assert_true(FileAccess.file_exists(SESSION_PATH), "R2 session must provide persistent puzzle integration")
    if not FileAccess.file_exists(SESSION_PATH):
        return null
    return load(SESSION_PATH).new()

func _fixture() -> Dictionary:
    return JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))

func _teach_chain(s) -> void:
    assert_true(s.setup_training("CHAIN"))
    assert_true(s.command("chain_swap", {"from": [4, 5], "to": [5, 5]}).success)

func test_exact_two_wave_fixture_and_bank_consumed_once() -> void:
    var s = _session()
    if s == null: return
    s.combat.attack_bank = 7
    _teach_chain(s)
    assert_eq(s.chain.matched_cells(), [[4,5], [4,6], [4,7], [5,3], [5,4], [5,5]])
    assert_eq(s.tick(299999), [])
    var events: Array = s.tick(1)
    assert_eq(s.combat.boss_hp, 229)
    assert_eq(s.chain.matched_cells(), [[3,4], [4,4], [5,4]])
    assert_eq(events.filter(func(e): return e.get("effect") == "ATK_DAMAGE").size(), 1)
    s.tick(300000)
    assert_eq(s.combat.boss_hp, 223)
    assert_eq(s.combat.attack_bank, 0)
    assert_eq(s.chain.rows(), ["HAHAHDTT","DADAHDAT","TTDHDHDD","HTHHTHHT","AADTADAT","AHHDTTDA","HAHHAHDT","ADTDTHAT"])
    assert_false(s.chain.resolving)
    assert_eq(s.chain.wave_index, 0)

func test_no_diagonal_match_and_failed_swap_no_change() -> void:
    var s = _session()
    if s == null: return
    s.setup_training("CHAIN")
    var rows: Array = s.chain.rows()
    assert_eq(s.chain.matched_cells(), [], "Authored board has diagonals but no H/V matches")
    assert_false(s.command("chain_swap", {"from":[0,0], "to":[1,0]}).success)
    assert_eq(s.chain.rows(), rows)
    assert_eq(s.combat.boss_hp, 240)
    assert_false(s.command("chain_swap", {"from":[0,0], "to":[1,1]}).success)

func test_category_locked_and_switch_queued_until_whole_cascade() -> void:
    var s = _session()
    if s == null: return
    _teach_chain(s)
    assert_eq(s.command("category", {"category":"SUP"}).reason, "CASCADE_CATEGORY_LOCKED")
    assert_true(s.command("switch").success)
    assert_eq(s.mode, "CHAIN")
    s.command("switch")
    s.tick(300000)
    assert_eq(s.mode, "CHAIN")
    s.tick(300000)
    assert_eq(s.mode, "LINE")
    assert_eq(s.selected_category, "ATK")
    assert_true(s.command("category", {"category":"SUP"}).success)

func test_inactive_line_freezes_while_boss_progresses() -> void:
    var s = _session()
    if s == null: return
    s.tick(600000)
    var before: Dictionary = s.line.snapshot()
    var eta: int = s.combat.eta_us
    s.command("switch")
    s.tick(2000000)
    assert_eq(s.line.snapshot(), before)
    assert_eq(s.combat.eta_us, eta - 2000000)
    s.command("switch")
    s.tick(399999)
    assert_eq(s.line.active.origin.y, int(before.active_y))
    s.tick(1)
    assert_eq(s.line.active.origin.y, int(before.active_y) + 1)

func test_line_fixture_unique_resource_cells_and_next_five() -> void:
    var s = _session()
    if s == null: return
    assert_true(s.setup_training("LINE"))
    var response: Dictionary = s.command("hard_drop")
    assert_true(response.success)
    assert_eq(s.combat.attack_bank, 4)
    assert_eq(s.combat.armor, 2)
    assert_eq(s.combat.hp, 82)
    assert_eq(s.combat.extension_us, 500000)
    assert_eq(s.line.next_queue.size(), 5)
    assert_eq(s.combat.snapshot().processed_line_cell_ids.size(), 10)
    s.tick(0)
    assert_eq(s.combat.attack_bank, 4)
    assert_true(s.line.board.is_empty())

func test_hold_pair_is_preserved_and_once_per_lock() -> void:
    var s = _session()
    if s == null: return
    var first: Dictionary = s.line.active_pair()
    assert_true(s.command("hold").success)
    assert_eq(s.line.hold_pair(), first)
    assert_false(s.command("hold").success)
    s.command("hard_drop")
    assert_true(s.command("hold").success)
    assert_eq(s.line.active_pair(), first)
    assert_false(s.line.hold_available)

func test_topout_cost_bypasses_armor_preserves_chain_and_resets_hold() -> void:
    var s = _session()
    if s == null: return
    s.command("hold")
    s.combat.armor = 40
    var rows: Array = s.chain.rows()
    for y in range(4):
        for x in range(10):
            s.line.board.set_cell(Vector2i(x,y), "D")
    var result: Dictionary = s.command("hard_drop")
    assert_true(result.success)
    assert_eq(s.combat.hp, 75)
    assert_eq(s.combat.armor, 40)
    assert_eq(s.chain.rows(), rows)
    assert_true(s.line.board.is_empty())
    assert_true(s.line.hold_available)
    assert_true(s.command("hold").success)
    assert_eq(s.combat.hp, 75, "Reset does not retain blocked held pose")

func test_pause_preserves_pending_wave_and_resume_identical() -> void:
    var a = _session()
    if a == null: return
    var b = _session()
    _teach_chain(a)
    _teach_chain(b)
    a.tick(123456)
    b.tick(123456)
    var before: Dictionary = a.chain.snapshot()
    var eta: int = a.combat.eta_us
    a.command("pause")
    a.tick(9000000)
    assert_eq(a.chain.snapshot(), before)
    assert_eq(a.combat.eta_us, eta)
    assert_false(a.command("category", {"category":"DEF"}).success)
    a.command("resume")
    a.tick(476544)
    b.tick(476544)
    assert_eq(a.snapshot(), b.snapshot())

func test_same_tick_lethal_boss_cancels_cast_refill_and_inputs() -> void:
    var s = _session()
    if s == null: return
    _teach_chain(s)
    s.combat.hp = 12
    s.combat.eta_us = 300000
    var rows: Array = s.chain.rows()
    s.tick(300000)
    assert_eq(s.combat.outcome, "DEFEAT")
    assert_eq(s.combat.boss_hp, 240)
    assert_eq(s.chain.rows(), rows)
    assert_false(s.chain.resolving)
    assert_false(s.command("switch").success)

func test_same_tick_lethal_boss_cancels_line_clear_and_heal() -> void:
    var s = _session()
    if s == null: return
    s.setup_training("LINE")
    s.combat.hp = 12
    s.combat.eta_us = 500000
    while s.line.active.try_move(s.line.board, Vector2i.DOWN): pass
    s.tick(500000)
    assert_eq(s.combat.outcome, "DEFEAT")
    assert_eq(s.combat.attack_bank, 0)
    assert_eq(s.line.board.get_cell(Vector2i(0,23)), "D")

func test_same_tick_finished_action_does_not_retarget_line_time_or_ward() -> void:
    var s = _session()
    if s == null: return
    s.setup_training("LINE")
    s.combat.eta_us = 500000
    while s.line.active.try_move(s.line.board, Vector2i.DOWN): pass
    s.tick(500000)
    assert_eq(s.combat.action_index, 1)
    assert_eq(s.combat.extension_us, 0)
    assert_eq(s.combat.eta_us, 14000000)
    assert_eq(s.combat.attack_bank, 4)
    var c = _session()
    c.command("category", {"category":"DEF"})
    _teach_chain(c)
    c.combat.eta_us = 300000
    c.tick(300000)
    assert_eq(c.combat.ward, 0)
    assert_eq(c.combat.action_index, 1)

func test_stable_json_restore_pauses_and_replays_rng_bags_and_pose() -> void:
    var a = _session()
    if a == null: return
    a.command("hold")
    a.tick(234567)
    var saved: Dictionary = JSON.parse_string(JSON.stringify(a.snapshot()))
    var b = _session()
    assert_true(b.combat.restore(saved.combat), "Combat payload accepts JSON numbers")
    assert_true(b.line.restore(saved.line), "LINE payload accepts JSON numbers")
    assert_true(b.chain.restore(saved.chain), "CHAIN payload accepts JSON numbers")
    assert_true(b.restore(saved), "Combined snapshot validates")
    assert_true(b.combat.paused)
    b.command("resume")
    assert_eq(b.snapshot(), a.snapshot())
    for i in range(12):
        assert_eq(a.command("hard_drop").success, b.command("hard_drop").success)
        assert_eq(a.line.snapshot(), b.line.snapshot())
    a.setup_training("CHAIN")
    b.setup_training("CHAIN")
    a.chain.training_stream = []
    b.chain.training_stream = []
    a.command("chain_swap", {"from":[4,5], "to":[5,5]})
    b.command("chain_swap", {"from":[4,5], "to":[5,5]})
    a.tick(600000)
    b.tick(600000)
    assert_eq(a.chain.snapshot(), b.chain.snapshot())

func test_invalid_restore_atomic_and_partial_snapshot_refused() -> void:
    var s = _session()
    if s == null: return
    var before: Dictionary = s.snapshot()
    for field in ["identity", "player", "boss", "line", "chain", "ui", "combat"]:
        var damaged: Dictionary = before.duplicate(true)
        damaged.erase(field)
        assert_false(s.restore(damaged))
        assert_eq(s.snapshot(), before)
    var bad: Dictionary = before.duplicate(true)
    bad.line.resource_rng_state = "9223372036854775808"
    assert_false(s.restore(bad))
    bad = before.duplicate(true)
    bad.line.next_queue[0].resource = "Q"
    assert_false(s.restore(bad))
    bad = before.duplicate(true)
    bad.boss.current_instance = "foreign"
    assert_false(s.restore(bad))
    bad = before.duplicate(true)
    bad.line.active_y = 999
    assert_false(s.restore(bad))
    bad = before.duplicate(true)
    bad.chain.cells[0] = "AAAAAAAA"
    assert_false(s.restore(bad))
    assert_eq(s.snapshot(), before)
    _teach_chain(s)
    assert_eq(s.snapshot(), {}, "Only stable checkpoint can be persisted")

func test_initial_chain_is_playable_no_match_and_seed_reproducible() -> void:
    var s = _session()
    if s == null: return
    var b = _session()
    assert_eq(s.chain.rows(), b.chain.rows())
    assert_eq(s.chain.matched_cells(), [])
    assert_true(s.chain.has_valid_move())
    assert_eq(s.line.active_pair(), b.line.active_pair())
    assert_eq(s.line.next_queue, b.line.next_queue)
    assert_eq(s.chain.training_stream, [])

func test_seventh_wave_uses_t6_and_safety_limit_recovers_without_reward() -> void:
    var s = _session()
    if s == null: return
    s.setup_training("CHAIN")
    s.chain.training_stream = []
    s.chain.cells = []
    for y in range(8): s.chain.cells.append("AAAAAAAA")
    s.chain.resolving = true
    s.chain.category_snapshot = "SUP"
    s.chain.chain_id = 1
    s.chain.wave_index = 6
    s.chain.next_wave_remaining_us = 300000
    s.combat.hp = 50
    var events: Array = s.tick(300000)
    var casts: Array = events.filter(func(e): return e.get("effect") == "SUP_HEAL")
    assert_eq(casts.size(), 1)
    assert_eq(casts[0].wave, 7)
    assert_eq(casts[0].stage, 6)
    assert_eq(s.combat.hp, 59)
    s.chain.cells = []
    for y in range(8): s.chain.cells.append("AAAAAAAA")
    s.chain.resolving = true
    s.chain.wave_index = 63
    s.chain.next_wave_remaining_us = 300000
    s.tick(300000)
    assert_false(s.chain.resolving)
    assert_eq(s.chain.matched_cells(), [])
    assert_true(s.chain.has_valid_move())
    assert_eq(s.combat.hp, 68)

func test_ground_lock_and_reset_limit_and_ghost_do_not_change_stream() -> void:
    var s = _session()
    if s == null: return
    var before: Dictionary = s.line.snapshot()
    assert_eq(s.line.ghost_cells().size(), 4)
    assert_eq(s.line.snapshot(), before)
    while s.line.active.try_move(s.line.board, Vector2i.DOWN): pass
    s.tick(400000)
    for i in range(15):
        assert_true(s.command("move", {"dx":1 if i % 2 == 0 else -1}).success)
        s.tick(10000)
    assert_eq(s.line.lock_reset_count, 15)
    s.tick(400000)
    s.command("move", {"dx":-1})
    var pair: Dictionary = s.line.active_pair()
    s.tick(89999)
    assert_eq(s.line.active_pair(), pair)
    s.tick(1)
    assert_eq(s.line.lock_reset_count, 0)

func test_save_rejects_event_counter_and_bag_inconsistency_atomically() -> void:
    var s = _session()
    if s == null: return
    s.setup_training("LINE")
    s.command("hard_drop")
    _teach_chain(s)
    s.tick(600000)
    var good: Dictionary = s.snapshot()
    var before: Dictionary = good.duplicate(true)
    var bad: Dictionary = good.duplicate(true)
    bad.chain.chain_id = 0
    assert_false(s.restore(bad),"A reused chain ID would skip future casts")
    bad = good.duplicate(true)
    bad.chain.processed_event_ids = []
    assert_false(s.restore(bad),"Puzzle and combat must agree on committed waves")
    bad = good.duplicate(true)
    bad.line.lock_sequence = 0
    assert_false(s.restore(bad),"A reused LINE event ID would skip rewards")
    bad = good.duplicate(true)
    bad.line.resource_bag_remaining = []
    assert_false(s.restore(bad),"Resource bag must agree with the piece stream position")
    assert_eq(s.snapshot(),before)
    var restored = _session()
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(good))))
    restored.command("resume")
    assert_eq(restored.snapshot(),good)
    _teach_chain(restored)
    restored.tick(600000)
    assert_eq(restored.combat.boss_hp,216)

func test_checkpoint_reason_and_queued_switch_are_inspectable() -> void:
    var s = _session()
    if s == null: return
    assert_true(s.can_checkpoint())
    _teach_chain(s)
    assert_false(s.can_checkpoint())
    assert_eq(s.checkpoint_status().reason,"CASCADE_RUNNING")
    assert_eq(s.command("switch").reason,"QUEUED_UNTIL_STABLE")

func test_cross_matches_are_unique_and_multirow_line_counts_actual_cells() -> void:
    var s = _session()
    if s == null: return
    s.setup_training("CHAIN")
    s.chain.cells = ["ADHTADHT","DHTADHTA","HTADHTAD","TADAADHT","AAAAAHTA","DHTADHTA","HTADHTAD","TADHTADH"]
    var matches: Array = s.chain.matched_cells()
    assert_eq(matches,[[0,4],[1,4],[2,4],[3,3],[3,4],[3,5],[4,4]])
    var l = _session()
    l.setup_training("LINE")
    l.line.board.clear_all()
    for y in [22,23]:
        for x in range(10):
            if x not in [4,5]: l.line.board.set_cell(Vector2i(x,y),"D")
    l.line._spawn_pair({"shape":"O","resource":"A"})
    l.command("hard_drop")
    assert_eq(l.combat.armor,16)
    assert_eq(l.combat.attack_bank,4)
    assert_eq(l.combat.snapshot().processed_line_cell_ids.size(),20)

func test_session_metrics_record_effective_waste_defenses_and_bank_marginal_damage() -> void:
    var s = _session()
    if s == null: return
    s.setup_training("LINE")
    s.command("hard_drop")
    assert_eq(s.metrics.get("attack_bank_generated",-1),4)
    assert_eq(s.metrics.get("healing_effective",-1),2)
    assert_eq(s.metrics.get("time_applied_us",-1),500000)
    s.command("category",{"category":"SUP"})
    _teach_chain(s)
    s.combat.hp = 99
    s.tick(600000)
    assert_eq(s.metrics.get("healing_effective",-1),3)
    assert_eq(s.metrics.get("healing_wasted",-1),4)
    s.command("category",{"category":"DEF"})
    _teach_chain(s)
    s.tick(600000)
    s.combat.eta_us = 1
    s.tick(1)
    assert_eq(s.metrics.get("ward_absorbed",-1),5)
    assert_eq(s.metrics.get("armor_absorbed",-1),2)
    assert_eq(s.metrics.get("boss_damage_to_hp",-1),5)
    assert_eq(s.metrics.get("hp_damage_taken",-1),5)
    s.command("category",{"category":"ATK"})
    _teach_chain(s)
    s.combat.boss_hp = 6
    s.tick(300000)
    assert_eq(s.metrics.get("damage_dealt",-1),6)
    assert_eq(s.metrics.get("damage_overkill",-1),2)
    assert_eq(s.metrics.get("attack_bank_consumed",-1),4)
    assert_eq(s.metrics.get("attack_bank_marginal_damage",-1),2)
    var saved: Dictionary = JSON.parse_string(JSON.stringify(s.snapshot()))
    var restored = _session()
    assert_true(restored.restore(saved))
    assert_eq(restored.metrics,s.metrics)

func test_metrics_count_committed_time_waste_and_unshieldable_topout_separately() -> void:
    var s = _session()
    if s == null: return
    s.setup_training("LINE")
    s.combat.extension_us = 2900000
    s.command("hard_drop")
    assert_eq(s.metrics.get("time_applied_us",-1),100000)
    assert_eq(s.metrics.get("time_wasted_us",-1),400000)
    s.setup_training("LINE")
    s.combat.eta_us = 1000
    s.command("hard_drop")
    assert_eq(s.metrics.get("time_applied_us",-1),100000)
    assert_eq(s.metrics.get("time_wasted_us",-1),900000)
    s.combat.hp = 100
    s.combat.armor = 40
    for y in range(4):
        for x in range(10): s.line.board.set_cell(Vector2i(x,y),"A")
    s.command("hard_drop")
    assert_eq(s.metrics.get("topout_damage_to_hp",-1),25)
    assert_eq(s.metrics.get("boss_damage_to_hp",-1),0)
    assert_eq(s.metrics.get("hp_damage_taken",-1),25)
    assert_eq(s.metrics.get("armor_absorbed",-1),0)
