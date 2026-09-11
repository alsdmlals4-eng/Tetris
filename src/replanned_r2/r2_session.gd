## Public input/timeline/checkpoint boundary; the view never commits gameplay.
extends RefCounted

const Combat = preload("res://src/replanned_r2/r2_combat.gd")
const Line = preload("res://src/replanned_r2/r2_line.gd")
const Chain = preload("res://src/replanned_r2/r2_chain.gd")
const DATA_PATH := "res://docs/design/r2-complete-session.json"
const SAVE_SCHEMA := "r2-save-v1"

var combat
var line
var chain
var mode := "LINE"
var selected_category := "ATK"
var encounter_mode := "STANDARD"
var queued_workspace := ""
var last_cast: Dictionary = {}
var metrics := {"line_clears":0,"casts":0,"max_combo":0,"switches":0,"topouts":0,
    "damage_dealt":0,"damage_overkill":0,"hp_damage_taken":0,"boss_damage_to_hp":0,
    "topout_damage_to_hp":0,"ward_absorbed":0,"armor_absorbed":0,"healing_effective":0,
    "healing_wasted":0,"time_applied_us":0,"time_wasted_us":0,"attack_bank_generated":0,
    "attack_bank_consumed":0,"attack_bank_marginal_damage":0}
var elapsed_simulation_us := 0
var checkpoint_sequence := 0
var run_id := ""
var training_mode := ""
var _rule_pack_hash := ""
var _transaction := false

func _init(difficulty: String = "STANDARD", seed_value: int = 9112026, requested_run_id: String = "") -> void:
    encounter_mode = "RELAXED" if difficulty == "RELAXED" else "STANDARD"
    combat = Combat.new(encounter_mode)
    line = Line.new(seed_value)
    chain = Chain.new(hash("r2-chain:%d" % seed_value))
    run_id = "r2:%d" % seed_value if requested_run_id.is_empty() else requested_run_id
    _rule_pack_hash = (combat.snapshot().rule_pack_hash + ":" + FileAccess.get_sha256(Line.CATALOG_PATH)).sha256_text()

func command(action: String, args: Dictionary = {}) -> Dictionary:
    if action == "pause":
        combat.paused = true
        return _result(true)
    if action == "resume":
        if combat.outcome != "RUNNING": return _result(false,"COMBAT_TERMINAL")
        combat.paused = false
        return _result(true)
    if combat.outcome != "RUNNING": return _result(false,"COMBAT_TERMINAL")
    if combat.paused: return _result(false,"PAUSED")
    if _transaction: return _result(false,"TRANSACTION_RUNNING")
    if action == "switch":
        var target: String = "CHAIN" if mode == "LINE" else "LINE"
        if chain.resolving:
            if queued_workspace.is_empty(): queued_workspace = target
            return {"success":true,"reason":"QUEUED_UNTIL_STABLE"}
        mode = target
        metrics.switches += 1
        return _result(true)
    if action == "category":
        if chain.resolving: return _result(false,"CASCADE_CATEGORY_LOCKED")
        if not args.get("category") is String or args.category not in ["ATK","DEF","SUP"]:
            return _result(false,"INVALID_CATEGORY")
        selected_category = args.category
        return _result(true)
    if action == "chain_swap":
        if mode != "CHAIN": return _result(false,"INACTIVE_WORKSPACE")
        if not _coordinate(args.get("from")) or not _coordinate(args.get("to")):
            return _result(false,"INVALID_CELL")
        return chain.try_swap(Vector2i(int(args.from[0]),int(args.from[1])),Vector2i(int(args.to[0]),int(args.to[1])),selected_category)
    if action not in ["move","soft_drop","rotate","hold","hard_drop"]: return _result(false,"UNKNOWN_COMMAND")
    if mode != "LINE": return _result(false,"INACTIVE_WORKSPACE")
    if line.spawn_blocked():
        var topout_events := _topout()
        return {"success":true,"reason":"LINE_TOPOUT","events":topout_events}
    if action == "move":
        if not Chain.valid_integer(args.get("dx"),-1,1) or int(args.dx) == 0: return _result(false,"INVALID_DIRECTION")
        return _result(line.move(int(args.dx)),"BLOCKED")
    if action == "soft_drop": return _result(line.move(0,1),"BLOCKED")
    if action == "rotate":
        if not Chain.valid_integer(args.get("direction"),-1,1) or int(args.direction) == 0: return _result(false,"INVALID_DIRECTION")
        return _result(line.rotate(int(args.direction)),"BLOCKED")
    if action == "hold":
        var success: bool = line.hold()
        var events: Array = _topout() if success and line.spawn_blocked() else []
        return {"success":success,"reason":"" if success else "HOLD_UNAVAILABLE","events":events}
    var plan: Dictionary = line.hard_drop_plan()
    var events := _resolve_step(0,plan)
    return {"success":true,"reason":"","events":events}

