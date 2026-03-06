extends Node2D

## Manages all particle effects for the game board: line clear bursts,
## lock sparks, hard drop impact, combo fire/lightning, level up.
## Added as a child of GameBoard — inherits shake transform automatically.

const Constants = preload("res://scripts/constants.gd")
const TetrominoDataScript = preload("res://scripts/tetromino_data.gd")

const ClearParticlesScene = preload("res://scenes/particles/ClearParticles.tscn")
const LockSparksScene = preload("res://scenes/particles/LockSparks.tscn")
const HardDropImpactScene = preload("res://scenes/particles/HardDropImpact.tscn")
const LevelUpEffectScene = preload("res://scenes/particles/LevelUpEffect.tscn")
const ComboFireEffectScene = preload("res://scenes/particles/ComboFireEffect.tscn")
const ComboLightningEffectScene = preload("res://scenes/particles/ComboLightningEffect.tscn")

var _combo_fire: CPUParticles2D = null
var _combo_lightning_left: CPUParticles2D = null
var _combo_lightning_right: CPUParticles2D = null


# =============================================================================
# LINE CLEAR PARTICLES
# =============================================================================

func spawn_clear_particles(events: Dictionary) -> void:
	var rows_data = events.get("cleared_rows_data", [])
	if rows_data.size() == 0:
		return

	var lines = events.get("lines_cleared", 0)

	for row_info in rows_data:
		var row: int = row_info["row"]
		var cells: Array = row_info["cells"]
		var row_y = Constants.BOARD_OFFSET.y + row * Constants.CELL_SIZE + Constants.CELL_SIZE * 0.5

		# Collect colors for this row
		var row_colors: Array[Color] = []
		for cell_type in cells:
			if cell_type != "" and TetrominoDataScript.COLORS.has(cell_type):
				var c: Color = TetrominoDataScript.COLORS[cell_type]
				if c not in row_colors:
					row_colors.append(c)

		if row_colors.size() == 0:
			row_colors.append(Color.WHITE)

		var particles = ClearParticlesScene.instantiate()
		var primary_color = row_colors[0]
		var p_pos = Vector2(Constants.BOARD_OFFSET.x + Constants.COLS * Constants.CELL_SIZE * 0.5, row_y)
		var p_amount = 90 + lines * 18
		var p_width = Constants.COLS * Constants.CELL_SIZE * 0.5
		particles.configure(p_pos, primary_color, p_amount, p_width)
		add_child(particles)


# =============================================================================
# LOCK SPARKS
# =============================================================================

func spawn_lock_sparks(events: Dictionary) -> void:
	var positions = events.get("locked_positions", [])
	var piece_type: String = events.get("locked_piece_type", "")
	if positions.size() == 0:
		return

	# Find the bottommost row of the locked piece for impact point
	var bottom_y: int = -1
	for pos in positions:
		if pos.y > bottom_y:
			bottom_y = pos.y

	# Collect bottom-row block positions for spark emission
	var bottom_blocks: Array[Vector2i] = []
	for pos in positions:
		if pos.y == bottom_y:
			bottom_blocks.append(pos)

	# Get piece color
	var spark_color = Color.WHITE
	if piece_type != "" and TetrominoDataScript.COLORS.has(piece_type):
		spark_color = TetrominoDataScript.COLORS[piece_type]

	# Spawn a small burst at each bottom block
	for block_pos in bottom_blocks:
		var screen_pos = _grid_to_screen(block_pos) + Vector2(Constants.CELL_SIZE * 0.5, Constants.CELL_SIZE)

		var particles = LockSparksScene.instantiate()
		particles.configure(screen_pos, spark_color)
		add_child(particles)


# =============================================================================
# HARD DROP IMPACT
# =============================================================================

func spawn_hard_drop_impact(events: Dictionary) -> void:
	var positions = events.get("locked_positions", [])
	var piece_type: String = events.get("locked_piece_type", "")
	var impact_data = events.get("hard_drop_impact", {})
	var distance = impact_data.get("distance", 0)

	if positions.size() == 0:
		return

	# Find bottommost row
	var bottom_y: int = -1
	for pos in positions:
		if pos.y > bottom_y:
			bottom_y = pos.y

	# Collect bottom blocks
	var bottom_blocks: Array[Vector2i] = []
	for pos in positions:
		if pos.y == bottom_y:
			bottom_blocks.append(pos)

	var spark_color = Color.WHITE
	if piece_type != "" and TetrominoDataScript.COLORS.has(piece_type):
		spark_color = TetrominoDataScript.COLORS[piece_type]

	# Scale effect with distance
	var particle_amount = int(clamp(12 + distance * 2, 12, 40))
	var vel_min = 60.0 + (distance * 3.0)
	var vel_max = 120.0 + (distance * 5.0)

	for block_pos in bottom_blocks:
		var screen_pos = _grid_to_screen(block_pos) + Vector2(Constants.CELL_SIZE * 0.5, Constants.CELL_SIZE)

		var particles = HardDropImpactScene.instantiate()
		particles.configure(screen_pos, spark_color, particle_amount, vel_min, vel_max)
		add_child(particles)


