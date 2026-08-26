extends GutTest

const STATUS_PATH := "res://src/production/skill/production_status_state.gd"

func _make_state():
    assert_true(ResourceLoader.exists(STATUS_PATH), "ProductionStatusState script must exist")
    if not ResourceLoader.exists(STATUS_PATH):
        return null
    return load(STATUS_PATH).new()

func test_status_vocabulary_is_bounded_to_current_tactical_contract() -> void:
    var state = _make_state()
    if state == null:
        return

    assert_eq(state.allowed_statuses(), [
        "BREACH",
        "FORTIFY",
        "RALLY",
        "WEAKEN",
        "RIFT_WARD",
        "RIFT_SEAL",
        "BATTLE_TRANCE",
    ])
    assert_false(state.apply_status("POISON", "enemy"))
    assert_false(state.has_status("POISON", "enemy"))

func test_plain_status_refreshes_without_unbounded_stack_growth() -> void:
    var state = _make_state()
    if state == null:
        return

    assert_true(state.apply_status("BREACH", "enemy", 1))
    assert_true(state.apply_status("BREACH", "enemy", 1))
    assert_true(state.has_status("BREACH", "enemy"))
    assert_eq(state.status_stacks("BREACH", "enemy"), 1, "first-slice bounded statuses refresh instead of stacking without an explicit stacking contract")

func test_future_forecast_status_binds_to_exact_visible_action_id_and_never_migrates() -> void:
    var state = _make_state()
    if state == null:
        return

    assert_false(state.apply_bound_status("WEAKEN", "enemy", "", "VISIBLE_NEXT_FORECAST_ACTION_ID"), "hidden/unknown actions cannot be targeted")
    assert_true(state.apply_bound_status("WEAKEN", "enemy", "enemy_action_42", "VISIBLE_NEXT_FORECAST_ACTION_ID"))
    assert_false(state.matches_bound_action("WEAKEN", "enemy", "enemy_action_41"))
    assert_true(state.matches_bound_action("WEAKEN", "enemy", "enemy_action_42"))

    assert_false(state.consume_for_action("WEAKEN", "enemy", "enemy_action_41"), "unrelated action must not consume or migrate binding")
    assert_true(state.matches_bound_action("WEAKEN", "enemy", "enemy_action_42"))
    assert_true(state.consume_for_action("WEAKEN", "enemy", "enemy_action_42"))
    assert_false(state.has_status("WEAKEN", "enemy"))

func test_current_telegraph_resource_ward_binds_to_exact_current_action_id() -> void:
    var state = _make_state()
    if state == null:
        return

    assert_true(state.apply_bound_status("RIFT_WARD", "player", "telegraph_7", "CURRENT_TELEGRAPH_ACTION_ID"))
    assert_true(state.matches_bound_action("RIFT_WARD", "player", "telegraph_7"))
    assert_false(state.matches_bound_action("RIFT_WARD", "player", "telegraph_8"))
