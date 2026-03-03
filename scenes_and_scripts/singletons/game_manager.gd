extends Node

#scene references
const MAIN_MENU = preload("uid://djuj72c4lcukn")
const LEVEL_01 = preload("uid://bea1h3570swpu")

enum GameState {MAIN_MENU, BALL_ON_PADDLE, PLAYING, PAUSED, GAME_OVER, CLICK_MODE}
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

#region gamestate functions
func change_state(to_state: GameState) -> void:
	if not is_valid_state_transition(current_state, to_state): return
	exit_state(current_state)
	enter_state(to_state)

func is_valid_state_transition(from_state: GameState, to_state: GameState) -> bool:
	if current_state == to_state: return false
	match from_state:
		GameState.MAIN_MENU:
			return to_state in [GameState.BALL_ON_PADDLE]
		GameState.BALL_ON_PADDLE:
			return to_state in [GameState.PLAYING, GameState.PAUSED]
		GameState.PLAYING:
			return to_state in [GameState.PAUSED, GameState.GAME_OVER, GameState.MAIN_MENU, GameState.CLICK_MODE]
		GameState.PAUSED:
			return to_state in [GameState.PLAYING, GameState.BALL_ON_PADDLE]
		GameState.GAME_OVER:
			return to_state in [GameState.MAIN_MENU, GameState.PLAYING]
		GameState.CLICK_MODE:
			return to_state in [GameState.PLAYING]		
	return false

func enter_state(change_to_state: GameState) -> void:
	current_state = change_to_state
	match current_state:
		GameState.MAIN_MENU:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
			GameManager.change_state(GameState.MAIN_MENU)
			call_deferred("load_scene", MAIN_MENU)
		GameState.CLICK_MODE:
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
			pass

func pause_game() -> void:
	get_tree().paused = !get_tree().paused

#endregion

#scene and gamestate functions

func restart_level() -> void:
	PlayerData.initialize_player_data()
	get_tree().reload_current_scene()

func _ready() -> void:
	_configure_frame_rate()
	PlayerData.initialize_player_data()
	Signalbus.player_died.connect(_load_level_on_player_death)
	Signalbus.level_cleared.connect(load_next_level)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _configure_frame_rate() -> void:
	# Disable VSync to avoid frame pacing jitter
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# Detect monitor refresh rate, fallback to 60 for web or if detection fails
	var refresh_rate: float = DisplayServer.screen_get_refresh_rate()
	if refresh_rate <= 0:
		refresh_rate = 60.0

	# Cap at 2x refresh rate for smooth frame selection, max 300fps
	Engine.max_fps = int(minf(refresh_rate * 2.0, 300.0))

func init_all_game_stats() -> void:
	PlayerData.initialize_player_data()



func load_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)

func _load_level_on_player_death() -> void:
	GameManager.change_state(GameState.GAME_OVER)

func load_next_level() -> void:
	change_state(GameState.MAIN_MENU)
	call_deferred("load_scene", MAIN_MENU) #will be replaced by maps and portals