func tick(delta_us: int) -> Array:
    if delta_us < 0: return [{"success":false,"reason":"INVALID_DELTA"}]
    if combat.paused or combat.outcome != "RUNNING" or delta_us == 0: return []
    var remaining := delta_us
    var events: Array = []
    while remaining > 0 and combat.outcome == "RUNNING":
        var step := mini(remaining,combat.eta_us)
        if mode == "LINE": step = mini(step,line.next_event_us())
        if chain.resolving: step = mini(step,chain.next_wave_remaining_us)
        if mode == "LINE": line.advance_time(step)
        chain.advance_time(step)
        var plan: Dictionary = {}
        if mode == "LINE":
            if line.spawn_blocked(): plan = {"topout":true}
            elif line.grounded() and line.grounded_us >= Line.LOCK_US: plan = line.lock_plan()
        events.append_array(_resolve_step(step,plan))
        elapsed_simulation_us += step
        remaining -= step
        if step == 0 and plan.is_empty() and not chain.resolving: break
    return events

func _resolve_step(delta_us: int, plan: Dictionary) -> Array:
    _transaction = true
    var lines: Array = []
    if not plan.is_empty() and not plan.get("topout",false) and not plan.cells.is_empty():
        lines.append({"id":plan.id,"cells":plan.cells})
    var cast_event: Dictionary = chain.due_cast()
    var casts: Array = [] if cast_event.is_empty() else [cast_event]
    # Boss resolves before either transaction, and closes its old target before rescheduling.
    var events: Array = combat.tick(delta_us,lines,casts)
    for event in events:
        _record_event_metrics(event)
        if event.get("category","") in ["ATK","DEF","SUP"] and event.get("success",false):
            last_cast = event.duplicate(true)
            metrics.casts += 1
            metrics.max_combo = maxi(metrics.max_combo,int(event.wave))
    if combat.outcome == "RUNNING":
        if not plan.is_empty():
            if plan.get("topout",false):
                events.append_array(_topout())
            else:
                metrics.line_clears += plan.rows.size()
                line.commit_lock()
                checkpoint_sequence += 1
                if line.spawn_blocked(): events.append_array(_topout())
        if not cast_event.is_empty() and combat.outcome == "RUNNING":
            events.append(chain.commit_wave())
            checkpoint_sequence += 1
    if combat.outcome != "RUNNING":
        chain.cancel()
        queued_workspace = ""
    elif not chain.resolving and not queued_workspace.is_empty():
        mode = queued_workspace
        queued_workspace = ""
        metrics.switches += 1
    _transaction = false
    return events

func _topout() -> Array:
    var event: Dictionary = combat.apply_topout("topout:%d" % (line.reset_sequence+1))
    _record_event_metrics(event)
    if event.get("reset_required",false):
        line.reset_after_topout()
        metrics.topouts += 1
        checkpoint_sequence += 1
    if combat.outcome != "RUNNING":
        chain.cancel()
        queued_workspace = ""
    return [event]

func setup_training(workspace: String) -> bool:
    if workspace not in ["LINE","CHAIN"] or _transaction or chain.resolving or combat.outcome != "RUNNING": return false
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    training_mode = workspace
    mode = workspace
    queued_workspace = ""
    if workspace == "LINE":
        line.setup_training(data.line_teaching)
        combat.hp = int(data.line_teaching.initial_hp)
    else:
        chain.setup_training()
    return true

func checkpoint_status() -> Dictionary:
    if _transaction: return _result(false,"TRANSACTION_RUNNING")
    if chain.resolving: return _result(false,"CASCADE_RUNNING")
    if not queued_workspace.is_empty(): return _result(false,"SWITCH_PENDING")
    return _result(true)

func can_checkpoint() -> bool:
    return checkpoint_status().success

func snapshot() -> Dictionary:
    if not can_checkpoint(): return {}
    var state: Dictionary = combat.snapshot()
    return {"identity":{"schema":SAVE_SCHEMA,"rule_pack_hash":_rule_pack_hash,
        "run_id":run_id,"mode":encounter_mode,"encounter_id":state.encounter_id,
        "elapsed_simulation_us":elapsed_simulation_us,"checkpoint_sequence":checkpoint_sequence,
        "training_mode":training_mode},
        "player":_player_state(state),"boss":_boss_state(state),
        "line":line.snapshot(),"chain":chain.snapshot(),
        "ui":{"active_workspace":mode,"selected_category":selected_category,
            "last_cast":last_cast.duplicate(true),"metrics":metrics.duplicate()},
        "combat":state}

