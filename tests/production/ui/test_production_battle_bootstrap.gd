extends GutTest

const SCENE_PATH := "res://scenes/production/battle.tscn"

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
