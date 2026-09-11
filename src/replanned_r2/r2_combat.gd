## Deterministic transaction owner for the isolated R2 automatic-cast prototype.
extends RefCounted

const SESSION_PATH := "res://docs/design/r2-complete-session.json"
const RULES_PATH := "res://docs/design/autocast-r2-data.json"
const SAVE_SCHEMA := "r2-combat-snapshot-v1"
const STANDARD_MODE := "STANDARD"
const DEFAULT_RUN_ID := "standalone-r2"
const RELAXED_MODE := "RELAXED"
const MAX_HP := 100
const MAX_WAVE := 64
const COMMIT_LEAD_US := 1000
const INTEGER_LIMIT := 2147483647

var hp: int = 0
var boss_hp: int = 0
var armor: int = 0
var attack_bank: int = 0
var ward: int = 0
var ward_target: String = ""
var eta_us: int = 0
var extension_us: int = 0
var action_index: int = 0
var paused: bool = false
var outcome: String = "RUNNING"

var _mode: String = STANDARD_MODE
var _run_id: String = DEFAULT_RUN_ID
var _encounter: Dictionary = {}
var _actions: Array = []
var _skills: Dictionary = {}
var _time_per_cell_us: int = 250000
var _extension_cap_us: int = 3000000
var _rule_pack: String = ""
var _rule_pack_hash: String = ""
var _ready: bool = false
var _action_finished: bool = false
var _processed_line_events: Dictionary = {}
var _processed_line_cells: Dictionary = {}
var _processed_cast_events: Dictionary = {}
var _processed_topout_events: Dictionary = {}

func _init(mode: String = STANDARD_MODE, run_id: String = DEFAULT_RUN_ID) -> void:
    _mode = RELAXED_MODE if mode == RELAXED_MODE else STANDARD_MODE
    _run_id = run_id
    _ready = _load_rule_pack() and valid_run_id(run_id)
    if not _ready:
        outcome = "DEFEAT"
        return
    hp = int(_encounter["player_hp"])
    boss_hp = int(_encounter["boss_hp"])
    armor = int(_encounter["armor"])
    attack_bank = int(_encounter["attack_bank"])
    ward = int(_encounter["ward"])
    eta_us = _duration_us_for_index(0)

func action_id() -> String:
    if not _ready:
        return ""
    return _action_id_for_index(action_index)

func current_action() -> Dictionary:
    if not _ready:
        return {}
    return _action_for_index(action_index)

func next_action() -> Dictionary:
    if not _ready:
        return {}
    return _action_for_index(action_index + 1)

