class_name RageShot
extends RageBlob

@export var speed: float = 550.0 ## Pixels per second along the launch direction.
@export var spin_speed: float = 10.0 ## Sprite spin in radians per second while flying.

var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	_setup_offscreen_cleanup()
	_setup_death_wall_detector()

func tick_movement(delta: float) -> void:
	$Sprite2D.rotation += spin_speed * delta
	velocity = direction * speed
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
	$Sprite2D.rotation = 0.0
	super(paddle)
