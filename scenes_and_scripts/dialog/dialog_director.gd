extends Node

const TREES_DIR: String = "res://scenes_and_scripts/dialog/trees/"
const BUBBLE_SCENE: PackedScene = preload("res://scenes_and_scripts/dialog/dialog_bubble.tscn")
const BASE_SECONDS_PER_BEAT: float = 2.2
const LINGER_SECONDS_PER_CHARACTER: float = 0.065
const FOCUSED_CLOSE_SETTLE_SECONDS: float = 0.25
const FOCUSED_ZOOM_FACTOR: float = 1.06
const FOCUSED_ZOOM_SECONDS: float = 0.35
const FOCUSED_PULL_FRACTION: float = 0.2
const FOCUSED_PULL_SECONDS: float = 0.3
const FOCUSED_DIM_ALPHA: float = 0.5
const FOCUSED_DIM_Z_INDEX: int = 90
const FOCUSED_DIM_RECT: Rect2 = Rect2(-200, -200, 2320, 1480)

signal tree_finished(tree_id: StringName)

var focused_active: bool = false

var _active_bubble: DialogBubble
var _active_anchor: Node2D
var _active_is_static: bool = false
var _active_no_override: bool = false
var _play_serial: int = 0
var _active_catcher: ClickCatcher
var _cancel_requested: bool = false
var _focus_camera: Camera2D
var _focus_base_zoom: Vector2
var _focus_base_offset: Vector2
var _focus_base_center: Vector2
var _focus_max_pull: Vector2
var _focus_dim: ColorRect
var _focus_tween: Tween
var _focus_pull_tween: Tween
var _clear_queue: Array[StringName] = []


func _ready() -> void:
	Signalbus.level_cleared.connect(_on_level_cleared)


func play(tree_id: StringName, anchor: Node2D = null) -> bool:
	if MemoryCodecPlayer.active_count > 0:
		return false
	if focused_active:
		return false
	var tree: DialogTree = _load_tree(tree_id)
	if tree == null or tree.beats.is_empty():
		return false
	if tree.tutorial_tip and not SettingsManager.show_tutorial_tips:
		return false
	if not tree.pauses_game and _no_override_active() and not tree.takes_over:
		return false
	if not _passes_trigger_threshold(tree_id, tree):
		return false
	if tree.once_per_run:
		if PlayerData.seen_dialog_trees.has(tree_id):
			return false
		PlayerData.seen_dialog_trees.append(tree_id)
	_play_serial += 1
	if tree.pauses_game:
		_play_focused(tree_id, tree, anchor)
	else:
		_play_timed(tree_id, tree, anchor, _play_serial)
	return true


func play_and_wait(tree_id: StringName, anchor: Node2D = null) -> void:
	if not play(tree_id, anchor):
		return
	var finished_id: StringName = await tree_finished
	while finished_id != tree_id:
		finished_id = await tree_finished


func play_at_control(tree_id: StringName, control: Control, screen_offset: Vector2 = Vector2.ZERO) -> bool:
	if not is_instance_valid(control):
		return false
	var tracker: ControlAnchor = ControlAnchor.new()
	tracker.target = control
	tracker.tree_id = tree_id
	tracker.screen_offset = screen_offset
	tracker.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(tracker)
	if not play(tree_id, tracker):
		tracker.queue_free()
		return false
	return true


func play_on_clear(tree_id: StringName) -> void:
	_clear_queue.erase(tree_id)
	_clear_queue.append(tree_id)


func reset_clear_queue() -> void:
	_clear_queue.clear()


## Instantly ends whatever is playing (cutscene skip). An ambient bubble is
## dismissed on the spot; a focused tree unwinds through its normal teardown
## (zoom-out, unpause, tree_finished) so nothing is left paused or dimmed.
func cancel_active() -> void:
	if focused_active:
		_cancel_requested = true
		if is_instance_valid(_active_catcher):
			_active_catcher.clicked.emit()
		return
	_play_serial += 1
	_dismiss_active_bubble()


func force_reset() -> void:
	_clear_queue.clear()
	_play_serial += 1
	_cancel_requested = true
	_kill_focus_tween()
	_kill_focus_pull_tween()
	_dismiss_active_bubble()
	if is_instance_valid(_active_catcher):
		_active_catcher.queue_free()
	_active_catcher = null
	if is_instance_valid(_focus_dim):
		_focus_dim.queue_free()
	_focus_dim = null
	_focus_camera = null
	if focused_active:
		GameManager.unpause_game()
		focused_active = false


func _on_level_cleared() -> void:
	if _clear_queue.is_empty():
		return
	var tree_id: StringName = _clear_queue[-1]
	_clear_queue.clear()
	play.call_deferred(tree_id)


func _passes_trigger_threshold(tree_id: StringName, tree: DialogTree) -> bool:
	if tree.trigger_threshold <= 1:
		return true
	var count: int = PlayerData.dialog_trigger_counts.get(tree_id, 0) + 1
	PlayerData.dialog_trigger_counts[tree_id] = count
	return count % tree.trigger_threshold == 0


