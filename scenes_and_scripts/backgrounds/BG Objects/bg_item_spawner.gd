extends Node3D

## nearest camera-space depth an item can spawn at
@export var depth_near: float = 6.0
## farthest camera-space depth an item can spawn at
@export var depth_far: float = 25.0
## item scale at depth_near
@export var scale_near: float = 2.5
## item scale at depth_far; larger than scale_near so distant items stay readable
@export var scale_far: float = 10.0
## random size multiplier applied per item on top of the depth-derived scale (0.25 = ±25%)
@export var scale_jitter: float = 0.25
## bottom of the vertical placement band, as a fraction of the view half-height at spawn depth
@export var band_bottom: float = -0.8
## top of the vertical placement band, as a fraction of the view half-height at spawn depth
@export var band_top: float = 0.85
## fraction of the view half-width items can spawn across, keeping them fully on screen
@export var spread: float = 0.95
## seconds before an emptied slot spawns a replacement item
@export var respawn_delay: float = 2.0
## candidate spots tried per placement; the one farthest from the other items wins
@export var placement_attempts: int = 6

class ItemSlot:
	var node: Node3D
	var scene: PackedScene
	var depth_band: int
	var respawn_timer: float

var _slots: Array[ItemSlot] = []
var _scene_pool: Array[PackedScene] = []
var _target_count: int
var _camera_base: Transform3D
var _tan_half_fov: float
var _aspect: float

@onready var _camera: Camera3D = $"../Camera3D"

func _ready() -> void:
	var fd: FloorData = GameManager.floor_data
	if fd == null:
		return
	for scene: PackedScene in fd.bg_item_scenes:
		if scene != null:
			_scene_pool.append(scene)
	if _scene_pool.is_empty():
		return
	_camera_base = _camera.global_transform
	_tan_half_fov = tan(deg_to_rad(_camera.fov) * 0.5)
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	_aspect = view_size.x / view_size.y
	_scene_pool.shuffle()
	_target_count = fd.bg_item_count
	for i: int in _target_count:
		var slot: ItemSlot = ItemSlot.new()
		slot.scene = _scene_pool[i % _scene_pool.size()]
		slot.depth_band = i
		_slots.append(slot)
		_spawn_item(slot)

func _process(delta: float) -> void:
	for slot: ItemSlot in _slots:
		if slot.node != null and is_instance_valid(slot.node):
			continue
		slot.node = null
		slot.respawn_timer -= delta
		if slot.respawn_timer <= 0.0:
			_spawn_item(slot)

func _spawn_item(slot: ItemSlot) -> void:
	slot.respawn_timer = respawn_delay
	var node: Node3D = slot.scene.instantiate() as Node3D
	if node == null:
		return
	_position_item(node, (slot.depth_band + randf()) / _target_count)
	add_child(node)
	slot.node = node

func place_item(item: Node3D) -> void:
	_position_item(item, randf())

func _position_item(item: Node3D, depth_t: float) -> void:
	var depth: float = lerpf(depth_near, depth_far, depth_t)
	var best: Vector2
	var best_distance: float = -1.0
	for attempt: int in placement_attempts:
		var candidate: Vector2 = Vector2(randf_range(-spread, spread), randf_range(band_bottom, band_top))
		var distance: float = _nearest_item_distance(candidate, item)
		if distance > best_distance:
			best_distance = distance
			best = candidate
	item.position = _camera_base * Vector3(best.x * depth * _tan_half_fov * _aspect, best.y * depth * _tan_half_fov, -depth)
	item.scale = Vector3.ONE * lerpf(scale_near, scale_far, depth_t) * randf_range(1.0 - scale_jitter, 1.0 + scale_jitter)

func _nearest_item_distance(candidate: Vector2, exclude: Node3D) -> float:
	var nearest: float = INF
	var inverse: Transform3D = _camera_base.affine_inverse()
	for slot: ItemSlot in _slots:
		if slot.node == null or not is_instance_valid(slot.node) or slot.node == exclude:
			continue
		var local: Vector3 = inverse * slot.node.position
		if local.z >= 0.0:
			continue
		var frac: Vector2 = Vector2(local.x / (-local.z * _tan_half_fov * _aspect), local.y / (-local.z * _tan_half_fov))
		nearest = minf(nearest, candidate.distance_to(frac))
	return nearest
