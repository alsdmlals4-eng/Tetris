## Pure falling-pair model. Session owns supply, HP and all skill effects.
## Time is scheduler-driven: advance at most next_event_us(), commit, then continue.
## Occupied cells use visible y=0..11 and hidden y=-2,-1; empty cells are implicit.
extends RefCounted

const RULES_PATH="res://data/replanned_r3/rules.json"
const OFFSETS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const KICKS=[Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP]
const PHASES=["NEED_PAIR","FALLING","LOCKED_SETTLE","CLEAR_PENDING","FALL_SETTLE","DISRUPTION_SETTLE","TOP_OUT_PENDING","ERROR","TERMINAL"]

var cells: Array=[]
var active_pair: Dictionary={}
var phase: String="NEED_PAIR"
var gravity_remaining_us: int
var lock_remaining_us: int
var lock_reset_count:=0
var wave_remaining_us:=0
var wave_index:=0
var chain_id:=0
var category_snapshot: String=""
var selected_category: String="ATK"
var cause: String="PLAYER_LOCK"
var revision:=0
var processed_event_ids: Array=[]
var reserved_clear_ids: Array=[]
var error: String=""
var _rules: Dictionary
var _all_rules: Dictionary
var _rng:=RandomNumberGenerator.new()
var _seed: int
var _namespace: String
var _next_cell_id:=0
var _next_pairs: Array=[]
var _bag: Array=[]
var _spawn_ids: Array=[]
var _cleared: Array=[]
var _soft_drop:=false

func _init(seed_value: int=9112026, namespace_value: String="chain"):
    _all_rules=JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
    _rules=_all_rules.chain
    _seed=seed_value
    _namespace=namespace_value
    _rng.seed=seed_value
    gravity_remaining_us=int(_rules.gravity_us)
    lock_remaining_us=int(_rules.lock_us)
    _fill_queue()

func next_pair_kinds() -> Array:
    return _next_pairs[0].duplicate()

func spawn(pair_id: String, kinds: Array=[]) -> Dictionary:
    if phase!="NEED_PAIR" or not active_pair.is_empty(): return _failure("BOARD_BUSY")
    if pair_id.is_empty() or pair_id in _spawn_ids: return _failure("INVALID_OR_DUPLICATE_PAIR")
    if not kinds.is_empty() and kinds!=next_pair_kinds(): return _failure("NEXT_PAIR_MISMATCH")
    if not _free(Vector2i(2,-1)) or not _free(Vector2i(2,-2)):
        phase="TOP_OUT_PENDING"
        revision+=1
        return _failure("TOP_OUT")
    var pair: Array=_next_pairs.pop_front()
    active_pair={"id":pair_id,"axis":_new_cell(2,-1,pair[0]),"satellite":_new_cell(2,-2,pair[1]),"orientation":0}
    _fill_queue()
    _spawn_ids.append(pair_id)
    phase="FALLING"
    cause="PLAYER_LOCK"
    gravity_remaining_us=_gravity_period()
    lock_remaining_us=int(_rules.lock_us)
    lock_reset_count=0
    revision+=1
    return {"success":true,"reason":"","pair_id":pair_id}

