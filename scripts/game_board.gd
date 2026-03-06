extends Node2D

const Constants = preload("res://scripts/constants.gd")
const GameLogicScript = preload("res://scripts/game_logic.gd")
const GridScript = preload("res://scripts/grid.gd")
const TetrominoDataScript = preload("res://scripts/tetromino_data.gd")

# Particle scenes
const ClearParticlesScene = preload("res://scenes/particles/ClearParticles.tscn")
const LockSparksScene = preload("res://scenes/particles/LockSparks.tscn")
const HardDropImpactScene = preload("res://scenes/particles/HardDropImpact.tscn")
const AmbientSparklesScene = preload("res://scenes/particles/AmbientSparkles.tscn")
const LevelUpEffectScene = preload("res://scenes/particles/LevelUpEffect.tscn")
const ComboFireEffectScene = preload("res://scenes/particles/ComboFireEffect.tscn")
const ComboLightningEffectScene = preload("res://scenes/particles/ComboLightningEffect.tscn")

# Fonts
var _font: Font
var _font_bold: Font

# Layout: board centered with side panels
# Board = 10 cols × 24 rows = 320 × 768
# Viewport = 480 × 1040

var game_logic: GameLogicScript
var textures: Dictionary = {}
var game_manager = null
var show_ghost: bool = true
var _floating_texts: Array = []

# --- VFX State ---
var _clear_anim: Dictionary = {}       # {"timer": float, "rows_data": Array, "lines": int}
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _original_position: Vector2 = Vector2.ZERO
var _border_glow: float = 0.0
var _border_glow_color: Color = Color.WHITE

# --- Combo VFX ---
var _combo_fire: CPUParticles2D = null
var _combo_lightning_left: CPUParticles2D = null
var _combo_lightning_right: CPUParticles2D = null


func _ready() -> void:
	var type_to_color = {
		"I": "cyan",
		"J": "blue",
		"L": "orange",
		"O": "yellow",
		"S": "green",
		"T": "purple",
		"Z": "red"
	}
	for piece_type in type_to_color.keys():
		textures[piece_type] = load("res://assets/blocks/block_" + type_to_color[piece_type] + ".png")
	textures["ghost"] = load("res://assets/blocks/block_ghost.png")

	# Initialize fonts with FontVariation for bold effect
	var base_font = preload("res://assets/fonts/monogram-extended.ttf")
	
	# Regular font with moderate bold
	var font_variation = FontVariation.new()
	font_variation.base_font = base_font
	font_variation.variation_embolden = 0.3
	_font = font_variation
	
	# Bold font with heavier embolden
	var font_bold_variation = FontVariation.new()
	font_bold_variation.base_font = base_font
	font_bold_variation.variation_embolden = 0.5
	_font_bold = font_bold_variation

	_original_position = position

	game_logic = GameLogicScript.new()
	game_logic.start_game()

func clear_floating_texts() -> void:
	_floating_texts.clear()
	_clear_anim = {}
	_border_glow = 0.0
	_shake_intensity = 0.0
	position = _original_position
	_force_clear_combo_vfx()

