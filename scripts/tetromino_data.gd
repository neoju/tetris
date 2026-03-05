class_name TetrominoData
# No extends needed - pure static data class with constants only

# Tetromino piece types
const PIECE_TYPES := ["I", "J", "L", "O", "S", "T", "Z"]

# Colors per piece type (Tetris Guideline standard)
const COLORS := {
	"I": Color("#00F0F0"),  # Cyan
	"J": Color("#0000FF"),  # Blue
	"L": Color("#FFA500"),  # Orange
	"O": Color("#FFFF00"),  # Yellow
	"S": Color("#00FF00"),  # Green
	"T": Color("#800080"),  # Purple
	"Z": Color("#FF0000"),  # Red
}

# Spawn positions (grid coordinates) - Row 1 is in buffer zone (above visible area)
# Column centering: I/O centered at 3, J/L/S/T/Z left-centered at 3
const SPAWN_POSITIONS := {
	"I": Vector2i(3, 1),
	"J": Vector2i(3, 1),
	"L": Vector2i(3, 1),
	"O": Vector2i(3, 1),  # O spawns at 3, its center is at 4 (width 2)
	"S": Vector2i(3, 1),
	"T": Vector2i(3, 1),
	"Z": Vector2i(3, 1),
}

# SHAPES: Array of 4 rotation states per piece type
# Each rotation state is an Array of Vector2i offsets relative to the pivot
# Coordinate system: X+ = right, Y+ = down (Godot convention)
# Note: SRS uses Y-up, so SRS wiki values are negated for Y
const SHAPES := {
	# I-piece: 4 states (horizontal, vertical, horizontal, vertical)
	"I": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],  # 0: horizontal
		[Vector2i(1, 0), Vector2i(1, -1), Vector2i(1, 1), Vector2i(1, 2)],  # 1: vertical
		[Vector2i(2, 0), Vector2i(1, 0), Vector2i(0, 0), Vector2i(-1, 0)], # 2: horizontal (mirrored)
		[Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(0, 2)],  # 3: vertical (mirrored)
	],
	
	# J-piece: 4 states
	"J": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, -1)], # 0
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, -1)], # 1
		[Vector2i(1, 0), Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 1)], # 2
		[Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, 1)], # 3
	],
	
	# L-piece: 4 states
	"L": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)], # 0
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], # 1
		[Vector2i(1, 0), Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1)], # 2
		[Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, -1)], # 3
	],
	
	# O-piece: 1 state (all 4 states are identical)
	"O": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # 0-3: all same
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # 1 (unused)
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # 2 (unused)
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # 3 (unused)
	],
	
	# S-piece: 4 states (SRS standard - green)
	"S": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], # 0: S-shape
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], # 1
		[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(-2, -1)], # 2
		[Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0)], # 3
	],
	
	# T-piece: 4 states
	"T": [
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1)], # 0
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)], # 1
		[Vector2i(1, 0), Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, 1)], # 2
		[Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, 0)], # 3
	],
	
	# Z-piece: 4 states (SRS standard - red)
	"Z": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1)], # 0: Z-shape
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], # 1
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(2, -1)], # 2
		[Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, -1)], # 3
	],
}
