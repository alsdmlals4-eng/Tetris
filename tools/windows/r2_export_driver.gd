@tool
extends SceneTree

const Snapshot = preload("res://tools/windows/r2_export_snapshot.gd")
var _snapshot

func _initialize() -> void:
    _snapshot = Snapshot.new()
    if not _snapshot.begin():
        push_error("R2_EXPORT_SNAPSHOT_BEGIN_FAILED")
        quit(1)
        return
    print("R2 export snapshot main: " + Snapshot.R2_TRIAL_MAIN)

func _finalize() -> void:
    if _snapshot != null:
        _snapshot.end()
        print("R2 export snapshot restored production main")