func restore(data: Dictionary) -> bool:
    if _transaction: return false
    if data.size() != 7: return false
    for group in ["identity","player","boss","line","chain","ui","combat"]:
        if not data.get(group) is Dictionary: return false
    var identity: Dictionary = data.identity
    var identity_keys := ["schema","rule_pack_hash","run_id","mode","encounter_id",
        "elapsed_simulation_us","checkpoint_sequence","training_mode"]
    if not _has_exact_keys(identity,identity_keys): return false
    if identity.schema != SAVE_SCHEMA or identity.rule_pack_hash != _rule_pack_hash: return false
    if not identity.run_id is String or identity.run_id.is_empty() or identity.run_id.length() > 128: return false
    if identity.mode not in ["STANDARD","RELAXED"] or identity.training_mode not in ["","LINE","CHAIN"]: return false
    if not Chain.valid_integer(identity.elapsed_simulation_us,0,9007199254740991) or not Chain.valid_integer(identity.checkpoint_sequence,0,2147483647): return false
    var candidate_combat = Combat.new(identity.mode)
    if not candidate_combat.restore(data.combat): return false
    var canonical_combat: Dictionary = candidate_combat.snapshot()
    if identity.encounter_id != canonical_combat.encounter_id or identity.mode != canonical_combat.mode: return false
    if not _projection_equal(data.player,_player_state(canonical_combat)) or not _projection_equal(data.boss,_boss_state(canonical_combat)): return false
    var candidate_line = Line.new()
    if not candidate_line.restore(data.line): return false
    var candidate_chain = Chain.new()
    if not candidate_chain.restore(data.chain,canonical_combat.outcome != "RUNNING"): return false
    if identity.training_mode == "" and not data.chain.training_stream.is_empty(): return false
    var ui: Dictionary = data.ui
    if not _has_exact_keys(ui,["active_workspace","selected_category","last_cast","metrics"]): return false
    if ui.active_workspace not in ["LINE","CHAIN"] or ui.selected_category not in ["ATK","DEF","SUP"]: return false
    if not ui.last_cast is Dictionary or not ui.metrics is Dictionary or not _has_exact_keys(ui.metrics,metrics.keys()): return false
    for key in metrics:
        if not Chain.valid_integer(ui.metrics[key],0,2147483647): return false
    if not ui.last_cast.is_empty():
        if ui.last_cast.get("category","") not in ["ATK","DEF","SUP"] or not ui.last_cast.get("event_id","") in canonical_combat.processed_cast_event_ids:
            return false
        if not Chain.valid_integer(ui.last_cast.get("wave"),1,64): return false
    if not _valid_event_ledgers(data.line,data.chain,canonical_combat,ui.metrics): return false
    # All candidate owners and redundant projections validate before replacing live state.
    combat = candidate_combat
    combat.paused = true
    line = candidate_line
    chain = candidate_chain
    run_id = identity.run_id
    encounter_mode = identity.mode
    training_mode = identity.training_mode
    elapsed_simulation_us = int(identity.elapsed_simulation_us)
    checkpoint_sequence = int(identity.checkpoint_sequence)
    mode = ui.active_workspace
    selected_category = ui.selected_category
    last_cast = _normalize_numbers(ui.last_cast)
    for key in metrics: metrics[key] = int(ui.metrics[key])
    queued_workspace = ""
    return true

static func _player_state(state: Dictionary) -> Dictionary:
    return {"hp":state.hp,"armor":state.armor,"attack_bank":state.attack_bank,
        "ward_value":state.ward,"ward_target_action_instance":state.ward_target}

static func _boss_state(state: Dictionary) -> Dictionary:
    return {"hp":state.boss_hp,"action_sequence_index":int(state.action_index)%4,
        "monotonic_action_index":state.action_index,
        "current_instance":"%s:%d" % [state.encounter_id,int(state.action_index)],
        "eta_us":state.eta_us,"extension_used_us":state.extension_us,
        "committed":int(state.eta_us) <= Combat.COMMIT_LEAD_US}

static func _has_exact_keys(value: Dictionary, keys: Array) -> bool:
    if value.size() != keys.size(): return false
    for key in keys:
        if not value.has(key): return false
    return true

static func _coordinate(value) -> bool:
    return value is Array and value.size() == 2 and Chain.valid_integer(value[0],0,7) and Chain.valid_integer(value[1],0,7)

static func _result(success: bool, reason: String = "") -> Dictionary:
    return {"success":success,"reason":"" if success else reason}

