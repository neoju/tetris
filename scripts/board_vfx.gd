class_name BoardVfx
extends RefCounted

## Pure-logic VFX state for the game board: clear animations, screen shake, border glow.
## No rendering — exposes state for GameBoard._draw() to consume.

const Constants = preload("res://scripts/constants.gd")


# === Clear Animation ===
var clear_anim: Dictionary = {}       # {"timer": float, "rows_data": Array, "lines": int}


# === Screen Shake ===
var shake_intensity: float = 0.0
var shake_timer: float = 0.0


# === Border Glow ===
var border_glow: float = 0.0
var border_glow_color: Color = Color.WHITE


# =============================================================================
# CLEAR ANIMATION
# =============================================================================

func is_clearing() -> bool:
	return clear_anim.size() > 0


func start_clear(events: Dictionary) -> void:
	var rows_data = events.get("cleared_rows_data", [])
	if rows_data.size() == 0:
		return
	clear_anim = {
		"timer": 0.0,
		"rows_data": rows_data,
		"lines": events.get("lines_cleared", 0),
	}


func update_clear(delta: float) -> bool:
	## Advance the clear timer. Returns true when the animation finishes.
	if clear_anim.size() == 0:
		return false

	clear_anim["timer"] += delta

	if clear_anim["timer"] >= Constants.CLEAR_TOTAL_DURATION:
		clear_anim = {}
		return true  # animation finished — caller should complete_clear()
	return false


func get_clearing_rows() -> Array[int]:
	if clear_anim.size() == 0:
		return []
	var rows: Array[int] = []
	for row_info in clear_anim["rows_data"]:
		rows.append(row_info["row"])
	return rows


# =============================================================================
# SCREEN SHAKE
# =============================================================================

func apply_shake(intensity: float) -> void:
	## Only apply if stronger than current shake.
	if intensity > shake_intensity:
		shake_intensity = intensity
		shake_timer = 0.0


func trigger_shake(events: Dictionary) -> void:
	var lines = events.get("lines_cleared", 0)
	var is_tspin = events.get("is_tspin", false)
	var is_pc = events.get("is_perfect_clear", false)

	var intensity: float
	if is_pc:
		intensity = 6.0
	elif lines == 4 or is_tspin:
		intensity = 4.5
	elif lines == 3:
		intensity = 3.0
	elif lines == 2:
		intensity = 2.0
	else:
		intensity = 1.2

	shake_intensity = intensity
	shake_timer = 0.0


func update_shake(delta: float) -> Vector2:
	## Decay shake and return the offset to apply to board position.
	if shake_intensity <= 0.1:
		shake_intensity = 0.0
		return Vector2.ZERO

	shake_timer += delta
	shake_intensity *= exp(-Constants.SHAKE_DECAY * delta)

	return Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)


# =============================================================================
# BORDER GLOW
# =============================================================================

func trigger_border_glow(events: Dictionary) -> void:
	var lines = events.get("lines_cleared", 0)
	var is_tspin = events.get("is_tspin", false)
	var is_pc = events.get("is_perfect_clear", false)

	if is_pc:
		border_glow = 1.0
		border_glow_color = Color(1.0, 0.2, 1.0)  # Magenta for perfect clear
	elif lines == 4 or is_tspin:
		border_glow = 1.0
		border_glow_color = Color(0.0, 1.0, 1.0)  # Cyan for Tetris/T-spin
	elif lines >= 2:
		border_glow = 0.7
		border_glow_color = Color(1.0, 1.0, 0.3)  # Yellow for multi-line
	else:
		border_glow = 0.4
		border_glow_color = Color.WHITE


func update_border_glow(delta: float) -> void:
	if border_glow <= 0.01:
		border_glow = 0.0
		return
	border_glow *= exp(-Constants.BORDER_GLOW_DECAY * delta)


# =============================================================================
# RESET
# =============================================================================

func reset() -> void:
	clear_anim = {}
	shake_intensity = 0.0
	shake_timer = 0.0
	border_glow = 0.0
	border_glow_color = Color.WHITE
