extends SceneTree

const Snapshot = preload("res://tools/windows/r2_export_snapshot.gd")
const MAIN_KEY := "application/run/main_scene"
const HELPER_KEY := "autoload/_mcp_game_helper"
const PRODUCTION_MAIN := "res://scenes/production/battle_briefing.tscn"
const R2_MAIN := "res://scenes/replanned_r2/main.tscn"

func _initialize() -> void:
    var failures: Array[String] = []
    var original_main = ProjectSettings.get_setting(MAIN_KEY, "")
    var had_helper := ProjectSettings.has_setting(HELPER_KEY)
    var original_helper = ProjectSettings.get_setting(HELPER_KEY, null)
    ProjectSettings.set_setting(MAIN_KEY, "res://scenes/production/battle_briefing.tscn")
    ProjectSettings.set_setting(HELPER_KEY, "*res://addons/godot_ai/runtime/game_helper.gd")
    var snapshot = Snapshot.new()
    snapshot.begin()
    if String(ProjectSettings.get_setting(MAIN_KEY, "")) != R2_MAIN:
        failures.append("R2_SNAPSHOT_MAIN_NOT_SELECTED")
    snapshot.end()
    if String(ProjectSettings.get_setting(MAIN_KEY, "")) != "res://scenes/production/battle_briefing.tscn":
        failures.append("PRODUCTION_MAIN_NOT_RESTORED")
    if String(ProjectSettings.get_setting(HELPER_KEY, "")) != "*res://addons/godot_ai/runtime/game_helper.gd":
        failures.append("HELPER_CHANGED_BY_R2_SNAPSHOT")
    snapshot.begin()
    snapshot.begin()
    snapshot.end()
    if String(ProjectSettings.get_setting(MAIN_KEY, "")) != "res://scenes/production/battle_briefing.tscn":
        failures.append("REPEATED_BEGIN_LOST_ORIGINAL")
    ProjectSettings.set_setting(MAIN_KEY, original_main)
    ProjectSettings.set_setting(HELPER_KEY, original_helper if had_helper else null)
    if failures.is_empty():
        print("R2_EXPORT_SNAPSHOT_TEST_PASS")
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)