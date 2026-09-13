## Finite campaign progression. Combat effects remain owned by R2Session.
extends RefCounted

const CATALOG_PATH := "res://data/replanned_r2/expedition.json"
const PRESENTATION_PATH := "res://data/replanned_r2/encounter-presentation.json"
const Combat = preload("res://src/replanned_r2/r2_combat.gd")
const Chain = preload("res://src/replanned_r2/r2_chain.gd")
const Session = preload("res://src/replanned_r2/r2_session.gd")

var _catalog: Dictionary = {}
var _state: Dictionary = {}
var _results: Array = []

func _init(run_id: String = "expedition", seed_value: int = 1, difficulty: String = "STANDARD"):
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
    if not parsed is Dictionary or not _valid_catalog(parsed): return
    if not Combat.valid_run_id(run_id) or run_id.length() > 80: return
    if seed_value < -2147483648 or seed_value > 4294967295: return
    if difficulty not in ["STANDARD", "RELAXED"]: return
    _catalog = parsed.duplicate(true)
    _state = {"phase":"ROUTE", "stage":0, "run_id":run_id, "seed":seed_value,
        "difficulty":difficulty, "hp":Combat.MAX_HP, "attack_bank":0, "armor":0,
        "route":[], "supplies":[], "active_battle":{}}

func view() -> Dictionary:
    return _state.duplicate(true)

func catalog() -> Dictionary:
    return _catalog.duplicate(true)

## Presentation text does not participate in the gameplay save hash.
func encounter_brief(encounter_id: String) -> Dictionary:
    if _state.is_empty() or not _catalog.encounters.has(encounter_id): return {}
    var combat = Combat.new(_state.difficulty,"route-preview",encounter_id)
    var result: Dictionary = combat.encounter_info()
    if result.is_empty(): return {}
    result["actions"] = combat.action_cycle()
    var fallback: Dictionary = _catalog.encounters[encounter_id]
    result["enemy_name"] = fallback.label
    result["scene_line"] = ""
    result["tactical_hint"] = fallback.intent
    result["victory_line"] = "전투를 돌파했습니다."
    var source = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH))
    if source is Dictionary and source.get("schema") == "r2-encounter-presentation-v1" and source.get("encounters") is Dictionary:
        var entry = source.encounters.get(encounter_id,{})
        if entry is Dictionary:
            for key in ["enemy_name","scene_line","tactical_hint","victory_line"]:
                if entry.get(key) is String and not entry[key].is_empty(): result[key]=entry[key]
    return result

func available_encounters() -> Array:
    if _state.is_empty() or _state.phase != "ROUTE": return []
    return _catalog.stages[_state.stage].duplicate()

func launch(encounter_id: String) -> Dictionary:
    if encounter_id not in available_encounters(): return _error("ENCOUNTER_NOT_AVAILABLE")
    _state.active_battle = {"encounter_id":encounter_id,
        "run_id":"%s:%d:%s" % [_state.run_id, _state.stage, encounter_id],
        "seed":hash("%s:%d:%s" % [str(_state.seed), _state.stage, encounter_id]),
        "difficulty":_state.difficulty, "hp":_state.hp,
        "attack_bank":_state.attack_bank, "armor":_state.armor}
    _state.route.append(encounter_id)
    _state.phase = "BATTLE"
    return {"success":true,"reason":"","battle":_state.active_battle.duplicate(true)}

## Caller passes a terminal receipt from the active real battle, not a UI result flag.
func finish_battle(receipt: Dictionary) -> Dictionary:
    if _state.is_empty() or _state.phase != "BATTLE": return _error("NOT_IN_BATTLE")
    if receipt.size() != 3 or receipt.get("run_id") != _state.active_battle.run_id:
        return _error("BATTLE_IDENTITY_MISMATCH")
    if receipt.get("outcome") not in ["VICTORY", "DEFEAT"]: return _error("BATTLE_NOT_TERMINAL")
    if not Chain.valid_integer(receipt.get("hp"),0,Combat.MAX_HP): return _error("INVALID_HP")
    if (receipt.outcome == "DEFEAT") != (int(receipt.hp) == 0): return _error("INVALID_OUTCOME_HP")
    _state.hp = int(receipt.hp)
    if receipt.outcome == "VICTORY": _results.append(receipt.duplicate(true))
    if receipt.outcome == "DEFEAT": _state.phase = "DEFEAT"
    elif _state.stage == _catalog.stages.size()-1: _state.phase = "COMPLETE"
    else: _state.phase = "SUPPLY"
    return {"success":true,"reason":"","phase":_state.phase}

func supply_preview(supply_id: String) -> Dictionary:
    if _state.is_empty() or _state.phase != "SUPPLY" or not _catalog.supplies.has(supply_id): return {}
    var supply: Dictionary = _catalog.supplies[supply_id]
    return {"healing_requested":int(supply.heal),
        "healing_applied":mini(int(supply.heal),Combat.MAX_HP-int(_state.hp)),
        "attack_bank":int(supply.attack_bank),"armor":int(supply.armor)}

