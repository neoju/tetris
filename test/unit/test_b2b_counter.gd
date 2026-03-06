extends GutTest

const Scoring = preload("res://scripts/scoring.gd")

var _scoring


func before_each() -> void:
	_scoring = Scoring.new()


# === Test: B2B Counter Initialization ===
func test_back_to_back_count_starts_at_zero() -> void:
	assert_eq(_scoring.back_to_back_count, 0, "B2B counter should initialize to 0")


func test_reset_restores_back_to_back_count_to_zero() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	_scoring.process_placement(4, false, false, false, 0, false)
	_scoring.reset()
	assert_eq(_scoring.back_to_back_count, 0, "Reset should restore B2B counter to 0")


# === Test: B2B Counter Activation ===
func test_back_to_back_count_set_to_1_on_first_tetris() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_true(_scoring.back_to_back, "First Tetris should activate B2B")
	assert_eq(_scoring.back_to_back_count, 1, "B2B counter should be 1 after first qualifying clear")


func test_back_to_back_count_set_to_1_on_first_tspin() -> void:
	_scoring.process_placement(1, true, false, false, 0, false)
	assert_true(_scoring.back_to_back, "First T-spin should activate B2B")
	assert_eq(_scoring.back_to_back_count, 1, "B2B counter should be 1 after first T-spin")


# === Test: B2B Counter Increment ===
func test_back_to_back_count_increments_on_consecutive_tetris() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "First Tetris: B2B counter = 1")
	
	_scoring.combo_count = -1
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 2, "Second consecutive Tetris: B2B counter = 2")
	
	_scoring.combo_count = -1
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 3, "Third consecutive Tetris: B2B counter = 3")


func test_back_to_back_count_increments_on_consecutive_tspins() -> void:
	_scoring.process_placement(1, true, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "First T-spin: B2B counter = 1")
	
	_scoring.combo_count = -1
	_scoring.process_placement(2, true, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 2, "Second consecutive T-spin: B2B counter = 2")


func test_back_to_back_count_increments_on_mixed_qualifying_clears() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "First Tetris: B2B counter = 1")
	
	_scoring.combo_count = -1
	_scoring.process_placement(3, true, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 2, "T-spin triple after Tetris: B2B counter = 2")
	
	_scoring.combo_count = -1
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 3, "Tetris after T-spin: B2B counter = 3")


# === Test: B2B Counter Reset (Break) ===
func test_back_to_back_count_resets_on_single_clear() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "Initial B2B counter = 1")
	
	_scoring.combo_count = -1
	_scoring.process_placement(1, false, false, false, 0, false)
	assert_false(_scoring.back_to_back, "Regular single should break B2B")
	assert_eq(_scoring.back_to_back_count, 0, "B2B counter should reset to 0 when B2B breaks")


func test_back_to_back_count_resets_on_double_clear() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "Initial B2B counter = 1")
	
	_scoring.combo_count = -1
	_scoring.process_placement(2, false, false, false, 0, false)
	assert_false(_scoring.back_to_back, "Regular double should break B2B")
	assert_eq(_scoring.back_to_back_count, 0, "B2B counter should reset to 0")


func test_back_to_back_count_resets_on_triple_clear() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "Initial B2B counter = 1")
	
	_scoring.combo_count = -1
	_scoring.process_placement(3, false, false, false, 0, false)
	assert_false(_scoring.back_to_back, "Regular triple should break B2B")
	assert_eq(_scoring.back_to_back_count, 0, "B2B counter should reset to 0")


func test_back_to_back_count_does_not_reset_on_no_clear() -> void:
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "Initial B2B counter = 1")
	
	_scoring.combo_grace_pieces = 0
	_scoring.process_placement(0, false, false, false, 0, false)
	assert_true(_scoring.back_to_back, "No clear should not break B2B")
	assert_eq(_scoring.back_to_back_count, 1, "B2B counter should remain unchanged on no clear")


# === Test: B2B Counter with Multiple Sequences ===
func test_back_to_back_count_multiple_b2b_sequences() -> void:
	# First B2B sequence: 2 Tetris clears
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "First B2B sequence starts: counter = 1")
	
	_scoring.combo_count = -1
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 2, "First B2B sequence continues: counter = 2")
	
	# Break B2B
	_scoring.combo_count = -1
	_scoring.process_placement(1, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 0, "B2B breaks: counter = 0")
	assert_false(_scoring.back_to_back, "B2B is off")
	
	# Second B2B sequence: T-spin then Tetris
	_scoring.combo_count = -1
	_scoring.process_placement(2, true, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 1, "Second B2B sequence starts: counter = 1")
	
	_scoring.combo_count = -1
	_scoring.process_placement(4, false, false, false, 0, false)
	assert_eq(_scoring.back_to_back_count, 2, "Second B2B sequence continues: counter = 2")
