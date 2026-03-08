extends Node

class AmbientPlayerData:
	var player: AudioStreamPlayer
	var playlist: AmbientPlaylist
	var finish_callback: Callable

@export var music_playlists: Array[MusicPlaylist] = []
@export var ambient_sets: Array[AmbienceSet] = []
var music_system: Dictionary = {}
var ambient_system: Dictionary = {}
var active_ambient_players: Dictionary = {}
@onready var music_player: AudioStreamPlayer = $music_player
var currently_playing_playlist: MusicPlaylist
var current_playlist_name: String
var current_track_index: int = -1
var played_tracks_indices: Array = []
var current_ambient_set: AmbienceSet = null

func _ready() -> void:
	for playlist: MusicPlaylist in music_playlists:
		music_system[playlist.playlist_name] = playlist
	for ambient_set: AmbienceSet in ambient_sets:
		ambient_system[ambient_set.ambience_set_name] = ambient_set

func execute_playlist(playlist_name: String) -> void:
	if not music_system.has(playlist_name):
		push_error("Playlist '%s' not found" % playlist_name)
		return

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
	var track: MusicSongEntry = currently_playing_playlist.tracks[current_track_index]
	print("Playing track: ", track.song_name)
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
	print("Track finished: ", currently_playing_playlist.tracks[current_track_index].song_name)
	if currently_playing_playlist.interval_between_tracks > 0:
		await get_tree().create_timer(currently_playing_playlist.interval_between_tracks).timeout
	execute_playlist(current_playlist_name)

# --------- Ambient Sound System ---------

func play_ambient_set(ambient_set_name: String) -> void:
	if not ambient_system.has(ambient_set_name):
		push_error("Ambient set '%s' not found" % ambient_set_name)
		return

	if current_ambient_set != null:
		stop_ambient_set()

	current_ambient_set = ambient_system[ambient_set_name]
	print("Playing ambient set: ", ambient_set_name)

	for playlist: AmbientPlaylist in current_ambient_set.playlists:
		match playlist.play_mode:
			AmbientPlaylist.PlayMode.AMB_RANDOM_SINGLE:
				_play_ambient_random_single(playlist)
			_:
				print("Playlist mode not implemented yet: ", playlist.play_mode)

func stop_ambient_set() -> void:
	if current_ambient_set == null:
		return

	print("Stopping ambient set: ", current_ambient_set.ambience_set_name)

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

	print("Started ambient track: ", random_track.song_name, " from playlist: ", playlist.playlist_name)
