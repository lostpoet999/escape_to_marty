extends Node

class AmbientPlayerData:
	var player: AudioStreamPlayer
	var playlist: AmbientPlaylist
	var finish_callback: Callable

@export var music_playlists: Array[MusicPlaylist] = []
@export var ambient_sets: Array[AmbienceSet] = []
## Volume_db the music fades to while the game-over screen is up; restored when play resumes or the main menu loads.
@export var game_over_music_db: float = -18.0
## Seconds to fade the music down on game over (and back up when leaving it).
@export var game_over_duck_time: float = 0.5
## Song crossfaded in while a memory plays (flame click -> room exit).
@export var memory_song: AudioStream
@export var memory_song_volume_db: float = -12.0
## Playback speed of the memory song; below 1.0 slows and deepens it.
@export var memory_song_pitch: float = 0.6
@export var memory_fade_seconds: float = 1.5
var music_system: Dictionary = {}
var ambient_system: Dictionary = {}
var active_ambient_players: Dictionary = {}
@onready var music_player: AudioStreamPlayer = $music_player
var currently_playing_playlist: MusicPlaylist
var current_playlist_name: String
var current_track_index: int = -1
var played_tracks_indices: Array = []
var current_ambient_set: AmbienceSet = null
var _duck_tween: Tween
var _pre_game_over_db: float = 0.0
var _music_ducked: bool = false
var _memory_tween: Tween
var _pitch_tween: Tween
var _memory_active: bool = false
var _pre_memory_stream: AudioStream
var _pre_memory_db: float = 0.0

func _ready() -> void:
	for playlist: MusicPlaylist in music_playlists:
		music_system[playlist.playlist_name] = playlist
	for ambient_set: AmbienceSet in ambient_sets:
		ambient_system[ambient_set.ambience_set_name] = ambient_set
	Signalbus.game_state_game_over.connect(_duck_music_for_game_over)
	Signalbus.game_state_main_menu.connect(_restore_music_after_game_over)
	Signalbus.game_state_playing.connect(_restore_music_after_game_over)

func _duck_music_for_game_over() -> void:
	if _music_ducked:
		return
	_music_ducked = true
	_pre_game_over_db = music_player.volume_db
	_tween_music_db(game_over_music_db)

func _restore_music_after_game_over() -> void:
	if not _music_ducked:
		return
	_music_ducked = false
	_tween_music_db(_pre_game_over_db)

func _tween_music_db(target_db: float) -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_duck_tween.tween_property(music_player, "volume_db", target_db, game_over_duck_time)

func _cancel_music_duck() -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = null
	_music_ducked = false

func enter_memory_music(volume_db_override: float = NAN) -> void:
	if _memory_active or memory_song == null:
		return
	_memory_active = true
	_pre_memory_stream = music_player.stream
	_pre_memory_db = music_player.volume_db
	var target_db: float = memory_song_volume_db if is_nan(volume_db_override) else volume_db_override
	_memory_fade_to(memory_song, target_db, memory_song_pitch)

func exit_memory_music() -> void:
	if not _memory_active:
		return
	_memory_active = false
	_memory_fade_to(_pre_memory_stream, _pre_memory_db, 1.0)

func _memory_fade_to(stream: AudioStream, target_db: float, pitch: float) -> void:
	_cancel_pitch_tween()
	if _memory_tween != null and _memory_tween.is_valid():
		_memory_tween.kill()
	_memory_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if music_player.playing:
		_memory_tween.tween_property(music_player, "volume_db", -60.0, memory_fade_seconds * 0.5)
	_memory_tween.tween_callback(_memory_swap_stream.bind(stream, pitch))
	_memory_tween.tween_property(music_player, "volume_db", target_db, memory_fade_seconds * 0.5)

func _memory_swap_stream(stream: AudioStream, pitch: float) -> void:
	if stream == null:
		music_player.stop()
		return
	music_player.stream = stream
	music_player.pitch_scale = pitch
	music_player.volume_db = -60.0
	music_player.play()
	if not music_player.finished.is_connected(_on_song_finished):
		music_player.finished.connect(_on_song_finished)

func _cancel_memory_music() -> void:
	if _memory_tween != null and _memory_tween.is_valid():
		_memory_tween.kill()
	_memory_tween = null
	_memory_active = false
	_cancel_pitch_tween()

func tween_music_pitch(target: float, seconds: float) -> void:
	_cancel_pitch_tween()
	if seconds <= 0.0:
		music_player.pitch_scale = target
		return
	_pitch_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pitch_tween.tween_property(music_player, "pitch_scale", target, seconds)

func _cancel_pitch_tween() -> void:
	if _pitch_tween != null and _pitch_tween.is_valid():
		_pitch_tween.kill()
	_pitch_tween = null

func execute_playlist(playlist_name: String) -> void:
	if not music_system.has(playlist_name):
		push_error("Playlist '%s' not found" % playlist_name)
		return

	if music_player.finished.is_connected(_on_song_finished):
		music_player.finished.disconnect(_on_song_finished)

	if current_playlist_name != playlist_name:
		stop_playlist()

	currently_playing_playlist = music_system[playlist_name]
	current_playlist_name = currently_playing_playlist.playlist_name

	match currently_playing_playlist.play_mode:
		MusicPlaylist.PlayMode.SEQUENTIAL:
			_play_sequential()
		MusicPlaylist.PlayMode.RANDOM:
			_play_random()

