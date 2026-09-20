## Reuse R2's orthogonal match/refill engine, never its cast consumer.
## Persistent IDs follow surviving cells; regeneration invalidates old targets.
extends "res://src/replanned_r2/r2_chain.gd"
var ids:Array=[]
var sequence:=0
var identity_prefix:String
var destructions:Array=[]
var _generation:=0

func _init(seed_value:int=9112026,identity:String="resource-swap"):
    identity_prefix=identity
    super(seed_value)

func _new_id()->String:
    sequence+=1
    return identity_prefix+":"+str(sequence)

func _reset_ids()->void:
    ids=[]
    for y in 8:
        var row=[]
        for x in 8:row.append(_new_id())
        ids.append(row)
    _generation+=1

func generate_stable()->void:
    super.generate_stable()
    _reset_ids()

func setup_training()->void:
    super.setup_training()
    _reset_ids()

func _swap(a:Vector2i,b:Vector2i)->void:
    super._swap(a,b)
    if ids.size()==8:
        var first=ids[a.y][a.x]
        ids[a.y][a.x]=ids[b.y][b.x]
        ids[b.y][b.x]=first

func clear_plan()->Dictionary:
    if not resolving or next_wave_remaining_us!=0:return {}
    var payload=[]
    for xy in matched_cells():payload.append({"id":ids[xy[1]][xy[0]],"kind":cells[xy[1]][xy[0]]})
    return {"id":identity_prefix+":clear:"+str(chain_id)+":"+str(wave_index+1),"cells":payload}

func commit_wave()->Dictionary:
    if due_cast().is_empty():return {}
    var feedback_id=identity_prefix+":clear:"+str(chain_id)+":"+str(wave_index+1)
    var removed={}
    for xy in matched_cells():removed[Vector2i(xy[0],xy[1])]=true
    var survivors=[]
    for x in 8:
        var column=[]
        for y in 8:
            if not removed.has(Vector2i(x,y)):column.append(ids[y][x])
        survivors.append(column)
    var generation=_generation
    var result=super.commit_wave()
    if generation==_generation:
        for x in 8:
            var missing=8-survivors[x].size()
            for y in missing:ids[y][x]=_new_id()
            for y in survivors[x].size():ids[y+missing][x]=survivors[x][y]
    result.effect="RESOURCE_SWAP_RESOLVED"
    result.event_id=feedback_id
    return result

func target_candidates()->Array:
    var protected={}
    if resolving:
        for xy in matched_cells():protected[Vector2i(xy[0],xy[1])]=true
    var result=[]
    for y in 8:
        for x in 8:
            if not protected.has(Vector2i(x,y)):result.append({"cell_id":ids[y][x],"x":x,"y":y,"kind":cells[y][x]})
    return result

func destroy_cells(event_id:String,targets:Array)->Dictionary:
    # Queue through the current atomic cascade; enemy timing/HP is not delayed.
    if resolving:return {}
    if event_id in destructions:return {"success":false,"reason":"DUPLICATE_DESTRUCTION"}
    var removed=[]
    for x in 8:
        var survivors=[]
        var surviving_ids=[]
        for y in 8:
            if ids[y][x] in targets:removed.append(ids[y][x])
            else:
                survivors.append(cells[y][x])
                surviving_ids.append(ids[y][x])
        var missing=8-survivors.size()
        for y in missing:
            _put(x,y,_next_kind())
            ids[y][x]=_new_id()
        for y in survivors.size():
            _put(x,y+missing,survivors[y])
            ids[y+missing][x]=surviving_ids[y]
    # Enemy-created matches settle without entering the player reward consumer.
    if not matched_cells().is_empty():
        chain_id+=1
        resolving=true
        category_snapshot="ATK"
        wave_index=0
        next_wave_remaining_us=0
        for safety in MAX_WAVES:
            commit_wave()
            if not resolving:break
            next_wave_remaining_us=0
    if not has_valid_move():generate_stable()
    destructions.append(event_id)
    return {"success":true,"removed":removed,"rewards":[]}

func export_state()->Dictionary:
    return {"schema":"resource-swap-v1","engine":super.snapshot(),"ids":ids.duplicate(true),"sequence":sequence,"namespace":identity_prefix,"destructions":destructions.duplicate()}

func load_state(data:Dictionary,terminal:bool=false)->bool:
    if data.size()!=6 or data.get("schema")!="resource-swap-v1" or data.get("namespace")!=identity_prefix:return false
    if not valid_integer(data.get("sequence"),64,2147483647) or not data.get("engine") is Dictionary or not data.get("ids") is Array or data.ids.size()!=8 or not data.get("destructions") is Array:return false
    if data.engine.get("seed")!=str(_seed):return false
    var seen={}
    for row in data.ids:
        if not row is Array or row.size()!=8:return false
        for id in row:
            if not id is String or not id.begins_with(identity_prefix+":") or seen.has(id):return false
            var ordinal=id.trim_prefix(identity_prefix+":")
            if not ordinal.is_valid_int() or str(int(ordinal))!=ordinal or int(ordinal)<1 or int(ordinal)>int(data.sequence):return false
            seen[id]=true
    seen={}
    for id in data.destructions:
        if not id is String or id.is_empty() or seen.has(id):return false
        seen[id]=true
    if not super.restore(data.engine,terminal):return false
    ids=data.ids.duplicate(true)
    sequence=int(data.sequence)
    destructions=data.destructions.duplicate()
    return true
