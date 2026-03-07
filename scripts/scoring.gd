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
var back_to_back_count: int = 0
var combo_grace_pieces: int = 0

# === STATS TRACKING ===
var stat_singles: int = 0
var stat_doubles: int = 0
var stat_triples: int = 0
var stat_tetrises: int = 0
var stat_tspin_zeros: int = 0
var stat_tspin_mini_zeros: int = 0
var stat_tspin_singles: int = 0
var stat_tspin_mini_singles: int = 0
var stat_tspin_doubles: int = 0
var stat_tspin_triples: int = 0
var stat_perfect_clears: int = 0
var stat_max_combo: int = 0
var stat_max_b2b: int = 0
var stat_combo_chains: Dictionary = {}  # {combo_level: count_of_chains}
var stat_combo_counts: Dictionary = {}  # {display_level: total_times_reached}
var stat_total_combos: int = 0
var stat_special_counts: Dictionary = {}  # {action_label: total_times}
var _chain_peak: int = 0


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
		back_to_back_count += 1

	var combo_bonus := 0
	if lines > 0:
		combo_count += 1
		combo_grace_pieces = 0
		combo_bonus = 50 * combo_count * level
		
		# Track total times this combo level was reached
		var display_combo = combo_count + 1
		if display_combo >= 2:
			stat_combo_counts[display_combo] = stat_combo_counts.get(display_combo, 0) + 1
			stat_total_combos += 1
			
		if combo_count > _chain_peak:
			_chain_peak = combo_count
		if combo_count > stat_max_combo:
			stat_max_combo = combo_count
	else:
		combo_grace_pieces += 1
		if combo_grace_pieces > 1:
			_record_chain_end()
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
		if not back_to_back:
			back_to_back_count = 1
		back_to_back = true
	elif lines > 0:
		back_to_back = false
		back_to_back_count = 0

	# Track stats
	_track_clear_type(lines, is_tspin, is_tspin_mini)
	
	if lines == 4:
		stat_special_counts["TETRIS"] = stat_special_counts.get("TETRIS", 0) + 1
	elif is_tspin and lines > 0:
		var t_label = "T-SPIN"
		if is_tspin_mini: t_label = "T-SPIN MINI"
		match lines:
			1: t_label += " SINGLE"
			2: t_label += " DOUBLE"
			3: t_label += " TRIPLE"
		stat_special_counts[t_label] = stat_special_counts.get(t_label, 0) + 1

	if is_perfect_clear and lines > 0:
		stat_perfect_clears += 1
		stat_special_counts["PERFECT CLEAR"] = stat_special_counts.get("PERFECT CLEAR", 0) + 1
	if back_to_back_count > stat_max_b2b:
		stat_max_b2b = back_to_back_count


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
	back_to_back_count = 0
	combo_grace_pieces = 0
	stat_singles = 0
	stat_doubles = 0
	stat_triples = 0
	stat_tetrises = 0
	stat_tspin_zeros = 0
	stat_tspin_mini_zeros = 0
	stat_tspin_singles = 0
	stat_tspin_mini_singles = 0
	stat_tspin_doubles = 0
	stat_tspin_triples = 0
	stat_perfect_clears = 0
	stat_max_combo = 0
	stat_max_b2b = 0
	stat_combo_chains = {}
	stat_combo_counts = {}
	stat_total_combos = 0
	stat_special_counts = {}
	_chain_peak = 0


func _track_clear_type(lines: int, is_tspin: bool, is_tspin_mini: bool) -> void:
	if is_tspin:
		match lines:
			0:
				if is_tspin_mini:
					stat_tspin_mini_zeros += 1
				else:
					stat_tspin_zeros += 1
			1:
				if is_tspin_mini:
					stat_tspin_mini_singles += 1
				else:
					stat_tspin_singles += 1
			2:
				stat_tspin_doubles += 1
			3:
				stat_tspin_triples += 1
	elif lines > 0:
		match lines:
			1: stat_singles += 1
			2: stat_doubles += 1
			3: stat_triples += 1
			4: stat_tetrises += 1


func _record_chain_end() -> void:
	if _chain_peak >= 1:
		if not stat_combo_chains.has(_chain_peak):
			stat_combo_chains[_chain_peak] = 0
		stat_combo_chains[_chain_peak] += 1
	_chain_peak = 0


func get_end_stats() -> Dictionary:
	# Include any active combo chain not yet recorded
	var chains := stat_combo_chains.duplicate()
	if _chain_peak >= 1:
		if not chains.has(_chain_peak):
			chains[_chain_peak] = 0
		chains[_chain_peak] += 1

	return {
		"singles": stat_singles,
		"doubles": stat_doubles,
		"triples": stat_triples,
		"tetrises": stat_tetrises,
		"tspin_zeros": stat_tspin_zeros,
		"tspin_mini_zeros": stat_tspin_mini_zeros,
		"tspin_singles": stat_tspin_singles,
		"tspin_mini_singles": stat_tspin_mini_singles,
		"tspin_doubles": stat_tspin_doubles,
		"tspin_triples": stat_tspin_triples,
		"perfect_clears": stat_perfect_clears,
		"max_combo": stat_max_combo,
		"max_b2b": stat_max_b2b,
		"combo_chains": chains,
	}


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
