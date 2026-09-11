## View-owned input state. Receives elapsed time; never ticks a gameplay owner.
extends RefCounted
var held := {}
var _sources := {}
var options: Dictionary = {}
var capture_group := ""
var capture_action := ""
var _menu_events := {}
const DAS_US := 150000
const ARR_US := 50000
func configure(value: Dictionary):
    release_menu_bindings()
    options = value
    clear()
func set_menu_bindings(enabled: bool):
    var actions={"ui_accept":"accept","ui_cancel":"cancel","ui_close_dialog":"cancel"}
    for ui_action in actions:
        var code=int(options.get("gamepad_mapping",{}).get(actions[ui_action],-1))
        if _menu_events.has(ui_action):
            if enabled and _menu_events[ui_action].button_index==code: continue
            InputMap.action_erase_event(ui_action,_menu_events[ui_action])
            _menu_events.erase(ui_action)
        if not enabled or code<0: continue
        var event=InputEventJoypadButton.new()
        event.device=-1
        event.button_index=code
        if not InputMap.action_has_event(ui_action,event):
            InputMap.action_add_event(ui_action,event)
            _menu_events[ui_action]=event
func release_menu_bindings():
    for action in _menu_events:
        InputMap.action_erase_event(action,_menu_events[action])
    _menu_events.clear()
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
