extends Node2D

## Renders persistent combo and B2B counters on the left panel.
## Counters remain visible while active, no fade-out animation.
## Added as a child of GameBoard — inherits shake transform automatically.

const Constants = preload("res://scripts/constants.gd")

var _combo_count: int = -1  # -1 = no combo, 0+ = active combo
var _b2b_count: int = 0     # 0 = no B2B, 1+ = active B2B
var _font_bold: Font


func _ready() -> void:
	var base_font = preload("res://assets/fonts/monogram-extended.ttf")

	# Bold font with heavier embolden
	var font_bold_variation = FontVariation.new()
	font_bold_variation.base_font = base_font
	font_bold_variation.variation_embolden = 0.5
	_font_bold = font_bold_variation


# =============================================================================
# PUBLIC API
# =============================================================================

func update_combo(count: int) -> void:
	_combo_count = count
	queue_redraw()


func update_b2b(count: int) -> void:
	_b2b_count = count
	queue_redraw()


func clear_combo() -> void:
	_combo_count = -1
	queue_redraw()


func clear_b2b() -> void:
	_b2b_count = 0
	queue_redraw()


func clear() -> void:
	clear_combo()
	clear_b2b()


# =============================================================================
# DRAWING
# =============================================================================

func _draw() -> void:
	var y = Constants.LEFT_PANEL_Y_START
	
	# B2B counter (if active)
	if _b2b_count > 0:
		draw_string(_font_bold, Vector2(0, y), "B2B x" + str(_b2b_count),
			HORIZONTAL_ALIGNMENT_RIGHT, Constants.LEFT_PANEL_X_RIGHT, 
			Constants.LEFT_PANEL_B2B_FONT_SIZE, Color(1.0, 0.85, 0.0))
		y += Constants.LEFT_PANEL_B2B_FONT_SIZE + Constants.LEFT_PANEL_LINE_GAP
	
	# Combo counter (if active: combo 1+ displays as "2 COMBO", "3 COMBO"...)
	if _combo_count >= 1:
		var combo_text = str(_combo_count + 1) + " COMBO"
		var combo_color = _get_combo_color(_combo_count)
		draw_string(_font_bold, Vector2(0, y), combo_text,
			HORIZONTAL_ALIGNMENT_RIGHT, Constants.LEFT_PANEL_X_RIGHT,
			Constants.LEFT_PANEL_COMBO_FONT_SIZE, combo_color)


# =============================================================================
# HELPERS
# =============================================================================

func _get_combo_color(combo: int) -> Color:
	if combo >= 3:
		return Color(1.0, 0.2, 0.2)
	if combo >= 2:
		return Color(1.0, 0.6, 0.1)
	return Color(1.0, 1.0, 0.3)
