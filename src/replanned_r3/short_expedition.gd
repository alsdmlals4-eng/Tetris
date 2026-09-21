## Bounded current-combat adapter, not a second progression framework.
extends "res://src/replanned_r2/r2_expedition.gd"
const Battle=preload("res://src/replanned_r3/counter_session.gd")
const LegacyRoute=preload("res://src/replanned_r2/r2_expedition.gd")
var resource_mode:="LINE"
var reports:Array=[]

func select_resource(mode:String)->bool:
    if _state.is_empty() or _state.phase!="ROUTE" or not _state.route.is_empty() or mode not in ["LINE","SWAP"]:return false
    resource_mode=mode
    return true

func make_battle_session():
    if _state.is_empty() or _state.phase!="BATTLE":return null
    var meta:Dictionary=_state.active_battle
    var s=Battle.new(meta.difficulty,int(meta.seed),meta.run_id,meta.encounter_id)
    if not s.command("prepare_resource",{"mode":resource_mode}).success:return null
    var initial:Dictionary=s.combat.snapshot()
    initial.hp=meta.hp;initial.attack_bank=meta.attack_bank;initial.armor=meta.armor
    if not s.combat.restore(initial):return null
    return s

func finish_session(s)->Dictionary:
    if s==null or not s.can_checkpoint() or _state.phase!="BATTLE":return _error("BATTLE_NOT_READY")
    var meta:Dictionary=_state.active_battle
    var validator=Battle.new(meta.difficulty,int(meta.seed),meta.run_id,meta.encounter_id)
    var state:Dictionary=s.snapshot()
    if not validator.restore(state) or validator.resource_mode!=resource_mode:return _error("INVALID_BATTLE")
    var result=finish_battle({"run_id":s._run_id,"outcome":s.combat.outcome,"hp":s.combat.hp})
    if result.success and s.combat.outcome=="VICTORY":reports.append(state)
    return result

func summary(extra=null)->Dictionary:
    var result={"battles":reports.size(),"casts":0,"max_combo":0,"prevented":0,"reflected":0}
    var entries=reports.duplicate()
    if extra!=null and extra.combat.outcome=="DEFEAT" and extra.can_checkpoint():entries.append(extra.snapshot())
    for report in entries:
        result.casts+=int(report.metrics.casts)
        result.max_combo=maxi(result.max_combo,int(report.metrics.max_combo))
        for hit in report.combat.counter.hits:
            result.prevented+=int(hit.prevented);result.reflected+=int(hit.reflected)
    return result

func snapshot()->Dictionary:
    var result=super.snapshot()
    if result.is_empty():return result
    result.schema="r3-short-expedition-v1"
    result["resource_mode"]=resource_mode
    result["reports"]=reports.duplicate(true)
    return result

func restore(data:Dictionary)->bool:
    if data.size()!=6 or data.get("schema")!="r3-short-expedition-v1" or data.get("resource_mode") not in ["LINE","SWAP"] or not data.get("reports") is Array:return false
    var copy=data.duplicate(true)
    copy.schema="r2-expedition-v1";copy.erase("resource_mode");copy.erase("reports")
    var route=LegacyRoute.new()
    if not route.restore(copy) or data.reports.size()!=route._results.size():return false
    var replay=LegacyRoute.new(route._state.run_id,int(route._state.seed),route._state.difficulty)
    var normalized=[]
    for i in data.reports.size():
        if not data.reports[i] is Dictionary:return false
        var meta:Dictionary=replay.launch(route._state.route[i]).battle
        var s=Battle.new(meta.difficulty,int(meta.seed),meta.run_id,meta.encounter_id)
        if not s.restore(data.reports[i]) or s.resource_mode!=data.resource_mode or s.combat.outcome!="VICTORY" or s.combat.hp!=route._results[i].hp:return false
        normalized.append(s.snapshot())
        if not replay.finish_battle(route._results[i]).success:return false
        if i<route._state.supplies.size() and not replay.choose_supply(route._state.supplies[i]).success:return false
    _state=route.view();_results=route._results.duplicate(true)
    resource_mode=data.resource_mode;reports=normalized
    return true
