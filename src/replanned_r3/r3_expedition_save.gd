extends "res://src/replanned_r3/r3_save.gd"
const Route=preload("res://src/replanned_r3/r3_expedition.gd")
const EXPEDITION_PATH="user://replanned_r3/expedition.json"

func _init(path:String=EXPEDITION_PATH):super(path)

func save_expedition(expedition,session,clock_remainder_ns:int=0)->Dictionary:
    if expedition==null or not _integer(clock_remainder_ns,0,999):return _error("INVALID_EXPEDITION")
    if session!=null and not session.can_checkpoint():return _error("CASCADE_OR_TRANSACTION_UNSTABLE")
    var payload={"schema":"r3-expedition-disk-v1","expedition":expedition.snapshot(),
        "battle":null if session==null else session.snapshot(),"clock_remainder_ns":clock_remainder_ns}
    payload["checksum"]=canonical_json(payload).sha256_text()
    return _replace(save_path,payload,false)

func load_expedition()->Dictionary:
    for suffix in ["",".bak"]:
        var payload=_read_valid(save_path+suffix,false)
        if payload.is_empty():continue
        var result=_decode(payload)
        result["source"]="primary" if suffix.is_empty() else "backup"
        return result
    return _error("온전한 R3 원정 기록이 없습니다.")

func _valid_payload(value:Dictionary,options:bool)->bool:
    if options:return super._valid_payload(value,true)
    if value.size()!=5 or value.get("schema")!="r3-expedition-disk-v1" or not value.get("checksum") is String:return false
    var body=value.duplicate(true)
    body.erase("checksum")
    return canonical_json(body).sha256_text()==value.checksum and _decode(value).success

func _decode(value:Dictionary)->Dictionary:
    if not value.get("expedition") is Dictionary or not _integer(value.get("clock_remainder_ns"),0,999):return _error("INVALID_ENVELOPE")
    var expedition=Route.new()
    if not expedition.restore(value.expedition):return _error("INVALID_ROUTE")
    var state:Dictionary=expedition.view()
    var session=null
    if state.phase=="ROUTE":
        if value.get("battle")!=null or int(value.clock_remainder_ns)!=0:return _error("ROUTE_HAS_LIVE_BATTLE")
    else:
        if not value.get("battle") is Dictionary:return _error("MISSING_BATTLE")
        var meta:Dictionary=state.active_battle
        session=R3Session.new(meta.difficulty,int(meta.seed),meta.run_id,meta.encounter_id)
        if not session.restore(value.battle):return _error("INVALID_BATTLE")
        var expected="RUNNING" if state.phase=="BATTLE" else ("DEFEAT" if state.phase=="DEFEAT" else "VICTORY")
        if session.combat.outcome!=expected:return _error("BATTLE_PHASE_MISMATCH")
        if state.phase!="BATTLE" and session.combat.hp!=state.hp:return _error("RESULT_HP_MISMATCH")
    return {"success":true,"expedition":expedition,"session":session,"clock_remainder_ns":int(value.clock_remainder_ns)}
