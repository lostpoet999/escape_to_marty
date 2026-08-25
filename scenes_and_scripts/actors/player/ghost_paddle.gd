class_name GhostPaddle
extends Area2D

const GHOST_PADDLE_GROUP: StringName = &"ghost_paddle"
const CATCHABLE_GROUP: StringName = &"ghost_catchable"

var paddle: Paddle = null
var shape_node: CollisionShape2D = null
var sprite_node: Sprite2D = null


func setup(host: Paddle, size: Vector2) -> void:
	paddle = host
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = size
	shape_node = CollisionShape2D.new()
	shape_node.shape = box
	add_child(shape_node)

func _ready() -> void:
	add_to_group(GHOST_PADDLE_GROUP)
	body_entered.connect(_on_body_entered)

func set_ghost_hidden(is_hidden: bool) -> void:
	visible = not is_hidden
	set_deferred("monitoring", not is_hidden)
	if shape_node != null:
		shape_node.set_deferred("disabled", is_hidden)
	if sprite_node != null and is_instance_valid(sprite_node):
		sprite_node.visible = not is_hidden

func _exit_tree() -> void:
	if sprite_node != null and is_instance_valid(sprite_node):
		sprite_node.queue_free()
		sprite_node = null

func half_width() -> float:
	if shape_node == null:
		return 0.0
	var box: RectangleShape2D = shape_node.shape as RectangleShape2D
	if box == null:
		return 0.0
	return box.size.x * 0.5

func _on_body_entered(body: Node2D) -> void:
	if paddle == null or not body.is_in_group(CATCHABLE_GROUP):
		return
	if not body.has_method("on_hit_paddle"):
		return
	body.call("on_hit_paddle", paddle)
