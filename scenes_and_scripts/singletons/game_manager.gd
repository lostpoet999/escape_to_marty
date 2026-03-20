extends Node

#scene references
const MAIN_MENU: PackedScene = preload("uid://djuj72c4lcukn")
const LEVEL_01: PackedScene = preload("uid://bea1h3570swpu")

#floor references
var current_floor:int = 1
var floor_data: FloorData
var room_data_for_floor: Dictionary = {}
var scene_ref: PackedScene
var current_room_id: String
var floor_ref: Dictionary = {
	1: "uid://dr8vct1f7lm5n"
}

enum GameState {MAIN_MENU, BALL_ON_PADDLE, PLAYING, PAUSED, GAME_OVER, CLICK_MODE, LEVEL_CLEARED} 
enum PhaseType {DENIAL, ANGER, BARGAINING, DEPRESSION, ACCEPTANCE, HEALTH}
var current_state: GameState = GameState.MAIN_MENU

#const node group constants
const DEATH_WALLS: String = "DeathWalls"
const BRICKS: String = "Brick"
const PADDLE: String = "paddle"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and current_state != GameState.MAIN_MENU:
		if current_state != GameState.PAUSED:
			change_state(GameState.PAUSED)
		else:
			change_state(GameState.PLAYING)			
	if event.is_action_pressed("click_mode_toggle") and current_state != GameState.MAIN_MENU:
		if current_state != GameState.CLICK_MODE:
			change_state(GameState.CLICK_MODE)
		elif current_state == GameState.CLICK_MODE:
			change_state(GameState.PLAYING)
	floor_data = ResourceLoader.load(str(floor_ref[current_floor])) as FloorData #floor one from main-menu

#region gamestate functions
func change_state(to_state: GameState) -> void:
	if not is_valid_state_transition(current_state, to_state): return
	exit_state(current_state)
	enter_state(to_state)
	
func get_floor_data()->void:
	for room: RoomEntry in floor_data.room_entries:
		room_data_for_floor[room.room_name_id] = room

func is_valid_state_transition(from_state: GameState, to_state: GameState) -> bool:
	if current_state == to_state: return false
	match from_state:
		GameState.MAIN_MENU:
			return to_state in [GameState.BALL_ON_PADDLE]
		GameState.BALL_ON_PADDLE:
			return to_state in [GameState.PLAYING, GameState.PAUSED, GameState.LEVEL_CLEARED]
		GameState.PLAYING:
			return to_state in [GameState.PAUSED, GameState.GAME_OVER, GameState.MAIN_MENU, GameState.CLICK_MODE, GameState.LEVEL_CLEARED]
		GameState.PAUSED:
			return to_state in [GameState.PLAYING, GameState.BALL_ON_PADDLE]
		GameState.GAME_OVER:
			return to_state in [GameState.MAIN_MENU, GameState.PLAYING]
		GameState.CLICK_MODE:
			return to_state in [GameState.PLAYING, GameState.LEVEL_CLEARED]
		GameState.LEVEL_CLEARED:
			return to_state  in [GameState.BALL_ON_PADDLE]
	return false

func enter_state(change_to_state: GameState) -> void: 
	#note that a big part of gamemanager and the game state is managing when mouse if visible or not. 
	#centralizing that here so its easy to spot/fix where mouse mode is not correct for current gam
	current_state = change_to_state
	match current_state:
		GameState.MAIN_MENU:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			current_room_id = floor_data.starting_room_id
			scene_ref = floor_data.starting_room_scene
			Signalbus.game_state_main_menu.emit()			
		GameState.BALL_ON_PADDLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		GameState.PLAYING:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			Signalbus.game_state_playing.emit()
		GameState.PAUSED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Signalbus.game_state_paused.emit()
			pause_game()
		GameState.GAME_OVER:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Signalbus.game_state_game_over.emit()
			pause_game()
			#GameManager.change_state(GameState.MAIN_MENU)
			#call_deferred("load_scene", MAIN_MENU)
		GameState.CLICK_MODE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Signalbus.game_state_click_mode.emit()
		GameState.LEVEL_CLEARED:			
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Signalbus.game_state_click_mode.emit()

func exit_state(close_state: GameState) -> void:
	match close_state: #clean-up/init
		GameState.MAIN_MENU:
			init_all_game_stats()
		GameState.PLAYING:
			pass
		GameState.PAUSED:
			pause_game()
		GameState.GAME_OVER:
			pause_game()

func pause_game() -> void:
	get_tree().paused = !get_tree().paused

#endregionrent_entr

func restart_level() -> void:
	PlayerData.initialize_player_data()
	get_tree().reload_current_scene()

func _ready() -> void:
	MusicPlayer.execute_playlist("test_playlist")
	floor_data = ResourceLoader.load(str(floor_ref[current_floor])) as FloorData
	scene_ref = floor_data.starting_room_scene
	current_room_id = floor_data.starting_room_id
	get_floor_data()
	_configure_frame_rate()
	PlayerData.initialize_player_data()
	Signalbus.player_died.connect(_load_level_on_player_death)
	Signalbus.level_cleared.connect(set_state_to_cleared)
	process_mode = Node.PROCESS_MODE_ALWAYS
	

func _configure_frame_rate() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)	
	var refresh_rate: float = DisplayServer.screen_get_refresh_rate()
	if refresh_rate <= 0:
		refresh_rate = 60.0
	
	Engine.max_fps = int(minf(refresh_rate * 2.0, 300.0))
	

func init_all_game_stats() -> void:
	PlayerData.initialize_player_data()
	

func load_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
	
func load_current_room()-> void:
	get_tree().change_scene_to_packed(scene_ref)

func _load_level_on_player_death() -> void:
	GameManager.change_state(GameState.GAME_OVER)

func set_state_to_cleared() -> void:	
	change_state(GameState.LEVEL_CLEARED)
