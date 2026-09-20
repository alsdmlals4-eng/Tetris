## Reuse verified R2 effect arithmetic with explicitly versioned R3 skill data.
extends "res://src/replanned_r2/r2_combat.gd"
const R3_RULES="res://data/replanned_r3/rules.json"

func _init(mode:String="STANDARD",run_identity:String="r3:standalone",profile:String=""):
    super(mode,run_identity,profile)
    _skills=JSON.parse_string(FileAccess.get_file_as_string(R3_RULES)).skills.duplicate(true)
    _rule_pack="r3-effects-v1"
    _rule_pack_hash=(_rule_pack_hash+":"+FileAccess.get_sha256(R3_RULES)).sha256_text()

func snapshot()->Dictionary:
    var result=super.snapshot()
    result.schema="r3-combat-v1"
    return result

func restore(data:Dictionary)->bool:
    if data.get("schema")!="r3-combat-v1":return false
    var candidate=data.duplicate(true)
    candidate.schema="r2-combat-snapshot-v1"
    return super.restore(candidate)
