extends GutTest

const SCENE_PATH := "res://scenes/production/battle.tscn"

func _standalone_scene() -> Dictionary:
    var packed = load(SCENE_PATH)
    assert_not_null(packed)
    if packed == null:
        return {}

    var ui = packed.instantiate()
    add_child_autofree(ui)
    await get_tree().process_frame
    await get_tree().process_frame

    var bootstrap = ui.get_node_or_null("RuntimeBootstrap")
    var bridge = ui.get_node_or_null("RuntimeBridge")
    assert_not_null(bootstrap)
    assert_not_null(bridge)
    if bootstrap == null or bridge == null:
        return {}
    assert_eq(String(bootstrap.bootstrap_state), "READY")
    assert_not_null(bridge.coordinator)
    if String(bootstrap.bootstrap_state) != "READY" or bridge.coordinator == null:
        return {}

    return {
        "ui": ui,
        "bridge": bridge,
        "coordinator": bridge.coordinator,
    }

func test_live_line_tick_consumes_shared_budget_and_refreshes_timer() -> void:
    var f := await _standalone_scene()
    if f.is_empty():
        return

    var ui = f["ui"]
    var bridge = f["bridge"]
    var coordinator = f["coordinator"]
    var budget = coordinator.battle_session.turn_controller.turn_budget
    var before_seconds: float = budget.remaining_seconds
    var before_label: String = ui.shared_timer_label.text

    assert_true(bridge.has_method("_process"), "Runtime bridge must own live Production ticking")
    if not bridge.has_method("_process"):
        return

    bridge._process(0.25)

    assert_lt(budget.remaining_seconds, before_seconds)
    assert_ne(ui.shared_timer_label.text, before_label)
