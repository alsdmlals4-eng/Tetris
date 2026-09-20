## Reuse readback/backup mechanics, never migrate or overwrite R2 saves.
extends "res://src/replanned_r2/r2_save.gd"
const R3Session=preload("res://src/replanned_r3/r3_session.gd")
const FinisherSession=preload("res://src/replanned_r3/r3_finisher_session.gd")
const AssistSession=preload("res://src/replanned_r3/r3_assist_session.gd")

func _init(path:String="user://replanned_r3/save.json",options:String="user://replanned_r3/options.json"):
    super(path,options)

func save_session(session,clock_remainder_ns:int=0)->Dictionary:
    if not session.can_checkpoint():return _error("CASCADE_OR_TRANSACTION_UNSTABLE")
    if clock_remainder_ns<0 or clock_remainder_ns>=1000:return _error("INVALID_CLOCK_RESIDUAL")
    var payload={"schema":"r3-disk-v1","snapshot":session.snapshot(),"clock_remainder_ns":clock_remainder_ns}
    payload["checksum"]=canonical_json(payload).sha256_text()
    return _replace(save_path,payload,false)

func _valid_payload(value:Dictionary,options:bool)->bool:
    if options:return super._valid_payload(value,true)
    if value.size()!=4 or value.get("schema")!="r3-disk-v1" or not value.get("snapshot") is Dictionary:return false
    if not value.get("checksum") is String or not _integer(value.get("clock_remainder_ns"),0,999):return false
    var body=value.duplicate(true)
    body.erase("checksum")
    if canonical_json(body).sha256_text()!=value.checksum:return false
    var state:Dictionary=value.snapshot
    if not state.get("seed") is String or not state.seed.is_valid_int():return false
    if not state.get("run_id") is String or not state.get("difficulty") is String or not state.get("profile") is String:return false
    var script=FinisherSession if state.get("schema") in ["r3-finisher-v1","r3-finisher-choice-v1"] else R3Session
    if state.get("schema") in ["r3-assist-v1","r3-assist-choice-v1"]:script=AssistSession
    var validator=script.new(state.difficulty,int(state.seed),state.run_id,state.profile)
    return validator.restore(state)
