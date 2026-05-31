class_name FallingEnemy
extends CharacterBody2D

# generic falling-enemy chassis. subclasses override the on_hit_* virtuals
# and optionally tick_movement() for non-straight fall behavior.

var falling: bool = false
@export var gravity: float = 9.8
@export var fall_speed: float = 0
@export var fall_delay: float = 0.2

func _ready() -> void:
	_setup_offscreen_cleanup()
	_pause_falling()

# offscreen-exit safety net. override to customize rect or skip entirely (e.g. seekers that re-enter view).
func _setup_offscreen_cleanup() -> void:
	var notifier: VisibleOnScreenNotifier2D = VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(-100, -100, 200, 200)
	notifier.screen_exited.connect(queue_free)
	add_child(notifier)

func _pause_falling() -> void:
	falling = false
	await get_tree().create_timer(fall_delay).timeout
	_start_falling()

func _start_falling() -> void:
	falling = true

func _physics_process(delta: float) -> void:
	tick_movement(delta)

# default: straight fall with gravity. override for arc, seek, etc.
func tick_movement(delta: float) -> void:
	if falling:
		fall_speed += gravity
	velocity = Vector2(0, fall_speed)
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		_dispatch_collision(collision.get_collider())

func _dispatch_collision(collider: Node) -> void:
	if collider.is_in_group(GameManager.PADDLE):
		on_hit_paddle(collider)
	elif collider.is_in_group("bounce_enemy"):
		on_hit_enemy(collider)

# helper for "land + free" — camera shake + queue_free.
func on_fall_landed() -> void:
	get_viewport().get_camera_2d().add_trauma(0.7)
	queue_free()

# --- virtual hooks. base dispatches paddle/enemy from tick_movement.
# ball/death_wall are Area2D — base does not auto-wire detection;
# subclasses that need them add area-overlap dispatch themselves.

func on_hit_paddle(_paddle: Node) -> void: pass
func on_hit_enemy(_enemy: Node) -> void: pass
func on_hit_ball(_ball: Node) -> void: pass
func on_hit_death_wall(_wall: Node) -> void: pass
