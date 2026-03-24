class_name MouseGestures extends Node2D

var mouse_down: bool = false
var mouse_down_time: float = 0.0

@export var click_dmg_type: Array[GameManager.PhaseType] #gesture would impact this??
@export_category("Click & Hold Config")
@export var click_vs_hold: float = 0.2
@export var hold_duration_max: float = 3.0
var damage: float = 0.0
var hold_indicator_radius: float = 0.0


func _input(event: InputEvent)->void:
	
	if event.is_action_pressed("click_mode_toggle") and GameManager.current_state != GameManager.GameState.MAIN_MENU:
		print("click mode entered")
		if GameManager.current_state != GameManager.GameState.CLICK_MODE:
			GameManager.change_state(GameManager.GameState.CLICK_MODE)
		elif GameManager.current_state == GameManager.GameState.CLICK_MODE:
			if mouse_down:
				mouse_down = false
				mouse_down_time = 0.0
				click_dmg_type.clear()
				_reset_hold_visuals()
			GameManager.change_state(GameManager.GameState.PLAYING)
			
	
	if GameManager.current_state == GameManager.GameState.CLICK_MODE:
		if not event is InputEventMouseButton:
			return	
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_down = true
				mouse_down_time = 0.0
			else: #released, detect click vs hold
				mouse_down = false
				click_dmg_type.clear()
				if mouse_down_time <= click_vs_hold: #a normal hold
					click_dmg_type.push_back(GameManager.PhaseType.DENIAL)
					damage = 1.0 #TODO this will be pulled from player/powerup data for click
					_handle_clicks_and_hold()
				else:
					click_dmg_type.push_back(GameManager.PhaseType.ANGER)
					damage = roundf(minf(mouse_down_time, hold_duration_max))
					_handle_clicks_and_hold()

func _handle_clicks_and_hold()->void:
	var target = _get_target_under_mouse()
	if target == null:
		return
	if target.has_method("accept_damage"):		
		target.accept_damage(damage, click_dmg_type)

func _get_target_under_mouse() -> Node:	
	var space := get_viewport().get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_viewport().get_mouse_position()
	query.collide_with_areas = true
	var results := space.intersect_point(query)
	if results.is_empty():		
		return null
	results.sort_custom(func(a, b): return a.collider.z_index > b.collider.z_index)	
	return results[0].collider

func _reset_hold_visuals(): #TODO: goal is for this to feel like a taking a deep breathe
	hold_indicator_radius = 0.0
	queue_redraw()

func _draw() -> void:
	if hold_indicator_radius > 0.0:
		draw_circle(to_local(get_global_mouse_position()), hold_indicator_radius, Color(0.4, 0.7, 1.0, 0.3))

func _process(delta: float) -> void:
	if mouse_down:
		mouse_down_time += delta
		if mouse_down_time >= click_vs_hold and mouse_down_time - delta < click_vs_hold:
			_reset_hold_visuals()
		if mouse_down_time > click_vs_hold:
			var pct := minf((mouse_down_time - click_vs_hold) / hold_duration_max, 1.0)
			hold_indicator_radius = ease(pct, -2.0) * 48.0			
			queue_redraw()
	else:
		if hold_indicator_radius > 0.0:
			hold_indicator_radius = 0.0			
			queue_redraw()
