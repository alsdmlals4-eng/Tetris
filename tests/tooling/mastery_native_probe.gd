## Exact scene native rendering and recorded scripted observations, not human balance evidence.
extends SceneTree
var screen
var output="res://docs/validation/mastery-patterns-20260921"
var shots=[]
func _initialize():call_deferred("run")
func capture(label:String):
    screen.refresh()
    await process_frame
    await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK)
    shots.append(label)
func run():
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    screen=load("res://scenes/replanned_r3/resource_choice.tscn").instantiate()
    screen.preference_path="user://mastery-native-probe/preference.cfg"
    screen.disk=load("res://src/replanned_r3/r3_save.gd").new("user://mastery-native-probe/save.json","user://mastery-native-probe/options.json")
    root.add_child(screen)
    current_scene=screen
    root.content_scale_size=Vector2i(1280,720)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.size=Vector2i(1280,720)
    screen.set_process(false)
    await capture("preparation")
    var practice=[]
    for kind in ["FOUR","SPIN","COMBO"]:
        screen.start_line_practice(kind)
        await capture("practice-"+kind.to_lower())
        if kind=="SPIN":screen.dispatch("rotate",{"direction":1})
        screen.dispatch("hard_drop")
        if kind=="COMBO":screen.dispatch("hard_drop")
        assert(screen.session.practice_complete())
        practice.append(screen.session.supply_report())
        await capture("result-"+kind.to_lower())
        screen.end_chain_practice()
    for profile in ["outer_breach","foundry","watchtower","rift_core"]:
        screen.preferred_encounter=profile
        screen.start_resource_battle("SWAP")
        var s=screen.session
        if profile!="foundry":s.tick(s.combat.eta_us+1600001)
        await capture("pattern-"+profile)
        if profile in ["foundry","outer_breach"]:
            s.tick(s.combat.eta_us+1600001)
            await capture("status-"+profile)
        screen.dispatch("pause")
        assert(screen.save_checkpoint().success)
        assert(screen.restore_checkpoint().success)
        screen.preparing=true
    root.size=Vector2i(960,540)
    screen.preparing=true
    await capture("preparation-960")
    screen.start_line_practice("SPIN")
    await capture("practice-spin-960")
    screen.end_chain_practice()
    screen.preferred_encounter="rift_core"
    screen.start_resource_battle("SWAP")
    screen.session.tick(screen.session.combat.eta_us+1600001)
    await capture("charge-960")
    var receipt={"renderer":RenderingServer.get_video_adapter_name(),"viewports":[[1280,720],[960,540]],"scene":"resource_choice.tscn","screenshots":shots,"practice":practice,"enemy_pattern_disk_roundtrips":4,"human_fun":"NOT_RUN","save_namespace":"user://mastery-native-probe"}
    var file=FileAccess.open(output+"/runtime.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(receipt,"  "))
    file.close()
    screen.queue_free()
    await process_frame
    quit()
