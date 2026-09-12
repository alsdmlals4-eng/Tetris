## Explicit local diagnostics, never a resumable save or telemetry upload.
extends RefCounted
const Session = preload("res://src/replanned_r2/r2_session.gd")
const DEFAULT_DIRECTORY := "user://replanned_r2/playtest_reports"

func build(snapshot: Dictionary, practice_complete: bool = false) -> Dictionary:
    var validated = Session.new()
    if not validated.restore(snapshot):
        return _failure("INVALID_OR_UNSTABLE_SNAPSHOT")
    var state: Dictionary = validated.snapshot()
    var outcome: String = state.combat.outcome
    if practice_complete:
        if state.identity.training_mode == "" or outcome != "RUNNING":
            return _failure("INVALID_PRACTICE_COMPLETION")
        outcome = "PRACTICE_COMPLETE"
    elif outcome == "RUNNING":
        return _failure("RESULT_NOT_FINISHED")
    return {"success":true,"report":{
        "schema":"r2-playtest-report-v1",
        "implementation_revision":"UNRECORDED",
        "run_id":state.identity.run_id,
        "mode":state.identity.mode,
        "encounter_id":state.identity.encounter_id,
        "rule_pack_hash":state.identity.rule_pack_hash,
        "shape_seed":state.line.shape_seed,
        "elapsed_simulation_us":state.identity.elapsed_simulation_us,
        "outcome":outcome,
        "practice":state.identity.training_mode,
        "metrics":state.ui.metrics.duplicate(true),
        "remaining_resources":state.player.duplicate(true)}}

func write_snapshot(snapshot: Dictionary, practice_complete: bool = false,
        directory: String = DEFAULT_DIRECTORY) -> Dictionary:
    var built := build(snapshot,practice_complete)
    if not built.success: return built
    if not directory.begins_with("user://") or ".." in directory or "\\" in directory:
        return _failure("INVALID_DIRECTORY")
    var contents := JSON.stringify(built.report,"  ",true,true) + "\n"
    var path := directory.path_join(contents.sha256_text() + ".json")
    var parent := directory
    while parent != "user://" and not parent.is_empty():
        if FileAccess.file_exists(parent): return _failure("DIRECTORY_UNAVAILABLE")
        parent = parent.get_base_dir()
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        return _failure("DIRECTORY_UNAVAILABLE")
    # Atomic directory creation serializes cooperating game instances. Never steal
    # a stale lock after a crash: preserve it for the user's explicit inspection.
    var lock_path := path + ".lock"
    if DirAccess.make_dir_absolute(lock_path) != OK:
        return _failure("REPORT_BUSY_OR_LOCK_UNAVAILABLE")
    var result := _write_locked(path,contents.to_utf8_buffer())
    var cleanup := DirAccess.remove_absolute(lock_path)
    if cleanup != OK and result.success:
        result["warning"] = "LOCK_CLEANUP_FAILED"
    return result

func _write_locked(path: String, bytes: PackedByteArray) -> Dictionary:
    if FileAccess.file_exists(path):
        return _readback(path,bytes,true)
    var file := FileAccess.open(path,FileAccess.WRITE)
    if file == null: return _failure("REPORT_OPEN_FAILED")
    var stored := file.store_buffer(bytes)
    file.flush()
    var error := file.get_error()
    file.close()
    if not stored or error != OK: return _failure("REPORT_WRITE_FAILED")
    return _readback(path,bytes,false)

func _readback(path: String, expected: PackedByteArray, existing: bool) -> Dictionary:
    var file := FileAccess.open(path,FileAccess.READ)
    if file == null: return _failure("REPORT_READ_FAILED")
    var bytes := file.get_buffer(file.get_length())
    var error := file.get_error()
    file.close()
    if error != OK or bytes != expected:
        return _failure("EXISTING_REPORT_CONFLICT" if existing else "REPORT_READBACK_FAILED")
    return {"success":true,"path":path,"already_exists":existing}

static func _failure(reason: String) -> Dictionary:
    return {"success":false,"reason":reason}
