extends CanvasLayer

const TEXTURE_WIDTH: int = 576
const TEXTURE_HEIGHT: int = 324
const TEXTURE_ASPECT: float = float(TEXTURE_WIDTH) / float(TEXTURE_HEIGHT)
const VIEWPORT_HEIGHT: int = 1040
const SCALE_FACTOR: float = float(VIEWPORT_HEIGHT) / float(TEXTURE_HEIGHT)

const BACKGROUNDS_PATH: String = "res://assets/backgrounds/"
const SHADER_PATH: String = "res://assets/shaders/parallax_layer.gdshader"

var _layer_rects: Array[ColorRect] = []
var _background_sets: Array[String] = []
var _shader: Shader
var _current_set: String = ""


func _ready() -> void:
	layer = -1
	_shader = load(SHADER_PATH)
	_scan_background_sets()
	get_viewport().size_changed.connect(_on_viewport_resized)
	select_random()


func _scan_background_sets() -> void:
	_background_sets.clear()
	var dir := DirAccess.open(BACKGROUNDS_PATH)
	if dir == null:
		return
	dir.list_dir_begin()
	var folder := dir.get_next()
	while folder != "":
		if dir.current_is_dir() and not folder.begins_with("."):
			_background_sets.append(folder)
		folder = dir.get_next()
	_background_sets.sort()


func select_random() -> void:
	if _background_sets.is_empty():
		return
	var idx := randi() % _background_sets.size()
	load_set(_background_sets[idx])


func load_set(bg_set_name: String) -> void:
	_clear_layers()
	_current_set = bg_set_name

	var set_path := BACKGROUNDS_PATH + bg_set_name + "/"
	var dir := DirAccess.open(set_path)
	if dir == null:
		return

	var png_files: Array[String] = []
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".png"):
			png_files.append(file)
		file = dir.get_next()
	png_files.sort_custom(func(a: String, b: String) -> bool:
		return a.get_basename().to_int() < b.get_basename().to_int()
	)

	var layer_count := png_files.size()
	for i in range(layer_count):
		var texture := load(set_path + png_files[i]) as Texture2D
		if texture == null:
			continue
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
	mat.set_shader_parameter("tiles_across", 1.0)
	rect.material = mat

	add_child(rect)
	_layer_rects.append(rect)


func _on_viewport_resized() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var vw := viewport_size.x
	var vh := viewport_size.y

	var tiles_across := (vw / vh) / TEXTURE_ASPECT
	if tiles_across < 1.0:
		tiles_across = 1.0

	for rect in _layer_rects:
		rect.position = Vector2.ZERO
		rect.size = Vector2(vw, vh)
		var mat := rect.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("tiles_across", tiles_across)


func _clear_layers() -> void:
	for rect in _layer_rects:
		rect.queue_free()
	_layer_rects.clear()
	_current_set = ""
