extends Node2D
## Runtime dressing for the contributor portal art (portal.tscn), attached as a
## script override on the Visual instance in floor_portal.tscn so the art scene
## stays untouched. Each swirl particle spawns as a random bright Apollo color;
## the spiral sprite pulses while cross-fading through the same palette.

## Brightest entry of each Apollo hue ramp (blue, green, tan, yellow, red, purple).
const BRIGHT_APOLLO_COLORS: Array[Color] = [
	Color("#a4dddb"),
	Color("#d0da91"),
	Color("#e7d5b3"),
	Color("#e8c170"),
	Color("#da863e"),
	Color("#df84a5"),
]
const CATEGORY_FADE_TIME: float = 1.6
const PULSE_SCALE: float = 1.08

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	_color_particles()
	_start_spiral_cycle()

func _color_particles() -> void:
	var gradient: Gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets: PackedFloat32Array = PackedFloat32Array()
	var colors: PackedColorArray = PackedColorArray()
	for i in BRIGHT_APOLLO_COLORS.size():
		offsets.append(float(i) / BRIGHT_APOLLO_COLORS.size())
		colors.append(BRIGHT_APOLLO_COLORS[i])
	gradient.offsets = offsets
	gradient.colors = colors
	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = gradient
	var mat: ParticleProcessMaterial = _particles.process_material
	mat.color_initial_ramp = ramp
	_particles.modulate = Color.WHITE
	_particles.restart()

func _start_spiral_cycle() -> void:
	var base_scale: Vector2 = _sprite.scale
	var color_tween: Tween = create_tween().set_loops()
	for category_color in BRIGHT_APOLLO_COLORS:
		color_tween.tween_property(_sprite, "modulate", category_color, CATEGORY_FADE_TIME)
	var pulse_tween: Tween = create_tween().set_loops()
	pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(_sprite, "scale", base_scale * PULSE_SCALE, CATEGORY_FADE_TIME * 0.5)
	pulse_tween.tween_property(_sprite, "scale", base_scale, CATEGORY_FADE_TIME * 0.5)
