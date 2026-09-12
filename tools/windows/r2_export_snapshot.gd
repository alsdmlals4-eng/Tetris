@tool
extends RefCounted

const MAIN_SCENE_KEY := "application/run/main_scene"
const R2_TRIAL_MAIN := "res://scenes/replanned_r2/main.tscn"

var _active := false
var _saved_main_scene: Variant = null

func begin() -> bool:
    if _active or not ProjectSettings.has_setting(MAIN_SCENE_KEY):
        return false
    _saved_main_scene = ProjectSettings.get_setting(MAIN_SCENE_KEY)
    ProjectSettings.set_setting(MAIN_SCENE_KEY, R2_TRIAL_MAIN)
    _active = true
    return true

func end() -> void:
    if not _active:
        return
    ProjectSettings.set_setting(MAIN_SCENE_KEY, _saved_main_scene)
    _saved_main_scene = null
    _active = false