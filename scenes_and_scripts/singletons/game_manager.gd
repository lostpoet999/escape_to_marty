extends Node

#scene references
const MAIN_MENU: PackedScene = preload("uid://djuj72c4lcukn")
const CREDITS_SCENE: PackedScene = preload("res://scenes_and_scripts/ui_main_menu/credits_scene.tscn")
const RETRY_ROOM: PackedScene = preload("res://scenes_and_scripts/levels/common_rooms/retry_room/retry_room.tscn")
const RETRY_ROOM_COORDS: Vector2i = Vector2i(99, 99)
const ALCOVE_ROOM: PackedScene = preload("res://scenes_and_scripts/levels/common_rooms/powerup_1.tscn")
const CARDINAL_OFFSETS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]

#floor references — add floors by editing floor_registry.tres in the inspector
const FLOOR_REGISTRY: FloorRegistry = preload("res://scenes_and_scripts/levels/floor_registry.tres")
var current_floor:int = 1
var floor_data: FloorData
var room_data_for_floor: Dictionary = {}
var scene_ref: PackedScene
var current_room_id: String
var test_floor_active: bool = false
var standalone_room_active: bool = false
var last_run_summary: Dictionary = {}

enum GameState {
	MAIN_MENU = 0,
	BALL_ON_PADDLE = 1,
	PLAYING = 2,
	PAUSED = 3,
	GAME_OVER = 4,
	CLICK_MODE = 5,
	LEVEL_CLEARED = 6,
	SPECIAL_ROOM = 7,
	DEBUG_PANEL = 8,
	} 
enum PhaseType {
	DENIAL = 0,
	ANGER = 1,
	BARGAINING = 2,
	DEPRESSION = 3,
	ACCEPTANCE = 4,
	HEALTH = 5,
	}
var current_state: GameState = GameState.MAIN_MENU
var _unpaused_state: GameState
var _web_build: bool = OS.has_feature("web")
var _pointer_lock_seen: bool = false

#const node group constants
const DEATH_WALLS: String = "DeathWalls"
const BRICKS: String = "Brick"
const PADDLE: String = "paddle"
const SURRENDER: String = "surrender"

var time_scale_modifier: float = 1.0
var _time_scale_base: float = 1.0

func set_time_scale_base(base: float) -> void:
	_time_scale_base = base
	apply_time_scale()

func set_time_scale_modifier(modifier: float) -> void:
	time_scale_modifier = modifier
	apply_time_scale()

func apply_time_scale() -> void:
	Engine.time_scale = _time_scale_base * SettingsManager.game_speed * time_scale_modifier

func surrender_active() -> bool:
	return get_tree().get_first_node_in_group(SURRENDER) != null

func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")) and current_state != GameState.MAIN_MENU:
		if current_state != GameState.PAUSED:
			request_pause()
		else:
			resume_from_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		request_pause()


func _input(event: InputEvent) -> void:
	if not _web_build:
		return
	if current_state not in [GameState.BALL_ON_PADDLE, GameState.PLAYING]:
		return
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta: float) -> void:
	_watch_pointer_lock()


func request_pause() -> void:
	if current_state in [GameState.MAIN_MENU, GameState.PAUSED]: return
	var prior_state: GameState = current_state
	if change_state(GameState.PAUSED):
		_unpaused_state = prior_state


func _watch_pointer_lock() -> void:
	if not _web_build: return
	if current_state not in [GameState.BALL_ON_PADDLE, GameState.PLAYING, GameState.CLICK_MODE]:
		_pointer_lock_seen = false
		return
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_pointer_lock_seen = true
	elif _pointer_lock_seen:
		# browsers only re-grant pointer lock on a click, so only pause on losing a grab we saw succeed
		_pointer_lock_seen = false
		request_pause()


func resume_from_pause() -> void:
	if current_state == GameState.PAUSED:
		change_state(_unpaused_state)

