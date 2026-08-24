extends GutTest

const RESPONSE_PATH := "res://src/production/combat/production_response_state.gd"
const EXECUTOR_PATH := "res://src/production/skill/production_effect_executor.gd"

func _make_response():
    assert_true(ResourceLoader.exists(RESPONSE_PATH), "ProductionResponseState script must exist")
    if not ResourceLoader.exists(RESPONSE_PATH):
        return null
    return load(RESPONSE_PATH).new()

func _make_executor():
    assert_true(ResourceLoader.exists(EXECUTOR_PATH), "ProductionEffectExecutor script must exist")
    if not ResourceLoader.exists(EXECUTOR_PATH):
        return null
    return load(EXECUTOR_PATH).new()

func test_direct_mitigation_is_bound_to_exact_current_telegraph_and_refreshes_by_max_not_sum() -> void:
    var response = _make_response()
    var executor = _make_executor()
    if response == null or executor == null:
        return

    var first: Dictionary = executor.execute(
        {"op": "MITIGATE_CURRENT_DIRECT", "magnitude": 10},
        {"response_state": response, "current_telegraph_action_id": "gatebreaker_slam_3"}
    )
    var second: Dictionary = executor.execute(
        {"op": "MITIGATE_CURRENT_DIRECT", "magnitude": 14},
        {"response_state": response, "current_telegraph_action_id": "gatebreaker_slam_3"}
    )

    assert_true(first["applied"])
    assert_true(second["applied"])
    assert_eq(response.modifiers_for_action("gatebreaker_slam_3")["direct_mitigation"], 14)
    assert_true(response.modifiers_for_action("another_action").is_empty())

func test_counter_ratio_binds_to_same_current_action_and_is_bounded() -> void:
    var response = _make_response()
    var executor = _make_executor()
    if response == null or executor == null:
        return

    var result: Dictionary = executor.execute(
        {"op": "COUNTER_FROM_PREVENTED_DAMAGE", "ratio": 0.5},
        {"response_state": response, "current_telegraph_action_id": "gatebreaker_slam_4"}
    )

    assert_true(result["applied"])
    assert_eq(response.modifiers_for_action("gatebreaker_slam_4")["counter_ratio"], 0.5)

    var rejected: Dictionary = executor.execute(
        {"op": "COUNTER_FROM_PREVENTED_DAMAGE", "ratio": 1.5},
        {"response_state": response, "current_telegraph_action_id": "gatebreaker_slam_4"}
    )
    assert_false(rejected["applied"])
    assert_eq(rejected["reason"], "INVALID_COUNTER_RATIO")
    assert_eq(response.modifiers_for_action("gatebreaker_slam_4")["counter_ratio"], 0.5)

func test_resource_ward_binds_only_to_current_telegraphed_resource_action() -> void:
    var response = _make_response()
    var executor = _make_executor()
    if response == null or executor == null:
        return

    var result: Dictionary = executor.execute(
        {"op": "PROTECT_RESOURCE_LOSS", "ratio": 0.6, "bind_to": "CURRENT_TELEGRAPH_ACTION_ID"},
        {"response_state": response, "current_telegraph_action_id": "rift_siphon_2"}
    )

    assert_true(result["applied"])
    assert_eq(response.modifiers_for_action("rift_siphon_2")["resource_ward_ratio"], 0.6)
    assert_true(response.modifiers_for_action("chain_fracture_9").is_empty())

func test_lethal_safety_records_hp_floor_and_single_charge_for_current_direct_action() -> void:
    var response = _make_response()
    var executor = _make_executor()
    if response == null or executor == null:
        return

    var result: Dictionary = executor.execute(
        {"op": "LETHAL_SAFETY", "hp_floor": 1, "charges": 1},
        {"response_state": response, "current_telegraph_action_id": "siege_charge_1"}
    )

    assert_true(result["applied"])
    var modifiers: Dictionary = response.modifiers_for_action("siege_charge_1")
    assert_eq(modifiers["lethal_hp_floor"], 1)
    assert_eq(modifiers["lethal_charges"], 1)

func test_current_response_primitives_fail_closed_without_current_telegraph_or_response_state() -> void:
    var response = _make_response()
    var executor = _make_executor()
    if response == null or executor == null:
        return

    var missing_id: Dictionary = executor.execute(
        {"op": "MITIGATE_CURRENT_DIRECT", "magnitude": 10},
        {"response_state": response}
    )
    var missing_state: Dictionary = executor.execute(
        {"op": "PROTECT_RESOURCE_LOSS", "ratio": 0.6, "bind_to": "CURRENT_TELEGRAPH_ACTION_ID"},
        {"current_telegraph_action_id": "rift_siphon_1"}
    )

    assert_false(missing_id["applied"])
    assert_eq(missing_id["reason"], "MISSING_CURRENT_TELEGRAPH")
    assert_false(missing_state["applied"])
    assert_eq(missing_state["reason"], "MISSING_RESPONSE_STATE")
