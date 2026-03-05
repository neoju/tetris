class_name InputHandler
extends RefCounted

const DAS_DELAY: float = 0.167
const ARR_RATE: float = 0.033

var _das_timer_left: float = 0.0
var _das_timer_right: float = 0.0
var _das_charged_left: bool = false
var _das_charged_right: bool = false
var _arr_timer_left: float = 0.0
var _arr_timer_right: float = 0.0


func process_input(delta: float) -> Dictionary:
	var actions := {
		"move": Vector2i.ZERO,
		"rotate_cw": false,
		"rotate_ccw": false,
		"hard_drop": false,
		"soft_drop": false,
		"hold": false,
		"pause": false
	}

	actions["rotate_cw"] = Input.is_action_just_pressed("rotate_cw")
	actions["rotate_ccw"] = Input.is_action_just_pressed("rotate_ccw")
	actions["hard_drop"] = Input.is_action_just_pressed("hard_drop")
	actions["soft_drop"] = Input.is_action_pressed("soft_drop")
	actions["hold"] = Input.is_action_just_pressed("hold")
	actions["pause"] = Input.is_action_just_pressed("pause")

	var left_just := Input.is_action_just_pressed("move_left")
	var right_just := Input.is_action_just_pressed("move_right")
	var left_pressed := Input.is_action_pressed("move_left")
	var right_pressed := Input.is_action_pressed("move_right")

	# Prioritize right when both are active.
	if right_just:
		_reset_left_state()
		_start_right()
		actions["move"] = Vector2i.RIGHT
	elif left_just:
		_reset_right_state()
		_start_left()
		actions["move"] = Vector2i.LEFT
	elif right_pressed:
		if left_pressed:
			_reset_left_state()
		actions["move"] = _update_right_repeat(delta)
	elif left_pressed:
		actions["move"] = _update_left_repeat(delta)
	else:
		_reset_left_state()
		_reset_right_state()

	if not left_pressed:
		_reset_left_state()
	if not right_pressed:
		_reset_right_state()

	return actions


func reset() -> void:
	_reset_left_state()
	_reset_right_state()


func _start_left() -> void:
	_das_timer_left = 0.0
	_das_charged_left = false
	_arr_timer_left = 0.0


func _start_right() -> void:
	_das_timer_right = 0.0
	_das_charged_right = false
	_arr_timer_right = 0.0


func _reset_left_state() -> void:
	_das_timer_left = 0.0
	_das_charged_left = false
	_arr_timer_left = 0.0


func _reset_right_state() -> void:
	_das_timer_right = 0.0
	_das_charged_right = false
	_arr_timer_right = 0.0


func _update_left_repeat(delta: float) -> Vector2i:
	if not _das_charged_left:
		_das_timer_left += delta
		if _das_timer_left >= DAS_DELAY:
			_das_charged_left = true
			_arr_timer_left = 0.0
		return Vector2i.ZERO

	_arr_timer_left += delta
	if _arr_timer_left >= ARR_RATE:
		_arr_timer_left -= ARR_RATE
		return Vector2i.LEFT

	return Vector2i.ZERO


func _update_right_repeat(delta: float) -> Vector2i:
	if not _das_charged_right:
		_das_timer_right += delta
		if _das_timer_right >= DAS_DELAY:
			_das_charged_right = true
			_arr_timer_right = 0.0
		return Vector2i.ZERO

	_arr_timer_right += delta
	if _arr_timer_right >= ARR_RATE:
		_arr_timer_right -= ARR_RATE
		return Vector2i.RIGHT

	return Vector2i.ZERO
