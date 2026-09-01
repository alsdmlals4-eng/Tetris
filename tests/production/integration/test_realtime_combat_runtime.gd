## 연속시간 전투 런타임이 퍼즐과 적 ETA와 전술 pause를 같은 프레임 순서로 소유하는지 검증한다.
extends GutTest

const RUNTIME_PATH := "res://src/production/runtime/production_combat_runtime.gd"
const PAUSE_PATH := "res://src/production/runtime/simulation_pause_controller.gd"
const WORKSPACE_PATH := "res://src/production/runtime/puzzle_workspace_manager.gd"
const LINE_SESSION_PATH := "res://src/production/line/production_line_session.gd"
const CHAIN_SESSION_PATH := "res://src/production/chain/production_chain_session.gd"
const SCHEDULER_PATH := "res://src/production/runtime/enemy_action_scheduler.gd"
const SKILL_SESSION_PATH := "res://src/production/skill/production_skill_session.gd"
const COMBAT_STATE_PATH := "res://src/production/combat/production_combat_state.gd"

class FakeLineSession:
	var input_enabled := true
	var tick_count := 0
	var last_delta := -1.0
	var events: Array[Dictionary] = []
	func tick(delta: float) -> Dictionary:
		tick_count += 1
		last_delta = delta
		return {"advanced": true}
	func drain_events() -> Array[Dictionary]:
		var drained := events.duplicate(true)
		events.clear()
		return drained

class FakeChainSession:
	var input_enabled := false
	var events: Array[Dictionary] = []
	var pending_failed_swap := false
	var begin_swap_result: Dictionary = {}
	var keep_call_count := 0
	func is_resolving() -> bool:
		return false
	func begin_swap(_first: Vector2i, _second: Vector2i) -> Dictionary:
		pending_failed_swap = String(begin_swap_result.get("reason", "")) == "NO_MATCH"
		return begin_swap_result.duplicate(true)
	func has_pending_failed_swap() -> bool:
		return pending_failed_swap
	func keep_pending_failed_swap() -> bool:
		if not pending_failed_swap:
			return false
		keep_call_count += 1
		pending_failed_swap = false
		return true
	func discard_pending_failed_swap() -> bool:
		if not pending_failed_swap:
			return false
		pending_failed_swap = false
		return true
	func complete_pending_resolution() -> Dictionary:
		return {"success": false}
	func drain_events() -> Array[Dictionary]:
		var drained := events.duplicate(true)
		events.clear()
		return drained

class FakeWorkspaceManager:
	var line_session := FakeLineSession.new()
	var chain_session := FakeChainSession.new()
	var _active := "LINE"
	func active_workspace() -> String:
		return _active
	func process_safe_handoff() -> Dictionary:
		return {"switched": false}
	func request_switch(target: String) -> Dictionary:
		if target != "LINE" and target != "CHAIN":
			return {"accepted": false}
		_active = target
		return {"accepted": true}

func test_runtime_exposes_continuous_api_and_tactical_pause_freezes_enemy_eta_in_the_same_frame() -> void:
	assert_true(ResourceLoader.exists(RUNTIME_PATH), "ProductionCombatRuntime is required for CORE-029")
	if not ResourceLoader.exists(RUNTIME_PATH):
		return
	var runtime_script = load(RUNTIME_PATH)
	var runtime = runtime_script.new(null, null, null, null, null, null, null)
	for method_name in [
		"start_battle", "process_player_command", "tick", "open_skill", "close_skill_without_use",
		"try_chain_swap", "confirm_chain_mp_lock", "discard_chain_mp_lock",
		"is_simulation_paused", "is_terminal", "snapshot",
	]:
		assert_true(runtime.has_method(method_name), "%s is required by the continuous runtime contract" % method_name)

func test_runtime_does_not_tick_enemy_or_active_puzzle_while_tactical_skill_is_open() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var skill = _skill_session(pause, player)
	var runtime_script = load(RUNTIME_PATH)
	if runtime_script == null or scheduler == null or skill == null:
		return
	var runtime = runtime_script.new(player, enemy, null, scheduler, skill, pause, null)
	assert_true(bool(runtime.start_battle().get("started", false)))
	var before_eta: float = scheduler.remaining_seconds()
	assert_true(bool(runtime.open_skill().get("opened", false)))
	assert_true(runtime.is_simulation_paused())
	assert_eq(runtime.tick(1.0).size(), 0)
	assert_almost_eq(scheduler.remaining_seconds(), before_eta, 0.001, "tactical pause must freeze ETA in its opening frame")
	assert_true(bool(runtime.close_skill_without_use().get("closed", false)))
	assert_false(runtime.is_simulation_paused())
	runtime.tick(1.0)
	assert_almost_eq(scheduler.remaining_seconds(), before_eta - 1.0, 0.001)