#region gamestate functions
func change_state(to_state: GameState) -> bool:
	if DialogDirector.focused_active: return false
	if not is_valid_state_transition(current_state, to_state): return false
	exit_state(current_state)
	enter_state(to_state)
	return true
	
func get_floor_data()->void:
	room_data_for_floor.clear()
	var open_slots: Array[RoomEntry] = []
	for slot: RoomEntry in floor_data.room_entries:
		if slot.is_static:
			room_data_for_floor[RoomEntry.make_key(slot.room_coords)] = slot
		else:
			open_slots.append(slot)
	_assign_pooled_content(open_slots)
	_apply_trophy_alcove()

func _assign_pooled_content(open_slots: Array[RoomEntry]) -> void:
	var assignment: Array[RoomContent] = []
	var filler: Array[RoomContent] = []
	for content: RoomContent in floor_data.room_pool:
		if content.required:
			assignment.append(content)
		else:
			filler.append(content)
	filler.shuffle()
	var filler_needed: int = open_slots.size() - assignment.size()
	for i: int in range(mini(filler_needed, filler.size())):
		assignment.append(filler[i])
	if assignment.size() < open_slots.size():
		push_warning("floor pool under-supplies slots: %d content for %d open slots" % [assignment.size(), open_slots.size()])
	open_slots.shuffle()
	for i: int in range(mini(open_slots.size(), assignment.size())):
		var resolved: RoomEntry = open_slots[i].duplicate()
		resolved.content = assignment[i]
		room_data_for_floor[RoomEntry.make_key(resolved.room_coords)] = resolved

func _apply_trophy_alcove() -> void:
	if not _alcove_mode_active():
		return
	_seal_memory_doors()
	_inject_alcove()

func _alcove_mode_active() -> bool:
	if not SaveProgression.has_memory_trophy(current_floor):
		return false
	var found_memory: bool = false
	for key: String in room_data_for_floor:
		var entry: RoomEntry = room_data_for_floor[key]
		if entry.content == null or entry.content.room_type != RoomContent.ROOM_TYPES.memory:
			continue
		if entry.content.memory_tree == null:
			continue
		found_memory = true
		if not SaveProgression.is_memory_seen(entry.content.memory_id()):
			return false
	return found_memory

func _seal_memory_doors() -> void:
	for key: String in room_data_for_floor.keys():
		var entry: RoomEntry = room_data_for_floor[key]
		if entry.content == null or entry.content.room_type != RoomContent.ROOM_TYPES.memory:
			continue
		var sealed: RoomEntry = entry.duplicate()
		for offset: Vector2i in CARDINAL_OFFSETS:
			sealed.set_door(offset, false)
		room_data_for_floor[key] = sealed
		for offset: Vector2i in CARDINAL_OFFSETS:
			var neighbor_key: String = RoomEntry.make_key(entry.room_coords + offset)
			if not room_data_for_floor.has(neighbor_key):
				continue
			var neighbor: RoomEntry = room_data_for_floor[neighbor_key]
			if not neighbor.has_door(-offset):
				continue
			var cut: RoomEntry = neighbor.duplicate()
			cut.set_door(-offset, false)
			room_data_for_floor[neighbor_key] = cut

func _inject_alcove() -> void:
	var pick: Dictionary = PlayerData.hidden_alcove_picks.get(current_floor, {})
	if pick.is_empty() or not _alcove_pick_valid(pick):
		pick = _roll_alcove_pick()
		if pick.is_empty():
			return
		PlayerData.hidden_alcove_picks[current_floor] = pick
	var host: Vector2i = pick["host"]
	var cell: Vector2i = pick["cell"]
	var content: RoomContent = RoomContent.new()
	content.room_scene = ALCOVE_ROOM
	content.room_type = RoomContent.ROOM_TYPES.free_item
	content.is_secret = true
	var entry: RoomEntry = RoomEntry.new()
	entry.room_coords = cell
	entry.content = content
	entry.set_door(host - cell, true)
	room_data_for_floor[RoomEntry.make_key(cell)] = entry

