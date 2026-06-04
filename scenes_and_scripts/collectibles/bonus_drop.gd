class_name BonusDrop extends Area2D

@export var fall_speed: float = 120.0

var payload: BonusPayload
var collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if payload:
		if payload.drop_texture:
			sprite.texture = payload.drop_texture
		sprite.modulate = payload.drop_modulate
	SFX.play_sound("rare_drop")
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
	tween.set_loops(0)

func _process(delta: float) -> void:
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
