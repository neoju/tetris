class_name WallKickData
# Pure static data class - no extends needed

# =============================================================================
# SRS WALL KICK DATA
# =============================================================================
# Source: https://tetris.wiki/Super_Rotation_System#Wall_Kicks
#
# Coordinate Convention:
# - Godot uses Y-positive = DOWN (screen coordinates)
# - tetris.wiki uses Y-positive = UP (mathematical coordinates)
# - Therefore: negate ALL Y values from wiki tables
#
# Rotation States: 0=0°, 1=90° CW, 2=180°, 3=270° CW
# Transitions: "0>1" means rotating from state 0 to state 1
# Each transition has 5 test offsets to try in order
# =============================================================================

# JLSTZ Wall Kicks (same for J, L, S, T, Z pieces)
# Format: transition_string -> Array of 5 Vector2i offsets
const KICKS_JLSTZ := {
	# 0° → 90° CW
	"0>1": [
		Vector2i(0, 0),   # Test 1
		Vector2i(-1, 0),  # Test 2
		Vector2i(-1, -1), # Test 3 (wiki: -1,+1 → negated: -1,-1)
		Vector2i(0, 2),   # Test 4 (wiki: 0,-2 → negated: 0,2)
		Vector2i(-1, 2),  # Test 5 (wiki: -1,-2 → negated: -1,2)
	],
	
	# 90° CW → 0°
	"1>0": [
		Vector2i(0, 0),   # Test 1
		Vector2i(1, 0),   # Test 2
		Vector2i(1, 1),   # Test 3 (wiki: 1,-1 → negated: 1,1)
		Vector2i(0, -2),  # Test 4 (wiki: 0,2 → negated: 0,-2)
		Vector2i(1, -2),  # Test 5 (wiki: 1,2 → negated: 1,-2)
	],
	
	# 90° CW → 180°
	"1>2": [
		Vector2i(0, 0),   # Test 1
		Vector2i(1, 0),   # Test 2
		Vector2i(1, 1),   # Test 3 (wiki: 1,-1 → negated: 1,1)
		Vector2i(0, -2),  # Test 4 (wiki: 0,2 → negated: 0,-2)
		Vector2i(1, -2),  # Test 5 (wiki: 1,2 → negated: 1,-2)
	],
	
	# 180° → 90° CW
	"2>1": [
		Vector2i(0, 0),   # Test 1
		Vector2i(-1, 0),  # Test 2
		Vector2i(-1, -1), # Test 3 (wiki: -1,+1 → negated: -1,-1)
		Vector2i(0, 2),   # Test 4 (wiki: 0,-2 → negated: 0,2)
		Vector2i(-1, 2),  # Test 5 (wiki: -1,-2 → negated: -1,2)
	],
	
	# 180° → 270° CW
	"2>3": [
		Vector2i(0, 0),   # Test 1
		Vector2i(1, 0),   # Test 2
		Vector2i(1, -1),  # Test 3 (wiki: 1,+1 → negated: 1,-1)
		Vector2i(0, 2),   # Test 4 (wiki: 0,-2 → negated: 0,2)
		Vector2i(1, 2),   # Test 5 (wiki: 1,-2 → negated: 1,2)
	],
	
	# 270° CW → 180°
	"3>2": [
		Vector2i(0, 0),   # Test 1
		Vector2i(-1, 0),  # Test 2
		Vector2i(-1, 1),  # Test 3 (wiki: -1,-1 → negated: -1,1)
		Vector2i(0, -2),  # Test 4 (wiki: 0,2 → negated: 0,-2)
		Vector2i(-1, -2), # Test 5 (wiki: -1,2 → negated: -1,-2)
	],
	
	# 270° CW → 0° (360°)
	"3>0": [
		Vector2i(0, 0),   # Test 1
		Vector2i(1, 0),   # Test 2
		Vector2i(1, -1),  # Test 3 (wiki: 1,+1 → negated: 1,-1)
		Vector2i(0, 2),   # Test 4 (wiki: 0,-2 → negated: 0,2)
		Vector2i(1, 2),   # Test 5 (wiki: 1,-2 → negated: 1,2)
	],
	
	# 0° (360°) → 270° CW
	"0>3": [
		Vector2i(0, 0),   # Test 1
		Vector2i(-1, 0),  # Test 2
		Vector2i(-1, 1),  # Test 3 (wiki: -1,-1 → negated: -1,1)
		Vector2i(0, -2),  # Test 4 (wiki: 0,2 → negated: 0,-2)
		Vector2i(-1, -2), # Test 5 (wiki: -1,2 → negated: -1,-2)
	],
}