func _alcove_pick_valid(pick: Dictionary) -> bool:
	var host: Vector2i = pick["host"]
	var cell: Vector2i = pick["cell"]
	if cell - host not in CARDINAL_OFFSETS:
		return false
	var host_key: String = RoomEntry.make_key(host)
	if not room_data_for_floor.has(host_key):
		return false
	var host_entry: RoomEntry = room_data_for_floor[host_key]
	if host_entry.content == null or host_entry.content.room_type != RoomContent.ROOM_TYPES.combat:
		return false
	return not room_data_for_floor.has(RoomEntry.make_key(cell))

func _roll_alcove_pick() -> Dictionary:
	var hosts: Array[RoomEntry] = []
	for key: String in room_data_for_floor:
		var entry: RoomEntry = room_data_for_floor[key]
		if entry.content == null or entry.content.room_type != RoomContent.ROOM_TYPES.combat:
			continue
		if not _open_cells_beside(entry.room_coords).is_empty():
			hosts.append(entry)
	if hosts.is_empty():
		return {}
	var host: RoomEntry = hosts.pick_random()
	var cells: Array[Vector2i] = _open_cells_beside(host.room_coords)
	var cell: Vector2i = cells.pick_random()
	return {"host": host.room_coords, "cell": cell}

func _open_cells_beside(coords: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset: Vector2i in CARDINAL_OFFSETS:
		var cell: Vector2i = coords + offset
		if cell.x < 1 or cell.x > floor_data.grid_size.x:
			continue
		if cell.y < 1 or cell.y > floor_data.grid_size.y:
			continue
		if room_data_for_floor.has(RoomEntry.make_key(cell)):
			continue
		cells.append(cell)
	return cells

func grant_memory_trophies() -> void:
	if PlayerData.inventory == null:
		return
	for floor_index: int in range(1, FLOOR_REGISTRY.floors.size() + 1):
		var path: String = SaveProgression.memory_trophy_path(floor_index)
		if path == "":
			continue
		var item: Resource = load(path)
		if item is BaseItem and not PlayerData.inventory.items.has(item) and not PlayerData.inventory.core_items.has(item):
			PlayerData.inventory.add_item(item)

func memories_complete_for_current_floor() -> bool:
	var found_memory: bool = false
	for key: String in room_data_for_floor:
		var entry: RoomEntry = room_data_for_floor[key]
		if entry.content == null or entry.content.room_type != RoomContent.ROOM_TYPES.memory:
			continue
		found_memory = true
		if not PlayerData.is_memory_collected(entry.content.memory_id()):
			return false
	return found_memory

func floor_memories_outstanding() -> bool:
	for key: String in room_data_for_floor:
		var entry: RoomEntry = room_data_for_floor[key]
		if entry.content == null or entry.content.room_type != RoomContent.ROOM_TYPES.memory:
			continue
		if entry.content.memory_tree == null:
			continue
		if not PlayerData.is_memory_collected(entry.content.memory_id()):
			return true
	return false

func _find_starting_slot() -> RoomEntry:
	for room: RoomEntry in floor_data.room_entries:
		if room.content != null and room.content.room_type == RoomContent.ROOM_TYPES.starting_room:
			return room
	return floor_data.room_entries[0]

func get_current_floor_entry(key: String)->RoomEntry:
	return room_data_for_floor[key]

func is_valid_state_transition(from_state: GameState, to_state: GameState) -> bool:
	if current_state == to_state: return false
	match from_state:
		GameState.MAIN_MENU:
			return to_state in [GameState.BALL_ON_PADDLE, GameState.SPECIAL_ROOM, GameState.DEBUG_PANEL]
		GameState.BALL_ON_PADDLE:
			return to_state in [GameState.PLAYING, GameState.PAUSED, GameState.LEVEL_CLEARED, GameState.SPECIAL_ROOM,GameState.DEBUG_PANEL, GameState.GAME_OVER]
		GameState.PLAYING:
			return to_state in [GameState.PAUSED, GameState.GAME_OVER, GameState.MAIN_MENU, GameState.CLICK_MODE, GameState.LEVEL_CLEARED, GameState.SPECIAL_ROOM, GameState.DEBUG_PANEL, GameState.BALL_ON_PADDLE]
		GameState.PAUSED:
			return to_state in [GameState.PLAYING, GameState.BALL_ON_PADDLE, GameState.MAIN_MENU, GameState.LEVEL_CLEARED, GameState.SPECIAL_ROOM, GameState.CLICK_MODE]
		GameState.GAME_OVER:
			return to_state in [GameState.MAIN_MENU, GameState.PLAYING, GameState.BALL_ON_PADDLE, GameState.SPECIAL_ROOM]
		GameState.CLICK_MODE:
			return to_state in [GameState.PLAYING, GameState.LEVEL_CLEARED,GameState.DEBUG_PANEL, GameState.BALL_ON_PADDLE, GameState.GAME_OVER, GameState.MAIN_MENU, GameState.PAUSED]
		GameState.LEVEL_CLEARED:
			return to_state  in [GameState.BALL_ON_PADDLE, GameState.SPECIAL_ROOM,GameState.DEBUG_PANEL, GameState.MAIN_MENU, GameState.GAME_OVER, GameState.PAUSED]
		GameState.SPECIAL_ROOM:
			return to_state in [GameState.BALL_ON_PADDLE, GameState.PLAYING,GameState.DEBUG_PANEL, GameState.PAUSED]
		GameState.DEBUG_PANEL:
			return to_state in [GameState.BALL_ON_PADDLE, GameState.PLAYING, GameState.LEVEL_CLEARED, GameState.SPECIAL_ROOM, GameState.MAIN_MENU, GameState.CLICK_MODE]
			
	assert(false, "No valid transitions defined for from_state: %s" % GameState.keys()[from_state])
	return false

func set_mouse_visible() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("document.exitPointerLock();")

func enter_state(change_to_state: GameState) -> void: 
	#note that a big part of gamemanager and the game state is managing when mouse if visible or not. 
	#centralizing that here so its easy to spot/fix where mouse mode is not correct for current gam
	current_state = change_to_state
	match current_state:
		GameState.MAIN_MENU:
			set_mouse_visible()
			current_floor = 1
			start_floor()
			Signalbus.game_state_main_menu.emit()
		GameState.BALL_ON_PADDLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Signalbus.game_state_playing.emit()
		GameState.PLAYING:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Signalbus.game_state_playing.emit()
		GameState.PAUSED:
			set_mouse_visible()
			Signalbus.game_state_pause_changed.emit(true)
			pause_game()
		GameState.GAME_OVER:
			set_mouse_visible()
			Signalbus.game_state_game_over.emit()
			pause_game()
		GameState.CLICK_MODE:
			set_time_scale_base(0.5)
			Signalbus.game_state_click_mode.emit()
		GameState.LEVEL_CLEARED:
			Signalbus.game_state_click_mode.emit()
		GameState.SPECIAL_ROOM:
			Signalbus.game_state_special_room.emit()
		GameState.DEBUG_PANEL:
			set_mouse_visible()
			pause_game()


func exit_state(close_state: GameState) -> void:
	match close_state: #clean-up/init
		GameState.MAIN_MENU:
			init_all_game_stats()
		GameState.PLAYING:
			pass
		GameState.PAUSED:
			unpause_game()
			Signalbus.game_state_pause_changed.emit(false)
		GameState.GAME_OVER:
			unpause_game()
		GameState.DEBUG_PANEL:			
			unpause_game()
		GameState.CLICK_MODE:
			set_time_scale_base(1.0)

func pause_game() -> void:
	get_tree().paused = true

func unpause_game() -> void:
	get_tree().paused = false

#endregionrent_entr

func restart_level() -> void:
	PlayerData.initialize_player_data()
	get_tree().reload_current_scene()

func start_floor(reset_player_data: bool = true) -> void:
	var fd_variant: Variant = FLOOR_REGISTRY.floors[current_floor - 1]
	start_floor_with_data(fd_variant, reset_player_data)

func adopt_floor_flavor(floor_index: int) -> void:
	var idx: int = clampi(floor_index, 1, FLOOR_REGISTRY.floors.size())
	var fd_variant: Variant = FLOOR_REGISTRY.floors[idx - 1]
	floor_data = fd_variant

func start_standalone_room(floor_flavor: int, standalone_entry: RoomEntry) -> void:
	standalone_room_active = true
	current_floor = clampi(floor_flavor, 1, FLOOR_REGISTRY.floors.size())
	var fd_variant: Variant = FLOOR_REGISTRY.floors[current_floor - 1]
	floor_data = fd_variant
	room_data_for_floor.clear()
	current_room_id = RoomEntry.make_key(standalone_entry.room_coords)
	room_data_for_floor[current_room_id] = standalone_entry

func start_floor_with_data(data: FloorData, reset_player_data: bool = true) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	floor_data = data
	test_floor_active = data.floor_name_id == "TEST"
	if reset_player_data:
		PlayerData.initialize_player_data()
	else:
		PlayerData.room_state.clear()
	get_floor_data()
	var start_slot: RoomEntry = _find_starting_slot()
	current_room_id = RoomEntry.make_key(start_slot.room_coords)
	scene_ref = start_slot.content.room_scene
	_configure_frame_rate()
	

func _ready() -> void:
	Signalbus.player_died.connect(_cancel_click_mode_on_death)
	Signalbus.death_sequence_finished.connect(_load_level_on_player_death)
	Signalbus.level_cleared.connect(set_state_to_cleared)
	Signalbus.floor_cleared.connect(floor_cleared)
	DP.track("Game State", DP, "old_state", GameState)
	DP.track("Current Room:", self, "current_room_id")
	if standalone_room_active:
		process_mode = Node.PROCESS_MODE_ALWAYS
		PlayerData.initialize_player_data()
		_configure_frame_rate()
		MusicPlayer.play_song(floor_data.music, floor_data.music_volume_db)
	else:
		start_floor()
	
func floor_cleared()->void:
	if standalone_room_active:
		restart_level()
		return
	if test_floor_active:
		_return_to_test_room()
		return
	if current_floor >= FLOOR_REGISTRY.floors.size():
		win_game()
		return
	current_floor += 1
	start_floor(false)
	write_run_checkpoint()
	load_current_room()

func _return_to_test_room() -> void:
	var here: RoomEntry = room_data_for_floor[current_room_id]
	var below_key: String = RoomEntry.make_key(here.room_coords + Vector2i(0, 1))
	if not room_data_for_floor.has(below_key):
		push_warning("test floor: no room below %s to return to" % current_room_id)
		return
	PlayerData.room_state.erase(current_room_id)
	var target: RoomEntry = room_data_for_floor[below_key]
	current_room_id = below_key
	scene_ref = target.content.room_scene
	change_state(GameState.BALL_ON_PADDLE)
	get_tree().change_scene_to_packed(scene_ref)

func win_game()->void:
	last_run_summary = PlayerData.build_run_summary(true)
	SaveProgression.record_run_score(PlayerData.difficulty_tier_name(), PlayerData.get_player_score())
	SaveProgression.record_run_clear(PlayerData.difficulty_tier_name())
	SaveProgression.clear_run_checkpoint()
	change_state(GameState.MAIN_MENU)
	load_scene(CREDITS_SCENE)

func write_run_checkpoint() -> void:
	SaveProgression.save_run_checkpoint(current_floor, PlayerData.build_checkpoint())

func mark_cutscene_seen(cutscene_id: StringName) -> void:
	if not PlayerData.seen_cutscenes.has(cutscene_id):
		PlayerData.seen_cutscenes.append(cutscene_id)
	if standalone_room_active or test_floor_active:
		return
	write_run_checkpoint()

func retry_floor() -> void:
	if not change_state(GameState.BALL_ON_PADDLE):
		return
	var player_state: Dictionary = SaveProgression.run_checkpoint_player()
	if SaveProgression.has_run_checkpoint() and not player_state.is_empty():
		PlayerData.restore_checkpoint(player_state)
	PlayerData.resnapshot_difficulty()
	PlayerData.retry_counts[current_floor] = PlayerData.retry_counts.get(current_floor, 0) + 1
	PlayerData.refresh_for_retry()
	start_floor(false)
	var content: RoomContent = RoomContent.new()
	content.room_type = RoomContent.ROOM_TYPES.free_item
	content.room_scene = RETRY_ROOM
	var entry: RoomEntry = RoomEntry.new()
	entry.room_coords = RETRY_ROOM_COORDS
	entry.content = content
	room_data_for_floor[RoomEntry.make_key(RETRY_ROOM_COORDS)] = entry
	current_room_id = RoomEntry.make_key(RETRY_ROOM_COORDS)
	load_scene(RETRY_ROOM)

func retry_floor_easier() -> void:
	SettingsManager.apply_tier(SettingsManager.tier_index() - 1)
	SettingsManager.save_settings()
	retry_floor()

func exit_retry_room() -> void:
	if not change_state(GameState.BALL_ON_PADDLE):
		return
	var key: String = RoomEntry.make_key(RETRY_ROOM_COORDS)
	room_data_for_floor.erase(key)
	PlayerData.room_state.erase(key)
	var start_slot: RoomEntry = _find_starting_slot()
	current_room_id = RoomEntry.make_key(start_slot.room_coords)
	scene_ref = start_slot.content.room_scene
	load_current_room()

func restart_run() -> void:
	if not change_state(GameState.BALL_ON_PADDLE):
		return
	current_floor = 1
	last_run_summary = {}
	start_floor()
	write_run_checkpoint()
	load_current_room()

func continue_run() -> void:
	if not SaveProgression.has_run_checkpoint():
		return
	var player_state: Dictionary = SaveProgression.run_checkpoint_player()
	if player_state.is_empty():
		return
	if not change_state(GameState.BALL_ON_PADDLE):
		return
	current_floor = clampi(SaveProgression.run_checkpoint_floor(), 1, FLOOR_REGISTRY.floors.size())
	PlayerData.restore_checkpoint(player_state)
	PlayerData.resnapshot_difficulty()
	grant_memory_trophies()
	last_run_summary = {}
	start_floor(false)
	load_current_room()

func _configure_frame_rate() -> void:
	if OS.has_feature("web"):
		Engine.max_fps = 60
		Engine.physics_ticks_per_second = 60
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var refresh_rate: float = DisplayServer.screen_get_refresh_rate()
	if refresh_rate <= 0:
		refresh_rate = 60.0

	Engine.max_fps = int(minf(refresh_rate * 2.0, 300.0))
	

func init_all_game_stats() -> void:
	PlayerData.initialize_player_data()
	

func load_scene(scene: PackedScene) -> void:
	scene_ref = scene
	get_tree().change_scene_to_packed(scene)
	
func load_current_room()-> void:
	LoadingScreen.raise()
	MusicPlayer.play_song(floor_data.music, floor_data.music_volume_db)
	get_tree().change_scene_to_packed(scene_ref)

func _cancel_click_mode_on_death() -> void:
	if current_state == GameState.CLICK_MODE:
		change_state(GameState.PLAYING)

func _load_level_on_player_death() -> void:
	GameManager.change_state(GameState.GAME_OVER)

func set_state_to_cleared() -> void:	
	change_state(GameState.LEVEL_CLEARED)