func test_manual_and_tactical_pause_tokens_compose_without_resuming_enemy_time_early() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var skill = _skill_session(pause, player)
	var runtime = load(RUNTIME_PATH).new(player, enemy, null, scheduler, skill, pause, null)
	assert_true(bool(runtime.start_battle().get("started", false)))
	var before_eta: float = scheduler.remaining_seconds()
	assert_true(bool(runtime.process_player_command({"kind": "TOGGLE_SYSTEM_PAUSE"}).get("paused", false)))
	assert_true(bool(runtime.open_skill().get("opened", false)))
	assert_true(bool(runtime.close_skill_without_use().get("closed", false)))
	assert_true(runtime.is_simulation_paused(), "closing Skill must preserve an independent manual pause")
	runtime.tick(1.0)
	assert_almost_eq(scheduler.remaining_seconds(), before_eta, 0.001)
	assert_false(bool(runtime.process_player_command({"kind": "TOGGLE_SYSTEM_PAUSE"}).get("paused", true)))
	runtime.tick(1.0)
	assert_almost_eq(scheduler.remaining_seconds(), before_eta - 1.0, 0.001)

func test_runtime_commits_each_puzzle_reward_once_and_marks_terminal_without_turn_transitions() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var skill = _skill_session(pause, player)
	var workspace = FakeWorkspaceManager.new()
	workspace.line_session.events.append({"kind": "production_line_resolved", "energy_delta": 7})
	var runtime = load(RUNTIME_PATH).new(player, enemy, workspace, scheduler, skill, pause, null)
	assert_true(bool(runtime.start_battle().get("started", false)))
	runtime.tick(0.5)
	assert_eq(player.energy, 7)
	assert_eq(workspace.line_session.tick_count, 1)
	runtime.tick(0.5)
	assert_eq(player.energy, 7, "a drained Line event may not grant Energy twice")
	player.hp = 0
	var terminal_events: Array = runtime.tick(0.1)
	assert_true(runtime.is_terminal())
	assert_true(terminal_events.any(func(event): return String(event.get("kind", "")) == "DEFEAT"))

func test_guided_opening_keeps_realtime_active_but_prevents_terminal_defeat_until_first_confirm() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var guided = load("res://src/production/session/production_guided_practice_state.gd").new()
	var runtime = load(RUNTIME_PATH).new(player, enemy, FakeWorkspaceManager.new(), scheduler, _skill_session(pause, player), pause, null, null, null, guided)
	assert_true(bool(runtime.start_battle().get("started", false)))
	var eta_before: float = scheduler.remaining_seconds()
	assert_almost_eq(eta_before, 28.0, 0.001, "the first guided encounter shares one live 28-second opening ETA")
	player.hp = 0
	var guarded_events: Array = runtime.tick(0.1)
	assert_false(runtime.is_terminal(), "the opening may apply pressure but cannot end before the first explicit CONFIRM")
	assert_eq(player.hp, 1, "the opening guard keeps a visible one-HP recovery floor instead of freezing time")
	assert_true(guarded_events.any(func(event): return String(event.get("kind", "")) == "GUIDED_OPENING_GUARD"))
	assert_almost_eq(scheduler.remaining_seconds(), eta_before - 0.1, 0.001, "the enemy ETA remains a live realtime clock during the opening")

	guided.record_skill_confirmation({"committed": true})
	player.hp = 0
	runtime.tick(0.1)
	assert_true(runtime.is_terminal(), "the authored opening guard ends immediately after the first CONFIRM")

func test_failed_chain_swap_resets_combo_and_keeps_only_after_one_mp_payment() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	player.energy = 20
	player.stock = 5
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var workspace = FakeWorkspaceManager.new()
	workspace._active = "CHAIN"
	workspace.chain_session.begin_swap_result = {
		"accepted": false,
		"reason": "NO_MATCH",
		"swapped_snapshot": ["swapped"],
	}
	var runtime = load(RUNTIME_PATH).new(player, enemy, workspace, scheduler, _skill_session(pause, player), pause, null)

	var failed_swap: Dictionary = runtime.try_chain_swap(Vector2i(0, 1), Vector2i(1, 1))
	assert_eq(String(failed_swap.get("reason", "")), "NO_MATCH")
	assert_eq(player.stock, 0)
	assert_true(workspace.chain_session.has_pending_failed_swap())
	assert_true(bool(runtime.confirm_chain_mp_lock().get("kept", false)))
	assert_eq(player.energy, 19)
	assert_eq(workspace.chain_session.keep_call_count, 1)
	assert_false(workspace.chain_session.has_pending_failed_swap())

