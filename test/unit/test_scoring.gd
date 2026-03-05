extends GutTest

const Scoring = preload("res://scripts/scoring.gd")
const Grid = preload("res://scripts/grid.gd")

var _scoring


func before_each() -> void:
	_scoring = Scoring.new()


func test_single_at_level_1() -> void:
	_scoring.process_placement(1, false, false, false, 0, false)
	assert_eq(_scoring.get_score(), 100, "Single should award 100 points at level 1")


func test_tetris_at_level_3() -> void:
	_scoring.level = 3
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.get_score(), 2400, "Tetris should award 800 x level")


func test_tspin_double_at_level_1() -> void:
	_scoring.process_placement(2, true, false, false, 0, false)
	assert_eq(_scoring.get_score(), 1200, "T-spin double should award 1200 at level 1")


func test_back_to_back_tetris() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	_scoring.combo_count = -1
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.get_score(), 2000, "Second consecutive tetris should get B2B bonus")


func test_back_to_back_breaks() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	_scoring.combo_count = -1
	_scoring.process_placement(1, false, false, false, 0, false)
	assert_eq(_scoring.get_score(), 900, "Single after tetris should score normally")
	assert_false(_scoring.back_to_back, "Regular line clear should break B2B")


func test_combo_scoring() -> void:
	_scoring.process_placement(1, false, false, false, 0, false) # combo 0 => +0
	_scoring.process_placement(1, false, false, false, 0, false) # combo 1 => +50
	_scoring.process_placement(1, false, false, false, 0, false) # combo 2 => +100
	assert_eq(_scoring.get_score(), 450, "3 consecutive singles should include combo bonuses 0, 50, 100")
	assert_eq(_scoring.combo_count, 2, "Combo count should be 2 after three consecutive clears")


func test_hard_drop_scoring() -> void:
	_scoring.process_placement(0, false, false, false, 10, true)
	assert_eq(_scoring.get_score(), 20, "Hard drop should award 2 points per cell")


func test_soft_drop_scoring() -> void:
	_scoring.process_placement(0, false, false, false, 5, false)
	assert_eq(_scoring.get_score(), 5, "Soft drop should award 1 point per cell")


func test_level_progression() -> void:
	# 10 lines total
	_scoring.process_placement(4, false, false, false, 0, false)
	_scoring.process_placement(4, false, false, false, 0, false)
	_scoring.process_placement(2, false, false, false, 0, false)
	assert_eq(_scoring.get_level(), 2, "At 10 total lines, level should be 2")

	# 20 lines total
	_scoring.process_placement(4, false, false, false, 0, false)
	_scoring.process_placement(4, false, false, false, 0, false)
	_scoring.process_placement(2, false, false, false, 0, false)
	assert_eq(_scoring.get_level(), 3, "At 20 total lines, level should be 3")


func test_level_cap_at_15() -> void:
	for _i in range(80):
		_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.get_level(), 15, "Level should never exceed 15")


func test_perfect_clear_single() -> void:
	_scoring.process_placement(1, false, false, true, 0, false)
	assert_eq(_scoring.get_score(), 900, "Perfect clear single should add 800 bonus plus single clear score")


func test_tspin_detection_3_corners() -> void:
	var grid := Grid.new()
	var center := Vector2i(4, 10)

	# Occupy 3 corners around center: TL, TR, BR
	grid.place_blocks([center + Vector2i(-1, -1)], "X")
	grid.place_blocks([center + Vector2i(1, -1)], "X")
	grid.place_blocks([center + Vector2i(1, 1)], "X")

	var result: Dictionary = _scoring.detect_tspin(grid, "T", center, 0, true)
	assert_true(result["is_tspin"], "3 occupied corners after rotation should detect T-spin")


func test_tspin_detection_marks_mini_when_front_not_both_filled() -> void:
	var grid := Grid.new()
	var center := Vector2i(4, 10)

	# State 0 front corners are TL and TR. Fill TL + BR + BL => 3 corners, but front not both.
	grid.place_blocks([center + Vector2i(-1, -1)], "X")
	grid.place_blocks([center + Vector2i(1, 1)], "X")
	grid.place_blocks([center + Vector2i(-1, 1)], "X")

	var result: Dictionary = _scoring.detect_tspin(grid, "T", center, 0, true)
	assert_true(result["is_tspin"], "Should still detect T-spin with 3 occupied corners")
	assert_true(result["is_mini"], "Should be mini when front corners are not both occupied")


func test_reset_restores_initial_state() -> void:
	_scoring.process_placement(4, false, false, false, 6, true)
	_scoring.reset()
	assert_eq(_scoring.get_score(), 0, "Reset should clear score")
	assert_eq(_scoring.get_level(), 1, "Reset should restore level 1")
	assert_eq(_scoring.get_lines(), 0, "Reset should clear total lines")
	assert_eq(_scoring.combo_count, -1, "Reset should restore combo_count")
	assert_false(_scoring.back_to_back, "Reset should clear B2B state")
