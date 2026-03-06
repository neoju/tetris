extends CanvasLayer

const BACKGROUNDS_PATH: String = "res://assets/backgrounds/"
const SHADER_PATH: String = "res://assets/shaders/parallax_layer.gdshader"

# Hardcoded manifest — DirAccess scanning doesn't work on web exports
# because imported .png files are not listed in PCK directory listings.
# Key = set name, value = number of layers (files named 1.png, 2.png, ...).
const SETS: Dictionary = {
	"city_01": 7, "city_02": 8, "city_03": 7, "city_04": 8,
	"city_05": 7, "city_06": 8, "city_07": 7, "city_08": 7,
	"clouds_01": 4, "clouds_02": 4, "clouds_03": 4, "clouds_04": 4,
	"clouds_05": 5, "clouds_06": 6, "clouds_07": 4, "clouds_08": 6,
	"mountain_01": 5, "mountain_02": 7, "mountain_03": 5, "mountain_04": 3,
	"mountain_05": 4, "mountain_06": 5, "mountain_07": 3, "mountain_08": 3,
}

var _layer_rects: Array[ColorRect] = []
var _set_names: Array[String] = []
var _shader: Shader
var _current_set: String = ""
var _texture_size: Vector2 = Vector2(576.0, 324.0)


func _ready() -> void:
	layer = -1
	_shader = load(SHADER_PATH)
	_set_names.assign(SETS.keys())
	_set_names.sort()
	get_viewport().size_changed.connect(_on_viewport_resized)
	select_random()


func select_random() -> void:
	if _set_names.is_empty():
		return
	var idx := randi() % _set_names.size()
	load_set(_set_names[idx])


func load_set(bg_set_name: String) -> void:
	_clear_layers()
	_current_set = bg_set_name

	if not SETS.has(bg_set_name):
		return

	var layer_count: int = SETS[bg_set_name]
	for i in range(layer_count):
		var path := BACKGROUNDS_PATH + bg_set_name + "/" + str(i + 1) + ".png"
		var texture := load(path) as Texture2D
		if texture == null:
			continue
		if i == 0:
			_texture_size = texture.get_size()
		var speed := _calculate_scroll_speed(i, layer_count)
		_create_layer_rect(texture, speed)

	_on_viewport_resized()


func _calculate_scroll_speed(layer_index: int, total_layers: int) -> float:
	if layer_index == 0:
		return 0.0
	var t := float(layer_index) / float(total_layers - 1) if total_layers > 1 else 1.0
	return t * t * 0.04


func _create_layer_rect(texture: Texture2D, scroll_speed: float) -> void:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("layer_texture", texture)
	mat.set_shader_parameter("scroll_speed", scroll_speed)
	rect.material = mat

	add_child(rect)
	_layer_rects.append(rect)


func _on_viewport_resized() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var vw := viewport_size.x
	var vh := viewport_size.y

	# Cover mode: scale texture proportionally to fill entire viewport,
	# cropping excess rather than letterboxing or maintaining aspect ratio.
	var scale_x := vw / _texture_size.x
	var scale_y := vh / _texture_size.y
	var cover_scale := maxf(scale_x, scale_y)

	var rect_w := _texture_size.x * cover_scale
	var rect_h := _texture_size.y * cover_scale

	var offset_x := (vw - rect_w) * 0.5
	var offset_y := (vh - rect_h) * 0.5

	for rect in _layer_rects:
		rect.position = Vector2(offset_x, offset_y)
		rect.size = Vector2(rect_w, rect_h)


func _clear_layers() -> void:
	for rect in _layer_rects:
		rect.queue_free()
	_layer_rects.clear()
	_current_set = ""
