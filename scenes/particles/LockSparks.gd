extends CPUParticles2D

func _ready() -> void:
	emitting = true
	one_shot = true
	explosiveness = 1.0
	lifetime = 0.3
	
	direction = Vector2(0, -1)
	spread = 70.0
	initial_velocity_min = 30.0
	initial_velocity_max = 80.0
	gravity = Vector2(0, 150)
	
	scale_amount_min = 0.8
	scale_amount_max = 2.0
	
	material = _create_additive_material()
	finished.connect(queue_free)

func configure(p_pos: Vector2, p_color: Color) -> void:
	position = p_pos
	color = p_color
	color.a = 0.8

func _create_additive_material() -> CanvasItemMaterial:
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat
