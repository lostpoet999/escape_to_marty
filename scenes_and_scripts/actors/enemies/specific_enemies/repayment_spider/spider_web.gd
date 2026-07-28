class_name SpiderWeb
extends Area2D

const LIFETIME: float = 10.0
const FALL_GRAVITY: float = 700.0
const BLINK_INTERVAL: float = 0.12
const BLINK_COUNT: int = 3
const OFFSCREEN_Y: float = 1300.0

@export var shakes_to_break: int = 5 ## Mouse direction reversals needed to shake this web off the paddle.
var target_position: Vector2 = Vector2.ZERO
var speed: float = 140.0
var _age: float = 0.0
var _expired: bool = false
var _falling: bool = false
var _fall_speed: float = 0.0

func _ready() -> void:
	add_to_group(&"spider_webs")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	if _falling:
		_fall_speed += FALL_GRAVITY * delta
		position.y += _fall_speed * delta
		if global_position.y > OFFSCREEN_Y:
			queue_free()
		return
	if _expired:
		return
	var to_target: Vector2 = target_position - global_position
	var step: float = speed * delta
	if to_target.length() <= step:
		global_position = target_position
		_expire()
	else:
		global_position += to_target.normalized() * step

func _expire() -> void:
	_expired = true
	set_deferred("monitoring", false)
	var blink: Tween = create_tween()
	for i: int in BLINK_COUNT:
		blink.tween_property(self, "modulate:a", 0.15, BLINK_INTERVAL)
		blink.tween_property(self, "modulate:a", 1.0, BLINK_INTERVAL)
	blink.tween_callback(func() -> void: _falling = true)

func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion() or _expired or not body.is_in_group(GameManager.PADDLE):
		return
	var paddle: Paddle = body as Paddle
	if paddle != null:
		paddle.apply_web(shakes_to_break)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(GameManager.DEATH_WALLS) or area.is_in_group(&"ball"):
		queue_free()
