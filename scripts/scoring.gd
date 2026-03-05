class_name Scoring
extends RefCounted

const POINTS := {
	"Single": 100,
	"Double": 300,
	"Triple": 500,
	"Tetris": 800,
	"TSpin": 400,
	"TSpinMini": 100,
	"TSpinSingle": 800,
	"TSpinMiniSingle": 200,
	"TSpinDouble": 1200,
	"TSpinTriple": 1600,
}

const PERFECT_CLEAR_POINTS := {
	1: 800,
	2: 1200,
	3: 1800,
	4: 3200,
}

var score: int = 0
var level: int = 1
var lines_cleared: int = 0
var combo_count: int = -1
var back_to_back: bool = false


func get_score() -> int:
	return score


func get_level() -> int:
	return level


func get_lines() -> int:
	return lines_cleared


func process_placement(
		lines: int,
		is_tspin: bool,
		is_tspin_mini: bool,
		is_perfect_clear: bool,
		drop_distance: int,
		was_hard_drop: bool
	) -> void:
	var line_clear_points := _get_line_clear_points(lines, is_tspin, is_tspin_mini)
	var qualifies_for_b2b := lines > 0 and (lines == 4 or is_tspin)

	if qualifies_for_b2b and back_to_back:
		line_clear_points = int(floor(line_clear_points * 1.5))

	var combo_bonus := 0
	if lines > 0:
		combo_count += 1
		combo_bonus = 50 * combo_count * level
	else:
		combo_count = -1

	var perfect_clear_bonus := 0
	if is_perfect_clear and PERFECT_CLEAR_POINTS.has(lines):
		perfect_clear_bonus = PERFECT_CLEAR_POINTS[lines] * level

	var drop_points := drop_distance
	if was_hard_drop:
		drop_points = drop_distance * 2

	score += line_clear_points + combo_bonus + perfect_clear_bonus + drop_points
	lines_cleared += lines
	level = mini(int(lines_cleared / 10.0) + 1, 15)

	if qualifies_for_b2b:
		back_to_back = true
	elif lines > 0:
		back_to_back = false


func detect_tspin(
		grid,
		piece_type: String,
		piece_position: Vector2i,
		piece_rotation_state: int,
		last_was_rotation: bool
	) -> Dictionary:
	if piece_type != "T" or not last_was_rotation:
		return {"is_tspin": false, "is_mini": false}

	var center := piece_position
	var corner_offsets := [
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
	]

	var occupied_corners := 0
	for offset in corner_offsets:
		if not grid.is_empty_at(center + offset):
			occupied_corners += 1

	if occupied_corners < 3:
		return {"is_tspin": false, "is_mini": false}

	var state := posmod(piece_rotation_state, 4)
	var front_offsets: Array
	match state:
		0:
			front_offsets = [Vector2i(-1, -1), Vector2i(1, -1)]
		1:
			front_offsets = [Vector2i(1, -1), Vector2i(1, 1)]
		2:
			front_offsets = [Vector2i(1, 1), Vector2i(-1, 1)]
		3:
			front_offsets = [Vector2i(-1, 1), Vector2i(-1, -1)]
		_:
			front_offsets = [Vector2i(-1, -1), Vector2i(1, -1)]

	var front_filled_a: bool = not grid.is_empty_at(center + front_offsets[0])
	var front_filled_b: bool = not grid.is_empty_at(center + front_offsets[1])
	var is_full_tspin: bool = front_filled_a and front_filled_b

	return {
		"is_tspin": true,
		"is_mini": not is_full_tspin,
	}


func reset() -> void:
	score = 0
	level = 1
	lines_cleared = 0
	combo_count = -1
	back_to_back = false


func _get_line_clear_points(lines: int, is_tspin: bool, is_tspin_mini: bool) -> int:
	var action := ""

	if is_tspin:
		match lines:
			0:
				action = "TSpinMini" if is_tspin_mini else "TSpin"
			1:
				action = "TSpinMiniSingle" if is_tspin_mini else "TSpinSingle"
			2:
				action = "TSpinDouble"
			3:
				action = "TSpinTriple"
			_:
				action = ""
	else:
		match lines:
			1:
				action = "Single"
			2:
				action = "Double"
			3:
				action = "Triple"
			4:
				action = "Tetris"
			_:
				action = ""

	if action == "" or not POINTS.has(action):
		return 0

	return POINTS[action] * level
