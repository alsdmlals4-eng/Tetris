extends GutTest

const SCENE_PATH := "res://scenes/production/battle.tscn"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const FEEL_DATA_PATH := "res://data/production/line_feel_config.json"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"

class StubDataBootstrap:
    extends ProductionBattleBootstrap

    var override_path: String = ""
    var override_data: Dictionary = {}

    func _init(p_override_path: String, p_override_data: Dictionary) -> void:
        override_path = p_override_path
        override_data = p_override_data.duplicate(true)

    func _json(path: String) -> Dictionary:
        if path == override_path:
            return override_data.duplicate(true)
        if not FileAccess.file_exists(path):
            return {}
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        return parsed if parsed is Dictionary else {}

func _scene_with_bootstrap(bootstrap: ProductionBattleBootstrap):
    var packed = load(SCENE_PATH)
    assert_not_null(packed)
    if packed == null:
        bootstrap.free()
        return null

    var ui = packed.instantiate()
    var default_bootstrap = ui.get_node_or_null("RuntimeBootstrap")
    if default_bootstrap != null:
        ui.remove_child(default_bootstrap)
        default_bootstrap.free()
    bootstrap.name = "RuntimeBootstrap"
    ui.add_child(bootstrap)
    add_child_autofree(ui)
    return ui

func test_scene_bootstraps_real_production_line_runtime_without_external_binding() -> void:
    var packed = load(SCENE_PATH)
    assert_not_null(packed)
    if packed == null:
        return

    var ui = packed.instantiate()
    add_child_autofree(ui)
    await get_tree().process_frame
    await get_tree().process_frame

    var bootstrap = ui.get_node_or_null("RuntimeBootstrap")
    var bridge = ui.get_node_or_null("RuntimeBridge")
    assert_not_null(bootstrap, "Production battle scene must own a runtime bootstrap")
    assert_not_null(bridge, "Production battle scene must own the runtime bridge")
    if bootstrap == null or bridge == null:
        return

    assert_eq(String(bootstrap.bootstrap_state), "READY")
    assert_not_null(bridge.coordinator, "Standalone scene must bind its coordinator automatically")
    if bridge.coordinator == null:
        return

    var coordinator = bridge.coordinator
    assert_not_null(coordinator.battle_session)
    assert_not_null(coordinator.line_session)
    assert_null(coordinator.chain_session, "Chain runtime stays deferred until a Production reward owner exists")
    assert_not_null(coordinator.battle_session.encounter_director)
    assert_eq(coordinator.battle_session.turn_controller.phase, TurnPhase.LINE)
    assert_true(coordinator.line_session.can_accept_input())

    assert_true(ui.phase_label.text.contains("LINE"))
    assert_true(ui.current_telegraph_label.text.contains("Light Smash"))
    assert_true(ui.next_forecast_label.text.contains("Gatebreaker Slam"))
    assert_true(ui.ready_button.visible)
    assert_false(ui.ready_button.disabled)

    ui.ready_button.pressed.emit()

    assert_eq(coordinator.battle_session.turn_controller.phase, TurnPhase.LINE_SETTLE)
    assert_true(ui.phase_label.text.contains("LINE_SETTLE"))

func test_standalone_bootstrap_refuses_malformed_time_data() -> void:
    var malformed_time := {
        "difficulty_profiles": {
            "NORMAL": {
                "base_budget_seconds": 90.0,
            },
        },
    }
    var bootstrap := StubDataBootstrap.new(TIME_DATA_PATH, malformed_time)
    var ui = _scene_with_bootstrap(bootstrap)
    if ui == null:
        return
    await get_tree().process_frame
    await get_tree().process_frame

    var bridge = ui.get_node_or_null("RuntimeBridge")
    assert_eq(String(bootstrap.bootstrap_state), "FAILED", "Malformed Shared Turn seed must fail closed")
    assert_ne(String(bootstrap.failure_reason), "")
    assert_not_null(bridge)
    if bridge != null:
        assert_null(bridge.coordinator, "Malformed Shared Turn seed must not bind a live coordinator")

func test_line_bootstrap_refuses_missing_feel_data() -> void:
    var bootstrap := StubDataBootstrap.new(FEEL_DATA_PATH, {})
    var turn := TurnController.new(TurnBudget.new())
    var line = bootstrap._make_line(turn)
    assert_null(line, "Missing feel seed must fail closed")
    bootstrap.free()

func test_line_bootstrap_refuses_missing_reward_data() -> void:
    var bootstrap := StubDataBootstrap.new(REWARD_DATA_PATH, {})
    var turn := TurnController.new(TurnBudget.new())
    var line = bootstrap._make_line(turn)
    assert_null(line, "Missing reward seed must fail closed")
    bootstrap.free()

func test_line_bootstrap_refuses_malformed_tetromino_data() -> void:
    var bootstrap := StubDataBootstrap.new(TETROMINO_DATA_PATH, {"schema_version": 1})
    var turn := TurnController.new(TurnBudget.new())
    var line = bootstrap._make_line(turn)
    assert_null(line, "Tetromino data without the seven Production pieces must fail closed")
    bootstrap.free()

func test_line_bootstrap_refuses_malformed_feel_data() -> void:
    var bootstrap := StubDataBootstrap.new(FEEL_DATA_PATH, {"balance_status": "TUNING_SEED_NOT_FINAL"})
    var turn := TurnController.new(TurnBudget.new())
    var line = bootstrap._make_line(turn)
    assert_null(line, "Feel data missing required fields must fail closed")
    bootstrap.free()

func test_line_bootstrap_refuses_malformed_reward_data() -> void:
    var bootstrap := StubDataBootstrap.new(REWARD_DATA_PATH, {"balance_status": "TUNING_SEED_NOT_FINAL"})
    var turn := TurnController.new(TurnBudget.new())
    var line = bootstrap._make_line(turn)
    assert_null(line, "Reward data missing required clear-kind maps must fail closed")
    bootstrap.free()
