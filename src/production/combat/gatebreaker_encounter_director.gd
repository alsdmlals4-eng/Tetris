class_name GatebreakerEncounterDirector
extends RefCounted

var balance_status: String = ""
var current_phase: int = 1
var repair_used: bool = false

var _catalog: GatebreakerActionCatalog
var _phase2_threshold: float = 0.70
var _phase3_threshold: float = 0.30
var _phase1_cycle: Array[String] = []
var _phase2_cycle: Array[String] = []
var _phase3_entry: String = ""
var _phase3_cycle: Array[String] = []
var _repair_key: String = ""
var _repair_trigger: float = 0.50
var _repair_max_uses: int = 0
var _repair_requires_base: int = 0

var _started: bool = false
var _sequence_id: int = 1
var _phase_action_index: int = 0
var _repair_uses: int = 0

static func from_dictionary(data: Dictionary, catalog: GatebreakerActionCatalog):
    if catalog == null:
        return null
    if String(data.get("balance_status", "")) != "TUNING_SEED_NOT_FINAL":
        return null

    var phase2 := float(data.get("phase_2_at_or_below", -1.0))
    var phase3 := float(data.get("phase_3_at_or_below", -1.0))
    if phase2 <= 0.0 or phase2 >= 1.0 or phase3 <= 0.0 or phase3 >= phase2:
        return null

    var phase1 := _string_array(data.get("phase_1_cycle", []))
    var phase2_cycle := _string_array(data.get("phase_2_cycle", []))
    var phase3_cycle := _string_array(data.get("phase_3_cycle", []))
    var phase3_entry := String(data.get("phase_3_entry", ""))
    if phase1.is_empty() or phase2_cycle.is_empty() or phase3_cycle.is_empty() or phase3_entry == "":
        return null
    if phase1[0] != "light_smash":
        return null

    var repair_value = data.get("phase_2_repair", {})
    if not repair_value is Dictionary:
        return null
    var repair: Dictionary = repair_value
    var repair_key := String(repair.get("key", ""))
    var repair_trigger := float(repair.get("trigger_at_or_below", -1.0))
    var repair_max_uses := int(repair.get("max_uses", 0))
    var repair_requires_base := int(repair.get("requires_base_actions_scheduled", 0))
    if repair_key == "" or repair_trigger <= phase3 or repair_trigger > phase2:
        return null
    if repair_max_uses != 1 or repair_requires_base < 1:
        return null

    if not _all_allowed_in_phase(catalog, phase1, 1):
        return null
    if not _all_allowed_in_phase(catalog, phase2_cycle, 2):
        return null
    if not catalog.is_allowed_in_phase(repair_key, 2):
        return null
    if not catalog.is_allowed_in_phase(phase3_entry, 3):
        return null
    if not _all_allowed_in_phase(catalog, phase3_cycle, 3):
        return null
    if phase3_entry != "siege_charge" or phase3_cycle.has("rift_repair"):
        return null

    var director := GatebreakerEncounterDirector.new()
    director.balance_status = String(data["balance_status"])
    director._catalog = catalog
    director._phase2_threshold = phase2
    director._phase3_threshold = phase3
    director._phase1_cycle = phase1
    director._phase2_cycle = phase2_cycle
    director._phase3_entry = phase3_entry
    director._phase3_cycle = phase3_cycle
    director._repair_key = repair_key
    director._repair_trigger = repair_trigger
    director._repair_max_uses = repair_max_uses
    director._repair_requires_base = repair_requires_base
    return director

func phase_for_hp_ratio(hp_ratio: float) -> int:
    var ratio := clampf(hp_ratio, 0.0, 1.0)
    if ratio <= _phase3_threshold:
        return 3
    if ratio <= _phase2_threshold:
        return 2
    return 1

func bootstrap() -> Dictionary:
    if _started or _catalog == null:
        return {}
    _started = true
    current_phase = 1
    _phase_action_index = 0
    _sequence_id = 1
    _repair_uses = 0
    repair_used = false

    var current := _schedule_for_current_phase(1.0)
    var next := _schedule_for_current_phase(1.0)
    if current.is_empty() or next.is_empty():
        return {}
    return {
        "current": current,
        "next": next,
    }

func preview_next_after_resolve(boss_hp_ratio: float) -> Dictionary:
    var snapshot := _snapshot_state()
    var candidate := schedule_next_after_resolve(boss_hp_ratio)
    _restore_state(snapshot)
    return candidate

func commit_next_after_resolve(boss_hp_ratio: float, expected_action_id: String) -> Dictionary:
    if expected_action_id == "":
        return {}
    var preview := preview_next_after_resolve(boss_hp_ratio)
    if preview.is_empty() or String(preview.get("id", "")) != expected_action_id:
        return {}
    return schedule_next_after_resolve(boss_hp_ratio)

func schedule_next_after_resolve(boss_hp_ratio: float) -> Dictionary:
    if not _started or _catalog == null:
        return {}

    var desired_phase := phase_for_hp_ratio(boss_hp_ratio)
    if desired_phase > current_phase:
        current_phase = desired_phase
        _phase_action_index = 0

    return _schedule_for_current_phase(clampf(boss_hp_ratio, 0.0, 1.0))

func _schedule_for_current_phase(boss_hp_ratio: float) -> Dictionary:
    var key := ""
    match current_phase:
        1:
            key = _phase1_cycle[_phase_action_index % _phase1_cycle.size()]
            _phase_action_index += 1
        2:
            if _should_schedule_repair(boss_hp_ratio):
                key = _repair_key
                _repair_uses += 1
                repair_used = true
            else:
                key = _phase2_cycle[_phase_action_index % _phase2_cycle.size()]
                _phase_action_index += 1
        3:
            if _phase_action_index == 0:
                key = _phase3_entry
            else:
                key = _phase3_cycle[(_phase_action_index - 1) % _phase3_cycle.size()]
            _phase_action_index += 1
        _:
            return {}

    if not _catalog.is_allowed_in_phase(key, current_phase):
        return {}
    var action := _catalog.instantiate_action(key, _sequence_id)
    if action.is_empty():
        return {}
    _sequence_id += 1
    return action

func _should_schedule_repair(boss_hp_ratio: float) -> bool:
    if _repair_uses >= _repair_max_uses:
        return false
    if _phase_action_index < _repair_requires_base:
        return false
    return boss_hp_ratio <= _repair_trigger

func _snapshot_state() -> Dictionary:
    return {
        "started": _started,
        "sequence_id": _sequence_id,
        "phase_action_index": _phase_action_index,
        "repair_uses": _repair_uses,
        "current_phase": current_phase,
        "repair_used": repair_used,
    }

func _restore_state(snapshot: Dictionary) -> void:
    _started = bool(snapshot.get("started", false))
    _sequence_id = int(snapshot.get("sequence_id", 1))
    _phase_action_index = int(snapshot.get("phase_action_index", 0))
    _repair_uses = int(snapshot.get("repair_uses", 0))
    current_phase = int(snapshot.get("current_phase", 1))
    repair_used = bool(snapshot.get("repair_used", false))

static func _string_array(value) -> Array[String]:
    var result: Array[String] = []
    if not value is Array:
        return result
    for item in value:
        var key := String(item)
        if key == "":
            return []
        result.append(key)
    return result

static func _all_allowed_in_phase(catalog: GatebreakerActionCatalog, keys: Array[String], phase_id: int) -> bool:
    for key in keys:
        if not catalog.is_allowed_in_phase(key, phase_id):
            return false
    return true
