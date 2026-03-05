extends Control

const TetrominoData = preload("res://scripts/tetromino_data.gd")

var game_logic = null

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if game_logic == null:
		return
		
	var font = ThemeDB.fallback_font
	
	# --- Left Panel: Hold ---
	var left_center_x = 40.0
	draw_string(font, Vector2(0, 30), "HOLD", HORIZONTAL_ALIGNMENT_CENTER, 80, 16, Color.WHITE)
	
	if game_logic.hold_piece_type != "":
		var alpha = 1.0 if game_logic.can_hold else 0.4
		_draw_mini_piece(game_logic.hold_piece_type, left_center_x, 60.0, 14.0, alpha)

	# --- Right Panel: Next ---
	var right_start_x = 400.0
	var right_center_x = 440.0
	draw_string(font, Vector2(right_start_x, 30), "NEXT", HORIZONTAL_ALIGNMENT_CENTER, 80, 16, Color.WHITE)
	
	var next_pieces = game_logic.get_next_pieces(3)
	for i in range(next_pieces.size()):
		_draw_mini_piece(next_pieces[i], right_center_x, 60.0 + i * 70.0, 14.0, 1.0)
		
	# --- Right Panel: Stats ---
	var stats_start_y = 300.0
	
	draw_string(font, Vector2(right_start_x, stats_start_y), "SCORE", HORIZONTAL_ALIGNMENT_CENTER, 80, 14, Color.GRAY)
	draw_string(font, Vector2(right_start_x, stats_start_y + 25), str(game_logic.scoring.score), HORIZONTAL_ALIGNMENT_CENTER, 80, 18, Color.WHITE)
	
	draw_string(font, Vector2(right_start_x, stats_start_y + 65), "LEVEL", HORIZONTAL_ALIGNMENT_CENTER, 80, 14, Color.GRAY)
	draw_string(font, Vector2(right_start_x, stats_start_y + 90), str(game_logic.scoring.level), HORIZONTAL_ALIGNMENT_CENTER, 80, 18, Color.WHITE)
	
	draw_string(font, Vector2(right_start_x, stats_start_y + 130), "LINES", HORIZONTAL_ALIGNMENT_CENTER, 80, 14, Color.GRAY)
	draw_string(font, Vector2(right_start_x, stats_start_y + 155), str(game_logic.scoring.lines_cleared), HORIZONTAL_ALIGNMENT_CENTER, 80, 18, Color.WHITE)

func _draw_mini_piece(piece_type: String, center_x: float, top_y: float, block_size: float, alpha: float = 1.0) -> void:
	var offsets = TetrominoData.SHAPES[piece_type][0]
	var color = TetrominoData.COLORS[piece_type]
	if alpha < 1.0:
		color.a = alpha
		
	var min_x = 999
	var max_x = -999
	var min_y = 999
	var max_y = -999
	for offset in offsets:
		min_x = mini(min_x, offset.x)
		max_x = maxi(max_x, offset.x)
		min_y = mini(min_y, offset.y)
		max_y = maxi(max_y, offset.y)
		
	var piece_width = (max_x - min_x + 1) * block_size
	var start_x = center_x - piece_width / 2.0
	var start_y = top_y
	
	for offset in offsets:
		var rect = Rect2(
			start_x + (offset.x - min_x) * block_size,
			start_y + (offset.y - min_y) * block_size,
			block_size - 1, block_size - 1
		)
		draw_rect(rect, color)
