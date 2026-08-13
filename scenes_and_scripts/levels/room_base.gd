class_name RoomBase extends Node2D

const ESCAPED_SPIRIT: PackedScene = preload("uid://5j2pau7yvts4")
const DAMAGE_NUMBER: PackedScene = preload("uid://bedvoohhfbi03")
const FREE_ITEM_PANEL: PackedScene = preload("uid://ct8n40refigl7")
const SHOP_PANEL: PackedScene = preload("uid://cshoppanel1")
const SHOP_KIOSK: PackedScene = preload("uid://cshopkiosk1")
const FREE_ITEM_KIOSK: PackedScene = preload("uid://cfreekiosk01")
const KIOSK_POSITION: Vector2 = Vector2(804, 570)
const BONUS_ITEM_PANEL: PackedScene = preload("res://scenes_and_scripts/ui_menus/bonus_item_panel.tscn")

const PLAYER_HURT_TRAUMA: float = 0.8

## The play area (every world-space child of this room) tints to this while the game-over screen is up; restored on exit. Menus and HUD sit on CanvasLayers, so they stay bright.
@export var game_over_dim: Color = Color(0.35, 0.35, 0.4, 1.0)
## Seconds to fade the play area to/from the game-over dim.
@export var game_over_dim_time: float = 0.5
var _dim_tween: Tween
var _play_area_dimmed: bool = false
var _hud_tween: Tween
var _hud_hidden: bool = false
var _hud_prev_alpha: float = 1.0

const MERCY_FLASH_COLOR: Color = Color.GOLD

const CELEBRATE_STING: String = "win_longer_sting"
const CELEBRATE_FALLBACK_S: float = 3.5
const CLEAR_POP_STING: String = "win_sting"
const CLEAR_POP_FALLBACK_S: float = 1.2
const CLEAR_POP_BURSTS: int = 3
const CELEBRATE_TINT: Color = Color(1.14, 1.09, 0.92)
const CELEBRATE_ZOOM_PUNCH: float = 1.03
const MINIMAP_TIP_OFFSET: Vector2 = Vector2(0, -100)
const CELEBRATE_FX: PackedScene = preload("res://scenes_and_scripts/bricks/brick_vfx/brick_destroy_fx.tscn")
const CELEBRATE_FX_SCALE: float = 2.0
const CELEBRATE_FIELD: Rect2 = Rect2(345, 128, 1481, 704)
const CELEBRATE_FIREWORK_COLORS: Array[Color] = [
	Color("a23e8c"),
	Color("a53030"),
	Color("de9e41"),
	Color("394a50"),
	Color("75a743"),
	Color("4f8fba"),
]
var _celebrate_running: bool = false
var _room_had_bricks: bool = false

## Fairness gate: once only one live seal remains, it clears itself after a random delay.
## Encounter rooms switch it off; rooms that START with a single seal never arm it.
@export var mercy_clear_enabled: bool = true
## Random delay range in seconds between reaching one live seal and the mercy clear firing.
@export var mercy_delay_min_s: float = 10.0
@export var mercy_delay_max_s: float = 30.0
var _mercy_room_eligible: bool = false
var _mercy_timer_s: float = -1.0
var _mercy_seal: BaseSeal = null
var _mercy_pop_pending: bool = false

## Fairness gate on seal-drop enemies; encounter rooms switch it off so boss pacing stays hand-tuned.
@export var seal_enemy_cooldown_enabled: bool = true
## Seconds the drop cluster stays open after the first actual enemy spawn; drops inside it roll normally.
@export var seal_enemy_cluster_window_s: float = 3.0
## Max seal-drop enemies per cluster; reaching it closes the window early and starts the cooldown.
@export var seal_enemy_cluster_max: int = 2
## Cooldown after a cluster closes is rolled between these two values; pops during it spawn spirits instead.
@export var seal_enemy_cooldown_min_s: float = 8.0
@export var seal_enemy_cooldown_max_s: float = 15.0
var _seal_cluster_started_ms: int = -1
var _seal_cluster_count: int = 0
var _seal_cooldown_until_ms: int = -1
var _first_launch_seen: bool = false

