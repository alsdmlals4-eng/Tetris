extends GutTest

const MANAGER_PATH := "res://src/production/runtime/puzzle_workspace_manager.gd"
const LINE := "LINE"
const CHAIN := "CHAIN"

const LINE_SESSION_PATH := "res://src/production/line/production_line_session.gd"
const LINE_BOARD_PATH := "res://src/production/line/line_board.gd"
const LINE_CYCLE_PATH := "res://src/production/line/line_piece_cycle.gd"
const LINE_CATALOG_PATH := "res://src/production/line/tetromino_catalog.gd"
const LINE_FALL_PATH := "res://src/production/line/line_fall_state.gd"
const LINE_FEEL_CONFIG_PATH := "res://src/production/line/line_feel_config.gd"
const LINE_REWARD_CONFIG_PATH := "res://src/production/line/line_reward_config.gd"
const LINE_TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const LINE_FEEL_DATA_PATH := "res://data/production/line_feel_config.json"
const LINE_REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"

const CHAIN_BOARD_PATH := "res://src/production/chain/chain_board.gd"
const CHAIN_RANDOMIZER_PATH := "res://src/production/chain/chain_randomizer.gd"
const CHAIN_RESOLVER_PATH := "res://src/production/chain/chain_resolver.gd"
const CHAIN_SESSION_PATH := "res://src/production/chain/production_chain_session.gd"
const CHAIN_CONFIG_PATH := "res://src/production/chain/production_chain_config.gd"
const CHAIN_CONFIG_DATA_PATH := "res://data/production/chain_runtime_seed.json"

const REQUIRED_PATHS := [
    LINE_SESSION_PATH,
    LINE_BOARD_PATH,
    LINE_CYCLE_PATH,
    LINE_CATALOG_PATH,
    LINE_FALL_PATH,
    LINE_FEEL_CONFIG_PATH,
    LINE_REWARD_CONFIG_PATH,
    CHAIN_BOARD_PATH,
    CHAIN_RANDOMIZER_PATH,
    CHAIN_RESOLVER_PATH,
    CHAIN_SESSION_PATH,
    CHAIN_CONFIG_PATH,
]

func _requirements_exist() -> bool:
    var ready := true
    for path in REQUIRED_PATHS:
        var exists := ResourceLoader.exists(path)
        assert_true(exists, "%s must exist for the workspace-switch contract" % path)
        ready = ready and exists
    for data_path in [
        LINE_TETROMINO_DATA_PATH,
        LINE_FEEL_DATA_PATH,
        LINE_REWARD_DATA_PATH,
        CHAIN_CONFIG_DATA_PATH,
    ]:
        var data_exists := FileAccess.file_exists(data_path)
        assert_true(data_exists, "%s must exist for the workspace-switch contract" % data_path)
        ready = ready and data_exists
    return ready

func _read_json(path: String):
    return JSON.parse_string(FileAccess.get_file_as_string(path))

func _make_line_session():
    var catalog = load(LINE_CATALOG_PATH).from_dictionary(_read_json(LINE_TETROMINO_DATA_PATH))
    var feel_config = load(LINE_FEEL_CONFIG_PATH).from_dictionary(_read_json(LINE_FEEL_DATA_PATH))
    var reward_config = load(LINE_REWARD_CONFIG_PATH).from_dictionary(_read_json(LINE_REWARD_DATA_PATH))
    var board = load(LINE_BOARD_PATH).new(10, 20, 4)
    var cycle = load(LINE_CYCLE_PATH).new(20260824, catalog, board)
    cycle.start()
    var fall_state = load(LINE_FALL_PATH).new(feel_config)
    return load(LINE_SESSION_PATH).new(cycle, fall_state, reward_config)

func _make_chain_session():
    var config = load(CHAIN_CONFIG_PATH).from_dictionary(_read_json(CHAIN_CONFIG_DATA_PATH))
    var board = load(CHAIN_BOARD_PATH).new(3, 3)
    assert_true(board.restore([
        "A", "B", "A",
        "B", "A", "C",
        "C", "A", "B",
    ]), "fixture must start with the committed Chain swap used by the contract")
    var randomizer = load(CHAIN_RANDOMIZER_PATH).new(20260826, config.palette)
    var resolver = load(CHAIN_RESOLVER_PATH).new(board, randomizer)
    return load(CHAIN_SESSION_PATH).new(board, resolver, config)

func _make_manager(line_session, chain_session):
    var manager_exists := ResourceLoader.exists(MANAGER_PATH)
    assert_true(manager_exists, "%s must define persistent workspace switching" % MANAGER_PATH)
    if not manager_exists:
        return null
    return load(MANAGER_PATH).new(line_session, chain_session)

