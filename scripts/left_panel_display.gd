extends Control

## Renders persistent stats on the left HUD panel.
## Reads directly from game_logic.scoring each frame.
## Display order (top to bottom), equal vertical spacing:
##   1. Special actions (TETRIS, T-SPIN, PERFECT CLEAR) — largest, most prominent
##   2. B2B streak — secondary
##   3. Combo total — tertiary

const Constants = preload("res://scripts/constants.gd")

var game_logic = null

var _total_combos: int = 0
var _special_stats: Dictionary = {}
var _b2b_count: int = 0

var _font: Font
var _font_bold: Font

# Shadow for readability against parallax backgrounds
const SHADOW_OFFSET := Vector2(1, 2)
const SHADOW_COLOR := Color(0.0, 0.0, 0.05, 0.55)


func _ready() -> void:
	var base_font = preload("res://assets/fonts/monogram-extended.ttf")

	var font_variation = FontVariation.new()
	font_variation.base_font = base_font
	font_variation.variation_embolden = 0.3
	_font = font_variation

	var font_bold_variation = FontVariation.new()
	font_bold_variation.base_font = base_font
	font_bold_variation.variation_embolden = 0.5
	_font_bold = font_bold_variation

	queue_redraw()


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
	var draw_w := Constants.LEFT_PANEL_DRAW_WIDTH
	var x_pos := Constants.LEFT_PANEL_X_RIGHT - draw_w
	var y := Constants.LEFT_PANEL_Y_START
	var gap := Constants.LEFT_PANEL_LINE_GAP

	# 1. Special actions (TETRIS, T-SPIN, PERFECT CLEAR) — most prominent
	if not _special_stats.is_empty():
		var special_labels := _special_stats.keys()
		special_labels.sort()

		for label in special_labels:
			var count: int = _special_stats[label]
			var text = _abbreviate(label) + " x " + str(count)
			var color := _get_special_color(label)

			_draw_shadowed(_font_bold, Vector2(x_pos, y), text, draw_w,
				Constants.LEFT_PANEL_SPECIAL_FONT_SIZE, color)
			y += Constants.LEFT_PANEL_SPECIAL_FONT_SIZE + gap

	# 3. B2B streak
	if _b2b_count > 0:
		_draw_shadowed(_font_bold, Vector2(x_pos, y), "B2B x" + str(_b2b_count), draw_w,
			Constants.LEFT_PANEL_B2B_FONT_SIZE, Color(1.0, 0.85, 0.0))
		y += Constants.LEFT_PANEL_B2B_FONT_SIZE + gap

	# 4. Combo total
	if _total_combos > 0:
		_draw_shadowed(_font_bold, Vector2(x_pos, y), "Combo x " + str(_total_combos), draw_w,
			Constants.LEFT_PANEL_COMBO_FONT_SIZE, Color(0.9, 1.0, 0.3))


# =============================================================================
# HELPERS
# =============================================================================

func _draw_shadowed(font: Font, pos: Vector2, text: String, width: float,
		font_size: int, color: Color) -> void:
	draw_string(font, pos + SHADOW_OFFSET, text,
		HORIZONTAL_ALIGNMENT_RIGHT, width, font_size, SHADOW_COLOR)
	draw_string(font, pos, text,
		HORIZONTAL_ALIGNMENT_RIGHT, width, font_size, color)


func _get_special_color(label: String) -> Color:
	if "TETRIS" in label:
		return Color(0.0, 1.0, 1.0)      # Cyan — matches I-piece
	if "T-SPIN" in label:
		return Color(0.85, 0.35, 1.0)    # Purple — matches T-piece
	if "PERFECT" in label:
		return Color(1.0, 1.0, 1.0)      # White — celebratory
	return Color(1.0, 0.6, 0.1)          # Golden fallback


func _abbreviate(label: String) -> String:
	# Shorten long action labels to fit panel width
	# Order matters: check "T-SPIN MINI" before "T-SPIN"
	return label.replace("T-SPIN MINI", "TSM").replace("T-SPIN", "TS").replace("PERFECT CLEAR", "PERFECT")
