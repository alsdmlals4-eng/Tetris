## R2 movement engine, R3 persistent settled-cell identity. No reward owner here.
extends RefCounted
const LineEngine=preload("res://src/replanned_r2/r2_line.gd")
const Validation=preload("res://src/replanned_r2/r2_chain.gd")
const LOCK_US=LineEngine.LOCK_US
var _engine
var _namespace: String
var _sequence:=0
var _cells: Array=[]
var _destructions: Array=[]

func _init(seed_value:int=9112026,namespace_value:String="line"):
    _engine=LineEngine.new(seed_value)
    _namespace=namespace_value

func rows(visible_only:bool=true)->Array: return _engine.rows(visible_only)
func active_cells()->Array: return _engine.active_cells()
func ghost_cells()->Array: return _engine.ghost_cells()
func active_pair()->Dictionary: return _engine.active_pair()
func hold_pair()->Dictionary: return _engine.hold_pair()
func next_pairs()->Array: return _engine.next_queue.duplicate(true)
func grounded()->bool: return _engine.grounded()
func grounded_time()->int: return _engine.grounded_us
func spawn_blocked()->bool: return _engine.spawn_blocked()
func move(dx:int,dy:int=0)->bool: return _engine.move(dx,dy)
func rotate(direction:int)->bool: return _engine.rotate(direction)
func hold()->bool: return _engine.hold()
func next_event_us()->int: return _engine.next_event_us()
func advance_time(delta_us:int)->void: _engine.advance_time(delta_us)
func target_candidates()->Array: return _cells.duplicate(true)

func _placed_cells()->Array:
    var result=_cells.duplicate(true)
    var ordinal=_sequence
    for position in active_cells():
        ordinal+=1
        result.append({"cell_id":_namespace+":"+str(ordinal),"x":int(position[0]),
            "y":int(position[1]),"kind":_engine.active_resource})
    return result

func hard_drop_plan()->Dictionary:
    _engine.hard_drop_plan()
    return lock_plan()

func lock_plan()->Dictionary:
    var plan:Dictionary=_engine.lock_plan()
    if plan.get("topout",false): return plan
    plan.id=_namespace+":"+plan.id
    plan.cells=[]
    for cell in _placed_cells():
        if cell.y in plan.rows:
            plan.cells.append({"id":cell.cell_id,"kind":cell.kind})
    return plan

func commit_lock()->void:
    if spawn_blocked(): return
    var plan:Dictionary=_engine.lock_plan()
    var placed=_placed_cells()
    _sequence+=4
    _cells=[]
    for cell in placed:
        if cell.y in plan.rows: continue
        var distance=0
        for row in plan.rows:
            if int(row)>cell.y: distance+=1
        cell.y+=distance
        _cells.append(cell)
    _engine.commit_lock()

func destroy_cells(event_id:String,ids:Array)->Dictionary:
    if event_id.is_empty() or event_id in _destructions:
        return {"success":false,"reason":"DUPLICATE_OR_EMPTY_EVENT"}
    var unique:Dictionary={}
    for id in ids:
        if not id is String or id.is_empty() or unique.has(id):
            return {"success":false,"reason":"INVALID_TARGET_IDS"}
        unique[id]=true
    var removed:Array=[]
    var kept:Array=[]
    for cell in _cells:
        if unique.has(cell.cell_id):
            _engine.board.set_cell(Vector2i(cell.x,cell.y),"")
            removed.append(cell.cell_id)
        else: kept.append(cell)
    _cells=kept
    if not grounded(): _engine.grounded_us=0
    _destructions.append(event_id)
    return {"success":true,"origin":"ENEMY_DESTROY","removed":removed,"rewards":[]}

func reset_after_topout()->void:
    _engine.reset_after_topout()
    _cells.clear()

func snapshot()->Dictionary:
    return {"schema":"r3-line-v1","namespace":_namespace,"sequence":_sequence,
        "engine":_engine.snapshot(),"cells":_cells.duplicate(true),"destructions":_destructions.duplicate()}

func restore(data:Dictionary)->bool:
    if data.size()!=6 or data.get("schema")!="r3-line-v1": return false
    if not data.get("namespace") is String or data.namespace!=_namespace: return false
    if not Validation.valid_integer(data.get("sequence"),0,2147483647): return false
    if not data.get("engine") is Dictionary or not data.get("cells") is Array or not data.get("destructions") is Array: return false
    var candidate=LineEngine.new()
    if not candidate.restore(data.engine): return false
    if int(data.sequence)!=4*candidate.lock_sequence: return false
    var seen:Dictionary={}
    var positions:Dictionary={}
    var normalized:Array=[]
    for cell in data.cells:
        if not cell is Dictionary or cell.size()!=4: return false
        if not cell.get("cell_id") is String or not cell.cell_id.begins_with(_namespace+":"): return false
        var suffix:String=cell.cell_id.substr(_namespace.length()+1)
        if not suffix.is_valid_int() or str(int(suffix))!=suffix or int(suffix)<1 or int(suffix)>int(data.sequence): return false
        if seen.has(cell.cell_id) or not Validation.valid_integer(cell.get("x"),0,9) or not Validation.valid_integer(cell.get("y"),0,23): return false
        if cell.get("kind") not in LineEngine.KINDS: return false
        var position=Vector2i(int(cell.x),int(cell.y))
        if positions.has(position) or candidate.board.get_cell(position)!=cell.kind: return false
        seen[cell.cell_id]=true
        positions[position]=true
        normalized.append({"cell_id":cell.cell_id,"x":int(cell.x),"y":int(cell.y),"kind":cell.kind})
    for y in 24:
        for x in 10:
            if not candidate.board.get_cell(Vector2i(x,y)).is_empty() and not positions.has(Vector2i(x,y)): return false
    var events:Dictionary={}
    for event in data.destructions:
        if not event is String or event.is_empty() or events.has(event): return false
        events[event]=true
    _engine=candidate
    _sequence=int(data.sequence)
    _cells=normalized
    _destructions=data.destructions.duplicate()
    return true
