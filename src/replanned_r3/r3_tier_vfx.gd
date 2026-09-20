## Runtime vector accents around existing approved character/tile textures.
## Presentation only: no combat mutation and no separate timer.
extends Control
var state:Dictionary={}
var reduced:=false
const COLORS={"A":Color("#ff8a57"),"D":Color("#6acbff"),"H":Color("#7ff5a5"),"T":Color("#f2d578")}
func present(view:Dictionary,reduce_motion:bool)->void:
    state=view
    reduced=reduce_motion
    visible=not state.is_empty()
    queue_redraw()
func _draw()->void:
    if state.is_empty():return
    var tier=int(state.get("rings",1))
    var tint:Color=COLORS.get(state.get("starter",""),Color("#c593ff"))
    var center=Vector2(335,117)
    var progress=0.65 if reduced else float(state.get("progress",0))
    var burst=1.0 if reduced else sin(clampf(progress*1.7,0,1)*PI)
    for ring in tier:
        var radius=36.0+ring*8.0+burst*15.0
        draw_arc(center,radius,0,TAU,48,Color(tint,0.30+0.055*tier),1.0+ring*0.35,true)
    for ray in tier*4:
        var angle=TAU*float(ray)/float(tier*4)+(0.0 if reduced else progress*0.7)
        var unit=Vector2(cos(angle),sin(angle))
        draw_line(center+unit*(48+5*tier),center+unit*(60+6*tier+burst*8),Color(tint,0.6),1.0+tier*0.35,true)
    if tier>=3:
        draw_line(Vector2(25,218),Vector2(390,218),Color(tint,0.8),tier-1,true)
    if tier>=5:
        var diamond=PackedVector2Array([center+Vector2(0,-94),center+Vector2(94,0),center+Vector2(0,94),center+Vector2(-94,0),center+Vector2(0,-94)])
        draw_polyline(diamond,Color(tint,0.7),2.5,true)
