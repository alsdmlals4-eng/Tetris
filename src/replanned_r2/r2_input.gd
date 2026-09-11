## View-owned input state. Receives elapsed time; never ticks a gameplay owner.
extends RefCounted
var held := {}
var _sources := {}
var options: Dictionary = {}
var capture_group := ""
var capture_action := ""
const DAS_US := 150000
const ARR_US := 50000
func configure(value: Dictionary):
    options = value
    clear()
func clear():
    held.clear()
    _sources.clear()
func event_intent(event: InputEvent) -> Dictionary:
    var group := ""
    var code := -1
    var pressed := false
    if event is InputEventKey:
        if event.echo: return {}
        group = "keyboard_mapping"
        code = event.keycode if event.keycode != 0 else event.physical_keycode
        pressed = event.pressed
    elif event is InputEventJoypadButton:
        group = "gamepad_mapping"
        code = event.button_index
        pressed = event.pressed
    else: return {}
    if not capture_group.is_empty():
        if pressed and group == capture_group:
            return {"capture":true,"group":group,"action":capture_action,"code":code}
        return {}
    var action := ""
    for candidate in options.get(group,{}):
        var matched = code in options[group][candidate] if group == "keyboard_mapping" else code == options[group][candidate]
        if matched: action = candidate; break
    if action.is_empty(): return {}
    var source = group+":"+str(event.device)+":"+str(code)
    if not pressed:
        _sources.erase(source)
        if action not in _sources.values(): held.erase(action)
        return {}
    if _sources.has(source): return {}
    _sources[source] = action
    if action in ["left","right","down"]: held[action] = DAS_US
    return {"action":action,"gamepad":group == "gamepad_mapping"}
func next_repeat_us() -> int:
    var next := 2147483647
    for remaining in held.values(): next = mini(next,int(remaining))
    return next
func elapse(delta_us: int) -> Array:
    var due := []
    for action in held.keys():
        held[action] = int(held[action])-delta_us
        if int(held[action]) <= 0:
            due.append(action)
            held[action] = ARR_US
    return due
func begin_capture(group: String, action: String):
    clear()
    capture_group = group
    capture_action = action
func cancel_capture():
    capture_group = ""
    capture_action = ""
