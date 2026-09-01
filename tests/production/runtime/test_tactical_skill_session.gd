## 전술 스킬이 현재 Combo 프리뷰와 원자적 CONFIRM 경계를 지키는지 검증한다.
extends GutTest

const PAUSE_CONTROLLER_PATH := "res://src/production/runtime/simulation_pause_controller.gd"
const COMBAT_STATE_PATH := "res://src/production/combat/production_combat_state.gd"
const RESPONSE_STATE_PATH := "res://src/production/combat/production_response_state.gd"
const ACTION_CATALOG_PATH := "res://src/production/combat/gatebreaker_action_catalog.gd"
const ENCOUNTER_DIRECTOR_PATH := "res://src/production/combat/gatebreaker_encounter_director.gd"
const ENEMY_RESOLVER_PATH := "res://src/production/combat/production_enemy_action_resolver.gd"
const SCHEDULER_PATH := "res://src/production/runtime/enemy_action_scheduler.gd"
const TIMING_PATH := "res://src/production/runtime/gatebreaker_realtime_timing_config.gd"
const BOARD_OPPORTUNITY_PATH := "res://src/production/runtime/player_board_opportunity_state.gd"
const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const EFFECT_EXECUTOR_PATH := "res://src/production/skill/production_effect_executor.gd"
const TECHNIQUE_RESOLVER_PATH := "res://src/production/skill/production_technique_resolver.gd"
const SKILL_SESSION_PATH := "res://src/production/skill/production_skill_session.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const ACTION_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const SEQUENCE_DATA_PATH := "res://data/production/gatebreaker_sequence_seed.json"
const TIMING_DATA_PATH := "res://data/production/gatebreaker_realtime_timing_seed.json"

class FailingExecutor:
	var _real_executor
	var _fail_on_execution: int
	var _execution_count := 0

	func _init(real_executor, fail_on_execution: int) -> void:
		_real_executor = real_executor
		_fail_on_execution = fail_on_execution

	func execute(effect: Dictionary, context: Dictionary) -> Dictionary:
		_execution_count += 1
		if _execution_count == _fail_on_execution:
			return {"ok": false, "reason": "FORCED_EXECUTION_FAILURE"}
		return _real_executor.execute(effect, context)

class RejectingReserve:
	var _remaining_seconds := 0.0

	func grant(seconds: float) -> Dictionary:
		if seconds <= 0.0:
			return {"granted": false, "remaining_seconds": _remaining_seconds}
		_remaining_seconds += seconds
		return {"granted": true, "granted_seconds": seconds, "remaining_seconds": _remaining_seconds}

	func remaining_seconds() -> float:
		return _remaining_seconds

	func snapshot_state() -> Dictionary:
		return {"remaining_seconds": _remaining_seconds}

	func restore_state(_snapshot: Dictionary) -> bool:
		return false

func _read_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _required_paths_exist() -> bool:
	var ready := true
	for path in [
		PAUSE_CONTROLLER_PATH,
		COMBAT_STATE_PATH,
		RESPONSE_STATE_PATH,
		ACTION_CATALOG_PATH,
		ENCOUNTER_DIRECTOR_PATH,
		ENEMY_RESOLVER_PATH,
		SCHEDULER_PATH,
		TIMING_PATH,
		BOARD_OPPORTUNITY_PATH,
		CATALOG_PATH,
		EFFECT_EXECUTOR_PATH,
		TECHNIQUE_RESOLVER_PATH,
		SKILL_SESSION_PATH,
	]:
		var exists := ResourceLoader.exists(path)
		assert_true(exists, "%s must exist for the Combo-resolved Skill contract" % path)
		ready = ready and exists
	for path in [SKILL_DATA_PATH, ACTION_DATA_PATH, SEQUENCE_DATA_PATH, TIMING_DATA_PATH]:
		var data_exists := FileAccess.file_exists(path)
		assert_true(data_exists, "%s must exist for the Combo-resolved Skill contract" % path)
		ready = ready and data_exists
	return ready

func _scheduler():
	var action_catalog = load(ACTION_CATALOG_PATH).from_dictionary(_read_json(ACTION_DATA_PATH))
	var director = load(ENCOUNTER_DIRECTOR_PATH).from_dictionary(_read_json(SEQUENCE_DATA_PATH), action_catalog)
	var timing = load(TIMING_PATH).from_dictionary(_read_json(TIMING_DATA_PATH))
	if action_catalog == null or director == null or timing == null:
		return null
	return load(SCHEDULER_PATH).new(director, timing, load(ENEMY_RESOLVER_PATH).new())

