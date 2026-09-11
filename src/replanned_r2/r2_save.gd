## Recoverable R2-only whole snapshots. FileAccess.flush is not power-loss durability.
extends RefCounted
const Session = preload("res://src/replanned_r2/r2_session.gd")
const DEFAULT_PATH := "user://replanned_r2/save.json"
const DEFAULT_OPTIONS := "user://replanned_r2/options.json"
var save_path: String
var options_path: String
## Test-only interruption injection. Empty during normal play.
var failure_point := ""
func _init(path: String = DEFAULT_PATH, options: String = DEFAULT_OPTIONS):
    save_path = path
    options_path = options

static func canonical_json(value) -> String:
    if value is Dictionary:
        var keys = value.keys()
        keys.sort()
        var items := PackedStringArray()
        for key in keys: items.append(JSON.stringify(String(key))+":"+canonical_json(value[key]))
        return "{"+",".join(items)+"}"
    if value is Array:
        var items := PackedStringArray()
        for item in value: items.append(canonical_json(item))
        return "["+",".join(items)+"]"
    if value is float and is_finite(value) and value == floor(value): return str(int(value))
    return JSON.stringify(value)

func save_session(session, clock_remainder_ns: int = 0) -> Dictionary:
    if not session.can_checkpoint(): return _error("CASCADE_OR_TRANSACTION_UNSTABLE")
    if clock_remainder_ns < 0 or clock_remainder_ns >= 1000: return _error("INVALID_CLOCK_RESIDUAL")
    var payload = {"schema":"r2-disk-v1","snapshot":session.snapshot(),"clock_remainder_ns":clock_remainder_ns}
    payload["checksum"] = canonical_json(payload).sha256_text()
    return _replace(save_path,payload,false)

func load_checkpoint() -> Dictionary:
    for suffix in ["",".bak"]:
        var payload = _read_valid(save_path+suffix,false)
        if not payload.is_empty():
            return {"success":true,"source":"primary" if suffix.is_empty() else "backup",
                "snapshot":payload.snapshot,"clock_remainder_ns":int(payload.clock_remainder_ns)}
    return _error("이어갈 수 있는 온전한 기록이 없습니다. 새 도전을 시작하세요.")

func _replace(path: String, payload: Dictionary, options: bool) -> Dictionary:
    if not _valid_payload(payload,options): return _error("INVALID_COMPLETE_PAYLOAD")
    var directory = ProjectSettings.globalize_path(path.get_base_dir())
    if DirAccess.make_dir_recursive_absolute(directory) != OK: return _error("DIRECTORY_FAILED")
    var text = canonical_json(payload)
    if not _write_flushed(path+".tmp",text): return _error("TEMP_WRITE_FAILED")
    if _read_valid(path+".tmp",options).is_empty(): return _error("TEMP_READBACK_FAILED")
    var previous = _read_valid(path,options)
    # Never copy a corrupt primary over the last known good backup.
    if not previous.is_empty():
        if failure_point == "backup": return _error("BACKUP_PRESERVATION_FAILED")
        if not _write_flushed(path+".bak.tmp",canonical_json(previous)): return _error("BACKUP_WRITE_FAILED")
        if _read_valid(path+".bak.tmp",options).is_empty(): return _error("BACKUP_READBACK_FAILED")
        if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".bak.tmp"),ProjectSettings.globalize_path(path+".bak")) != OK:
            return _error("BACKUP_RENAME_FAILED")
        if _read_valid(path+".bak",options).is_empty(): return _error("BACKUP_FINAL_READBACK_FAILED")
    if failure_point == "after_primary_removed":
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        return _error("INTERRUPTED_BEFORE_RENAME")
    if failure_point == "rename": return _error("PRIMARY_RENAME_FAILED")
    # Godot's Windows overwrite may remove the destination before MoveFileW.
    # Backup is validated above before this boundary, not claimed OS-atomic.
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path)) != OK:
        return _error("PRIMARY_RENAME_FAILED")
    var final = _read_valid(path,options)
    if final.is_empty() or canonical_json(final) != text: return _error("PRIMARY_READBACK_FAILED")
    return {"success":true,"reason":"","durability":"FLUSHED_READBACK_RECOVERABLE_NOT_POWERLOSS_ATOMIC"}

func _write_flushed(path: String, text: String) -> bool:
    var file = FileAccess.open(path,FileAccess.WRITE)
    if file == null: return false
    var stored = file.store_string(text)
    file.flush()
    var error = file.get_error()
    file.close()
    return stored and error == OK

func _read_valid(path: String, options: bool) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var file = FileAccess.open(path,FileAccess.READ)
    if file == null or file.get_length() > 4194304: return {}
    var parser = JSON.new()
    var parse_error = parser.parse(file.get_as_text())
    file.close()
    if parse_error != OK: return {}
    var value = parser.data
    if not value is Dictionary or not _valid_payload(value,options): return {}
    return value

