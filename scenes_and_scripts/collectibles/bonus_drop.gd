class_name BonusDrop extends Area2D

@export var fall_speed: float = 120.0
@export var pull_speed: float = 320.0 ## Speed the drop curves toward a spider captor; it falls normally when uncaptured.
@export var display_size: float = 32.0 ## On-screen size (longest side, px) every drop renders at, regardless of the source art's resolution.

const COIN_MAX_FALL_PAUSE: float = 0.25
const COIN_FALL_SPEED_VARIANCE_MIN: float = 0.85
const COIN_FALL_SPEED_VARIANCE_MAX: float = 1.2

var payload: BonusPayload
var collected: bool = false
var captor: Node2D
var _fall_delay: float = 0.0
var _anim_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if payload:
		if payload.drop_texture:
			sprite.texture = payload.drop_texture
		sprite.hframes = maxi(payload.drop_hframes, 1)
		if sprite.hframes > 1:
			_anim_time = randf() * float(sprite.hframes)
			sprite.frame = int(_anim_time) % sprite.hframes
		sprite.modulate = payload.drop_modulate
		if payload.is_rare and not payload is ShieldPayload:
			SFX.play_sound("rare_drop")
		if payload is CurrencyPayload:
			fall_speed *= randf_range(COIN_FALL_SPEED_VARIANCE_MIN, COIN_FALL_SPEED_VARIANCE_MAX)
			_fall_delay = randf_range(0.0, COIN_MAX_FALL_PAUSE)
	_fit_sprite()
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
	tween.set_loops(0)

func _fit_sprite() -> void:
	if sprite.texture == null:
		return
	var frame_width: float = float(sprite.texture.get_width()) / float(maxi(sprite.hframes, 1))
	var frame_height: float = float(sprite.texture.get_height()) / float(maxi(sprite.vframes, 1))
	var longest: float = maxf(frame_width, frame_height)
	if longest <= 0.0:
		return
	var target: float = display_size * (payload.drop_scale if payload else 1.0)
	sprite.scale = Vector2.ONE * (target / longest)
	_fit_collision(Vector2(frame_width, frame_height) * sprite.scale)

func _fit_collision(rendered_size: Vector2) -> void:
	var box: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if box == null:
		return
	# shape is resource_local_to_scene in bonus_drop.tscn, so this resize stays on this drop
	box.size = rendered_size

func _advance_frame(delta: float) -> void:
	if payload == null or sprite.hframes <= 1 or payload.drop_anim_fps <= 0.0:
		return
	_anim_time += delta * payload.drop_anim_fps
	sprite.frame = int(_anim_time) % sprite.hframes

func _process(delta: float) -> void:
	_advance_frame(delta)
	if captor != null and is_instance_valid(captor):
		global_position = global_position.move_toward(captor.global_position, pull_speed * delta)
	else:
		if _fall_delay > 0.0:
			_fall_delay -= delta
			return
		position.y += fall_speed * delta

func _on_area_entered(area: Area2D) -> void:
	if collected:
		return
	if area.is_in_group(GameManager.DEATH_WALLS):
		collected = true
		Signalbus.gold_collected.emit(-1)
		queue_free()
	elif area.is_in_group("david") or area.is_in_group(GhostPaddle.GHOST_PADDLE_GROUP):
		collect()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameManager.PADDLE):
		collect()

func collect() -> void:
	if collected:
		return
	collected = true
	set_deferred("monitoring", false)
	Signalbus.gold_collected.emit(-1)
	PlayerData.play_gold_pickup_sfx()
	if payload:
		payload.apply()
	visible = false
	call_deferred("queue_free")
