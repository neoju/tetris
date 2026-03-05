extends GutTest

const Grid = preload("res://scripts/grid.gd")
const Piece = preload("res://scripts/piece.gd")
const TetrominoDataScript = preload("res://scripts/tetromino_data.gd")
const WallKickDataScript = preload("res://scripts/wall_kick_data.gd")

var _grid: Grid


func before_each() -> void:
	_grid = Grid.new()


func _sorted_positions(positions: Array[Vector2i]) -> Array[Vector2i]:
	var sorted := positions.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return sorted


func _assert_positions_match(actual: Array[Vector2i], expected: Array[Vector2i], message: String) -> void:
	assert_eq(_sorted_positions(actual), _sorted_positions(expected), message)


func _positions_for(type: String, state: int, pivot: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for offset in TetrominoDataScript.SHAPES[type][state]:
		positions.append(pivot + offset)
	return positions


func test_t_piece_rotates_cw() -> void:
	var piece = Piece.new("T", Vector2i(4, 10))
	var rotated = piece.try_rotate(_grid, true)

	assert_true(rotated, "T piece should rotate CW in open space")
	assert_eq(piece.rotation_state, 1, "Rotation state should be 0 -> 1")
	var expected := _positions_for("T", 1, Vector2i(4, 10))
	_assert_positions_match(piece.get_block_positions(), expected, "CW-rotated T blocks should match state 1 shape")


func test_t_piece_rotates_ccw() -> void:
	var piece = Piece.new("T", Vector2i(4, 10))
	var rotated = piece.try_rotate(_grid, false)

	assert_true(rotated, "T piece should rotate CCW in open space")
	assert_eq(piece.rotation_state, 3, "Rotation state should be 0 -> 3")
	var expected := _positions_for("T", 3, Vector2i(4, 10))
	_assert_positions_match(piece.get_block_positions(), expected, "CCW-rotated T blocks should match state 3 shape")


func test_i_piece_rotates_all_4_states() -> void:
	var piece = Piece.new("I", Vector2i(4, 10))

	for _i in range(4):
		assert_true(piece.try_rotate(_grid, true), "I-piece rotation should succeed in open space")

	assert_eq(piece.rotation_state, 0, "I-piece should return to state 0 after 4 CW rotations")


func test_s_piece_rotates_through_expected_cycle() -> void:
	var piece = Piece.new("S", Vector2i(4, 10))
	var expected_state_0: Array[Vector2i] = [Vector2i(3, 10), Vector2i(4, 10), Vector2i(4, 11), Vector2i(5, 11)]
	var expected_state_1: Array[Vector2i] = [Vector2i(4, 9), Vector2i(4, 10), Vector2i(3, 10), Vector2i(3, 11)]
	var expected_state_2: Array[Vector2i] = [Vector2i(5, 10), Vector2i(4, 10), Vector2i(4, 9), Vector2i(3, 9)]
	var expected_state_3: Array[Vector2i] = [Vector2i(4, 11), Vector2i(4, 10), Vector2i(5, 10), Vector2i(5, 9)]

	_assert_positions_match(piece.get_block_positions(), expected_state_0, "S state 0 should match expected shape")

	assert_true(piece.try_rotate(_grid, true), "S-piece rotation to state 1 should succeed")
	assert_eq(piece.rotation_state, 1, "S-piece rotation state should be 1")
	_assert_positions_match(piece.get_block_positions(), expected_state_1, "S state 1 should match expected shape")

	assert_true(piece.try_rotate(_grid, true), "S-piece rotation to state 2 should succeed")
	assert_eq(piece.rotation_state, 2, "S-piece rotation state should be 2")
	_assert_positions_match(piece.get_block_positions(), expected_state_2, "S state 2 should match expected shape")

	assert_true(piece.try_rotate(_grid, true), "S-piece rotation to state 3 should succeed")
	assert_eq(piece.rotation_state, 3, "S-piece rotation state should be 3")
	_assert_positions_match(piece.get_block_positions(), expected_state_3, "S state 3 should match expected shape")

	assert_true(piece.try_rotate(_grid, true), "S-piece fourth rotation should succeed")
	assert_eq(piece.rotation_state, 0, "S-piece should return to state 0 after 4 CW rotations")
	_assert_positions_match(piece.get_block_positions(), expected_state_0, "S-piece should return to original shape")


func test_z_piece_rotates_through_expected_cycle() -> void:
	var piece = Piece.new("Z", Vector2i(4, 10))
	var expected_state_0: Array[Vector2i] = [Vector2i(4, 10), Vector2i(5, 10), Vector2i(3, 11), Vector2i(4, 11)]
	var expected_state_1: Array[Vector2i] = [Vector2i(3, 9), Vector2i(3, 10), Vector2i(4, 10), Vector2i(4, 11)]
	var expected_state_2: Array[Vector2i] = [Vector2i(5, 9), Vector2i(4, 9), Vector2i(4, 10), Vector2i(3, 10)]
	var expected_state_3: Array[Vector2i] = [Vector2i(5, 11), Vector2i(5, 10), Vector2i(4, 10), Vector2i(4, 9)]

	_assert_positions_match(piece.get_block_positions(), expected_state_0, "Z state 0 should match expected shape")

	assert_true(piece.try_rotate(_grid, true), "Z-piece rotation to state 1 should succeed")
	assert_eq(piece.rotation_state, 1, "Z-piece rotation state should be 1")
	_assert_positions_match(piece.get_block_positions(), expected_state_1, "Z state 1 should match expected shape")

	assert_true(piece.try_rotate(_grid, true), "Z-piece rotation to state 2 should succeed")
	assert_eq(piece.rotation_state, 2, "Z-piece rotation state should be 2")
	_assert_positions_match(piece.get_block_positions(), expected_state_2, "Z state 2 should match expected shape")

	assert_true(piece.try_rotate(_grid, true), "Z-piece rotation to state 3 should succeed")
	assert_eq(piece.rotation_state, 3, "Z-piece rotation state should be 3")
	_assert_positions_match(piece.get_block_positions(), expected_state_3, "Z state 3 should match expected shape")

	assert_true(piece.try_rotate(_grid, true), "Z-piece fourth rotation should succeed")
	assert_eq(piece.rotation_state, 0, "Z-piece should return to state 0 after 4 CW rotations")
	_assert_positions_match(piece.get_block_positions(), expected_state_0, "Z-piece should return to original shape")


func test_o_piece_does_not_rotate() -> void:
	var piece = Piece.new("O", Vector2i(4, 10))
	var original_positions = piece.get_block_positions()

	assert_false(piece.try_rotate(_grid, true), "O-piece should not rotate")
	assert_eq(piece.rotation_state, 0, "O-piece rotation state should remain unchanged")
	_assert_positions_match(piece.get_block_positions(), original_positions, "O-piece blocks should remain unchanged")


func test_wall_kick_right_wall() -> void:
	var piece = Piece.new("T", Vector2i(9, 10))
	var rotated = piece.try_rotate(_grid, true)

	assert_true(rotated, "T-piece should rotate with wall kick near right wall")
	assert_eq(piece.rotation_state, 1, "Rotation state should be 0 -> 1")
	assert_eq(piece.position, Vector2i(8, 10), "Piece should kick left by 1 near right wall")


func test_wall_kick_left_wall() -> void:
	var piece = Piece.new("T", Vector2i(0, 10))
	piece.rotation_state = 1
	var rotated = piece.try_rotate(_grid, false)

	assert_true(rotated, "T-piece should rotate with wall kick near left wall")
	assert_eq(piece.rotation_state, 0, "Rotation state should be 1 -> 0")
	assert_eq(piece.position, Vector2i(1, 10), "Piece should kick right by 1 near left wall")


func test_i_piece_floor_kick() -> void:
	var piece = Piece.new("I", Vector2i(3, 22))
	var rotated = piece.try_rotate(_grid, true)

	assert_true(rotated, "I-piece should rotate with floor kick near bottom")
	assert_eq(piece.rotation_state, 1, "Rotation state should be 0 -> 1")
	assert_eq(piece.position, Vector2i(1, 21), "I-piece should use SRS floor kick offset")


func test_rotation_fails_when_trapped() -> void:
	var piece = Piece.new("T", Vector2i(4, 10))
	var to_state = 1
	var transition_key = "0>1"
	var kicks: Array = WallKickDataScript.KICKS_JLSTZ[transition_key]

	for kick in kicks:
		var candidate_pivot: Vector2i = piece.position + kick
		for block_pos in _positions_for("T", to_state, candidate_pivot):
			if block_pos.x >= 0 and block_pos.x < Grid.WIDTH and block_pos.y >= 0 and block_pos.y < Grid.HEIGHT:
				_grid.place_blocks([block_pos], "X")

	assert_false(piece.try_rotate(_grid, true), "Rotation should fail when all kick tests are blocked")
	assert_eq(piece.rotation_state, 0, "Rotation state should remain unchanged when rotation fails")
	assert_eq(piece.position, Vector2i(4, 10), "Position should remain unchanged when rotation fails")


func test_ghost_position_lands_at_bottom() -> void:
	var piece = Piece.new("T", Vector2i(4, 1))
	var ghost_position = piece.get_ghost_position(_grid)

	assert_eq(ghost_position, Vector2i(4, 23), "Ghost pivot should stop at lowest valid row")
	var ghost_blocks := piece.get_ghost_block_positions(_grid)
	var expected_blocks := _positions_for("T", 0, ghost_position)
	_assert_positions_match(ghost_blocks, expected_blocks, "Ghost block positions should match landing position")
