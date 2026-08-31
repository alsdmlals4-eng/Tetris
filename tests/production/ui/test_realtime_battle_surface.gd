## CORE-029 전투 화면이 단일 50/50 퍼즐·전투 표면과 pause 가능한 스킬 문맥을 제공하는지 검증한다.
extends GutTest

const BATTLE_SCENE_PATH := "res://scenes/production/battle.tscn"

class TerminalRuntime:
	var _snapshot: Dictionary

	func _init(snapshot: Dictionary) -> void:
		_snapshot = snapshot

	func snapshot() -> Dictionary:
		return _snapshot

	func is_skill_open() -> bool:
		return false

func _has_physical_key(action_name: String, expected_key: Key) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == expected_key:
			return true
	return false

func test_battle_surface_has_required_50_50_hierarchy_without_a_turn_rail() -> void:
	assert_true(ResourceLoader.exists(BATTLE_SCENE_PATH), "CORE-029 production battle scene must exist")
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var scene = load(BATTLE_SCENE_PATH)
	var battle = scene.instantiate()
	add_child_autofree(battle)
	for node_path in [
		"MainRow/PuzzleColumn/ModeFrame/ModeBar",
		"MainRow/PuzzleColumn/ChainLockFrame/LockPrompt/KeepButton",
		"MainRow/PuzzleColumn/ChainLockFrame/LockPrompt/DiscardButton",
		"MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
		"MainRow/PuzzleColumn/PuzzleHost/ChainBoardView",
		"MainRow/CombatColumn/ThreatFrame/ThreatPanel",
		"MainRow/PuzzleColumn/PuzzleFeedbackFrame/FeedbackStack/GuidedPracticePrompt",
		"MainRow/CombatColumn/CombatStage",
		"MainRow/CombatColumn/ResourceFrame/ResourceRow/ResourceBar",
		"MainRow/CombatColumn/SkillFrame/SkillPanel",
	]:
		assert_not_null(battle.get_node_or_null(node_path), "%s is required by the 50/50 battle composition" % node_path)
	var puzzle_column: Control = battle.get_node_or_null("MainRow/PuzzleColumn")
	var combat_column: Control = battle.get_node_or_null("MainRow/CombatColumn")
	assert_almost_eq(puzzle_column.size_flags_stretch_ratio, 0.5, 0.01)
	assert_almost_eq(combat_column.size_flags_stretch_ratio, 0.5, 0.01)
	assert_eq(battle.find_children("*Turn*", "", true, false).size(), 0, "CORE-029 must not restore a turn rail")
	assert_false(battle.get_node("MainRow/PuzzleColumn/ChainLockFrame").visible, "a lock choice appears only after a failed Chain swap")

func test_battle_surface_uses_named_theme_and_semantic_visual_frames() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	assert_not_null(battle.theme, "the production battle surface must use its named visual theme")
	for node_path in [
		"MainRow/PuzzleColumn/ModeFrame",
		"MainRow/CombatColumn/ThreatFrame",
		"MainRow/CombatColumn/ResourceFrame",
		"MainRow/CombatColumn/SkillFrame",
	]:
		assert_not_null(battle.get_node_or_null(node_path), "%s must provide a semantic visual hierarchy frame" % node_path)

func test_battle_theme_uses_an_antique_gold_border_over_the_obsidian_surface() -> void:
	var theme: Theme = load("res://resources/production/production_battle_theme.tres")
	var panel_style := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	assert_not_null(panel_style, "the battle theme needs a concrete panel style for the visual canon")
	if panel_style != null:
		assert_gt(panel_style.border_color.r, panel_style.border_color.b, "TETRIS-VISUAL-043 requires antique-gold panel borders instead of the superseded violet-only chrome")