var gold_cleared: bool = false
var bricks_cleared: bool = false
var level_clear_emitted: bool = false
var gold_in_level: int = 0
var bricks_in_level: int = 0
@onready var item_spawn_point: Marker2D = $item_spawn_point

var room_state: RoomState
var entry: RoomEntry
@onready var loot_items_data: LootItemsData
@onready var item_box: Itembox
@onready var no_respawn: Node2D = $"No-Respawn"
@onready var play_area: Control = $PlayArea
@onready var hud_ui_area: Control = $HUDLayer/UIArea
@onready var minimap: Control = $HUDLayer/UIArea/Main_UI/VBoxContainer/MinimapMargins/Minimap
@onready var play_background: ColorRect = $PlayArea/Background
@onready var flash_overlay: ColorRect = $PlayArea/FlashOverlay
@onready var misty_background: Node2D = $"PlayArea/Misty-Background"
@onready var paddle: Paddle = $Paddle



func _process(delta: float) -> void:
	_tick_mercy_timer(delta)

	
func supress_respawn_entities()->void:
	no_respawn.queue_free()	

func _enter_tree() -> void:
	var flavored: RoomEntry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	if flavored == null or flavored.content == null:
		return
	if flavored.content.floor_flavor == RoomContent.FloorFlavor.INHERIT:
		return
	GameManager.adopt_floor_flavor(flavored.content.floor_flavor)
	if not GameManager.floor_data.depression_lights_enabled:
		var canvas_modulate: CanvasModulate = get_node_or_null(^"PlayArea/CanvasModulate") as CanvasModulate
		if canvas_modulate != null:
			canvas_modulate.color = Color.WHITE

func _ready() -> void:

	visible = false
	entry = GameManager.get_current_floor_entry(GameManager.current_room_id)
	room_state = PlayerData.get_room_state(entry)
	DialogDirector.reset_clear_queue()
	if room_state.cleared:
		supress_respawn_entities()
		Signalbus.level_cleared.emit()
	_apply_floor_wall_visuals()
	await get_tree().process_frame
	visible = true
	room_state.visited = true
	bricks_in_level = get_tree().get_nodes_in_group("bricks").size()
	_room_had_bricks = bricks_in_level > 0
	_mercy_room_eligible = mercy_clear_enabled and bricks_in_level > 1 and not room_state.cleared
	Signalbus.gold_updated.emit()
	Signalbus.score_updated.emit()
	Signalbus.player_health_updated.emit()
	Signalbus.reflect_shield_changed.emit(PlayerData.get_player_shields())
	Signalbus.brick_destroyed.connect(_on_brick_destroyed)
	Signalbus.gold_collected.connect(update_gold_in_level)
	Signalbus.gold_spawned.connect(update_gold_in_level)
	Signalbus.enemy_requested.connect(_on_enemy_requested)
	Signalbus.wall_walker_removed.connect(_on_wall_walker_removed)
	Signalbus.screen_flash.connect(flash_play_area)
	Signalbus.player_damaged.connect(_on_player_damaged)
	Signalbus.game_state_game_over.connect(_dim_play_area)
	Signalbus.game_state_playing.connect(_restore_play_area)
	Signalbus.game_state_main_menu.connect(_restore_play_area)
	Signalbus.player_died.connect(_hide_hud_for_death)
	Signalbus.game_state_playing.connect(_restore_hud_after_death)
	Signalbus.game_state_main_menu.connect(_restore_hud_after_death)
	initiate_special_room()
	if entry.content.room_type == RoomContent.ROOM_TYPES.combat:
		_play_combat_entry_dialog()
	_run_cutscene_if_present()
	LoadingScreen.lower()


