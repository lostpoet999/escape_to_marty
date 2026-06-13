class_name DepressionLight extends Node2D

const DEPRESSION_TYPES: Array[GameManager.PhaseType] = [GameManager.PhaseType.DEPRESSION]
const _TEXTURE_HALF_PX: float = 128.0
const _ORB_TEXTURE_HALF_PX: float = 32.0

@export_category("Reach & Damage")
## Radius (px) within which seals are lit (held safe from regrow/reseed) and DEPRESSION seals take tick damage.
@export var radius: float = 96.0
## Seconds between damage ticks for a perfectly centered seal (the fast, rewarding cadence).
@export var tick_interval_centered: float = 1.0
## Seconds between damage ticks for a seal at the very rim of the light (slow — the rim still chips away, it just drags).
@export var tick_interval_edge: float = 3.0
## DEPRESSION phase-HP removed per tick. Whole numbers only — centering controls tick RATE, not damage size, so the popups stay clean.
@export var damage_per_tick: float = 1.0
## Within this fraction of radius ticks fire at the full centered rate; beyond it the cadence slows toward tick_interval_edge. A forgiving bright core.
@export_range(0.0, 1.0) var full_power_fraction: float = 0.35
@export_flags_2d_physics var collision_mask: int = 0xFFFFFFFF

@export_category("Lifetime")
## Seconds the light holds at full brightness before the quick extinguish (no gradual dim).
@export var lifetime: float = 4.0
## Seconds for the quick snap from full to zero at the very end.
@export var drop_duration: float = 0.5

@export_category("Flicker warning")
## Times (as fraction of lifetime) the light pulses red to warn it is about to die. The first entry is when the warning starts.
@export var flicker_fractions: Array[float] = [0.75, 0.9]
## Seconds each warning pulse lasts.
@export var flicker_duration: float = 0.18
## Brightness multiplier during a pulse (>1 makes it a bright pop).
@export var flicker_boost: float = 1.5
## Colour of the warning pulse.
@export var flicker_color: Color = Color(1, 0.15, 0.1)

@export_category("Look")
## PointLight2D brightness.
@export var light_energy: float = 1.8
## PointLight2D tint.
@export var light_color: Color = Color(1, 0.9, 0.68)
## Visual glow size relative to damage radius (1.0 = glow edge ~ damage edge).
@export var light_scale_ratio: float = 1.0

@export_category("Orb marker")
## Warm yellow tint of the placement orb at full life.
@export var orb_color_full: Color = Color(1, 0.88, 0.45)
## Dark gray the orb fades toward as it burns out — the continuous lifetime gauge (replaces the red flash).
@export var orb_color_dying: Color = Color(0.22, 0.22, 0.25)
## Fraction of lifetime after which the orb starts graying. 0 = grays steadily across the whole life (a fuel gauge); >0 holds full first.
@export_range(0.0, 1.0) var orb_dim_start_fraction: float = 0.0
## Radius (px) of the placement orb sprite at full life.
@export var orb_radius: float = 20.0
## Orb scale at end of life relative to full (steady shrink alongside the gray-out makes the fuel gauge more noticeable). 1.0 = no shrink.
@export_range(0.1, 1.0) var orb_dying_scale: float = 0.6

@onready var point_light: PointLight2D = $PointLight2D
@onready var orb: Sprite2D = $Orb

var _targeting: ShapeTarget
var _age: float = 0.0
var _tick_accum: Dictionary = {}
var _extinguished: bool = false
var _orb_base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	var probe: CircleShape2D = CircleShape2D.new()
	probe.radius = radius
	_targeting = ShapeTarget.new()
	_targeting.probe_shape = probe
	if point_light != null:
		point_light.energy = light_energy
		point_light.color = light_color
		point_light.texture_scale = (radius / _TEXTURE_HALF_PX) * light_scale_ratio
	if orb != null:
		_orb_base_scale = Vector2.ONE * (orb_radius / _ORB_TEXTURE_HALF_PX)
		orb.scale = _orb_base_scale
		orb.modulate = orb_color_full

