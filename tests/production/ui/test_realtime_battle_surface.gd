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

class PausedRuntime:
	func snapshot() -> Dictionary:
		return {"player_energy": 7}

	func is_simulation_paused() -> bool:
		return true

class PendingChainSession:
	func has_pending_failed_swap() -> bool:
		return true

class PendingChainWorkspace:
	var chain_session := PendingChainSession.new()

class SkillPreviewRuntime:
	var selected_category := ""
	var _snapshot := {
		"terminal": false,
		"paused": true,
		"player_hp": 72,
		"player_energy": 31,
		"player_stock": 5,
		"enemy_hp": 100,
		"enemy_eta_seconds": 8.5,
		"last_time_feedback": {
			"target": "CURRENT ENEMY ETA",
			"changed": "Current enemy ETA +2.0 s",
			"unchanged": "LINE board timing unchanged",
		},
	}

	func is_skill_open() -> bool:
		return true

	func is_simulation_paused() -> bool:
		return true

	func select_skill_category(category: String) -> Dictionary:
		selected_category = category
		return {
			"selected": true,
			"ready": true,
			"category": category,
			"technique_id": "atk_c5_severing_drive",
			"display_name": "Severing Drive",
			"opening_combo": 5,
			"resolved_stage": 5,
			"converted_combo": 0,
			"mp_cost": 22,
			"preview_lines": ["Deal 28 direct damage."],
			"effects": [{"op": "DAMAGE_SINGLE", "magnitude": 28}],
		}

	func snapshot() -> Dictionary:
		return _snapshot

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
		"MainRow/PuzzleColumn/PuzzleHost/LineBoardView",
		"MainRow/PuzzleColumn/PuzzleHost/ChainBoardView",
		"MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel",
		"MainRow/CombatColumn/ThreatFrame/ThreatPanel",
		"MainRow/CombatColumn/CombatStage",
		"MainRow/CombatColumn/SharedActionFrame",
		"MainRow/CombatColumn/ResourceFrame/ResourceRow/ResourceBar",
		"MainRow/CombatColumn/ResourceFrame/ResourceRow/VanguardPortrait",
		"MainRow/CombatColumn/SkillFrame/SkillPanel",
	]:
		assert_not_null(battle.get_node_or_null(node_path), "%s is required by the 50/50 battle composition" % node_path)
	var puzzle_column: Control = battle.get_node_or_null("MainRow/PuzzleColumn")
	var combat_column: Control = battle.get_node_or_null("MainRow/CombatColumn")
	assert_almost_eq(puzzle_column.size_flags_stretch_ratio, 0.5, 0.01)
	assert_almost_eq(combat_column.size_flags_stretch_ratio, 0.5, 0.01)
	assert_eq(battle.find_children("*Turn*", "", true, false).size(), 0, "CORE-029 must not restore a turn rail")

func test_battle_surface_uses_named_theme_and_semantic_visual_frames() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	assert_not_null(battle.theme, "the production battle surface must use its named visual theme")
	for node_path in [
		"MainRow/PuzzleColumn/ModeFrame",
		"MainRow/CombatColumn/ThreatFrame",
		"MainRow/CombatColumn/SharedActionFrame",
		"MainRow/CombatColumn/ResourceFrame",
		"MainRow/CombatColumn/SkillFrame",
	]:
		assert_not_null(battle.get_node_or_null(node_path), "%s must provide a semantic visual hierarchy frame" % node_path)

