extends Node

# NO class_name — autoload singleton (avoids "hides autoload" error)

const Constants = preload("res://scripts/constants.gd")

var enabled: bool = true

var _player: AudioStreamPlayer

# Hardcoded manifest — DirAccess scanning doesn't work on web exports
const _TRACK_FILES: Array[String] = [
	"res://assets/music/a_welcome_haunting.ogg",
	"res://assets/music/hi_score_hustle.ogg",
	"res://assets/music/its_snowtime.ogg",
	"res://assets/music/lily_paddling_down_the_stream.ogg",
	"res://assets/music/thinking_and_tinkering.ogg",
	"res://assets/music/veil_of_dreams.ogg",
]


func _ready() -> void:
	randomize()
	_player = AudioStreamPlayer.new()
	_player.volume_db = Constants.MUSIC_VOLUME_DB
	_player.bus = "Master"
	add_child(_player)
	_player.finished.connect(_on_track_finished)


# =============================================================================
# PUBLIC API
# =============================================================================

func play() -> void:
	if not enabled:
		return
	var path: String = _TRACK_FILES[randi() % _TRACK_FILES.size()]
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_player.stream = stream
	_player.play()


func stop() -> void:
	_player.stop()


func pause() -> void:
	_player.stream_paused = true


func unpause() -> void:
	if not enabled:
		return
	_player.stream_paused = false


func toggle() -> bool:
	enabled = not enabled
	if not enabled:
		_player.stream_paused = true
	else:
		if _player.playing:
			_player.stream_paused = false
		else:
			play()
	return enabled


# =============================================================================
# LOOPING
# =============================================================================

func _on_track_finished() -> void:
	if enabled and not _player.stream_paused:
		play()