func _process(delta: float) -> void:
	if _extinguished:
		return
	_age += delta
	if _age >= lifetime:
		extinguish()
		return
	if point_light != null:
		if _in_flicker(_age / lifetime):
			point_light.energy = light_energy * flicker_boost
			point_light.color = flicker_color
		else:
			point_light.energy = light_energy * maxf(_fade_factor(), 0.0)
			point_light.color = light_color
	_update_orb()
	var lit: Array[Node2D] = _seals_in_reach()
	var live_ids: Dictionary = {}
	for node: Node2D in lit:
		if node.has_method("illuminate"):
			node.illuminate()
		if node is BaseSeal and (node as BaseSeal).current_stage == GameManager.PhaseType.DEPRESSION:
			var id: int = node.get_instance_id()
			live_ids[id] = true
			var interval: float = _tick_interval_for(global_position.distance_to(node.global_position))
			var accum: float = float(_tick_accum.get(id, 0.0)) + delta
			if accum >= interval:
				accum -= interval
				node.accept_damage(damage_per_tick, DEPRESSION_TYPES)
			_tick_accum[id] = accum
	for id: int in _tick_accum.keys():
		if not live_ids.has(id):
			_tick_accum.erase(id)

func _tick_interval_for(dist: float) -> float:
	return lerpf(tick_interval_centered, tick_interval_edge, 1.0 - _centeredness(dist))

func _centeredness(dist: float) -> float:
	var t: float = clampf(dist / radius, 0.0, 1.0)
	if t <= full_power_fraction:
		return 1.0
	var k: float = (t - full_power_fraction) / maxf(1.0 - full_power_fraction, 0.001)
	return 1.0 - clampf(k, 0.0, 1.0)

func _update_orb() -> void:
	if orb == null:
		return
	var drop_start: float = maxf(lifetime - drop_duration, 0.001)
	var age_frac: float = clampf(_age / lifetime, 0.0, 1.0)
	orb.scale = _orb_base_scale * lerpf(1.0, orb_dying_scale, age_frac)
	var tint: Color
	var alpha: float = 1.0
	if _age >= drop_start:
		tint = orb_color_dying
		alpha = 1.0 - clampf((_age - drop_start) / maxf(drop_duration, 0.001), 0.0, 1.0)
	else:
		var span: float = maxf(drop_start / lifetime - orb_dim_start_fraction, 0.001)
		var k: float = clampf((age_frac - orb_dim_start_fraction) / span, 0.0, 1.0)
		tint = orb_color_full.lerp(orb_color_dying, k)
	tint.a *= alpha
	orb.modulate = tint

func _fade_factor() -> float:
	var drop_start: float = maxf(lifetime - drop_duration, 0.001)
	if _age < drop_start:
		return 1.0
	var d: float = (_age - drop_start) / maxf(drop_duration, 0.001)
	return 1.0 - clampf(d, 0.0, 1.0)

func _in_flicker(t: float) -> bool:
	var window: float = flicker_duration / maxf(lifetime, 0.001)
	for f: float in flicker_fractions:
		if t >= f and t < f + window:
			return true
	return false

func _seals_in_reach() -> Array[Node2D]:
	var ctx: HitContext = HitContext.new()
	ctx.source = self
	ctx.hit_point = global_position
	ctx.collision_mask = collision_mask
	return _targeting.select(ctx, null)

## Snuff the light early (the future light-snuff enemy calls this). Depression then regrows in the dark.
func extinguish() -> void:
	if _extinguished:
		return
	_extinguished = true
	var tween: Tween = get_tree().create_tween()
	if point_light != null:
		tween.tween_property(point_light, "energy", 0.0, 0.25)
	tween.tween_callback(queue_free)
