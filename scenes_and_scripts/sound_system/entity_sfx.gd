class_name EntitySFX
extends Node

@export var sounds: Array[SoundEntry] = []
var sound_dict: Dictionary = {}
var active_counts: Dictionary = {}

const UI_CLICK_SOUND: String = "ui_select"

func _ready() -> void:
	for sound: SoundEntry in sounds:
		sound_dict[sound.name] = sound
	get_tree().node_added.connect(_on_node_added)
	_hook_existing_buttons(get_tree().root)
	Signalbus.game_state_main_menu.connect(stop_all_looping_sounds)

func _hook_existing_buttons(node: Node) -> void:
	_on_node_added(node)
	for child: Node in node.get_children():
		_hook_existing_buttons(child)

func _on_node_added(node: Node) -> void:
	var button: BaseButton = node as BaseButton
	if button == null:
		return
	if button.pressed.is_connected(_on_button_pressed):
		return
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	play_sound(UI_CLICK_SOUND)

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
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
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

func is_looping(sound_name: String) -> bool:
	for child: Node in get_children():
		if child.name == "loop_" + sound_name:
			return true
	return false

func stop_looping_sound(sound_name: String) -> void:
	for child: Node in get_children():
		if child.name == "loop_" + sound_name:
			var player: AudioStreamPlayer = child as AudioStreamPlayer
			player.stop()
			remove_child(player)
			player.queue_free()
			break

func stop_all_looping_sounds() -> void:
	for child: Node in get_children():
		if child.name.begins_with("loop_"):
			var player: AudioStreamPlayer = child as AudioStreamPlayer
			player.stop()
			remove_child(player)
			player.queue_free()
