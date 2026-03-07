class_name GameManager
extends Node

enum State { MENU, COUNTDOWN, PLAYING, PAUSED, GAME_OVER }

const Constants = preload("res://scripts/constants.gd")
const CountdownEffectScene = preload("res://scenes/particles/CountdownEffect.tscn")

var current_state: State = State.MENU
var game_board: Node2D
var hud: Control
var title_screen: Control
var pause_menu: CanvasLayer
var game_over_screen: CanvasLayer
var credits_screen: Control
var final_score_label: Label
var stats_label: Label
var sfx_toggle: TextureButton
var music_toggle: TextureButton
var ghost_toggle: TextureButton

var _game_content: Node2D
var _background_layer: CanvasLayer


func _ready() -> void:
	_background_layer = $BackgroundLayer
	_game_content = $GameContent
	title_screen = $TitleScreen
	game_board = $GameContent/GameBoard
	hud = $GameContent/HUD
	pause_menu = $PauseMenu
	game_over_screen = $GameOverScreen
	credits_screen = $CreditsScreen

	game_board.game_manager = self

	var start_btn = title_screen.get_node("CenterContainer/PanelContainer/VBoxContainer/StartButton")
	start_btn.pressed.connect(_on_start_pressed)

	var credits_btn = title_screen.get_node("CenterContainer/PanelContainer/VBoxContainer/CreditsButton")
	credits_btn.pressed.connect(_on_credits_pressed)

	var back_btn = credits_screen.get_node("CenterContainer/PanelContainer/VBoxContainer/BackButton")
	back_btn.pressed.connect(_back_to_menu_from_credits)

	var music_link = credits_screen.get_node("CenterContainer/PanelContainer/VBoxContainer/MusicLink")
	music_link.pressed.connect(_open_url.bind("https://fablefly-music.itch.io"))

	var game_link = credits_screen.get_node("CenterContainer/PanelContainer/VBoxContainer/GameLink")
	game_link.pressed.connect(_open_url.bind("https://tetr.io"))

	var linkedin_link = credits_screen.get_node("CenterContainer/PanelContainer/VBoxContainer/LinkedInLink")
	linkedin_link.pressed.connect(_open_url.bind("https://www.linkedin.com/in/neoju"))

	var resume_btn = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/ResumeButton")
	resume_btn.pressed.connect(_resume)

	var quit_to_menu_btn = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/QuitButton")
	quit_to_menu_btn.pressed.connect(_quit_to_menu_from_pause)

	var play_again_btn = game_over_screen.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/PlayAgainButton")
	play_again_btn.pressed.connect(_play_again)

	var menu_btn = game_over_screen.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/MenuButton")
	menu_btn.pressed.connect(_quit_to_menu_from_game_over)

	final_score_label = game_over_screen.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/FinalScoreLabel")
	stats_label = game_over_screen.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/StatsLabel")

	sfx_toggle = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/SfxRow/SfxToggle")
	sfx_toggle.toggled.connect(_on_sfx_toggled)

	music_toggle = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/MusicRow/MusicToggle")
	music_toggle.toggled.connect(_on_music_toggled)

	ghost_toggle = pause_menu.get_node("Control/CenterContainer/PanelContainer/VBoxContainer/GhostRow/GhostToggle")
	ghost_toggle.toggled.connect(_on_ghost_toggled)

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

	_show_title_screen()


func _on_viewport_resized() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var visible_top := Constants.BOARD_OFFSET.y + Constants.BUFFER_ROWS * Constants.CELL_SIZE
	var board_center_x := Constants.BOARD_OFFSET.x + Constants.COLS * Constants.CELL_SIZE * 0.5
	var board_center_y := visible_top + Constants.VISIBLE_ROWS * Constants.CELL_SIZE * 0.5
	_game_content.position.x = viewport_size.x * 0.5 - board_center_x
	_game_content.position.y = viewport_size.y * 0.5 - board_center_y


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

	if fresh_game:
		_background_layer.select_random()
		hud.game_logic = game_board.game_logic
		game_board.game_logic.start_game()
		game_board.clear_floating_texts()

	game_board.set_process(false)
	hud.set_process(true)

	var countdown := CountdownEffectScene.instantiate()
	countdown.countdown_finished.connect(_on_countdown_finished)
	game_board.add_child(countdown)
	countdown.start()


func _on_countdown_finished() -> void:
	current_state = State.PLAYING
	game_board.set_process(true)
	hud.set_process(true)
	MusicManager.play()


# =============================================================================
# PAUSE / RESUME
# =============================================================================