func play_current_track() -> void:
	_cancel_music_duck()
	var track: MusicSongEntry = currently_playing_playlist.tracks[current_track_index]
	music_player.stream = track.audio
	music_player.volume_db = track.volume_db
	music_player.bus = "Music"
	music_player.pitch_scale = track.pitch_scale
	music_player.play()

	if not music_player.finished.is_connected(_on_track_finished):
		music_player.finished.connect(_on_track_finished)

func stop_playlist() -> void:
	if not music_player.playing:
		return

	music_player.stop()

	if music_player.finished.is_connected(_on_track_finished):
		music_player.finished.disconnect(_on_track_finished)

	current_track_index = -1
	played_tracks_indices.clear()
	currently_playing_playlist = null
	current_playlist_name = ""

func _play_sequential() -> void:
	if current_track_index < currently_playing_playlist.tracks.size() - 1:
		current_track_index += 1
	else:
		current_track_index = 0
	play_current_track()

func _play_random() -> void:
	if played_tracks_indices.size() >= currently_playing_playlist.tracks.size():
		played_tracks_indices.clear()

	var available_indices: Array[int] = []
	for i: int in range(currently_playing_playlist.tracks.size()):
		if not played_tracks_indices.has(i):
			available_indices.append(i)

	current_track_index = available_indices.pick_random()
	played_tracks_indices.append(current_track_index)
	play_current_track()

func _on_track_finished() -> void:
	if currently_playing_playlist.interval_between_tracks > 0:
		await get_tree().create_timer(currently_playing_playlist.interval_between_tracks).timeout
	if currently_playing_playlist == null:
		return
	execute_playlist(current_playlist_name)

## play one song on loop (floor music via FloorData.music, menu music); replaces any running playlist.
## null stream = silence whatever is playing
func play_song(stream: AudioStream, volume_db: float = -5.0) -> void:
	_cancel_music_duck()
	_cancel_memory_music()
	if stream == null:
		stop_playlist()
		stop_song()
		return

	if music_player.stream == stream and music_player.playing:
		music_player.volume_db = volume_db
		return

	stop_playlist()
	currently_playing_playlist = null
	current_playlist_name = ""

	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.bus = "Music"
	music_player.pitch_scale = 1.0
	music_player.play()

	if not music_player.finished.is_connected(_on_song_finished):
		music_player.finished.connect(_on_song_finished)

func stop_song() -> void:
	if music_player.finished.is_connected(_on_song_finished):
		music_player.finished.disconnect(_on_song_finished)
	music_player.stop()

func _on_song_finished() -> void:
	music_player.play()

# --------- Ambient Sound System ---------

func play_ambient_set(ambient_set_name: String) -> void:
	if not ambient_system.has(ambient_set_name):
		push_error("Ambient set '%s' not found" % ambient_set_name)
		return

	if current_ambient_set != null:
		stop_ambient_set()

	current_ambient_set = ambient_system[ambient_set_name]	

	for playlist: AmbientPlaylist in current_ambient_set.playlists:
		match playlist.play_mode:
			AmbientPlaylist.PlayMode.AMB_RANDOM_SINGLE:
				_play_ambient_random_single(playlist)				

func stop_ambient_set() -> void:
	if current_ambient_set == null:
		return
	
	for player_key: String in active_ambient_players.keys():
		var player_data: AmbientPlayerData = active_ambient_players[player_key]

		if player_data.playlist.fade_out_time > 0:
			var tween: Tween = create_tween()
			tween.tween_property(player_data.player, "volume_db", -80.0, player_data.playlist.fade_out_time)
			await tween.finished

		if player_data.player.finished.is_connected(player_data.finish_callback):
			player_data.player.finished.disconnect(player_data.finish_callback)

		player_data.player.queue_free()

	active_ambient_players.clear()
	current_ambient_set = null

func _play_ambient_random_single(playlist: AmbientPlaylist) -> void:
	var player_key: String = "amb_random_single_" + playlist.playlist_name

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	self.add_child(player)
	player.bus = "Ambience"

	var random_track: MusicSongEntry = playlist.tracks[randi() % playlist.tracks.size()]
	player.stream = random_track.audio
	player.volume_db = random_track.volume_db
	player.pitch_scale = random_track.pitch_scale

	var finish_callback: Callable = func() -> void:
		var wait_time: float = randf_range(playlist.revisit_timer_min, playlist.revisit_timer_max)
		await get_tree().create_timer(wait_time).timeout
		_play_ambient_random_single(playlist)

	var data: AmbientPlayerData = AmbientPlayerData.new()
	data.player = player
	data.playlist = playlist
	data.finish_callback = finish_callback
	active_ambient_players[player_key] = data

	player.finished.connect(finish_callback)

	if playlist.fade_in_time > 0:
		player.volume_db = -80
		player.play()
		var tween: Tween = create_tween()
		tween.tween_property(player, "volume_db", random_track.volume_db, playlist.fade_in_time)
	else:
		player.play()
