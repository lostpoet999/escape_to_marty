class_name ShapeDrawVfxNode extends VfxNode

var shape: Shape2D
var color: Color = Color.WHITE
var color_ramp: Gradient
var scale_curve: Curve
var spin_degrees: float = 0.0
var drift: Vector2 = Vector2.ZERO
var canvas_blend_mode: int = -1
var origin: Vector2 = Vector2.ZERO
var base_rotation: float = 0.0

func _ready() -> void:
	if canvas_blend_mode >= 0:
		var blend_material := CanvasItemMaterial.new()
		blend_material.blend_mode = canvas_blend_mode
		material = blend_material
	_apply(0.0)

func _draw() -> void:
	if shape != null:
		shape.draw(get_canvas_item(), Color.WHITE)

func _animate(progress: float, _delta: float) -> void:
	_apply(progress)

func _apply(progress: float) -> void:
	modulate = color_ramp.sample(progress) if color_ramp != null else color
	var grow: float = scale_curve.sample(progress) if scale_curve != null else 1.0
	scale = Vector2.ONE * grow
	position = origin + drift * progress
	rotation = base_rotation + deg_to_rad(spin_degrees * progress)
