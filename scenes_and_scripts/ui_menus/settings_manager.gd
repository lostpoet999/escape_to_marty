extends Node

var settings_file: ConfigFile = ConfigFile.new()
const SETTINGS_PATH: String = "user://escape_to_marty_settings.cfg"
const SFX_BOOST_DB: float = 8.0

var music_volume: float = 0.5
var sfx_volume: float = 0.5
var game_speed: float = 1.0
var difficulty: int = 1

func _ready() -> void:
	load_settings()

func difficulty_mult() -> float:
	match difficulty:
		0: return 0.7
		2: return 1.3
		_: return 1.0

func save_settings() -> void:
	settings_file.set_value("audio", "music_volume", music_volume)
	settings_file.set_value("audio", "sfx_volume", sfx_volume)
	settings_file.set_value("game", "game_speed", game_speed)
	settings_file.set_value("game", "difficulty", difficulty)
	var error: int = settings_file.save(SETTINGS_PATH)
	if error != OK: print("Disk error saving settings: ", error)

func load_settings() -> void:
	var error: int = settings_file.load(SETTINGS_PATH)
	if error == OK:
		music_volume = settings_file.get_value("audio", "music_volume", music_volume)
		sfx_volume = settings_file.get_value("audio", "sfx_volume", sfx_volume)
		game_speed = settings_file.get_value("game", "game_speed", game_speed)
		difficulty = settings_file.get_value("game", "difficulty", difficulty)
	else:
		save_settings()
	apply_settings()

func apply_settings() -> void:
	Engine.time_scale = game_speed
	apply_audio()

func apply_audio() -> void:
	set_bus_volume("Music", music_volume, 0.0)
	set_bus_volume("SFX", sfx_volume, SFX_BOOST_DB)
	set_bus_volume("Ambience", sfx_volume, SFX_BOOST_DB)

func set_bus_volume(bus_name: String, linear: float, boost_db: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear, 0.0001)) + boost_db)
