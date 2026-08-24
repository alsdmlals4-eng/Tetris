extends GutTest

const BATTLE_PATH := "res://src/production/combat/production_battle_session.gd"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"

const NORMAL_INPUTS := [
    {"at": 20.0, "name": "LINE_RESULT"},
    {"at": 20.0, "name": "LINE_READY"},
    {"at": 21.0, "name": "LINE_SETTLE_COMPLETE"},
    {"at": 31.0, "name": "CHAIN_SWAP"},
    {"at": 31.0, "name": "CHAIN_RESOLVE"},
    {"at": 31.0, "name": "CHAIN_READY"},
    {"at": 32.5, "name": "CHAIN_SETTLE_COMPLETE"},
    {"at": 37.5, "name": "SELECT_ATK_T1"},
    {"at": 37.5, "name": "PLAYER_RESOLVE"},
]

const TIMEOUT_INPUTS := [
    {"at": 90.0, "name": "TIMEOUT_LINE_SETTLE_COMPLETE"},
    {"at": 91.0, "name": "PLAYER_RESOLVE"},
]

class FixedRewardPolicy:
    extends RefCounted

    func stock_for_resolution(resolution: Dictionary) -> int:
        return 2 if int(resolution.get("chain_depth", 0)) > 0 else 0

func _enemy_catalog() -> GatebreakerActionCatalog:
    return GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ENEMY_DATA_PATH)))

func _skill_catalog() -> ProductionSkillCatalog:
    return ProductionSkillCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH)))

func _time_config() -> TurnTimeConfig:
    return TurnTimeConfig.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(TIME_DATA_PATH)))

func _make_chain(turn: TurnController, player: ProductionCombatState, seed_value: int) -> Dictionary:
    var board := ChainBoard.new(3, 3)
    var rows := [
        ["A", "A", "B"],
        ["B", "C", "A"],
        ["C", "B", "C"],
    ]
    for y in range(rows.size()):
        for x in range(rows[y].size()):
            board.set_cell(Vector2i(x, y), String(rows[y][x]))

    var randomizer := ChainRandomizer.new(seed_value, ["D", "E", "F", "G"])
    var resolver := ChainResolver.new(board, randomizer)
    return {
        "session": ProductionChainSession.new(turn, board, resolver, player, FixedRewardPolicy.new()),
        "randomizer": randomizer,
    }

func _fixture(seed_value: int) -> Dictionary:
    var enemy_catalog := _enemy_catalog()
    var current := enemy_catalog.instantiate_action("light_smash", 1)
    var next := enemy_catalog.instantiate_action("gatebreaker_slam", 2)
    var turn := TurnController.new(TurnBudget.new())
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var battle = load(BATTLE_PATH).new(
        turn,
        player,
        enemy,
        _skill_catalog(),
        GatebreakerTelegraphState.new(current, next),
        ProductionStatusState.new(),
        ProductionResponseState.new(),
        TimeEffectState.new(),
        ProductionTechniqueResolver.new(ProductionEffectExecutor.new()),
        ProductionEnemyActionResolver.new()
    )
    var started: Dictionary = battle.start_next_player_turn(_time_config(), "NORMAL")
    assert_true(started["started"])

    var telemetry := ProductionTelemetry.new()
    assert_true(telemetry.record_event({
        "kind": &"turn_started",
        "turn_index": 1,
        "telegraph_action_id": String(current.get("id", "")),
        "profile_id": "NORMAL",
        "base_budget_seconds": float(started["base_budget_seconds"]),
        "flat_modifier_seconds": float(started["flat_modifier_seconds"]),
        "effective_budget_seconds": float(started["effective_budget_seconds"]),
        "tempo_reference_seconds": float(started["tempo_reference_seconds"]),
    }))

    var chain := _make_chain(turn, player, seed_value)
    return {
        "battle": battle,
        "turn": turn,
        "player": player,
        "enemy": enemy,
        "telemetry": telemetry,
        "chain": chain["session"],
        "chain_randomizer": chain["randomizer"],
    }

func _advance_wall_time(f: Dictionary, delta: float, active: Dictionary) -> void:
    if delta <= 0.0:
        return
    var turn: TurnController = f["turn"]
    var phase_before := turn.phase
    var remaining_before := turn.turn_budget.remaining_seconds
    turn.tick_player_time(delta)
    var consumed := minf(delta, remaining_before)
    match phase_before:
        TurnPhase.LINE:
            active["LINE"] = float(active["LINE"]) + consumed
        TurnPhase.CHAIN:
            active["CHAIN"] = float(active["CHAIN"]) + consumed
        TurnPhase.ACTION:
            active["ACTION"] = float(active["ACTION"]) + consumed

