extends GutTest

const LockDelay = preload("res://scripts/lock_delay.gd")


func test_lock_delay_expires_after_500ms() -> void:
	var lock_delay := LockDelay.new()
	lock_delay.start()

	assert_false(lock_delay.update(0.4), "Lock delay should not expire at 0.4s")
	assert_true(lock_delay.update(0.15), "Lock delay should expire after total time exceeds 0.5s")


func test_lock_delay_reset_on_move() -> void:
	var lock_delay := LockDelay.new()
	lock_delay.start()

	assert_false(lock_delay.update(0.4), "Lock delay should not expire before reset")
	lock_delay.reset_on_move()
	assert_false(lock_delay.update(0.4), "Move reset should restart timer")
	assert_true(lock_delay.update(0.15), "Lock delay should expire 0.55s after move reset")


func test_lock_delay_15_move_limit() -> void:
	var lock_delay := LockDelay.new()
	lock_delay.start()

	for _i in range(15):
		lock_delay.reset_on_move()

	assert_true(lock_delay.update(0.001), "15 move resets should force immediate lock")


func test_lock_delay_cancel_and_restart() -> void:
	var lock_delay := LockDelay.new()
	lock_delay.start()
	lock_delay.update(0.2)
	lock_delay.cancel()

	assert_false(lock_delay.update(1.0), "Canceled lock delay should not advance while inactive")

	lock_delay.start()
	assert_true(lock_delay.update(0.6), "Restart should use a fresh timer")


func test_lock_delay_move_count_persists_after_cancel() -> void:
	var lock_delay := LockDelay.new()
	lock_delay.start()

	for _i in range(14):
		lock_delay.reset_on_move()

	lock_delay.cancel()
	lock_delay.start()
	lock_delay.reset_on_move()

	assert_true(lock_delay.update(0.001), "Move count should persist across cancel/start and force lock at 15")


func test_lock_delay_inactive_by_default() -> void:
	var lock_delay := LockDelay.new()
	assert_false(lock_delay.update(1.0), "Lock delay should be inactive until started")


func test_lock_delay_full_reset() -> void:
	var lock_delay := LockDelay.new()
	lock_delay.start()

	for _i in range(10):
		lock_delay.reset_on_move()
	lock_delay.update(0.3)

	lock_delay.reset()
	assert_false(lock_delay.is_active(), "Full reset should set lock delay inactive")
	assert_false(lock_delay.update(1.0), "After reset, update should do nothing until started")

	lock_delay.start()
	for _i in range(14):
		lock_delay.reset_on_move()
	assert_false(lock_delay.update(0.49), "After full reset, move count and timer should start fresh")
	assert_true(lock_delay.update(0.02), "After full reset, timer should require full 0.5s")