func _play_combat_entry_dialog() -> void:
	while LoadingScreen.is_raised():
		await get_tree().process_frame
	await get_tree().create_timer(LoadingScreen.FADE_TIME, true).timeout
	if not is_inside_tree():
		return
	await DialogDirector.play_and_wait(&"tutorial_launch", paddle)
	if not is_inside_tree():
		return
	if DialogDirector.play_at_control(&"tutorial_minimap", minimap, MINIMAP_TIP_OFFSET):
		await DialogDirector.tree_finished
	if not is_inside_tree():
		return
	DialogDirector.play(&"first_combat_room")


func _run_cutscene_if_present() -> void:
	for child: Node in get_children():
		if child.is_in_group("cutscene") and child.has_method("run"):
			child.call("run")
			if child.get("active") == true:
				GameManager.set_mouse_visible()
			return

func flash_play_area(color: Color) -> void:
	flash_overlay.color = Color(color.r, color.g, color.b, 0.0)
	var tw: Tween = create_tween()
	tw.tween_property(flash_overlay, "color:a", 0.45, 0.06)
	tw.tween_property(flash_overlay, "color:a", 0.0, 0.35)

func _dim_play_area() -> void:
	if _play_area_dimmed:
		return
	_play_area_dimmed = true
	_tween_room_modulate(game_over_dim)

func _restore_play_area() -> void:
	if not _play_area_dimmed:
		return
	_play_area_dimmed = false
	_tween_room_modulate(Color.WHITE)

func _tween_room_modulate(target: Color) -> void:
	if _dim_tween != null and _dim_tween.is_valid():
		_dim_tween.kill()
	_dim_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_dim_tween.tween_property(self, "modulate", target, game_over_dim_time)

func _hide_hud_for_death() -> void:
	if _hud_hidden:
		return
	_hud_hidden = true
	_hud_prev_alpha = hud_ui_area.modulate.a
	_tween_hud_alpha(0.0, paddle.death_zoom_time)

func _restore_hud_after_death() -> void:
	if not _hud_hidden or PlayerData.player_current_health <= 0:
		return
	_hud_hidden = false
	_tween_hud_alpha(_hud_prev_alpha, game_over_dim_time)

func _tween_hud_alpha(target: float, duration: float) -> void:
	if _hud_tween != null and _hud_tween.is_valid():
		_hud_tween.kill()
	_hud_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_hud_tween.tween_property(hud_ui_area, "modulate:a", target, duration)

func _on_player_damaged(amount: int) -> void:
	flash_play_area(Color.RED)
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam != null and cam.has_method("add_trauma"):
		cam.add_trauma(PLAYER_HURT_TRAUMA)
	SFX.play_sound("player_hurt")
	paddle.hit_feedback()
	var damage_number: DamageNumber = DAMAGE_NUMBER.instantiate()
	damage_number.position = paddle.david_global_position()
	add_child(damage_number)
	damage_number.show_damage("-" + str(amount), DamageNumber.COLOR_TAKEN)

func initiate_special_room()->void:
	if entry.content.room_type in RoomContent.AUTO_CLEAR_ROOM_TYPES:
		bricks_cleared = true
		gold_cleared = true
		check_level_cleared()
	match entry.content.room_type:
		RoomContent.ROOM_TYPES.free_item:
			_spawn_free_item_panel()
		RoomContent.ROOM_TYPES.memory:
			_init_memory_room()
		RoomContent.ROOM_TYPES.shop:
			if !room_state.loot_items_data:
				room_state.generate_item_box()
			if not room_state.loot_items_data.shop_exhausted():
				loot_items_data = room_state.loot_items_data
				_spawn_kiosk(SHOP_KIOSK, _on_shop_kiosk_activated)
		RoomContent.ROOM_TYPES.bonus_room:
			_init_bonus_room()