func _record_phase(f: Dictionary, phase_name: String, active_seconds: float, settle_seconds: float, ready_used: bool, timeout_occurred: bool) -> void:
    assert_true(f["telemetry"].record_event({
        "kind": &"phase_completed",
        "turn_index": 1,
        "phase": phase_name,
        "active_used_seconds": active_seconds,
        "settle_seconds": settle_seconds,
        "ready_used": ready_used,
        "timeout_occurred": timeout_occurred,
        "remaining_budget_seconds": float(f["turn"].turn_budget.remaining_seconds),
    }))

func _record_tempo(f: Dictionary, selected: Dictionary) -> void:
    var performance: ProductionTurnPerformanceState = f["battle"].turn_performance_state
    assert_true(f["telemetry"].record_event({
        "kind": &"tempo_evaluated",
        "turn_index": 1,
        "line_qualified": performance.line_qualified,
        "chain_qualified": performance.chain_qualified,
        "action_non_pass": performance.action_non_pass,
        "timeout_occurred": performance.timeout_occurred,
        "board_break_occurred": performance.board_break_occurred,
        "saved_ratio": float(selected.get("tempo_saved_ratio", 0.0)),
        "eligible": bool(selected.get("tempo_eligible", false)),
        "ineligible_reason": String(selected.get("tempo_ineligible_reason", "")),
        "potency_bonus_ratio": float(selected.get("tempo_potency_bonus_ratio", 0.0)),
        "applied_potency_ratio": float(selected.get("tempo_potency_bonus_ratio", 0.0)),
    }))

func _run_normal(seed_value: int, inputs: Array) -> Dictionary:
    var f := _fixture(seed_value)
    var active := {"LINE": 0.0, "CHAIN": 0.0, "ACTION": 0.0}
    var last_at := 0.0
    var line_ready_at := -1.0
    var chain_ready_at := -1.0
    var selected: Dictionary = {}
    var resolved: Dictionary = {}

    for input_value in inputs:
        var input: Dictionary = input_value
        var at := float(input.get("at", last_at))
        assert_gte(at, last_at)
        _advance_wall_time(f, at - last_at, active)
        last_at = at

        match String(input.get("name", "")):
            "LINE_RESULT":
                var line_event := {"kind": &"production_line_resolved", "energy_delta": 10}
                assert_true(f["battle"].record_turn_performance_event(line_event))
                f["player"].apply_energy_delta(10)
            "LINE_READY":
                line_ready_at = at
                f["turn"].request_ready()
                assert_eq(f["turn"].phase, TurnPhase.LINE_SETTLE)
            "LINE_SETTLE_COMPLETE":
                _record_phase(f, "LINE", float(active["LINE"]), at - line_ready_at, true, false)
                f["turn"].complete_line_settle()
                assert_eq(f["turn"].phase, TurnPhase.CHAIN)
            "CHAIN_SWAP":
                assert_true(f["chain"].begin_swap(Vector2i(2, 0), Vector2i(2, 1))["accepted"])
            "CHAIN_RESOLVE":
                var resolution: Dictionary = f["chain"].complete_pending_resolution()
                assert_true(resolution["success"])
                var chain_events: Array = f["chain"].drain_events()
                assert_eq(chain_events.size(), 1)
                assert_true(f["battle"].record_turn_performance_event(chain_events[0]))
            "CHAIN_READY":
                chain_ready_at = at
                assert_true(f["chain"].request_ready())
            "CHAIN_SETTLE_COMPLETE":
                _record_phase(f, "CHAIN", float(active["CHAIN"]), at - chain_ready_at, true, false)
                assert_true(f["chain"].complete_settle())
                assert_eq(f["turn"].phase, TurnPhase.ACTION)
            "SELECT_ATK_T1":
                _record_phase(f, "ACTION", float(active["ACTION"]), 0.0, false, false)
                selected = f["battle"].select_technique("atk_t1_quick_cut")
                assert_true(selected["accepted"])
                _record_tempo(f, selected)
            "PLAYER_RESOLVE":
                resolved = f["battle"].resolve_player_action()
                assert_true(resolved["resolved"])
            _:
                fail_test("Unknown replay input: %s" % String(input.get("name", "")))

    return {
        "seed": seed_value,
        "inputs": inputs.duplicate(true),
        "telemetry": f["telemetry"].events_snapshot(),
        "phase": f["turn"].phase,
        "remaining_budget_seconds": f["turn"].turn_budget.remaining_seconds,
        "active_used_seconds": f["turn"].turn_budget.active_used_seconds,
        "timed_out": f["turn"].timed_out_this_turn,
        "tempo_eligible": bool(selected.get("tempo_eligible", false)),
        "tempo_saved_ratio": float(selected.get("tempo_saved_ratio", 0.0)),
        "tempo_potency_bonus_ratio": float(selected.get("tempo_potency_bonus_ratio", 0.0)),
        "enemy_hp": f["enemy"].hp,
        "player_energy": f["player"].energy,
        "player_stock": f["player"].stock,
        "chain_board": f["chain"].board.snapshot(),
        "chain_rng_state": f["chain_randomizer"].get_rng_state(),
        "resolved_technique_id": String(resolved.get("technique_id", "")),
    }

