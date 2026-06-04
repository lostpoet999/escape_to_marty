class_name Projectile extends Area2D

@export var speed: float = 800
@export var damage: int
var proj_dmg_type: Array[GameManager.PhaseType]
var spawner: PaddleActive
var behaviors: Array[HitBehavior]
var pierce_remaining: int = 0

func initialize_shot(speed_mod: float, damage_ref: int, spawner_ref: PaddleActive, projectile_dmg_types: Array[GameManager.PhaseType], on_hit: Array[HitBehavior], pierce: int)->void:
	speed *= speed_mod
	damage = damage_ref
	spawner = spawner_ref
	if projectile_dmg_types.is_empty():
		var health_only: Array[GameManager.PhaseType] = [GameManager.PhaseType.HEALTH]
		proj_dmg_type = health_only
	else:
		proj_dmg_type = projectile_dmg_types
	if on_hit.is_empty():
		var base: HitBehavior = HitBehavior.new()
		base.targeting = DirectTarget.new()
		var single: Array[HitBehavior] = [base]
		behaviors = single
	else:
		behaviors = on_hit
	pierce_remaining = pierce
	

func _process(delta: float) -> void:
	global_position += Vector2.UP.rotated(global_rotation) * speed * delta


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bricks"):
		var ctx: HitContext = _make_hit_context()
		for behavior: HitBehavior in behaviors:
			behavior.apply(ctx, area)
		SFX.play_sound("hit-brick")
		_register_hit()
	elif area.is_in_group("walls"):
		SFX.play_sound("bounce_1")
		queue_free()

func _make_hit_context() -> HitContext:
	var ctx: HitContext = HitContext.new()
	ctx.source = self
	ctx.hit_point = global_position
	ctx.collision_mask = collision_mask
	ctx.exclude = [get_rid()]
	ctx.base_damage = damage
	ctx.dmg_types = proj_dmg_type
	ctx.apply = func(target: Node2D, amount: float, types: Array) -> void:
		if target != null and target.has_method("accept_damage"):
			target.accept_damage(amount, types)
	return ctx

func _register_hit() -> void:
	pierce_remaining -= 1
	if pierce_remaining < 0:
		queue_free()


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
