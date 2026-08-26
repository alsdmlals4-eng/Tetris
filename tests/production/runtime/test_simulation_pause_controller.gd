extends GutTest

const CONTROLLER_PATH := "res://src/production/runtime/simulation_pause_controller.gd"
const TACTICAL_SKILL := "TACTICAL_SKILL"
const SYSTEM_MENU := "SYSTEM_MENU"
const RUNTIME_TRANSITION := "RUNTIME_TRANSITION"

func _controller():
    var exists := ResourceLoader.exists(CONTROLLER_PATH)
    assert_true(exists, "SimulationPauseController must exist")
    if not exists:
        return null
    return load(CONTROLLER_PATH).new()

func test_pause_tokens_compose_across_independent_reasons() -> void:
    var controller = _controller()
    if controller == null:
        return

    var tactical: int = controller.acquire(TACTICAL_SKILL)
    var system: int = controller.acquire(SYSTEM_MENU)

    assert_gt(tactical, 0)
    assert_gt(system, tactical)
    assert_true(controller.is_paused())
    assert_true(controller.has_reason(TACTICAL_SKILL))
    assert_true(controller.has_reason(SYSTEM_MENU))
    assert_eq(controller.active_reasons(), [TACTICAL_SKILL, SYSTEM_MENU])

    assert_true(controller.release(tactical))
    assert_true(controller.is_paused(), "one remaining token must keep the simulation paused")
    assert_false(controller.has_reason(TACTICAL_SKILL))
    assert_true(controller.has_reason(SYSTEM_MENU))

    assert_true(controller.release(system))
    assert_false(controller.is_paused())
    assert_eq(controller.active_reasons(), [])

func test_duplicate_reason_tokens_are_independent_and_double_release_fails_closed() -> void:
    var controller = _controller()
    if controller == null:
        return

    var first: int = controller.acquire(TACTICAL_SKILL)
    var second: int = controller.acquire(TACTICAL_SKILL)

    assert_gt(first, 0)
    assert_gt(second, first)
    assert_eq(controller.active_reasons(), [TACTICAL_SKILL])

    assert_true(controller.release(first))
    assert_true(controller.is_paused())
    assert_true(controller.has_reason(TACTICAL_SKILL))
    assert_false(controller.release(first), "a token may be released exactly once")
    assert_false(controller.release(999999), "unknown token release must fail closed")

    assert_true(controller.release(second))
    assert_false(controller.is_paused())

func test_supported_reasons_are_deterministic_and_unknown_reason_is_rejected() -> void:
    var controller = _controller()
    if controller == null:
        return

    var transition: int = controller.acquire(RUNTIME_TRANSITION)
    var tactical: int = controller.acquire(TACTICAL_SKILL)
    var system: int = controller.acquire(SYSTEM_MENU)

    assert_gt(transition, 0)
    assert_gt(tactical, 0)
    assert_gt(system, 0)
    assert_eq(
        controller.active_reasons(),
        [TACTICAL_SKILL, SYSTEM_MENU, RUNTIME_TRANSITION],
        "reason ordering must be stable for UI/telemetry"
    )

    var unknown: int = controller.acquire("UNKNOWN_REASON")
    assert_eq(unknown, 0)
    assert_eq(controller.active_reasons(), [TACTICAL_SKILL, SYSTEM_MENU, RUNTIME_TRANSITION])
