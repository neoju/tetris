extends GutTest

const Grid = preload("res://scripts/grid.gd")
const GameLogic = preload("res://scripts/game_logic.gd")
const TetrominoDataScript = preload("res://scripts/tetromino_data.gd")

var _game


func before_each() -> void:
	_game = GameLogic.new()
	_game.start_game()


func _fill_row_except(row: int, empty_cols: Array) -> void:
	for col in range(10):
		if not empty_cols.has(col):
			_game.grid.cells[row][col] = "X"


func test_start_game_spawns_piece() -> void:
	assert_true(_game.game_active, "Game should be active after start_game")
	assert_not_null(_game.active_piece, "start_game should spawn an active piece")

	var piece_type = _game.active_piece.type
	var expected_spawn = TetrominoDataScript.SPAWN_POSITIONS[piece_type]
	assert_eq(_game.active_piece.position, expected_spawn, "Active piece should spawn at configured spawn position")


func test_gravity_drops_piece() -> void:
	var start_y = _game.active_piece.position.y
	_game.update(1.0)

	assert_true(_game.active_piece.position.y > start_y, "Gravity should move piece down after enough delta")


func test_gravity_speed_increases_with_level() -> void:
	var speed_level_1 = _game.get_gravity_speed(1)
	var speed_level_10 = _game.get_gravity_speed(10)

	assert_true(speed_level_10 > speed_level_1, "Higher levels should have faster gravity")
	assert_true(speed_level_10 > speed_level_1 * 3.0, "Level 10 gravity should be significantly faster than level 1")


func test_hard_drop_and_lock() -> void:
	var piece_before = _game.active_piece
	var landing_blocks = piece_before.get_ghost_block_positions(_game.grid)

	_game.hard_drop()
	var lock_events = _game._lock_piece()

	assert_true(lock_events["piece_locked"], "Lock events should report piece_locked")
	for block in landing_blocks:
		assert_eq(_game.grid.get_cell(block), piece_before.type, "Locked piece blocks should be written to grid at ghost landing")

	assert_not_null(_game.active_piece, "A new piece should spawn after lock")
	assert_false(_game.active_piece == piece_before, "Active piece instance should change after lock")


func test_hard_drop_scores_correctly() -> void:
	_game.active_piece.position = Vector2i(3, 4)
	var expected_distance = _game.active_piece.get_ghost_position(_game.grid).y - _game.active_piece.position.y
	var score_before = _game.scoring.score

	var drop_result = _game.hard_drop()
	_game._lock_hard_drop_distance = drop_result["distance"]
	_game._lock_was_hard_drop = true
	var lock_events = _game._lock_piece()

	assert_eq(drop_result["distance"], expected_distance, "hard_drop should report ghost drop distance")
	assert_eq(lock_events["score_added"], expected_distance * 2, "Hard drop should score 2 points per dropped cell")
	assert_eq(_game.scoring.score, score_before + (expected_distance * 2), "Total score should include hard drop points")


func test_soft_drop_scoring_on_lock() -> void:
	var score_before = _game.scoring.score
	_game.soft_drop_distance = 6

	var lock_events = _game._lock_piece()

	assert_true(lock_events["piece_locked"], "Piece should lock normally")
	assert_eq(lock_events["score_added"], 6, "Soft drop should award 1 point per cell")
	assert_eq(_game.scoring.score, score_before + 6, "Score should increase by soft drop distance")


func test_hold_piece_works() -> void:
	var initial_type = _game.active_piece.type

	_game.hold()

	assert_eq(_game.hold_piece_type, initial_type, "Hold slot should store current piece type")
	assert_false(_game.can_hold, "Holding once should disable additional holds until lock")
	assert_not_null(_game.active_piece, "A replacement active piece should be spawned on first hold")
	assert_false(_game.active_piece.type == initial_type, "Replacement active piece should differ from held piece")


func test_hold_cannot_double_hold() -> void:
	var first_type = _game.active_piece.type
	_game.hold()
	var type_after_first_hold = _game.active_piece.type

	assert_false(_game.can_hold, "can_hold should be false after first hold")

	_game.hold()

	assert_eq(_game.hold_piece_type, first_type, "Second hold attempt should not alter held piece")
	assert_eq(_game.active_piece.type, type_after_first_hold, "Second hold attempt should not swap active piece")


func test_hold_swap_restores_held_piece() -> void:
	var first_type = _game.active_piece.type
	_game.hold()
	var second_type = _game.active_piece.type

	_game.can_hold = true
	_game.hold()

	assert_eq(_game.active_piece.type, first_type, "Second hold (after re-enabling) should restore initially held piece")
	assert_eq(_game.hold_piece_type, second_type, "Second hold should store the currently active piece")


func test_lock_delay_triggers_lock() -> void:
	_game.active_piece.position = _game.active_piece.get_ghost_position(_game.grid)
	var landing_blocks = _game.active_piece.get_block_positions()

	_game.lock_delay.start()
	var expired = _game.lock_delay.update(0.6)
	assert_true(expired, "Lock delay should expire after >0.5s")

	var lock_events = _game._lock_piece()
	assert_true(lock_events["piece_locked"], "Expired lock delay should result in piece lock")
	for block in landing_blocks:
		assert_true(_game.grid.get_cell(block) != "", "Locked blocks should be present in the grid")


func test_game_over_on_blocked_spawn() -> void:
	for row in range(0, 6):
		for col in range(10):
			_game.grid.cells[row][col] = "X"

	_game.spawn_piece("T")

	assert_false(_game.game_active, "Spawn collision in top rows should trigger game over")


func test_combo_counter_increments() -> void:
	_game.grid.reset()
	_game.spawn_piece("O")
	_game.active_piece.position = Vector2i(4, 22)
	_fill_row_except(23, [4, 5])

	var first_lock = _game._lock_piece()
	assert_eq(first_lock["lines_cleared"], 1, "First placement should clear one line")
	assert_eq(_game.scoring.combo_count, 0, "First consecutive line clear should set combo_count to 0")

	_game.grid.reset()
	_game.spawn_piece("O")
	_game.active_piece.position = Vector2i(4, 22)
	_fill_row_except(23, [4, 5])

	var second_lock = _game._lock_piece()
	assert_eq(second_lock["lines_cleared"], 1, "Second placement should also clear one line")
	assert_eq(_game.scoring.combo_count, 1, "Second consecutive line clear should increment combo_count to 1")


func test_level_up_after_10_lines() -> void:
	_game.scoring.lines_cleared = 9
	_game.scoring.level = 1

	_game.grid.reset()
	_game.spawn_piece("O")
	_game.active_piece.position = Vector2i(4, 22)
	_fill_row_except(23, [4, 5])

	var lock_events = _game._lock_piece()

	assert_eq(lock_events["lines_cleared"], 1, "Placement should clear one line")
	assert_true(lock_events["level_up"], "Lock event should report level up when crossing 10 lines")
	assert_eq(_game.scoring.level, 2, "Scoring level should increase from 1 to 2 at 10 total lines")
