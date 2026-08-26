## 실시간 Gatebreaker 행동 스케줄러가 authored 위협 순서와 ETA를 보존하는지 검증한다.
extends GutTest

const SCHEDULER_PATH := "res://src/production/runtime/enemy_action_scheduler.gd"
const TIMING_CONFIG_PATH := "res://src/production/runtime/gatebreaker_realtime_timing_config.gd"
const ACTION_CATALOG_PATH := "res://src/production/combat/gatebreaker_action_catalog.gd"
const DIRECTOR_PATH := "res://src/production/combat/gatebreaker_encounter_director.gd"
const TELEGRAPH_PATH := "res://src/production/combat/gatebreaker_telegraph_state.gd"
const RESOLVER_PATH := "res://src/production/combat/production_enemy_action_resolver.gd"
const COMBAT_STATE_PATH := "res://src/production/combat/production_combat_state.gd"
const ACTION_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const SEQUENCE_DATA_PATH := "res://data/production/gatebreaker_sequence_seed.json"
const TIMING_DATA_PATH := "res://data/production/gatebreaker_realtime_timing_seed.json"

func _read_json(path: String):
    return JSON.parse_string(FileAccess.get_file_as_string(path))

func _required_paths_exist() -> bool:
    var ready := true
    for path in [
        SCHEDULER_PATH,
        TIMING_CONFIG_PATH,
        ACTION_CATALOG_PATH,
        DIRECTOR_PATH,
        TELEGRAPH_PATH,
        RESOLVER_PATH,
        COMBAT_STATE_PATH,
    ]:
        var exists := ResourceLoader.exists(path)
        assert_true(exists, "%s must exist for the realtime enemy scheduler contract" % path)
        ready = ready and exists
    for path in [ACTION_DATA_PATH, SEQUENCE_DATA_PATH, TIMING_DATA_PATH]:
        var exists := FileAccess.file_exists(path)
        assert_true(exists, "%s must exist for the realtime enemy scheduler contract" % path)
        ready = ready and exists
    return ready

func _make_scheduler():
    if not _required_paths_exist():
        return null
    var catalog = load(ACTION_CATALOG_PATH).from_dictionary(_read_json(ACTION_DATA_PATH))
    var director = load(DIRECTOR_PATH).from_dictionary(_read_json(SEQUENCE_DATA_PATH), catalog)
    var timing = load(TIMING_CONFIG_PATH).from_dictionary(_read_json(TIMING_DATA_PATH))
    var resolver = load(RESOLVER_PATH).new()
    assert_not_null(catalog)
    assert_not_null(director)
    assert_not_null(timing)
    if catalog == null or director == null or timing == null:
        return null
    return load(SCHEDULER_PATH).new(director, timing, resolver)

func _context(player_hp := 100, enemy_hp := 100) -> Dictionary:
    var player = load(COMBAT_STATE_PATH).new(100)
    player.hp = player_hp
    var enemy = load(COMBAT_STATE_PATH).new(100)
    enemy.hp = enemy_hp
    return {"player": player, "enemy": enemy}

func test_scheduler_exposes_realtime_api_and_only_advances_when_ticked() -> void:
    var scheduler = _make_scheduler()
    if scheduler == null:
        return

    for method_name in [
        "start",
        "tick_simulation",
        "current_action_id",
        "next_action_id",
        "remaining_seconds",
        "is_action_committed",
    ]:
        assert_true(scheduler.has_method(method_name), "%s is required by the realtime scheduler contract" % method_name)

    var started: Dictionary = scheduler.start()
    assert_true(bool(started.get("started", false)))
    assert_eq(scheduler.current_action_id(), "gatebreaker:light_smash:1")
    assert_eq(scheduler.next_action_id(), "gatebreaker:gatebreaker_slam:2")
    assert_almost_eq(scheduler.remaining_seconds(), 8.0, 0.001)
    assert_false(scheduler.is_action_committed())

    assert_almost_eq(scheduler.remaining_seconds(), 8.0, 0.001, "reading the scheduler cannot advance enemy time")
    assert_eq(scheduler.tick_simulation(3.0, _context()).size(), 0)
    assert_almost_eq(scheduler.remaining_seconds(), 5.0, 0.001)
    assert_eq(scheduler.tick_simulation(4.99, _context()).size(), 0)
    assert_almost_eq(scheduler.remaining_seconds(), 0.01, 0.001)

func test_scheduler_resolves_each_authored_action_once_then_advances_the_locked_forecast() -> void:
    var scheduler = _make_scheduler()
    if scheduler == null:
        return
    scheduler.start()
    var events: Array = scheduler.tick_simulation(8.0, _context())

    assert_eq(events.size(), 1)
    assert_eq(String(events[0].get("kind", "")), "ENEMY_ACTION_RESOLVED")
    assert_eq(String(events[0].get("action_id", "")), "gatebreaker:light_smash:1")
    assert_true(bool(events[0].get("resolved", false)))
    assert_eq(scheduler.current_action_id(), "gatebreaker:gatebreaker_slam:2")
    assert_eq(scheduler.next_action_id(), "gatebreaker:light_smash:3")
    assert_almost_eq(scheduler.remaining_seconds(), 12.0, 0.001)
    assert_eq(scheduler.tick_simulation(0.0, _context()).size(), 0, "a prior-frame action cannot resolve twice")

func test_scheduler_never_retargets_authored_threats_from_player_state() -> void:
    var healthy_player_scheduler = _make_scheduler()
    var critical_player_scheduler = _make_scheduler()
    if healthy_player_scheduler == null or critical_player_scheduler == null:
        return
    healthy_player_scheduler.start()
    critical_player_scheduler.start()

    healthy_player_scheduler.tick_simulation(8.0, _context(100, 100))
    critical_player_scheduler.tick_simulation(8.0, _context(1, 100))

    assert_eq(healthy_player_scheduler.current_action_id(), "gatebreaker:gatebreaker_slam:2")
    assert_eq(
        critical_player_scheduler.current_action_id(),
        healthy_player_scheduler.current_action_id(),
        "player HP may change resolution impact but cannot secretly retarget the locked current telegraph"
    )
    assert_eq(critical_player_scheduler.next_action_id(), healthy_player_scheduler.next_action_id())

func test_scheduler_uses_boss_hp_only_at_authored_resolution_boundaries() -> void:
    var scheduler = _make_scheduler()
    if scheduler == null:
        return
    scheduler.start()
    var phase_two_context := _context(100, 69)
    scheduler.tick_simulation(8.0, phase_two_context)

    assert_eq(scheduler.current_action_id(), "gatebreaker:gatebreaker_slam:2")
    assert_eq(scheduler.next_action_id(), "gatebreaker:rift_siphon:3")
    assert_eq(scheduler.tick_simulation(12.0, phase_two_context).size(), 1)
    assert_eq(scheduler.current_action_id(), "gatebreaker:rift_siphon:3")