func command(action: String, args: Dictionary={}) -> Dictionary:
    if phase=="TERMINAL": return _failure("BOARD_TERMINAL")
    # Key release remains valid while a just-locked pair is resolving. Otherwise
    # one release between pairs can leave soft drop latched on the next spawn.
    if action=="soft_drop" and args.get("enabled") is bool and not args.enabled and phase!="ERROR":
        if _soft_drop:
            _soft_drop=false
            revision+=1
        return _success()
    if phase!="FALLING": return _failure("BOARD_NOT_FALLING")
    if action=="category":
        if args.get("category") not in ["ATK","DEF","SUP"]: return _failure("INVALID_CATEGORY")
        selected_category=args.category
        revision+=1
        return _success()
    if action=="soft_drop":
        if not args.get("enabled",true) is bool: return _failure("INVALID_SOFT_DROP")
        _soft_drop=args.get("enabled",true)
        gravity_remaining_us=mini(gravity_remaining_us,_gravity_period())
        revision+=1
        return _success()
    if action=="hard_drop":
        if args.get("category",selected_category) not in ["ATK","DEF","SUP"]: return _failure("INVALID_CATEGORY")
        selected_category=args.get("category",selected_category)
        while _can_translate(Vector2i.DOWN): _translate(Vector2i.DOWN)
        category_snapshot=selected_category
        phase="LOCKED_SETTLE"
        revision+=1
        return _success()
    var grounded:=_grounded()
    if action=="move":
        if args.get("dx") not in [-1,1]: return _failure("INVALID_DIRECTION")
        var offset=Vector2i(int(args.dx),0)
        if not _can_translate(offset): return _failure("COLLISION")
        _translate(offset)
    elif action=="rotate":
        if args.get("direction",1) not in [-1,1]: return _failure("INVALID_DIRECTION")
        var orientation=(int(active_pair.orientation)+int(args.get("direction",1))+4)%4
        var rotated:=false
        for kick in KICKS:
            var axis=Vector2i(active_pair.axis.x,active_pair.axis.y)+kick
            var satellite=axis+OFFSETS[orientation]
            if not _free(axis) or not _free(satellite): continue
            _position(active_pair.axis,axis)
            _position(active_pair.satellite,satellite)
            active_pair.orientation=orientation
            rotated=true
            break
        if not rotated: return _failure("COLLISION")
    else: return _failure("UNSUPPORTED_R3_COMMAND")
    if grounded and lock_reset_count<int(_rules.lock_resets):
        lock_reset_count+=1
        lock_remaining_us=int(_rules.lock_us)
    revision+=1
    return _success()

func next_event_us() -> int:
    match phase:
        "FALLING": return lock_remaining_us if _grounded() else gravity_remaining_us
        "CLEAR_PENDING","FALL_SETTLE","DISRUPTION_SETTLE": return wave_remaining_us
        "LOCKED_SETTLE","TOP_OUT_PENDING": return 0
    return -1

func advance_time(delta_us: int) -> void:
    if delta_us<=0: return
    var due:=next_event_us()
    if due<0: return
    var amount:=mini(delta_us,due)
    if phase=="FALLING":
        if _grounded(): lock_remaining_us-=amount
        else: gravity_remaining_us-=amount
    else: wave_remaining_us-=amount
    # Revision identifies logical mutations, not caller tick partitioning.

func plan_due_event() -> Dictionary:
    if next_event_us()!=0: return {}
    var type: String=""
    var event_cells: Array=[]
    match phase:
        "FALLING":
            type="LOCK_PAIR" if _grounded() else "GRAVITY"
            event_cells=[active_pair.axis,active_pair.satellite]
        "LOCKED_SETTLE":
            type="SCAN" if active_pair.is_empty() or cause=="ENEMY_SETTLE" else "LOCK_PAIR"
            if type=="LOCK_PAIR": event_cells=[active_pair.axis,active_pair.satellite]
        "CLEAR_PENDING":
            type="CLEAR_CELLS"
            for c in cells:
                if c.cell_id in reserved_clear_ids: event_cells.append(c)
        "FALL_SETTLE":
            type="WAVE_RESOLVED"
            event_cells=_cleared
        "DISRUPTION_SETTLE": type="SCAN"
        "TOP_OUT_PENDING": type="TOP_OUT"
    if type.is_empty(): return {}
    var category=selected_category if type=="LOCK_PAIR" and phase=="FALLING" else category_snapshot
    return _plan(type,event_cells,category)

func commit(plan: Dictionary) -> Dictionary:
    if plan.get("type")=="ENEMY_DESTROY": return _commit_disruption(plan)
    var expected:=plan_due_event()
    if expected.is_empty() or plan!=expected or plan.event_id in processed_event_ids: return _failure("INVALID_OR_STALE_PLAN")
    var type: String=plan.type
    var result=plan.duplicate(true)
    result.success=true
    result.reason=""
    result.reward_eligible=type=="WAVE_RESOLVED" and cause=="PLAYER_LOCK"
    match type:
        "GRAVITY":
            _translate(Vector2i.DOWN)
            gravity_remaining_us=_gravity_period()
        "LOCK_PAIR":
            cells.append(active_pair.axis.duplicate(true))
            cells.append(active_pair.satellite.duplicate(true))
            active_pair={}
            chain_id+=1
            wave_index=0
            category_snapshot=plan.category
            cause="PLAYER_LOCK"
            _compact()
            _scan()
        "SCAN":
            _compact()
            _scan()
        "CLEAR_CELLS":
            if plan.cells.size()<int(_rules.group_min): return _failure("CLEAR_TOO_SMALL")
            _cleared=plan.cells.duplicate(true)
            cells=cells.filter(func(c): return c.cell_id not in reserved_clear_ids)
            reserved_clear_ids=[]
            wave_index+=1
            phase="FALL_SETTLE"
            wave_remaining_us=int(_rules.settle_us)
        "WAVE_RESOLVED":
            _compact()
            _cleared=[]
            # Session may apply committed enemy destruction here, before SCAN.
            phase="LOCKED_SETTLE"
            wave_remaining_us=0
        "TOP_OUT":
            cells=[]
            active_pair={}
            reserved_clear_ids=[]
            _cleared=[]
            _finish()
    processed_event_ids.append(plan.event_id)
    revision+=1
    return result