# I-piece Wall Kicks (different from JLSTZ)
const KICKS_I := {
	# 0° → 90° CW
	"0>1": [
		Vector2i(0, 0),   # Test 1
		Vector2i(-2, 0),  # Test 2
		Vector2i(1, 0),   # Test 3
		Vector2i(-2, -1), # Test 4 (wiki: -2,+1 → negated)
		Vector2i(1, 2),   # Test 5 (wiki: 1,-2 → negated)
	],
	
	# 90° CW → 0°
	"1>0": [
		Vector2i(0, 0),   # Test 1
		Vector2i(2, 0),   # Test 2
		Vector2i(-1, 0),  # Test 3
		Vector2i(2, 1),   # Test 4 (wiki: 2,-1 → negated)
		Vector2i(-1, -2), # Test 5 (wiki: -1,2 → negated)
	],
	
	# 90° CW → 180°
	"1>2": [
		Vector2i(0, 0),   # Test 1
		Vector2i(-1, 0),  # Test 2
		Vector2i(2, 0),   # Test 3
		Vector2i(-1, 2),  # Test 4 (wiki: -1,-2 → negated)
		Vector2i(2, -1),  # Test 5 (wiki: 2,+1 → negated)
	],
	
	# 180° → 90° CW
	"2>1": [
		Vector2i(0, 0),   # Test 1
		Vector2i(1, 0),   # Test 2
		Vector2i(-2, 0),  # Test 3
		Vector2i(1, -2),  # Test 4 (wiki: 1,+2 → negated)
		Vector2i(-2, 1),  # Test 5 (wiki: -2,-1 → negated)
	],
	
	# 180° → 270° CW
	"2>3": [
		Vector2i(0, 0),   # Test 1
		Vector2i(2, 0),   # Test 2
		Vector2i(-1, 0),  # Test 3
		Vector2i(2, -1),  # Test 4 (wiki: 2,+1 → negated)
		Vector2i(-1, 2),  # Test 5 (wiki: -1,-2 → negated)
	],
	
	# 270° CW → 180°
	"3>2": [
		Vector2i(0, 0),   # Test 1
		Vector2i(-1, 0),  # Test 2
		Vector2i(2, 0),   # Test 3
		Vector2i(-1, -2), # Test 4 (wiki: -1,+2 → negated)
		Vector2i(2, 1),   # Test 5 (wiki: 2,-1 → negated)
	],
	
	# 270° CW → 0° (360°)
	"3>0": [
		Vector2i(0, 0),   # Test 1
		Vector2i(1, 0),   # Test 2
		Vector2i(-2, 0),  # Test 3
		Vector2i(1, 2),   # Test 4 (wiki: 1,-2 → negated)
		Vector2i(-2, -1), # Test 5 (wiki: -2,+1 → negated)
	],
	
	# 0° (360°) → 270° CW
	"0>3": [
		Vector2i(0, 0),   # Test 1
		Vector2i(-1, 0),  # Test 2
		Vector2i(2, 0),   # Test 3
		Vector2i(-1, -2), # Test 4 (wiki: -1,+2 → negated)
		Vector2i(2, 1),   # Test 5 (wiki: 2,-1 → negated)
	],
}

# Helper function to get kick data for a piece type
# Returns the appropriate kick table based on piece type
static func get_kick_table(piece_type: String) -> Dictionary:
	if piece_type == "I":
		return KICKS_I
	else:
		return KICKS_JLSTZ

# Helper function to get kick offset for a rotation transition
# piece_type: "I" or "J"/"L"/"S"/"T"/"Z"
# from_state: 0-3
# to_state: 0-3
# test_index: 0-4 (which of the 5 tests to try)
static func get_kick_offset(piece_type: String, from_state: int, to_state: int, test_index: int) -> Vector2i:
	var table = get_kick_table(piece_type)
	var key = str(from_state) + ">" + str(to_state)
	var kicks = table[key]
	return kicks[test_index]