func _valid_payload(value: Dictionary, options: bool) -> bool:
    if not value.get("checksum") is String: return false
    var body = value.duplicate(true)
    body.erase("checksum")
    if canonical_json(body).sha256_text() != value.checksum: return false
    if options:
        return value.size() == 3 and value.get("schema") == "r2-options-disk-v1" and value.get("options") is Dictionary and valid_options(value.options)
    if value.size() != 4 or value.get("schema") != "r2-disk-v1" or not value.get("snapshot") is Dictionary: return false
    var residual = value.get("clock_remainder_ns")
    if not _integer(residual,0,999): return false
    var validator = Session.new()
    return validator.restore(value.snapshot)

static func default_options() -> Dictionary:
    return {"schema":"r2-options-v1","language":"ko","font_scale":100,"reduced_motion":false,
        "audio":{"effects":70,"music":50},
        "keyboard_mapping":{"left":[KEY_LEFT,KEY_A],"right":[KEY_RIGHT,KEY_D],
            "up":[KEY_UP],"down":[KEY_DOWN,KEY_S],"rotate_left":[KEY_Z],"rotate_right":[KEY_X],
            "hard_drop":[KEY_SPACE],"hold":[KEY_C],"accept":[KEY_ENTER],"switch":[KEY_TAB],
            "atk":[KEY_1],"def":[KEY_2],"sup":[KEY_3],"pause":[KEY_ESCAPE],"details":[KEY_F1]},
        "gamepad_mapping":{"left":JOY_BUTTON_DPAD_LEFT,"right":JOY_BUTTON_DPAD_RIGHT,
            "up":JOY_BUTTON_DPAD_UP,"down":JOY_BUTTON_DPAD_DOWN,"accept":JOY_BUTTON_A,
            "cancel":JOY_BUTTON_B,"rotate_left":JOY_BUTTON_X,"rotate_right":JOY_BUTTON_Y,
            "switch":JOY_BUTTON_LEFT_SHOULDER,"category_next":JOY_BUTTON_RIGHT_SHOULDER,"pause":JOY_BUTTON_START}}

static func remap(options: Dictionary, group: String, action: String, code: int) -> Dictionary:
    if group not in ["keyboard_mapping","gamepad_mapping"] or not options.has(group) or not options[group].has(action):
        return _error("UNKNOWN_MAPPING")
    if code <= 0 and group == "keyboard_mapping": return _error("INVALID_KEY")
    if group == "gamepad_mapping" and (code < 0 or code >= JOY_BUTTON_MAX): return _error("INVALID_BUTTON")
    for other in options[group]:
        if other == action: continue
        var match_code = code in options[group][other] if group == "keyboard_mapping" else code == options[group][other]
        if match_code: return _error("충돌: "+String(other)+"에 이미 지정되어 있습니다.")
    if group == "keyboard_mapping":
        options[group][action] = [code]
    else:
        options[group][action] = code
    return {"success":true,"reason":""}

static func valid_options(value: Dictionary) -> bool:
    var defaults = default_options()
    if value.size() != defaults.size(): return false
    for key in defaults:
        if not value.has(key): return false
    if value.schema != "r2-options-v1" or value.language != "ko" or (not _integer(value.font_scale,100,125) or int(value.font_scale) not in [100,125]) or not value.reduced_motion is bool: return false
    if not value.audio is Dictionary or value.audio.size() != 2: return false
    for key in ["effects","music"]:
        if not _integer(value.audio.get(key),0,100): return false
    for group in ["keyboard_mapping","gamepad_mapping"]:
        if not value[group] is Dictionary or value[group].size() != defaults[group].size(): return false
        var used := {}
        for action in defaults[group]:
            if not value[group].has(action): return false
            var codes = value[group][action] if group == "keyboard_mapping" else [value[group][action]]
            if not codes is Array or codes.is_empty() or codes.size() > 2: return false
            for code in codes:
                if not _integer(code,1 if group == "keyboard_mapping" else 0,KEY_SPECIAL+65535 if group == "keyboard_mapping" else JOY_BUTTON_MAX-1): return false
                if used.has(int(code)): return false
                used[int(code)] = true
    return true

func save_options(options: Dictionary) -> bool:
    if not valid_options(options): return false
    var payload = {"schema":"r2-options-disk-v1","options":options.duplicate(true)}
    payload["checksum"] = canonical_json(payload).sha256_text()
    return _replace(options_path,payload,true).success
func load_options() -> Dictionary:
    for suffix in ["",".bak"]:
        var payload = _read_valid(options_path+suffix,true)
        if not payload.is_empty(): return _normalize_numbers(payload.options)
    return default_options()
static func _integer(value, low: int, high: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high
static func _error(reason: String) -> Dictionary:
    return {"success":false,"reason":reason}

static func _normalize_numbers(value):
    if value is Dictionary:
        var result := {}
        for key in value: result[key] = _normalize_numbers(value[key])
        return result
    if value is Array:
        var result := []
        for item in value: result.append(_normalize_numbers(item))
        return result
    return int(value) if value is float else value
