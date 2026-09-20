## Read-only cosmetic consumer; never owns combat effects or save state.
extends RefCounted

const FULL_US=620000
const COMPACT_US=240000
var _ledger:Array=[]
var _current:Dictionary={}
var _pending:Dictionary={}
var _pending_count=0
var _coalesced_count=1
var _elapsed_us=0
var _compact=false

func sync(ledger:Array,restoring:bool=false)->bool:
    var ids={}
    for record in ledger:
        if not record is Dictionary:return false
        if record.get("success")!=true:return false
        if not record.get("event_id") is String or record.event_id.is_empty():return false
        if record.get("category") not in ["ATK","DEF","SUP"]:return false
        if ids.has(record.event_id):return false
        ids[record.event_id]=true
    if not restoring:
        if ledger.size()<_ledger.size():return false
        for i in _ledger.size():
            if ledger[i]!=_ledger[i]:return false
    if restoring:
        cancel()
        _ledger=ledger.duplicate(true)
        return true
    for i in range(_ledger.size(),ledger.size()):
        if _current.is_empty():
            _current=ledger[i].duplicate(true)
            _elapsed_us=0
            _compact=false
            _coalesced_count=1
        else:
            _pending=ledger[i].duplicate(true)
            _pending_count+=1
    _ledger=ledger.duplicate(true)
    return true

func tick(delta_us:int,paused:bool=false)->void:
    if paused or delta_us<=0:return
    var remaining=delta_us
    while not _current.is_empty() and remaining>0:
        var duration=COMPACT_US if _compact else FULL_US
        var step=mini(remaining,duration-_elapsed_us)
        _elapsed_us+=step
        remaining-=step
        if _elapsed_us>=duration:
            _current=_pending
            _coalesced_count=_pending_count
            _pending={}
            _pending_count=0
            _elapsed_us=0
            _compact=true

func cancel()->void:
    _current={}
    _pending={}
    _pending_count=0
    _coalesced_count=1
    _elapsed_us=0
    _compact=false

func view(reduced_motion:bool=false)->Dictionary:
    if _current.is_empty():return {}
    var result=_current.duplicate(true)
    var phase="compact" if _compact else ("entrance" if _elapsed_us<120000 else ("impact" if _elapsed_us<380000 else "exit"))
    var alpha=1.0
    var offset=0.0
    if not reduced_motion and not _compact:
        if phase=="entrance":
            var t=float(_elapsed_us)/120000.0
            offset=-100.0*pow(1.0-t,3.0)
            alpha=t
        elif phase=="exit":
            var t=float(_elapsed_us-380000)/240000.0
            offset=60.0*t*t
            alpha=1.0-t
    result.merge({"phase":phase,"alpha":alpha,"offset_x":offset,"reduced_motion":reduced_motion,
        "pending_count":_pending_count,"coalesced_count":_coalesced_count,"elapsed_us":_elapsed_us},true)
    return result
