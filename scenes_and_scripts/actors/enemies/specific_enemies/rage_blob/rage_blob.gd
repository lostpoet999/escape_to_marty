class_name RageBlob
extends FallingEnemy

@export var grow_time: float = 1.5
@export var start_scale: float = 0.5
@export var damage_min: int = 1
@export var damage_max: int = 3

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

func on_hit_paddle(_paddle: Node) -> void:	
	queue_free()

func on_hit_death_wall(_wall: Node) -> void:
	PlayerData.accept_damage(randi_range(damage_min, damage_max))
	Signalbus.screen_flash.emit(Color.RED)
	on_fall_landed()
