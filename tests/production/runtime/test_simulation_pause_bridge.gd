extends GutTest

const CONTROLLER_PATH := "res://src/production/runtime/simulation_pause_controller.gd"
const BRIDGE_PATH := "res://src/production/runtime/simulation_pause_bridge.gd"
const TACTICAL_SKILL := "TACTICAL_SKILL"

class SimulationProbe:
    extends Node

    var process_ticks: int = 0
    var physics_ticks: int = 0

    func _ready() -> void:
        set_process(true)
        set_physics_process(true)

    func _process(_delta: float) -> void:
        process_ticks += 1

    func _physics_process(_delta: float) -> void:
        physics_ticks += 1

class PausedUiProbe:
    extends Node

    var process_ticks: int = 0
    var input_events: int = 0

    func _init() -> void:
        process_mode = Node.PROCESS_MODE_WHEN_PAUSED

    func _ready() -> void:
        set_process(true)
        set_process_input(true)

    func _process(_delta: float) -> void:
        process_ticks += 1

    func _input(event: InputEvent) -> void:
        if event is InputEventAction and event.action == "ui_accept" and event.pressed:
            input_events += 1

var _owned_nodes: Array[Node] = []

func after_each() -> void:
    get_tree().paused = false
    for node in _owned_nodes:
        if is_instance_valid(node):
            if node.get_parent() != null:
                node.get_parent().remove_child(node)
            node.free()
    _owned_nodes.clear()

func _new_script_instance(path: String):
    var exists := ResourceLoader.exists(path)
    assert_true(exists, "%s must exist" % path)
    if not exists:
        return null
    return load(path).new()

func _own(node: Node) -> Node:
    _owned_nodes.append(node)
    get_tree().root.add_child(node)
    return node

func _audio_stream() -> AudioStreamGenerator:
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 22050.0
    stream.buffer_length = 0.2
    return stream

func test_bridge_applies_full_tree_pause_keeps_pause_ui_alive_and_preserves_stopped_audio() -> void:
    var controller = _new_script_instance(CONTROLLER_PATH)
    var bridge = _new_script_instance(BRIDGE_PATH)
    if controller == null or bridge == null:
        return

    _own(bridge)
    assert_eq(bridge.process_mode, Node.PROCESS_MODE_ALWAYS)
    assert_true(bridge.has_method("bind_controller"))
    bridge.bind_controller(controller)

    var simulation := _own(SimulationProbe.new()) as SimulationProbe
    var pause_ui := _own(PausedUiProbe.new()) as PausedUiProbe

    var active_audio := _own(AudioStreamPlayer.new()) as AudioStreamPlayer
    active_audio.add_to_group("simulation_audio")
    active_audio.stream = _audio_stream()
    active_audio.play()

    var stopped_audio := _own(AudioStreamPlayer.new()) as AudioStreamPlayer
    stopped_audio.add_to_group("simulation_audio")
    stopped_audio.stream = _audio_stream()

    await get_tree().process_frame
    await get_tree().physics_frame
    assert_gt(simulation.process_ticks, 0)
    assert_gt(simulation.physics_ticks, 0)
    assert_true(active_audio.playing)
    assert_false(stopped_audio.playing)

    var process_before := simulation.process_ticks
    var physics_before := simulation.physics_ticks
    var ui_before := pause_ui.process_ticks

    var token: int = controller.acquire(TACTICAL_SKILL)
    assert_gt(token, 0)
    assert_true(get_tree().paused, "effective pause must reach SceneTree immediately")
    assert_true(active_audio.stream_paused, "playing simulation audio must pause")
    assert_false(stopped_audio.stream_paused, "already-stopped simulation audio must remain stopped, not paused")

    await get_tree().process_frame
    await get_tree().process_frame
    assert_eq(simulation.process_ticks, process_before, "normal _process must stop while the tree is paused")
    assert_eq(simulation.physics_ticks, physics_before, "normal _physics_process must stop while the tree is paused")
    assert_gt(pause_ui.process_ticks, ui_before, "pause UI must remain processable")

    var event := InputEventAction.new()
    event.action = "ui_accept"
    event.pressed = true
    get_viewport().push_input(event)
    assert_eq(pause_ui.input_events, 1, "pause-enabled UI must still receive input")

    assert_true(controller.release(token))
    assert_false(get_tree().paused)
    assert_false(active_audio.stream_paused, "audio paused by the bridge must resume")
    assert_false(stopped_audio.stream_paused)

    var resumed_before := simulation.process_ticks
    await get_tree().process_frame
    assert_gt(simulation.process_ticks, resumed_before, "normal simulation processing must resume")

func test_bridge_does_not_resume_tree_until_last_pause_token_is_released() -> void:
    var controller = _new_script_instance(CONTROLLER_PATH)
    var bridge = _new_script_instance(BRIDGE_PATH)
    if controller == null or bridge == null:
        return

    _own(bridge)
    bridge.bind_controller(controller)

    var tactical: int = controller.acquire("TACTICAL_SKILL")
    var menu: int = controller.acquire("SYSTEM_MENU")
    assert_true(get_tree().paused)

    assert_true(controller.release(tactical))
    assert_true(get_tree().paused, "remaining SYSTEM_MENU token must keep the tree paused")

    assert_true(controller.release(menu))
    assert_false(get_tree().paused)
