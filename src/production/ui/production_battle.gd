## 60/40 전투 화면에서 한 번에 하나의 퍼즐 workspace만 표시한다.
class_name ProductionBattle
extends Control

const LINE := "LINE"
const CHAIN := "CHAIN"

@onready var _line_view: Control = $MainRow/PuzzleColumn/PuzzleHost/LineBoardView
@onready var _chain_view: Control = $MainRow/PuzzleColumn/PuzzleHost/ChainBoardView

func _ready() -> void:
	$MainRow/PuzzleColumn/ModeBar/LineButton.pressed.connect(func(): set_active_workspace(LINE))
	$MainRow/PuzzleColumn/ModeBar/ChainButton.pressed.connect(func(): set_active_workspace(CHAIN))
	set_active_workspace(LINE)

func set_active_workspace(workspace: String) -> bool:
	if workspace != LINE and workspace != CHAIN:
		return false
	_line_view.visible = workspace == LINE
	_chain_view.visible = workspace == CHAIN
	return true
