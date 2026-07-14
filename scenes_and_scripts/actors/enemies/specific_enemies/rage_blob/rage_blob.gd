class_name RageBlob
extends FallingEnemy

const FRAME_FALL: int = 0
const FRAME_SPLAT: int = 1
const FRAME_EXPLODE: int = 2
const SPLAT_TOP_FROM_CENTER: float = 19.0

@export var grow_time: float = 1.5
@export var start_scale: float = 0.5
@export var damage_min: int = 1
@export var damage_max: int = 3
@export var death_frame_time: float = 0.4 ## Seconds the splat/explode frame stays on screen before the blob frees.
@export var destroy_fx: PackedScene ## Particle burst instanced at the blob's position when the splat/explode frame ends. Empty = no burst.
@export var splat_top_above_paddle: float = 8.0 ## Pixels the top of the splat frame pokes above the paddle's top edge when the blob seats onto it.

var is_tweening_to_david: bool = false
var dying: bool = false

func _ready() -> void:
	_setup_offscreen_cleanup()	
	falling = false
	scale = Vector2.ONE * start_scale
	_setup_death_wall_detector()
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, grow_time)
	tween.tween_callback(_start_falling)

func _setup_death_wall_detector() -> void:
	var detector: Area2D = $DeathWallDetector
	detector.area_entered.connect(_on_detector_area_entered)

func _on_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group(GameManager.DEATH_WALLS):
		on_hit_death_wall(area)
	elif area is Ball:
		_die_showing(FRAME_EXPLODE, "deon_die")

func tick_movement(delta: float) -> void:
	if falling:
		fall_speed += gravity
	velocity = Vector2(0, fall_speed)
	var motion: Vector2 = velocity * delta
	while true:
		var collision: KinematicCollision2D = move_and_collide(motion)
		if collision == null:
			return
		var collider: Node = collision.get_collider() as Node
		if collider == null:
			return
		if collider.is_in_group(GameManager.PADDLE):
			on_hit_paddle(collider)
			return
		add_collision_exception_with(collider)
		motion = collision.get_remainder()

func on_hit_paddle(paddle: Node) -> void:
	if dying or is_tweening_to_david:
		return
	_die_showing(FRAME_SPLAT, "enemy_hurt")
	_seat_splat_on_paddle(paddle as Node2D)

func _seat_splat_on_paddle(paddle: Node2D) -> void:
	var paddle_shape: CollisionShape2D = paddle.get_node("PaddleCollisionShape")
	var rect: RectangleShape2D = paddle_shape.shape as RectangleShape2D
	var paddle_top: float = paddle_shape.global_position.y - rect.size.y * 0.5
	global_position.y = paddle_top - splat_top_above_paddle + SPLAT_TOP_FROM_CENTER
	reparent.call_deferred(paddle)

func _die_showing(death_frame: int, death_sound: String) -> void:
	if dying or is_tweening_to_david:
		return
	dying = true
	SFX.play_sound(death_sound)
	set_physics_process(false)
	$DeathWallDetector.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.frame = death_frame
	var death_tween: Tween = create_tween()
	death_tween.tween_interval(death_frame_time)
	death_tween.tween_callback(_spawn_destroy_fx)
	death_tween.tween_callback(queue_free)

func _spawn_destroy_fx() -> void:
	if destroy_fx == null:
		return
	var fx: Node2D = destroy_fx.instantiate()
	fx.position = global_position
	get_tree().current_scene.add_child(fx)

func on_hit_death_wall(_wall: Node) -> void:
	if is_tweening_to_david or dying:
		return
	await tween_to_david(global_position)
	PlayerData.accept_damage(randi_range(damage_min, damage_max))
	DialogDirector.play(&"rage_blob_hit")
	on_fall_landed()

func tween_to_david(hit_pos: Vector2) -> void:
	is_tweening_to_david = true
	set_physics_process(false)
	$DeathWallDetector.set_deferred("monitoring", false)

	var david: Node2D = get_tree().get_first_node_in_group("david")
	var hit_target: Node2D = david.get_node("DavidHitTarget")

	var p0: Vector2 = hit_pos
	var p2: Vector2 = hit_target.global_position
	var mid: Vector2 = (p0 + p2) * 0.5
	var sag: float = 40.0
	var p1: Vector2 = mid + Vector2(0, sag)

	var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(
		func(t: float) -> void:
			global_position = _bezier(t, p0, p1, p2),
		0.0, 1.0, 0.2
	)
	await tw.finished

func _bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u: float = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2
