extends GutTest

func _tracker():
    var script := load("res://src/validation/manual_validation_tracker.gd")
    assert_not_null(script)
    if script == null:
        return null
    return script.new()

func _complete_steps(tracker) -> void:
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

func test_manual_validation_requires_all_steps_and_forty_five_seconds() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    _complete_steps(tracker)
    tracker.update_elapsed(44.9)
    assert_false(tracker.is_complete())

    tracker.update_elapsed(45.0)
    assert_true(tracker.is_complete())
    assert_eq(tracker.completed_step_count(), 10)

func test_steps_must_be_observed_in_contract_order() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    tracker.record_skill_success(1.0)
    tracker.record_chain_switch_locked(2.0, 0)
    tracker.record_line_energy(3.0, 22)
    assert_eq(tracker.completed_step_count(), 0)

    tracker.record_line_run(4.0)
    tracker.record_line_energy(5.0, 22)
    tracker.record_line_lock(6.0, 2)
    tracker.record_chain_switch_locked(7.0, 2)
    tracker.record_chain_run(8.0)
    tracker.record_chain_complete(9.0, 3)
    assert_eq(tracker.completed_step_count(), 6)
    assert_false(tracker.skill_success)

    tracker.record_skill_success(10.0)
    assert_true(tracker.skill_success)

func test_line_return_only_passes_when_saved_progress_is_unchanged() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    _complete_steps(tracker)
    tracker.line_return_preserved = false
    tracker.record_line_return_preserved(14.0, 2, 3)
    assert_false(tracker.line_return_preserved)
    tracker.record_line_return_preserved(15.0, 2, 2)
    assert_true(tracker.line_return_preserved)

func test_report_contains_machine_readable_verdict_and_environment() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    _complete_steps(tracker)
    tracker.update_elapsed(45.0)

    var report: Dictionary = tracker.build_report("4.7.1.stable", "9.7.1", "abc123")
    assert_eq(report.verdict, "PASS")
    assert_eq(report.godot_version, "4.7.1.stable")
    assert_eq(report.gut_version, "9.7.1")
    assert_eq(report.commit, "abc123")
    assert_eq(report.completed_steps, 10)
    assert_true(report.elapsed_seconds >= 45.0)

func test_complete_validation_can_persist_and_reload_json_evidence() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    _complete_steps(tracker)
    tracker.update_elapsed(45.0)
    var path := "user://manual_validation_test.json"
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

    assert_true(tracker.write_report(path, "4.7.1.stable", "9.7.1", "abc123"))
    assert_true(FileAccess.file_exists(path))

    var file := FileAccess.open(path, FileAccess.READ)
    assert_not_null(file)
    if file != null:
        var parsed = JSON.parse_string(file.get_as_text())
        assert_typeof(parsed, TYPE_DICTIONARY)
        if typeof(parsed) == TYPE_DICTIONARY:
            assert_eq(parsed.get("verdict"), "PASS")
            assert_eq(parsed.get("commit"), "abc123")
            assert_eq(int(parsed.get("completed_steps", 0)), 10)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_incomplete_validation_refuses_to_write_pass_evidence() -> void:
    var tracker = _tracker()
    if tracker == null:
        return

    tracker.record_line_run(0.0)
    tracker.update_elapsed(45.0)
    var path := "user://manual_validation_incomplete.json"
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

    assert_false(tracker.write_report(path, "4.7.1.stable", "9.7.1", "abc123"))
    assert_false(FileAccess.file_exists(path))
