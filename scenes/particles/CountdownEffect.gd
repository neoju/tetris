extends Node2D

signal countdown_finished

const Constants = preload("res://scripts/constants.gd")
const LevelUpEffectScene = preload("res://scenes/particles/LevelUpEffect.tscn")

# Countdown steps: text + duration before next step
const STEPS: Array[Dictionary] = [
	{"text": "3", "duration": 0.75},
	{"text": "2", "duration": 0.75},
	{"text": "1", "duration": 0.75},
	{"text": "GO!", "duration": 0.85},
]

# Animation tuning
const START_FONT_SIZE: float = 20.0
const END_FONT_SIZE: float = 100.0
const GROW_DURATION: float = 0.35         # Time to scale from small → big
const SPARK_DELAY: float = 0.30           # Spark fires as text nears full size
const START_OFFSET_Y: float = 75.0       # Text starts 50px above center

var _center: Vector2
var _current_step: int = -1
var _step_timer: float = 0.0
var _active: bool = false
var _sparked: bool = false

# Current display state
var _display_text: String = ""
var _display_alpha: float = 0.0
var _display_size: float = START_FONT_SIZE
var _display_y_offset: float = START_OFFSET_Y

var _font: Font


func _ready() -> void:
	var base_font := preload("res://assets/fonts/monogram-extended.ttf")
	var font_variation := FontVariation.new()
	font_variation.base_font = base_font
	font_variation.variation_embolden = 0.6
	_font = font_variation

	# Board center (visible area)
	var play_top := Constants.BOARD_OFFSET.y + Constants.BUFFER_ROWS * Constants.CELL_SIZE
	var play_h := Constants.VISIBLE_ROWS * Constants.CELL_SIZE
	var board_w := Constants.COLS * Constants.CELL_SIZE
	_center = Vector2(
		Constants.BOARD_OFFSET.x + board_w * 0.5,
		play_top + play_h * 0.5
	)


func start() -> void:
	_current_step = -1
	_active = true
	_advance_step()


func _advance_step() -> void:
	_current_step += 1
	if _current_step >= STEPS.size():
		_active = false
		_display_text = ""
		queue_redraw()
		countdown_finished.emit()
		queue_free()
		return

	var step: Dictionary = STEPS[_current_step]
	_display_text = step["text"]
	_step_timer = 0.0
	_display_alpha = 1.0
	_display_size = START_FONT_SIZE
	_display_y_offset = START_OFFSET_Y
	_sparked = false
	queue_redraw()


func _spawn_burst() -> void:
	var particles := LevelUpEffectScene.instantiate()
	# Smaller burst for numbers, bigger for GO!
	if _current_step == STEPS.size() - 1:
		particles.amount = 80
	else:
		particles.amount = 35
	particles.configure(_center)
	add_child(particles)


func _process(delta: float) -> void:
	if not _active:
		return

	var step: Dictionary = STEPS[_current_step]
	var duration: float = step["duration"]
	_step_timer += delta

	# Phase 1: Grow from small to big + drift from offset to center
	var grow_t := clampf(_step_timer / GROW_DURATION, 0.0, 1.0)
	# Ease-out curve for smooth deceleration
	var eased_t := 1.0 - (1.0 - grow_t) * (1.0 - grow_t)
	_display_size = lerpf(START_FONT_SIZE, END_FONT_SIZE, eased_t)
	_display_y_offset = lerpf(START_OFFSET_Y, 0.0, eased_t)

	# Fire spark when text reaches near full size
	if not _sparked and _step_timer >= SPARK_DELAY:
		_sparked = true
		_spawn_burst()

	# Phase 2: Fade out after growth completes
	var fade_start := GROW_DURATION
	if _step_timer > fade_start:
		var fade_t := (_step_timer - fade_start) / (duration - fade_start)
		_display_alpha = 1.0 - clampf(fade_t, 0.0, 1.0)
	else:
		_display_alpha = 1.0

	if _step_timer >= duration:
		_advance_step()
		return

	queue_redraw()


func _draw() -> void:
	if _display_text == "":
		return

	var font_size := int(_display_size)
	var color := Color(1.0, 0.85, 0.0, _display_alpha)
	var draw_y := _center.y + _display_y_offset + font_size * 0.35

	draw_string(
		_font,
		Vector2(_center.x - 100, draw_y),
		_display_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		200,
		font_size,
		color
	)