func _pause() -> void:
	current_state = State.PAUSED
	pause_menu.show()
	game_board.set_process(false)
	hud.set_process(false)
	MusicManager.pause()


func _resume() -> void:
	current_state = State.PLAYING
	pause_menu.hide()
	game_board.set_process(true)
	hud.set_process(true)
	MusicManager.unpause()


# =============================================================================
# GAME OVER
# =============================================================================

func on_game_over(final_score: int) -> void:
	current_state = State.GAME_OVER
	game_board.set_process(false)
	hud.set_process(false)
	final_score_label.text = "Score: " + str(final_score)
	stats_label.text = _build_stats_text()
	game_over_screen.show()
	MusicManager.stop()


func _build_stats_text() -> String:
	var scoring: Scoring = game_board.game_logic.scoring
	var stats: Dictionary = scoring.get_end_stats()

	var text_lines: Array[String] = []
	text_lines.append("Level: " + str(scoring.level) + "  |  Lines: " + str(scoring.lines_cleared))

	# Clear type breakdown (only non-zero)
	var clears: Array[String] = []
	if stats["singles"] > 0: clears.append("Single: " + str(stats["singles"]))
	if stats["doubles"] > 0: clears.append("Double: " + str(stats["doubles"]))
	if stats["triples"] > 0: clears.append("Triple: " + str(stats["triples"]))
	if stats["tetrises"] > 0: clears.append("Tetris: " + str(stats["tetrises"]))
	if clears.size() > 0:
		text_lines.append("")
		for i in range(0, clears.size(), 2):
			if i + 1 < clears.size():
				text_lines.append(clears[i] + "   " + clears[i + 1])
			else:
				text_lines.append(clears[i])

	# T-spin stats (only non-zero)
	var tspins: Array[String] = []
	if stats["tspin_singles"] > 0: tspins.append("TSS: " + str(stats["tspin_singles"]))
	if stats["tspin_doubles"] > 0: tspins.append("TSD: " + str(stats["tspin_doubles"]))
	if stats["tspin_triples"] > 0: tspins.append("TST: " + str(stats["tspin_triples"]))
	if stats["tspin_mini_singles"] > 0: tspins.append("Mini: " + str(stats["tspin_mini_singles"]))
	if tspins.size() > 0:
		text_lines.append("")
		text_lines.append("  ".join(tspins))

	# Combo chains
	var combo_chains: Dictionary = stats["combo_chains"]
	var levels: Array = combo_chains.keys()
	levels.sort()
	if levels.size() > 0:
		var combo_parts: Array[String] = []
		for level in levels:
			var count: int = combo_chains[level]
			if count > 0:
				combo_parts.append(str(count) + "x C" + str(level))
		if combo_parts.size() > 0:
			text_lines.append("")
			text_lines.append("  ".join(combo_parts))

	# Max combo, B2B, Perfect Clears
	var footer: Array[String] = []
	if stats["max_combo"] > 0: footer.append("Max Combo: " + str(stats["max_combo"]))
	if stats["max_b2b"] > 0: footer.append("B2B: " + str(stats["max_b2b"]))
	if stats["perfect_clears"] > 0: footer.append("PC: " + str(stats["perfect_clears"]))
	if footer.size() > 0:
		text_lines.append("")
		text_lines.append("  |  ".join(footer))

	return "\n".join(text_lines)


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
	title_screen.show()
	MusicManager.stop()


func _quit_to_menu_from_game_over() -> void:
	current_state = State.MENU
	game_over_screen.hide()
	game_board.hide()
	hud.hide()
	title_screen.show()
	MusicManager.stop()


func _show_title_screen() -> void:
	current_state = State.MENU
	title_screen.show()
	game_board.hide()
	hud.hide()
	pause_menu.hide()
	game_over_screen.hide()
	credits_screen.hide()
	game_board.set_process(false)
	hud.set_process(false)


# =============================================================================
# CREDITS
# =============================================================================

func _on_credits_pressed() -> void:
	title_screen.hide()
	credits_screen.show()


func _back_to_menu_from_credits() -> void:
	credits_screen.hide()
	title_screen.show()


func _open_url(url: String) -> void:
	OS.shell_open(url)


# =============================================================================
# SETTINGS TOGGLES
# =============================================================================

func _on_sfx_toggled(is_on: bool) -> void:
	SfxManager.enabled = is_on


func _on_music_toggled(_is_on: bool) -> void:
	MusicManager.toggle()


func _on_ghost_toggled(is_on: bool) -> void:
	game_board.show_ghost = is_on