func _process(delta: float) -> void:
	# Update VFX timers regardless of game state
	_update_shake(delta)
	_update_border_glow(delta)

	# Handle clear animation in progress
	if _is_clearing():
		_update_clear_anim(delta)
		queue_redraw()
		return

	if game_logic != null:
		var events = game_logic.update(delta)

		if events.get("moved", false):
			SfxManager.play("move")
		if events.get("rotated", false):
			SfxManager.play("rotate")
		if events.get("hard_dropped", false):
			SfxManager.play("hard_drop")
			
		if events.has("hard_drop_impact"):
			var distance: int = events["hard_drop_impact"].get("distance", 0)
			var impact_shake = clampf(0.6 + (float(distance) / 2.5), 0.6, 3.0)
			if _shake_intensity < impact_shake:
				_shake_intensity = impact_shake
				_shake_timer = 0.0
			_spawn_hard_drop_impact_particles(events)

		if events.get("soft_dropped", false):
			SfxManager.play("soft_drop")
		if events.get("hold_swapped", false):
			SfxManager.play("hold")
		if events.get("piece_locked", false):
			if events.get("lines_cleared", 0) == 4:
				SfxManager.play("tetris_clear")
			elif events.get("lines_cleared", 0) > 0:
				SfxManager.play("line_clear")
			else:
				SfxManager.play("lock")

			var combo = events.get("combo_count", -1)
			if combo == 1:
				SfxManager.play("combo_1")
			elif combo == 2:
				SfxManager.play("combo_2")
			elif combo == 3:
				SfxManager.play("combo_3")
			elif combo >= 4:
				SfxManager.play("combo_high")

			# Lock impact sparks on every piece lock
			_spawn_lock_sparks(events)

			# Update combo streak VFX (fire + lightning)
			_update_combo_vfx(combo)
			
			# Combo-based screen shake (combo 2+)
			if combo >= 1:
				var combo_shake = 1.5 + (combo - 1) * 0.7  # 2→1.5, 3→2.2, 4→3.0, etc
				if combo_shake > _shake_intensity:
					_shake_intensity = combo_shake
					_shake_timer = 0.0

			if events.get("lines_cleared", 0) > 0:
				_spawn_floating_text(events)
				_start_clear_animation(events)
				_trigger_shake(events)
				_trigger_border_glow(events)
				_spawn_clear_particles(events)

		if events.get("level_up", false):
			SfxManager.play("level_up")
			_spawn_level_up_effect()
		if events.get("game_over", false):
			SfxManager.play("game_over")
			if game_manager != null:
				game_manager.on_game_over(game_logic.scoring.score)

	_update_floating_texts(delta)
	queue_redraw()


# =============================================================================
# LINE CLEAR ANIMATION
# =============================================================================

func _is_clearing() -> bool:
	return _clear_anim.size() > 0


func _start_clear_animation(events: Dictionary) -> void:
	var rows_data = events.get("cleared_rows_data", [])
	if rows_data.size() == 0:
		return
	_clear_anim = {
		"timer": 0.0,
		"rows_data": rows_data,
		"lines": events.get("lines_cleared", 0),
	}


func _update_clear_anim(delta: float) -> void:
	if _clear_anim.size() == 0:
		return

	_clear_anim["timer"] += delta

	# Also update floating texts during clear anim so they don't freeze
	_update_floating_texts(delta)

	if _clear_anim["timer"] >= Constants.CLEAR_TOTAL_DURATION:
		# Animation done — actually clear the grid rows
		_clear_anim = {}
		if game_logic != null:
			var result = game_logic.complete_clear()
			if result.get("game_over", false):
				SfxManager.play("game_over")
				if game_manager != null:
					game_manager.on_game_over(game_logic.scoring.score)


func _draw_clear_animations() -> void:
	if _clear_anim.size() == 0:
		return

	var timer: float = _clear_anim["timer"]
	var rows_data: Array = _clear_anim["rows_data"]
	var board_w = Constants.COLS * Constants.CELL_SIZE

	for row_info in rows_data:
		var row: int = row_info["row"]
		var cells: Array = row_info["cells"]
		var row_y = Constants.BOARD_OFFSET.y + row * Constants.CELL_SIZE

		if timer < Constants.CLEAR_FLASH_DURATION:
			# Phase 1: White flash overlay on the full row
			var flash_t = timer / Constants.CLEAR_FLASH_DURATION
			var flash_alpha = 1.0 - flash_t * 0.3  # Start bright, slight fade
			var flash_rect = Rect2(Constants.BOARD_OFFSET.x, row_y, board_w, Constants.CELL_SIZE)
			draw_rect(flash_rect, Color(1.0, 1.0, 1.0, flash_alpha))
		else:
			# Phase 2: Dissolve — blocks fade out with decreasing alpha
			var dissolve_t = (timer - Constants.CLEAR_FLASH_DURATION) / Constants.CLEAR_DISSOLVE_DURATION
			dissolve_t = clampf(dissolve_t, 0.0, 1.0)
			var alpha = 1.0 - dissolve_t

			for col in range(cells.size()):
				var cell_type = cells[col]
				if cell_type != "" and textures.has(cell_type):
					var pos = Vector2(Constants.BOARD_OFFSET.x + col * Constants.CELL_SIZE, row_y)
					draw_set_transform(pos, 0.0, Vector2.ONE)
					var mod_color = Color(1.0, 1.0, 1.0, alpha)
					draw_texture(textures[cell_type], Vector2.ZERO, mod_color)

			# Reset transform
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _get_clearing_rows() -> Array[int]:
	if _clear_anim.size() == 0:
		return []
	var rows: Array[int] = []
	for row_info in _clear_anim["rows_data"]:
		rows.append(row_info["row"])
	return rows