# =============================================================================
# COMBO STREAK VFX (fire + lightning)
# =============================================================================

func update_combo_vfx(combo_count: int) -> void:
	if combo_count < 1:
		# No combo or combo broken — fade out effects
		_stop_combo_vfx()
		return

	# Combo 2+ — fire at bottom of board
	if _combo_fire == null or not is_instance_valid(_combo_fire):
		_spawn_combo_fire()
	_combo_fire.set_intensity(combo_count)

	# Combo 3+ — lightning on side edges
	if combo_count >= 2:
		if _combo_lightning_left == null or not is_instance_valid(_combo_lightning_left):
			_spawn_combo_lightning()
		_combo_lightning_left.set_intensity(combo_count)
		_combo_lightning_right.set_intensity(combo_count)
	elif _combo_lightning_left != null and is_instance_valid(_combo_lightning_left):
		_combo_lightning_left.stop()
		_combo_lightning_right.stop()
		_combo_lightning_left = null
		_combo_lightning_right = null


func _spawn_combo_fire() -> void:
	var board_w := Constants.COLS * Constants.CELL_SIZE
	var board_bottom := Constants.BOARD_OFFSET.y + Constants.TOTAL_ROWS * Constants.CELL_SIZE
	var center_x := Constants.BOARD_OFFSET.x + board_w * 0.5

	_combo_fire = ComboFireEffectScene.instantiate()
	_combo_fire.configure(Vector2(center_x, board_bottom), board_w * 0.5)
	add_child(_combo_fire)


func _spawn_combo_lightning() -> void:
	var board_left := Constants.BOARD_OFFSET.x
	var board_right := Constants.BOARD_OFFSET.x + Constants.COLS * Constants.CELL_SIZE
	var visible_top := Constants.BOARD_OFFSET.y + Constants.BUFFER_ROWS * Constants.CELL_SIZE
	var visible_bottom := Constants.BOARD_OFFSET.y + Constants.TOTAL_ROWS * Constants.CELL_SIZE
	# Cover bottom 60% of visible area to avoid top playfield
	var zone_top := visible_top + (visible_bottom - visible_top) * 0.4
	var zone_center_y := (zone_top + visible_bottom) * 0.5
	var zone_half_height := (visible_bottom - zone_top) * 0.5

	_combo_lightning_left = ComboLightningEffectScene.instantiate()
	_combo_lightning_left.configure(Vector2(board_left, zone_center_y), zone_half_height, true)
	add_child(_combo_lightning_left)

	_combo_lightning_right = ComboLightningEffectScene.instantiate()
	_combo_lightning_right.configure(Vector2(board_right, zone_center_y), zone_half_height, false)
	add_child(_combo_lightning_right)


func _stop_combo_vfx() -> void:
	if _combo_fire != null and is_instance_valid(_combo_fire):
		_combo_fire.stop()
		_combo_fire = null
	if _combo_lightning_left != null and is_instance_valid(_combo_lightning_left):
		_combo_lightning_left.stop()
		_combo_lightning_left = null
	if _combo_lightning_right != null and is_instance_valid(_combo_lightning_right):
		_combo_lightning_right.stop()
		_combo_lightning_right = null


func force_clear() -> void:
	## Immediately free all combo VFX (for game reset).
	if _combo_fire != null and is_instance_valid(_combo_fire):
		_combo_fire.queue_free()
		_combo_fire = null
	if _combo_lightning_left != null and is_instance_valid(_combo_lightning_left):
		_combo_lightning_left.queue_free()
		_combo_lightning_left = null
	if _combo_lightning_right != null and is_instance_valid(_combo_lightning_right):
		_combo_lightning_right.queue_free()
		_combo_lightning_right = null


# =============================================================================
# LEVEL UP
# =============================================================================

func spawn_level_up_effect(center: Vector2) -> void:
	var particles := LevelUpEffectScene.instantiate()
	particles.configure(center)
	add_child(particles)


# =============================================================================
# HELPERS
# =============================================================================

func _grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return Constants.BOARD_OFFSET + Vector2(grid_pos.x * Constants.CELL_SIZE, grid_pos.y * Constants.CELL_SIZE)
