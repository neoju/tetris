extends Node2D

const GameLogicScript = preload("res://scripts/game_logic.gd")
const GridScript = preload("res://scripts/grid.gd")

const CELL_SIZE = 32
const BOARD_OFFSET = Vector2(80, 0)
const COLS = GridScript.WIDTH
const VISIBLE_ROWS = GridScript.VISIBLE_HEIGHT
const BUFFER_ROWS = GridScript.BUFFER_ROWS

const FLOAT_SPEED = 45.0
const FLOAT_DURATION = 1.6
const FLOAT_HOLD_RATIO = 0.3
const SCALE_PUNCH = 1.4
const SCALE_SETTLE_TIME = 0.15

var game_logic: GameLogicScript
var textures: Dictionary = {}
var game_manager = null
var _floating_texts: Array = []

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

	game_logic = GameLogicScript.new()
	game_logic.start_game()

func clear_floating_texts() -> void:
	_floating_texts.clear()

func _process(delta: float) -> void:
	if game_logic != null:
		var events = game_logic.update(delta)

		if events.get("moved", false):
			SfxManager.play("move")
		if events.get("rotated", false):
			SfxManager.play("rotate")
		if events.get("hard_dropped", false):
			SfxManager.play("hard_drop")
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

			if events.get("lines_cleared", 0) > 0:
				_spawn_floating_text(events)
		if events.get("level_up", false):
			SfxManager.play("level_up")
		if events.get("game_over", false):
			SfxManager.play("game_over")
			if game_manager != null:
				game_manager.on_game_over(game_logic.scoring.score)

		_update_floating_texts(delta)
		queue_redraw()

func _update_floating_texts(delta: float) -> void:
	var i = _floating_texts.size() - 1
	while i >= 0:
		var ft = _floating_texts[i]
		ft["timer"] += delta
		ft["position"].y -= FLOAT_SPEED * delta
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

	var center_x = BOARD_OFFSET.x + (COLS * CELL_SIZE) / 2.0
	var spawn_y = VISIBLE_ROWS * CELL_SIZE * 0.4

	_floating_texts.append({
		"score_text": score_text,
		"action_text": action_text,
		"combo_text": combo_text,
		"b2b_text": b2b_text,
		"position": Vector2(center_x, spawn_y),
		"timer": 0.0,
		"duration": FLOAT_DURATION,
		"font_size": _score_to_font_size(score_added),
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

func _score_to_font_size(score: int) -> int:
	if score <= 100:
		return 16
	elif score <= 300:
		return 20
	elif score <= 800:
		return 24
	elif score <= 1200:
		return 28
	return 32

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
	var font = ThemeDB.fallback_font
	for ft in _floating_texts:
		var t = ft["timer"] / ft["duration"]
		var hold_end = FLOAT_HOLD_RATIO
		var alpha = 1.0
		if t > hold_end:
			alpha = 1.0 - (t - hold_end) / (1.0 - hold_end)
		alpha = clampf(alpha, 0.0, 1.0)

		var scale_t = clampf(ft["timer"] / SCALE_SETTLE_TIME, 0.0, 1.0)
		var scale_factor = lerpf(SCALE_PUNCH, 1.0, scale_t)

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
			draw_string(font, Vector2(pos.x - 100, y_cursor), ft["b2b_text"],
				HORIZONTAL_ALIGNMENT_CENTER, 200, b2b_size, b2b_color)
			y_cursor += b2b_size + line_gap

		var action_size = maxi(scaled_size - 2, 12)
		draw_string(font, Vector2(pos.x - 100, y_cursor), ft["action_text"],
			HORIZONTAL_ALIGNMENT_CENTER, 200, action_size, color)
		y_cursor += action_size + line_gap

		draw_string(font, Vector2(pos.x - 100, y_cursor), ft["score_text"],
			HORIZONTAL_ALIGNMENT_CENTER, 200, scaled_size, color)
		y_cursor += scaled_size + line_gap

		if ft["combo_text"] != "":
			var combo_color = _get_combo_color(ft["combo_count"])
			combo_color.a = alpha
			var combo_size = maxi(scaled_size - 4, 10)
			draw_string(font, Vector2(pos.x - 100, y_cursor), ft["combo_text"],
				HORIZONTAL_ALIGNMENT_CENTER, 200, combo_size, combo_color)

func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return BOARD_OFFSET + Vector2(grid_pos.x * CELL_SIZE, (grid_pos.y - BUFFER_ROWS) * CELL_SIZE)

func _draw() -> void:
	if game_logic == null:
		return
		
	var bg_rect = Rect2(BOARD_OFFSET.x, 0, COLS * CELL_SIZE, VISIBLE_ROWS * CELL_SIZE)
	draw_rect(bg_rect, Color(0.1, 0.1, 0.15))

	var line_color = Color(0.2, 0.2, 0.25)
	for i in range(COLS + 1):
		var x = BOARD_OFFSET.x + i * CELL_SIZE
		draw_line(Vector2(x, 0), Vector2(x, VISIBLE_ROWS * CELL_SIZE), line_color)
	for j in range(VISIBLE_ROWS + 1):
		var y = j * CELL_SIZE
		draw_line(Vector2(BOARD_OFFSET.x, y), Vector2(BOARD_OFFSET.x + COLS * CELL_SIZE, y), line_color)

	var grid = game_logic.grid
	for y in range(BUFFER_ROWS, grid.HEIGHT):
		for x in range(grid.WIDTH):
			var cell_value = grid.cells[y][x]
			if cell_value != "":
				var pos = grid_to_screen(Vector2i(x, y))
				if textures.has(cell_value):
					draw_texture(textures[cell_value], pos)

	var active_positions: Array[Vector2i] = []
	if game_logic.active_piece != null:
		active_positions = game_logic.active_piece.get_block_positions()

	var ghost_positions = game_logic.get_ghost_blocks()
	for ghost_pos in ghost_positions:
		if ghost_pos.y >= BUFFER_ROWS and not ghost_pos in active_positions:
			var pos = grid_to_screen(ghost_pos)
			draw_texture(textures["ghost"], pos)

	if game_logic.active_piece != null:
		var piece_type = game_logic.active_piece.type
		if textures.has(piece_type):
			for active_pos in active_positions:
				if active_pos.y >= BUFFER_ROWS:
					var pos = grid_to_screen(active_pos)
					draw_texture(textures[piece_type], pos)

	_draw_floating_texts()
