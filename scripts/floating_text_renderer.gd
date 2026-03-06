extends Node2D

## Renders floating score/action/combo text above the game board.
## Added as a child of GameBoard — inherits shake transform automatically.
## No own _process(); parent calls update_texts(delta) explicitly.

const Constants = preload("res://scripts/constants.gd")

var _texts: Array = []
var _font: Font
var _font_bold: Font


func _ready() -> void:
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


func clear() -> void:
	_texts.clear()
	queue_redraw()


func update_texts(delta: float) -> void:
	var i = _texts.size() - 1
	while i >= 0:
		var ft = _texts[i]
		ft["timer"] += delta
		ft["position"].y -= Constants.FLOAT_SPEED * delta
		if ft["timer"] >= ft["duration"]:
			_texts.remove_at(i)
		i -= 1
	queue_redraw()


func spawn(events: Dictionary) -> void:
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

	_texts.append({
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


func spawn_level_up(center: Vector2) -> void:
	_texts.append({
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
# DRAWING
# =============================================================================

func _draw() -> void:
	for ft in _texts:
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
# HELPERS
# =============================================================================

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
