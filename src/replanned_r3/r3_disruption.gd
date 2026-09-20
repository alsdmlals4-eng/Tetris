## Fixed ID reservation only. Session owns ETA, HP and atomic board cleanup.
extends RefCounted
const Validation=preload("res://src/replanned_r2/r2_chain.gd")
const RULES_PATH="res://data/replanned_r3/rules.json"
var _seed:int
var _reservation:Dictionary={}
var _completed:Array=[]

func _init(seed_value:int=9112026): _seed=seed_value

func begin(action_id:String,board:String,count:int)->Dictionary:
    if not _reservation.is_empty() or action_id.is_empty() or action_id in _completed:
        return _failure("DUPLICATE_OR_PENDING_ACTION")
    if board not in ["LINE","CHAIN"] or count<0 or count>84: return _failure("INVALID_TARGET")
    _reservation={"action_id":action_id,"target_board":board,"count":count,"reserved":false,"target_ids":[]}
    return {"success":true}

func reserve(eta_us:int,candidates:Array)->Dictionary:
    if _reservation.is_empty() or _reservation.reserved: return _failure("NO_UNRESERVED_ACTION")
    var preview_us:int=int(JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH)).disruption.preview_us)
    if eta_us<0 or eta_us>preview_us: return _failure("OUTSIDE_PREVIEW")
    var ids:Array=[]
    for cell in candidates:
        if not cell is Dictionary or not cell.get("cell_id") is String or cell.cell_id.is_empty() or cell.cell_id in ids:
            return _failure("INVALID_CANDIDATES")
        ids.append(cell.cell_id)
    ids.sort()
    var rng=RandomNumberGenerator.new()
    rng.seed=hash("r3-disruption:%d:%s"%[_seed,_reservation.action_id])
    for index in range(ids.size()-1,0,-1):
        var other=rng.randi_range(0,index)
        var temp=ids[index]
        ids[index]=ids[other]
        ids[other]=temp
    _reservation.target_ids=ids.slice(0,mini(ids.size(),int(_reservation.count)))
    _reservation.reserved=true
    return {"success":true}

func preview()->Dictionary: return _reservation.duplicate(true)

func cancel_uncommitted()->void:
    _reservation={}

func commit()->Dictionary:
    if _reservation.is_empty() or not _reservation.reserved: return _failure("NO_RESERVATION")
    var result=_reservation.duplicate(true)
    result.success=true
    result.origin="ENEMY_DESTROY"
    result.rewards=[]
    _completed.append(_reservation.action_id)
    _reservation={}
    return result

func snapshot()->Dictionary:
    return {"schema":"r3-disruption-v1","rules_hash":FileAccess.get_sha256(RULES_PATH),"seed":str(_seed),
        "reservation":preview(),"completed":_completed.duplicate()}

func restore(data:Dictionary)->bool:
    if data.size()!=5 or data.get("schema")!="r3-disruption-v1" or data.get("rules_hash")!=FileAccess.get_sha256(RULES_PATH): return false
    if data.get("seed")!=str(_seed) or not data.get("completed") is Array or not data.get("reservation") is Dictionary: return false
    var seen:Dictionary={}
    for id in data.completed:
        if not id is String or id.is_empty() or seen.has(id): return false
        seen[id]=true
    var reservation:Dictionary=data.reservation
    if not reservation.is_empty():
        if reservation.size()!=5 or not reservation.get("action_id") is String or reservation.action_id.is_empty() or seen.has(reservation.action_id): return false
        if reservation.get("target_board") not in ["LINE","CHAIN"] or not Validation.valid_integer(reservation.get("count"),0,84): return false
        if not reservation.get("reserved") is bool or not reservation.get("target_ids") is Array: return false
        if reservation.target_ids.size()>int(reservation.count) or (not reservation.reserved and not reservation.target_ids.is_empty()): return false
        seen.clear()
        for id in reservation.target_ids:
            if not id is String or id.is_empty() or seen.has(id): return false
            seen[id]=true
    _reservation=reservation.duplicate(true)
    if not _reservation.is_empty(): _reservation.count=int(_reservation.count)
    _completed=data.completed.duplicate()
    return true

static func _failure(reason:String)->Dictionary: return {"success":false,"reason":reason}