# =============================================================================
# SCREEN SHAKE
# =============================================================================

func _trigger_shake(events: Dictionary) -> void:
	var lines = events.get("lines_cleared", 0)
	var is_tspin = events.get("is_tspin", false)
	var is_pc = events.get("is_perfect_clear", false)

	if is_pc:
		_shake_intensity = 6.0
	elif lines == 4 or is_tspin:
		_shake_intensity = 4.5
	elif lines == 3:
		_shake_intensity = 3.0
	elif lines == 2:
		_shake_intensity = 2.0
	else:
		_shake_intensity = 1.2

	_shake_timer = 0.0


func _update_shake(delta: float) -> void:
	if _shake_intensity <= 0.1:
		_shake_intensity = 0.0
		position = _original_position
		return

	_shake_timer += delta
	_shake_intensity *= exp(-Constants.SHAKE_DECAY * delta)

	var offset = Vector2(
		randf_range(-_shake_intensity, _shake_intensity),
		randf_range(-_shake_intensity, _shake_intensity)
	)
	position = _original_position + offset


# =============================================================================
# BORDER GLOW
# =============================================================================

func _trigger_border_glow(events: Dictionary) -> void:
	var lines = events.get("lines_cleared", 0)
	var is_tspin = events.get("is_tspin", false)
	var is_pc = events.get("is_perfect_clear", false)

	if is_pc:
		_border_glow = 1.0
		_border_glow_color = Color(1.0, 0.2, 1.0)  # Magenta for perfect clear
	elif lines == 4 or is_tspin:
		_border_glow = 1.0
		_border_glow_color = Color(0.0, 1.0, 1.0)  # Cyan for Tetris/T-spin
	elif lines >= 2:
		_border_glow = 0.7
		_border_glow_color = Color(1.0, 1.0, 0.3)  # Yellow for multi-line
	else:
		_border_glow = 0.4
		_border_glow_color = Color.WHITE


func _update_border_glow(delta: float) -> void:
	if _border_glow <= 0.01:
		_border_glow = 0.0
		return
	_border_glow *= exp(-Constants.BORDER_GLOW_DECAY * delta)


func _draw_border_glow() -> void:
	if _border_glow <= 0.01:
		return

	var board_w = Constants.COLS * Constants.CELL_SIZE
	var board_h = Constants.TOTAL_ROWS * Constants.CELL_SIZE

	# Draw multiple expanding border rings with decreasing opacity
	for i in range(4):
		var expand = float(i) * 2.0
		var alpha = _border_glow * (1.0 - float(i) * 0.25)
		if alpha <= 0.0:
			continue
		var glow_color = _border_glow_color
		glow_color.a = alpha * 0.6
		var glow_rect = Rect2(
			Constants.BOARD_OFFSET.x - expand,
			Constants.BOARD_OFFSET.y - expand,
			board_w + expand * 2.0,
			board_h + expand * 2.0
		)
		draw_rect(glow_rect, glow_color, false, 1.5 + float(i) * 0.5)


