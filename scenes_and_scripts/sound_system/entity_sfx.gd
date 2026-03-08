extends Node
@export var sounds: Array[SoundEntry] = []
var sound_dict = {}

func _ready():
	for sound in sounds:
		sound_dict[sound.name] = sound

func play_sound(sound_name: String) -> AudioStreamPlayer:
	if not sound_dict.has(sound_name):
		push_error("Sound '%s' not found in entity SFX dictionary" % sound_name)
		return null

	var sound = sound_dict[sound_name]

	if sound.loop_sound:
		for child in get_children():
			if child.name == "loop_" + sound_name:
				return child

	var sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "loop_" + sound_name if sound.loop_sound else sound_name
	add_child(sfx_player)

	sfx_player.stream = sound.audio
	sfx_player.volume_db = sound.volume_db
	sfx_player.bus = "SFX"
	sfx_player.pitch_scale = sound.pitch_scale + randf_range(-sound.pitch_variance, sound.pitch_variance)

	sfx_player.play()

	if sound.loop_sound:
		sfx_player.finished.connect(func():
			if sound.loop_interval > 0:
				await get_tree().create_timer(sound.loop_interval).timeout
			if is_instance_valid(sfx_player):
				sfx_player.play()
		)
	else:
		sfx_player.finished.connect(func(): sfx_player.queue_free())

	return sfx_player

func stop_looping_sound(sound_name: String) -> void:
	for child in get_children():
		if child.name == "loop_" + sound_name:
			child.stop()
			child.queue_free()
			break
