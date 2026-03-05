extends CPUParticles2D

@export var particle_color: Color = Color.WHITE
@export var emission_width: float = 160.0

func _ready() -> void:
	# Base configuration (static)
	emitting = true
	one_shot = true
	explosiveness = 0.95
	lifetime = 0.6
	
	# Direction
	direction = Vector2(0, -1)
	spread = 45.0
	initial_velocity_min = 45.0
	initial_velocity_max = 150.0
	gravity = Vector2(0, 200)
	
	# Size
	scale_amount_min = 1.5
	scale_amount_max = 3.5
	
	# Blend mode (additive glow)
	material = _create_additive_material()
	
	# Connect finished to auto-remove
	finished.connect(queue_free)

func configure(p_pos: Vector2, p_color: Color, p_amount: int, p_width: float = 160.0) -> void:
	position = p_pos
	color = p_color
	color.a = 0.9
	amount = p_amount
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(p_width, 3.0)
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