func apply_line(event_id: String, cells: Array) -> Dictionary:
    var rejected := _line_result(false, "NO_EFFECT", "")
    if not _ready:
        rejected["reason"] = "RULE_PACK_INVALID"
        return rejected
    if paused:
        rejected["reason"] = "PAUSED"
        return rejected
    if outcome != "RUNNING":
        rejected["reason"] = "COMBAT_TERMINAL"
        return rejected
    if event_id.is_empty():
        rejected["reason"] = "INVALID_EVENT_ID"
        return rejected
    if _processed_line_events.has(event_id):
        rejected["reason"] = "DUPLICATE_EVENT"
        return rejected
    if cells.is_empty():
        rejected["reason"] = "EMPTY_CELLS"
        return rejected

    var unique_payload: Dictionary = {}
    for raw_cell in cells:
        if not raw_cell is Dictionary:
            rejected["reason"] = "INVALID_CELL"
            return rejected
        var cell: Dictionary = raw_cell
        if not cell.has("id") or not cell.has("kind") or not cell["id"] is String or not cell["kind"] is String:
            rejected["reason"] = "INVALID_CELL"
            return rejected
        var cell_id := String(cell["id"])
        var kind := String(cell["kind"])
        if cell_id.is_empty():
            rejected["reason"] = "INVALID_CELL"
            return rejected
        if kind not in ["A", "D", "H", "T"]:
            rejected["reason"] = "INVALID_CELL_KIND"
            return rejected
        if unique_payload.has(cell_id) and String(unique_payload[cell_id]) != kind:
            rejected["reason"] = "CONFLICTING_CELL_KIND"
            return rejected
        unique_payload[cell_id] = kind

    var new_cells: Dictionary = {}
    for cell_id in unique_payload:
        if not _processed_line_cells.has(cell_id):
            new_cells[cell_id] = unique_payload[cell_id]
    _processed_line_events[event_id] = true
    if new_cells.is_empty():
        rejected["reason"] = "NO_NEW_CELLS"
        return rejected

    var counts := {"A": 0, "D": 0, "H": 0, "T": 0}
    for cell_id in new_cells:
        var kind := String(new_cells[cell_id])
        counts[kind] = int(counts[kind]) + 1
        _processed_line_cells[cell_id] = true

    attack_bank += int(counts["A"])
    armor += int(counts["D"])
    var healing_requested := int(counts["H"])
    var healing_applied := mini(healing_requested, MAX_HP - hp)
    hp += healing_applied

    var time_requested := int(counts["T"]) * _time_per_cell_us
    var time_applied := 0
    var time_reason := ""
    if time_requested > 0:
        if _action_finished:
            time_reason = "ACTION_FINISHED"
        elif _is_action_committed():
            time_reason = "ACTION_COMMITTED"
        elif extension_us >= _extension_cap_us:
            time_reason = "EXTENSION_CAP_REACHED"
        else:
            time_applied = mini(time_requested, _extension_cap_us - extension_us)
            extension_us += time_applied
            eta_us += time_applied
            if time_applied < time_requested:
                time_reason = "EXTENSION_CAP_REACHED"

    return {
        "success": true,
        "effect": "LINE_RESOURCES_APPLIED",
        "reason": "",
        "event_id": event_id,
        "counts": counts,
        "healing_requested": healing_requested,
        "healing_applied": healing_applied,
        "time_requested_us": time_requested,
        "time_applied_us": time_applied,
        "time_reason": time_reason,
    }

func cast(event_id: String, category: String, wave: int) -> Dictionary:
    var rejected := _cast_result(false, "NO_EFFECT", event_id, category, wave, "")
    if not _ready:
        rejected["reason"] = "RULE_PACK_INVALID"
        return rejected
    if paused:
        rejected["reason"] = "PAUSED"
        return rejected
    if outcome != "RUNNING":
        rejected["reason"] = "COMBAT_TERMINAL"
        return rejected
    if event_id.is_empty():
        rejected["reason"] = "INVALID_EVENT_ID"
        return rejected
    if _processed_cast_events.has(event_id):
        rejected["reason"] = "DUPLICATE_EVENT"
        return rejected
    if category not in ["ATK", "DEF", "SUP"]:
        rejected["reason"] = "INVALID_CATEGORY"
        return rejected
    if wave < 1 or wave > MAX_WAVE:
        rejected["reason"] = "INVALID_WAVE"
        return rejected

    var stage := mini(wave, 6)
    var values: Array = _skills[category]
    var power := int(values[stage - 1])
    _processed_cast_events[event_id] = true

    if category == "ATK":
        var bank_consumed := attack_bank
        var requested_damage := power + bank_consumed
        var damage_applied := mini(requested_damage, boss_hp)
        boss_hp -= damage_applied
        attack_bank = 0
        if boss_hp == 0:
            outcome = "VICTORY"
        return {
            "success": true,
            "effect": "ATK_DAMAGE",
            "reason": "",
            "event_id": event_id,
            "category": category,
            "wave": wave,
            "stage": stage,
            "power": power,
            "bank_consumed": bank_consumed,
            "damage_requested": requested_damage,
            "damage_applied": damage_applied,
        }

    if category == "DEF":
        var no_target_reason := ""
        if _action_finished:
            no_target_reason = "ACTION_FINISHED"
        elif _is_action_committed():
            no_target_reason = "ACTION_COMMITTED"
        elif int(current_action()["damage"]) <= 0:
            no_target_reason = "NO_DAMAGE_ACTION"
        if not no_target_reason.is_empty():
            return {
                "success": true,
                "effect": "DEF_NO_TARGET",
                "reason": no_target_reason,
                "event_id": event_id,
                "category": category,
                "wave": wave,
                "stage": stage,
                "ward_before": ward,
                "ward_after": ward,
                "ward_target": ward_target,
            }
        var ward_before := ward
        ward = maxi(ward, power)
        ward_target = action_id()
        return {
            "success": true,
            "effect": "DEF_WARD",
            "reason": "",
            "event_id": event_id,
            "category": category,
            "wave": wave,
            "stage": stage,
            "ward_before": ward_before,
            "ward_after": ward,
            "ward_target": ward_target,
        }

    var healing_applied := mini(power, MAX_HP - hp)
    hp += healing_applied
    return {
        "success": true,
        "effect": "SUP_HEAL",
        "reason": "",
        "event_id": event_id,
        "category": category,
        "wave": wave,
        "stage": stage,
        "healing_requested": power,
        "healing_applied": healing_applied,
    }

func apply_topout(event_id: String) -> Dictionary:
    var rejected := {
        "success": false,
        "effect": "NO_EFFECT",
        "reason": "",
        "event_id": event_id,
        "damage_applied": 0,
        "reset_required": false,
    }
    if not _ready:
        rejected["reason"] = "RULE_PACK_INVALID"
        return rejected
    if paused:
        rejected["reason"] = "PAUSED"
        return rejected
    if outcome != "RUNNING":
        rejected["reason"] = "COMBAT_TERMINAL"
        return rejected
    if event_id.is_empty():
        rejected["reason"] = "INVALID_EVENT_ID"
        return rejected
    if _processed_topout_events.has(event_id):
        rejected["reason"] = "DUPLICATE_EVENT"
        return rejected

    _processed_topout_events[event_id] = true
    var damage_applied := mini(hp, 25)
    hp -= damage_applied
    if hp == 0:
        outcome = "DEFEAT"
    return {
        "success": true,
        "effect": "LINE_TOPOUT_DAMAGE",
        "reason": "",
        "event_id": event_id,
        "damage_applied": damage_applied,
        "reset_required": true,
    }
func tick(delta_us: int, line_events: Array = [], cast_events: Array = []) -> Array:
    var events: Array = []
    if not _ready or paused or outcome != "RUNNING":
        return events
    if delta_us < 0:
        return [{"success": false, "effect": "NO_EFFECT", "reason": "INVALID_DELTA"}]

    var resolved_action := false
    if delta_us > 0:
        eta_us = maxi(0, eta_us - delta_us)
        if eta_us == 0:
            events.append(_resolve_current_action())
            resolved_action = true
            _action_finished = true
            if outcome == "DEFEAT":
                return events

    for raw_event in line_events:
        if not raw_event is Dictionary:
            events.append(_line_result(false, "NO_EFFECT", "INVALID_EVENT"))
            continue
        var line_event: Dictionary = raw_event
        if not line_event.has("id") or not line_event["id"] is String or not line_event.has("cells") or not line_event["cells"] is Array:
            events.append(_line_result(false, "NO_EFFECT", "INVALID_EVENT"))
            continue
        events.append(apply_line(String(line_event["id"]), line_event["cells"]))

    for raw_event in cast_events:
        if outcome != "RUNNING":
            break
        if not raw_event is Dictionary:
            events.append(_cast_result(false, "NO_EFFECT", "", "", 0, "INVALID_EVENT"))
            continue
        var cast_event: Dictionary = raw_event
        if not cast_event.has("id") or not cast_event["id"] is String or not cast_event.has("category") or not cast_event["category"] is String or not cast_event.has("wave"):
            events.append(_cast_result(false, "NO_EFFECT", "", "", 0, "INVALID_EVENT"))
            continue
        var wave_value = _normalized_integer(cast_event["wave"], 1, MAX_WAVE)
        if wave_value == null:
            events.append(_cast_result(false, "NO_EFFECT", String(cast_event["id"]), String(cast_event["category"]), 0, "INVALID_WAVE"))
            continue
        events.append(cast(String(cast_event["id"]), String(cast_event["category"]), int(wave_value)))

    if resolved_action and outcome == "RUNNING":
        _schedule_next_action()
        events.append({
            "success": true,
            "effect": "ACTION_SCHEDULED",
            "reason": "",
            "action_id": action_id(),
            "eta_us": eta_us,
        })
    return events