# =============================================================================
# DEBRIS PARTICLES (line clear burst)
# =============================================================================

func _spawn_clear_particles(events: Dictionary) -> void:
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

		# Use particle scene
		var particles = ClearParticlesScene.instantiate()
		var primary_color = row_colors[0]
		var p_pos = Vector2(Constants.BOARD_OFFSET.x + Constants.COLS * Constants.CELL_SIZE * 0.5, row_y)
		var p_amount = 90 + lines * 18
		var p_width = Constants.COLS * Constants.CELL_SIZE * 0.5
		particles.configure(p_pos, primary_color, p_amount, p_width)
		add_child(particles)


func _draw_hard_drop_starfall(active_positions: Array[Vector2i], state: Dictionary) -> void:
	if active_positions.size() == 0:
		return

	var start_y: int = state.get("start_y", 0)
	var current_y: int = state.get("current_y", start_y)
	var progress: float = state.get("progress", 1.0)

	for block_pos in active_positions:
		var local_y := block_pos.y - current_y
		var to_y := Constants.BOARD_OFFSET.y + float(block_pos.y) * Constants.CELL_SIZE + Constants.CELL_SIZE * 0.5
		var x := Constants.BOARD_OFFSET.x + float(block_pos.x) * Constants.CELL_SIZE + Constants.CELL_SIZE * 0.5

		# Cap trail length to last 3 cells for shorter, more focused effect
		var max_trail_cells := 7.0
		var original_from_y := Constants.BOARD_OFFSET.y + float(start_y + local_y) * Constants.CELL_SIZE + Constants.CELL_SIZE * 0.5
		var from_y := maxf(original_from_y, to_y - (max_trail_cells * Constants.CELL_SIZE))

		var trail_alpha := 0.45 * (1.0 - progress * 0.35)
		if to_y > from_y + 1.0:
			draw_line(
				Vector2(x, from_y),
				Vector2(x, to_y),
				Color(1.0, 1.0, 0.92, trail_alpha),
				2.0
			)

		# Falling-star head
		draw_circle(
			Vector2(x, to_y),
			2.2,
			Color(1.0, 1.0, 1.0, 0.65)
		)


func _make_fade_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.5, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	return curve


# =============================================================================
# PIECE LOCK IMPACT SPARKS
# =============================================================================

func _spawn_lock_sparks(events: Dictionary) -> void:
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
		var screen_pos = grid_to_screen(block_pos) + Vector2(Constants.CELL_SIZE * 0.5, Constants.CELL_SIZE)

		var particles = LockSparksScene.instantiate()
		particles.configure(screen_pos, spark_color)
		add_child(particles)

func _spawn_hard_drop_impact_particles(events: Dictionary) -> void:
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
		var screen_pos = grid_to_screen(block_pos) + Vector2(Constants.CELL_SIZE * 0.5, Constants.CELL_SIZE)

		var particles = HardDropImpactScene.instantiate()
		particles.configure(screen_pos, spark_color, particle_amount, vel_min, vel_max)
		add_child(particles)


# =============================================================================
# COMBO STREAK VFX (fire + lightning)
# =============================================================================

func _update_combo_vfx(combo_count: int) -> void:
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


func _force_clear_combo_vfx() -> void:
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
# LEVEL UP VFX
# =============================================================================

func _spawn_level_up_effect() -> void:
	# Board center position (visible area only)
	var play_top := Constants.BOARD_OFFSET.y + Constants.BUFFER_ROWS * Constants.CELL_SIZE
	var play_h := Constants.VISIBLE_ROWS * Constants.CELL_SIZE
	var board_w := Constants.COLS * Constants.CELL_SIZE
	var center := Vector2(
		Constants.BOARD_OFFSET.x + board_w * 0.5,
		play_top + play_h * 0.5
	)

	# Particle burst
	var particles := LevelUpEffectScene.instantiate()
	particles.configure(center)
	add_child(particles)

	# "LEVEL UP!" floating text
	_floating_texts.append({
		"score_text": "",
		"action_text": "LEVEL UP!",
		"combo_text": "",
		"b2b_text": "",
		"position": Vector2(center.x, center.y),
		"timer": 0.0,
		"duration": Constants.FLOAT_DURATION,
		"font_size": 48,
		"color": Color(1.0, 0.85, 0.0),
		"combo_count": -1,
	})