## Eligible fixed cells only. Reserved player/enemy clear cells are protected.
func target_candidates() -> Array:
    return cells.filter(func(c): return c.cell_id not in reserved_clear_ids).duplicate(true)

## During a wave Session queues this until WAVE_RESOLVED, then commits before SCAN.
func plan_disruption(event_id: String, target_ids: Array) -> Dictionary:
    if phase in ["CLEAR_PENDING","FALL_SETTLE","DISRUPTION_SETTLE","TOP_OUT_PENDING","ERROR","TERMINAL"]: return {}
    if phase=="LOCKED_SETTLE" and not active_pair.is_empty() and cause!="ENEMY_SETTLE": return {}
    if event_id.is_empty() or event_id in processed_event_ids: return {}
    var seen={}
    for id in target_ids:
        if not id is String or id.is_empty() or seen.has(id): return {}
        seen[id]=true
    var removed=[]
    for c in target_candidates():
        if c.cell_id in target_ids: removed.append(c)
    var plan=_plan("ENEMY_DESTROY",removed,"")
    plan.event_id=event_id
    plan.cause="ENEMY_DESTROY"
    plan.target_ids=target_ids.duplicate()
    return plan

func _commit_disruption(plan: Dictionary) -> Dictionary:
    if not plan.get("target_ids") is Array: return _failure("INVALID_DISRUPTION")
    var expected:=plan_disruption(str(plan.get("event_id","")),plan.target_ids)
    if expected.is_empty() or plan!=expected: return _failure("INVALID_OR_STALE_PLAN")
    var remove_ids=[]
    for c in plan.cells: remove_ids.append(c.cell_id)
    cells=cells.filter(func(c): return c.cell_id not in remove_ids)
    processed_event_ids.append(plan.event_id)
    cause="ENEMY_SETTLE"
    category_snapshot=""
    wave_index=0
    chain_id+=1
    reserved_clear_ids=[]
    _cleared=[]
    _compact()
    phase="DISRUPTION_SETTLE"
    wave_remaining_us=0
    revision+=1
    var result=plan.duplicate(true)
    result.success=true
    result.reason=""
    result.reward_eligible=false
    return result

func matched_cells() -> Array:
    return _matched_cells_in(cells)

func _matched_cells_in(source: Array) -> Array:
    var lookup={}
    for c in source: lookup[Vector2i(c.x,c.y)]=c
    var visited={}
    var found={}
    for c in source:
        var start=Vector2i(c.x,c.y)
        if visited.has(start): continue
        var queue=[start]
        var group=[]
        visited[start]=true
        while not queue.is_empty():
            var pos=queue.pop_front()
            group.append(lookup[pos])
            for offset in OFFSETS:
                var adjacent=pos+offset
                if visited.has(adjacent) or not lookup.has(adjacent): continue
                if lookup[adjacent].kind!=c.kind: continue
                visited[adjacent]=true
                queue.append(adjacent)
        if group.size()>=int(_rules.group_min):
            for member in group: found[member.cell_id]=true
    return source.filter(func(c): return found.has(c.cell_id)).duplicate(true)

func is_resolving() -> bool:
    return phase in ["LOCKED_SETTLE","CLEAR_PENDING","FALL_SETTLE","DISRUPTION_SETTLE","TOP_OUT_PENDING"]

## Session calls immediately on defeat, or after committed enemy cleanup on victory.
## Do not clear or compact the physical board: preserve the exact final frame.
## This cancels future effects, emits no gameplay event, and is safe to repeat.
func finalize_terminal() -> Dictionary:
    if phase!="TERMINAL":
        phase="TERMINAL"
        reserved_clear_ids=[]
        _cleared=[]
        wave_index=0
        wave_remaining_us=0
        category_snapshot=""
        cause="PLAYER_LOCK"
        _soft_drop=false
        revision+=1
    return {"success":true,"reason":"","reward_eligible":false}