func snapshot() -> Dictionary:
    return {
        "schema": SAVE_SCHEMA,
        "run_id": _run_id,
        "rule_pack": _rule_pack,
        "rule_pack_hash": _rule_pack_hash,
        "encounter_id": String(_encounter.get("id", "")),
        "mode": _mode,
        "hp": hp,
        "boss_hp": boss_hp,
        "armor": armor,
        "attack_bank": attack_bank,
        "ward": ward,
        "ward_target": ward_target,
        "eta_us": eta_us,
        "extension_us": extension_us,
        "action_index": action_index,
        "paused": paused,
        "outcome": outcome,
        "processed_line_event_ids": _sorted_string_keys(_processed_line_events),
        "processed_line_cell_ids": _sorted_string_keys(_processed_line_cells),
        "processed_cast_event_ids": _sorted_string_keys(_processed_cast_events),
        "processed_topout_event_ids": _sorted_string_keys(_processed_topout_events),
    }

func restore(value: Dictionary) -> bool:
    if not _ready:
        return false
    var required := [
        "schema", "run_id", "rule_pack", "rule_pack_hash", "encounter_id", "mode",
        "hp", "boss_hp", "armor", "attack_bank", "ward", "ward_target",
        "eta_us", "extension_us", "action_index", "paused", "outcome",
        "processed_line_event_ids", "processed_line_cell_ids", "processed_cast_event_ids",
        "processed_topout_event_ids",
    ]
    if value.size() != required.size():
        return false
    for key in required:
        if not value.has(key):
            return false
    if not valid_run_id(value["run_id"]):
        return false
    var restored_run_id: String = value["run_id"]
    if not value["schema"] is String or String(value["schema"]) != SAVE_SCHEMA:
        return false
    if not value["rule_pack"] is String or String(value["rule_pack"]) != _rule_pack:
        return false
    if not value["rule_pack_hash"] is String or String(value["rule_pack_hash"]) != _rule_pack_hash:
        return false
    if not value["encounter_id"] is String or String(value["encounter_id"]) != String(_encounter["id"]):
        return false
    if not value["mode"] is String or String(value["mode"]) not in [STANDARD_MODE, RELAXED_MODE]:
        return false
    if not value["ward_target"] is String or not value["paused"] is bool or not value["outcome"] is String:
        return false

    var restored_hp = _normalized_integer(value["hp"], 0, MAX_HP)
    var restored_boss_hp = _normalized_integer(value["boss_hp"], 0, int(_encounter["boss_hp"]))
    var restored_armor = _normalized_integer(value["armor"], 0, INTEGER_LIMIT)
    var restored_bank = _normalized_integer(value["attack_bank"], 0, INTEGER_LIMIT)
    var restored_ward = _normalized_integer(value["ward"], 0, INTEGER_LIMIT)
    var restored_eta = _normalized_integer(value["eta_us"], 0, INTEGER_LIMIT)
    var restored_extension = _normalized_integer(value["extension_us"], 0, _extension_cap_us)
    var restored_index = _normalized_integer(value["action_index"], 0, INTEGER_LIMIT)
    if restored_hp == null or restored_boss_hp == null or restored_armor == null or restored_bank == null or restored_ward == null or restored_eta == null or restored_extension == null or restored_index == null:
        return false

    var restored_mode := String(value["mode"])
    var restored_outcome := String(value["outcome"])
    var maximum_eta := _duration_us_for_index(int(restored_index), restored_mode) + int(restored_extension)
    if int(restored_eta) > maximum_eta:
        return false
    if restored_outcome not in ["RUNNING", "VICTORY", "DEFEAT"]:
        return false
    if restored_outcome == "RUNNING" and (int(restored_hp) <= 0 or int(restored_boss_hp) <= 0 or int(restored_eta) <= 0):
        return false
    if restored_outcome == "VICTORY" and (int(restored_boss_hp) != 0 or int(restored_hp) <= 0):
        return false
    if restored_outcome == "DEFEAT" and int(restored_hp) != 0:
        return false

    var restored_target := String(value["ward_target"])
    if int(restored_ward) == 0 and not restored_target.is_empty():
        return false
    if int(restored_ward) > 0:
        if not _is_authored_ward_value(int(restored_ward)):
            return false
        if restored_target != _action_id_for_index(int(restored_index), restored_run_id):
            return false
        var action := _action_for_index(int(restored_index), restored_mode)
        if int(action["damage"]) <= 0:
            return false

    var line_event_set = _string_array_to_set(value["processed_line_event_ids"])
    var line_cell_set = _string_array_to_set(value["processed_line_cell_ids"])
    var cast_event_set = _string_array_to_set(value["processed_cast_event_ids"])
    var topout_event_set = _string_array_to_set(value["processed_topout_event_ids"])
    if line_event_set == null or line_cell_set == null or cast_event_set == null or topout_event_set == null:
        return false

    hp = int(restored_hp)
    boss_hp = int(restored_boss_hp)
    armor = int(restored_armor)
    attack_bank = int(restored_bank)
    ward = int(restored_ward)
    ward_target = restored_target
    eta_us = int(restored_eta)
    extension_us = int(restored_extension)
    action_index = int(restored_index)
    paused = bool(value["paused"])
    outcome = restored_outcome
    _mode = restored_mode
    _run_id = restored_run_id
    _processed_line_events = line_event_set
    _processed_line_cells = line_cell_set
    _processed_cast_events = cast_event_set
    _processed_topout_events = topout_event_set
    _action_finished = false
    return true

