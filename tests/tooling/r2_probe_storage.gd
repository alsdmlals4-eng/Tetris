## Native QA only. Never retrofit path properties on an already-running player scene.
extends RefCounted
const ROOT="user://replanned_r2_tests/"

func create_screen():
    var screen=load("res://scenes/replanned_r2/main.tscn").instantiate()
    var directory=ROOT+"isolated-"+Crypto.new().generate_random_bytes(16).hex_encode()+"/"
    screen.save_path=directory+"save.json"
    screen.options_path=directory+"options.json"
    screen.expedition_save_path=directory+"expedition.json"
    screen.report_directory=directory+"reports"
    return screen

func is_isolated(screen) -> bool:
    if screen==null or screen.disk==null or screen.expedition_disk==null: return false
    if screen.disk.save_path!=screen.save_path or screen.disk.options_path!=screen.options_path or screen.expedition_disk.save_path!=screen.expedition_save_path: return false
    for path in [screen.disk.save_path,screen.disk.options_path,screen.expedition_disk.save_path,screen.report_directory]:
        var normalized=String(path).replace("\\","/").simplify_path()
        if not normalized.begins_with(ROOT) or normalized==ROOT: return false
    return true
