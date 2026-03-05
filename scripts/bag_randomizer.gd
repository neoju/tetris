class_name BagRandomizer
extends RefCounted

# =============================================================================
# 7-BAG RANDOMIZER - Tetris Guideline compliant piece randomizer
# =============================================================================
# Algorithm: https://tetris.wiki/Random_Generator
# Uses 7-bag system where all 7 pieces appear exactly once per bag
# =============================================================================

# All 7 tetromino types
const PIECE_TYPES := ["I", "J", "L", "O", "S", "T", "Z"]

# Current bag containing pieces to deal
var _bag: Array = []

# Next bag (pre-generated for preview)
var _next_bag: Array = []

func _init() -> void:
	_generate_bag()
	_bag = _next_bag.duplicate()
	_generate_bag()  # Pre-generate next bag


# Generate a new bag with all 7 pieces in random order
func _generate_bag() -> void:
	_next_bag = PIECE_TYPES.duplicate()
	_next_bag.shuffle()


# Get the next piece from the current bag
# Automatically refills when current bag is empty
func next_piece() -> String:
	# If current bag is empty, promote next bag and generate new one
	if _bag.is_empty():
		_bag = _next_bag.duplicate()
		_generate_bag()
	
	if _bag.is_empty():
		return ""
	
	return _bag.pop_front()


# Peek at upcoming pieces without consuming them
# Handles bag boundary correctly
func peek_next(count: int) -> Array:
	var result: Array = []
	
	# Combine current bag and next bag for peeking
	var combined: Array = _bag.duplicate()
	if not _next_bag.is_empty():
		combined.append_array(_next_bag)
	
	# Take first 'count' pieces
	for i in range(min(count, combined.size())):
		result.append(combined[i])
	
	return result


# Get next piece without consuming (peek exactly one)
func peek() -> String:
	var result = peek_next(1)
	if result.is_empty():
		return ""
	return result[0]


# Reset the randomizer (start fresh with new bags)
func reset() -> void:
	_bag.clear()
	_next_bag.clear()
	_generate_bag()
	_bag = _next_bag.duplicate()
	_generate_bag()


# Get count of remaining pieces in current bag
func get_remaining_count() -> int:
	return _bag.size()
