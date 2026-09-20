## Authored input puzzles; no automatic success and no persistent battle state.
extends RefCounted
static func setup(line,kind:String)->void:
    line._engine.board.clear_all()
    line._cells=[]
    var coordinates=[]
    if kind=="FOUR":
        for y in range(20,24):
            for x in 10:
                if x!=5:coordinates.append(Vector2i(x,y))
    elif kind=="SPIN":
        coordinates.append_array([Vector2i(3,21),Vector2i(5,21)])
        for x in 10:
            if x not in [3,4,5]:coordinates.append(Vector2i(x,22))
            if x!=4:coordinates.append(Vector2i(x,23))
    else:
        for y in [22,23]:
            for x in 10:
                if x not in [3,4,5,6]:coordinates.append(Vector2i(x,y))
    for xy in coordinates:
        line._sequence+=1
        line._engine.board.set_cell(xy,"A")
        line._cells.append({"cell_id":line._namespace+":"+str(line._sequence),"x":xy.x,"y":xy.y,"kind":"A"})
    line._engine._spawn_pair({"shape":"T" if kind=="SPIN" else "I","resource":"A"})
    line._engine.active.rotation=0 if kind=="COMBO" else 1
    line._engine.active.origin=Vector2i(3,21 if kind=="SPIN" else 4)
    if kind=="COMBO":line._engine.next_queue[0]={"shape":"I","resource":"A"}