func _make_workspace_fixture() -> Dictionary:
    if not _requirements_exist():
        return {}
    var line_session = _make_line_session()
    var chain_session = _make_chain_session()
    var manager = _make_manager(line_session, chain_session)
    if manager == null:
        return {}
    return {
        "manager": manager,
        "line": line_session,
        "chain": chain_session,
    }

func _switch_and_handoff(manager, target: String) -> Dictionary:
    var requested: Dictionary = manager.request_switch(target)
    assert_true(bool(requested.get("accepted", false)), "valid workspace request must be accepted")
    return manager.process_safe_handoff()

func test_manager_exposes_workspace_api_and_starts_with_line_input_only() -> void:
    var fixture := _make_workspace_fixture()
    if fixture.is_empty():
        return
    var manager = fixture["manager"]
    var line_session = fixture["line"]
    var chain_session = fixture["chain"]

    var manager_script = load(MANAGER_PATH)
    assert_eq(manager_script.LINE, LINE)
    assert_eq(manager_script.CHAIN, CHAIN)
    for method_name in [
        "active_workspace",
        "request_switch",
        "process_safe_handoff",
        "is_switch_pending",
        "line_input_enabled",
        "chain_input_enabled",
    ]:
        assert_true(manager.has_method(method_name), "%s is required by the workspace manager contract" % method_name)

    assert_eq(manager.active_workspace(), LINE)
    assert_false(manager.is_switch_pending())
    assert_true(manager.line_input_enabled())
    assert_false(manager.chain_input_enabled())
    assert_true(line_session.can_accept_input())
    assert_false(chain_session.can_accept_input())

    var invalid: Dictionary = manager.request_switch("ACTION")
    assert_false(bool(invalid.get("accepted", true)), "unknown workspaces must fail closed")
    assert_eq(manager.active_workspace(), LINE)
    assert_false(manager.is_switch_pending())

    var same_workspace: Dictionary = manager.request_switch(LINE)
    assert_false(bool(same_workspace.get("accepted", true)), "same-workspace requests must fail closed without a pending handoff")
    assert_false(manager.is_switch_pending())

func test_round_trip_restores_line_state_a_and_chain_state_b_on_the_same_sessions() -> void:
    var fixture := _make_workspace_fixture()
    if fixture.is_empty():
        return
    var manager = fixture["manager"]
    var line_session = fixture["line"]
    var chain_session = fixture["chain"]

    var gravity: float = line_session.fall_state.config.gravity_seconds_per_cell
    line_session.tick(gravity * 0.75, false)
    assert_true(line_session.try_hold())
    assert_true(line_session.try_move(Vector2i.LEFT))
    var line_state_a: Dictionary = line_session.snapshot_runtime_state()

    var to_chain: Dictionary = _switch_and_handoff(manager, CHAIN)
    assert_true(bool(to_chain.get("switched", false)), "stable Line must hand off synchronously")
    assert_eq(manager.active_workspace(), CHAIN)
    assert_false(line_session.can_accept_input())
    assert_true(chain_session.can_accept_input())

    var committed_swap: Dictionary = chain_session.begin_swap(Vector2i(1, 0), Vector2i(1, 1))
    assert_true(bool(committed_swap.get("accepted", false)))
    var resolution: Dictionary = chain_session.complete_pending_resolution()
    assert_true(bool(resolution.get("success", false)))
    assert_false(chain_session.is_resolving())
    var chain_state_b: Dictionary = chain_session.snapshot_runtime_state()

    var to_line: Dictionary = _switch_and_handoff(manager, LINE)
    assert_true(bool(to_line.get("switched", false)))
    assert_eq(manager.active_workspace(), LINE)
    assert_eq(line_session.snapshot_runtime_state(), line_state_a, "returning to Line must restore exact state A")

    var return_to_chain: Dictionary = _switch_and_handoff(manager, CHAIN)
    assert_true(bool(return_to_chain.get("switched", false)))
    assert_eq(manager.active_workspace(), CHAIN)
    assert_eq(chain_session.snapshot_runtime_state(), chain_state_b, "returning to Chain must restore exact stable state B")

