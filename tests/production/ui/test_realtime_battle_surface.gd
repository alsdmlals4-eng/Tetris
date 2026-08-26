## CORE-029 전투 화면이 단일 60/40 퍼즐·전투 표면과 pause 가능한 스킬 문맥을 제공하는지 검증한다.
extends GutTest

const BATTLE_SCENE_PATH := "res://scenes/production/battle.tscn"

func test_battle_surface_has_required_60_40_hierarchy_without_a_turn_rail() -> void:
	assert_true(ResourceLoader.exists(BATTLE_SCENE_PATH), "CORE-029 production battle scene must exist")
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var scene = load(BATTLE_SCENE_PATH)
	var battle = scene.instantiate()
	add_child_autofree(battle)
	for node_path in [
		"MainRow/PuzzleColumn/ModeBar",
		"MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
		"MainRow/PuzzleColumn/PuzzleHost/ChainBoardView",
		"MainRow/CombatColumn/ThreatPanel",
		"MainRow/CombatColumn/CombatStage",
		"MainRow/CombatColumn/ResourceBar",
		"MainRow/CombatColumn/SkillPanel",
	]:
		assert_not_null(battle.get_node_or_null(node_path), "%s is required by the 60/40 battle composition" % node_path)
	var puzzle_column: Control = battle.get_node_or_null("MainRow/PuzzleColumn")
	var combat_column: Control = battle.get_node_or_null("MainRow/CombatColumn")
	assert_almost_eq(puzzle_column.size_flags_stretch_ratio, 0.6, 0.01)
	assert_almost_eq(combat_column.size_flags_stretch_ratio, 0.4, 0.01)
	assert_eq(battle.find_children("*Turn*", "", true, false).size(), 0, "CORE-029 must not restore a turn rail")

func test_skill_panel_is_pause_capable_and_chain_board_starts_hidden() -> void:
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var skill_panel: Control = battle.get_node("MainRow/CombatColumn/SkillPanel")
	var skill_button: Button = battle.get_node("MainRow/PuzzleColumn/ModeBar/SkillButton")
	var chain_view: Control = battle.get_node("MainRow/PuzzleColumn/PuzzleHost/ChainBoardView")
	assert_eq(skill_panel.process_mode, Node.PROCESS_MODE_WHEN_PAUSED)
	assert_eq(skill_button.process_mode, Node.PROCESS_MODE_WHEN_PAUSED)
	assert_false(chain_view.visible, "LINE is the initial active workspace; Chain should not share the puzzle surface")

func test_mode_buttons_switch_the_single_visible_puzzle_surface() -> void:
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	assert_true(battle.has_method("set_active_workspace"), "battle UI must expose one explicit workspace state")
	if not battle.has_method("set_active_workspace"):
		return
	battle.set_active_workspace("CHAIN")
	assert_false(battle.get_node("MainRow/PuzzleColumn/PuzzleHost/LineBoardView").visible)
	assert_true(battle.get_node("MainRow/PuzzleColumn/PuzzleHost/ChainBoardView").visible)
	battle.set_active_workspace("LINE")
	assert_true(battle.get_node("MainRow/PuzzleColumn/PuzzleHost/LineBoardView").visible)
	assert_false(battle.get_node("MainRow/PuzzleColumn/PuzzleHost/ChainBoardView").visible)

func test_skill_panel_exposes_explicit_lane_tier_and_use_controls() -> void:
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	for node_path in ["Attack", "Defense", "Support", "Tier1", "Tier2", "Tier3", "Tier4", "Tier5", "Tier6", "UseButton"]:
		assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillPanel/%s" % node_path))
	assert_true(battle.has_method("select_skill_category"))
	assert_true(battle.has_method("select_skill_tier"))
