extends Node2D

const GameLogicScript = preload("res://scripts/game_logic.gd")
const GridScript = preload("res://scripts/grid.gd")

const CELL_SIZE = 32
const BOARD_OFFSET = Vector2(80, 0)
const COLS = GridScript.WIDTH
const VISIBLE_ROWS = GridScript.VISIBLE_HEIGHT
const BUFFER_ROWS = GridScript.BUFFER_ROWS

var game_logic: GameLogicScript
var textures: Dictionary = {}
var game_manager = null

func _ready() -> void:
	# Map piece types to color names (assets are named by color)
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

func _process(delta: float) -> void:
	if game_logic != null:
		var events = game_logic.update(delta)

		# SFX triggers based on events
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
		if events.get("level_up", false):
			SfxManager.play("level_up")
		if events.get("game_over", false):
			SfxManager.play("game_over")
			if game_manager != null:
				game_manager.on_game_over(game_logic.scoring.score)

		queue_redraw()

func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return BOARD_OFFSET + Vector2(grid_pos.x * CELL_SIZE, (grid_pos.y - BUFFER_ROWS) * CELL_SIZE)

func _draw() -> void:
	if game_logic == null:
		return
		
	# 1. Draw grid background
	var bg_rect = Rect2(BOARD_OFFSET.x, 0, COLS * CELL_SIZE, VISIBLE_ROWS * CELL_SIZE)
	draw_rect(bg_rect, Color(0.1, 0.1, 0.15))

	# Draw grid lines
	var line_color = Color(0.2, 0.2, 0.25)
	for i in range(COLS + 1):
		var x = BOARD_OFFSET.x + i * CELL_SIZE
		draw_line(Vector2(x, 0), Vector2(x, VISIBLE_ROWS * CELL_SIZE), line_color)
	for j in range(VISIBLE_ROWS + 1):
		var y = j * CELL_SIZE
		draw_line(Vector2(BOARD_OFFSET.x, y), Vector2(BOARD_OFFSET.x + COLS * CELL_SIZE, y), line_color)

	# 2. Draw locked blocks
	var grid = game_logic.grid
	for y in range(BUFFER_ROWS, grid.HEIGHT):
		for x in range(grid.WIDTH):
			var cell_value = grid.cells[y][x]
			if cell_value != "":
				var pos = grid_to_screen(Vector2i(x, y))
				if textures.has(cell_value):
					draw_texture(textures[cell_value], pos)

	# Get active positions early to check for overlaps
	var active_positions: Array[Vector2i] = []
	if game_logic.active_piece != null:
		active_positions = game_logic.active_piece.get_block_positions()

	# 3. Draw ghost piece
	var ghost_positions = game_logic.get_ghost_blocks()
	for ghost_pos in ghost_positions:
		if ghost_pos.y >= BUFFER_ROWS and not ghost_pos in active_positions:
			var pos = grid_to_screen(ghost_pos)
			draw_texture(textures["ghost"], pos)

	# 4. Draw active piece
	if game_logic.active_piece != null:
		var piece_type = game_logic.active_piece.type
		if textures.has(piece_type):
			for active_pos in active_positions:
				if active_pos.y >= BUFFER_ROWS:
					var pos = grid_to_screen(active_pos)
					draw_texture(textures[piece_type], pos)
