class_name HopToCenter
extends EnemyActions

const CENTER:float = 1088.00
const LEFT:float = 384.00
const LEFT_CENTER:float  = 960.00
const RIGHT: float = 1782.00

var target_x:float
var is_hopping: bool = false
const LANDING_DUST: PackedScene = preload("uid://e5v7jmrw71ba")


@export var hop_distance: float
@export var up_distance: float
@export var speed: float
@export var max_hops: int
@export var back_chance: float
# scaled-up subclasses (e.g. DeonBossHop) override these via .tscn sub_resource
@export var right_center: float = 1216.0
@export var landing_dust_scale: float = 1.5
var hops: int = 0

var origin_position: Vector2
var origin_scale_cached: Vector2
var active_tweens: Array[Tween] = []
var collision_node: Node2D
var origin_collision_scale_cached: Vector2 = Vector2.ONE

func reset()->void:
	hops = 0
	is_hopping = false

func set_target_x(actor: PlacedEnemy)->void:	
	if actor.global_position.x <= LEFT_CENTER:
		if randf_range(1,100) <= back_chance and actor.global_position.x > 384:
			target_x = actor.global_position.x - hop_distance
		elif actor.global_position.x != LEFT_CENTER:
			target_x = actor.global_position.x + hop_distance
	elif actor.global_position.x >= right_center:
		if randf_range(1,100) <= back_chance and actor.global_position.x < 1782:
			target_x = actor.global_position.x + hop_distance
		elif actor.global_position.x != right_center:
			target_x = actor.global_position.x - hop_distance
	
func execute_action(actor: PlacedEnemy) -> void:
	if is_hopping:
		return
	set_target_x(actor)
	if target_x == actor.global_position.x:
		return
	is_hopping = true
	var origin_y: float = actor.global_position.y
	var origin_scale: Vector2 = actor.scale
	var start_x: float = actor.global_position.x
	origin_position = Vector2(start_x, origin_y)
	origin_scale_cached = origin_scale
	active_tweens.clear()

	# --- Hitbox stays a constant world size while the sprite squashes ---
	collision_node = actor.get_node_or_null("CollisionShape2D")
	if collision_node != null:
		origin_collision_scale_cached = collision_node.scale
		var hitbox_tween: Tween = actor.create_tween()
		hitbox_tween.tween_method(func(_t: float) -> void:
			collision_node.scale = origin_collision_scale_cached * origin_scale / actor.scale
		, 0.0, 1.0, speed * 1.5)
		hitbox_tween.tween_callback(func() -> void:
			collision_node.scale = origin_collision_scale_cached
		)
		active_tweens.append(hitbox_tween)

	# --- Position Tween ---
	var tween: Tween = actor.create_tween()
	tween.tween_method(func(x: float) -> void:
		actor.global_position.x = x
		Signalbus.blocker_moved.emit()
	, start_x, target_x, speed)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	var up_tween: Tween = actor.create_tween()
	up_tween.tween_property(actor, "global_position:y",
		origin_y - up_distance, speed * 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	up_tween.tween_property(actor, "global_position:y",
		origin_y, speed * 0.5)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		
	# --- Takeoff Squash & Stretch ---
	var scale_tween: Tween = actor.create_tween()
	scale_tween.tween_property(actor, "scale",
		Vector2(origin_scale.x * 1.3, origin_scale.y * 0.7), speed * 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	scale_tween.tween_property(actor, "scale",
		Vector2(origin_scale.x * 0.8, origin_scale.y * 1.4), speed * 0.10)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	scale_tween.tween_property(actor, "scale",
		origin_scale, speed * 0.75)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
	active_tweens.append_array([tween, up_tween, scale_tween])

	# --- Landing fires after arc completes ---
	up_tween.tween_callback(func() -> void:
		var land_tween: Tween = actor.create_tween()
		active_tweens.append(land_tween)
		land_tween.tween_property(actor, "scale",
			Vector2(origin_scale.x * 1.3, origin_scale.y * 0.7), speed * 0.10)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		land_tween.tween_callback(func() -> void:
			SFX.play_sound("landing")
			Signalbus.jump_landed.emit()
			var dust1: CPUParticles2D = LANDING_DUST.instantiate()
			var dust2: CPUParticles2D = LANDING_DUST.instantiate()
			dust1.scale *= landing_dust_scale
			dust2.scale *= landing_dust_scale
			actor.get_parent().add_child(dust1)
			actor.get_parent().add_child(dust2)
			dust1.z_index = 1000
			dust2.z_index = 1000
			dust1.global_position = actor.foot_1.global_position
			dust2.global_position = actor.foot_2.global_position
			dust1.emitting = true			
			dust2.emitting = true
		)
		land_tween.tween_property(actor, "scale",
			origin_scale, speed * 0.30)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		land_tween.tween_callback(func() -> void: is_hopping = false)
	)
	hops += 1
	_after_takeoff(actor)

# subclass hook — runs once per hop, right after the hop is launched
func _after_takeoff(_actor: PlacedEnemy) -> void:
	pass

func cancel_to_origin(actor: PlacedEnemy) -> void:
	if not is_hopping: return
	for t: Tween in active_tweens:
		if t != null and t.is_valid(): t.kill()
	active_tweens.clear()
	actor.global_position = origin_position
	actor.scale = origin_scale_cached
	if collision_node != null:
		collision_node.scale = origin_collision_scale_cached
	is_hopping = false
