extends Node2D

const Constants = preload("res://scripts/constants.gd")
const GameLogicScript = preload("res://scripts/game_logic.gd")
const GridScript = preload("res://scripts/grid.gd")
const BoardVfxScript = preload("res://scripts/board_vfx.gd")
const FloatingTextRendererScript = preload("res://scripts/floating_text_renderer.gd")
const LeftPanelDisplayScript = preload("res://scripts/left_panel_display.gd")
const ParticleEffectsScript = preload("res://scripts/particle_effects.gd")

var game_logic: GameLogicScript
var textures: Dictionary = {}
var game_manager = null
var show_ghost: bool = true

var _vfx: BoardVfxScript
var _text_renderer: Node2D   # FloatingTextRenderer
var _left_panel: Node2D   # LeftPanelDisplay (persistent counters)
var _particles: Node2D        # ParticleEffects
var _original_position: Vector2 = Vector2.ZERO


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

	_original_position = position

	# VFX state (RefCounted)
	_vfx = BoardVfxScript.new()

	# Child Node2D renderers (draw order: text on top of board, particles on top of text)
	_text_renderer = FloatingTextRendererScript.new()
	add_child(_text_renderer)

	_left_panel = LeftPanelDisplayScript.new()
	add_child(_left_panel)

	_particles = ParticleEffectsScript.new()
	add_child(_particles)

	game_logic = GameLogicScript.new()
	game_logic.start_game()


func get_left_panel_stats() -> Dictionary:
	return _left_panel.get_stats()


func clear_floating_texts() -> void:
	_text_renderer.clear()
	_left_panel.clear()
	_vfx.reset()
	position = _original_position
	_particles.force_clear()


func _process(delta: float) -> void:
	# Update VFX timers regardless of game state
	var shake_offset = _vfx.update_shake(delta)
	position = _original_position + shake_offset
	_vfx.update_border_glow(delta)

	# Handle clear animation in progress
	if _vfx.is_clearing():
		var finished = _vfx.update_clear(delta)
		_text_renderer.update_texts(delta)
		if finished and game_logic != null:
			var result = game_logic.complete_clear()
			if result.get("game_over", false):
				SfxManager.play("game_over")
				if game_manager != null:
					game_manager.on_game_over(game_logic.scoring.score)
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
			_vfx.apply_shake(impact_shake)
			_particles.spawn_hard_drop_impact(events)

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
			_particles.spawn_lock_sparks(events)

			# Update combo streak VFX (fire + lightning)
			_particles.update_combo_vfx(combo)

			# Combo-based screen shake (combo 2+)
			if combo >= 1:
				var combo_shake = 1.5 + (combo - 1) * 0.7
				_vfx.apply_shake(combo_shake)

		if events.get("lines_cleared", 0) > 0:
			_text_renderer.spawn(events)
			_vfx.start_clear(events)
			_vfx.trigger_shake(events)
			_vfx.trigger_border_glow(events)
			_particles.spawn_clear_particles(events)

			# Update left panel persistent counters
			var combo = events.get("combo_count", -1)
			var b2b_count = events.get("back_to_back_count", 0)

			if combo >= 1:
				_left_panel.update_combo(combo)
			elif combo == -1:
				_left_panel.clear_combo()

			if b2b_count > 0:
				_left_panel.update_b2b(b2b_count)
			elif b2b_count == 0:
				# B2B broke on this line clear
				_left_panel.clear_b2b()

		if events.get("level_up", false):
			SfxManager.play("level_up")
			var center = _get_playfield_center()
			_particles.spawn_level_up_effect(center)
			_text_renderer.spawn_level_up(center)
		if events.get("game_over", false):
			SfxManager.play("game_over")
			if game_manager != null:
				game_manager.on_game_over(game_logic.scoring.score)

	_text_renderer.update_texts(delta)
	queue_redraw()


# =============================================================================
# DRAWING
# =============================================================================

func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return Constants.BOARD_OFFSET + Vector2(grid_pos.x * Constants.CELL_SIZE, grid_pos.y * Constants.CELL_SIZE)


func _draw() -> void:
	if game_logic == null:
		return

	var board_w = Constants.COLS * Constants.CELL_SIZE
	var board_h = Constants.TOTAL_ROWS * Constants.CELL_SIZE

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
	var clearing_rows = _vfx.get_clearing_rows()
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
					draw_texture(textures[piece_type], pos)
					var glow_alpha := 0.2
					if hard_drop_state.get("active", false):
						glow_alpha = 0.45
					var glow_color = Color(1.0, 1.0, 1.0, glow_alpha)
					draw_texture(textures[piece_type], pos, glow_color)


# =============================================================================
# DRAW HELPERS (remain here — they use draw_* calls on this CanvasItem)
# =============================================================================

func _draw_border_glow() -> void:
	if _vfx.border_glow <= 0.01:
		return

	var board_w = Constants.COLS * Constants.CELL_SIZE
	var board_h = Constants.TOTAL_ROWS * Constants.CELL_SIZE

	for i in range(4):
		var expand = float(i) * 2.0
		var alpha = _vfx.border_glow * (1.0 - float(i) * 0.25)
		if alpha <= 0.0:
			continue
		var glow_color = _vfx.border_glow_color
		glow_color.a = alpha * 0.6
		var glow_rect = Rect2(
			Constants.BOARD_OFFSET.x - expand,
			Constants.BOARD_OFFSET.y - expand,
			board_w + expand * 2.0,
			board_h + expand * 2.0
		)
		draw_rect(glow_rect, glow_color, false, 1.5 + float(i) * 0.5)


func _draw_clear_animations() -> void:
	if not _vfx.is_clearing():
		return

	var timer: float = _vfx.clear_anim["timer"]
	var rows_data: Array = _vfx.clear_anim["rows_data"]
	var board_w = Constants.COLS * Constants.CELL_SIZE

	for row_info in rows_data:
		var row: int = row_info["row"]
		var cells: Array = row_info["cells"]
		var row_y = Constants.BOARD_OFFSET.y + row * Constants.CELL_SIZE

		if timer < Constants.CLEAR_FLASH_DURATION:
			# Phase 1: White flash overlay on the full row
			var flash_t = timer / Constants.CLEAR_FLASH_DURATION
			var flash_alpha = 1.0 - flash_t * 0.3
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

		# Cap trail length to last 7 cells for shorter, more focused effect
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


func _get_playfield_center() -> Vector2:
	var play_top := Constants.BOARD_OFFSET.y + Constants.BUFFER_ROWS * Constants.CELL_SIZE
	var play_h := Constants.VISIBLE_ROWS * Constants.CELL_SIZE
	var board_w := Constants.COLS * Constants.CELL_SIZE
	return Vector2(
		Constants.BOARD_OFFSET.x + board_w * 0.5,
		play_top + play_h * 0.5
	)
