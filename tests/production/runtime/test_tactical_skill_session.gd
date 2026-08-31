## 현재 Combo로 스킬을 자동 해석하고 CONFIRM에서만 원자적으로 소비하는지 검증한다.
extends GutTest

const PAUSE_PATH := "res://src/production/runtime/simulation_pause_controller.gd"
const COMBAT_PATH := "res://src/production/combat/production_combat_state.gd"
const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const EXECUTOR_PATH := "res://src/production/skill/production_effect_executor.gd"
const RESOLVER_PATH := "res://src/production/skill/production_technique_resolver.gd"
const SESSION_PATH := "res://src/production/skill/production_skill_session.gd"
const SKILL_DATA := "res://data/production/vanguard_skill_seed.json"

func _fixture() -> Dictionary:
	var catalog = load(CATALOG_PATH).from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA)))
	if catalog == null:
		return {}
	var pause = load(PAUSE_PATH).new()
	var player = load(COMBAT_PATH).new(100)
	var enemy = load(COMBAT_PATH).new(100)
	var board_opportunity = load("res://src/production/runtime/player_board_opportunity_state.gd").new()
	var resolver = load(RESOLVER_PATH).new(load(EXECUTOR_PATH).new())
	return {"pause": pause, "player": player, "enemy": enemy, "board_opportunity": board_opportunity, "session": load(SESSION_PATH).new(pause, player, catalog, resolver)}

func _context(fixture: Dictionary) -> Dictionary:
	return {"player": fixture["player"], "enemy": fixture["enemy"], "board_opportunity": fixture["board_opportunity"], "current_action_kind": "DIRECT_HP_RATIO"}

func test_category_preview_uses_opening_c5_without_manual_lower_stage_selection_or_spend() -> void:
	var fixture := _fixture()
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var session = fixture["session"]
	player.energy = 20
	player.stock = 5
	assert_true(session.open())
	assert_false(session.has_method("select_technique"))
	var preview: Dictionary = session.select_category("ATTACK", _context(fixture))
	assert_true(bool(preview.get("ready", false)))
	assert_eq(int(preview.get("opening_combo", 0)), 5)
	assert_eq(int(preview.get("resolved_stage", 0)), 5)
	assert_eq(int(preview.get("converted_combo", -1)), 0)
	assert_eq(String(preview.get("display_name", "")), "Severing Drive")
	assert_eq(player.energy, 20)
	assert_eq(player.stock, 5)

func test_shortage_preview_uses_highest_feasible_lower_stage_only_on_confirm() -> void:
	var fixture := _fixture()
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var enemy = fixture["enemy"]
	var session = fixture["session"]
	player.energy = 8
	player.stock = 5
	assert_true(session.open())
	var preview: Dictionary = session.select_category("ATTACK", _context(fixture))
	assert_true(bool(preview.get("ready", false)))
	assert_eq(int(preview.get("resolved_stage", 0)), 3)
	assert_eq(int(preview.get("converted_combo", -1)), 2)
	assert_eq(player.energy, 8)
	assert_eq(player.stock, 5)
	assert_true(bool(session.commit_selected(_context(fixture)).get("committed", false)))
	assert_eq(player.energy, 4)
	assert_eq(player.stock, 0)
	assert_eq(enemy.hp, 72)

func test_cancel_and_second_confirm_do_not_spend_or_apply_twice() -> void:
	var fixture := _fixture()
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var enemy = fixture["enemy"]
	var session = fixture["session"]
	player.energy = 8
	player.stock = 1
	assert_true(session.open())
	assert_true(bool(session.select_category("ATTACK", _context(fixture)).get("ready", false)))
	assert_true(bool(session.cancel().get("canceled", false)))
	assert_eq(player.energy, 8)
	assert_eq(player.stock, 1)
	assert_eq(enemy.hp, 100)
	assert_true(session.open())
	assert_true(bool(session.select_category("ATTACK", _context(fixture)).get("ready", false)))
	assert_true(bool(session.commit_selected(_context(fixture)).get("committed", false)))
	assert_false(bool(session.commit_selected(_context(fixture)).get("committed", false)))
	assert_eq(player.energy, 0)
	assert_eq(player.stock, 0)
	assert_eq(enemy.hp, 86)

func test_stage_inspection_prebrowses_a_technique_without_opening_the_pause_or_spending_resources() -> void:
	var fixture := _fixture()
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var session = fixture["session"]
	player.energy = 7
	player.stock = 0
	assert_false(session.is_open())
	assert_false(session.has_method("select_technique"))
	var detail: Dictionary = session.inspect_stage("DEFENSE", 1, _context(fixture))
	assert_true(bool(detail.get("inspectable", false)))
	assert_eq(int(detail.get("stage", 0)), 1)
	assert_eq(String(detail.get("display_name", "")), "Brace")
	assert_eq(int(detail.get("combo_cost", 0)), 1)
	assert_eq(int(detail.get("mp_cost", 0)), 8)
	assert_eq(player.energy, 7)
	assert_eq(player.stock, 0)
	assert_false(session.is_open(), "prebrowsing must not enter tactical pause or select a payable technique")
