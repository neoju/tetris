extends Control

@onready var score_value: Label = $RightScore/ScoreValue
@onready var lines_value: Label = $RightScore/LinesValue
@onready var level_value: Label = $RightScore/LevelValue
@onready var hold_display: Control = $HoldContainer/HoldPiece
@onready var next_display: Control = $NextContainer/NextPieces
@onready var left_panel: Control = $LeftScore

var game_logic = null:
	set(value):
		game_logic = value
		if hold_display != null:
			hold_display.game_logic = value
		if next_display != null:
			next_display.game_logic = value
		if left_panel != null:
			left_panel.game_logic = value


func _process(_delta: float) -> void:
	if game_logic == null:
		return

	score_value.text = _format_number(game_logic.scoring.score)
	lines_value.text = "LINES %4d" % game_logic.scoring.lines_cleared
	level_value.text = "LEVEL %4d" % game_logic.scoring.level


func _format_number(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
