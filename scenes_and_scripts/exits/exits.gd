extends Area2D

const DEFAULT_REVEAL_VFX: PackedScene = preload("res://scenes_and_scripts/bricks/brick_vfx/brick_damage_fx.tscn")
const SECRET_FLASH_COLOR: Color = Color(3.0, 3.0, 3.0)
const SECRET_FLASH_IN_TIME: float = 0.1
const SECRET_FLASH_OUT_TIME: float = 0.4
const SECRET_FLASH_INTERVAL_MIN: float = 8.0
const SECRET_FLASH_INTERVAL_MAX: float = 12.0
const SECRET_FLASHES_PER_BARK_MIN: int = 3
const SECRET_FLASHES_PER_BARK_MAX: int = 4
const SECRET_SOUND_BOOST_DB: float = 3.5
const BONUS_DOOR_GOLD: Color = Color(1.0, 0.9, 0.2)
const CLOSED_DOOR_TINT: Color = Color("#a53030")
const OPEN_DOOR_TINT: Color = Color("#75a743")
const DIR_OFFSETS: Dictionary = {
	"NorthExit": Vector2i(0, -1),
	"SouthExit": Vector2i(0, 1),
	"EastExit": Vector2i(1, 0),
	"WestExit": Vector2i(-1, 0),
}

@onready var room_ref: Dictionary = GameManager.room_data_for_floor #dictionary of room entries
@onready var walls_no_door: Node2D = $walls_no_door
@onready var exit_barrier_closed: TextureRect = $ExitBarrier_closed
@onready var exit_barrier_open: TextureRect = $ExitBarrier_open

@export var reveal_vfx: PackedScene

var room_cleared: bool = false
var travel_locked: bool = false
var _flash_tween: Tween
var _open_pulse_tween: Tween
var _flashes_until_bark: int = 0

func _ready() -> void:
	exit_barrier_closed.modulate = CLOSED_DOOR_TINT
	exit_barrier_open.modulate = OPEN_DOOR_TINT
	Signalbus.level_cleared.connect(enable_exits)
	Signalbus.wall_hit.connect(_on_wall_hit)
	reconcile_exits()

func _on_wall_hit(_source: Node2D, wall: Node2D, _damage: float, _dmg_types: Array) -> void:
	if wall != self or travel_locked or not _is_secret_unrevealed():
		return
	_flash_secret_now()

func tween_open_door()->void:
	_open_pulse_tween = create_tween()
	_open_pulse_tween.tween_property(self, "scale", Vector2(.95, .95), .5)
	_open_pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), .5)
	_open_pulse_tween.set_loops(0)

func _stop_open_pulse()-> void:
	if _open_pulse_tween and _open_pulse_tween.is_valid():
		_open_pulse_tween.kill()
	_open_pulse_tween = null
	scale = Vector2.ONE

## Cutscenes lock travel without lying about the room: real doors show
## closed, solid walls stay walls, unrevealed secrets stay disguised (but
## can't be reveal-clicked while locked).
func set_travel_locked(locked: bool) -> void:
	travel_locked = locked
	reconcile_exits()

func reconcile_exits()-> void:
	_stop_secret_flash()
	_stop_open_pulse()
	var target_id: String = _target_id()
	if target_id == "":
		show_walls()
	elif _is_secret_unrevealed():
		show_secret_wall()
		if travel_locked:
			self.input_pickable = false
	elif travel_locked:
		show_closed_door()
	elif _targets_bonus_room():
		_show_bonus_door()
	elif room_cleared:
		show_open_door()
		tween_open_door()
	else:
		show_closed_door()

func _show_bonus_door()-> void:
	if room_cleared and _bonus_gate_open():
		show_open_door()
		tween_open_door()
	else:
		show_closed_door()
		self.input_pickable = true
	exit_barrier_closed.modulate = BONUS_DOOR_GOLD
	exit_barrier_open.modulate = BONUS_DOOR_GOLD

func _targets_bonus_room()-> bool:
	var target_id: String = _target_id()
	if target_id == "" or not room_ref.has(target_id):
		return false
	return room_ref[target_id].content.room_type == RoomContent.ROOM_TYPES.bonus_room

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_on_exit_clicked()

func _on_exit_clicked()-> void:
	if _is_secret_unrevealed():
		if _can_reveal_secret():
			reveal_secret()
		return

	if _targets_bonus_room() and not _bonus_gate_open():
		DialogDirector.play(&"bonus_door_locked")
		return

	if !room_cleared:
		return

	var target_id: String = _target_id()
	if target_id == "":
		return

	var target_room: RoomEntry = room_ref[target_id]
	GameManager.current_room_id = target_id
	GameManager.scene_ref = target_room.content.room_scene
	GameManager.change_state(GameManager.GameState.BALL_ON_PADDLE)
	get_tree().change_scene_to_packed(target_room.content.room_scene)

func is_click_responsive()-> bool:
	if _is_secret_unrevealed() or travel_locked:
		return false
	if _targets_bonus_room() and not _bonus_gate_open():
		return true
	return room_cleared and _target_id() != ""

func _bonus_gate_open()-> bool:
	var target_id: String = _target_id()
	if target_id == "" or not room_ref.has(target_id):
		return true
	if room_ref[target_id].content.room_type != RoomContent.ROOM_TYPES.bonus_room:
		return true
	return GameManager.memories_complete_for_current_floor()

