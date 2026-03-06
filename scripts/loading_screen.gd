extends Node2D

# =============================================================================
# LOADING SCREEN
# =============================================================================
# Lightweight entry scene that background-loads the main game via
# ResourceLoader.load_threaded_request(), displays a Tetris-themed
# pixel-art progress bar, then transitions with change_scene_to_packed().
# No class_name — follows Node-script convention.
# =============================================================================

const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const MIN_DISPLAY_TIME: float = 0.5

# --- Visual Constants ---
const BG_COLOR := Color(0.05, 0.02, 0.12)
const GRID_SPACING: int = 32
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.018)

const SEGMENT_COUNT: int = 20
const SEGMENT_W: int = 14
const SEGMENT_H: int = 14
const SEGMENT_GAP: int = 2
const BAR_BORDER: int = 2
const BAR_PADDING: int = 3

const BORDER_COLOR := Color(0.65, 0.65, 0.72)
const BAR_BG_COLOR := Color(0.09, 0.09, 0.14)
const EMPTY_COLOR := Color(0.1, 0.1, 0.16)
const TEXT_COLOR := Color(0.75, 0.82, 0.95)

const PIECE_COLORS: Array[Color] = [
	Color("#00F0F0"),  # I - Cyan
	Color("#0000FF"),  # J - Blue
	Color("#FFA500"),  # L - Orange
	Color("#FFFF00"),  # O - Yellow
	Color("#00FF00"),  # S - Green
	Color("#800080"),  # T - Purple
	Color("#FF0000"),  # Z - Red
]

# --- State ---
var _font: Font
var _font_bold: Font
var _time: float = 0.0
var _display_progress: float = 0.0
var _actual_progress: float = 0.0
var _scene_loaded: bool = false
var _loaded_scene: PackedScene = null


func _ready() -> void:
	# Set up fonts (same pattern as game_board.gd)
	var base_font: Font = preload("res://assets/fonts/monogram-extended.ttf")

	var font_variation := FontVariation.new()
	font_variation.base_font = base_font
	font_variation.variation_embolden = 0.3
	_font = font_variation

	var font_bold_variation := FontVariation.new()
	font_bold_variation.base_font = base_font
	font_bold_variation.variation_embolden = 0.5
	_font_bold = font_bold_variation

	# Start background loading
	ResourceLoader.load_threaded_request(MAIN_SCENE_PATH, "", true)


func _process(delta: float) -> void:
	_time += delta

	# Poll loading status
	if not _scene_loaded:
		var progress: Array = []
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(MAIN_SCENE_PATH, progress)

		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				if progress.size() > 0:
					_actual_progress = progress[0]
			ResourceLoader.THREAD_LOAD_LOADED:
				_actual_progress = 1.0
				_scene_loaded = true
				_loaded_scene = ResourceLoader.load_threaded_get(MAIN_SCENE_PATH) as PackedScene
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load main scene: " + MAIN_SCENE_PATH)
				_actual_progress = 1.0
				_scene_loaded = true
				# Fallback: try synchronous load
				_loaded_scene = load(MAIN_SCENE_PATH) as PackedScene

	# Smooth progress animation (lerp towards actual)
	_display_progress = lerpf(_display_progress, _actual_progress, delta * 8.0)

	# Transition when loaded, min display time elapsed, and bar visually complete
	if _scene_loaded and _loaded_scene != null and _time >= MIN_DISPLAY_TIME and _display_progress > 0.99:
		get_tree().change_scene_to_packed(_loaded_scene)
		return

	queue_redraw()


