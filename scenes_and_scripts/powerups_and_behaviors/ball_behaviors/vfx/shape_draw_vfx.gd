## Draws the targeting shape as a flat fill and animates it over its lifetime
## (color, scale, spin, drift, blend). The shape itself is supplied by the targeting strategy.
class_name ShapeDrawVfx extends VfxSpec

enum BlendMode {
	## Normal transparency.
	MIX,
	## Glow / fire / energy — author with bright colors; black is invisible.
	ADD,
	## Void / drain / scorch — a bright source darkens the scene.
	SUBTRACT,
	## Ink / stain / shadow — author with dark colors; white is invisible.
	MULTIPLY,
}

## Flat tint, used only when color_ramp is empty. The shape is drawn white, so this fully sets the look.
@export var color: Color = Color(1.0, 1.0, 1.0, 0.5)

## RGBA sampled across the lifetime (0 = spawn, 1 = death). Sets both color and fade — end at alpha 0 to fade out. Overrides color when set.
@export var color_ramp: Gradient

## Size multiplier over the lifetime (X = progress, Y = scale; 1.0 = full footprint). Raise the curve's max_value above 1 for overshoot. Empty = full size, no scaling.
@export var scale_curve: Curve

## Total rotation over the lifetime. 360 = one full turn; positive spins clockwise. No visible effect on circles.
@export var spin_degrees: float = 0.0

## Pixel offset travelled from the hit point over the lifetime. +Y is downward.
@export var drift: Vector2 = Vector2.ZERO

## How the effect combines with the background.
## Mix: normal transparency.
## Add: glow / fire / energy (bright colors; black is invisible).
## Subtract: void / drain (a bright source darkens the scene).
## Multiply: ink / stain / shadow (dark colors; white is invisible).
@export var blend: BlendMode = BlendMode.MIX

## Seconds the effect lives before freeing itself.
@export var lifetime: float = 0.3

func spawn_fitted(parent: Node, world_transform: Transform2D, shape: Shape2D) -> Node:
	if shape == null:
		return null
	var node := ShapeDrawVfxNode.new()
	node.shape = shape
	node.color = color
	node.color_ramp = color_ramp
	node.scale_curve = scale_curve
	node.spin_degrees = spin_degrees
	node.drift = drift
	node.canvas_blend_mode = _native_blend()
	node.lifetime = lifetime
	node.origin = world_transform.origin
	node.base_rotation = world_transform.get_rotation()
	parent.add_child(node)
	return node

func _native_blend() -> int:
	match blend:
		BlendMode.ADD: return CanvasItemMaterial.BLEND_MODE_ADD
		BlendMode.SUBTRACT: return CanvasItemMaterial.BLEND_MODE_SUB
		BlendMode.MULTIPLY: return CanvasItemMaterial.BLEND_MODE_MUL
		_: return -1
