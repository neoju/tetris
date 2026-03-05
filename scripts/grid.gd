class_name Grid
extends RefCounted

# =============================================================================
# GRID - Pure logic class for Tetris playfield
# =============================================================================
# Coordinate system: (0,0) = top-left, X+ = right, Y+ = down
# Row 0-3 = hidden spawn buffer, Row 4-23 = visible playfield
# =============================================================================

# Grid dimensions
const WIDTH := 10
const HEIGHT := 24        # 4 buffer + 20 visible
const VISIBLE_HEIGHT := 20
const BUFFER_ROWS := 4

# Cell storage - 2D array: cells[row][col] = "" (empty) or piece type string
var cells: Array = []

func _init() -> void:
	reset()

# Reset the grid to empty state
func reset() -> void:
	cells = []
	for row in range(HEIGHT):
		cells.append([])
		for col in range(WIDTH):
			cells[row].append("")

# Check if a position is within grid bounds
func _is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < WIDTH and pos.y >= 0 and pos.y < HEIGHT

# Check if a cell is empty (within bounds and no block)
func is_empty_at(pos: Vector2i) -> bool:
	if not _is_in_bounds(pos):
		return false
	return cells[pos.y][pos.x] == ""

# Get the content of a cell
func get_cell(pos: Vector2i) -> String:
	if not _is_in_bounds(pos):
		return ""
	return cells[pos.y][pos.x]

# Check if all block positions are valid for placement
# block_positions: Array of Vector2i (absolute grid positions)
func is_valid_position(block_positions: Array) -> bool:
	for pos in block_positions:
		# Out of bounds check
		if not _is_in_bounds(pos):
			return false
		# Collision with existing block check
		if cells[pos.y][pos.x] != "":
			return false
	return true

# Place blocks into the grid
# block_positions: Array of Vector2i (absolute grid positions)
# piece_type: String identifying the piece type (for color lookup)
func place_blocks(block_positions: Array, piece_type: String) -> void:
	for pos in block_positions:
		if _is_in_bounds(pos):
			cells[pos.y][pos.x] = piece_type

# Clear full lines from the bottom up
# Returns the number of lines cleared
func clear_full_lines() -> int:
	var lines_cleared := 0
	
	# Scan from bottom (row 23) to top (row 0)
	# Use while loop so we can re-check same index after shifting
	var row := HEIGHT - 1
	while row >= 0:
		if _is_line_full(row):
			_remove_line(row)
			lines_cleared += 1
			# Don't decrement row - after removing a line, the row above 
			# has shifted down into our current position, so check again
		else:
			row -= 1
	
	return lines_cleared


# Find all rows that are completely full (without clearing them)
# Returns row indices in bottom-to-top order
func find_full_lines() -> Array[int]:
	var full_rows: Array[int] = []
	for row in range(HEIGHT - 1, -1, -1):
		if _is_line_full(row):
			full_rows.append(row)
	return full_rows


# Get a copy of a row's cell data
func get_row_data(row: int) -> Array:
	var data: Array = []
	for col in range(WIDTH):
		data.append(cells[row][col])
	return data


# Check if clearing the given full rows would result in a perfect clear
func would_be_perfect_clear(full_rows: Array[int]) -> bool:
	for row in range(HEIGHT):
		if row in full_rows:
			continue
		for col in range(WIDTH):
			if cells[row][col] != "":
				return false
	return true


# Check if a specific row is completely filled
func _is_line_full(row: int) -> bool:
	for col in range(WIDTH):
		if cells[row][col] == "":
			return false
	return true

# Remove a line and shift everything above it down
func _remove_line(row_to_remove: int) -> void:
	# Shift all rows above the removed line down by 1
	for row in range(row_to_remove, 0, -1):
		for col in range(WIDTH):
			cells[row][col] = cells[row - 1][col]
	
	# Clear the top row
	for col in range(WIDTH):
		cells[0][col] = ""

# Check if the entire grid is empty (for perfect clear detection)
func is_perfect_clear() -> bool:
	for row in range(HEIGHT):
		for col in range(WIDTH):
			if cells[row][col] != "":
				return false
	return true

# Get the number of filled cells in a row (for debugging/testing)
func get_filled_count_in_row(row: int) -> int:
	var count := 0
	for col in range(WIDTH):
		if cells[row][col] != "":
			count += 1
	return count

# Print grid for debugging
func debug_print() -> String:
	var output := ""
	# Only show visible rows (buffer rows are hidden)
	for row in range(BUFFER_ROWS, HEIGHT):
		var line := ""
		for col in range(WIDTH):
			if cells[row][col] == "":
				line += ". "
			else:
				line += cells[row][col] + " "
		output += line + "\n"
	return output