func _make_fixture(catalog_override = null, resolver_override = null, reserve_override = null) -> Dictionary:
	if not _required_paths_exist():
		return {}
	var catalog = catalog_override
	if catalog == null:
		catalog = load(CATALOG_PATH).from_dictionary(_read_json(SKILL_DATA_PATH))
	assert_not_null(catalog)
	if catalog == null:
		return {}
	var scheduler = _scheduler()
	assert_not_null(scheduler)
	if scheduler == null or not bool(scheduler.start().get("started", false)):
		return {}
	var pause_controller = load(PAUSE_CONTROLLER_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	var response = load(RESPONSE_STATE_PATH).new()
	var reserve = reserve_override if reserve_override != null else load(BOARD_OPPORTUNITY_PATH).new()
	var resolver = resolver_override if resolver_override != null else load(TECHNIQUE_RESOLVER_PATH).new(load(EFFECT_EXECUTOR_PATH).new())
	var session = load(SKILL_SESSION_PATH).new(pause_controller, player, catalog, resolver)
	return {
		"controller": pause_controller,
		"player": player,
		"enemy": enemy,
		"response": response,
		"reserve": reserve,
		"scheduler": scheduler,
		"session": session,
	}

func _context(fixture: Dictionary) -> Dictionary:
	var scheduler = fixture["scheduler"]
	return {
		"player": fixture["player"],
		"enemy": fixture["enemy"],
		"response_state": fixture["response"],
		"board_opportunity": fixture["reserve"],
		"enemy_scheduler": scheduler,
		"telegraph_action_id": scheduler.current_action_id(),
		"current_action_kind": scheduler.current_action_kind(),
	}

func _rollback_catalog(effects: Array):
	return load(CATALOG_PATH).from_dictionary({
		"schema_version": 2,
		"balance_status": "TEST_ONLY",
		"techniques": [{
			"id": "sup_c2_rollback_fixture",
			"lane": "SUPPORT",
			"stage": 2,
			"combo_cost": 2,
			"mp_cost": 10,
			"display_name": "Rollback Fixture",
			"preview_lines": ["Verify atomic effect rollback."],
			"effects": effects,
		}],
	})

func _failing_resolver(fail_on_execution: int):
	var failing_executor = FailingExecutor.new(load(EFFECT_EXECUTOR_PATH).new(), fail_on_execution)
	return load(TECHNIQUE_RESOLVER_PATH).new(failing_executor)

func test_category_preview_resolves_current_c5_without_manual_lower_stage_selection() -> void:
	var fixture := _make_fixture()
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var session = fixture["session"]
	player.energy = 30
	player.stock = 5
	var context := _context(fixture)

	assert_true(session.open())
	var preview: Dictionary = session.select_category("ATTACK", context)
	assert_true(bool(preview.get("ready", false)))
	assert_eq(int(preview.get("opening_combo", -1)), 5)
	assert_eq(int(preview.get("resolved_stage", -1)), 5)
	assert_eq(int(preview.get("converted_combo", -1)), 0)
	assert_eq(String(preview.get("display_name", "")), "Severing Drive")
	assert_false(session.has_method("select_technique"), "manual Technique selection must not survive the Combo-resolved flow")
	assert_eq(player.energy, 30, "preview must not spend MP")
	assert_eq(player.stock, 5, "preview must not spend Combo")

func test_previewed_shortage_fallback_uses_the_highest_feasible_lower_stage_on_confirm() -> void:
	var fixture := _make_fixture()
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var enemy = fixture["enemy"]
	var session = fixture["session"]
	player.energy = 13
	player.stock = 5
	var context := _context(fixture)

	assert_true(session.open())
	var preview: Dictionary = session.select_category("ATTACK", context)
	assert_true(bool(preview.get("ready", false)))
	assert_eq(int(preview.get("resolved_stage", -1)), 4)
	assert_eq(int(preview.get("converted_combo", -1)), 1)
	assert_eq(int(preview.get("mp_cost", -1)), 18)
	assert_eq(player.energy, 13, "fallback preview must not mint or spend MP")
	assert_eq(player.stock, 5, "fallback preview must not convert Combo early")

	var committed: Dictionary = session.commit_selected(context)
	assert_true(bool(committed.get("committed", false)))
	assert_eq(player.energy, 0)
	assert_eq(player.stock, 0)
	assert_eq(enemy.hp, 72)

func test_cancel_and_lane_replacement_leave_resources_and_effect_owners_unchanged() -> void:
	var fixture := _make_fixture()
	if fixture.is_empty():
		return
	var controller = fixture["controller"]
	var player = fixture["player"]
	var enemy = fixture["enemy"]
	var session = fixture["session"]
	player.energy = 30
	player.stock = 3
	var context := _context(fixture)

	assert_true(session.open())
	assert_true(bool(session.select_category("ATTACK", context).get("ready", false)))
	assert_true(bool(session.select_category("SUPPORT", context).get("ready", false)))
	assert_eq(player.energy, 30)
	assert_eq(player.stock, 3)
	assert_eq(enemy.hp, 100)
	assert_true(controller.is_paused())
	var canceled: Dictionary = session.cancel()
	assert_true(bool(canceled.get("canceled", false)))
	assert_false(controller.is_paused())
	assert_eq(player.energy, 30)
	assert_eq(player.stock, 3)
	assert_eq(enemy.hp, 100)

func test_explicit_confirm_commits_the_preview_once_then_releases_only_tactical_pause() -> void:
	var fixture := _make_fixture()
	if fixture.is_empty():
		return
	var controller = fixture["controller"]
	var player = fixture["player"]
	var enemy = fixture["enemy"]
	var session = fixture["session"]
	player.energy = 30
	player.stock = 1
	var context := _context(fixture)

	assert_true(session.open())
	assert_true(bool(session.select_category("ATTACK", context).get("ready", false)))
	var committed: Dictionary = session.commit_selected(context)
	assert_true(bool(committed.get("committed", false)))
	assert_eq(player.energy, 20)
	assert_eq(player.stock, 0)
	assert_eq(enemy.hp, 88)
	assert_false(controller.is_paused())

	var second_commit: Dictionary = session.commit_selected(context)
	assert_false(bool(second_commit.get("committed", false)))
	assert_eq(player.energy, 20)
	assert_eq(player.stock, 0)
	assert_eq(enemy.hp, 88)

func test_post_preflight_execution_failure_restores_resources_and_every_mutable_effect_owner() -> void:
	var catalog = _rollback_catalog([
		{"op": "DAMAGE_SINGLE", "magnitude": 10},
		{"op": "HEAL_SELF", "magnitude": 15},
		{"op": "MITIGATE_CURRENT_DIRECT", "magnitude": 20},
		{"op": "GRANT_PLAYER_BOARD_OPPORTUNITY", "magnitude": 2},
		{"op": "ADJUST_CURRENT_ENEMY_ETA", "magnitude": 2},
		{"op": "HEAL_SELF", "magnitude": 1},
	])
	var fixture := _make_fixture(catalog, _failing_resolver(6))
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var enemy = fixture["enemy"]
	var response = fixture["response"]
	var reserve = fixture["reserve"]
	var scheduler = fixture["scheduler"]
	var session = fixture["session"]
	player.energy = 20
	player.stock = 2
	player.hp = 50
	assert_true(response.configure_direct_mitigation(scheduler.current_action_id(), 10))
	var response_before: Dictionary = response.modifiers_for_action(scheduler.current_action_id())
	reserve.grant(3.0)
	var eta_before: float = scheduler.remaining_seconds()
	var context := _context(fixture)

	assert_true(session.open())
	assert_true(bool(session.select_category("SUPPORT", context).get("ready", false)))
	var result: Dictionary = session.commit_selected(context)
	assert_false(bool(result.get("committed", true)))
	assert_eq(String(result.get("reason", "")), "FORCED_EXECUTION_FAILURE")
	assert_eq(player.hp, 50)
	assert_eq(player.energy, 20)
	assert_eq(player.stock, 2)
	assert_eq(enemy.hp, 100)
	assert_eq(response.modifiers_for_action(scheduler.current_action_id()), response_before)
	assert_almost_eq(reserve.remaining_seconds(), 3.0, 0.001)
	assert_almost_eq(scheduler.remaining_seconds(), eta_before, 0.001)
	assert_true(session.is_open(), "an unsuccessful Confirm must keep the deterministic tactical recovery state open")

func test_restore_failure_is_fail_closed_and_keeps_tactical_pause_open() -> void:
	var catalog = _rollback_catalog([
		{"op": "GRANT_PLAYER_BOARD_OPPORTUNITY", "magnitude": 2},
		{"op": "HEAL_SELF", "magnitude": 1},
	])
	var rejecting_reserve := RejectingReserve.new()
	var fixture := _make_fixture(catalog, _failing_resolver(2), rejecting_reserve)
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var controller = fixture["controller"]
	var session = fixture["session"]
	player.energy = 20
	player.stock = 2
	var context := _context(fixture)

	assert_true(session.open())
	assert_true(bool(session.select_category("SUPPORT", context).get("ready", false)))
	var result: Dictionary = session.commit_selected(context)
	assert_false(bool(result.get("committed", true)))
	assert_eq(String(result.get("reason", "")), "ROLLBACK_FAILED")
	assert_true(session.is_open())
	assert_true(controller.is_paused())