func _spawn_kiosk(scene: PackedScene, on_activated: Callable) -> void:
	var kiosk: RoomKiosk = scene.instantiate()
	kiosk.position = KIOSK_POSITION
	kiosk.activated.connect(on_activated.bind(kiosk))
	$PlayArea.add_child(kiosk)

func _on_shop_kiosk_activated(kiosk: RoomKiosk) -> void:
	kiosk.visible = false
	var panel: ShopPanel = SHOP_PANEL.instantiate()
	panel.z_index = 500
	panel.setup(loot_items_data)
	panel.closed.connect(_on_shop_panel_closed.bind(kiosk))
	$PlayArea.add_child(panel)

func _on_shop_panel_closed(kiosk: RoomKiosk) -> void:
	if not is_instance_valid(kiosk):
		return
	if loot_items_data.shop_exhausted():
		kiosk.queue_free()
		return
	kiosk.visible = true

func _on_free_item_kiosk_activated(kiosk: RoomKiosk) -> void:
	kiosk.visible = false
	var panel: FreeItemPanel = FREE_ITEM_PANEL.instantiate()
	panel.z_index = 500
	panel.setup(loot_items_data)
	panel.closed.connect(_on_free_item_panel_closed.bind(kiosk))
	$PlayArea.add_child(panel)

func _on_free_item_panel_closed(kiosk: RoomKiosk) -> void:
	if not is_instance_valid(kiosk):
		return
	if loot_items_data.free_pick_exhausted():
		kiosk.queue_free()
		return
	kiosk.visible = true

func _init_bonus_room() -> void:
	var content: RoomContent = entry.content
	if content.bonus_item == null:
		return
	if SaveProgression.has_memory_trophy(GameManager.current_floor):
		return
	var data: LootItemsData = LootItemsData.new()
	var single: Array[BaseItem] = [content.bonus_item]
	data.items = single
	var panel: BonusItemPanel = BONUS_ITEM_PANEL.instantiate()
	panel.z_index = 500
	panel.setup(data)
	panel.item_taken.connect(_on_bonus_item_taken)
	$PlayArea.add_child(panel)

func _on_bonus_item_taken(item: BaseItem) -> void:
	var trophy_floor: int = item.trophy_floor if item.trophy_floor > 0 else GameManager.current_floor
	SaveProgression.set_memory_trophy(trophy_floor, item.resource_path)

func _spawn_free_item_panel() -> void:
	if !room_state.loot_items_data:
		room_state.generate_item_box(entry.content.item_pool_override)
	if not room_state.loot_items_data.free_pick_exhausted():
		loot_items_data = room_state.loot_items_data
		_spawn_kiosk(FREE_ITEM_KIOSK, _on_free_item_kiosk_activated)

func _init_memory_room() -> void:
	if not PlayerData.is_memory_collected(entry.content.memory_id()):
		return
	bricks_cleared = true
	gold_cleared = true
	check_level_cleared()
	if SaveProgression.is_memory_seen(entry.content.memory_id()):
		_spawn_free_item_panel()

func _on_enemy_requested(spawn_from: Area2D) -> void: # for brick break enemies
	if _mercy_pop_pending:
		_mercy_pop_pending = false
		_spawn_escaped_spirit(spawn_from)
		return
	if _pre_first_launch():
		_spawn_escaped_spirit(spawn_from)
		return
	if _seal_drop_on_cooldown():
		_spawn_escaped_spirit(spawn_from)
		return
	var seal_break_enemies: Array[EnemyConfig] = GameManager.floor_data.seal_break_enemies
	var config: EnemyConfig = pick_seal_break_config(seal_break_enemies)

	if config and not _config_at_spawn_cap(config):
		var enemy: FallingEnemy = config.scene_ref.instantiate()
		enemy.add_to_group(_spawn_cap_group(config))
		spawn_from.get_parent().add_child(enemy)
		enemy.position = spawn_from.position
		_register_seal_drop_spawn()
	else:#freed-spirit
		_spawn_escaped_spirit(spawn_from)