func _run_timeout(seed_value: int, inputs: Array) -> Dictionary:
    var f := _fixture(seed_value)
    var active := {"LINE": 0.0, "CHAIN": 0.0, "ACTION": 0.0}
    var last_at := 0.0
    var pass_result: Dictionary = {}

    for input_value in inputs:
        var input: Dictionary = input_value
        var at := float(input.get("at", last_at))
        _advance_wall_time(f, at - last_at, active)
        last_at = at

        match String(input.get("name", "")):
            "TIMEOUT_LINE_SETTLE_COMPLETE":
                assert_true(f["turn"].timed_out_this_turn)
                assert_eq(f["turn"].phase, TurnPhase.LINE_SETTLE)
                _record_phase(f, "LINE", float(active["LINE"]), 0.0, false, true)
                f["turn"].complete_line_settle()
                assert_eq(f["turn"].pending_player_action.id, "PASS")
            "PLAYER_RESOLVE":
                pass_result = f["battle"].resolve_player_action()
                assert_true(pass_result["resolved"])
                assert_true(pass_result["passed"])
                var performance: ProductionTurnPerformanceState = f["battle"].turn_performance_state
                assert_true(f["telemetry"].record_event({
                    "kind": &"tempo_evaluated",
                    "turn_index": 1,
                    "line_qualified": performance.line_qualified,
                    "chain_qualified": performance.chain_qualified,
                    "action_non_pass": performance.action_non_pass,
                    "timeout_occurred": bool(pass_result.get("timeout_occurred", false)),
                    "board_break_occurred": performance.board_break_occurred,
                    "saved_ratio": 0.0,
                    "eligible": false,
                    "ineligible_reason": String(pass_result.get("tempo_ineligible_reason", "")),
                    "potency_bonus_ratio": 0.0,
                    "applied_potency_ratio": 0.0,
                }))
            _:
                fail_test("Unknown replay input: %s" % String(input.get("name", "")))

    return {
        "seed": seed_value,
        "inputs": inputs.duplicate(true),
        "telemetry": f["telemetry"].events_snapshot(),
        "phase": f["turn"].phase,
        "remaining_budget_seconds": f["turn"].turn_budget.remaining_seconds,
        "active_used_seconds": f["turn"].turn_budget.active_used_seconds,
        "timed_out": f["turn"].timed_out_this_turn,
        "pass_timeout": bool(pass_result.get("timeout_occurred", false)),
        "tempo_reason": String(pass_result.get("tempo_ineligible_reason", "")),
    }

func test_same_seed_and_timestamped_named_inputs_reproduce_full_shared_turn_trace() -> void:
    var first := _run_normal(424242, NORMAL_INPUTS)
    var second := _run_normal(424242, NORMAL_INPUTS)

    assert_eq(first, second)
    assert_eq(first["phase"], TurnPhase.ENEMY_RESOLVE)
    assert_eq(first["remaining_budget_seconds"], 55.0)
    assert_eq(first["active_used_seconds"], 35.0)
    assert_false(first["timed_out"])
    assert_true(first["tempo_eligible"])
    assert_gt(first["tempo_potency_bonus_ratio"], 0.0)
    assert_eq(first["telemetry"].size(), 5)

func test_same_timeout_input_stream_reproduces_deterministic_pass_route() -> void:
    var first := _run_timeout(777777, TIMEOUT_INPUTS)
    var second := _run_timeout(777777, TIMEOUT_INPUTS)

    assert_eq(first, second)
    assert_eq(first["phase"], TurnPhase.ENEMY_RESOLVE)
    assert_eq(first["remaining_budget_seconds"], 0.0)
    assert_true(first["timed_out"])
    assert_true(first["pass_timeout"])
    assert_eq(first["tempo_reason"], "TIMEOUT")
    assert_eq(first["telemetry"].size(), 3)