# combat rooms reveal secrets only mid-fight (CLICK_MODE while PLAYING), so a
# cleared room can't be brute-force scanned. no-combat rooms have no such fight to
# gate the reveal: shops/free-item/start reveal once they auto-clear into
# LEVEL_CLEARED; a memory sits in SPECIAL_ROOM, so it reveals once its flame is
# collected (room_cleared) — this lets a memory link onward to another secret.
func _can_reveal_secret()-> bool:
	if GameManager.current_state == GameManager.GameState.CLICK_MODE:
		return true
	var here: RoomEntry = room_ref[GameManager.current_room_id]
	if GameManager.current_state == GameManager.GameState.LEVEL_CLEARED:
		return here.content.room_type in RoomContent.AUTO_CLEAR_ROOM_TYPES
	if GameManager.current_state == GameManager.GameState.SPECIAL_ROOM:
		return room_cleared and here.content.room_type == RoomContent.ROOM_TYPES.memory
	return false

func reveal_secret()-> void:
	var state: RoomState = _current_room_state()
	var dir: StringName = _direction_key()
	if dir not in state.revealed_exits:
		state.revealed_exits.append(dir)
	if SFX.sound_dict.has("secret_reveal"):
		var reveal_sound: AudioStreamPlayer = SFX.play_sound("secret_reveal")
		if reveal_sound != null:
			reveal_sound.volume_db += SECRET_SOUND_BOOST_DB
	_spawn_reveal_vfx()
	reconcile_exits()

func show_closed_door()-> void:
	walls_no_door.hide()
	exit_barrier_closed.show()
	exit_barrier_open.hide()
	self.input_pickable = false

func show_open_door()-> void:
	walls_no_door.hide()
	exit_barrier_closed.hide()
	exit_barrier_open.show()
	self.input_pickable = true

func show_secret_wall()-> void:
	walls_no_door.show()
	walls_no_door.modulate = Color.WHITE
	exit_barrier_closed.hide()
	exit_barrier_open.hide()
	self.input_pickable = true
	if not travel_locked:
		_start_secret_flash()

func _start_secret_flash()-> void:
	_flashes_until_bark = randi_range(SECRET_FLASHES_PER_BARK_MIN, SECRET_FLASHES_PER_BARK_MAX)
	_queue_secret_flash()

func _queue_secret_flash()-> void:
	_flash_tween = create_tween()
	_flash_tween.tween_interval(randf_range(SECRET_FLASH_INTERVAL_MIN, SECRET_FLASH_INTERVAL_MAX))
	_chain_flash_steps()

func _flash_secret_now()-> void:
	_stop_secret_flash()
	_flash_tween = create_tween()
	_chain_flash_steps()

func _chain_flash_steps()-> void:
	_flash_tween.tween_callback(_on_secret_flash)
	_flash_tween.tween_property(walls_no_door, "modulate", SECRET_FLASH_COLOR, SECRET_FLASH_IN_TIME)
	_flash_tween.tween_property(walls_no_door, "modulate", Color.WHITE, SECRET_FLASH_OUT_TIME)
	_flash_tween.tween_callback(_queue_secret_flash)

func _on_secret_flash()-> void:
	var tell_sound: AudioStreamPlayer = SFX.play_sound("secret_tell")
	if tell_sound != null:
		tell_sound.volume_db += SECRET_SOUND_BOOST_DB
	_flashes_until_bark -= 1
	if _flashes_until_bark <= 0:
		_flashes_until_bark = randi_range(SECRET_FLASHES_PER_BARK_MIN, SECRET_FLASHES_PER_BARK_MAX)
		DialogDirector.play(&"secret_wall_suspicious")

func _stop_secret_flash()-> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = null

func show_walls()-> void:
	walls_no_door.show()
	walls_no_door.modulate = Color.WHITE
	exit_barrier_closed.hide()
	exit_barrier_open.hide()
	self.input_pickable = false

func enable_exits()-> void:
	room_cleared = true
	reconcile_exits()

func _direction_key()-> StringName:
	match self.name:
		"NorthExit": return &"north"
		"SouthExit": return &"south"
		"EastExit": return &"east"
		"WestExit": return &"west"
	return &""

func _target_id()-> String:
	var offset: Vector2i = DIR_OFFSETS.get(self.name, Vector2i.ZERO)
	if offset == Vector2i.ZERO:
		return ""
	var here: RoomEntry = room_ref[GameManager.current_room_id]
	var key: String = RoomEntry.make_key(here.room_coords + offset)
	if not room_ref.has(key):
		return ""
	if here.has_door(offset) or room_ref[key].has_door(-offset):
		return key
	return ""

func _current_room_state()-> RoomState:
	return PlayerData.get_room_state(room_ref[GameManager.current_room_id])

func _is_secret_unrevealed()-> bool:
	var target_id: String = _target_id()
	if target_id == "" or not room_ref.has(target_id):
		return false
	if not room_ref[target_id].content.is_secret:
		return false
	return _direction_key() not in _current_room_state().revealed_exits

func _spawn_reveal_vfx()-> void:
	var scene: PackedScene = reveal_vfx if reveal_vfx else DEFAULT_REVEAL_VFX
	if scene == null:
		return
	var fx: Node2D = scene.instantiate()
	fx.position = global_position
	get_tree().current_scene.add_child(fx)