func rows() -> Array:
    var result=[]
    for y in int(_rules.visible_height)+int(_rules.hidden_height): result.append(".".repeat(int(_rules.width)))
    for c in cells:
        var row: String=result[int(c.y)+int(_rules.hidden_height)]
        result[int(c.y)+int(_rules.hidden_height)]=row.substr(0,c.x)+c.kind+row.substr(int(c.x)+1)
    return result

func ghost_cells() -> Array:
    if active_pair.is_empty(): return []
    var offset=Vector2i.ZERO
    while _can_translate(offset+Vector2i.DOWN): offset+=Vector2i.DOWN
    var result=[active_pair.axis.duplicate(true),active_pair.satellite.duplicate(true)]
    for c in result: c.y+=offset.y
    return result

func _scan() -> void:
    var matches:=matched_cells()
    if not matches.is_empty():
        if wave_index>=int(_rules.max_waves):
            phase="ERROR"
            error="MAX_WAVES_EXCEEDED"
            return
        reserved_clear_ids=[]
        for c in matches: reserved_clear_ids.append(c.cell_id)
        phase="CLEAR_PENDING"
        wave_remaining_us=int(_rules.clear_us)
        return
    for c in cells:
        if c.y<0:
            phase="TOP_OUT_PENDING"
            return
    _finish()

func _finish() -> void:
    phase="NEED_PAIR" if active_pair.is_empty() else "FALLING"
    wave_index=0
    category_snapshot=""
    wave_remaining_us=0
    cause="PLAYER_LOCK"

func _compact() -> void:
    for x in int(_rules.width):
        var column=cells.filter(func(c): return int(c.x)==x)
        column.sort_custom(func(a,b): return int(a.y)>int(b.y))
        var y=int(_rules.visible_height)-1
        for c in column:
            c.y=y
            y-=1

func _plan(type: String, event_cells: Array, category: String) -> Dictionary:
    return {"event_id":"%s:event:%d:%s"%[_namespace,revision,type],"revision":revision,"type":type,
        "cause":cause,"phase":phase,"cells":event_cells.duplicate(true),"wave":wave_index if type=="WAVE_RESOLVED" else wave_index+1,
        "chain_id":chain_id,"category":category}

func _free(pos: Vector2i) -> bool:
    if pos.x<0 or pos.x>=int(_rules.width) or pos.y<-int(_rules.hidden_height) or pos.y>=int(_rules.visible_height): return false
    for c in cells:
        if int(c.x)==pos.x and int(c.y)==pos.y: return false
    return true

func _can_translate(offset: Vector2i) -> bool:
    for c in [active_pair.axis,active_pair.satellite]:
        if not _free(Vector2i(c.x,c.y)+offset): return false
    return true

func _grounded() -> bool:
    return not active_pair.is_empty() and not _can_translate(Vector2i.DOWN)

func _translate(offset: Vector2i) -> void:
    for c in [active_pair.axis,active_pair.satellite]:
        c.x+=offset.x
        c.y+=offset.y

func _position(cell: Dictionary, pos: Vector2i) -> void:
    cell.x=pos.x
    cell.y=pos.y

func _new_cell(x: int,y: int,kind: String) -> Dictionary:
    _next_cell_id+=1
    return {"cell_id":"%s:cell:%d"%[_namespace,_next_cell_id],"x":x,"y":y,"kind":kind}

func _gravity_period() -> int:
    return int(_rules.soft_drop_us) if _soft_drop else int(_rules.gravity_us)

func _fill_queue() -> void:
    while _next_pairs.size()<int(_rules.next_pairs): _next_pairs.append([_next_kind(),_next_kind()])

func _next_kind() -> String:
    if _bag.is_empty():
        for kind in _all_rules.kinds:
            for copy in int(_all_rules.bag_copies_per_kind): _bag.append(kind)
        for i in range(_bag.size()-1,0,-1):
            var j=_rng.randi_range(0,i)
            var value=_bag[i]
            _bag[i]=_bag[j]
            _bag[j]=value
    return _bag.pop_front()

