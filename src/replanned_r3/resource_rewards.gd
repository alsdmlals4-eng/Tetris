## Converts genuine player clears to whole resource units, retaining fractional credit.
## Synthetic unit IDs are receipts, never board cell identities or destruction targets.
extends RefCounted
const RULES="res://data/replanned_r3/resource_choice.json"
var _namespace:String
var _denominator:int
var _history:Array=[]
var _seen:Dictionary={}
var _events:Array=[]
var _counts={"A":0,"D":0,"H":0,"T":0}
var _units:Array=[]
var _reward_events:Array=[]

func _init(identity:String="resource",producer:String="SWAP"):
    _namespace=identity
    _denominator=int(JSON.parse_string(FileAccess.get_file_as_string(RULES)).resource_denominator[producer])

func credit(event_id:String,cells:Array)->Dictionary:
    if event_id.is_empty() or event_id in _events or cells.is_empty():return {"success":false}
    var unique={}
    for cell in cells:
        if not cell is Dictionary or not cell.get("id") is String or cell.id.is_empty() or cell.get("kind") not in _counts:return {"success":false}
        if unique.has(cell.id) or _seen.has(cell.id):return {"success":false}
        unique[cell.id]=true
    var result:Array=[]
    for cell in cells:
        _seen[cell.id]=true
        _counts[cell.kind]+=1
        if int(_counts[cell.kind])%_denominator==0:
            var unit={"id":_namespace+":"+cell.kind+":"+str(int(_counts[cell.kind])/_denominator),"kind":cell.kind}
            result.append(unit)
            _units.append(unit.duplicate())
    _events.append(event_id)
    _history.append({"event_id":event_id,"cells":cells.duplicate(true)})
    if not result.is_empty():_reward_events.append(event_id)
    return {"success":true,"cells":result,"raw_cells":cells.size()}

func total_units()->int:return _units.size()
func unit_ids()->Array:
    var result=[]
    for unit in _units:result.append(unit.id)
    return result
func reward_events()->Array:return _reward_events.duplicate()
func fractions()->Dictionary:
    var result={}
    for kind in _counts:result[kind]=int(_counts[kind])%_denominator
    return result
func snapshot()->Dictionary:
    return {"schema":"resource-rewards-v1","hash":FileAccess.get_sha256(RULES),"namespace":_namespace,"denominator":_denominator,"history":_history.duplicate(true)}
func restore(data:Dictionary)->bool:
    if data.size()!=5 or data.get("schema")!="resource-rewards-v1" or data.get("hash")!=FileAccess.get_sha256(RULES) or data.get("namespace")!=_namespace or data.get("denominator")!=_denominator or not data.get("history") is Array:return false
    var replay=get_script().new(_namespace,"SWAP")
    for event in data.history:
        if not event is Dictionary or event.size()!=2 or not event.get("event_id") is String or not event.get("cells") is Array:return false
        if not replay.credit(event.event_id,event.cells).success:return false
    _history=replay._history
    _seen=replay._seen
    _events=replay._events
    _counts=replay._counts
    _units=replay._units
    _reward_events=replay._reward_events
    return true
