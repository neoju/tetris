class_name Piece
extends RefCounted

const TetrominoDataScript = preload("res://scripts/tetromino_data.gd")
const WallKickDataScript = preload("res://scripts/wall_kick_data.gd")

var type: String
var position: Vector2i
var rotation_state: int = 0
var last_action_was_rotation: bool = false


func _init(piece_type: String, spawn_pos: Vector2i) -> void:
	type = piece_type
	position = spawn_pos
	rotation_state = 0
	last_action_was_rotation = false


func get_block_positions() -> Array[Vector2i]:
	return _get_block_positions_for_state_at(rotation_state, position)


func try_rotate(grid, clockwise: bool) -> bool:
	if type == "O":
		return false

	var new_state := (rotation_state + (1 if clockwise else 3)) % 4
	var kick_table := WallKickDataScript.KICKS_I if type == "I" else WallKickDataScript.KICKS_JLSTZ
	var transition_key := str(rotation_state) + ">" + str(new_state)
	if not kick_table.has(transition_key):
		return false

	var kick_offsets: Array = kick_table[transition_key]
	for kick in kick_offsets:
		var test_position: Vector2i = position + kick
		var test_blocks := _get_block_positions_for_state_at(new_state, test_position)
		if grid.is_valid_position(test_blocks):
			rotation_state = new_state
			position = test_position
			last_action_was_rotation = true
			return true

	return false


func try_move(grid, offset: Vector2i) -> bool:
	var new_position := position + offset
	var new_block_positions := _get_block_positions_for_state_at(rotation_state, new_position)
	if not grid.is_valid_position(new_block_positions):
		return false

	position = new_position
	last_action_was_rotation = false
	return true


func get_ghost_position(grid) -> Vector2i:
	var ghost_position := position
	while true:
		var next_position := ghost_position + Vector2i(0, 1)
		var next_blocks := _get_block_positions_for_state_at(rotation_state, next_position)
		if not grid.is_valid_position(next_blocks):
			break
		ghost_position = next_position

	return ghost_position


func get_ghost_block_positions(grid) -> Array[Vector2i]:
	var ghost_position := get_ghost_position(grid)
	return _get_block_positions_for_state_at(rotation_state, ghost_position)


func duplicate_piece():
	var copy = get_script().new(type, position)
	copy.rotation_state = rotation_state
	copy.last_action_was_rotation = last_action_was_rotation
	return copy


func _get_block_positions_for_state_at(state: int, pivot: Vector2i) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var offsets: Array = TetrominoDataScript.SHAPES[type][state]
	for offset in offsets:
		positions.append(pivot + offset)
	return positions