func test_skill_panel_is_pause_capable_and_chain_board_starts_hidden() -> void:
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var skill_panel: Control = battle.get_node("MainRow/CombatColumn/SkillFrame/SkillPanel")
	var skill_button: Button = battle.get_node("MainRow/PuzzleColumn/ModeFrame/ModeBar/SkillButton")
	var chain_view: Control = battle.get_node("MainRow/PuzzleColumn/PuzzleHost/ChainBoardView")
	assert_eq(skill_panel.process_mode, Node.PROCESS_MODE_WHEN_PAUSED)
	assert_eq(skill_button.process_mode, Node.PROCESS_MODE_WHEN_PAUSED)
	assert_false(chain_view.visible, "LINE is the initial active workspace; Chain should not share the puzzle surface")
	assert_true(battle.get_node("MainRow/PuzzleColumn/PuzzleHost/LineBoardView").has_method("bind_line_session"))
	assert_true(chain_view.has_method("bind_chain_session"))

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

func test_puzzle_board_precedes_controls_and_surfaces_tetris_chain_feedback_below_it() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var puzzle_column: VBoxContainer = battle.get_node("MainRow/PuzzleColumn")
	var host: Control = battle.get_node("MainRow/PuzzleColumn/PuzzleHost")
	var feedback_frame: Control = battle.get_node_or_null("MainRow/PuzzleColumn/PuzzleFeedbackFrame")
	var lock_frame: Control = battle.get_node("MainRow/PuzzleColumn/ChainLockFrame")
	var mode_frame: Control = battle.get_node("MainRow/PuzzleColumn/ModeFrame")
	assert_not_null(feedback_frame, "TETRIS and CHAIN outcomes require a persistent text feedback surface")
	if feedback_frame != null:
		assert_lt(puzzle_column.get_children().find(host), puzzle_column.get_children().find(feedback_frame), "the board must keep the available top area")
	assert_lt(puzzle_column.get_children().find(host), puzzle_column.get_children().find(lock_frame), "the conditional Chain decision belongs below the board")
	assert_lt(puzzle_column.get_children().find(host), puzzle_column.get_children().find(mode_frame), "mode guidance belongs below the active puzzle")
	assert_true(battle.has_method("_refresh_puzzle_feedback"))
	assert_not_null(battle.get_node_or_null("MainRow/PuzzleColumn/PuzzleFeedbackFrame/FeedbackStack/PuzzleFeedback"))
	assert_not_null(battle.get_node_or_null("MainRow/PuzzleColumn/PuzzleFeedbackFrame/FeedbackStack/ChainFeedback"))

func test_skill_panel_exposes_category_resolved_preview_and_confirm_controls() -> void:
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	for node_path in ["Attack", "Defense", "Support"]:
		assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/%s" % node_path))
	assert_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/TierGrid"))
	assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/ResolvedPreview"))
	assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/ConfirmButton"))
	assert_true(battle.has_method("select_skill_category"))
	assert_false(battle.has_method("select_skill_tier"))

func test_skill_panel_groups_categories_and_one_resolved_preview_for_the_compact_combat_column() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var skill_panel_path := "MainRow/CombatColumn/SkillFrame/SkillPanel"
	assert_not_null(battle.get_node_or_null("%s/SkillCategories" % skill_panel_path))
	assert_not_null(battle.get_node_or_null("%s/ResolvedPreview" % skill_panel_path))
	assert_not_null(battle.get_node_or_null("%s/ConfirmButton" % skill_panel_path))
	assert_not_null(battle.get_node_or_null("%s/SkillStageSummary" % skill_panel_path))
	assert_not_null(battle.get_node_or_null("%s/SkillStageRail" % skill_panel_path))
	assert_not_null(battle.get_node_or_null("%s/SkillDetailCard" % skill_panel_path))

func test_skill_unavailability_does_not_reintroduce_the_historical_ready_term() -> void:
	var battle_script_text := FileAccess.get_file_as_string("res://src/production/ui/production_battle.gd")
	assert_false(battle_script_text.contains("NO READY TECHNIQUE"), "the current real-time skill surface must not reuse the superseded READY terminology")
	assert_true(battle_script_text.contains("NO AVAILABLE TECHNIQUE"), "unavailable category feedback must describe availability without implying an old stage-advance state")

