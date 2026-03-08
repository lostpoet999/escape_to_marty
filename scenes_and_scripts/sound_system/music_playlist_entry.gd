extends Resource
class_name MusicPlaylist

enum PlayMode {SEQUENTIAL, RANDOM, LOOP_SINGLE_RANDOM, LOOP_FIRST}

@export var playlist_name = "playlist"
@export var tracks: Array[MusicSongEntry] = []
@export var play_mode: PlayMode = PlayMode.SEQUENTIAL
@export var interval_between_tracks = 0.5
