extends GutTest

func _tracker():
    var script := load("res://src/validation/manual_validation_tracker.gd")
    assert_not_null(script)
    if script == null:
        return null
    return script.new()

func test_manual_validation_requires_all_steps_and_forty_five_seconds() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    tracker.record_line_run(0.0)
    tracker.record_line_energy(2.0, 22)
    tracker.record_line_lock(4.0, 2)
    tracker.record_chain_switch_locked(5.0, 2)
    tracker.record_chain_run(6.0)
    tracker.record_chain_complete(8.0, 3)
    tracker.record_skill_success(10.0)
    tracker.record_skill_rejected(11.0)
    tracker.record_enemy_during_lock(12.0)
    tracker.record_line_return_preserved(14.0, 2, 2)
    tracker.update_elapsed(44.9)
    assert_false(tracker.is_complete())

    tracker.update_elapsed(45.0)
    assert_true(tracker.is_complete())
    assert_eq(tracker.completed_step_count(), 10)

func test_line_return_only_passes_when_saved_progress_is_unchanged() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    tracker.record_line_return_preserved(14.0, 2, 3)
    assert_false(tracker.line_return_preserved)
    tracker.record_line_return_preserved(15.0, 2, 2)
    assert_true(tracker.line_return_preserved)

func test_report_contains_machine_readable_verdict_and_environment() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    tracker.record_line_run(0.0)
    tracker.record_line_energy(2.0, 22)
    tracker.record_line_lock(4.0, 2)
    tracker.record_chain_switch_locked(5.0, 2)
    tracker.record_chain_run(6.0)
    tracker.record_chain_complete(8.0, 3)
    tracker.record_skill_success(10.0)
    tracker.record_skill_rejected(11.0)
    tracker.record_enemy_during_lock(12.0)
    tracker.record_line_return_preserved(14.0, 2, 2)
    tracker.update_elapsed(45.0)

    var report := tracker.build_report("4.7.1.stable", "9.7.1", "abc123")
    assert_eq(report.verdict, "PASS")
    assert_eq(report.godot_version, "4.7.1.stable")
    assert_eq(report.gut_version, "9.7.1")
    assert_eq(report.commit, "abc123")
    assert_eq(report.completed_steps, 10)
    assert_true(report.elapsed_seconds >= 45.0)