func _play_timed(tree_id: StringName, tree: DialogTree, anchor: Node2D, serial: int) -> void:
	_dismiss_active_bubble()
	for beat: DialogBeat in _beats_to_play(tree_id, tree):
		if not _present_beat(beat, anchor, tree.tutorial_tip):
			break
		_active_no_override = tree.no_override
		await get_tree().create_timer(_beat_seconds(beat), false).timeout
		if serial != _play_serial:
			tree_finished.emit(tree_id)
			return
		if not is_instance_valid(_active_bubble):
			tree_finished.emit(tree_id)
			return
	_dismiss_active_bubble()
	tree_finished.emit(tree_id)


func _play_focused(tree_id: StringName, tree: DialogTree, anchor: Node2D) -> void:
	_dismiss_active_bubble()
	focused_active = true
	var prior_mouse_mode: Input.MouseMode = Input.get_mouse_mode()
	GameManager.pause_game()
	GameManager.set_mouse_visible()
	var catcher: ClickCatcher = _spawn_click_catcher()
	_active_catcher = catcher
	_cancel_requested = false
	_begin_focus_frame()
	for beat: DialogBeat in _beats_to_play(tree_id, tree):
		if _cancel_requested:
			break
		if not _present_beat(beat, anchor, tree.tutorial_tip):
			break
		_active_bubble.process_mode = Node.PROCESS_MODE_ALWAYS
		_active_bubble.focused = true
		var pull_target: Vector2 = _active_bubble.focus_point()
		if tree.tutorial_tip and is_instance_valid(anchor):
			pull_target = anchor.global_position
		_retarget_focus_pull(pull_target)
		await _advance_click(catcher)
		if not is_instance_valid(_active_bubble):
			break
	_dismiss_active_bubble()
	catcher.queue_free()
	await _end_focus_frame()
	await get_tree().create_timer(FOCUSED_CLOSE_SETTLE_SECONDS, true).timeout
	GameManager.unpause_game()
	Input.set_mouse_mode(prior_mouse_mode)
	focused_active = false
	_active_catcher = null
	_cancel_requested = false
	tree_finished.emit(tree_id)


func _begin_focus_frame() -> void:
	_focus_dim = ColorRect.new()
	_focus_dim.color = Color(0, 0, 0, 0)
	_focus_dim.position = FOCUSED_DIM_RECT.position
	_focus_dim.size = FOCUSED_DIM_RECT.size
	_focus_dim.z_index = FOCUSED_DIM_Z_INDEX
	_focus_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().current_scene.add_child(_focus_dim)
	_kill_focus_tween()
	_focus_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_focus_tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_focus_tween.tween_property(_focus_dim, "color:a", FOCUSED_DIM_ALPHA, FOCUSED_ZOOM_SECONDS)
	_focus_camera = get_viewport().get_camera_2d()
	if _focus_camera == null:
		return
	_focus_base_zoom = _focus_camera.zoom
	_focus_base_offset = _focus_camera.offset
	_focus_base_center = _focus_camera.get_screen_center_position()
	_focus_max_pull = _focus_camera.get_viewport_rect().size * 0.5 / _focus_base_zoom * (1.0 - 1.0 / FOCUSED_ZOOM_FACTOR)
	_focus_tween.tween_property(_focus_camera, "zoom", _focus_base_zoom * FOCUSED_ZOOM_FACTOR, FOCUSED_ZOOM_SECONDS)


func _retarget_focus_pull(target: Vector2) -> void:
	if _focus_camera == null:
		return
	var pull: Vector2 = (target - _focus_base_center) * FOCUSED_PULL_FRACTION
	pull = pull.clamp(-_focus_max_pull, _focus_max_pull)
	_kill_focus_pull_tween()
	_focus_pull_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_focus_pull_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_focus_pull_tween.tween_property(_focus_camera, "offset", _focus_base_offset + pull, FOCUSED_PULL_SECONDS)


func _end_focus_frame() -> void:
	_kill_focus_tween()
	_kill_focus_pull_tween()
	_focus_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_focus_tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(_focus_dim):
		_focus_tween.tween_property(_focus_dim, "color:a", 0.0, FOCUSED_ZOOM_SECONDS)
	if is_instance_valid(_focus_camera):
		_focus_tween.tween_property(_focus_camera, "zoom", _focus_base_zoom, FOCUSED_ZOOM_SECONDS)
		_focus_tween.tween_property(_focus_camera, "offset", _focus_base_offset, FOCUSED_ZOOM_SECONDS)
	await _focus_tween.finished
	if is_instance_valid(_focus_dim):
		_focus_dim.queue_free()
	_focus_dim = null
	_focus_camera = null


func _kill_focus_tween() -> void:
	if _focus_tween != null and _focus_tween.is_valid():
		_focus_tween.kill()
	_focus_tween = null


