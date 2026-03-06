extends CPUParticles2D

func _ready() -> void:
	emitting = true
	one_shot = true
	explosiveness = 0.85
	amount = 80
	lifetime = 1.2

	# Radial burst in all directions
	direction = Vector2(0, -1)
	spread = 180.0
	initial_velocity_min = 60.0
	initial_velocity_max = 200.0
	gravity = Vector2(0, 80)

	# Size
	scale_amount_min = 1.5
	scale_amount_max = 4.0
	scale_amount_curve = _create_fade_curve()

	# Gold color ramp
	color_ramp = _create_color_ramp()

	# Blend mode (additive glow)
	material = _create_additive_material()

	# Auto-remove when done
	finished.connect(queue_free)

func configure(p_pos: Vector2) -> void:
	position = p_pos

func _create_additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

func _create_color_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.4, 1.0))       # Bright gold
	ramp.add_point(0.3, Color(1.0, 0.8, 0.2, 0.9))       # Warm gold
	ramp.add_point(0.6, Color(1.0, 0.6, 0.1, 0.5))       # Orange-gold fade
	ramp.set_color(1, Color(1.0, 0.4, 0.0, 0.0))         # Fade to transparent
	return ramp

func _create_fade_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.5))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(0.6, 0.6))
	curve.add_point(Vector2(1.0, 0.0))
	return curve