func snapshot() -> Dictionary:
    return {"schema":"r3-pair-board-v1","rules_hash":FileAccess.get_sha256(RULES_PATH),"rng_version":1,
        "namespace":_namespace,"seed":str(_seed),"rng_state":str(_rng.state),"next_cell_id":_next_cell_id,
        "cells":cells.duplicate(true),"active_pair":active_pair.duplicate(true),"phase":phase,
        "gravity_remaining_us":gravity_remaining_us,"lock_remaining_us":lock_remaining_us,"lock_reset_count":lock_reset_count,
        "wave_remaining_us":wave_remaining_us,"wave_index":wave_index,"chain_id":chain_id,"category_snapshot":category_snapshot,
        "selected_category":selected_category,"cause":cause,"revision":revision,"processed_event_ids":processed_event_ids.duplicate(),
        "reserved_clear_ids":reserved_clear_ids.duplicate(),"cleared":_cleared.duplicate(true),"next_pairs":_next_pairs.duplicate(true),
        "bag":_bag.duplicate(),"spawn_ids":_spawn_ids.duplicate(),"soft_drop":_soft_drop,"error":error}

func restore(value: Dictionary) -> bool:
    if not _valid_snapshot(value): return false
    _namespace=value.namespace
    _seed=int(value.seed)
    _rng.seed=_seed
    _rng.state=int(value.rng_state)
    _next_cell_id=int(value.next_cell_id)
    cells=value.cells.duplicate(true)
    active_pair=value.active_pair.duplicate(true)
    for c in cells:
        c.x=int(c.x)
        c.y=int(c.y)
    if not active_pair.is_empty():
        active_pair.orientation=int(active_pair.orientation)
        for c in [active_pair.axis,active_pair.satellite]:
            c.x=int(c.x)
            c.y=int(c.y)
    phase=value.phase
    gravity_remaining_us=int(value.gravity_remaining_us)
    lock_remaining_us=int(value.lock_remaining_us)
    lock_reset_count=int(value.lock_reset_count)
    wave_remaining_us=int(value.wave_remaining_us)
    wave_index=int(value.wave_index)
    chain_id=int(value.chain_id)
    category_snapshot=value.category_snapshot
    selected_category=value.selected_category
    cause=value.cause
    revision=int(value.revision)
    processed_event_ids=value.processed_event_ids.duplicate()
    reserved_clear_ids=value.reserved_clear_ids.duplicate()
    _cleared=value.cleared.duplicate(true)
    for c in _cleared:
        c.x=int(c.x)
        c.y=int(c.y)
    _next_pairs=value.next_pairs.duplicate(true)
    _bag=value.bag.duplicate()
    _spawn_ids=value.spawn_ids.duplicate()
    _soft_drop=value.soft_drop
    error=value.error
    return true

