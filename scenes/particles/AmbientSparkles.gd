extends CPUParticles2D

func _ready() -> void:
	emitting = true
	amount = 25
	lifetime = 4.0
	preprocess = 4.0
	
	direction = Vector2(0, -1)
	spread = 30.0
	initial_velocity_min = 15.0
	initial_velocity_max = 40.0
	gravity = Vector2.ZERO
	
	scale_amount_min = 1.0
	scale_amount_max = 2.5
	
	color_ramp = _create_color_ramp()
	
	material = _create_additive_material()

func configure(p_pos: Vector2, p_width: float) -> void:
	position = p_pos
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(p_width, 10.0)

func _create_additive_material() -> CanvasItemMaterial:
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

func _create_color_ramp() -> Gradient:
	var ramp = Gradient.new()
	ramp.set_color(0, Color(0.7, 0.85, 1.0, 0.0))
	ramp.add_point(0.15, Color(0.8, 0.9, 1.0, 0.35))
	ramp.add_point(0.5, Color(1.0, 1.0, 1.0, 0.25))
	ramp.set_color(1, Color(0.7, 0.85, 1.0, 0.0))
	return ramp