func test_skill_detail_exposes_a_read_only_stage_rail_and_prebrowse_card_without_restoring_manual_selection() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var skill_panel_path := "MainRow/CombatColumn/SkillFrame/SkillPanel"
	var stage_rail: Control = battle.get_node("%s/SkillStageRail" % skill_panel_path)
	assert_eq(stage_rail.find_children("*", "Button", true, false).size(), 0, "the C1-C10 rail is explanatory only; it must not restore manual stage selection")
	for node_name in ["TechniqueName", "TechniquePurpose", "TechniqueCost", "TechniqueAvailability"]:
		assert_not_null(battle.get_node_or_null("%s/SkillDetailCard/TechniqueStack/%s" % [skill_panel_path, node_name]))
	assert_true(battle.has_method("_refresh_skill_surface"), "the visible card must refresh from the current runtime snapshot")

func test_skill_categories_reserve_illustrated_seal_slots_without_restoring_a_tier_grid() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var expected_texture_paths := {
		"Attack": "res://assets/production/icons/skill_lane_attack_seal_v1.png",
		"Defense": "res://assets/production/icons/skill_lane_defense_seal_v1.png",
		"Support": "res://assets/production/icons/skill_lane_support_seal_v1.png",
	}
	for category_name: String in expected_texture_paths:
		var category: Button = battle.get_node("MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/%s" % category_name)
		var seal: TextureRect = category.get_node_or_null("CategorySeal")
		assert_not_null(seal, "%s needs a bounded category-seal icon slot" % category_name)
		if seal != null:
			assert_eq(seal.mouse_filter, Control.MOUSE_FILTER_IGNORE)
			assert_gte(seal.custom_minimum_size.x, 32.0, "%s seal must remain legible as the compact column changes width" % category_name)
			assert_eq(seal.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s seal must preserve its illustrated aspect" % category_name)
			assert_not_null(seal.texture, "%s must consume its locked category-seal asset" % category_name)
			if seal.texture != null:
				assert_eq(seal.texture.resource_path, expected_texture_paths[category_name])

func test_combat_stage_exposes_a_dedicated_runtime_backdrop_consumer() -> void:
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var backdrop = battle.get_node_or_null("MainRow/CombatColumn/CombatStage/StageBackdrop")
	assert_not_null(backdrop, "CombatStage must own the named backdrop consumer")
	if backdrop == null:
		return
	assert_true(backdrop is TextureRect, "the stage backdrop must consume a Texture2D directly")
	assert_not_null(backdrop.texture, "the stage backdrop needs a deterministic placeholder or production texture")
	assert_eq(backdrop.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "the wide stage slot must cover its full bounds")
	assert_true(backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the decorative backdrop must never intercept battle controls")

func test_combat_stage_reserves_enemy_visual_space_for_gatebreaker_only() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var stage: Control = battle.get_node("MainRow/CombatColumn/CombatStage")
	var gatebreaker: TextureRect = battle.get_node("MainRow/CombatColumn/CombatStage/GatebreakerReference")
	assert_gte(stage.custom_minimum_size.y, 200.0, "the combat stage needs enough dedicated height for an imposing boss silhouette")
	assert_true(stage.clip_contents, "the oversized boss must remain visually contained in its enemy-stage frame and never cover the shared timer")
	assert_lte(gatebreaker.anchor_left, 0.12, "the Gatebreaker must enter early enough to dominate the combat stage")
	assert_eq(gatebreaker.anchor_right, 1.0)
	assert_lte(gatebreaker.anchor_top, -0.1)
	assert_gte(gatebreaker.anchor_bottom, 1.1)
	assert_null(battle.get_node_or_null("MainRow/CombatColumn/CombatStage/VanguardReference"), "the enemy combat stage must not contain a player Vanguard cutout")

func test_action_phase_surfaces_the_single_enemy_eta_as_the_player_shared_action_timer() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var action_frame: Control = battle.get_node_or_null("MainRow/CombatColumn/SharedActionFrame") as Control
	assert_not_null(action_frame, "the boss-action and player-action window needs a dedicated central Action Phase surface")
	if action_frame == null:
		return
	for node_name in ["ActionPhaseTitle", "ActionPhaseSubtitle", "SharedTimerValue", "SharedTimerCaption", "CurrentActionFrame", "NextActionFrame"]:
		assert_not_null(action_frame.find_child(node_name, true, false), "%s is required for the shared-action reading order" % node_name)
	battle._runtime = TerminalRuntime.new({"terminal": false, "paused": false, "player_hp": 100, "player_energy": 12, "player_stock": 3, "enemy_hp": 100, "enemy_eta_seconds": 28.4})
	battle._refresh_runtime_labels()
	var timer_value: Label = action_frame.find_child("SharedTimerValue", true, false)
	var timer_caption: Label = action_frame.find_child("SharedTimerCaption", true, false)
	assert_eq(timer_value.text, "29", "the central player-action timer must read the same countdown as the enemy ETA")
	assert_eq(timer_caption.text, "SEC · BOSS / PLAYER", "the timer must communicate one shared action window rather than an unrelated decorative countdown")

func test_1280x720_combat_surface_minimum_height_keeps_every_required_panel_on_screen() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	battle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	battle.position = Vector2.ZERO
	battle.size = Vector2(1280.0, 720.0)
	add_child_autofree(battle)
	await get_tree().process_frame
	for node_path in [
		"MainRow/PuzzleColumn/ModeFrame",
		"MainRow/CombatColumn/ThreatFrame",
		"MainRow/CombatColumn/CombatStage",
		"MainRow/CombatColumn/SharedActionFrame",
		"MainRow/CombatColumn/ResourceFrame",
		"MainRow/CombatColumn/SkillFrame",
	]:
		var panel: Control = battle.get_node(node_path)
		assert_gte(panel.global_position.y, 0.0, "%s must start inside the declared viewport" % node_path)
		assert_lte(panel.global_position.y + panel.size.y, 720.0, "%s must remain inside the declared 1280x720 viewport" % node_path)

func test_resource_surface_exposes_a_large_vanguard_portrait_separate_from_the_boss_stage() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var portrait: TextureRect = battle.get_node_or_null("MainRow/CombatColumn/ResourceFrame/ResourceRow/VanguardPortrait")
	assert_not_null(portrait, "the player-facing resource strip needs a dedicated, readable Vanguard portrait")
	if portrait == null:
		return
	assert_not_null(portrait.texture)
	assert_gte(portrait.custom_minimum_size.x, 96.0, "the portrait must remain readable at battle scale")
	assert_gte(portrait.custom_minimum_size.y, 96.0, "the portrait must remain readable at battle scale")
	assert_eq(portrait.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_resource_surface_consumes_the_locked_vanguard_face_portrait_asset() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var portrait: TextureRect = battle.get_node("MainRow/CombatColumn/ResourceFrame/ResourceRow/VanguardPortrait")
	assert_not_null(portrait.texture, "the readable resource portrait needs its dedicated locked face asset")
	if portrait.texture != null:
		assert_eq(
			portrait.texture.resource_path,
			"res://assets/production/characters/vanguard_face_portrait_v1.png",
			"the compact portrait must no longer depend on a crop from the full-body stage cutout",
		)

func test_chain_workspace_resolves_each_symbol_to_its_locked_ornamental_tile_texture() -> void:
	var view := ProductionChainBoardView.new()
	add_child_autofree(view)
	var expected_texture_paths := {
		"R": "res://assets/production/tiles/chain_tile_red_v1.png",
		"G": "res://assets/production/tiles/chain_tile_green_v1.png",
		"B": "res://assets/production/tiles/chain_tile_blue_v1.png",
		"Y": "res://assets/production/tiles/chain_tile_yellow_v1.png",
		"P": "res://assets/production/tiles/chain_tile_purple_v1.png",
		"C": "res://assets/production/tiles/chain_tile_cyan_v1.png",
	}
	assert_true(view.has_method("get_tile_texture"), "Chain rendering must resolve gameplay symbols to locked ornamental textures")
	if not view.has_method("get_tile_texture"):
		return
	for symbol: String in expected_texture_paths:
		var texture = view.call("get_tile_texture", symbol) as Texture2D
		assert_not_null(texture, "%s must have a dedicated chain tile texture" % symbol)
		if texture != null:
			assert_eq(texture.resource_path, expected_texture_paths[symbol])

func test_battle_surface_declares_and_reads_only_named_workspace_skill_and_pause_actions() -> void:
	for action_name in [
		"workspace_line", "workspace_chain", "open_skill", "pause_game",
		"line_left", "line_right", "line_soft_drop", "line_rotate_cw", "line_rotate_ccw", "line_hold", "line_hard_drop",
	]:
		assert_true(InputMap.has_action(action_name), "%s must be a named project action" % action_name)
		assert_gt(InputMap.action_get_events(action_name).size(), 0, "%s needs a default testable binding" % action_name)
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	assert_true(battle.has_method("_unhandled_input"), "the battle bridge must receive named input actions")
	assert_true(battle.has_method("_handle_line_action"), "the battle bridge must route Line controls through the active session")
	assert_true(battle.has_method("_handle_chain_click"), "the battle bridge must route Chain pointer selection through the active session")
	assert_true(battle.has_method("_confirm_chain_mp_lock"), "the battle bridge must explicitly confirm the fixed MP lock")
	assert_true(battle.has_method("_discard_chain_mp_lock"), "the battle bridge must explicitly discard a failed Chain swap")
	assert_eq(battle.process_mode, Node.PROCESS_MODE_ALWAYS, "the input bridge must remain available while SceneTree is paused")

func test_line_actions_keep_letter_bindings_and_add_directional_aliases() -> void:
	assert_true(_has_physical_key("line_left", KEY_A))
	assert_true(_has_physical_key("line_left", KEY_LEFT))
	assert_true(_has_physical_key("line_right", KEY_D))
	assert_true(_has_physical_key("line_right", KEY_RIGHT))
	assert_true(_has_physical_key("line_soft_drop", KEY_S))
	assert_true(_has_physical_key("line_soft_drop", KEY_DOWN))
	assert_true(_has_physical_key("line_rotate_cw", KEY_X))
	assert_true(_has_physical_key("line_rotate_cw", KEY_UP))

func test_terminal_defeat_replaces_the_running_combat_label() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	battle._runtime = TerminalRuntime.new({"terminal": true, "paused": false, "player_hp": 0, "player_energy": 0, "player_stock": 0, "enemy_hp": 100, "enemy_eta_seconds": 0.0})
	battle._refresh_runtime_labels()
	assert_eq(battle.get_node("MainRow/CombatColumn/SkillFrame/SkillPanel/PauseState").text, "DEFEAT")

func test_terminal_victory_replaces_the_running_combat_label() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	battle._runtime = TerminalRuntime.new({"terminal": true, "paused": false, "player_hp": 100, "player_energy": 0, "player_stock": 0, "enemy_hp": 0, "enemy_eta_seconds": 0.0})
	battle._refresh_runtime_labels()
	assert_eq(battle.get_node("MainRow/CombatColumn/SkillFrame/SkillPanel/PauseState").text, "VICTORY")

func test_terminal_result_exposes_retry_only_after_combat_ends() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var retry_button = battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/RetryButton")
	assert_not_null(retry_button, "terminal result flow needs a visible retry control")
	if retry_button == null:
		return
	assert_false(retry_button.visible, "Retry must not compete with active combat controls")
	battle._runtime = TerminalRuntime.new({"terminal": true, "paused": false, "player_hp": 0, "player_energy": 0, "player_stock": 0, "enemy_hp": 100, "enemy_eta_seconds": 0.0})
	battle._refresh_runtime_labels()
	assert_true(retry_button.visible, "Retry must appear after a terminal outcome")
	assert_true(battle.has_method("_retry_encounter"), "Retry must restart through an explicit battle-owned bridge")
