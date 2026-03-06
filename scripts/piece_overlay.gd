extends Control

@export var hold_panel_path: NodePath = ^"../HoldBG"
@export var next_panel_path: NodePath = ^"../NextBG"
@export var header_height: float = 22.0
@export var hold_piece_top_padding: float = 10.0
@export var next_piece_top_padding: float = 12.0
@export var next_piece_spacing: float = 66.0
@export var block_size: float = 14.0

var game_logic = null

@onready var hold_panel: Control = get_node_or_null(hold_panel_path)
@onready var next_panel: Control = get_node_or_null(next_panel_path)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game_logic == null:
		return
	if hold_panel == null or next_panel == null:
		return

	var hold_rect := Rect2(hold_panel.position, hold_panel.size)
	var next_rect := Rect2(next_panel.position, next_panel.size)

	# Borders are authored in hud.tscn (Panel styleboxes), not drawn here.

	# Hold piece
	if game_logic.hold_piece_type != "":
		var alpha = 1.0 if game_logic.can_hold else 0.35
		_draw_mini_piece(game_logic.hold_piece_type,
			hold_rect.position.x + hold_rect.size.x / 2.0,
			hold_rect.position.y + header_height + hold_piece_top_padding,
			block_size,
			alpha)

	# Next pieces (3)
	var next_pieces = game_logic.get_next_pieces(3)
	for i in range(next_pieces.size()):
		_draw_mini_piece(next_pieces[i],
			next_rect.position.x + next_rect.size.x / 2.0,
			next_rect.position.y + header_height + next_piece_top_padding + i * next_piece_spacing,
			block_size,
			1.0)


func _draw_mini_piece(piece_type: String, center_x: float, top_y: float, mini_block_size: float, alpha: float = 1.0) -> void:
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

	var piece_width = (max_x - min_x + 1) * mini_block_size
	var piece_height = (max_y - min_y + 1) * mini_block_size
	var start_x = center_x - piece_width / 2.0
	var start_y = top_y + (mini_block_size * 2 - piece_height) / 2.0

	for offset in offsets:
		var rect = Rect2(
			start_x + (offset.x - min_x) * mini_block_size,
			start_y + (offset.y - min_y) * mini_block_size,
			mini_block_size - 1, mini_block_size - 1
		)
		draw_rect(rect, color)