func test_rapid_switches_preserve_runtime_state_and_do_not_duplicate_chain_rewards_or_need_a_clock() -> void:
    var fixture := _make_workspace_fixture()
    if fixture.is_empty():
        return
    var manager = fixture["manager"]
    var line_session = fixture["line"]
    var chain_session = fixture["chain"]

    var gravity: float = line_session.fall_state.config.gravity_seconds_per_cell
    line_session.tick(gravity * 0.75, false)
    assert_true(line_session.try_hold())
    var line_state_a: Dictionary = line_session.snapshot_runtime_state()

    var first_request: Dictionary = manager.request_switch(CHAIN)
    var repeated_request: Dictionary = manager.request_switch(CHAIN)
    assert_true(bool(first_request.get("accepted", false)))
    assert_true(bool(repeated_request.get("accepted", false)), "repeated valid requests must not reset either workspace")
    var first_handoff: Dictionary = manager.process_safe_handoff()
    assert_true(bool(first_handoff.get("switched", false)), "handoff must complete synchronously without a pause or clock tick")

    var committed_swap: Dictionary = chain_session.begin_swap(Vector2i(1, 0), Vector2i(1, 1))
    assert_true(bool(committed_swap.get("accepted", false)))
    var resolution: Dictionary = chain_session.complete_pending_resolution()
    assert_true(bool(resolution.get("success", false)))
    var chain_state_b: Dictionary = chain_session.snapshot_runtime_state()

    var to_line_request: Dictionary = manager.request_switch(LINE)
    assert_true(bool(to_line_request.get("accepted", false)))
    var repeated_line_request: Dictionary = manager.request_switch(LINE)
    assert_true(bool(repeated_line_request.get("accepted", false)))
    var to_line: Dictionary = manager.process_safe_handoff()
    assert_true(bool(to_line.get("switched", false)))
    assert_eq(line_session.snapshot_runtime_state(), line_state_a, "rapid switching must preserve gravity, lock, Hold, and NEXT")

    var return_to_chain_request: Dictionary = manager.request_switch(CHAIN)
    assert_true(bool(return_to_chain_request.get("accepted", false)))
    var cancelled: Dictionary = manager.request_switch(LINE)
    assert_true(bool(cancelled.get("accepted", false)), "requesting the active workspace must cancel an opposite pending request")
    assert_false(manager.is_switch_pending())
    assert_eq(manager.active_workspace(), LINE)

    var final_chain_handoff: Dictionary = _switch_and_handoff(manager, CHAIN)
    assert_true(bool(final_chain_handoff.get("switched", false)))
    assert_eq(chain_session.snapshot_runtime_state(), chain_state_b, "rapid switching must not reroll Chain RNG or refill its board")

    var rewards: Array = chain_session.drain_events()
    assert_eq(rewards.size(), 1, "switch spam must preserve exactly one committed Chain reward request")
    if rewards.size() == 1:
        assert_eq(String(rewards[0].get("kind", "")), "production_chain_resolved")
    assert_eq(chain_session.drain_events().size(), 0, "switch spam must not duplicate drained rewards")

func test_switch_away_from_committed_chain_resolution_stays_pending_until_the_board_is_stable() -> void:
    var fixture := _make_workspace_fixture()
    if fixture.is_empty():
        return
    var manager = fixture["manager"]
    var line_session = fixture["line"]
    var chain_session = fixture["chain"]

    var to_chain: Dictionary = _switch_and_handoff(manager, CHAIN)
    assert_true(bool(to_chain.get("switched", false)))
    var committed_swap: Dictionary = chain_session.begin_swap(Vector2i(1, 0), Vector2i(1, 1))
    assert_true(bool(committed_swap.get("accepted", false)))
    assert_true(chain_session.is_resolving())

    var requested: Dictionary = manager.request_switch(LINE)
    assert_true(bool(requested.get("accepted", false)))
    assert_true(manager.is_switch_pending())
    var premature_handoff: Dictionary = manager.process_safe_handoff()
    assert_false(bool(premature_handoff.get("switched", false)), "committed Chain resolution must never be interrupted")
    assert_eq(manager.active_workspace(), CHAIN)
    assert_false(chain_session.can_accept_input(), "resolving Chain stays active but closes new input")
    assert_false(line_session.can_accept_input())

    var resolution: Dictionary = chain_session.complete_pending_resolution()
    assert_true(bool(resolution.get("success", false)))
    assert_false(chain_session.is_resolving())
    assert_true(chain_session.board.find_match_groups().is_empty())

    var stable_handoff: Dictionary = manager.process_safe_handoff()
    assert_true(bool(stable_handoff.get("switched", false)), "the pending request must complete once existing Chain work is stable")
    assert_eq(manager.active_workspace(), LINE)
    assert_false(manager.is_switch_pending())
    assert_true(line_session.can_accept_input())
    assert_false(chain_session.can_accept_input())
