class_name GameManager
extends Node

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: State = State.MENU
var game_board: Node2D
var ui_panel: Control
var menu: Control
var pause_overlay: CanvasLayer
var game_over_overlay: CanvasLayer
var final_score_label: Label


func _ready() -> void:
	menu = $Menu
	game_board = $GameBoard
	ui_panel = $UIPanel
	pause_overlay = $PauseOverlay
	game_over_overlay = $GameOverOverlay
	
	game_board.game_manager = self
	
	var start_btn = menu.get_node("CenterContainer/VBoxContainer/StartButton")
	start_btn.pressed.connect(_on_start_game)
	
	var resume_btn = pause_overlay.get_node("Control/CenterContainer/VBoxContainer/ResumeButton")
	resume_btn.pressed.connect(_resume)
	
	var quit_to_menu_btn = pause_overlay.get_node("Control/CenterContainer/VBoxContainer/QuitButton")
	quit_to_menu_btn.pressed.connect(_quit_to_menu_from_pause)
	
	var play_again_btn = game_over_overlay.get_node("Control/CenterContainer/VBoxContainer/PlayAgainButton")
	play_again_btn.pressed.connect(_play_again)
	
	var menu_btn = game_over_overlay.get_node("Control/CenterContainer/VBoxContainer/MenuButton")
	menu_btn.pressed.connect(_quit_to_menu_from_game_over)
	
	final_score_label = game_over_overlay.get_node("Control/CenterContainer/VBoxContainer/FinalScoreLabel")
	
	_show_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == State.PLAYING:
			_pause()
		elif current_state == State.PAUSED:
			_resume()


func _on_start_game() -> void:
	current_state = State.PLAYING
	menu.hide()
	game_board.show()
	ui_panel.show()
	
	ui_panel.game_logic = game_board.game_logic
	game_board.game_logic.start_game()
	game_board.set_process(true)
	ui_panel.set_process(true)


func _pause() -> void:
	current_state = State.PAUSED
	pause_overlay.show()
	game_board.set_process(false)
	ui_panel.set_process(false)


func _resume() -> void:
	current_state = State.PLAYING
	pause_overlay.hide()
	game_board.set_process(true)
	ui_panel.set_process(true)


func on_game_over(final_score: int) -> void:
	current_state = State.GAME_OVER
	game_board.set_process(false)
	ui_panel.set_process(false)
	final_score_label.text = "Score: " + str(final_score)
	game_over_overlay.show()


func _play_again() -> void:
	current_state = State.PLAYING
	game_over_overlay.hide()
	game_board.game_logic.start_game()
	game_board.set_process(true)
	ui_panel.set_process(true)


func _quit_to_menu_from_pause() -> void:
	current_state = State.MENU
	pause_overlay.hide()
	game_board.hide()
	ui_panel.hide()
	menu.show()


func _quit_to_menu_from_game_over() -> void:
	current_state = State.MENU
	game_over_overlay.hide()
	game_board.hide()
	ui_panel.hide()
	menu.show()


func _show_menu() -> void:
	current_state = State.MENU
	menu.show()
	game_board.hide()
	ui_panel.hide()
	pause_overlay.hide()
	game_over_overlay.hide()
	game_board.set_process(false)
	ui_panel.set_process(false)
