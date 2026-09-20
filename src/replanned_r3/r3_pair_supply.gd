## Finite placement budget. Session routes only committed player LINE clears here.
extends RefCounted

const RULES_PATH="res://data/replanned_r3/rules.json"
var pairs: int
var remainder:=0
var discarded:=0
var _clears: Array=[]
var _cells: Array=[]
var _spawns: Array=[]
var _history: Array=[]
var _rules: Dictionary

func _init():
    _rules=JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH)).pair_supply
    pairs=int(_rules.initial)

func credit(clear_id: String, unique_cell_ids: Array) -> Dictionary:
    if clear_id.is_empty() or clear_id in _clears: return _failure("INVALID_OR_DUPLICATE_CLEAR")
    if unique_cell_ids.is_empty(): return _failure("NO_CELLS")
    var seen={}
    for cell in unique_cell_ids:
        if not cell is String or cell.is_empty() or seen.has(cell) or cell in _cells:
            return _failure("INVALID_OR_DUPLICATE_CELL")
        seen[cell]=true
    var total:=remainder+unique_cell_ids.size()
    var granted:=int(total/int(_rules.line_cells))*int(_rules.pairs_per_clear)
    var applied:=mini(granted,int(_rules.cap)-pairs)
    remainder=total%int(_rules.line_cells)
    pairs+=applied
    discarded+=granted-applied
    _clears.append(clear_id)
    _cells.append_array(unique_cell_ids)
    _history.append({"operation":"clear","id":clear_id,"cells":unique_cell_ids.duplicate()})
    return {"success":true,"applied":applied,"overflow":granted-applied,"reason":""}

func consume(spawn_id: String) -> Dictionary:
    if spawn_id.is_empty() or spawn_id in _spawns: return _failure("INVALID_OR_DUPLICATE_SPAWN")
    if pairs==0: return _failure("NO_PAIR_SUPPLY")
    pairs-=1
    _spawns.append(spawn_id)
    _history.append({"operation":"spawn","id":spawn_id})
    return {"success":true,"applied":-1,"overflow":0,"reason":""}

func _rules_hash()->String:return FileAccess.get_sha256(RULES_PATH)

func snapshot() -> Dictionary:
    return {"schema":"r3-supply-v1","rules_hash":_rules_hash(),
        "pairs":pairs,"remainder":remainder,"discarded":discarded,"clears":_clears.duplicate(),
        "cells":_cells.duplicate(),"spawns":_spawns.duplicate(),"history":_history.duplicate(true)}

func restore(value: Dictionary) -> bool:
    if value.size()!=9 or value.get("schema")!="r3-supply-v1" or value.get("rules_hash")!=_rules_hash(): return false
    if not _integer(value.get("pairs"),0,int(_rules.cap)) or not _integer(value.get("remainder"),0,int(_rules.line_cells)-1): return false
    for key in ["clears","cells","spawns"]:
        if not value.get(key) is Array: return false
        var seen={}
        for item in value[key]:
            if not item is String or item.is_empty() or seen.has(item): return false
            seen[item]=true
    # Counts cannot prove the full history, but impossible credit totals are rejected.
    if int(value.remainder)!=value.cells.size()%int(_rules.line_cells): return false
    if value.clears.size()>value.cells.size(): return false
    var earned:=int(_rules.initial)+int(value.cells.size()/int(_rules.line_cells))*int(_rules.pairs_per_clear)
    if int(value.pairs)+value.spawns.size()>earned: return false
    if not value.get("history") is Array: return false
    var replay=get_script().new()
    for entry in value.history:
        if not entry is Dictionary or not entry.get("id") is String: return false
        var result:Dictionary
        if entry.get("operation")=="clear" and entry.size()==3 and entry.get("cells") is Array:
            result=replay.credit(entry.id,entry.cells)
        elif entry.get("operation")=="spawn" and entry.size()==2:
            result=replay.consume(entry.id)
        else: return false
        if not result.success: return false
    var expected:Dictionary=replay.snapshot()
    for key in ["pairs","remainder","discarded","clears","cells","spawns"]:
        if expected[key]!=value[key]: return false
    pairs=int(value.pairs)
    remainder=int(value.remainder)
    discarded=int(value.discarded)
    _clears=value.clears.duplicate()
    _cells=value.cells.duplicate()
    _spawns=value.spawns.duplicate()
    _history=value.history.duplicate(true)
    return true

static func _integer(value, minimum: int, maximum: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value==floor(float(value)) and value>=minimum and value<=maximum

static func _failure(reason: String) -> Dictionary:
    return {"success":false,"applied":0,"overflow":0,"reason":reason}
