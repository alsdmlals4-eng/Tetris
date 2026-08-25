class_name ProductionBattleRuntimeBridge
extends Node

const LINE_VIEW_PATH := "Layout/MainRow/PuzzlePanel/LineBoardHost/LineBoardView"

var coordinator = null
var ui: ProductionBattleUI = null

func _ready() -> void:
    _bind_ui_signal()

func _process(delta: float) -> void:
    if coordinator == null or delta <= 0.0:
        return
    if coordinator.line_session != null:
        coordinator.line_session.tick(delta)
    _refresh_presentation()

func bind_coordinator(value) -> bool:
    if value == null:
        return false
    coordinator = value
    _bind_ui_signal()
    return _refresh_presentation()

func _bind_ui_signal() -> void:
    if ui == null:
        ui = get_parent() as ProductionBattleUI
    if ui == null:
        return
    if not ui.ready_requested.is_connected(_on_ready_requested):
        ui.ready_requested.connect(_on_ready_requested)
    if not ui.technique_requested.is_connected(_on_technique_requested):
        ui.technique_requested.connect(_on_technique_requested)

func _on_ready_requested() -> void:
    if coordinator == null:
        return
    coordinator.request_ready()
    _refresh_presentation()

func _on_technique_requested(technique_id: String) -> void:
    if coordinator == null:
        return
    coordinator.select_technique(technique_id)
    _refresh_presentation()

func _refresh_presentation() -> bool:
    if coordinator == null or ui == null:
        return false
    var state: Dictionary = coordinator.snapshot()
    if state.is_empty():
        return false
    ui.apply_presentation(state)
    _refresh_line_view()
    return true

func _refresh_line_view() -> void:
    if coordinator == null or ui == null or coordinator.line_session == null:
        return
    var view = ui.get_node_or_null(LINE_VIEW_PATH)
    if view == null or not view.has_method("bind_line_session"):
        return
    view.bind_line_session(coordinator.line_session)