static func _projection_equal(actual: Dictionary, expected: Dictionary) -> bool:
    if not _has_exact_keys(actual,expected.keys()): return false
    for key in expected:
        if expected[key] is int:
            if not Chain.valid_integer(actual[key],0,9007199254740991) or int(actual[key]) != expected[key]: return false
        elif typeof(actual[key]) != typeof(expected[key]) or actual[key] != expected[key]:
            return false
    return true

static func _normalize_numbers(value):
    if value is float and is_finite(value) and value == floor(value): return int(value)
    if value is Dictionary:
        var result: Dictionary = {}
        for key in value: result[key] = _normalize_numbers(value[key])
        return result
    if value is Array:
        var result: Array = []
        for item in value: result.append(_normalize_numbers(item))
        return result
    return value

static func _valid_event_ledgers(line_data: Dictionary, chain_data: Dictionary, state: Dictionary, stats: Dictionary) -> bool:
    var cast_ids: Array = state.processed_cast_event_ids
    var chain_events: Array = chain_data.processed_event_ids
    var maximum_chain := 0
    var maximum_wave := 0
    for id in cast_ids:
        var parts: PackedStringArray = id.split(":")
        if parts.size() != 4 or parts[0] != "chain" or parts[2] != "wave": return false
        if not parts[1].is_valid_int() or not parts[3].is_valid_int(): return false
        var number := int(parts[1])
        var wave := int(parts[3])
        if number < 1 or number > int(chain_data.chain_id) or wave < 1 or wave > 64: return false
        if id != "chain:%d:wave:%d" % [number,wave]: return false
        maximum_chain = maxi(maximum_chain,number)
        maximum_wave = maxi(maximum_wave,wave)
    for id in chain_events:
        if id not in cast_ids: return false
    if state.outcome == "RUNNING":
        if chain_events.size() != cast_ids.size() or maximum_chain != int(chain_data.chain_id): return false
    if int(stats.casts) != cast_ids.size() or int(stats.max_combo) != maximum_wave: return false
    for id in state.processed_line_event_ids:
        var parts: PackedStringArray = id.split(":")
        if parts.size() != 2 or parts[0] != "line" or not parts[1].is_valid_int(): return false
        var number := int(parts[1])
        if number < 1 or number > int(line_data.lock_sequence) or id != "line:%d" % number: return false
    for id in state.processed_line_cell_ids:
        var parts: PackedStringArray = id.split(":")
        if parts.size() != 4 or not parts[2].is_valid_int() or not parts[3].is_valid_int(): return false
        if parts[0]+":"+parts[1] not in state.processed_line_event_ids: return false
        var x := int(parts[2])
        var y := int(parts[3])
        if x < 0 or x > 9 or y < 0 or y > 23 or id != "%s:%s:%d:%d" % [parts[0],parts[1],x,y]: return false
    if state.processed_line_cell_ids.size() != int(stats.line_clears)*10: return false
    if state.processed_topout_event_ids.size() != int(line_data.reset_sequence) or int(stats.topouts) != int(line_data.reset_sequence): return false
    for i in range(int(line_data.reset_sequence)):
        if "topout:%d" % (i+1) not in state.processed_topout_event_ids: return false
    return true

func _record_event_metrics(event: Dictionary) -> void:
    if not event.get("success",false): return
    match event.get("effect",""):
        "LINE_RESOURCES_APPLIED":
            metrics.attack_bank_generated += int(event.counts.A)
            metrics.healing_effective += int(event.healing_applied)
            metrics.healing_wasted += int(event.healing_requested)-int(event.healing_applied)
            metrics.time_applied_us += int(event.time_applied_us)
            metrics.time_wasted_us += int(event.time_requested_us)-int(event.time_applied_us)
        "ATK_DAMAGE":
            metrics.damage_dealt += int(event.damage_applied)
            metrics.damage_overkill += int(event.damage_requested)-int(event.damage_applied)
            metrics.attack_bank_consumed += int(event.bank_consumed)
            # Counterfactual extra actual damage versus this same hit without bank.
            # Consumption may exceed this contribution when the boss is nearly dead.
            metrics.attack_bank_marginal_damage += maxi(0,int(event.damage_applied)-int(event.power))
        "SUP_HEAL":
            metrics.healing_effective += int(event.healing_applied)
            metrics.healing_wasted += int(event.healing_requested)-int(event.healing_applied)
        "ENEMY_ACTION_RESOLVED":
            metrics.ward_absorbed += int(event.ward_absorbed)
            metrics.armor_absorbed += int(event.armor_absorbed)
            metrics.boss_damage_to_hp += int(event.damage_to_hp)
            metrics.hp_damage_taken += int(event.damage_to_hp)
        "LINE_TOPOUT_DAMAGE":
            metrics.topout_damage_to_hp += int(event.damage_applied)
            metrics.hp_damage_taken += int(event.damage_applied)
