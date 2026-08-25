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

func test_coordinator_routes_line_move_rotate_and_hold_without_owning_piece_rules() -> void:
    var f := await _standalone_scene()
    if f.is_empty():
        return

    var coordinator = f["coordinator"]
    var line = coordinator.line_session
    var original_piece_id: String = line.piece_cycle.active_piece.piece_id
    var original_origin: Vector2i = line.piece_cycle.active_piece.origin
    var original_rotation: int = line.piece_cycle.active_piece.rotation

    assert_true(coordinator.has_method("line_move"))
    assert_true(coordinator.has_method("line_rotate"))
    assert_true(coordinator.has_method("line_hold"))
    if not coordinator.has_method("line_move") or not coordinator.has_method("line_rotate") or not coordinator.has_method("line_hold"):
        return

    assert_true(coordinator.line_move(Vector2i.RIGHT))
    assert_eq(line.piece_cycle.active_piece.origin, original_origin + Vector2i.RIGHT)

    assert_true(coordinator.line_rotate(1))
    assert_ne(line.piece_cycle.active_piece.rotation, original_rotation)

    assert_true(coordinator.line_hold())
    assert_eq(line.piece_cycle.held_piece_id, original_piece_id)
    assert_eq(coordinator.battle_session.turn_controller.phase, TurnPhase.LINE)
