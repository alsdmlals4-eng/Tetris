## Native actual-entry captures; scripted fixtures, not human fun or listening approval.
extends SceneTree
var screen
var output="res://docs/validation/puzzle-feedback-20260921"
var shots=[]
func _initialize():call_deferred("run")
func capture(label:String):
    screen.refresh()
    await process_frame
    await RenderingServer.frame_post_draw
    var image=root.get_texture().get_image()
    assert(image.save_png(output+"/"+label+".png")==OK)
    shots.append({"name":label,"size":[image.get_width(),image.get_height()]})
func run():
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    screen=load("res://scenes/replanned_r3/resource_choice.tscn").instantiate()
    screen.preference_path="user://feedback-native-probe/preference.cfg"
    root.add_child(screen)
    current_scene=screen
    root.content_scale_size=Vector2i(1280,720)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    screen.set_process(false)
    for size in [Vector2i(1280,720),Vector2i(960,540)]:
        root.size=size
        var suffix="-"+str(size.x)
        for kind in ["FOUR","SPIN","COMBO"]:
            screen.start_line_practice(kind)
            if kind=="SPIN":screen.dispatch("rotate",{"direction":1})
            screen.dispatch("hard_drop")
            if kind=="COMBO":screen.dispatch("hard_drop")
            screen.get_node("Puzzle/Feedback").advance(0.08)
            await capture(kind.to_lower()+suffix)
            screen.end_chain_practice()
        screen.start_chain_practice()
        screen.dispatch("hard_drop")
        screen._process(0.31)
        await capture("chain1"+suffix)
        screen._process(0.31)
        await capture("chain2"+suffix)
        screen._process(0.49)
        await capture("skill-impact"+suffix)
        screen._process(1.5)
        await capture("skill-recent"+suffix)
        screen.end_chain_practice()
        screen.start_resource_battle("SWAP")
        screen.session.swap.setup_training()
        var swap=screen.session.swap._teaching.swap
        screen.dispatch("resource_swap",{"a":Vector2i(swap[0][0],swap[0][1]),"b":Vector2i(swap[1][0],swap[1][1])})
        screen._process(0.31)
        await capture("swap"+suffix)
        screen.reduced_motion=true
        screen.get_node("Puzzle/Feedback").advance(0.0)
        await capture("reduced"+suffix)
        screen.reduced_motion=false
        screen.preparing=true
    var receipt={"renderer":RenderingServer.get_video_adapter_name(),"scene":"resource_choice.tscn","screenshots":shots,"human_fun":"NOT_RUN","listening_mix":"NOT_RUN","input":"scripted real dispatch and process; not physical keyboard"}
    var file=FileAccess.open(output+"/runtime.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(receipt,"  "))
    file.close()
    screen.queue_free()
    await process_frame
    quit()
