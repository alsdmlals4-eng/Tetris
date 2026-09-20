## Skill units share the progress meter, not the actual cleared-cell ledger.
extends "res://src/replanned_r3/bonus_supply.gd"
const MASTERY_CONFIG="res://data/replanned_r3/mastery.json"
var mastery:Array=[]

func credit_mastery(event_id:String,units:int)->Dictionary:
    if event_id.is_empty() or units<1 or units>20:return _failure("INVALID_MASTERY")
    for entry in mastery:
        if entry.id==event_id:return _failure("DUPLICATE_MASTERY")
    var total=remainder+units
    var granted=int(total/int(_rules.line_cells))*int(_rules.pairs_per_clear)
    var applied=mini(granted,int(_rules.cap)-pairs)
    pairs+=applied
    discarded+=granted-applied
    remainder=total%int(_rules.line_cells)
    mastery.append({"id":event_id,"units":units})
    _history.append({"operation":"mastery","id":event_id,"units":units})
    return {"success":true,"applied":applied,"overflow":granted-applied,"reason":"","mastery_units":units}

func _rules_hash()->String:return (super._rules_hash()+":"+FileAccess.get_sha256(MASTERY_CONFIG)).sha256_text()

func snapshot()->Dictionary:
    var result=super.snapshot()
    result.schema="r3-mastery-supply-v1"
    result["mastery"]=mastery.duplicate(true)
    return result

func restore(value:Dictionary)->bool:
    if value.size()!=10 or value.get("schema")!="r3-mastery-supply-v1" or value.get("rules_hash")!=_rules_hash() or not value.get("history") is Array:return false
    var replay=get_script().new()
    for entry in value.history:
        if not entry is Dictionary or not entry.get("id") is String:return false
        var result:Dictionary
        if entry.get("operation")=="clear" and entry.size()==3 and entry.get("cells") is Array:result=replay.credit(entry.id,entry.cells)
        elif entry.get("operation")=="spawn" and entry.size()==2:result=replay.consume(entry.id)
        elif entry.get("operation")=="mastery" and entry.size()==3 and _integer(entry.get("units"),1,20):result=replay.credit_mastery(entry.id,int(entry.units))
        else:return false
        if not result.success:return false
    var expected:Dictionary=replay.snapshot()
    for key in expected:
        if not value.has(key) or expected[key]!=value[key]:return false
    pairs=replay.pairs
    remainder=replay.remainder
    discarded=replay.discarded
    _cells=replay._cells
    _clears=replay._clears
    _spawns=replay._spawns
    _history=replay._history
    mastery=replay.mastery
    return true
