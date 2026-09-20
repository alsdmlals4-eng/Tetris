## Assist-only combat validation. Legacy effect packs are unchanged.
extends "res://src/replanned_r3/r3_combat.gd"
var bonus_spend_ids:Array=[]
func _init(mode:String="STANDARD",run_identity:String="r3:standalone",profile:String=""):
    super(mode,run_identity,profile)
    var path="res://data/replanned_r3/assist.json"
    _skills.DEF=JSON.parse_string(FileAccess.get_file_as_string(path)).power.D.duplicate()
    _rule_pack="r3-assist-effects-v1"
    _rule_pack_hash=(_rule_pack_hash+":"+FileAccess.get_sha256(path)).sha256_text()
func snapshot()->Dictionary:
    var result=super.snapshot()
    result.schema="r3-assist-combat-v1"
    result["bonus_spend_ids"]=bonus_spend_ids.duplicate()
    return result
func restore(data:Dictionary)->bool:
    if data.get("schema")!="r3-assist-combat-v1" or not data.get("bonus_spend_ids") is Array:return false
    var seen=[]
    for id in data.bonus_spend_ids:
        if not id is String or id.length()!=64 or id in seen:return false
        for c in id:
            if c not in "0123456789abcdef":return false
        seen.append(id)
    var copy=data.duplicate(true)
    copy.schema="r3-combat-v1"
    copy.erase("bonus_spend_ids")
    if not super.restore(copy):return false
    bonus_spend_ids=seen
    return true
