## Reuses atomic write/readback/backup, with a separate current-run namespace.
extends "res://src/replanned_r3/r3_expedition_save.gd"
const ShortRoute=preload("res://src/replanned_r3/short_expedition.gd")
const Battle=preload("res://src/replanned_r3/counter_session.gd")
func _init(path:String="user://short_expedition/save.json"):super(path)

func _decode(value:Dictionary)->Dictionary:
    if not value.get("expedition") is Dictionary or not _integer(value.get("clock_remainder_ns"),0,999):return _error("INVALID_ENVELOPE")
    var run=ShortRoute.new()
    if not run.restore(value.expedition):return _error("INVALID_ROUTE")
    var state:Dictionary=run.view()
    var session=null
    if state.phase=="ROUTE":
        if value.get("battle")!=null or int(value.clock_remainder_ns)!=0:return _error("ROUTE_HAS_LIVE_BATTLE")
    else:
        if not value.get("battle") is Dictionary:return _error("MISSING_BATTLE")
        var meta:Dictionary=state.active_battle
        session=Battle.new(meta.difficulty,int(meta.seed),meta.run_id,meta.encounter_id)
        if not session.restore(value.battle) or session.resource_mode!=run.resource_mode:return _error("INVALID_BATTLE")
        var expected="RUNNING" if state.phase=="BATTLE" else ("DEFEAT" if state.phase=="DEFEAT" else "VICTORY")
        if session.combat.outcome!=expected:return _error("BATTLE_PHASE_MISMATCH")
        if state.phase!="BATTLE" and session.combat.hp!=state.hp:return _error("RESULT_HP_MISMATCH")
        if state.phase in ["SUPPLY","COMPLETE"] and session.snapshot()!=run.reports[-1]:return _error("RESULT_RECEIPT_MISMATCH")
    return {"success":true,"reason":"","expedition":run,"session":session,"clock_remainder_ns":int(value.clock_remainder_ns)}
