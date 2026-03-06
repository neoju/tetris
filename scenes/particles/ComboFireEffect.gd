extends CPUParticles2D

var _stopping: bool = false


func _ready() -> void:
	emitting = false
	one_shot = false

	direction = Vector2(0, -1)
	spread = 100.0
	gravity = Vector2(0, -10)
	damping_min = 5.0
	damping_max = 15.0
	angular_velocity_min = -90.0
	angular_velocity_max = 90.0

	scale_amount_curve = _create_scale_curve()
	material = _create_additive_material()


func configure(p_pos: Vector2, p_width: float) -> void:
	position = p_pos
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(p_width, 3.0)


func set_intensity(combo_level: int) -> void:
	_stopping = false
	emitting = true

	if combo_level <= 1:
		# Combo 2 — small fire
		amount = 30
		lifetime = 0.5
		initial_velocity_min = 25.0
		initial_velocity_max = 55.0
		scale_amount_min = 3.0
		scale_amount_max = 5.5
	elif combo_level == 2:
		# Combo 3 — medium fire
		amount = 60
		lifetime = 0.7
		initial_velocity_min = 35.0
		initial_velocity_max = 75.0
		scale_amount_min = 3.5
		scale_amount_max = 6.5
	else:
		# Combo 4+ — big fire, scales slightly with combo
		var extra := mini(combo_level - 3, 4)
		amount = 90 + extra * 5
		lifetime = 0.9
		initial_velocity_min = 45.0
		initial_velocity_max = 100.0
		scale_amount_min = 4.5
		scale_amount_max = 8.0

	color_ramp = _create_fire_ramp(combo_level)


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
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(0.5, 0.7))
	curve.add_point(Vector2(1.0, 0.0))
	return curve


func _create_fire_ramp(combo_level: int) -> Gradient:
	var intensity := clampf(0.4 + combo_level * 0.15, 0.4, 0.85)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.4, intensity))
	ramp.add_point(0.25, Color(1.0, 0.6, 0.15, intensity * 0.85))
	ramp.add_point(0.55, Color(0.9, 0.25, 0.05, intensity * 0.5))
	ramp.set_color(1, Color(0.4, 0.08, 0.0, 0.0))
	return ramp
