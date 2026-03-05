class_name GameLogic
extends RefCounted

const GridScript = preload("res://scripts/grid.gd")
const PieceScript = preload("res://scripts/piece.gd")
const BagScript = preload("res://scripts/bag_randomizer.gd")
const ScoringScript = preload("res://scripts/scoring.gd")
const LockDelayScript = preload("res://scripts/lock_delay.gd")
const InputHandlerScript = preload("res://scripts/input_handler.gd")
const TetrominoDataScript = preload("res://scripts/tetromino_data.gd")

var grid: Grid
var active_piece: Piece
var bag: BagRandomizer
var scoring: Scoring
var lock_delay: LockDelay
var input_handler: InputHandler
var hold_piece_type: String = ""
var can_hold: bool = true
var gravity_accumulator: float = 0.0
var game_active: bool = false
var soft_drop_distance: int = 0

var _lock_hard_drop_distance: int = 0
var _lock_was_hard_drop: bool = false


func _init() -> void:
	grid = GridScript.new()
	bag = BagScript.new()
	scoring = ScoringScript.new()
	lock_delay = LockDelayScript.new()
	input_handler = InputHandlerScript.new()
	active_piece = null


func start_game() -> void:
	grid.reset()
	scoring.reset()
	bag.reset()
	lock_delay.reset()
	input_handler.reset()
	hold_piece_type = ""
	can_hold = true
	gravity_accumulator = 0.0
	soft_drop_distance = 0
	_lock_hard_drop_distance = 0
	_lock_was_hard_drop = false
	game_active = true
	spawn_piece(bag.next_piece())


func update(delta: float) -> Dictionary:
	if not game_active:
		return {}

	var events := {
		"lines_cleared": 0,
		"score_added": 0,
		"game_over": false,
		"piece_locked": false,
		"hold_swapped": false,
		"level_up": false,
		"moved": false,
		"rotated": false,
		"hard_dropped": false,
		"soft_dropped": false
	}

	if active_piece == null:
		return events

	var actions: Dictionary = input_handler.process_input(delta)

	if actions["hold"] and can_hold:
		hold()
		events["hold_swapped"] = true
		if not game_active:
			events["game_over"] = true
			return events

	if active_piece == null:
		return events

	if actions["rotate_cw"]:
		var was_on_surface_before_rotate := _is_on_surface()
		if active_piece.try_rotate(grid, true):
			events["rotated"] = true
			if was_on_surface_before_rotate:
				lock_delay.reset_on_move()

	if actions["rotate_ccw"]:
		var was_on_surface_before_rotate_ccw := _is_on_surface()
		if active_piece.try_rotate(grid, false):
			events["rotated"] = true
			if was_on_surface_before_rotate_ccw:
				lock_delay.reset_on_move()

	if actions["move"] != Vector2i.ZERO:
		var was_on_surface_before_move := _is_on_surface()
		if active_piece.try_move(grid, actions["move"]):
			events["moved"] = true
			if was_on_surface_before_move:
				lock_delay.reset_on_move()

	if actions["hard_drop"]:
		var hard_drop_result := hard_drop()
		_lock_hard_drop_distance = hard_drop_result["distance"]
		_lock_was_hard_drop = true
		events["hard_dropped"] = true
		var lock_events := _lock_piece()
		for key in lock_events.keys():
			events[key] = lock_events[key]
		if not game_active:
			events["game_over"] = true
		return events

	var gravity_speed := get_gravity_speed(scoring.level)
	if actions["soft_drop"]:
		gravity_speed = maxf(gravity_speed, 20.0)

	gravity_accumulator += gravity_speed * delta
	while gravity_accumulator >= 1.0 and active_piece != null:
		if active_piece.try_move(grid, Vector2i.DOWN):
			gravity_accumulator -= 1.0
			if actions["soft_drop"]:
				soft_drop_distance += 1
				events["soft_dropped"] = true
		else:
			gravity_accumulator = 0.0
			break

	if active_piece == null:
		return events

	var on_surface := _is_on_surface()
	if on_surface and not lock_delay.is_active():
		lock_delay.start()
	elif not on_surface and lock_delay.is_active():
		lock_delay.cancel()

	if lock_delay.is_active() and lock_delay.update(delta):
		var lock_events_gravity := _lock_piece()
		for key2 in lock_events_gravity.keys():
			events[key2] = lock_events_gravity[key2]
		if not game_active:
			events["game_over"] = true

	return events


func hold() -> void:
	if active_piece == null:
		return

	if not can_hold:
		return

	var current_type := active_piece.type
	if hold_piece_type == "":
		hold_piece_type = current_type
		spawn_piece(bag.next_piece())
	else:
		var swap_type := hold_piece_type
		hold_piece_type = current_type
		spawn_piece(swap_type)

	can_hold = false
	lock_delay.cancel()


func hard_drop() -> Dictionary:
	if active_piece == null:
		return {"distance": 0}

	var ghost_position := active_piece.get_ghost_position(grid)
	var distance := ghost_position.y - active_piece.position.y
	active_piece.position = ghost_position
	return {"distance": max(distance, 0)}


func spawn_piece(type: String) -> void:
	if type == "":
		active_piece = null
		game_active = false
		return

	active_piece = PieceScript.new(type, TetrominoDataScript.SPAWN_POSITIONS[type])
	if not grid.is_valid_position(active_piece.get_block_positions()):
		game_active = false

	gravity_accumulator = 0.0
	soft_drop_distance = 0
	_lock_hard_drop_distance = 0
	_lock_was_hard_drop = false


func get_gravity_speed(level: int) -> float:
	var time_per_cell = pow(0.8 - ((level - 1) * 0.007), level - 1)
	return 1.0 / time_per_cell


func get_next_pieces(count: int) -> Array:
	return bag.peek_next(count)


func get_ghost_blocks() -> Array[Vector2i]:
	if active_piece == null:
		return []
	return active_piece.get_ghost_block_positions(grid)


func reset() -> void:
	start_game()


func _is_on_surface() -> bool:
	if active_piece == null:
		return false

	var piece_one_below: Array[Vector2i] = []
	for block in active_piece.get_block_positions():
		piece_one_below.append(block + Vector2i.DOWN)
	return not grid.is_valid_position(piece_one_below)


func _lock_piece() -> Dictionary:
	var events := {
		"lines_cleared": 0,
		"score_added": 0,
		"piece_locked": false,
		"level_up": false
	}

	if active_piece == null:
		return events

	var level_before := scoring.level
	var score_before := scoring.score

	grid.place_blocks(active_piece.get_block_positions(), active_piece.type)
	var tspin := scoring.detect_tspin(
		grid,
		active_piece.type,
		active_piece.position,
		active_piece.rotation_state,
		active_piece.last_action_was_rotation
	)

	var lines := grid.clear_full_lines()
	var perfect_clear := grid.is_perfect_clear()
	var drop_distance_total := _lock_hard_drop_distance + soft_drop_distance
	scoring.process_placement(
		lines,
		tspin["is_tspin"],
		tspin["is_mini"],
		perfect_clear,
		drop_distance_total,
		_lock_was_hard_drop
	)

	events["lines_cleared"] = lines
	events["score_added"] = scoring.score - score_before
	events["piece_locked"] = true
	events["level_up"] = scoring.level > level_before

	soft_drop_distance = 0
	gravity_accumulator = 0.0
	lock_delay.reset()
	can_hold = true

	spawn_piece(bag.next_piece())
	return events
