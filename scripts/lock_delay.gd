class_name LockDelay
extends RefCounted

var _timer: float = 0.0
var _move_count: int = 0
var _active: bool = false


func start() -> void:
	_active = true
	_timer = 0.0


func reset_on_move() -> void:
	if _active and _move_count < Constants.MAX_MOVES:
		_timer = 0.0
		_move_count += 1


func update(delta: float) -> bool:
	if not _active:
		return false

	_timer += delta
	return _timer >= Constants.LOCK_TIME or _move_count >= Constants.MAX_MOVES


func cancel() -> void:
	_active = false
	_timer = 0.0


func reset() -> void:
	_timer = 0.0
	_move_count = 0
	_active = false


func is_active() -> bool:
	return _active
