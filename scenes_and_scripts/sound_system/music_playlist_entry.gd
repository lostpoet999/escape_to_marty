extends Resource
class_name MusicPlaylist

enum PlayMode {
	SEQUENTIAL = 0,
	RANDOM = 1,
	LOOP_SINGLE_RANDOM = 2,
	LOOP_FIRST = 3,
	}

@export var playlist_name: String = "playlist"
@export var tracks: Array[MusicSongEntry] = []
@export var play_mode: PlayMode = PlayMode.SEQUENTIAL
@export var interval_between_tracks: float = 0.5
