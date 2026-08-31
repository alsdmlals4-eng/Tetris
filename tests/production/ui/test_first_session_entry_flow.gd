## 온보딩 진입점이 전투를 건너뛰거나 규칙 확인 없이 Deploy하지 않도록 보호한다.
extends GutTest

const TITLE_SCENE_PATH := "res://scenes/production/title.tscn"
const BRIEFING_SCENE_PATH := "res://scenes/production/battle_briefing.tscn"
const BATTLE_SCENE_PATH := "res://scenes/production/battle.tscn"
const FLOW_SCRIPT_PATH := "res://src/production/session/production_first_session_flow.gd"
const TITLE_LOGO_PATH := "res://assets/production/branding/fracture_frontier_title_logo_v1.png"

func test_project_starts_at_the_production_title_surface() -> void:
	var project_config := ConfigFile.new()
	assert_eq(project_config.load("res://project.godot"), OK)
	assert_eq(project_config.get_value("application", "run/main_scene", ""), TITLE_SCENE_PATH)
	assert_true(ResourceLoader.exists(TITLE_SCENE_PATH), "new sessions must have a real title scene, not enter combat directly")

func test_first_session_requires_rule_acknowledgement_before_deploy() -> void:
	assert_true(ResourceLoader.exists(FLOW_SCRIPT_PATH), "the first-session state must be owned by a reusable runtime flow")
	if not ResourceLoader.exists(FLOW_SCRIPT_PATH):
		return
	var flow = load(FLOW_SCRIPT_PATH).new()
	assert_eq(flow.start_briefing(), BRIEFING_SCENE_PATH)
	assert_false(flow.can_deploy(), "a first visit must disclose the complete critical rules before Deploy")
	assert_false(bool(flow.deploy().get("accepted", false)))
	flow.acknowledge_rules()
	assert_true(flow.can_deploy())
	var result: Dictionary = flow.deploy()
	assert_true(bool(result.get("accepted", false)))
	assert_eq(String(result.get("scene_path", "")), BATTLE_SCENE_PATH)

func test_briefing_scene_exposes_rules_acknowledgement_and_explicit_deploy() -> void:
	assert_true(ResourceLoader.exists(BRIEFING_SCENE_PATH), "the title must lead to a real briefing surface")
	if not ResourceLoader.exists(BRIEFING_SCENE_PATH):
		return
	var briefing = load(BRIEFING_SCENE_PATH).instantiate()
	add_child_autofree(briefing)
	var acknowledge_button: Button = briefing.get_node_or_null("Margin/Panel/Content/AcknowledgeRules")
	var deploy_button: Button = briefing.get_node_or_null("Margin/Panel/Content/Deploy")
	assert_not_null(acknowledge_button)
	assert_not_null(deploy_button)
	if deploy_button != null:
		assert_true(deploy_button.disabled, "Deploy must remain gated until the player acknowledges the rule summary")

func test_title_binds_the_user_locked_logo_without_a_duplicate_text_title() -> void:
	assert_true(ResourceLoader.exists(TITLE_LOGO_PATH), "the user-locked title logo must be registered at its canonical runtime path")
	assert_true(ResourceLoader.exists(TITLE_SCENE_PATH))
	if not ResourceLoader.exists(TITLE_SCENE_PATH):
		return
	var title = load(TITLE_SCENE_PATH).instantiate()
	add_child_autofree(title)
	var logo_slot: TextureRect = title.get_node_or_null("Margin/Panel/Content/TitleLogo")
	var title_text: Label = title.get_node_or_null("Margin/Panel/Content/TitleText")
	assert_not_null(logo_slot, "the title needs the registered logo consumer")
	assert_not_null(title_text)
	if logo_slot != null:
		assert_eq(logo_slot.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_true(logo_slot.visible, "the locked logo must be visible on the production title surface")
		assert_not_null(logo_slot.texture)
		if logo_slot.texture != null:
			assert_eq(logo_slot.texture.resource_path, TITLE_LOGO_PATH)
		assert_eq(logo_slot.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	if title_text != null:
		assert_false(title_text.visible, "the raster title logo replaces the duplicate text rendering while preserving the text contract below")

func test_title_names_the_world_not_the_player_job() -> void:
	assert_true(ResourceLoader.exists(TITLE_SCENE_PATH))
	if not ResourceLoader.exists(TITLE_SCENE_PATH):
		return
	var title = load(TITLE_SCENE_PATH).instantiate()
	add_child_autofree(title)
	var title_text: Label = title.get_node_or_null("Margin/Panel/Content/TitleText")
	assert_not_null(title_text)
	if title_text != null:
		assert_eq(title_text.text, "FRACTURE FRONTIER", "the public title must name the Frontier Gate world, not the Vanguard player job")
