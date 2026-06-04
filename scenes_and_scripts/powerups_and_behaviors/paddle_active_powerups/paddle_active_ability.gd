class_name PaddleActive extends BaseItem

const SPAWN_MARKERS: Array[StringName] = [
	&"spawn_center",
	&"spawn_left",
	&"spawn_right",
	&"spawn_left_mid",
	&"spawn_right_mid",
	&"spawn_left_corner",
	&"spawn_right_corner",
]

@export_category("Shot Configuration:")
@export var projectile_ref: PackedScene
@export var max_spawn: int
# reserved for future time-based actives (instant abilities with no projectile to gate via max_spawn)
@export var cool_down_seconds: float
@export var speed_modifier: float
@export var damage: int
@export var projectile_dmg_type: Array[GameManager.PhaseType]
@export var on_hit: Array[HitBehavior]
@export_flags("Center", "Left", "Right", "Left Mid", "Right Mid", "Left Corner", "Right Corner") var spawn_points: int = 0
@export var pierce: int = 0
var active_volleys: int = 0

func _ready()->void:
	active_volleys = 0

func activate(paddle: Paddle, projectile_node: Node) -> void:
	if not ((active_volleys < max_spawn) or (max_spawn <= 0)):
		return
	var shots: Array[Transform2D] = _volley_transforms(paddle)
	if shots.is_empty():
		return
	active_volleys += 1
	var remaining: Array[int] = [shots.size()]
	for shot: Transform2D in shots:
		_fire(shot, projectile_node, remaining)
	SFX.play_sound("shot_fired")

func _volley_transforms(paddle: Paddle) -> Array[Transform2D]:
	var markers: Array[StringName] = _selected_markers()
	if markers.is_empty():
		return [Transform2D(0.0, paddle.global_position + Vector2(0, -32))]
	var shots: Array[Transform2D] = []
	for point_name: StringName in markers:
		var marker: Marker2D = paddle.get_node_or_null(NodePath(point_name)) as Marker2D
		if marker != null:
			shots.append(marker.global_transform)
	return shots

func _selected_markers() -> Array[StringName]:
	var result: Array[StringName] = []
	for i: int in SPAWN_MARKERS.size():
		if spawn_points & (1 << i):
			result.append(SPAWN_MARKERS[i])
	return result

func _fire(shot: Transform2D, projectile_node: Node, remaining: Array[int]) -> void:
	var projectile: Projectile = projectile_ref.instantiate() as Projectile
	projectile.initialize_shot(speed_modifier, damage, self, projectile_dmg_type, on_hit, pierce)
	projectile_node.add_child(projectile)
	projectile.global_position = shot.origin
	projectile.global_rotation = shot.get_rotation()
	projectile.tree_exited.connect(func() -> void:
		remaining[0] -= 1
		if remaining[0] <= 0:
			active_volleys -= 1)
