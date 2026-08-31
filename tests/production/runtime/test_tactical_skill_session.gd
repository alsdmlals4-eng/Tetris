## 전술 스킬 세션이 full tactical pause와 explicit USE 경계를 지키는지 검증한다.
extends GutTest

const PAUSE_CONTROLLER_PATH := "res://src/production/runtime/simulation_pause_controller.gd"
const COMBAT_STATE_PATH := "res://src/production/combat/production_combat_state.gd"
const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const EFFECT_EXECUTOR_PATH := "res://src/production/skill/production_effect_executor.gd"
const TECHNIQUE_RESOLVER_PATH := "res://src/production/skill/production_technique_resolver.gd"
const SKILL_SESSION_PATH := "res://src/production/skill/production_skill_session.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"

func _read_json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _required_paths_exist() -> bool:
	var ready := true
	for path in [
		PAUSE_CONTROLLER_PATH,
		COMBAT_STATE_PATH,
		CATALOG_PATH,
		EFFECT_EXECUTOR_PATH,
		TECHNIQUE_RESOLVER_PATH,
		SKILL_SESSION_PATH,
	]:
		var exists := ResourceLoader.exists(path)
		assert_true(exists, "%s must exist for the tactical Skill session contract" % path)
		ready = ready and exists
	var data_exists := FileAccess.file_exists(SKILL_DATA_PATH)
	assert_true(data_exists, "%s must exist for the tactical Skill session contract" % SKILL_DATA_PATH)
	return ready and data_exists

func _make_fixture() -> Dictionary:
	if not _required_paths_exist():
		return {}
	var catalog = load(CATALOG_PATH).from_dictionary(_read_json(SKILL_DATA_PATH))
	assert_not_null(catalog)
	if catalog == null:
		return {}
	var pause_controller = load(PAUSE_CONTROLLER_PATH).new()
	var player = load(COMBAT_STATE_PATH).new(100)
	var enemy = load(COMBAT_STATE_PATH).new(100)
	player.energy = 30
	player.stock = 3
	var resolver = load(TECHNIQUE_RESOLVER_PATH).new(load(EFFECT_EXECUTOR_PATH).new())
	var session = load(SKILL_SESSION_PATH).new(pause_controller, player, catalog, resolver)
	return {
		"controller": pause_controller,
		"player": player,
		"enemy": enemy,
		"session": session,
	}

func _context(fixture: Dictionary) -> Dictionary:
	return {
		"player": fixture["player"],
		"enemy": fixture["enemy"],
	}

func test_tactical_browse_composes_pause_tokens_and_row_selection_never_spends() -> void:
	var fixture := _make_fixture()
	if fixture.is_empty():
		return
	var controller = fixture["controller"]
	var player = fixture["player"]
	var session = fixture["session"]
	var context := _context(fixture)

	assert_true(session.open())
	assert_true(controller.is_paused())
	assert_true(controller.has_reason("TACTICAL_SKILL"))
	assert_true(session.select_category("ATTACK"))
	var selected: Dictionary = session.select_technique("atk_t1_quick_cut")
	assert_true(bool(selected.get("selected", false)))
	assert_eq(int(player.energy), 30, "selecting a row must not spend Energy")
	assert_eq(int(player.stock), 3, "selecting a row must not spend Stock")
	assert_eq(int(fixture["enemy"].hp), 100, "selecting a row must not apply an effect")
	assert_eq(String(session.selected_detail().get("id", "")), "atk_t1_quick_cut")
	assert_true(bool(session.readiness("atk_t1_quick_cut", context).get("ready", false)))

	var system_token: int = controller.acquire("SYSTEM_MENU")
	assert_gt(system_token, 0)
	var cancelled: Dictionary = session.cancel()
	assert_true(bool(cancelled.get("cancelled", false)))
	assert_true(controller.is_paused(), "SYSTEM_MENU must keep pause active after Skill cancel")
	assert_false(controller.has_reason("TACTICAL_SKILL"))
	assert_eq(int(player.energy), 30)
	assert_eq(int(player.stock), 3)
	assert_true(controller.release(system_token))
	assert_false(controller.is_paused())

func test_explicit_use_commits_once_and_releases_only_the_tactical_pause() -> void:
	var fixture := _make_fixture()
	if fixture.is_empty():
		return
	var controller = fixture["controller"]
	var player = fixture["player"]
	var enemy = fixture["enemy"]
	var session = fixture["session"]
	var context := _context(fixture)

	assert_true(session.open())
	assert_true(session.select_category("ATTACK"))
	assert_true(bool(session.select_technique("atk_t1_quick_cut").get("selected", false)))
	var committed: Dictionary = session.commit_selected(context)
	assert_true(bool(committed.get("committed", false)))
	assert_eq(int(player.energy), 22)
	assert_eq(int(player.stock), 2)
	assert_eq(int(enemy.hp), 86)
	assert_false(controller.is_paused())

	var second_commit: Dictionary = session.commit_selected(context)
	assert_false(bool(second_commit.get("committed", false)))
	assert_eq(int(player.energy), 22, "USE may spend a selected Technique only once")
	assert_eq(int(player.stock), 2, "USE may spend a selected Technique only once")
	assert_eq(int(enemy.hp), 86, "USE may apply a selected Technique only once")

func test_future_time_primitive_fails_closed_without_partial_spend() -> void:
	var fixture := _make_fixture()
	if fixture.is_empty():
		return
	var player = fixture["player"]
	var session = fixture["session"]
	var context := _context(fixture)
	player.energy = 30
	player.stock = 6

	assert_true(session.open())
	assert_true(session.select_category("SUPPORT"))
	var selected: Dictionary = session.select_technique("sup_t6_breather")
	assert_true(bool(selected.get("selected", false)))
	var readiness: Dictionary = session.readiness("sup_t6_breather", context)
	assert_false(bool(readiness.get("ready", true)))
	assert_eq(String(readiness.get("reason", "")), "EFFECT_NOT_READY")
	var committed: Dictionary = session.commit_selected(context)
	assert_false(bool(committed.get("committed", false)))
	assert_eq(String(committed.get("reason", "")), "EFFECT_NOT_READY")
	assert_eq(int(player.energy), 30)
	assert_eq(int(player.stock), 6)
