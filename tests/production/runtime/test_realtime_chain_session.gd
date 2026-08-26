extends GutTest

const BOARD_PATH := "res://src/production/chain/chain_board.gd"
const RANDOMIZER_PATH := "res://src/production/chain/chain_randomizer.gd"
const RESOLVER_PATH := "res://src/production/chain/chain_resolver.gd"
const SESSION_PATH := "res://src/production/chain/production_chain_session.gd"
const CONFIG_PATH := "res://src/production/chain/production_chain_config.gd"
const CONFIG_DATA_PATH := "res://data/production/chain_runtime_seed.json"

const SCRIPT_PATHS := [
    BOARD_PATH,
    RANDOMIZER_PATH,
    RESOLVER_PATH,
    SESSION_PATH,
    CONFIG_PATH,
]

func _requirements_exist() -> bool:
    var ready := true
    for path in SCRIPT_PATHS:
        var exists := ResourceLoader.exists(path)
        assert_true(exists, "%s must exist for the realtime Chain workspace" % path)
        ready = ready and exists
    var data_exists := FileAccess.file_exists(CONFIG_DATA_PATH)
    assert_true(data_exists, "%s must exist for the realtime Chain workspace" % CONFIG_DATA_PATH)
    return ready and data_exists

func _has_property(instance: Object, property_name: String) -> bool:
    for property in instance.get_property_list():
        if String(property.get("name", "")) == property_name:
            return true
    return false

func _config():
    if not _requirements_exist():
        return null
    var raw := FileAccess.get_file_as_string(CONFIG_DATA_PATH)
    var parsed = JSON.parse_string(raw)
    if not parsed is Dictionary:
        return null
    return load(CONFIG_PATH).from_dictionary(parsed)

func _make_session():
    var config = _config()
    if config == null:
        return null

    var board = load(BOARD_PATH).new(3, 3)
    assert_true(board.restore([
        "A", "B", "A",
        "B", "A", "C",
        "C", "A", "B",
    ]))
    var randomizer = load(RANDOMIZER_PATH).new(20260826, config.palette)
    var resolver = load(RESOLVER_PATH).new(board, randomizer)
    return load(SESSION_PATH).new(board, resolver, config)

func test_realtime_chain_session_has_no_turn_or_combat_resource_ownership() -> void:
    var session = _make_session()
    if session == null:
        return

    assert_true(session.input_enabled)
    assert_true(session.can_accept_input())
    assert_false(_has_property(session, "turn_controller"))
    assert_false(_has_property(session, "combat_state"))
    assert_true(session.has_method("set_input_enabled"))
    assert_true(session.has_method("is_resolving"))
    assert_true(session.has_method("snapshot_runtime_state"))

func test_stable_inactive_chain_rejects_new_swaps_without_mutating_board_or_rng() -> void:
    var session = _make_session()
    if session == null:
        return

    var before: Dictionary = session.snapshot_runtime_state()
    session.set_input_enabled(false)
    assert_false(session.can_accept_input())

    var rejected: Dictionary = session.begin_swap(Vector2i(1, 0), Vector2i(1, 1))
    assert_false(bool(rejected.get("accepted", false)))
    assert_eq(String(rejected.get("reason", "")), "INPUT_CLOSED")
    assert_eq(session.drain_events().size(), 0)

    var during: Dictionary = session.snapshot_runtime_state()
    assert_eq(during["board"], before["board"])
    assert_eq(during["rng_state"], before["rng_state"])
    assert_false(bool(during["resolving"]))

    session.set_input_enabled(true)
    var after: Dictionary = session.snapshot_runtime_state()
    assert_eq(after["board"], before["board"])
    assert_eq(after["rng_state"], before["rng_state"])
    assert_true(session.can_accept_input())

func test_committed_swap_settles_once_after_input_closes_and_emits_resource_request_only() -> void:
    var session = _make_session()
    if session == null:
        return

    var swap: Dictionary = session.begin_swap(Vector2i(1, 0), Vector2i(1, 1))
    assert_true(bool(swap.get("accepted", false)))
    assert_true(session.is_resolving())

    session.set_input_enabled(false)
    assert_false(session.can_accept_input())

    var resolution: Dictionary = session.complete_pending_resolution()
    assert_true(bool(resolution.get("success", false)))
    assert_gt(int(resolution.get("chain_depth", 0)), 0)
    assert_false(session.is_resolving())
    assert_true(session.board.find_match_groups().is_empty(), "committed Chain work must reach a stable board")

    var events: Array = session.drain_events()
    assert_eq(events.size(), 1)
    if events.size() == 1:
        var event: Dictionary = events[0]
        assert_eq(String(event.get("kind", "")), "production_chain_resolved")
        assert_eq(int(event.get("chain_depth", 0)), int(resolution.get("chain_depth", 0)))
        assert_eq(int(event.get("stock_requested", -1)), session.reward_policy.stock_for_resolution(resolution))
        assert_false(event.has("stock_applied"), "Chain workspace must not mutate combat Stock directly")
        assert_false(event.has("stock_lost_at_cap"))

    var duplicate: Dictionary = session.complete_pending_resolution()
    assert_false(bool(duplicate.get("success", false)))
    assert_eq(String(duplicate.get("reason", "")), "NO_PENDING_RESOLUTION")
    assert_eq(session.drain_events().size(), 0, "completed resolution must not duplicate rewards")

    var frozen_after_settle: Dictionary = session.snapshot_runtime_state()
    session.set_input_enabled(true)
    var resumed: Dictionary = session.snapshot_runtime_state()
    assert_eq(resumed["board"], frozen_after_settle["board"])
    assert_eq(resumed["rng_state"], frozen_after_settle["rng_state"])
    assert_true(session.can_accept_input())
