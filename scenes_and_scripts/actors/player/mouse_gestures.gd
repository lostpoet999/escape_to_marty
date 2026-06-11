class_name MouseGestures extends Node2D

const DEFAULT_CLICK_DMG: float = 1.0

var click_behavior: HitBehavior
var hold_probe: CircleShape2D
var hold_behavior: HitBehavior

var mouse_down: bool = false
var mouse_down_time: float = 0.0

@export var click_dmg_type: Array[GameManager.PhaseType] #gesture would impact this??
@export_category("Click & Hold Config")
@export var click_vs_hold: float = 0.2
@export var hold_duration_max: float = 3.0
var hold_indicator_radius: float = 0.0

func _ready() -> void:
	click_behavior = HitBehavior.new()
	click_behavior.targeting = DirectTarget.new()
	hold_probe = CircleShape2D.new()
	var hold_shape: ShapeTarget = ShapeTarget.new()
	hold_shape.probe_shape = hold_probe
	var anger_only: Array[GameManager.PhaseType] = [GameManager.PhaseType.ANGER]
	hold_shape.filter_phases = anger_only
	hold_behavior = HitBehavior.new()
	hold_behavior.targeting = hold_shape

@export_category("Bargain Config")
@export var bargain_sweep_duration: float = 0.37
var bargain_active: bool = false
var bargain_seal: BaseSeal = null
var bargain_bid: float = 0.0


func _input(event: InputEvent)->void:
	
	if event.is_action_pressed("click_mode_toggle") and GameManager.current_state != GameManager.GameState.MAIN_MENU:		
		if GameManager.current_state != GameManager.GameState.CLICK_MODE:
			GameManager.change_state(GameManager.GameState.CLICK_MODE)
		elif GameManager.current_state == GameManager.GameState.CLICK_MODE:
			if bargain_active:
				_resolve_bargain()
			if mouse_down:
				mouse_down = false
				mouse_down_time = 0.0
				click_dmg_type.clear()
				_reset_hold_visuals()
			GameManager.change_state(GameManager.GameState.PLAYING)
			
	
	if GameManager.current_state == GameManager.GameState.CLICK_MODE:
		if not event is InputEventMouseButton:
			return
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				var target: Node = _get_target_under_mouse()
				if _is_bargain_target(target):
					_begin_bargain(target)
				else:
					mouse_down = true
					mouse_down_time = 0.0
			elif bargain_active:
				_resolve_bargain()
			elif mouse_down: #released, detect click vs hold
				mouse_down = false
				if mouse_down_time <= click_vs_hold:
					_handle_clicks_and_hold()
				else:
					_handle_anger_aoe()

func _handle_clicks_and_hold()->void:
	var target: Node = _get_target_under_mouse()
	if target == null:
		return
	click_behavior.apply(_gesture_context(GameManager.PhaseType.DENIAL, _gesture_damage()), target as Node2D)

func _handle_anger_aoe()->void:
	hold_probe.radius = maxf(hold_indicator_radius, 8.0)
	var hold_charge: float = roundf(minf(mouse_down_time, hold_duration_max))
	hold_behavior.apply(_gesture_context(GameManager.PhaseType.ANGER, _gesture_damage() * hold_charge), null)

func _gesture_context(verb_type: GameManager.PhaseType, base: float) -> HitContext:
	var ctx: HitContext = HitContext.new()
	ctx.source = self
	ctx.hit_point = get_global_mouse_position()
	ctx.collision_mask = 0xFFFFFFFF
	ctx.base_damage = base
	var verb_types: Array[GameManager.PhaseType] = [verb_type]
	ctx.dmg_types = verb_types
	ctx.apply = func(target: Node2D, amount: float, _types: Array) -> void:
		if target != null and target.has_method("accept_damage"):
			target.accept_damage(amount, verb_types)
	return ctx

func _gesture_damage() -> float:
	return PlayerInventory.get_instance().get_gesture_damage()

func _get_target_under_mouse() -> Node:	
	var space : PhysicsDirectSpaceState2D = get_viewport().get_world_2d().direct_space_state
	var query : PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = get_viewport().get_mouse_position()
	query.collide_with_areas = true
	var results : Array[Dictionary] = space.intersect_point(query)
	results = results.filter(func(result: Dictionary) -> bool: return result.collider.has_method("accept_damage"))
	if results.is_empty():
		return null
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.collider.z_index > b.collider.z_index)
	return results[0].collider

func _is_bargain_target(target: Node) -> bool:
	return target is BaseSeal and target.current_stage == GameManager.PhaseType.BARGAINING

func _begin_bargain(seal: BaseSeal) -> void:
	bargain_active = true
	bargain_seal = seal
	bargain_bid = 0.0
	queue_redraw()

func _resolve_bargain() -> void:
	if not bargain_active:
		return
	if is_instance_valid(bargain_seal):
		bargain_seal.resolve_bargain(bargain_bid)
	bargain_active = false
	bargain_seal = null
	bargain_bid = 0.0
	queue_redraw()

func _draw_bargain() -> void:
	var track_width: float = 80.0
	var origin: Vector2 = to_local(bargain_seal.global_position) + Vector2(-track_width * 0.5, -44.0)
	var sweet: Vector2 = bargain_seal.bargain_sweet_range()
	draw_line(origin, origin + Vector2(track_width, 0.0), Color(0.85, 0.85, 0.85, 0.7), 3.0)
	draw_line(origin + Vector2(track_width * sweet.x, 0.0), origin + Vector2(track_width * sweet.y, 0.0), Color(0.4, 1.0, 0.5, 0.95), 6.0)
	var needle: Vector2 = origin + Vector2(track_width * bargain_bid, 0.0)
	draw_line(needle + Vector2(0.0, -9.0), needle + Vector2(0.0, 9.0), Color.WHITE, 2.0)

func _reset_hold_visuals()->void: #TODO: goal is for this to feel like a taking a deep breathe
	hold_indicator_radius = 0.0
	queue_redraw()

func _draw() -> void:
	if bargain_active and is_instance_valid(bargain_seal):
		_draw_bargain()
		return
	if hold_indicator_radius > 0.0:
		draw_circle(to_local(get_global_mouse_position()), hold_indicator_radius, Color(0.5, 0.85, 1.0, 0.6))

func _process(delta: float) -> void:
	if bargain_active:
		bargain_bid = minf(bargain_bid + delta / bargain_sweep_duration, 1.0)
		queue_redraw()
		if bargain_bid >= 1.0:
			_resolve_bargain()
		return
	if mouse_down:
		mouse_down_time += delta
		if mouse_down_time >= click_vs_hold and mouse_down_time - delta < click_vs_hold:
			_reset_hold_visuals()
		if mouse_down_time > click_vs_hold:
			var pct : float = minf((mouse_down_time - click_vs_hold) / hold_duration_max, 1.0) #TODO: tie this to powerups for AE and  more anger dmg
			hold_indicator_radius = ease(pct, 0.4) * 48.0
			queue_redraw()
	else:
		if hold_indicator_radius > 0.0:
			hold_indicator_radius = 0.0			
			queue_redraw()