func test_combat_stage_keeps_the_boss_large_and_moves_vanguard_to_the_resource_hud() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var stage = battle.get_node_or_null("MainRow/CombatColumn/CombatStage")
	var gatebreaker = battle.get_node_or_null("MainRow/CombatColumn/CombatStage/GatebreakerReference")
	var vanguard = battle.get_node_or_null("MainRow/CombatColumn/ResourceFrame/ResourceRow/VanguardPortrait")
	assert_not_null(stage)
	assert_not_null(gatebreaker)
	assert_not_null(vanguard)
	assert_null(battle.get_node_or_null("MainRow/CombatColumn/CombatStage/VanguardReference"), "Vanguard must not share the enemy presentation stage")
	if stage != null:
		assert_true(stage.clip_contents, "the enlarged boss crop must not spill over threat or skill controls")
	if gatebreaker != null:
		assert_eq(gatebreaker.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		assert_true(gatebreaker.texture is AtlasTexture, "the boss must use a deterministic stage crop")
	if vanguard != null:
		assert_true(vanguard.texture is AtlasTexture, "the HUD portrait must crop the existing Vanguard cutout")
		assert_gte(vanguard.custom_minimum_size.x, 110.0)

func test_shared_action_timer_is_a_presentation_alias_for_the_current_enemy_eta() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	battle._runtime = TerminalRuntime.new({"terminal": false, "paused": false, "player_hp": 72, "player_energy": 31, "player_stock": 4, "enemy_hp": 100, "enemy_eta_seconds": 8.5})
	battle._refresh_runtime_labels()
	var current = battle.get_node("MainRow/CombatColumn/ThreatFrame/ThreatPanel/CurrentTelegraph") as Label
	var shared_value = battle.get_node("MainRow/CombatColumn/SharedActionFrame/ActionPhaseStack/SharedTimerRow/SharedTimerCore/SharedTimerValue") as Label
	var current_frame = battle.get_node("MainRow/CombatColumn/SharedActionFrame/ActionPhaseStack/SharedTimerRow/CurrentActionFrame") as Label
	assert_string_contains(current.text, "8.5")
	assert_eq(shared_value.text, "8.5")
	assert_string_contains(current_frame.text, "8.5")
	var resources = battle.get_node("MainRow/CombatColumn/ResourceFrame/ResourceRow/ResourceBar") as Label
	assert_string_contains(resources.text, "MP 31 / 60")
	assert_string_contains(resources.text, "COMBO 4 / 10")

func test_chain_lock_prompt_exposes_visible_keep_or_revert_controls_without_overlaying_the_board() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var frame = battle.get_node_or_null("MainRow/PuzzleColumn/ChainLockFrame") as Control
	var prompt = battle.get_node_or_null("MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/Prompt") as Label
	var keep = battle.get_node_or_null("MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/LockActions/KeepSwapButton") as Button
	var discard = battle.get_node_or_null("MainRow/PuzzleColumn/ChainLockFrame/ChainLockPanel/LockActions/DiscardSwapButton") as Button
	assert_not_null(frame)
	assert_not_null(prompt)
	assert_not_null(keep)
	assert_not_null(discard)
	if frame != null:
		assert_false(frame.visible, "the no-match decision must not occupy board space until an invalid swap occurs")
		assert_eq(frame.process_mode, Node.PROCESS_MODE_ALWAYS, "the no-match decision must accept Keep/Revert clicks while normal combat is running")
	if prompt != null:
		assert_string_contains(prompt.text, "1 MP")
	if keep != null:
		assert_string_contains(keep.text, "KEEP")
	if discard != null:
		assert_string_contains(discard.text, "REVERT")

func test_chain_lock_prompt_hides_a_pending_swap_while_tactical_pause_owns_input() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	battle._runtime = PausedRuntime.new()
	battle._workspace_manager = PendingChainWorkspace.new()
	battle._refresh_chain_lock_prompt()
	var frame = battle.get_node_or_null("MainRow/PuzzleColumn/ChainLockFrame") as Control
	assert_not_null(frame)
	if frame != null:
		assert_false(frame.visible, "tactical pause must not expose a chain-board choice that runtime rejects")

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

func test_skill_panel_exposes_categories_one_preview_and_explicit_confirm_without_tier_grid() -> void:
	if not ResourceLoader.exists(BATTLE_SCENE_PATH):
		return
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	for node_path in ["Attack", "Defense", "Support"]:
		assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/SkillCategories/%s" % node_path))
	assert_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/TierGrid"))
	assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/SkillPreview"))
	assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/ConfirmButton"))
	assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/CancelButton"))
	assert_not_null(battle.get_node_or_null("MainRow/CombatColumn/SkillFrame/SkillPanel/TimingFeedback"))
	assert_true(battle.has_method("select_skill_category"))
	assert_false(battle.has_method("select_skill_tier"))

func test_battle_keeps_the_same_briefing_as_a_reopenable_rules_reference() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	assert_not_null(battle.get_node_or_null("MainRow/PuzzleColumn/ModeFrame/ModeBar/RulesButton"))
	assert_not_null(battle.get_node_or_null("RulesReferencePopup/BattleBriefing"))
	assert_true(battle.has_method("_open_rules_reference"))

func test_skill_preview_binds_the_resolved_combo_stage_before_confirm() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	var runtime := SkillPreviewRuntime.new()
	battle._runtime = runtime
	var preview: Dictionary = battle.select_skill_category("ATTACK")
	assert_true(bool(preview.get("ready", false)))
	assert_eq(runtime.selected_category, "ATTACK")
	var preview_label = battle.get_node("MainRow/CombatColumn/SkillFrame/SkillPanel/SkillPreview") as RichTextLabel
	var confirm_button = battle.get_node("MainRow/CombatColumn/SkillFrame/SkillPanel/ConfirmButton") as Button
	assert_string_contains(preview_label.text, "C5")
	assert_string_contains(preview_label.text, "22 MP")
	assert_false(confirm_button.disabled)

func test_timing_feedback_names_target_changed_value_and_unchanged_domain() -> void:
	var battle = load(BATTLE_SCENE_PATH).instantiate()
	add_child_autofree(battle)
	battle._runtime = SkillPreviewRuntime.new()
	battle._refresh_runtime_labels()
	var feedback = battle.get_node("MainRow/CombatColumn/SkillFrame/SkillPanel/TimingFeedback") as Label
	assert_string_contains(feedback.text, "CURRENT ENEMY ETA")
	assert_string_contains(feedback.text, "Current enemy ETA +2.0 s")
	assert_string_contains(feedback.text, "LINE board timing unchanged")

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
