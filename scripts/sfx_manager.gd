extends Node

var enabled: bool = true
var _sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

func _ready() -> void:
	for i in range(Constants.SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.volume_db = Constants.SFX_VOLUME_DB
		add_child(player)
		_players.append(player)
	
	var sfx_names = ["move", "rotate", "hard_drop", "soft_drop", "line_clear", 
	                 "tetris_clear", "hold", "lock", "game_over", "level_up",
	                 "combo_1", "combo_2", "combo_3", "combo_high"]
	for sfx_name in sfx_names:
		var path = "res://assets/sfx/" + sfx_name + ".wav"
		_sounds[sfx_name] = load(path)

func play(sfx_name: String) -> void:
	if not enabled:
		return
	if not _sounds.has(sfx_name):
		return
	var player = _players[_next_player]
	player.stream = _sounds[sfx_name]
	player.play()
	_next_player = (_next_player + 1) % Constants.SFX_POOL_SIZE


func toggle() -> bool:
	enabled = not enabled
	return enabled
