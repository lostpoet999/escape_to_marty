extends Resource
class_name AmbientPlaylist

enum PlayMode {AMB_SEQUENTIAL, AMB_RANDOM_SINGLE, AMB_RANDOM_MULTI, AMB_PARALLEL_ALL}

@export var playlist_name: String = "ambient_playlist"
@export var tracks: Array[MusicSongEntry] = []  # reusing MusicSongEntry
@export var min_tracks: int = 1 #only used for random_multi
@export var max_tracks: int = 3 #only used for random_multi
@export var revisit_timer_min: float = 30.0
@export var revisit_timer_max: float = 60.0
@export var play_mode: PlayMode = PlayMode.AMB_PARALLEL_ALL
@export var fade_in_time: float = 2.0
@export var fade_out_time: float = 2.0
