class_name HopToCenter
extends EnemyActions

const CENTER:float = 1088.00
const LEFT:float = 384.00
const LEFT_CENTER:float  = 960.00
const RIGHT_CENTER: float = 1216.00
const RIGHT: float = 1782.00

var target_x:float
var is_hopping: bool = false


@export var hop_distance: float
@export var up_distance: float
@export var speed: float
@export var max_hops: int
@export var back_chance: float
var hops: int = 0

func reset()->void:
	hops = 0
	is_hopping = false

func set_target_x(actor: PlacedEnemy)->void:	
	if actor.global_position.x <= LEFT_CENTER:
		if randf_range(1,100) <= back_chance and actor.global_position.x > 384:
			target_x = actor.global_position.x - hop_distance
		elif actor.global_position.x != LEFT_CENTER:
			target_x = actor.global_position.x + hop_distance
	elif actor.global_position.x >= RIGHT_CENTER:
		if randf_range(1,100) <= back_chance and actor.global_position.x < 1782:
			target_x = actor.global_position.x + hop_distance
		elif actor.global_position.x != RIGHT_CENTER:
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
	# --- Landing fires after arc completes ---
	up_tween.tween_callback(func() -> void:
		var land_tween: Tween = actor.create_tween()
		land_tween.tween_property(actor, "scale",
			Vector2(origin_scale.x * 1.3, origin_scale.y * 0.7), speed * 0.10)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		land_tween.tween_callback(func() -> void:
			SFX.play_sound("landing")
		)
		land_tween.tween_property(actor, "scale",
			origin_scale, speed * 0.30)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		land_tween.tween_callback(func() -> void: is_hopping = false)
	)
	hops += 1
