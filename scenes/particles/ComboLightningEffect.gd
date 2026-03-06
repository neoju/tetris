extends CPUParticles2D

var _stopping: bool = false


func _ready() -> void:
	emitting = false
	one_shot = false

	gravity = Vector2(0, 30)
	damping_min = 10.0
	damping_max = 30.0
	angular_velocity_min = -120.0
	angular_velocity_max = 120.0

	scale_amount_curve = _create_scale_curve()
	material = _create_additive_material()


func configure(p_pos: Vector2, p_height: float, facing_right: bool) -> void:
	position = p_pos
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(3.0, p_height)
	if facing_right:
		direction = Vector2(1, -0.3)
	else:
		direction = Vector2(-1, -0.3)
	spread = 50.0


func set_intensity(combo_level: int) -> void:
	_stopping = false
	emitting = true

	if combo_level <= 2:
		# Combo 3 — subtle lightning
		amount = 10
		lifetime = 0.3
		initial_velocity_min = 20.0
		initial_velocity_max = 50.0
		scale_amount_min = 2.8
		scale_amount_max = 4.0
	else:
		# Combo 4+ — intense lightning, scales with combo
		var extra := mini(combo_level - 3, 4)
		amount = 18 + extra * 3
		lifetime = 0.4
		initial_velocity_min = 30.0
		initial_velocity_max = 70.0
		scale_amount_min = 4.0
		scale_amount_max = 7

	color_ramp = _create_lightning_ramp(combo_level)


func stop() -> void:
	if _stopping:
		return
	_stopping = true
	emitting = false
	get_tree().create_timer(lifetime + 0.2).timeout.connect(queue_free)


func _create_additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


func _create_scale_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.3, 0.6))
	curve.add_point(Vector2(1.0, 0.0))
	return curve


func _create_lightning_ramp(combo_level: int) -> Gradient:
	var intensity := clampf(0.35 + (combo_level - 2) * 0.15, 0.35, 0.75)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, intensity))
	ramp.add_point(0.2, Color(0.7, 0.9, 1.0, intensity * 0.8))
	ramp.add_point(0.5, Color(0.35, 0.55, 1.0, intensity * 0.4))
	ramp.set_color(1, Color(0.2, 0.3, 0.8, 0.0))
	return ramp
