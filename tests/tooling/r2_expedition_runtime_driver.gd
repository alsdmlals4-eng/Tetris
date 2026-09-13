## Shared deterministic wiring driver for GUT and native scene inspection.
## No deliberation time: never treat its wins as human balance evidence.
extends RefCounted

func drive_one_battle(screen) -> Dictionary:
    if screen.page != "battle": return {"success":false,"reason":"NOT_IN_BATTLE"}
    if screen.session.mode != "CHAIN": screen.dispatch("switch")
    for step in 300:
        if screen.page != "battle": return {"success":true,"phase":screen.expedition.view().phase}
        if screen.session.chain.resolving:
            screen.advance_seconds(0.3)
            continue
        var probe = screen.Session.Chain.new()
        if not probe.restore(screen.session.chain.snapshot()): return {"success":false,"reason":"PROBE_RESTORE"}
        var move := {}
        for y in 8:
            for x in 8:
                for delta in [Vector2i.RIGHT,Vector2i.DOWN]:
                    var end: Vector2i = Vector2i(x,y)+delta
                    if end.x >= 8 or end.y >= 8: continue
                    if probe.try_swap(Vector2i(x,y),end,"ATK").success:
                        move = {"from":[x,y],"to":[end.x,end.y]}
                        break
                if not move.is_empty(): break
            if not move.is_empty(): break
        if move.is_empty(): return {"success":false,"reason":"NO_LEGAL_MOVE"}
        if not screen.dispatch("chain_swap",move).success: return {"success":false,"reason":"DISPATCH_FAILED"}
        screen.advance_seconds(0.3)
    return {"success":false,"reason":"DRIVER_BOUND_EXCEEDED"}
