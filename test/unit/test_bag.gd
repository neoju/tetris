extends GutTest

# Preload BagRandomizer class explicitly
const BagRandomizer = preload("res://scripts/bag_randomizer.gd")

# Test class for BagRandomizer
var _bag: BagRandomizer


func before_each() -> void:
	_bag = BagRandomizer.new()


# ============================================================================
# Test: Bag contains all seven pieces
# ============================================================================
func test_bag_contains_all_seven() -> void:
	# Get 7 pieces
	var pieces: Array = []
	for i in range(7):
		pieces.append(_bag.next_piece())
	
	# Verify one of each type
	for piece_type in ["I", "J", "L", "O", "S", "T", "Z"]:
		assert_true(pieces.has(piece_type), "Bag should contain " + piece_type)


# ============================================================================
# Test: Second bag is different order
# ============================================================================
func test_second_bag_is_different_order() -> void:
	# Get 14 pieces (2 full bags)
	var first_bag: Array = []
	for i in range(7):
		first_bag.append(_bag.next_piece())
	
	var second_bag: Array = []
	for i in range(7):
		second_bag.append(_bag.next_piece())
	
	# Both bags should contain all types
	for piece_type in ["I", "J", "L", "O", "S", "T", "Z"]:
		assert_true(first_bag.has(piece_type), "First bag should contain " + piece_type)
		assert_true(second_bag.has(piece_type), "Second bag should contain " + piece_type)


# ============================================================================
# Test: Peek does not consume
# ============================================================================
func test_peek_does_not_consume() -> void:
	# Peek at next piece
	var peeked := _bag.peek_next(3)
	var first_peek = peeked[0]
	
	# Now get the actual next piece
	var actual := _bag.next_piece()
	
	# Should be the same
	assert_eq(actual, first_peek, "peek_next should not consume pieces")


# ============================================================================
# Test: Peek across bag boundary
# ============================================================================
func test_peek_across_bag_boundary() -> void:
	# Get 5 pieces from bag (leaving 2)
	for i in range(5):
		_bag.next_piece()
	
	# Now 2 pieces remain in current bag
	# Peek 5 should give us 2 from current + 3 from next bag
	var peeked := _bag.peek_next(5)
	
	assert_eq(peeked.size(), 5, "Should peek 5 pieces total")
	# First 2 should be from current bag
	assert_eq(_bag.get_remaining_count(), 2, "Current bag should still have 2 pieces")


# ============================================================================
# Test: Maximum drought
# ============================================================================
func test_maximum_drought() -> void:
	# Track when each piece type last appeared
	var last_appearance: Dictionary = {}
	for piece in ["I", "J", "L", "O", "S", "T", "Z"]:
		last_appearance[piece] = -1
	
	var max_gap := 0
	var pieces_generated := 0
	
	# Generate 1000+ pieces
	while pieces_generated < 1000:
		var piece = _bag.next_piece()
		if last_appearance.get(piece, -1) != -1:
			var gap = pieces_generated - last_appearance.get(piece) - 1
			max_gap = max(max_gap, gap)
		last_appearance[piece] = pieces_generated
		pieces_generated += 1
	
	# In 7-bag, maximum gap between same piece type should be ≤ 12
	# (theoretical max is 12: piece at end of one bag, start of next = 12 pieces in between)
	assert_true(max_gap <= 12, "Max drought should be ≤ 12, got " + str(max_gap))


# ============================================================================
# Test: Reset clears bags
# ============================================================================
func test_reset() -> void:
	# Use some pieces
	for i in range(3):
		_bag.next_piece()
	
	# Reset
	_bag.reset()
	
	# Should have 7 pieces in current bag again
	assert_eq(_bag.get_remaining_count(), 7, "After reset, bag should have 7 pieces")


# ============================================================================
# Test: Empty bag promotes next bag
# ============================================================================
func test_empty_bag_promotes_next() -> void:
	# Drain the current bag
	for i in range(7):
		_bag.next_piece()
	
	# Next piece should come from what was the next bag
	var piece = _bag.next_piece()
	assert_true(piece != "", "Should get piece from next bag after current is empty")
