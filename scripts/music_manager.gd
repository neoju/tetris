extends Node

# NO class_name — autoload singleton (avoids "hides autoload" error)

const Constants = preload("res://scripts/constants.gd")

var enabled: bool = true

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _current_tier: int = -1
var _current_level: int = 1
var _current_pack: int = -1
var _tracks: Dictionary = {}           # tier_index -> AudioStream (lazy-loaded)
var _loading_tier: int = -1            # tier currently being background-loaded
var _crossfade_tween: Tween = null

const _PACK_COUNT: int = 3
const _TIER_COUNT: int = 3
const _FADE_OUT_DB: float = -40.0


func _ready() -> void:
	randomize()

	_player_a = AudioStreamPlayer.new()
	_player_a.volume_db = Constants.MUSIC_VOLUME_DB
	_player_a.bus = "Master"
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.volume_db = _FADE_OUT_DB
	_player_b.bus = "Master"
	add_child(_player_b)

	_active_player = _player_a


# =============================================================================
# PUBLIC API
# =============================================================================

func play_for_level(level: int) -> void:
	if not enabled:
		return
	_current_level = level
	var tier := _get_tier_for_level(level)

	if tier == _current_tier:
		# Same tier — just adjust pitch_scale within tier
		_update_pitch_scale(level)
		return

	# Tier changed — crossfade to new track
	var stream := _get_or_load_track(tier)
	if stream == null:
		return

	_current_tier = tier
	_crossfade_to(stream)
	_update_pitch_scale(level)

	# Preload next tier in background
	_preload_next_tier(tier)


func stop() -> void:
	_player_a.stop()
	_player_b.stop()
	_current_tier = -1
	_tracks.clear()
	_loading_tier = -1
	if _crossfade_tween != null:
		_crossfade_tween.kill()
		_crossfade_tween = null


func pause() -> void:
	_player_a.stream_paused = true
	_player_b.stream_paused = true


func unpause() -> void:
	if not enabled:
		return
	_player_a.stream_paused = false
	_player_b.stream_paused = false


func toggle() -> bool:
	enabled = not enabled
	if not enabled:
		_player_a.stream_paused = true
		_player_b.stream_paused = true
	else:
		# If we have a current tier, resume; otherwise start fresh
		if _current_tier >= 0:
			_player_a.stream_paused = false
			_player_b.stream_paused = false
		elif _current_level > 0:
			play_for_level(_current_level)
	return enabled


## Begin background load of tier 1 track (call during countdown).
## Also picks a random pack for this game session.
func preload_initial_track() -> void:
	_select_random_pack()
	_tracks.clear()
	_loading_tier = -1
	var path: String = _get_track_path(0)
	ResourceLoader.load_threaded_request(path)
	_loading_tier = 0


# =============================================================================
# PACK SELECTION
# =============================================================================

func _select_random_pack() -> void:
	_current_pack = randi() % _PACK_COUNT + 1


func _get_track_path(tier: int) -> String:
	return "res://assets/music/pack_%d/tier_%d.wav" % [_current_pack, tier + 1]


# =============================================================================
# TIER RESOLUTION
# =============================================================================

func _get_tier_for_level(level: int) -> int:
	var tiers: Array = Constants.MUSIC_TIER_LEVELS
	var tier := 0
	for i in range(tiers.size()):
		if level >= tiers[i]:
			tier = i
	return tier


func _update_pitch_scale(level: int) -> void:
	var tiers: Array = Constants.MUSIC_TIER_LEVELS
	var tier := _get_tier_for_level(level)
	var tier_start: int = tiers[tier]
	var tier_end: int
	if tier + 1 < tiers.size():
		tier_end = tiers[tier + 1] - 1
	else:
		tier_end = 15

	var tier_range := float(tier_end - tier_start)
	var progress: float = 0.0
	if tier_range > 0:
		progress = float(level - tier_start) / tier_range

	# Subtle pitch increase within tier: 1.0 → 1.06
	var pitch := 1.0 + progress * 0.06
	_active_player.pitch_scale = pitch


# =============================================================================
# LAZY LOADING
# =============================================================================

func _configure_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		# Calculate sample count from raw data size (16-bit mono = 2 bytes/sample)
		var bytes_per_sample := 2
		if stream.stereo:
			bytes_per_sample = 4
		stream.loop_end = stream.data.size() / bytes_per_sample


func _get_or_load_track(tier: int) -> AudioStream:
	if _tracks.has(tier):
		return _tracks[tier]

	if _current_pack < 1:
		return null

	# Check if background load completed
	var path: String = _get_track_path(tier)
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var stream_res = ResourceLoader.load_threaded_get(path)
		_configure_loop(stream_res)
		_tracks[tier] = stream_res
		return _tracks[tier]

	# Synchronous fallback — small WAV files load fast
	var stream = load(path)
	if stream != null:
		_configure_loop(stream)
		_tracks[tier] = stream
	return stream


func _preload_next_tier(current_tier: int) -> void:
	var next_tier := current_tier + 1
	if next_tier >= _TIER_COUNT:
		return
	if _tracks.has(next_tier):
		return
	if _loading_tier == next_tier:
		return

	var path: String = _get_track_path(next_tier)
	ResourceLoader.load_threaded_request(path)
	_loading_tier = next_tier


# =============================================================================
# CROSSFADE
# =============================================================================

func _crossfade_to(stream: AudioStream) -> void:
	if _crossfade_tween != null:
		_crossfade_tween.kill()

	# Determine which player is inactive
	var new_player: AudioStreamPlayer
	if _active_player == _player_a:
		new_player = _player_b
	else:
		new_player = _player_a

	var old_player := _active_player

	# Set up new player
	new_player.stream = stream
	new_player.volume_db = _FADE_OUT_DB
	new_player.stream_paused = false
	new_player.play()

	# Crossfade tween
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(new_player, "volume_db", Constants.MUSIC_VOLUME_DB, Constants.MUSIC_CROSSFADE_TIME)
	_crossfade_tween.tween_property(old_player, "volume_db", _FADE_OUT_DB, Constants.MUSIC_CROSSFADE_TIME)
	_crossfade_tween.set_parallel(false)
	_crossfade_tween.tween_callback(old_player.stop)

	_active_player = new_player