func _draw() -> void:
	var vp_size := get_viewport_rect().size

	# --- Background ---
	draw_rect(Rect2(Vector2.ZERO, vp_size), BG_COLOR)

	# --- Faint grid pattern ---
	var x: float = 0.0
	while x <= vp_size.x:
		draw_line(Vector2(x, 0), Vector2(x, vp_size.y), GRID_COLOR, 1.0)
		x += GRID_SPACING
	var y: float = 0.0
	while y <= vp_size.y:
		draw_line(Vector2(0, y), Vector2(vp_size.x, y), GRID_COLOR, 1.0)
		y += GRID_SPACING

	# --- Center point ---
	var center_x: float = vp_size.x * 0.5
	var center_y: float = vp_size.y * 0.5

	# --- Title: "TETRIS" ---
	var title_text: String = "TETRIS"
	var title_size: int = 54
	var title_str_size: Vector2 = _font_bold.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, title_size)
	var title_pos := Vector2(center_x - title_str_size.x * 0.5, center_y - 20)
	draw_string(_font_bold, title_pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, TEXT_COLOR)

	# --- Progress Bar ---
	var inner_w: float = SEGMENT_COUNT * SEGMENT_W + (SEGMENT_COUNT - 1) * SEGMENT_GAP
	var total_w: float = inner_w + 2 * (BAR_BORDER + BAR_PADDING)
	var total_h: float = SEGMENT_H + 2 * (BAR_BORDER + BAR_PADDING)
	var bar_x: float = center_x - total_w * 0.5
	var bar_y: float = center_y + 20

	# Border
	draw_rect(Rect2(bar_x, bar_y, total_w, total_h), BORDER_COLOR, false, float(BAR_BORDER))

	# Background fill
	var inner_rect := Rect2(
		bar_x + BAR_BORDER,
		bar_y + BAR_BORDER,
		total_w - 2 * BAR_BORDER,
		total_h - 2 * BAR_BORDER
	)
	draw_rect(inner_rect, BAR_BG_COLOR)

	# Segments
	var seg_origin_x: float = bar_x + BAR_BORDER + BAR_PADDING
	var seg_origin_y: float = bar_y + BAR_BORDER + BAR_PADDING
	var filled_count: int = int(_display_progress * SEGMENT_COUNT)
	var current_seg: int = filled_count  # The segment currently loading (pulsing)

	for i in range(SEGMENT_COUNT):
		var sx: float = seg_origin_x + i * (SEGMENT_W + SEGMENT_GAP)
		var seg_rect := Rect2(sx, seg_origin_y, SEGMENT_W, SEGMENT_H)

		if i < filled_count:
			# Filled segment — cycling tetromino color
			var color: Color = PIECE_COLORS[i % PIECE_COLORS.size()]
			draw_rect(seg_rect, color)
			_draw_pixel_block(seg_rect, color)
		elif i == current_seg and not _scene_loaded:
			# Pulsing current segment
			var pulse: float = (sin(_time * 5.0) + 1.0) * 0.5  # 0..1
			var color: Color = PIECE_COLORS[i % PIECE_COLORS.size()]
			var dim_color: Color = color * 0.25
			var half_color: Color = color * 0.5
			var pulsed: Color = dim_color.lerp(half_color, pulse)
			pulsed.a = 1.0
			draw_rect(seg_rect, pulsed)
		else:
			# Empty segment
			draw_rect(seg_rect, EMPTY_COLOR)

	# --- Loading text ---
	var pct: int = int(_display_progress * 100.0)
	var loading_text: String = "LOADING... " + str(pct) + "%"
	var load_size: int = 22
	var load_str_size: Vector2 = _font.get_string_size(loading_text, HORIZONTAL_ALIGNMENT_CENTER, -1, load_size)
	var load_pos := Vector2(center_x - load_str_size.x * 0.5, bar_y + total_h + 24)
	draw_string(_font, load_pos, loading_text, HORIZONTAL_ALIGNMENT_LEFT, -1, load_size, TEXT_COLOR)


func _draw_pixel_block(rect: Rect2, _base_color: Color) -> void:
	# Pixel-art highlight (top + left edges)
	var highlight := Color(1.0, 1.0, 1.0, 0.25)
	var highlight_inner := Color(1.0, 1.0, 1.0, 0.2)
	# Top edge - 2px
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 1), highlight)
	draw_rect(Rect2(rect.position.x, rect.position.y + 1, rect.size.x - 1, 1), highlight_inner)
	# Left edge - 2px
	draw_rect(Rect2(rect.position.x, rect.position.y, 1, rect.size.y), highlight)
	draw_rect(Rect2(rect.position.x + 1, rect.position.y + 1, 1, rect.size.y - 2), highlight_inner)

	# Pixel-art shadow (bottom + right edges)
	var shadow := Color(0.0, 0.0, 0.0, 0.3)
	var shadow_inner := Color(0.0, 0.0, 0.0, 0.25)
	# Bottom edge - 2px
	draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - 1, rect.size.x, 1), shadow)
	draw_rect(Rect2(rect.position.x + 1, rect.position.y + rect.size.y - 2, rect.size.x - 1, 1), shadow_inner)
	# Right edge - 2px
	draw_rect(Rect2(rect.position.x + rect.size.x - 1, rect.position.y, 1, rect.size.y), shadow)
	draw_rect(Rect2(rect.position.x + rect.size.x - 2, rect.position.y + 1, 1, rect.size.y - 2), shadow_inner)