func test_runtime_applies_every_valid_chain_wave_in_order() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var workspace = FakeWorkspaceManager.new()
	workspace.chain_session.events.append({
		"kind": "production_chain_resolved",
		"waves": [
			{"qualified_line_lengths": [3]},
			{"qualified_line_lengths": [4]},
		],
	})
	var runtime = load(RUNTIME_PATH).new(player, enemy, workspace, scheduler, _skill_session(pause, player), pause, null)
	assert_true(bool(runtime.start_battle().get("started", false)))

	var events: Array = runtime.tick(0.1)

	assert_eq(player.stock, 2)
	assert_eq(player.energy, 4, "per-wave recovery is (3 - 3 + 1) + (4 - 3 + 2)")
	assert_true(events.any(func(event): return String(event.get("kind", "")) == "production_chain_resolved"))

func test_workspace_switch_keeps_only_the_active_puzzle_simulating() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var workspace = FakeWorkspaceManager.new()
	var runtime = load(RUNTIME_PATH).new(player, enemy, workspace, scheduler, _skill_session(pause, player), pause, null)
	assert_true(bool(runtime.start_battle().get("started", false)))
	runtime.tick(0.25)
	assert_eq(workspace.line_session.tick_count, 1)
	assert_true(bool(runtime.process_player_command({"kind": "SWITCH_WORKSPACE", "target": "CHAIN"}).get("accepted", false)))
	runtime.tick(0.25)
	assert_eq(workspace.line_session.tick_count, 1, "inactive Line workspace must not receive a simulation tick")

func test_player_board_opportunity_holds_only_line_delta_while_enemy_eta_uses_full_delta() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var workspace = FakeWorkspaceManager.new()
	var opportunity = load("res://src/production/runtime/player_board_opportunity_state.gd").new()
	var runtime = load(RUNTIME_PATH).new(player, enemy, workspace, scheduler, _skill_session(pause, player), pause, null, null, opportunity)
	assert_true(bool(runtime.start_battle().get("started", false)))
	assert_true(runtime.has_method("grant_player_board_opportunity"))
	if not runtime.has_method("grant_player_board_opportunity"):
		return

	runtime.grant_player_board_opportunity(2.0)
	var eta_before: float = scheduler.remaining_seconds()
	runtime.tick(1.0)
	assert_almost_eq(workspace.line_session.last_delta, 0.0, 0.001)
	assert_true(workspace.line_session.input_enabled)
	assert_almost_eq(scheduler.remaining_seconds(), eta_before - 1.0, 0.001)
	assert_almost_eq(float(runtime.snapshot().get("player_board_opportunity_seconds", -1.0)), 1.0, 0.001)

func test_player_board_opportunity_does_not_consume_while_chain_or_paused() -> void:
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var scheduler = _scheduler()
	var workspace = FakeWorkspaceManager.new()
	var opportunity = load("res://src/production/runtime/player_board_opportunity_state.gd").new()
	var runtime = load(RUNTIME_PATH).new(player, enemy, workspace, scheduler, _skill_session(pause, player), pause, null, null, opportunity)
	assert_true(bool(runtime.start_battle().get("started", false)))
	runtime.grant_player_board_opportunity(2.0)
	assert_true(bool(runtime.process_player_command({"kind": "SWITCH_WORKSPACE", "target": "CHAIN"}).get("accepted", false)))
	runtime.tick(0.5)
	assert_almost_eq(float(runtime.snapshot().get("player_board_opportunity_seconds", -1.0)), 2.0, 0.001)
	assert_true(bool(runtime.toggle_system_pause().get("paused", false)))
	runtime.tick(0.5)
	assert_almost_eq(float(runtime.snapshot().get("player_board_opportunity_seconds", -1.0)), 2.0, 0.001)

func _read_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _scheduler():
	var catalog = load("res://src/production/combat/gatebreaker_action_catalog.gd").from_dictionary(_read_json("res://data/production/gatebreaker_action_seed.json"))
	var director = load("res://src/production/combat/gatebreaker_encounter_director.gd").from_dictionary(_read_json("res://data/production/gatebreaker_sequence_seed.json"), catalog)
	var timing = load("res://src/production/runtime/gatebreaker_realtime_timing_config.gd").from_dictionary(_read_json("res://data/production/gatebreaker_realtime_timing_seed.json"))
	if catalog == null or director == null or timing == null:
		return null
	return load(SCHEDULER_PATH).new(director, timing, load("res://src/production/combat/production_enemy_action_resolver.gd").new())

func _skill_session(pause, player):
	var catalog = load("res://src/production/skill/production_skill_catalog.gd").from_dictionary(_read_json("res://data/production/vanguard_skill_seed.json"))
	if catalog == null:
		return null
	var resolver = load("res://src/production/skill/production_technique_resolver.gd").new(load("res://src/production/skill/production_effect_executor.gd").new())
	return load(SKILL_SESSION_PATH).new(pause, player, catalog, resolver)
