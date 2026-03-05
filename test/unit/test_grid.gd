extends GutTest

# Preload Grid class explicitly
const Grid = preload("res://scripts/grid.gd")

# Test class for Grid logic
# Run with: godot -d -s --path . addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -ginclude_subdirs -gexit

var _grid: Grid


func before_each() -> void:
	_grid = Grid.new()


# ============================================================================
# Test: Empty grid allows placement
# ============================================================================
func test_empty_grid_allows_placement() -> void:
	var positions := [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	]
	assert_true(_grid.is_valid_position(positions), "Empty grid should allow any valid position")


# ============================================================================
# Test: Collision with left wall
# ============================================================================
func test_collision_with_left_wall() -> void:
	# Piece at x=-1 should be invalid
	var positions := [Vector2i(-1, 0)]
	assert_false(_grid.is_valid_position(positions), "Position at x=-1 should be invalid")


# ============================================================================
# Test: Collision with right wall
# ============================================================================
func test_collision_with_right_wall() -> void:
	# Piece at x=10 should be invalid (grid width is 10, indices 0-9)
	var positions := [Vector2i(10, 0)]
	assert_false(_grid.is_valid_position(positions), "Position at x=10 should be invalid")


# ============================================================================
# Test: Collision with floor
# ============================================================================
func test_collision_with_floor() -> void:
	# Piece at y=24 should be invalid (grid height is 24, indices 0-23)
	var positions := [Vector2i(0, 24)]
	assert_false(_grid.is_valid_position(positions), "Position at y=24 should be invalid")


# ============================================================================
# Test: Collision with existing blocks
# ============================================================================
func test_collision_with_existing_blocks() -> void:
	# Place some blocks first
	var existing_blocks := [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	]
	_grid.place_blocks(existing_blocks, "I")
	
	# Try to place at overlapping position
	var overlapping := [Vector2i(2, 0)]
	assert_false(_grid.is_valid_position(overlapping), "Should not be able to place on existing block")


# ============================================================================
# Test: Single line clear
# ============================================================================
func test_single_line_clear() -> void:
	# Fill row 23 completely
	for col in range(Grid.WIDTH):
		_grid.place_blocks([Vector2i(col, 23)], "I")
	
	# Clear lines
	var cleared := _grid.clear_full_lines()
	
	assert_eq(cleared, 1, "Should clear exactly 1 line")
	assert_eq(_grid.get_filled_count_in_row(23), 0, "Row 23 should be empty after clear")


# ============================================================================
# Test: Double line clear
# ============================================================================
func test_double_line_clear() -> void:
	# Fill rows 22 and 23
	for row in [22, 23]:
		for col in range(Grid.WIDTH):
			_grid.place_blocks([Vector2i(col, row)], "I")
	
	var cleared := _grid.clear_full_lines()
	assert_eq(cleared, 2, "Should clear exactly 2 lines")


# ============================================================================
# Test: Triple line clear
# ============================================================================
func test_triple_line_clear() -> void:
	# Fill rows 21, 22, and 23
	for row in [21, 22, 23]:
		for col in range(Grid.WIDTH):
			_grid.place_blocks([Vector2i(col, row)], "I")
	
	var cleared := _grid.clear_full_lines()
	assert_eq(cleared, 3, "Should clear exactly 3 lines")


# ============================================================================
# Test: Tetris line clear (4 lines)
# ============================================================================
func test_tetris_line_clear() -> void:
	# Fill rows 20, 21, 22, and 23
	for row in [20, 21, 22, 23]:
		for col in range(Grid.WIDTH):
			_grid.place_blocks([Vector2i(col, row)], "I")
	
	var cleared := _grid.clear_full_lines()
	assert_eq(cleared, 4, "Should clear exactly 4 lines (Tetris)")


# ============================================================================
# Test: Partial line does not clear
# ============================================================================
func test_partial_line_no_clear() -> void:
	# Fill row 23 with 9 blocks (leave a gap at col 0)
	for col in range(1, Grid.WIDTH):
		_grid.place_blocks([Vector2i(col, 23)], "I")
	
	var cleared := _grid.clear_full_lines()
	assert_eq(cleared, 0, "Should not clear incomplete line")
	assert_eq(_grid.get_filled_count_in_row(23), 9, "Row 23 should still have 9 blocks")


# ============================================================================
# Test: Perfect clear detection
# ============================================================================
func test_perfect_clear() -> void:
	# Fill some blocks
	for col in range(Grid.WIDTH):
		_grid.place_blocks([Vector2i(col, 23)], "I")
	
	# Clear all lines
	_grid.clear_full_lines()
	
	assert_true(_grid.is_perfect_clear(), "Grid should be empty after clearing all blocks")


# ============================================================================
# Test: Non-perfect clear detection
# ============================================================================
func test_non_perfect_clear() -> void:
	# Fill bottom row (will be cleared)
	for col in range(Grid.WIDTH):
		_grid.place_blocks([Vector2i(col, 23)], "I")
	
	# Fill row 20 with a GAP at column 0 (will NOT be cleared)
	for col in range(1, Grid.WIDTH):
		_grid.place_blocks([Vector2i(col, 20)], "T")
	
	# Clear bottom row(s)
	_grid.clear_full_lines()
	
	# Row 20 had a gap, so it wasn't cleared - blocks should remain
	assert_false(_grid.is_perfect_clear(), "Grid should not be empty - row 20 had gap and remains")


# ============================================================================
# Test: is_empty_at function
# ============================================================================
func test_is_empty_at() -> void:
	assert_true(_grid.is_empty_at(Vector2i(0, 0)), "Empty cell should return true")
	assert_true(_grid.is_empty_at(Vector2i(9, 23)), "Empty cell at edge should return true")
	
	# Place a block
	_grid.place_blocks([Vector2i(5, 10)], "T")
	assert_false(_grid.is_empty_at(Vector2i(5, 10)), "Occupied cell should return false")


# ============================================================================
# Test: get_cell function
# void get_cell
# ============================================================================
func test_get_cell() -> void:
	assert_eq(_grid.get_cell(Vector2i(0, 0)), "", "Empty cell should return empty string")
	
	_grid.place_blocks([Vector2i(3, 5)], "L")
	assert_eq(_grid.get_cell(Vector2i(3, 5)), "L", "Should return piece type")


# ============================================================================
# Test: Out of bounds get_cell returns empty
# ============================================================================
func test_get_cell_out_of_bounds() -> void:
	assert_eq(_grid.get_cell(Vector2i(-1, 0)), "", "Out of bounds should return empty")
	assert_eq(_grid.get_cell(Vector2i(0, 24)), "", "Out of bounds should return empty")
	assert_eq(_grid.get_cell(Vector2i(10, 0)), "", "Out of bounds should return empty")


# ============================================================================
# Test: Grid reset
# ============================================================================
func test_grid_reset() -> void:
	# Place some blocks
	for col in range(Grid.WIDTH):
		_grid.place_blocks([Vector2i(col, 23)], "I")
	
	# Reset
	_grid.reset()
	
	assert_true(_grid.is_perfect_clear(), "Grid should be empty after reset")
