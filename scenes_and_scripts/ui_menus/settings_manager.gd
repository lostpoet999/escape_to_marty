# this code is meant to be used by a settings menu
# to remember sound volume and game speed config
# we could also save highscores here if we wanted
# as an auto-loaded Global, any script can access it

# example:
# SettingsManager.master_volume

extends Node

var settingsFile = ConfigFile.new()
const settingsFileNAME = "user://escape_to_marty_settings.cfg"

# Default values
var master_volume: float = 1.0
var game_speed: float = 1.0

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	settingsFile.set_value("audio", "master_volume", master_volume)
	settingsFile.set_value("game", "game_speed", game_speed)
	var error = settingsFile.save(settingsFileNAME)
	if error != OK: print("Disk error saving settings: ", error)

func load_settings() -> void:
	print("SettingsManager: loading "+settingsFileNAME)
	var error = settingsFile.load(settingsFileNAME)
	if error != OK:
		print("SettingsManager: creating new file")
		save_settings()
		return
	master_volume = settingsFile.get_value("audio", "master_volume", master_volume)
	game_speed = settingsFile.get_value("game", "game_speed", game_speed)
	apply_settings()

func apply_settings() -> void:
	print("SettingsManager: settings loaded OK")
	print("SettingsManager.master_volume="+str(master_volume))
	print("SettingsManager.game_speed="+str(game_speed))
	
	# run code right away to change stuff based on settings
	Engine.time_scale = SettingsManager.game_speed
	
	# sound example: (untested)
	# var bus_index = AudioServer.get_bus_index("Master")
	# if bus_index != -1: AudioServer.set_bus_volume_db(bus_index, linear_to_db(master_volume))
