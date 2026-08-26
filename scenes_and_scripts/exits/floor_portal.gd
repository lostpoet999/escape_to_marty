class_name FloorPortal extends Area2D

signal portal_clicked

const CODEC_PLAYER: PackedScene = preload("uid://ccodecplayer")

## Off = antechamber mode: clicks only emit portal_clicked, never floor_cleared,
## and the memory gate plus its locked-click bark are skipped.
@export var advances_floor: bool = true

## Codec tree played full-screen on a travel-ready click; portal_clicked and
## floor_cleared wait for it to finish. Empty = clear immediately as always.
@export var farewell_tree: DialogTree

## Volume for the slowed memory song under the farewell tree.
@export var farewell_music_volume_db: float = -12.0

var _travel_ready: bool = false
var _farewell_playing: bool = false

@onready var _visual: PortalVisual = $Visual

func _ready() -> void:
	deactivate()

func activate() -> void:
	visible = true
	input_pickable = true
	set_travel_ready(not GameManager.floor_memories_outstanding())

func show_dormant(pickable: bool = true) -> void:
	visible = true
	input_pickable = pickable
	set_travel_ready(false)

func set_travel_ready(ready: bool) -> void:
	_travel_ready = ready
	_visual.set_dormant(not ready)

func deactivate() -> void:
	visible = false
	input_pickable = false

## Lights up the click-mode cursor on hover (see MouseGestures._is_hover_responsive);
## pickable only after the encounter clears, so the tell matches clickability.
func is_click_responsive() -> bool:
	return input_pickable

func handle_gesture_click() -> void:
	if not input_pickable:
		return
	if not _travel_ready:
		if advances_floor:
			DialogDirector.play(&"floor_portal_locked")
		return
	if farewell_tree != null:
		_play_farewell()
		return
	portal_clicked.emit()
	if advances_floor:
		Signalbus.floor_cleared.emit()

func _play_farewell() -> void:
	if _farewell_playing:
		return
	_farewell_playing = true
	MusicPlayer.enter_memory_music(farewell_music_volume_db)
	var player: MemoryCodecPlayer = CODEC_PLAYER.instantiate()
	player.memory_tree = farewell_tree
	add_child(player)
	if advances_floor:
		player.screen_covered.connect(_on_farewell_covered)
		await player.play()
		return
	await player.play()
	if is_instance_valid(player):
		player.queue_free()
	_farewell_playing = false
	portal_clicked.emit()

func _on_farewell_covered(opening: bool) -> void:
	if opening:
		return
	portal_clicked.emit()
	Signalbus.floor_cleared.emit()
