class_name MemoryCodecPlayer extends CanvasLayer

signal finished
signal _advanced

## This room's memory sequence. Layout is inferred per beat: central_image + text = inner voice, portraits = codec conversation, text only = pure voice on a dark stage.
@export var memory_tree: DialogTree

## Text colors per speaker--defaults match dialog_bubble.tscn.
@export var david_text_color: Color = Color(0.4, 0.8, 1)
@export var collector_text_color: Color = Color(1, 0.9, 0.4)
@export var spirit_text_color: Color = Color(0.75, 1, 0.8)
@export var boss_text_color: Color = Color(1, 0.6, 0.6)

## Modulate on the portrait side that is not speaking.
@export var inactive_portrait_dim: Color = Color(0.45, 0.45, 0.45)

@onready var root_control: Control = $Root
@onready var central_image: TextureRect = $Root/CentralImage
@onready var portrait_left: TextureRect = $Root/PortraitLeft
@onready var portrait_right: TextureRect = $Root/PortraitRight
@onready var name_left: Label = $Root/NameLeft
@onready var name_right: Label = $Root/NameRight
@onready var beat_text: Label = $Root/TextPanel/MarginContainer/BeatText
@onready var advance_indicator: Polygon2D = $Root/AdvanceIndicator

var _playing: bool = false
var _reveal_tween: Tween
var _animation_time: float = 0.0
var _indicator_base_position: Vector2


func _ready() -> void:
	beat_text.label_settings = beat_text.label_settings.duplicate()
	_indicator_base_position = advance_indicator.position
	if get_tree().current_scene == self:
		play.call_deferred()


func _process(delta: float) -> void:
	_animation_time += delta
	advance_indicator.visible = _playing and _is_reveal_complete()
	if advance_indicator.visible:
		var bob: float = sin(TAU * _animation_time / DialogBubble.ADVANCE_BOB_SECONDS) * DialogBubble.ADVANCE_BOB_PIXELS
		advance_indicator.position = _indicator_base_position + Vector2(0.0, bob)


func play() -> void:
	if _playing:
		return
	if memory_tree == null or memory_tree.beats.is_empty():
		push_warning("MemoryCodecPlayer: no memory_tree assigned--completing immediately")
		finished.emit()
		return
	_playing = true
	_reset_stage()
	visible = true
	for beat: DialogBeat in memory_tree.beats:
		_present_beat(beat)
		await _advanced
	visible = false
	_playing = false
	finished.emit()


func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			root_control.accept_event()
			_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _playing:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	if not _playing:
		return
	if not _is_reveal_complete():
		_complete_reveal()
		return
	_advanced.emit()


func _reset_stage() -> void:
	central_image.texture = null
	beat_text.text = ""
	_clear_portraits()


func _clear_portraits() -> void:
	portrait_left.texture = null
	portrait_right.texture = null
	name_left.text = ""
	name_right.text = ""


func _present_beat(beat: DialogBeat) -> void:
	if beat.clears_portraits:
		_clear_portraits()
	central_image.texture = beat.central_image
	central_image.visible = beat.central_image != null
	if beat.portrait != null:
		_portrait_slot(beat.portrait_side).texture = beat.portrait
	if not beat.speaker_name.is_empty():
		_name_label(beat.portrait_side).text = beat.speaker_name
		if _portrait_slot(beat.portrait_side).texture == null:
			push_warning("MemoryCodecPlayer: speaker_name '%s' is on a side with no portrait--name labels only show under a face" % beat.speaker_name)
	_style_portrait_side(DialogBeat.PortraitSide.LEFT, beat.portrait_side)
	_style_portrait_side(DialogBeat.PortraitSide.RIGHT, beat.portrait_side)
	_reveal_text(beat)


func _style_portrait_side(side: DialogBeat.PortraitSide, active_side: DialogBeat.PortraitSide) -> void:
	var slot: TextureRect = _portrait_slot(side)
	var name_label: Label = _name_label(side)
	var tint: Color = Color.WHITE if side == active_side else inactive_portrait_dim
	slot.visible = slot.texture != null
	slot.modulate = tint
	name_label.visible = slot.visible and not name_label.text.is_empty()
	name_label.modulate = tint


func _reveal_text(beat: DialogBeat) -> void:
	beat_text.label_settings.font_color = _speaker_color(beat.speaker)
	beat_text.text = beat.text
	beat_text.visible_ratio = 0.0
	if _reveal_tween:
		_reveal_tween.kill()
	_reveal_tween = create_tween()
	_reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var reveal_seconds: float = maxf(beat.text.length() / DialogBubble.REVEAL_CHARACTERS_PER_SECOND, 0.1)
	_reveal_tween.tween_property(beat_text, "visible_ratio", 1.0, reveal_seconds)


func _is_reveal_complete() -> bool:
	return beat_text.visible_ratio >= 1.0


func _complete_reveal() -> void:
	if _reveal_tween:
		_reveal_tween.kill()
	beat_text.visible_ratio = 1.0


func _speaker_color(speaker: DialogBeat.Speaker) -> Color:
	match speaker:
		DialogBeat.Speaker.COLLECTOR:
			return collector_text_color
		DialogBeat.Speaker.LINGERING_SPIRIT:
			return spirit_text_color
		DialogBeat.Speaker.BOSS:
			return boss_text_color
		_:
			return david_text_color


func _portrait_slot(side: DialogBeat.PortraitSide) -> TextureRect:
	return portrait_left if side == DialogBeat.PortraitSide.LEFT else portrait_right


func _name_label(side: DialogBeat.PortraitSide) -> Label:
	return name_left if side == DialogBeat.PortraitSide.LEFT else name_right