# =============================================================================
# FLOATING TEXTS
# =============================================================================

func _update_floating_texts(delta: float) -> void:
	var i = _floating_texts.size() - 1
	while i >= 0:
		var ft = _floating_texts[i]
		ft["timer"] += delta
		ft["position"].y -= Constants.FLOAT_SPEED * delta
		if ft["timer"] >= ft["duration"]:
			_floating_texts.remove_at(i)
		i -= 1

func _spawn_floating_text(events: Dictionary) -> void:
	var lines = events.get("lines_cleared", 0)
	var score_added = events.get("score_added", 0)
	var is_tspin = events.get("is_tspin", false)
	var is_mini = events.get("is_tspin_mini", false)
	var is_b2b = events.get("is_back_to_back", false)
	var is_pc = events.get("is_perfect_clear", false)
	var combo = events.get("combo_count", -1)

	var action_text = _get_action_label(lines, is_tspin, is_mini)
	var score_text = "+" + str(score_added)
	var combo_text = ""
	if combo >= 1:
		combo_text = "COMBO " + str(combo + 1) + "!"
	var b2b_text = ""
	if is_pc:
		b2b_text = "PERFECT CLEAR"
	elif is_b2b:
		b2b_text = "BACK TO BACK"

	# Extract position data from events
	var locked_positions = events.get("locked_positions", [])
	var cleared_rows = events.get("cleared_rows_data", [])

	# Calculate spawn_x (horizontal center of locked piece)
	var spawn_x: float
	if locked_positions.size() > 0:
		var min_col := 999
		var max_col := -1
		for pos in locked_positions:
			if pos.x < min_col: min_col = pos.x
			if pos.x > max_col: max_col = pos.x
		spawn_x = Constants.BOARD_OFFSET.x + ((min_col + max_col) / 2.0 + 0.5) * Constants.CELL_SIZE
	else:
		spawn_x = Constants.BOARD_OFFSET.x + (Constants.COLS * Constants.CELL_SIZE) / 2.0

	# Calculate spawn_y (topmost cleared row)
	var spawn_y: float
	if cleared_rows.size() > 0:
		var top_row := 999
		for row_info in cleared_rows:
			var r: int = row_info["row"]
			if r < top_row: top_row = r
		spawn_y = Constants.BOARD_OFFSET.y + top_row * Constants.CELL_SIZE
	else:
		var playfield_top = Constants.BOARD_OFFSET.y + Constants.BUFFER_ROWS * Constants.CELL_SIZE
		spawn_y = playfield_top + Constants.VISIBLE_ROWS * Constants.CELL_SIZE * 0.4

	# Clamp position within playfield bounds
	var board_left = Constants.BOARD_OFFSET.x + 40.0
	var board_right = Constants.BOARD_OFFSET.x + Constants.COLS * Constants.CELL_SIZE - 40.0
	spawn_x = clampf(spawn_x, board_left, board_right)
	var vis_top = Constants.BOARD_OFFSET.y + Constants.BUFFER_ROWS * Constants.CELL_SIZE + 20.0
	var vis_bottom = Constants.BOARD_OFFSET.y + Constants.TOTAL_ROWS * Constants.CELL_SIZE - 40.0
	spawn_y = clampf(spawn_y, vis_top, vis_bottom)

	_floating_texts.append({
		"score_text": score_text,
		"action_text": action_text,
		"combo_text": combo_text,
		"b2b_text": b2b_text,
		"position": Vector2(spawn_x, spawn_y),
		"timer": 0.0,
		"duration": Constants.FLOAT_DURATION,
		"font_size": _score_to_font_size(lines, combo),
		"color": _get_score_color(lines, is_tspin, is_b2b, is_pc),
		"combo_count": combo,
	})