func _spawn_escaped_spirit(spawn_from: Area2D) -> void:
	var spirit: Node2D = ESCAPED_SPIRIT.instantiate()
	spirit.position = spawn_from.position
	spawn_from.get_parent().add_child(spirit)
	DialogDirector.play_on_clear(&"freed_spirit")

func _pre_first_launch() -> bool:
	if _first_launch_seen:
		return false
	var ball: Ball = get_tree().get_first_node_in_group("ball") as Ball
	if ball == null or not ball.on_paddle:
		_first_launch_seen = true
		return false
	return true

func _seal_drop_on_cooldown() -> bool:
	if not seal_enemy_cooldown_enabled:
		return false
	var now: int = Time.get_ticks_msec()
	_close_seal_cluster_if_expired(now)
	return now < _seal_cooldown_until_ms

func _register_seal_drop_spawn() -> void:
	if not seal_enemy_cooldown_enabled:
		return
	if _seal_cluster_started_ms < 0:
		_seal_cluster_started_ms = Time.get_ticks_msec()
		_seal_cluster_count = 0
	_seal_cluster_count += 1
	if _seal_cluster_count >= seal_enemy_cluster_max:
		_close_seal_cluster(Time.get_ticks_msec())

func _close_seal_cluster_if_expired(now: int) -> void:
	if _seal_cluster_started_ms < 0:
		return
	var close_ms: int = _seal_cluster_started_ms + int(seal_enemy_cluster_window_s * 1000.0)
	if now >= close_ms:
		_close_seal_cluster(close_ms)

func _close_seal_cluster(close_ms: int) -> void:
	_seal_cluster_started_ms = -1
	_seal_cluster_count = 0
	_seal_cooldown_until_ms = close_ms + int(randf_range(seal_enemy_cooldown_min_s, seal_enemy_cooldown_max_s) * 1000.0)

func pick_seal_break_config(enemy_configs: Array[EnemyConfig]) -> EnemyConfig: #for brick break enemies
	var mult: float = SettingsManager.difficulty_mult()
	var index: int = 0
	var spawned_percentage: float = randf() * 100
	while (index < enemy_configs.size()):
		var spawn_configuration: EnemyConfig = enemy_configs[index]
		var chance: float = spawn_configuration.spawn_chance * mult
		if (spawned_percentage < chance):
			return spawn_configuration
		else:
			spawned_percentage -= chance
			index += 1
	return null

func _config_at_spawn_cap(config: EnemyConfig) -> bool:
	if config.max_global_spawn <= 0:
		return false
	var cap: int = roundi(config.max_global_spawn * SettingsManager.difficulty_mult())
	return get_tree().get_nodes_in_group(_spawn_cap_group(config)).size() >= cap

func _spawn_cap_group(config: EnemyConfig) -> StringName:
	return StringName("seal_break_enemy_" + config.enemy_name)

func check_level_cleared() -> void: #let gamemanager know level is cleared
	if level_clear_emitted:
		return
	if PlayerData.player_current_health <= 0:
		return
	var max_clear:int = GameManager.get_current_floor_entry(GameManager.current_room_id).content.max_clears
	if gold_cleared && bricks_cleared && _no_walker_holds_gold():
		level_clear_emitted = true
		Signalbus.level_cleared.emit()
		if _room_had_bricks and entry.content.room_type == RoomContent.ROOM_TYPES.combat:
			_play_clear_pop()
		room_state.clear_count +=1
		if entry.content.max_clears == -1: return
		if room_state.clear_count >= max_clear: room_state.cleared = true

