## View-owned input state. Receives elapsed time; never ticks a gameplay owner.
extends RefCounted
var held := {}
var _sources := {}
var options: Dictionary = {}
var capture_group := ""
var capture_action := ""
var presentation_group := "keyboard_mapping"
var _menu_events := {}
const GAMEPAD_NAMES := {0:"A",1:"B",2:"X",3:"Y",4:"Back",5:"Guide",6:"Start",7:"왼쪽 스틱",8:"오른쪽 스틱",9:"LB",10:"RB",11:"십자키 위",12:"십자키 아래",13:"십자키 왼쪽",14:"십자키 오른쪽"}
const DAS_US := 150000
const ARR_US := 50000
func configure(value: Dictionary):
    release_menu_bindings()
    options = value
    clear()
func _presentation_action(action: String, group: String) -> String:
    if group == "gamepad_mapping":
        if action == "hard_drop": return "accept"
        if action == "hold": return "cancel"
        if action == "def": return "category_next"
    return action

func binding_names(action: String, group: String = "", source_options: Dictionary = {}) -> PackedStringArray:
    var selected_group := presentation_group if group.is_empty() else group
    var selected_options := options if source_options.is_empty() else source_options
    var mapped_action := _presentation_action(action,selected_group)
    var mapping: Dictionary = selected_options.get(selected_group,{})
    if not mapping.has(mapped_action): return PackedStringArray()
    var codes: Array = []
    if selected_group == "keyboard_mapping": codes = mapping[mapped_action]
    else: codes = [mapping[mapped_action]]
    var names := PackedStringArray()
    for raw_code in codes:
        var code := int(raw_code)
        if selected_group == "keyboard_mapping": names.append(OS.get_keycode_string(code))
        else: names.append(String(GAMEPAD_NAMES.get(code,"패드 버튼 "+str(code))))
    return names

func binding_label(action: String, group: String = "", include_alternatives: bool = false, source_options: Dictionary = {}) -> String:
    var names := binding_names(action,group,source_options)
    if names.is_empty(): return "미지정"
    return " / ".join(names) if include_alternatives else names[0]

func group_label(group: String = "") -> String:
    var selected_group := presentation_group if group.is_empty() else group
    return "키" if selected_group == "keyboard_mapping" else "패드"

func binding_phrase(action: String, group: String = "", include_alternatives: bool = false) -> String:
    var selected_group := presentation_group if group.is_empty() else group
    return group_label(selected_group)+" "+binding_label(action,selected_group,include_alternatives)

func paired_binding_phrase(action: String) -> String:
    return binding_phrase(action,"keyboard_mapping")+" / "+binding_phrase(action,"gamepad_mapping")

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
    if pressed: presentation_group = group
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