func _get_action_label(lines: int, is_tspin: bool, is_mini: bool) -> String:
	if is_tspin:
		var prefix = "T-SPIN MINI " if is_mini else "T-SPIN "
		match lines:
			0: return prefix.strip_edges()
			1: return prefix + "SINGLE"
			2: return "T-SPIN DOUBLE!"
			3: return "T-SPIN TRIPLE!"
	match lines:
		1: return "SINGLE"
		2: return "DOUBLE"
		3: return "TRIPLE"
		4: return "TETRIS!"
	return ""

func _score_to_font_size(lines: int, combo: int) -> int:
	var size := 32

	# Add combo bonus
	match combo:
		1:
			size += 6
		2:
			size += 10
		3:
			size += 16
		_:
			if combo >= 4:
				size += 20

	# Add clean-row bonus
	match lines:
		1:
			size += 0
		2:
			size += 4
		3:
			size += 8
		4:
			size += 16

	return size

func _get_score_color(lines: int, is_tspin: bool, is_b2b: bool, is_pc: bool) -> Color:
	if is_pc:
		return Color(1.0, 0.2, 1.0)
	if is_b2b:
		return Color(1.0, 0.85, 0.0)
	if is_tspin:
		return Color(0.7, 0.3, 1.0)
	if lines == 4:
		return Color(0.0, 1.0, 1.0)
	if lines >= 2:
		return Color(1.0, 1.0, 0.3)
	return Color.WHITE

func _get_combo_color(combo: int) -> Color:
	if combo >= 3:
		return Color(1.0, 0.2, 0.2)
	if combo >= 2:
		return Color(1.0, 0.6, 0.1)
	return Color(1.0, 1.0, 0.3)

func _draw_floating_texts() -> void:
	for ft in _floating_texts:
		var t = ft["timer"] / ft["duration"]
		var hold_end = Constants.FLOAT_HOLD_RATIO
		var alpha = 1.0
		if t > hold_end:
			alpha = 1.0 - (t - hold_end) / (1.0 - hold_end)
		alpha = clampf(alpha, 0.0, 1.0)

		var scale_t = clampf(ft["timer"] / Constants.SCALE_SETTLE_TIME, 0.0, 1.0)
		var scale_factor = lerpf(Constants.SCALE_PUNCH, 1.0, scale_t)

		var pos = ft["position"]
		var base_size: int = ft["font_size"]
		var scaled_size = int(base_size * scale_factor)
		var color: Color = ft["color"]
		color.a = alpha

		var y_cursor = pos.y
		var line_gap = 4.0

		if ft["b2b_text"] != "":
			var b2b_color = Color(1.0, 0.85, 0.0, alpha)
			var b2b_size = maxi(scaled_size - 6, 10)
			draw_string(_font_bold, Vector2(pos.x - 100, y_cursor), ft["b2b_text"],
				HORIZONTAL_ALIGNMENT_CENTER, 200, b2b_size, b2b_color)
			y_cursor += b2b_size + line_gap

		var action_size = maxi(scaled_size - 2, 12)
		draw_string(_font_bold, Vector2(pos.x - 100, y_cursor), ft["action_text"],
			HORIZONTAL_ALIGNMENT_CENTER, 200, action_size, color)
		y_cursor += action_size + line_gap

		draw_string(_font, Vector2(pos.x - 100, y_cursor), ft["score_text"],
			HORIZONTAL_ALIGNMENT_CENTER, 200, scaled_size, color)
		y_cursor += scaled_size + line_gap

		if ft["combo_text"] != "":
			var combo_color = _get_combo_color(ft["combo_count"])
			combo_color.a = alpha
			var combo_size = maxi(scaled_size - 4, 10)
			draw_string(_font_bold, Vector2(pos.x - 100, y_cursor), ft["combo_text"],
				HORIZONTAL_ALIGNMENT_CENTER, 200, combo_size, combo_color)