func _play_room_celebrate() -> void:
	if _celebrate_running:
		return
	_celebrate_running = true
	var duration: float = CELEBRATE_FALLBACK_S
	if SFX.sound_dict.has(CELEBRATE_STING):
		var sting: AudioStreamPlayer = SFX.play_sound(CELEBRATE_STING)
		if sting != null and sting.stream != null:
			duration = maxf(sting.stream.get_length(), 1.0)
	flash_play_area(Color.GOLD)
	_celebrate_camera_punch()
	_celebrate_confetti(duration, clampi(roundi(duration * 4.0), 6, 24))
	_celebrate_paddle_bows()
	var pulse: Tween = _celebrate_pulse(duration)
	await get_tree().create_timer(duration, false).timeout
	if pulse != null and pulse.is_valid():
		pulse.kill()
	if not _play_area_dimmed:
		modulate = Color.WHITE
	_celebrate_running = false

func _celebrate_pulse(duration: float) -> Tween:
	if _play_area_dimmed:
		return null
	var tw: Tween = create_tween().set_loops(maxi(1, floori(duration / 0.9)))
	tw.tween_property(self, "modulate", CELEBRATE_TINT, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw

func _celebrate_camera_punch() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var base_zoom: Vector2 = cam.zoom
	var tw: Tween = create_tween()
	tw.tween_property(cam, "zoom", base_zoom * CELEBRATE_ZOOM_PUNCH, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "zoom", base_zoom, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_clear_pop() -> void:
	if _celebrate_running:
		return
	_celebrate_running = true
	var duration: float = CLEAR_POP_FALLBACK_S
	if SFX.sound_dict.has(CLEAR_POP_STING):
		var sting: AudioStreamPlayer = SFX.play_sound(CLEAR_POP_STING)
		if sting != null and sting.stream != null:
			duration = maxf(sting.stream.get_length(), 0.6)
	flash_play_area(Color.GOLD)
	_celebrate_confetti(duration, CLEAR_POP_BURSTS)
	await get_tree().create_timer(duration, false).timeout
	_celebrate_running = false

func _celebrate_confetti(duration: float, bursts: int) -> void:
	var burst_times: Array[float] = []
	for i: int in bursts:
		burst_times.append(randf_range(0.15, duration * 0.92))
	burst_times.sort()
	var tw: Tween = create_tween()
	var last_time: float = 0.0
	for burst_time: float in burst_times:
		tw.tween_interval(maxf(burst_time - last_time, 0.01))
		tw.tween_callback(_spawn_celebrate_burst)
		last_time = burst_time

func _spawn_celebrate_burst() -> void:
	var fx: Node2D = CELEBRATE_FX.instantiate()
	fx.scale = Vector2.ONE * CELEBRATE_FX_SCALE
	fx.modulate = CELEBRATE_FIREWORK_COLORS.pick_random()
	fx.position = Vector2(
		randf_range(CELEBRATE_FIELD.position.x, CELEBRATE_FIELD.end.x),
		randf_range(CELEBRATE_FIELD.position.y, CELEBRATE_FIELD.end.y))
	add_child(fx)
	SFX.play_sound("hit-brick")

func _celebrate_paddle_bows() -> void:
	var tw: Tween = create_tween()
	for i: int in 3:
		tw.tween_interval(0.5)
		tw.tween_callback(paddle.bounce_dip)

func _no_walker_holds_gold() -> bool:
	for node: Node in get_tree().get_nodes_in_group("wall_walkers"):
		var walker: WallWalker = node as WallWalker
		if walker == null or walker.is_queued_for_deletion():
			continue
		if walker.holds_player_gold():
			return false
	return true

func _on_wall_walker_removed(_walker: Node2D) -> void:
	check_level_cleared()

func update_gold_in_level(amount: int) -> void:
	gold_in_level += amount
	if gold_in_level <= 0:
		gold_cleared = true
		check_level_cleared()
	else:
		gold_cleared = false

func _on_brick_destroyed() -> void:
	bricks_in_level -= 1
	if bricks_in_level <= 0:
		bricks_cleared = true
		check_level_cleared()
	_update_mercy_state.call_deferred()

func _update_mercy_state() -> void:
	if not _mercy_room_eligible or level_clear_emitted:
		_disarm_mercy()
		return
	var live: Array[BaseSeal] = _get_live_seals()
	if live.size() != 1:
		_disarm_mercy()
		return
	if _mercy_timer_s < 0.0 or _mercy_seal != live[0]:
		_mercy_seal = live[0]
		_mercy_timer_s = randf_range(mercy_delay_min_s, mercy_delay_max_s)

func _tick_mercy_timer(delta: float) -> void:
	if _mercy_timer_s < 0.0:
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	_mercy_timer_s -= delta
	if _mercy_timer_s <= 0.0:
		_fire_mercy_clear()

func _fire_mercy_clear() -> void:
	var seal: BaseSeal = _mercy_seal
	_disarm_mercy()
	if level_clear_emitted or not is_instance_valid(seal) or seal.dying:
		return
	var live: Array[BaseSeal] = _get_live_seals()
	if live.size() != 1 or live[0] != seal:
		return
	DialogDirector.play_on_clear(&"last_seal_mercy")
	flash_play_area(MERCY_FLASH_COLOR)
	_mercy_pop_pending = true
	seal.force_clear()

func _get_live_seals() -> Array[BaseSeal]:
	var live: Array[BaseSeal] = []
	for node: Node in get_tree().get_nodes_in_group("bricks"):
		var seal: BaseSeal = node as BaseSeal
		if seal != null and is_instance_valid(seal) and not seal.dying:
			live.append(seal)
	return live

func _disarm_mercy() -> void:
	_mercy_timer_s = -1.0
	_mercy_seal = null

func _apply_floor_wall_visuals() -> void:
	var fd: FloorData = GameManager.floor_data
	if fd == null:
		return
	# local RNG seeded by room id so jitter/flip stay stable across re-entries
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(GameManager.current_room_id)
	var base_tint: Color = fd.wall_modulate
	base_tint.a *= fd.wall_alpha
	for wall: Node in get_tree().get_nodes_in_group("walls"):
		for child: Node in wall.find_children("*", "", true, false):
			var tex_rect: TextureRect = child as TextureRect
			var sprite: Sprite2D = child as Sprite2D
			if tex_rect != null:
				if tex_rect.texture == null:
					continue
				# avoid overriding door sprite
				if tex_rect.size == Vector2(128, 64):
					continue
			elif sprite != null:
				if sprite.texture == null:
					continue
			else:
				continue
			var item: CanvasItem = child as CanvasItem
			if fd.wall_texture != null:
				if tex_rect != null:
					tex_rect.texture = fd.wall_texture
				else:
					sprite.texture = fd.wall_texture
			item.self_modulate = _jittered(base_tint, fd.wall_brightness_jitter, rng)
			item.texture_filter = fd.wall_texture_filter
			if fd.wall_random_flip:
				var flip_h: bool = rng.randi() % 2 == 0
				var flip_v: bool = rng.randi() % 2 == 0
				if tex_rect != null:
					tex_rect.flip_h = flip_h
					tex_rect.flip_v = flip_v
				else:
					sprite.flip_h = flip_h
					sprite.flip_v = flip_v
	play_background.color = fd.background_color
	misty_background.visible = fd.misty_background_enabled
	for child: Node in misty_background.get_children():
		var particles: CPUParticles2D = child as CPUParticles2D
		if particles != null:
			particles.emitting = fd.misty_background_enabled

func _jittered(base: Color, amount: float, rng: RandomNumberGenerator) -> Color:
	if amount <= 0.0:
		return base
	var j: float = rng.randf_range(-amount, amount)
	return Color(clampf(base.r + j, 0.0, 1.0), clampf(base.g + j, 0.0, 1.0), clampf(base.b + j, 0.0, 1.0), base.a)
