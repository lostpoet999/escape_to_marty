class_name BonusDrop extends Area2D

@export var fall_speed: float = 120.0
@export var pull_speed: float = 320.0 ## Speed the drop curves toward a spider captor; it falls normally when uncaptured.
@export var display_size: float = 32.0 ## On-screen size (longest side, px) every drop renders at, regardless of the source art's resolution.

var payload: BonusPayload
var collected: bool = false
var captor: Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if payload:
		if payload.drop_texture:
			sprite.texture = payload.drop_texture
		sprite.modulate = payload.drop_modulate
		if payload.is_rare:
			SFX.play_sound("rare_drop")
	_fit_sprite()
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
	tween.set_loops(0)

func _fit_sprite() -> void:
	if sprite.texture == null:
		return
	var longest: float = maxf(sprite.texture.get_width(), sprite.texture.get_height())
	if longest > 0.0:
		sprite.scale = Vector2.ONE * (display_size / longest)

func _process(delta: float) -> void:
	if captor != null and is_instance_valid(captor):
		global_position = global_position.move_toward(captor.global_position, pull_speed * delta)
	else:
		position.y += fall_speed * delta

func _on_area_entered(area: Area2D) -> void:
	if collected:
		return
	if area.is_in_group(GameManager.DEATH_WALLS):
		collected = true
		Signalbus.star_collected.emit(-1)
		queue_free()
	elif area.is_in_group("david"):
		collect()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(GameManager.PADDLE):
		collect()

func collect() -> void:
	if collected:
		return
	collected = true
	set_deferred("monitoring", false)
	Signalbus.star_collected.emit(-1)
	SFX.play_sound("star_collected")
	if payload:
		payload.apply()
	visible = false
	call_deferred("queue_free")
