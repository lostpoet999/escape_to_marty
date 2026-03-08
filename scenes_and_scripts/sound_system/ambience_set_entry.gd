# Create a new script AmbienceSet.gd
extends Resource
class_name AmbienceSet

@export var ambience_set_name: String = "default_ambience"
@export var playlists: Array[AmbientPlaylist] = []