func choose_supply(supply_id: String) -> Dictionary:
    var preview := supply_preview(supply_id)
    if preview.is_empty(): return _error("SUPPLY_NOT_AVAILABLE")
    _state.hp += preview.healing_applied
    _state.attack_bank = preview.attack_bank
    _state.armor = preview.armor
    _state.supplies.append(supply_id)
    _state.stage += 1
    _state.phase = "ROUTE"
    _state.active_battle = {}
    return {"success":true,"reason":"","receipt":preview}

func retry_battle() -> Dictionary:
    if _state.is_empty() or _state.phase != "DEFEAT": return _error("RETRY_NOT_AVAILABLE")
    _state.hp = _state.active_battle.hp
    _state.phase = "BATTLE"
    return {"success":true,"reason":"","battle":_state.active_battle.duplicate(true)}

func make_battle_session():
    if _state.is_empty() or _state.phase != "BATTLE": return null
    var meta: Dictionary = _state.active_battle
    var session = Session.new(meta.difficulty,int(meta.seed),meta.run_id,meta.encounter_id)
    if session.combat.encounter_info().is_empty(): return null
    var initial: Dictionary = session.combat.snapshot()
    initial.hp = meta.hp
    initial.attack_bank = meta.attack_bank
    initial.armor = meta.armor
    if not session.combat.restore(initial): return null
    return session

func snapshot() -> Dictionary:
    if _state.is_empty(): return {}
    return {"schema":"r2-expedition-v1", "catalog_hash":FileAccess.get_sha256(CATALOG_PATH),
        "state":view(), "results":_results.duplicate(true)}

## Replay the bounded completed route through the same public guards before commit.
func restore(value: Dictionary) -> bool:
    if value.size() != 4 or value.get("schema") != "r2-expedition-v1": return false
    if value.get("catalog_hash") != FileAccess.get_sha256(CATALOG_PATH): return false
    if not value.get("state") is Dictionary or not value.get("results") is Array: return false
    var state: Dictionary = value.state
    if not state.get("run_id") is String or not state.get("difficulty") is String: return false
    if not Chain.valid_integer(state.get("seed"),-2147483648,4294967295): return false
    if not state.get("route") is Array or not state.get("supplies") is Array: return false
    if state.route.size() > _catalog.stages.size() or value.results.size() > state.route.size(): return false
    if state.supplies.size() > value.results.size(): return false
    var candidate = get_script().new(state.run_id, int(state.seed), state.difficulty)
    if candidate.view().is_empty(): return false
    for i in state.route.size():
        if not state.route[i] is String or not candidate.launch(state.route[i]).success: return false
        if i < value.results.size():
            if not value.results[i] is Dictionary or value.results[i].get("outcome") != "VICTORY": return false
            if not candidate.finish_battle(value.results[i]).success: return false
        if i < state.supplies.size():
            if not state.supplies[i] is String or not candidate.choose_supply(state.supplies[i]).success: return false
    if state.get("phase") == "DEFEAT":
        var active: Dictionary = candidate.view().active_battle
        if active.is_empty(): return false
        if not candidate.finish_battle({"run_id":active.run_id,"outcome":"DEFEAT","hp":0}).success: return false
    # JSON turns integer fields into floats. Compare both complete projections in
    # that same representation, after replay guards validate the incoming values.
    if JSON.parse_string(JSON.stringify(candidate.view())) != JSON.parse_string(JSON.stringify(state)): return false
    _state = candidate.view()
    _results = candidate._results.duplicate(true)
    return true

static func _error(reason: String) -> Dictionary:
    return {"success":false,"reason":reason}

static func _valid_catalog(value: Dictionary) -> bool:
    if value.get("schema") != "r2-expedition-catalog-v1": return false
    if not value.get("stages") is Array or value.stages.is_empty(): return false
    if not value.get("encounters") is Dictionary or not value.get("supplies") is Dictionary: return false
    for field in ["title", "opening", "ending"]:
        if not value.get(field) is String or value[field].is_empty(): return false
    var seen := {}
    for stage in value.stages:
        if not stage is Array or stage.is_empty(): return false
        for id in stage:
            if not id is String or id.is_empty() or seen.has(id) or not value.encounters.has(id): return false
            seen[id] = true
            var encounter = value.encounters[id]
            if not encounter is Dictionary: return false
            for field in ["label", "intent"]:
                if not encounter.get(field) is String or encounter[field].is_empty(): return false
    if seen.size() != value.encounters.size() or value.supplies.is_empty(): return false
    for id in value.supplies:
        var supply = value.supplies[id]
        if not supply is Dictionary or not supply.get("label") is String: return false
        for field in ["heal", "attack_bank", "armor"]:
            if not Chain.valid_integer(supply.get(field),0,Combat.MAX_HP): return false
    return true
