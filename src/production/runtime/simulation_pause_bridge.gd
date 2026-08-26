class_name SimulationPauseBridge
extends Node

const SIMULATION_AUDIO_GROUP := "simulation_audio"

var _controller: SimulationPauseController = null
var _audio_paused_by_bridge: Dictionary = {}

func _init() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
    _apply_pause_state(_controller != null and _controller.is_paused())

func _exit_tree() -> void:
    _disconnect_controller()

func bind_controller(controller: SimulationPauseController) -> void:
    if controller == _controller:
        _apply_pause_state(controller != null and controller.is_paused())
        return

    _disconnect_controller()
    _controller = controller
    if _controller != null:
        _controller.pause_state_changed.connect(_on_pause_state_changed)
    _apply_pause_state(_controller != null and _controller.is_paused())

func _disconnect_controller() -> void:
    if _controller != null and _controller.pause_state_changed.is_connected(_on_pause_state_changed):
        _controller.pause_state_changed.disconnect(_on_pause_state_changed)
    _controller = null

func _on_pause_state_changed(paused: bool) -> void:
    _apply_pause_state(paused)

func _apply_pause_state(paused: bool) -> void:
    if not is_inside_tree():
        return
    var tree := get_tree()
    if tree == null:
        return

    tree.paused = paused
    if paused:
        _pause_playing_simulation_audio(tree)
    else:
        _resume_audio_paused_by_bridge()

func _pause_playing_simulation_audio(tree: SceneTree) -> void:
    for node in tree.get_nodes_in_group(SIMULATION_AUDIO_GROUP):
        if node is AudioStreamPlayer and node.playing and not node.stream_paused:
            node.stream_paused = true
            _audio_paused_by_bridge[node.get_instance_id()] = true

func _resume_audio_paused_by_bridge() -> void:
    for audio_id in _audio_paused_by_bridge:
        var node: Object = instance_from_id(audio_id)
        if node is AudioStreamPlayer:
            node.stream_paused = false
    _audio_paused_by_bridge.clear()
