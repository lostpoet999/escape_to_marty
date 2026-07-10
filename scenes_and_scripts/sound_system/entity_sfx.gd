class_name EntitySFX
extends Node

@export var sounds: Array[SoundEntry] = []
var sound_dict: Dictionary = {}
var active_counts: Dictionary = {}

func _ready() -> void:
	for sound: SoundEntry in sounds:
		sound_dict[sound.name] = sound

func play_sound(sound_name: String) -> AudioStreamPlayer:	
	if not sound_dict.has(sound_name):
		push_error("Sound '%s' not found in entity SFX dictionary" % sound_name)
		return null
	var sound: SoundEntry = sound_dict[sound_name]
	if sound.loop_sound:
		for child: Node in get_children():
			if child.name == "loop_" + sound_name:
				return child as AudioStreamPlayer
	elif sound.max_concurrent > 0:
		var active: int = active_counts.get(sound_name, 0)
		if active >= sound.max_concurrent:
			return null
	var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
	sfx_player.name = "loop_" + sound_name if sound.loop_sound else sound_name
	add_child(sfx_player)
	sfx_player.bus = "SFX"
	sfx_player.stream = sound.audio
	sfx_player.volume_db = sound.volume_db
	var pitch: float = sound.pitch_scale + randf_range(-sound.pitch_variance, sound.pitch_variance)
	sfx_player.pitch_scale = maxf(pitch, 0.01)
	sfx_player.play()	
	if sound.loop_sound:
		sfx_player.finished.connect(func() -> void:
			if sound.loop_interval > 0:
				await get_tree().create_timer(sound.loop_interval).timeout
			if is_instance_valid(sfx_player):
				sfx_player.play()
		)
	else:
		active_counts[sound_name] = int(active_counts.get(sound_name, 0)) + 1
		sfx_player.finished.connect(func() -> void:
			active_counts[sound_name] = maxi(int(active_counts.get(sound_name, 0)) - 1, 0)
			sfx_player.queue_free()
		)
	return sfx_player

func stop_looping_sound(sound_name: String) -> void:	
	for child: Node in get_children():
		if child.name == "loop_" + sound_name:
			var player: AudioStreamPlayer = child as AudioStreamPlayer
			player.stop()
			player.queue_free()
			break
