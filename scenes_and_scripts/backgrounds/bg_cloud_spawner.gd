extends Node3D

## scene instanced for each drifting cloud
@export var cloud_scene: PackedScene
## fewest clouds kept drifting at once
@export var min_clouds: int = 4
## most clouds kept drifting at once
@export var max_clouds: int = 6
## nearest camera-space depth a cloud can spawn at
@export var depth_near: float = 6.0
## farthest camera-space depth a cloud can spawn at
@export var depth_far: float = 36.0
## drift speed in world units/sec for a cloud at depth_near
@export var speed_near: float = 0.45
## drift speed in world units/sec for a cloud at depth_far
@export var speed_far: float = 0.125
## cloud scale at depth_near
@export var scale_near: float = 1.3
## cloud scale at depth_far; larger than scale_near so distant clouds stay readable
@export var scale_far: float = 7.0
## how far below the depth-derived scale the random multiplier can dip (0.45 = -45%)
@export var scale_jitter_down: float = 0.45
## how far above the depth-derived scale the random multiplier can reach (1.2 = +120%)
@export var scale_jitter_up: float = 1.2
## random Z-roll in degrees applied per cloud, both directions
@export var roll_jitter_deg: float = 8.0
## chance a cloud's sprite spawns mirrored horizontally
@export var flip_chance: float = 0.5
## chance a spawned cloud is a jitter cloud that flipbooks its two sheet frames
@export var jitter_cloud_chance: float = 0.1
## seconds between frame swaps on a jitter cloud
@export var jitter_frame_seconds: float = 0.3
## shared cloud material applied to each cloud sprite
@export var sprite_material: Material = preload("res://scenes_and_scripts/backgrounds/BG Objects/mat_cloud_sprite.tres")
## cloud sprite opacity at depth_far; near clouds stay fully solid
@export var opacity_far: float = 0.55
## bottom of the vertical placement band, as a fraction of the view half-height at spawn depth
@export var band_bottom: float = -0.4
## top of the vertical placement band, as a fraction of the view half-height at spawn depth
@export var band_top: float = 0.7
## half-width of one cloud at scale 1, used to keep spawns fully offscreen
@export var cloud_half_width: float = 0.35
## extra horizontal margin covering the camera's parallax sweep
@export var edge_margin: float = 1.2
## start with clouds spread across the sky instead of an empty sky that fills in slowly
@export var prepopulate: bool = true

class DriftingCloud:
	var node: Node3D
	var speed: float
	var exit_x: float
	var depth_band: int
	var sprite: Sprite3D
	var jitters: bool
	var frame_timer: float

var _clouds: Array[DriftingCloud] = []
var _camera_base: Transform3D
var _tan_half_fov: float
var _aspect: float
var _target_count: int

@onready var _camera: Camera3D = $"../Camera3D"

func _ready() -> void:
	_camera_base = _camera.global_transform
	_tan_half_fov = tan(deg_to_rad(_camera.fov) * 0.5)
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	_aspect = view_size.x / view_size.y
	_target_count = randi_range(min_clouds, max_clouds)
	for band: int in _target_count:
		_spawn_cloud(prepopulate, band)

func _process(delta: float) -> void:
	var finished: Array[DriftingCloud] = []
	for cloud: DriftingCloud in _clouds:
		cloud.node.position.x += cloud.speed * delta
		if cloud.jitters:
			cloud.frame_timer += delta
			if cloud.frame_timer >= jitter_frame_seconds:
				cloud.frame_timer -= jitter_frame_seconds
				cloud.sprite.frame = 1 - cloud.sprite.frame
		if cloud.node.position.x > cloud.exit_x:
			finished.append(cloud)
	for cloud: DriftingCloud in finished:
		_clouds.erase(cloud)
		cloud.node.queue_free()
		_spawn_cloud(false, cloud.depth_band)

func _spawn_cloud(spread_across_view: bool, depth_band: int) -> void:
	if cloud_scene == null:
		return
	var depth_t: float = (depth_band + randf()) / _target_count
	var depth: float = lerpf(depth_near, depth_far, depth_t)
	var cloud_scale: float = lerpf(scale_near, scale_far, depth_t) * randf_range(1.0 - scale_jitter_down, 1.0 + scale_jitter_up)
	var view_half_width: float = depth * _tan_half_fov * _aspect
	var margin: float = edge_margin + cloud_half_width * cloud_scale
	var enter_x: float = _camera_base.origin.x - view_half_width - margin
	var exit_x: float = _camera_base.origin.x + view_half_width + margin
	var band_offset: float = randf_range(band_bottom, band_top) * depth * _tan_half_fov
	var spawn_pos: Vector3 = _camera_base * Vector3(0.0, band_offset, -depth)
	spawn_pos.x = randf_range(enter_x, exit_x) if spread_across_view else enter_x
	var node: Node3D = cloud_scene.instantiate() as Node3D
	if node == null:
		return
	var cloud: DriftingCloud = DriftingCloud.new()
	cloud.node = node
	cloud.speed = lerpf(speed_near, speed_far, depth_t)
	cloud.exit_x = exit_x
	cloud.depth_band = depth_band
	cloud.node.position = spawn_pos
	cloud.node.scale = Vector3.ONE * cloud_scale
	cloud.node.rotation_degrees.z = randf_range(-roll_jitter_deg, roll_jitter_deg)
	var sprite: Sprite3D = node.get_node_or_null(^"Sprite3D") as Sprite3D
	if sprite != null:
		sprite.flip_h = randf() < flip_chance
		sprite.material_override = sprite_material
		sprite.modulate = Color(1.0, 1.0, 1.0, lerpf(1.0, opacity_far, depth_t))
	cloud.sprite = sprite
	cloud.jitters = sprite != null and randf() < jitter_cloud_chance
	add_child(cloud.node)
	_clouds.append(cloud)