# =============================================================================
# DRAWING
# =============================================================================

func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return Constants.BOARD_OFFSET + Vector2(grid_pos.x * Constants.CELL_SIZE, grid_pos.y * Constants.CELL_SIZE)

func _draw() -> void:
	if game_logic == null:
		return

	var board_w = Constants.COLS * Constants.CELL_SIZE
	var board_h = Constants.TOTAL_ROWS * Constants.CELL_SIZE  # Full 24 rows

	var board_rect = Rect2(Constants.BOARD_OFFSET.x, Constants.BOARD_OFFSET.y, board_w, board_h)

	# Subtle grid lines — full board (all 24 rows)
	var play_top = Constants.BOARD_OFFSET.y
	var play_h = Constants.TOTAL_ROWS * Constants.CELL_SIZE
	for i in range(1, Constants.COLS):
		var x = Constants.BOARD_OFFSET.x + i * Constants.CELL_SIZE
		draw_line(Vector2(x, play_top), Vector2(x, play_top + play_h), Constants.GRID_LINE_COLOR)
	for j in range(1, Constants.TOTAL_ROWS):
		var y = play_top + j * Constants.CELL_SIZE
		draw_line(Vector2(Constants.BOARD_OFFSET.x, y), Vector2(Constants.BOARD_OFFSET.x + board_w, y), Constants.GRID_LINE_COLOR)

	# Thin white border around entire board area (all 24 rows)
	draw_rect(board_rect, Constants.BORDER_COLOR, false, Constants.BORDER_WIDTH)

	# Border glow (drawn on top of normal border)
	_draw_border_glow()

	# Draw locked blocks — ALL rows (including spawn zone)
	# Skip rows that are currently being animated (clear animation draws them separately)
	var clearing_rows = _get_clearing_rows()
	var grid = game_logic.grid
	for y in range(grid.HEIGHT):
		if y in clearing_rows:
			continue
		for x in range(grid.WIDTH):
			var cell_value = grid.cells[y][x]
			if cell_value != "":
				var pos = grid_to_screen(Vector2i(x, y))
				if textures.has(cell_value):
					draw_texture(textures[cell_value], pos)

	# Draw clear animation overlays (flash / dissolve)
	_draw_clear_animations()

	# Ghost piece — visible from row 0
	var active_positions: Array[Vector2i] = []
	if game_logic.active_piece != null:
		active_positions = game_logic.active_piece.get_block_positions()
	var hard_drop_state := game_logic.get_hard_drop_visual_state()

	if show_ghost:
		var ghost_positions = game_logic.get_ghost_blocks()
		for ghost_pos in ghost_positions:
			if ghost_pos.y >= 0 and not ghost_pos in active_positions:
				var pos = grid_to_screen(ghost_pos)
				draw_texture(textures["ghost"], pos)

	# Active piece with glow — brighter than locked blocks
	if game_logic.active_piece != null:
		var piece_type = game_logic.active_piece.type
		if textures.has(piece_type):
			if hard_drop_state.get("active", false):
				_draw_hard_drop_starfall(active_positions, hard_drop_state)
			for active_pos in active_positions:
				if active_pos.y >= 0:
					var pos = grid_to_screen(active_pos)
					# Draw normal block
					draw_texture(textures[piece_type], pos)
					# Additive glow overlay — brighter, slightly larger feel
					var glow_alpha := 0.2
					if hard_drop_state.get("active", false):
						glow_alpha = 0.45
					var glow_color = Color(1.0, 1.0, 1.0, glow_alpha)
					draw_texture(textures[piece_type], pos, glow_color)

	_draw_floating_texts()
