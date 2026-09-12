extends GutTest
const Session = preload("res://src/replanned_r2/r2_session.gd")
const REPORT_PATH = "res://src/replanned_r2/r2_playtest_report.gd"
var report
var folder: String

func before_each():
    folder = "user://replanned_r2_tests/reports/%s" % str(Time.get_ticks_usec())
    report = load(REPORT_PATH).new() if ResourceLoader.exists(REPORT_PATH) else null

func ready_report() -> bool:
    assert_not_null(report, "Read-only playtest report must exist")
    return report != null

func finished():
    var session = Session.new("STANDARD", 42, "r2:report-test")
    session.command("switch")
    session.tick(120000000)
    assert_eq(session.combat.outcome, "DEFEAT")
    return session

func test_completed_report_preserves_source_and_projects_real_metrics():
    if not ready_report(): return
    var session = finished()
    var snapshot = session.snapshot()
    var before = snapshot.duplicate(true)
    var result = report.build(snapshot)
    assert_true(result.success)
    if not result.success: return
    assert_eq(result.report.schema, "r2-playtest-report-v1")
    assert_eq(result.report.run_id, "r2:report-test")
    assert_eq(result.report.outcome, "DEFEAT")
    assert_eq(result.report.mode, "STANDARD")
    assert_eq(result.report.shape_seed, "42")
    assert_eq(result.report.metrics.casts, 0)
    assert_eq(result.report.metrics.hp_damage_taken, 100)
    assert_eq(result.report.remaining_resources.hp, 0)
    assert_eq(result.report.rule_pack_hash, snapshot.identity.rule_pack_hash)
    assert_eq(result.report.implementation_revision, "UNRECORDED")
    assert_eq(snapshot, before)
    assert_eq(session.snapshot(), before)

func test_rejects_running_empty_and_inconsistent_snapshot():
    if not ready_report(): return
    assert_false(report.build({}).success)
    var session = Session.new()
    assert_false(report.build(session.snapshot()).success)
    var snapshot = finished().snapshot()
    snapshot.ui.metrics.casts = 1
    assert_false(report.build(snapshot).success)

func test_practice_classification_cannot_disguise_ordinary_run():
    if not ready_report(): return
    var session = Session.new()
    assert_false(report.build(session.snapshot(), true).success)
    session.setup_training("CHAIN", true)
    var result = report.build(session.snapshot(), true)
    assert_true(result.success)
    assert_eq(result.report.outcome, "PRACTICE_COMPLETE")
    assert_eq(result.report.practice, "CHAIN")
    assert_false(report.build(session.snapshot(), false).success)

func test_unstable_snapshot_is_rejected():
    if not ready_report(): return
    var session = Session.new()
    session.setup_training("CHAIN", true)
    session.command("chain_swap", {"from":[4,5],"to":[5,5]})
    assert_false(report.build(session.snapshot(), true).success)

func test_write_is_parseable_idempotent_and_does_not_change_snapshot():
    if not ready_report(): return
    var snapshot = finished().snapshot()
    var before = snapshot.duplicate(true)
    var first = report.write_snapshot(snapshot, false, folder)
    assert_true(first.success)
    if not first.success: return
    var bytes = FileAccess.get_file_as_bytes(first.path)
    var parsed = JSON.parse_string(bytes.get_string_from_utf8())
    assert_eq(parsed.run_id, "r2:report-test")
    assert_eq(parsed.metrics.hp_damage_taken, 100.0)
    assert_eq(first.path.get_file(), FileAccess.get_sha256(first.path) + ".json")
    var second = report.write_snapshot(snapshot, false, folder)
    assert_true(second.success)
    assert_eq(second.path, first.path)
    assert_eq(FileAccess.get_file_as_bytes(first.path), bytes)
    assert_eq(snapshot, before)

func test_conflicting_existing_file_is_never_overwritten():
    if not ready_report(): return
    var snapshot = finished().snapshot()
    var first = report.write_snapshot(snapshot, false, folder)
    assert_true(first.success)
    if not first.success: return
    var file = FileAccess.open(first.path, FileAccess.WRITE)
    file.store_string("conflicting user-owned bytes")
    file.close()
    var second = report.write_snapshot(snapshot, false, folder)
    assert_false(second.success)
    assert_eq(FileAccess.get_file_as_string(first.path), "conflicting user-owned bytes")

func test_existing_lock_is_preserved_and_does_not_change_report():
    if not ready_report(): return
    var snapshot = finished().snapshot()
    var saved = report.write_snapshot(snapshot,false,folder)
    assert_true(saved.success)
    if not saved.success: return
    var bytes = FileAccess.get_file_as_bytes(saved.path)
    assert_eq(DirAccess.make_dir_absolute(saved.path+".lock"),OK)
    var again = report.write_snapshot(snapshot,false,folder)
    assert_false(again.success)
    assert_eq(again.reason,"REPORT_BUSY_OR_LOCK_UNAVAILABLE")
    assert_eq(FileAccess.get_file_as_bytes(saved.path),bytes)
    assert_true(DirAccess.dir_exists_absolute(saved.path+".lock"))

func test_unavailable_destination_fails_without_other_writes():
    if not ready_report(): return
    DirAccess.make_dir_recursive_absolute(folder)
    var blocker = FileAccess.open(folder.path_join("file"), FileAccess.WRITE)
    blocker.store_string("preserve")
    blocker.close()
    var result = report.write_snapshot(finished().snapshot(), false, folder.path_join("file/reports"))
    assert_false(result.success)
    assert_eq(FileAccess.get_file_as_string(folder.path_join("file")), "preserve")
