extends CPUParticles2D

func _ready() -> void:
	emitting = true
	one_shot = true
	explosiveness = 0.9
	lifetime = 0.5
	
	direction = Vector2(0, -1)
	spread = 85.0
	gravity = Vector2(0, 250)
	
	scale_amount_min = 1.0
	scale_amount_max = 2.5
	
	material = _create_additive_material()
	finished.connect(queue_free)

func configure(p_pos: Vector2, p_color: Color, p_amount: int, p_vel_min: float, p_vel_max: float) -> void:
	position = p_pos
	color = p_color
	color.a = 0.9
	amount = p_amount
	initial_velocity_min = p_vel_min
	initial_velocity_max = p_vel_max
	scale_amount_curve = _create_fade_curve()

func _create_additive_material() -> CanvasItemMaterial:
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

func _create_fade_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(0.5, 0.6))
	curve.add_point(Vector2(1.0, 0.0))
	return curve
