extends SceneTree

const ENTRY_SCENE := "res://scenes/replanned_r2/main.tscn"
const RAW_ASSET_ROOT_ENV := "TETRIS_R2_SOURCE_ASSET_ROOT"
const MANIFEST_PATH := "res://docs/design/r2-complete-session.json"
const REQUIRED_JSON := [
    "res://docs/design/r2-complete-session.json",
    "res://docs/design/autocast-r2-data.json",
    "res://data/production/line_tetrominoes.json",
]

func _initialize() -> void:
    call_deferred("_verify")

func _report_path() -> String:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--report="):
            return argument.trim_prefix("--report=")
    return ""

func _record(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)

func _verify() -> void:
    var failures: Array[String] = []
    var result := {
        "engine_version": Engine.get_version_info().string,
        "main_scene": String(ProjectSettings.get_setting("application/run/main_scene", "")),
        "helper_autoload_present": ProjectSettings.has_setting("autoload/_mcp_game_helper"),
        "json_files": {},
        "raw_asset_root": OS.get_environment(RAW_ASSET_ROOT_ENV),
        "raw_asset_hashes": {},
        "asset_errors": [],
        "asset_count": 0,
        "korean_font_chars": false,
        "entry_instantiated": false,
        "practice_entered": false,
    }
    _record(result.main_scene == ENTRY_SCENE, "EXPORTED_R2_MAIN_NOT_SELECTED", failures)
    _record(not result.helper_autoload_present, "EDITOR_HELPER_AUTOLOAD_PRESENT", failures)
    _record(not String(result.raw_asset_root).is_empty(), "RAW_ASSET_ROOT_NOT_PROVIDED", failures)
    for path in REQUIRED_JSON:
        var text := FileAccess.get_file_as_string(path)
        var parsed = JSON.parse_string(text)
        result.json_files[path] = parsed is Dictionary
        _record(parsed is Dictionary, "JSON_MISSING_OR_INVALID:" + path, failures)
    var manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    if manifest is Dictionary and manifest.get("assets") is Dictionary:
        for id in manifest.assets:
            var entry: Dictionary = manifest.assets[id]
            var raw_root := OS.get_environment(RAW_ASSET_ROOT_ENV)
            var path := raw_root.path_join(String(entry.path))
            var actual := FileAccess.get_sha256(path)
            result.raw_asset_hashes[id] = actual
            _record(actual == String(entry.sha256), "RAW_ASSET_HASH_MISMATCH:" + String(id), failures)
    else:
        failures.append("ASSET_MANIFEST_MISSING")
    var assets_script = load("res://src/replanned_r2/r2_assets.gd")
    if assets_script == null:
        failures.append("ASSET_OWNER_MISSING")
    else:
        var assets = assets_script.new()
        result.asset_errors = assets.errors.duplicate()
        result.asset_count = assets.consumer_manifest().assets.size()
        _record(assets.errors.is_empty(), "ASSET_OWNER_REJECTED_PACKAGE", failures)
        _record(result.asset_count == 5, "ASSET_COUNT_NOT_FIVE", failures)
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "sans-serif"])
    result.korean_font_chars = font.has_char(0xAC00) and font.has_char(0xD55C)
    _record(result.korean_font_chars, "KOREAN_SYSTEM_FONT_UNAVAILABLE", failures)
    var packed = load(ENTRY_SCENE)
    if packed is PackedScene:
        var screen = packed.instantiate()
        root.add_child(screen)
        await process_frame
        result.entry_instantiated = screen != null and String(screen.page) == "main"
        _record(result.entry_instantiated, "R2_ENTRY_NOT_MAIN", failures)
        if result.entry_instantiated:
            var status := String(screen.get_node("Main/Status").text)
            _record(not status.begins_with("개발 오류:"), "R2_ENTRY_ASSET_ERROR:" + status, failures)
            screen.begin_practice(1)
            await process_frame
            result.practice_entered = String(screen.page) == "battle" and screen.get_node("Battle").visible
            _record(result.practice_entered, "R2_PRACTICE_NOT_ENTERED", failures)
        screen.queue_free()
    else:
        failures.append("R2_ENTRY_SCENE_MISSING")
    result.failures = failures
    result.ok = failures.is_empty()
    var path := _report_path()
    if not path.is_empty():
        var file := FileAccess.open(path, FileAccess.WRITE)
        if file != null:
            file.store_string(JSON.stringify(result, "  ") + "\n")
            file.flush()
            file.close()
    if result.ok:
        print("R2_EXPORTED_PACKAGE_PROBE_OK")
        quit(0)
    else:
        push_error("R2_EXPORTED_PACKAGE_PROBE_FAILED:" + ",".join(failures))
        quit(1)