func _load_rule_pack() -> bool:
    if not FileAccess.file_exists(SESSION_PATH) or not FileAccess.file_exists(RULES_PATH):
        return false
    var session = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
    var rules = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
    if not session is Dictionary or not rules is Dictionary:
        return false
    if not session.has("encounter") or not session["encounter"] is Dictionary:
        return false
    if not rules.has("schema") or not rules.has("skills") or not rules["skills"] is Dictionary:
        return false
    var encounter: Dictionary = session["encounter"]
    if not encounter.has("actions") or not encounter["actions"] is Array or encounter["actions"].size() != 4:
        return false
    for key in ["id", "player_hp", "boss_hp", "attack_bank", "armor", "ward", "repeat", "relaxed_windup_multiplier", "commit_lead_seconds"]:
        if not encounter.has(key):
            return false
    if not bool(encounter["repeat"]) or roundi(float(encounter["commit_lead_seconds"]) * 1000000.0) != COMMIT_LEAD_US:
        return false
    for raw_action in encounter["actions"]:
        if not raw_action is Dictionary:
            return false
        for key in ["id", "label", "seconds", "damage", "anticipation"]:
            if not raw_action.has(key):
                return false
        if String(raw_action["id"]).is_empty() or float(raw_action["seconds"]) <= 0.0 or int(raw_action["damage"]) < 0:
            return false
    var skills: Dictionary = rules["skills"]
    for category in ["ATK", "DEF", "SUP"]:
        if not skills.has(category) or not skills[category] is Array or skills[category].size() != 6:
            return false
    if not rules.has("line") or not rules["line"] is Dictionary or not rules.has("timer") or not rules["timer"] is Dictionary:
        return false
    _time_per_cell_us = roundi(float(rules["line"].get("time_per_cell_seconds", 0.0)) * 1000000.0)
    _extension_cap_us = roundi(float(rules["timer"].get("extension_cap_seconds", 0.0)) * 1000000.0)
    if _time_per_cell_us <= 0 or _extension_cap_us <= 0:
        return false
    _encounter = encounter.duplicate(true)
    _actions = encounter["actions"].duplicate(true)
    _skills = {
        "ATK": skills["ATK"].duplicate(),
        "DEF": skills["DEF"].duplicate(),
        "SUP": skills["SUP"].duplicate(),
    }
    _rule_pack = String(rules["schema"])
    _rule_pack_hash = "%s:%s" % [FileAccess.get_sha256(RULES_PATH), FileAccess.get_sha256(SESSION_PATH)]
    return not _rule_pack.is_empty() and not _rule_pack_hash.begins_with(":") and not _rule_pack_hash.ends_with(":")

