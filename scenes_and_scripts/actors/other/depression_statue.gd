class_name DepressionStatue extends Node2D

signal charge_changed

const _TEXTURE_HALF_PX: float = 128.0

## Seconds of light this statue needs before it locks. Set per corner in reading order: 10 / 15 / 22 / 30.
@export var charge_seconds: float = 10.0
## Grief-phase tint: paints the placeholder box and the light this statue throws as it fills.
@export var phase_color: Color = Color("a23e8c")
## Charge seconds gained per second while at least one live depression light is in reach. Two lights in reach do not stack.
@export var charge_rate: float = 1.0
## Reach (px) from the statue center a light must be inside to feed it. 0 = use each light's own radius, so the visible glow edge is the functional edge.
@export var charge_radius: float = 0.0
## Charge seconds an imp tears off per strike. Three strikes land per drain run, and only one imp at a time may work a statue, so this is the whole drain budget against charge_rate. Above ~1.6 the imps out-drain the player and the encounter cannot be finished.
@export var drain_per_strike: float = 1.0
## Once full, the statue locks and can no longer be drained. Off makes finished statues drainable again, which four imps make unwinnable.
@export var locks_when_charged: bool = true
## Contributor art for the dormant statue. Empty = the placeholder box shows instead.
@export var statue_texture: Texture2D
## Contributor art swapped in once the statue is charged. Empty = the dormant art stays.
@export var charged_texture: Texture2D
## Light brightness at full charge; the light ramps from idle_light_fraction up to this as the statue fills.
@export var light_energy: float = 2.4
## Share of light_energy a dormant statue still throws, so the player can find it in the floor-4 dark before it has any charge. 0 makes an uncharged statue invisible.
@export_range(0.0, 1.0) var idle_light_fraction: float = 0.18
## Radius (px) of the light a charged statue throws into the floor-4 dark.
@export var light_radius: float = 260.0
## Seconds for one full blink of a charged statue, dim to bright and back.
@export var charged_pulse_period: float = 0.9
## Dim end of the charged blink, as a share of light_energy.
@export var charged_pulse_low: float = 0.4
## Bright end of the charged blink, as a share of light_energy. Above 1 overbrights the statue art.
@export var charged_pulse_high: float = 1.45
## Brightness spike the instant a statue finishes charging, as a share of light_energy.
@export var charge_complete_flash_level: float = 3.0
## Seconds the completion spike takes to fall back into the steady blink.
@export var charge_complete_flash_time: float = 0.45

var charge: float = 0.0

var _locked: bool = false
var _drainer: Node2D = null
var _gestures: MouseGestures
var _pulse: Tween
var _flash: Tween

@onready var _placeholder: ColorRect = $Placeholder
@onready var _art: Sprite2D = $Art
@onready var _light: PointLight2D = $StatueLight

func _ready() -> void:
	_placeholder.color = phase_color
	_light.color = phase_color
	_light.texture_scale = light_radius / _TEXTURE_HALF_PX
	_update_visuals()

func _process(delta: float) -> void:
	if _locked:
		return
	if GameManager.current_state == GameManager.GameState.LEVEL_CLEARED:
		return
	if not _light_in_reach():
		return
	_add_charge(charge_rate * delta)

func is_charged() -> bool:
	return charge >= charge_seconds - 0.001

func is_drainable(by: Node2D = null) -> bool:
	if _locked or charge <= 0.0:
		return false
	if _drainer == by:
		return true
	return _drainer == null or not is_instance_valid(_drainer) or _drainer.is_queued_for_deletion()

func claim_drain(imp: Node2D) -> void:
	_drainer = imp

func release_drain(imp: Node2D) -> void:
	if _drainer == imp:
		_drainer = null

func charge_fraction() -> float:
	if charge_seconds <= 0.0:
		return 1.0
	return clampf(charge / charge_seconds, 0.0, 1.0)

func force_charged(animate: bool = true, lock: bool = true) -> void:
	charge = charge_seconds
	_locked = lock
	if animate:
		_update_visuals()
		return
	_light.enabled = true
	_apply_art(charged_texture if charged_texture != null else statue_texture)
	_start_charged_blink()

func apply_imp_strike() -> void:
	if _locked:
		return
	_add_charge(-drain_per_strike)

func drain(amount: float) -> void:
	if _locked:
		return
	_add_charge(-amount)

func _add_charge(amount: float) -> void:
	var before: float = charge
	var was_charged: bool = is_charged()
	charge = clampf(charge + amount, 0.0, charge_seconds)
	if is_charged() and locks_when_charged:
		_locked = true
	if is_equal_approx(before, charge):
		return
	_update_visuals()
	if is_charged() != was_charged or floori(before) != floori(charge):
		charge_changed.emit()

func _light_in_reach() -> bool:
	var gestures: MouseGestures = _resolve_gestures()
	if gestures == null:
		return false
	for node: Node2D in gestures.depression_lights:
		var light: DepressionLight = node as DepressionLight
		if light == null or not is_instance_valid(light):
			continue
		if light.is_queued_for_deletion() or not light.is_lit():
			continue
		var reach: float = charge_radius if charge_radius > 0.0 else light.radius
		if global_position.distance_to(light.global_position) <= reach:
			return true
	return false

func _resolve_gestures() -> MouseGestures:
	if _gestures != null and is_instance_valid(_gestures):
		return _gestures
	_gestures = get_tree().get_first_node_in_group(&"mouse_gestures") as MouseGestures
	return _gestures

func _update_visuals() -> void:
	_light.enabled = true
	if is_charged():
		if _pulse == null and _flash == null:
			_play_charge_complete_flash()
	else:
		_stop_charged_blink()
		_apply_glow(lerpf(idle_light_fraction, 1.0, charge_fraction()), false)
	if is_charged() and charged_texture != null:
		_apply_art(charged_texture)
		return
	_apply_art(statue_texture)

func _play_charge_complete_flash() -> void:
	_flash = create_tween()
	_flash.tween_method(_apply_charged_glow, charge_complete_flash_level, charged_pulse_high, charge_complete_flash_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash.finished.connect(_start_charged_blink)

func _start_charged_blink() -> void:
	_flash = null
	if not is_charged():
		return
	_pulse = create_tween()
	_pulse.set_loops()
	_pulse.tween_method(_apply_charged_glow, charged_pulse_high, charged_pulse_low, charged_pulse_period * 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.tween_method(_apply_charged_glow, charged_pulse_low, charged_pulse_high, charged_pulse_period * 0.5).set_trans(Tween.TRANS_SINE)

func _stop_charged_blink() -> void:
	if _flash != null:
		_flash.kill()
		_flash = null
	if _pulse != null:
		_pulse.kill()
		_pulse = null

func _apply_charged_glow(level: float) -> void:
	_apply_glow(level, true)

func _apply_glow(level: float, tint_visual: bool) -> void:
	_light.energy = light_energy * level
	var tint: float = clampf(level, 0.0, 2.0) if tint_visual else 1.0
	var shade: Color = Color(tint, tint, tint, 1.0)
	_placeholder.modulate = shade
	_art.modulate = shade

func _apply_art(texture: Texture2D) -> void:
	if texture == null:
		_art.visible = false
		_placeholder.visible = true
		return
	if _art.texture != texture:
		_art.texture = texture
	_art.visible = true
	_placeholder.visible = false
