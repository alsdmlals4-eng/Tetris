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

func _key(code: int, pressed: bool = true) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = pressed
    event.echo = false
    return event

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

func test_line_board_view_exposes_visible_active_ghost_hold_and_next_without_mutation() -> void:
    var f := await _standalone_scene()
    if f.is_empty():
        return

    var ui = f["ui"]
    var bridge = f["bridge"]
    var coordinator = f["coordinator"]
    var line = coordinator.line_session
    var view = ui.get_node_or_null("Layout/MainRow/PuzzlePanel/LineBoardHost/LineBoardView")
    assert_not_null(view, "Production scene must mount a real read-only Line board view")
    if view == null:
        return

    assert_true(view.has_method("snapshot"))
    if not view.has_method("snapshot"):
        return

    var before_origin: Vector2i = line.piece_cycle.active_piece.origin
    var before: Dictionary = view.snapshot()
    assert_eq(int(before.get("width", 0)), 10)
    assert_eq(int(before.get("height", 0)), 20)
    assert_eq((before.get("cells", []) as Array).size(), 20)
    assert_ne(String(before.get("active_piece_id", "")), "")
    assert_true(before.has("ghost_origin"))
    assert_true(before.has("held_piece_id"))
    assert_eq((before.get("next_piece_ids", []) as Array).size(), 5)
    assert_eq(line.piece_cycle.active_piece.origin, before_origin, "Read-only snapshot must not mutate gameplay state")

    assert_true(coordinator.line_move(Vector2i.RIGHT))
    assert_true(bridge.has_method("_refresh_presentation"))
    bridge._refresh_presentation()
    var after: Dictionary = view.snapshot()
    assert_ne(after.get("active_origin"), before.get("active_origin"))
    assert_eq(line.piece_cycle.active_piece.origin, before_origin + Vector2i.RIGHT)

func test_engineering_keyboard_routes_move_rotate_hold_soft_drop_and_hard_drop() -> void:
    var f := await _standalone_scene()
    if f.is_empty():
        return

    var bridge = f["bridge"]
    var coordinator = f["coordinator"]
    var line = coordinator.line_session

    assert_true(bridge.has_method("_unhandled_key_input"), "Bridge must own the temporary engineering key map")
    if not bridge.has_method("_unhandled_key_input"):
        return

    var original_origin: Vector2i = line.piece_cycle.active_piece.origin
    var original_rotation: int = line.piece_cycle.active_piece.rotation
    var original_piece_id: String = line.piece_cycle.active_piece.piece_id

    bridge._unhandled_key_input(_key(KEY_RIGHT))
    assert_eq(line.piece_cycle.active_piece.origin, original_origin + Vector2i.RIGHT)

    bridge._unhandled_key_input(_key(KEY_X))
    assert_ne(line.piece_cycle.active_piece.rotation, original_rotation)
    bridge._unhandled_key_input(_key(KEY_Z))
    assert_eq(line.piece_cycle.active_piece.rotation, original_rotation)

    bridge._unhandled_key_input(_key(KEY_C))
    assert_eq(line.piece_cycle.held_piece_id, original_piece_id)

    var soft_drop_origin: Vector2i = line.piece_cycle.active_piece.origin
    bridge._unhandled_key_input(_key(KEY_DOWN, true))
    bridge._process(0.06)
    assert_gt(line.piece_cycle.active_piece.origin.y, soft_drop_origin.y, "Held Down must use the existing data-driven soft-drop interval")
    bridge._unhandled_key_input(_key(KEY_DOWN, false))

    var active_before_drop = line.piece_cycle.active_piece
    bridge._unhandled_key_input(_key(KEY_SPACE))
    assert_ne(line.piece_cycle.active_piece, active_before_drop)
    var routed: Array = coordinator.drain_routed_events()
    assert_eq(routed.size(), 1)
    assert_eq(routed[0].get("kind", &""), &"production_line_resolved")
