class_name GameManager
extends Node

enum State { MENU, COUNTDOWN, PLAYING, PAUSED, GAME_OVER }

const CountdownEffectScene = preload("res://scenes/particles/CountdownEffect.tscn")

var current_state: State = State.MENU
var game_board: Node2D
var hud: Control
var title_screen: Control
var pause_menu: CanvasLayer
var game_over_screen: CanvasLayer
var final_score_label: Label
var menu_button: Button
var sfx_toggle: TextureButton
var ghost_toggle: TextureButton


func _ready() -> void:
	title_screen = $TitleScreen
	game_board = $GameBoard
	hud = $HUD
	pause_menu = $PauseMenu
	game_over_screen = $GameOverScreen

	game_board.game_manager = self

	var start_btn = title_screen.get_node("CenterContainer/PanelContainer/VBoxContainer/StartButton")
	start_btn.pressed.connect(_on_start_pressed)

	var resume_btn = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/ResumeButton")
	resume_btn.pressed.connect(_resume)

	var quit_to_menu_btn = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/QuitButton")
	quit_to_menu_btn.pressed.connect(_quit_to_menu_from_pause)

	var play_again_btn = game_over_screen.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/PlayAgainButton")
	play_again_btn.pressed.connect(_play_again)

	var menu_btn = game_over_screen.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/MenuButton")
	menu_btn.pressed.connect(_quit_to_menu_from_game_over)

	final_score_label = game_over_screen.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/FinalScoreLabel")

	# SFX toggle
	sfx_toggle = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/SfxRow/SfxToggle")
	sfx_toggle.toggled.connect(_on_sfx_toggled)

	# Ghost toggle
	ghost_toggle = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/GhostRow/GhostToggle")
	ghost_toggle.toggled.connect(_on_ghost_toggled)

	# Create in-game menu button (hamburger ≡)
	_create_menu_button()

	_show_title_screen()


func _create_menu_button() -> void:
	# Get menu button from HUD scene (authored in .tscn)
	menu_button = hud.get_node("MenuButton")
	menu_button.visible = false
	menu_button.pressed.connect(_pause)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == State.PLAYING:
			_pause()
		elif current_state == State.PAUSED:
			_resume()


# =============================================================================
# COUNTDOWN
# =============================================================================

func _on_start_pressed() -> void:
	_begin_countdown(true)


func _begin_countdown(fresh_game: bool) -> void:
	current_state = State.COUNTDOWN
	title_screen.hide()
	game_over_screen.hide()
	game_board.show()
	hud.show()
	menu_button.visible = false

	if fresh_game:
		hud.game_logic = game_board.game_logic
		game_board.game_logic.start_game()
		game_board.clear_floating_texts()

	# Board visible but not processing game logic during countdown
	game_board.set_process(false)
	hud.set_process(true)

	# Spawn countdown overlay on the game board so particles render in board space
	var countdown := CountdownEffectScene.instantiate()
	countdown.countdown_finished.connect(_on_countdown_finished)
	game_board.add_child(countdown)
	countdown.start()


func _on_countdown_finished() -> void:
	current_state = State.PLAYING
	menu_button.visible = true
	game_board.set_process(true)
	hud.set_process(true)


# =============================================================================
# PAUSE / RESUME
# =============================================================================

func _pause() -> void:
	current_state = State.PAUSED
	pause_menu.show()
	menu_button.visible = false
	game_board.set_process(false)
	hud.set_process(false)


func _resume() -> void:
	current_state = State.PLAYING
	pause_menu.hide()
	menu_button.visible = true
	game_board.set_process(true)
	hud.set_process(true)


# =============================================================================
# GAME OVER
# =============================================================================

func on_game_over(final_score: int) -> void:
	current_state = State.GAME_OVER
	menu_button.visible = false
	game_board.set_process(false)
	hud.set_process(false)
	final_score_label.text = "Score: " + str(final_score)
	game_over_screen.show()


func _play_again() -> void:
	game_over_screen.hide()
	_begin_countdown(true)


# =============================================================================
# MENU NAVIGATION
# =============================================================================

func _quit_to_menu_from_pause() -> void:
	current_state = State.MENU
	pause_menu.hide()
	game_board.hide()
	hud.hide()
	menu_button.visible = false
	title_screen.show()


func _quit_to_menu_from_game_over() -> void:
	current_state = State.MENU
	game_over_screen.hide()
	game_board.hide()
	hud.hide()
	menu_button.visible = false
	title_screen.show()


func _show_title_screen() -> void:
	current_state = State.MENU
	title_screen.show()
	game_board.hide()
	hud.hide()
	menu_button.visible = false
	pause_menu.hide()
	game_over_screen.hide()
	game_board.set_process(false)
	hud.set_process(false)


func _on_sfx_toggled(is_on: bool) -> void:
	SfxManager.enabled = is_on


func _on_ghost_toggled(is_on: bool) -> void:
	game_board.show_ghost = is_on