func _resolve_current_action() -> Dictionary:
    var action := current_action()
    var damage := int(action["damage"])
    var ward_absorbed := 0
    if ward_target == action_id():
        ward_absorbed = mini(ward, damage)
    var after_ward := damage - ward_absorbed
    var armor_absorbed := mini(armor, after_ward)
    var damage_to_hp := mini(hp, after_ward - armor_absorbed)
    ward = 0
    ward_target = ""
    armor -= armor_absorbed
    hp -= damage_to_hp
    if hp == 0:
        outcome = "DEFEAT"
    return {
        "success": true,
        "effect": "ENEMY_ACTION_RESOLVED",
        "reason": "",
        "action_id": action_id(),
        "damage": damage,
        "ward_absorbed": ward_absorbed,
        "armor_absorbed": armor_absorbed,
        "damage_to_hp": damage_to_hp,
    }

func _schedule_next_action() -> void:
    action_index += 1
    extension_us = 0
    eta_us = _duration_us_for_index(action_index)
    ward = 0
    ward_target = ""
    _action_finished = false

func _is_action_committed() -> bool:
    return _action_finished or eta_us <= COMMIT_LEAD_US

func _duration_us_for_index(index: int, mode: String = "") -> int:
    var action: Dictionary = _actions[posmod(index, _actions.size())]
    var selected_mode := _mode if mode.is_empty() else mode
    var multiplier := float(_encounter["relaxed_windup_multiplier"]) if selected_mode == RELAXED_MODE else 1.0
    return roundi(float(action["seconds"]) * 1000000.0 * multiplier)

func _action_id_for_index(index: int, run_identity: String = "") -> String:
    return "%s:%d" % [_run_id if run_identity.is_empty() else run_identity, index]

func _action_for_index(index: int, mode: String = "") -> Dictionary:
    var raw: Dictionary = _actions[posmod(index, _actions.size())]
    return {
        "instance_id": _action_id_for_index(index),
        "id": String(raw["id"]),
        "label": String(raw["label"]),
        "base_duration_us": roundi(float(raw["seconds"]) * 1000000.0),
        "duration_us": _duration_us_for_index(index, mode),
        "damage": int(raw["damage"]),
        "anticipation": float(raw["anticipation"]),
    }

func _line_result(success: bool, effect: String, reason: String) -> Dictionary:
    return {
        "success": success,
        "effect": effect,
        "reason": reason,
        "counts": {"A": 0, "D": 0, "H": 0, "T": 0},
        "healing_requested": 0,
        "healing_applied": 0,
        "time_requested_us": 0,
        "time_applied_us": 0,
        "time_reason": "",
    }

func _cast_result(success: bool, effect: String, event_id: String, category: String, wave: int, reason: String) -> Dictionary:
    return {
        "success": success,
        "effect": effect,
        "reason": reason,
        "event_id": event_id,
        "category": category,
        "wave": wave,
    }

func _normalized_integer(value, minimum: int, maximum: int):
    var normalized: int
    if value is int:
        normalized = int(value)
    elif value is float:
        var number := float(value)
        if is_nan(number) or is_inf(number) or floor(number) != number:
            return null
        normalized = int(number)
    else:
        return null
    if normalized < minimum or normalized > maximum:
        return null
    return normalized

func _is_authored_ward_value(value: int) -> bool:
    for authored_value in _skills["DEF"]:
        if int(authored_value) == value:
            return true
    return false

func _sorted_string_keys(values: Dictionary) -> Array:
    var result: Array = []
    for key in values.keys():
        result.append(String(key))
    result.sort()
    return result

func _string_array_to_set(value):
    if not value is Array:
        return null
    var result: Dictionary = {}
    for item in value:
        if not item is String or String(item).is_empty() or result.has(String(item)):
            return null
        result[String(item)] = true
    return result

static func valid_run_id(value) -> bool:
    return value is String and not value.strip_edges().is_empty() and value.length() <= 128