func _kill_focus_pull_tween() -> void:
	if _focus_pull_tween != null and _focus_pull_tween.is_valid():
		_focus_pull_tween.kill()
	_focus_pull_tween = null


func _advance_click(catcher: ClickCatcher) -> void:
	while true:
		await catcher.clicked
		if _cancel_requested:
			return
		if is_instance_valid(_active_bubble) and not _active_bubble.is_reveal_complete():
			_active_bubble.complete_reveal()
		else:
			return


func _spawn_click_catcher() -> ClickCatcher:
	var catcher: ClickCatcher = ClickCatcher.new()
	catcher.process_mode = Node.PROCESS_MODE_ALWAYS
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(catcher)
	return catcher


func _beats_to_play(tree_id: StringName, tree: DialogTree) -> Array[DialogBeat]:
	if tree.pick_next_beat:
		var cursor: int = PlayerData.dialog_beat_cursors.get(tree_id, 0)
		var index: int = mini(cursor, tree.beats.size() - 1)
		PlayerData.dialog_beat_cursors[tree_id] = index + 1
		var next: Array[DialogBeat] = [tree.beats[index]]
		return next
	if tree.pick_random_beat:
		var picked: Array[DialogBeat] = [tree.beats.pick_random() as DialogBeat]
		return picked
	return tree.beats


func _present_beat(beat: DialogBeat, anchor: Node2D, is_tutorial: bool = false) -> bool:
	if beat.speaker == DialogBeat.Speaker.COLLECTOR and not is_instance_valid(anchor):
		_show_collector(beat, is_tutorial)
		return true
	var beat_anchor: Node2D = _resolve_anchor(beat, anchor)
	if beat_anchor == null:
		return false
	_show_anchored(beat, beat_anchor, is_tutorial)
	return true


func _show_anchored(beat: DialogBeat, beat_anchor: Node2D, is_tutorial: bool) -> void:
	var reusable: bool = is_instance_valid(_active_bubble) and not _active_is_static and _active_anchor == beat_anchor
	if not reusable:
		_dismiss_active_bubble()
		var bubble: DialogBubble = BUBBLE_SCENE.instantiate()
		bubble.setup(beat_anchor)
		beat_anchor.add_child(bubble)
		_active_bubble = bubble
		_active_anchor = beat_anchor
		_active_is_static = false
	_active_bubble.show_beat(beat, is_tutorial)


func _show_collector(beat: DialogBeat, is_tutorial: bool) -> void:
	var reusable: bool = is_instance_valid(_active_bubble) and _active_is_static
	if not reusable:
		_dismiss_active_bubble()
		var bubble: DialogBubble = BUBBLE_SCENE.instantiate()
		bubble.setup_collector()
		get_tree().current_scene.add_child(bubble)
		_active_bubble = bubble
		_active_anchor = null
		_active_is_static = true
	_active_bubble.show_beat(beat, is_tutorial)


func _resolve_anchor(beat: DialogBeat, provided_anchor: Node2D) -> Node2D:
	if is_instance_valid(provided_anchor):
		return provided_anchor
	if beat.speaker == DialogBeat.Speaker.DAVID:
		return get_tree().get_first_node_in_group("david") as Node2D
	push_warning("DialogDirector: no anchor provided for speaker %d" % beat.speaker)
	return null


func _beat_seconds(beat: DialogBeat) -> float:
	return BASE_SECONDS_PER_BEAT + beat.text.length() * LINGER_SECONDS_PER_CHARACTER


func _no_override_active() -> bool:
	return _active_no_override and is_instance_valid(_active_bubble)


func _dismiss_active_bubble() -> void:
	if is_instance_valid(_active_bubble):
		_active_bubble.queue_free()
	_active_bubble = null
	_active_anchor = null
	_active_is_static = false
	_active_no_override = false


func _load_tree(tree_id: StringName) -> DialogTree:
	var path: String = TREES_DIR + String(tree_id) + ".tres"
	if not ResourceLoader.exists(path):
		push_warning("DialogDirector: no dialog tree at %s" % path)
		return null
	return load(path) as DialogTree


class ControlAnchor extends Node2D:
	var target: Control
	var tree_id: StringName
	var screen_offset: Vector2 = Vector2.ZERO

	func _ready() -> void:
		DialogDirector.tree_finished.connect(_on_tree_finished)
		_track()

	func _on_tree_finished(finished_id: StringName) -> void:
		if finished_id == tree_id:
			queue_free()

	func _process(_delta: float) -> void:
		_track()

	func _track() -> void:
		if not is_instance_valid(target):
			queue_free()
			return
		var screen_point: Vector2 = target.get_global_rect().get_center() + screen_offset
		global_position = get_viewport().get_canvas_transform().affine_inverse() * screen_point


class ClickCatcher extends Control:
	signal clicked()

	func _gui_input(event: InputEvent) -> void:
		var click: InputEventMouseButton = event as InputEventMouseButton
		if click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			accept_event()
			clicked.emit()
