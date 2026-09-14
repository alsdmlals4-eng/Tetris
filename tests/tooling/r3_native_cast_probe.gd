## Explicit in-memory art/consumer fixture. Never saves or proves organic play.
extends RefCounted

static func run(screen,category:String="DEF")->Dictionary:
    if category not in ["ATK","DEF","SUP"]:return {"success":false}
    screen.set_process(false)
    screen.session=load("res://src/replanned_r3/r3_session.gd").new("STANDARD",42,"r3:native-cast")
    screen.presentation=load("res://src/replanned_r3/r3_cast_presentation.gd").new()
    screen._ledger_count=0
    screen.dispatch("category",{"category":category})
    screen.dispatch("switch")
    screen.session.chain.cells=[
        {"cell_id":"fixture:1","x":0,"y":10,"kind":"A"},
        {"cell_id":"fixture:2","x":1,"y":10,"kind":"A"},
        {"cell_id":"fixture:3","x":0,"y":11,"kind":"A"},
        {"cell_id":"fixture:4","x":1,"y":11,"kind":"A"}]
    screen.session.chain._next_cell_id=4
    for i in 3:screen.dispatch("move",{"dx":1})
    screen.dispatch("hard_drop")
    screen.session.tick(300000)
    screen.refresh()
    screen.presentation.tick(160000)
    screen.dispatch("pause")
    screen.get_window().mode=Window.MODE_WINDOWED
    screen.get_window().grab_focus()
    RenderingServer.force_draw(false)
    return {"fixture":true,"cast":screen.session.last_cast,"visual":screen.presentation.view(),
        "art_errors":screen.performer.errors,"eta_us":screen.session.combat.eta_us,
        "actor_region":str(screen.get_node("Combat/CutIn/Actor").texture.region)}