func _valid_snapshot(v: Dictionary) -> bool:
    var expected=snapshot()
    if v.size()!=expected.size(): return false
    for key in expected:
        if not v.has(key): return false
    if v.schema!=expected.schema or v.rules_hash!=expected.rules_hash or v.rng_version!=1: return false
    if not v.namespace is String or v.namespace.is_empty(): return false
    for key in ["seed","rng_state"]:
        if not v[key] is String or not v[key].is_valid_int() or str(int(v[key]))!=v[key]: return false
    for key in ["next_cell_id","chain_id","revision"]:
        if not _integer(v[key],0,2147483647): return false
    for pair in [["gravity_remaining_us",int(_rules.gravity_us)],["lock_remaining_us",int(_rules.lock_us)],
        ["lock_reset_count",int(_rules.lock_resets)],["wave_remaining_us",int(_rules.clear_us)], ["wave_index",int(_rules.max_waves)]]:
        if not _integer(v[pair[0]],0,pair[1]): return false
    if v.phase not in PHASES or v.cause not in ["PLAYER_LOCK","ENEMY_SETTLE"]: return false
    if v.selected_category not in ["ATK","DEF","SUP"] or v.category_snapshot not in ["","ATK","DEF","SUP"]: return false
    if not v.soft_drop is bool or not v.error is String: return false
    if not v.cells is Array or not v.cleared is Array or not v.active_pair is Dictionary: return false
    if v.cells.size()+v.cleared.size()>int(_rules.width)*(int(_rules.hidden_height)+int(_rules.visible_height)): return false
    var identities={}
    var positions={}
    for c in v.cells:
        if not _valid_cell(c,identities,positions): return false
    if not v.active_pair.is_empty():
        if v.active_pair.size()!=4 or not v.active_pair.get("id") is String or v.active_pair.id.is_empty(): return false
        if not _integer(v.active_pair.get("orientation"),0,3): return false
        for key in ["axis","satellite"]:
            if not _valid_cell(v.active_pair.get(key),identities,positions): return false
        var a=v.active_pair.axis
        var s=v.active_pair.satellite
        if Vector2i(s.x-a.x,s.y-a.y)!=OFFSETS[int(v.active_pair.orientation)]: return false
    if v.phase=="FALLING" and v.active_pair.is_empty(): return false
    if v.phase=="NEED_PAIR" and not v.active_pair.is_empty(): return false
    if v.phase=="FALL_SETTLE" and v.cleared.size()<int(_rules.group_min): return false
    if v.phase!="FALL_SETTLE" and not v.cleared.is_empty(): return false
    for c in v.cleared:
        if not _valid_cell(c,identities,{}): return false
    for key in ["spawn_ids","processed_event_ids","reserved_clear_ids"]:
        if not v[key] is Array: return false
        var seen={}
        for id in v[key]:
            if not id is String or id.is_empty() or seen.has(id): return false
            seen[id]=true
            if key=="reserved_clear_ids" and not identities.has(id): return false
    if not v.active_pair.is_empty() and v.active_pair.id not in v.spawn_ids: return false
    if int(v.next_cell_id)<v.spawn_ids.size()*2: return false
    var prefix: String=v.namespace+":cell:"
    for id in identities:
        if not id.begins_with(prefix): return false
        var tail: String=id.substr(prefix.length())
        if not tail.is_valid_int() or str(int(tail))!=tail or int(tail)<1 or int(tail)>int(v.next_cell_id): return false
    if v.phase=="CLEAR_PENDING" and v.reserved_clear_ids.size()<int(_rules.group_min): return false
    if v.phase!="CLEAR_PENDING" and not v.reserved_clear_ids.is_empty(): return false
    if v.phase=="CLEAR_PENDING":
        var matched_ids=[]
        for c in _matched_cells_in(v.cells): matched_ids.append(c.cell_id)
        if matched_ids!=v.reserved_clear_ids or int(v.wave_index)>=int(_rules.max_waves): return false
    if v.phase=="FALL_SETTLE" and (int(v.wave_index)<1 or int(v.wave_remaining_us)>int(_rules.settle_us)): return false
    if v.phase not in ["CLEAR_PENDING","FALL_SETTLE"] and int(v.wave_remaining_us)!=0: return false
    if v.phase in ["NEED_PAIR","FALLING","TERMINAL"]:
        if int(v.wave_index)!=0 or v.category_snapshot!="" or v.cause!="PLAYER_LOCK": return false
    if v.phase=="TERMINAL" and v.soft_drop: return false
    if v.phase in ["CLEAR_PENDING","FALL_SETTLE"]:
        if v.cause=="PLAYER_LOCK" and (v.category_snapshot=="" or not v.active_pair.is_empty()): return false
        if v.cause=="ENEMY_SETTLE" and v.category_snapshot!="": return false
    if not v.next_pairs is Array or v.next_pairs.size()!=int(_rules.next_pairs) or not v.bag is Array: return false
    for pair in v.next_pairs:
        if not pair is Array or pair.size()!=2: return false
        for kind in pair:
            if kind not in _all_rules.kinds: return false
    if v.bag.size()>_all_rules.kinds.size()*int(_all_rules.bag_copies_per_kind)-2 or v.bag.size()%2!=0: return false
    var counts={}
    for kind in v.bag:
        if kind not in _all_rules.kinds: return false
        counts[kind]=int(counts.get(kind,0))+1
        if counts[kind]>int(_all_rules.bag_copies_per_kind): return false
    return true

func _valid_cell(c,ids: Dictionary,positions: Dictionary) -> bool:
    if not c is Dictionary or c.size()!=4: return false
    if not c.get("cell_id") is String or c.cell_id.is_empty() or ids.has(c.cell_id): return false
    if c.get("kind") not in _all_rules.kinds: return false
    if not _integer(c.get("x"),0,int(_rules.width)-1) or not _integer(c.get("y"),-int(_rules.hidden_height),int(_rules.visible_height)-1): return false
    var pos=Vector2i(c.x,c.y)
    if positions.has(pos): return false
    ids[c.cell_id]=true
    positions[pos]=true
    return true

static func _integer(value, minimum: int, maximum: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value==floor(float(value)) and value>=minimum and value<=maximum

static func _failure(reason: String) -> Dictionary:
    return {"success":false,"reason":reason}

static func _success() -> Dictionary:
    return {"success":true,"reason":""}
