extends Control

## Renders persistent combo/special stats and B2B counter on the LeftScore HUD panel.
## Reads directly from game_logic.scoring each frame.
## - Special actions (TETRIS, T-SPINS, PERFECT CLEAR) have the LARGEST font.
## - Combo streak shows "Combo x <SUM>" at the top.

const Constants = preload("res://scripts/constants.gd")

var game_logic = null

var _total_combos: int = 0
var _special_stats: Dictionary = {} # {action_label: count}
var _b2b_count: int = 0            # Current active B2B streak
var _font_bold: Font

# Custom font sizes for hierarchy
const SPECIAL_FONT_SIZE: int = 42
const COMBO_SUM_FONT_SIZE: int = 32
const B2B_FONT_SIZE: int = 42

# Width for right-aligned text (extending left from the board edge)
const DRAW_WIDTH: float = 200.0


func _ready() -> void:
	var base_font = preload("res://assets/fonts/monogram-extended.ttf")

	# Bold font with heavier embolden
	var font_bold_variation = FontVariation.new()
	font_bold_variation.base_font = base_font
	font_bold_variation.variation_embolden = 0.5
	_font_bold = font_bold_variation


# =============================================================================
# DATA POLLING
# =============================================================================

func _process(_delta: float) -> void:
	if game_logic == null:
		return

	var scoring = game_logic.scoring
	var changed := false

	if _total_combos != scoring.stat_total_combos:
		_total_combos = scoring.stat_total_combos
		changed = true
	if _b2b_count != scoring.stat_max_b2b:
		_b2b_count = scoring.stat_max_b2b
		changed = true
	if scoring.stat_special_counts != _special_stats:
		_special_stats = scoring.stat_special_counts.duplicate()
		changed = true

	if changed:
		queue_redraw()


# =============================================================================
# PUBLIC API
# =============================================================================

func clear() -> void:
	_total_combos = 0
	_special_stats.clear()
	_b2b_count = 0
	queue_redraw()


# =============================================================================
# DRAWING
# =============================================================================

func _draw() -> void:
	# Right-align text to the board edge (with small gap)
	# We use a large DRAW_WIDTH to prevent truncation, extending leftwards.
	var x_pos = Constants.LEFT_PANEL_X_RIGHT - DRAW_WIDTH
	var y = Constants.LEFT_PANEL_Y_START
	
	# 1. Total Combo Sum (at the top: "Combo x <SUM>")
	if _total_combos > 0:
		var combo_text = "Combo x " + str(_total_combos)
		draw_string(_font_bold, Vector2(x_pos, y), combo_text,
			HORIZONTAL_ALIGNMENT_RIGHT, DRAW_WIDTH,
			COMBO_SUM_FONT_SIZE, Color(1.0, 1.0, 0.3))
		y += COMBO_SUM_FONT_SIZE + Constants.LEFT_PANEL_LINE_GAP
	
	# 2. B2B current streak (if active)
	if _b2b_count > 0:
		draw_string(_font_bold, Vector2(x_pos, y), "B2B x" + str(_b2b_count),
			HORIZONTAL_ALIGNMENT_RIGHT, DRAW_WIDTH, 
			B2B_FONT_SIZE, Color(1.0, 0.85, 0.0))
		y += B2B_FONT_SIZE + Constants.LEFT_PANEL_LINE_GAP
	
	# 3. Special Action counts (ALWAYS show, LARGEST font)
	if not _special_stats.is_empty():
		var special_labels = _special_stats.keys()
		special_labels.sort() # Alphabetical
		
		for label in special_labels:
			var count = _special_stats[label]
			var text = label + " x " + str(count)
			
			var color = Color(1.0, 0.6, 0.1) # Golden/Orange
			if label == "PERFECT CLEAR":
				color = Color(1.0, 1.0, 1.0) # White
			
			draw_string(_font_bold, Vector2(x_pos, y), text,
				HORIZONTAL_ALIGNMENT_RIGHT, DRAW_WIDTH,
				SPECIAL_FONT_SIZE, color)
			y += SPECIAL_FONT_SIZE + Constants.LEFT_PANEL_LINE_GAP


# =============================================================================
# HELPERS
# =============================================================================

func _get_combo_color(combo: int) -> Color:
	if combo >= 3:
		return Color(1.0, 0.2, 0.2)
	if combo >= 2:
		return Color(1.0, 0.6, 0.1)
	return Color(1.0, 1.0, 0.3)
