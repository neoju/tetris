extends Node2D

## Renders combo/clear/B2B display on the left panel.
## Single active display at a time — new events replace previous.
## Added as a child of GameBoard — inherits shake transform automatically.

const Constants = preload("res://scripts/constants.gd")

var _active_display: Dictionary = {}
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
	_active_display = {}
	queue_redraw()


func update_display(delta: float) -> void:
	if _active_display.is_empty():
		return

	_active_display["timer"] += delta

	if _active_display["timer"] >= _active_display["duration"]:
		_active_display = {}

	queue_redraw()


func spawn(events: Dictionary) -> void:
	var lines = events.get("lines_cleared", 0)
	var is_tspin = events.get("is_tspin", false)
	var is_mini = events.get("is_tspin_mini", false)
	var is_b2b = events.get("is_back_to_back", false)
	var b2b_count = events.get("back_to_back_count", 0)
	var combo = events.get("combo_count", -1)

	var action_text = _get_action_label(lines, is_tspin, is_mini)
	var b2b_text = ""
	if is_b2b:
		b2b_text = "B2B x" + str(b2b_count)

	var combo_text = ""
	if combo >= 1:
		combo_text = str(combo + 1) + " COMBO"

	_active_display = {
		"action_text": action_text,
		"b2b_text": b2b_text,
		"combo_text": combo_text,
		"timer": 0.0,
		"duration": Constants.LEFT_PANEL_TOTAL_DURATION,
		"color": _get_score_color(lines, is_tspin, is_b2b, false),
		"position": Vector2(Constants.LEFT_PANEL_X_RIGHT, Constants.LEFT_PANEL_Y_START),
		"combo_count": combo,
	}

	queue_redraw()


func spawn_level_up() -> void:
	_active_display = {
		"action_text": "LEVEL UP!",
		"b2b_text": "",
		"combo_text": "",
		"timer": 0.0,
		"duration": Constants.LEFT_PANEL_TOTAL_DURATION,
		"color": Color(1.0, 0.85, 0.0),
		"position": Vector2(Constants.LEFT_PANEL_X_RIGHT, Constants.LEFT_PANEL_Y_START),
		"combo_count": -1,
	}

	queue_redraw()


# =============================================================================
# DRAWING
# =============================================================================

func _draw() -> void:
	if _active_display.is_empty():
		return

	var t = _active_display["timer"] / _active_display["duration"]
	var hold_end = Constants.LEFT_PANEL_HOLD_DURATION / Constants.LEFT_PANEL_TOTAL_DURATION
	var alpha = 1.0
	if t > hold_end:
		alpha = 1.0 - (t - hold_end) / (1.0 - hold_end)
	alpha = clampf(alpha, 0.0, 1.0)

	var scale_t = clampf(_active_display["timer"] / Constants.SCALE_SETTLE_TIME, 0.0, 1.0)
	var scale_factor = lerpf(Constants.SCALE_PUNCH, 1.0, scale_t)

	var pos = _active_display["position"]
	var color: Color = _active_display["color"]
	color.a = alpha

	var y_cursor = pos.y

	# B2B line (if present)
	if _active_display["b2b_text"] != "":
		var b2b_color = Color(1.0, 0.85, 0.0, alpha)
		var b2b_size = int(Constants.LEFT_PANEL_B2B_FONT_SIZE * scale_factor)
		draw_string(_font_bold, Vector2(pos.x, y_cursor), _active_display["b2b_text"],
			HORIZONTAL_ALIGNMENT_RIGHT, Constants.LEFT_PANEL_TEXT_WIDTH, b2b_size, b2b_color)
		y_cursor += b2b_size + Constants.LEFT_PANEL_LINE_GAP

	# Action line (always)
	var action_size = int(Constants.LEFT_PANEL_ACTION_FONT_SIZE * scale_factor)
	draw_string(_font_bold, Vector2(pos.x, y_cursor), _active_display["action_text"],
		HORIZONTAL_ALIGNMENT_RIGHT, Constants.LEFT_PANEL_TEXT_WIDTH, action_size, color)
	y_cursor += action_size + Constants.LEFT_PANEL_LINE_GAP

	# Combo line (if present)
	if _active_display["combo_text"] != "":
		var combo_color = _get_combo_color(_active_display["combo_count"])
		combo_color.a = alpha
		var combo_size = int(Constants.LEFT_PANEL_COMBO_FONT_SIZE * scale_factor)
		draw_string(_font_bold, Vector2(pos.x, y_cursor), _active_display["combo_text"],
			HORIZONTAL_ALIGNMENT_RIGHT, Constants.LEFT_PANEL_TEXT_WIDTH, combo_size, combo_color)


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
