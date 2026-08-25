class_name SpitCoin
extends BonusDrop

const GRAVITY: float = 650.0
const MISS_TINT: Color = Color("a53030")
const HEART_ARC_TIME: float = 0.25
const HEART_ARC_SAG: float = 40.0
const OFFSCREEN_DROP_DISTANCE: float = 900.0
const OFFSCREEN_DROP_TIME: float = 0.5
const STRAY_FLOOR_Y: float = 1300.0
const FACE_FRAME: int = 1

@export var hurts_on_miss: bool = false ## Red spit coin: reaching the DeathWall arcs to David's heart for 1 damage before the coin is destroyed; off = a plain lost coin (death-burst drops).
var launch_velocity: Vector2 = Vector2.ZERO
var _resolving_miss: bool = false

func _ready() -> void:
	super()
	sprite.frame = FACE_FRAME
	if hurts_on_miss:
		sprite.modulate = MISS_TINT
	var room: SpiderEncounterRoom = get_tree().current_scene as SpiderEncounterRoom
	if room != null:
		room.register_coin(hurts_on_miss)

func _process(delta: float) -> void:
	if _resolving_miss:
		_advance_frame(delta)
		return
	if launch_velocity == Vector2.ZERO:
		super(delta)
		return
	_advance_frame(delta)
	launch_velocity.y += GRAVITY * delta
	position += launch_velocity * delta
	if global_position.y > STRAY_FLOOR_Y and not collected:
		collected = true
		Signalbus.gold_collected.emit(-1)
		_notify_resolved()
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if collected or _resolving_miss:
		return
	if area.is_in_group(GameManager.DEATH_WALLS):
		if hurts_on_miss:
			_resolve_hurt_miss()
		else:
			collected = true
			Signalbus.gold_collected.emit(-1)
			_notify_resolved()
			queue_free()
	elif area.is_in_group("david") or area.is_in_group(GhostPaddle.GHOST_PADDLE_GROUP):
		collect()

func collect() -> void:
	if collected:
		return
	super()
	_notify_resolved()

func _resolve_hurt_miss() -> void:
	_resolving_miss = true
	collected = true
	set_deferred("monitoring", false)
	Signalbus.gold_collected.emit(-1)
	var room: SpiderEncounterRoom = get_tree().current_scene as SpiderEncounterRoom
	if room != null:
		var delay: float = room.claim_heart_hit_delay()
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
	await _arc_to_heart()
	PlayerData.accept_damage(1)
	await _drop_off_screen()
	_notify_resolved()
	queue_free()

func _arc_to_heart() -> void:
	var david: Node2D = get_tree().get_first_node_in_group("david") as Node2D
	if david == null:
		return
	var hit_target: Node2D = david.get_node_or_null("DavidHitTarget") as Node2D
	if hit_target == null:
		return
	var p0: Vector2 = global_position
	var p2: Vector2 = hit_target.global_position
	var p1: Vector2 = (p0 + p2) * 0.5 + Vector2(0.0, HEART_ARC_SAG)
	var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(
		func(t: float) -> void:
			global_position = _bezier(t, p0, p1, p2),
		0.0, 1.0, HEART_ARC_TIME
	)
	await tw.finished

func _drop_off_screen() -> void:
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", position.y + OFFSCREEN_DROP_DISTANCE, OFFSCREEN_DROP_TIME)
	await tw.finished

func _advance_frame(_delta: float) -> void:
	pass

func _bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	var u: float = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

func _notify_resolved() -> void:
	var room: SpiderEncounterRoom = get_tree().current_scene as SpiderEncounterRoom
	if room != null:
		room.coin_resolved(hurts_on_miss)
