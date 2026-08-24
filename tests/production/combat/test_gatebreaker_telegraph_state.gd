extends GutTest

const STATE_PATH := "res://src/production/combat/gatebreaker_telegraph_state.gd"
const CATALOG_PATH := "res://src/production/combat/gatebreaker_action_catalog.gd"
const DATA_PATH := "res://data/production/gatebreaker_action_seed.json"

func _catalog():
    return load(CATALOG_PATH).from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

func _make_state(current: Dictionary, next: Dictionary):
    assert_true(ResourceLoader.exists(STATE_PATH), "GatebreakerTelegraphState script must exist")
    if not ResourceLoader.exists(STATE_PATH):
        return null
    return load(STATE_PATH).new(current, next)

func test_state_exposes_exact_current_and_next_authored_action_ids() -> void:
    var catalog = _catalog()
    var current: Dictionary = catalog.instantiate_action("light_smash", 1)
    var next: Dictionary = catalog.instantiate_action("gatebreaker_slam", 2)
    var state = _make_state(current, next)
    if state == null:
        return

    assert_eq(state.current_action()["id"], current["id"])
    assert_eq(state.next_action()["id"], next["id"])
    assert_eq(state.current_action()["template_key"], "light_smash")
    assert_eq(state.next_action()["template_key"], "gatebreaker_slam")

func test_returned_telegraphs_are_copies_and_cannot_mutate_locked_internal_actions() -> void:
    var catalog = _catalog()
    var current: Dictionary = catalog.instantiate_action("light_smash", 1)
    var next: Dictionary = catalog.instantiate_action("gatebreaker_slam", 2)
    var state = _make_state(current, next)
    if state == null:
        return

    var leaked_current: Dictionary = state.current_action()
    var leaked_next: Dictionary = state.next_action()
    leaked_current["id"] = "player_reactive_rewrite"
    leaked_current["hp_ratio"] = 1.0
    leaked_next["tags"] = ["HIDDEN_COUNTER"]

    assert_eq(state.current_action()["id"], current["id"])
    assert_eq(state.current_action()["hp_ratio"], 0.12)
    assert_true(state.next_action()["tags"].has("DIRECT_HIT"))
    assert_false(state.next_action()["tags"].has("HIDDEN_COUNTER"))

func test_mismatched_resolved_action_id_refuses_to_advance_or_replace_current() -> void:
    var catalog = _catalog()
    var current: Dictionary = catalog.instantiate_action("light_smash", 1)
    var next: Dictionary = catalog.instantiate_action("gatebreaker_slam", 2)
    var authored_after_next: Dictionary = catalog.instantiate_action("rift_siphon", 3)
    var state = _make_state(current, next)
    if state == null:
        return

    var result: Dictionary = state.advance_after_resolve("some_other_action", authored_after_next)

    assert_false(result["advanced"])
    assert_eq(result["reason"], "RESOLVED_ACTION_ID_MISMATCH")
    assert_eq(state.current_action()["id"], current["id"])
    assert_eq(state.next_action()["id"], next["id"])

func test_exact_resolve_advances_prior_next_to_current_and_accepts_only_new_authored_next() -> void:
    var catalog = _catalog()
    var current: Dictionary = catalog.instantiate_action("light_smash", 1)
    var next: Dictionary = catalog.instantiate_action("gatebreaker_slam", 2)
    var authored_after_next: Dictionary = catalog.instantiate_action("rift_siphon", 3)
    var state = _make_state(current, next)
    if state == null:
        return

    var result: Dictionary = state.advance_after_resolve(current["id"], authored_after_next)

    assert_true(result["advanced"])
    assert_eq(result["resolved_action_id"], current["id"])
    assert_eq(state.current_action()["id"], next["id"])
    assert_eq(state.next_action()["id"], authored_after_next["id"])

func test_invalid_or_unidentified_new_next_fails_closed_without_advancing() -> void:
    var catalog = _catalog()
    var current: Dictionary = catalog.instantiate_action("light_smash", 1)
    var next: Dictionary = catalog.instantiate_action("gatebreaker_slam", 2)
    var state = _make_state(current, next)
    if state == null:
        return

    var result: Dictionary = state.advance_after_resolve(current["id"], {"kind": "DIRECT_HP_RATIO", "hp_ratio": 0.99})

    assert_false(result["advanced"])
    assert_eq(result["reason"], "INVALID_NEXT_AUTHORED_ACTION")
    assert_eq(state.current_action()["id"], current["id"])
    assert_eq(state.next_action()["id"], next["id"])

func test_forecast_context_is_exact_and_contains_only_current_next_scope_inputs() -> void:
    var catalog = _catalog()
    var current: Dictionary = catalog.instantiate_action("rift_siphon", 4)
    var next: Dictionary = catalog.instantiate_action("gatebreaker_slam", 5)
    var state = _make_state(current, next)
    if state == null:
        return

    var context: Dictionary = state.forecast_context()

    assert_eq(context["current_telegraph_action_id"], current["id"])
    assert_eq(context["next_forecast_action_id"], next["id"])
    assert_true(context["current_telegraph_tags"].has("RIFT_UTILITY"))
    assert_true(context["next_forecast_tags"].has("DIRECT_HIT"))
    assert_false(context.has("hidden_future_action_id"))

func test_advance_readiness_validates_exact_current_and_new_next_without_mutating_lock() -> void:
    var catalog = _catalog()
    var current: Dictionary = catalog.instantiate_action("light_smash", 11)
    var next: Dictionary = catalog.instantiate_action("gatebreaker_slam", 12)
    var authored_after_next: Dictionary = catalog.instantiate_action("rift_siphon", 13)
    var state = _make_state(current, next)
    if state == null:
        return

    var ready: Dictionary = state.advance_readiness(current["id"], authored_after_next)
    var invalid: Dictionary = state.advance_readiness(current["id"], {"kind": "DIRECT_HP_RATIO", "hp_ratio": 0.5})

    assert_true(ready["ready"])
    assert_eq(ready["reason"], "READY")
    assert_false(invalid["ready"])
    assert_eq(invalid["reason"], "INVALID_NEXT_AUTHORED_ACTION")
    assert_eq(state.current_action()["id"], current["id"])
    assert_eq(state.next_action()["id"], next["id"])
