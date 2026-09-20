## Native-rendered UI evidence; isolated storage, no normal save or preference writes.
extends SceneTree
const Screen=preload("res://src/replanned_r3/r3_screen.gd")
const Disk=preload("res://src/replanned_r3/r3_save.gd")
var screen
var output="res://docs/validation/resource-choice-20260920"

func _initialize():call_deferred("run")

func capture(label:String):
    screen.refresh()
    await process_frame
    await RenderingServer.frame_post_draw
    var result=root.get_texture().get_image().save_png(output+"/"+label+".png")
    assert(result==OK)

func run():
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    screen=Screen.new()
    screen.show_preparation=true
    screen.preference_path="user://resource-choice-native-probe/preference.cfg"
    screen.disk=Disk.new("user://resource-choice-native-probe/save.json","user://resource-choice-native-probe/options.json")
    root.add_child(screen)
    current_scene=screen
    root.content_scale_size=Vector2i(1280,720)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.size=Vector2i(1280,720)
    screen.set_process(false)
    await capture("preparation")
    screen.start_resource_battle("SWAP")
    screen.set_process(false)
    await capture("swap")
    var selected=false
    for y in 8:
        for x in 7:
            if selected:break
            var a=Vector2i(x,y)
            var b=a+Vector2i.RIGHT
            screen.session.swap._swap(a,b)
            var valid=not screen.session.swap.matched_cells().is_empty()
            screen.session.swap._swap(a,b)
            if valid:
                screen.select_swap_cell(a)
                screen.select_swap_cell(b)
                selected=true
    assert(selected)
    for i in 65:
        if not screen.session.swap.resolving:break
        screen.session.tick(300000)
    assert(screen.session.metrics.casts==0)
    assert(screen.session.resource_rewards.total_units()>0)
    screen.dispatch("switch")
    await capture("pair")
    screen.dispatch("pause")
    assert(screen.save_checkpoint().success)
    assert(screen.restore_checkpoint().success)
    assert(screen.session.resource_mode=="SWAP")
    var receipt={"native_renderer":RenderingServer.get_video_adapter_name(),"viewport":[root.size.x,root.size.y],"resource_mode":screen.session.resource_mode,"swap_units":screen.session.resource_rewards.total_units(),"swap_casts":screen.session.metrics.casts,"disk_roundtrip":true,"storage":"user://resource-choice-native-probe","human_balance":"NOT_RUN"}
    var file=FileAccess.open(output+"/runtime.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(receipt,"  "))
    file.close()
    screen.queue_free()
    await process_frame
    screen=Screen.new()
    screen.show_preparation=true
    screen.preference_path="user://resource-choice-native-probe/preference.cfg"
    screen.disk=Disk.new("user://resource-choice-native-probe/save.json","user://resource-choice-native-probe/options.json")
    root.add_child(screen)
    current_scene=screen
    screen.start_resource_battle("LINE")
    screen.set_process(false)
    await capture("line")
    screen.queue_free()
    await process_frame
    quit()
