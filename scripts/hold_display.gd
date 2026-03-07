extends Control

const TetrominoData = preload("res://scripts/tetromino_data.gd")

@export var header_height: float = 28.0
@export var top_padding: float = 10.0
@export var block_size: float = 22.0

var game_logic = null
var _textures: Dictionary = {}


func _ready() -> void:
	var type_to_file := {
		"I": "cyan", "J": "blue", "L": "orange", "O": "yellow",
		"S": "green", "T": "purple", "Z": "red"
	}
	for piece_type in type_to_file:
		_textures[piece_type] = load("res://assets/blocks/block_" + type_to_file[piece_type] + ".png")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game_logic == null:
		return
	if game_logic.hold_piece_type == "":
		return

	var alpha := 1.0 if game_logic.can_hold else 0.35
	_draw_piece(game_logic.hold_piece_type, size.x / 2.0, header_height + top_padding, alpha)


func _draw_piece(piece_type: String, center_x: float, top_y: float, alpha: float = 1.0) -> void:
	var offsets: Array = TetrominoData.SHAPES[piece_type][0]
	var tex: Texture2D = _textures[piece_type]
	var modulate := Color(1.0, 1.0, 1.0, alpha)

	var min_x := 999
	var max_x := -999
	var min_y := 999
	var max_y := -999
	for offset in offsets:
		min_x = mini(min_x, offset.x)
		max_x = maxi(max_x, offset.x)
		min_y = mini(min_y, offset.y)
		max_y = maxi(max_y, offset.y)

	var piece_width := (max_x - min_x + 1) * block_size
	var piece_height := (max_y - min_y + 1) * block_size
	var start_x := center_x - piece_width / 2.0
	var start_y := top_y + (block_size * 2 - piece_height) / 2.0

	for offset in offsets:
		var rect := Rect2(
			start_x + (offset.x - min_x) * block_size,
			start_y + (offset.y - min_y) * block_size,
			block_size, block_size
		)
		draw_texture_rect(tex, rect, false, modulate)
