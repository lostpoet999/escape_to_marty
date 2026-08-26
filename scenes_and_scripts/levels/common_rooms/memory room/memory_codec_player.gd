class_name MemoryCodecPlayer extends CanvasLayer

signal finished
signal screen_covered(opening: bool)
signal _advanced

## This room's memory sequence. Layout is inferred per beat: central_image + text = inner voice, portraits = codec conversation, text only = pure voice on a dark stage.
@export var memory_tree: DialogTree

## Text colors per speaker--defaults match dialog_bubble.tscn.
@export var david_text_color: Color = Color(0.4, 0.8, 1)
@export var collector_text_color: Color = Color(1, 0.9, 0.4)
@export var spirit_text_color: Color = Color(0.75, 1, 0.8)
@export var boss_text_color: Color = Color(1, 0.6, 0.6)
@export var jessica_text_color: Color = Color("df84a5")
@export var adoption_officer_text_color: Color = Color("e7d5b3")
@export var grandpa_richard_text_color: Color = Color("de9e41")
@export var doctor_metcalf_text_color: Color = Color("c7cfcc")
@export var nurse_susan_text_color: Color = Color("d0da91")
@export var scuba_instructor_text_color: Color = Color("a4dddb")
@export var stranger_text_color: Color = Color("a8b5b2")

## Modulate on the portrait side that is not speaking.
@export var inactive_portrait_dim: Color = Color(0.45, 0.45, 0.45)

@export var speaker_bob_pixels: float = 5.0
@export var speaker_bob_seconds: float = 1.8

## Fade for portrait appear/replace/clear. 0 = instant, matching the pre-fade behavior.
@export var portrait_fade_seconds: float = 0.35

@export var music_pitch_ramp_seconds: float = 2.0

@onready var root_control: Control = $Root
@onready var central_image: TextureRect = $Root/CentralImage
@onready var portrait_left: TextureRect = $Root/PortraitLeft
@onready var portrait_right: TextureRect = $Root/PortraitRight
@onready var name_left: Label = $Root/NameLeft
@onready var name_right: Label = $Root/NameRight
@onready var beat_text: Label = $Root/TextPanel/MarginContainer/BeatText
@onready var advance_indicator: Polygon2D = $Root/AdvanceIndicator

const FADE_SECONDS: float = 0.25

static var active_count: int = 0

var _playing: bool = false
var _reveal_tween: Tween
var _animation_time: float = 0.0
var _indicator_base_position: Vector2
var _portrait_left_base: Vector2
var _portrait_right_base: Vector2
var _active_side: DialogBeat.PortraitSide = DialogBeat.PortraitSide.LEFT
var _slot_tween_left: Tween
var _slot_tween_right: Tween
var _central_tween: Tween
var _counted: bool = false
var _fade_rect: ColorRect


func _ready() -> void:
	beat_text.label_settings = beat_text.label_settings.duplicate()
	_indicator_base_position = advance_indicator.position
	_portrait_left_base = portrait_left.position
	_portrait_right_base = portrait_right.position
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)
	if get_tree().current_scene == self:
		play.call_deferred()


func _process(delta: float) -> void:
	_animation_time += delta
	advance_indicator.visible = _playing and _is_reveal_complete()
	if advance_indicator.visible:
		var bob: float = sin(TAU * _animation_time / DialogBubble.ADVANCE_BOB_SECONDS) * DialogBubble.ADVANCE_BOB_PIXELS
		advance_indicator.position = _indicator_base_position + Vector2(0.0, bob)
	var speaker_bob: float = 0.0
	if _playing and speaker_bob_seconds > 0.0:
		speaker_bob = sin(TAU * _animation_time / speaker_bob_seconds) * speaker_bob_pixels
	_apply_speaker_bob(DialogBeat.PortraitSide.LEFT, speaker_bob)
	_apply_speaker_bob(DialogBeat.PortraitSide.RIGHT, speaker_bob)


func play() -> void:
	if _playing:
		return
	if memory_tree == null or memory_tree.beats.is_empty():
		push_warning("MemoryCodecPlayer: no memory_tree assigned--completing immediately")
		finished.emit()
		return
	_playing = true
	active_count += 1
	_counted = true
	DialogDirector.cancel_active()
	_reset_stage()
	root_control.visible = false
	visible = true
	await _fade(1.0)
	screen_covered.emit(true)
	root_control.visible = true
	await _fade(0.0)
	for beat: DialogBeat in memory_tree.beats:
		_present_beat(beat)
		await _advanced
	await _fade(1.0)
	root_control.visible = false
	screen_covered.emit(false)
	await _fade(0.0)
	visible = false
	_playing = false
	_release_active_count()
	finished.emit()


func _release_active_count() -> void:
	if _counted:
		_counted = false
		active_count = maxi(active_count - 1, 0)


func _exit_tree() -> void:
	_release_active_count()


func _fade(target_alpha: float) -> void:
	var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade_rect, "color:a", target_alpha, FADE_SECONDS)
	await tw.finished


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
	if _central_tween:
		_central_tween.kill()
		_central_tween = null
	central_image.texture = null
	central_image.visible = false
	central_image.modulate.a = 1.0
	beat_text.text = ""
	_clear_portraits()


func _clear_portraits() -> void:
	_kill_slot_tween(DialogBeat.PortraitSide.LEFT)
	_kill_slot_tween(DialogBeat.PortraitSide.RIGHT)
	portrait_left.texture = null
	portrait_right.texture = null
	portrait_left.modulate.a = 1.0
	portrait_right.modulate.a = 1.0
	name_left.text = ""
	name_right.text = ""
	name_left.modulate.a = 1.0
	name_right.modulate.a = 1.0


func _present_beat(beat: DialogBeat) -> void:
	if beat.clears_portraits:
		_fade_out_slot(DialogBeat.PortraitSide.LEFT)
		_fade_out_slot(DialogBeat.PortraitSide.RIGHT)
	elif beat.clears_side != DialogBeat.ClearSide.NONE:
		var cleared: DialogBeat.PortraitSide = DialogBeat.PortraitSide.LEFT if beat.clears_side == DialogBeat.ClearSide.LEFT else DialogBeat.PortraitSide.RIGHT
		_fade_out_slot(cleared)
	_set_central(beat.central_image)
	if beat.portrait != null:
		_show_portrait(beat.portrait_side, beat.portrait)
	if beat.opposite_portrait != null:
		_show_portrait(_other_side(beat.portrait_side), beat.opposite_portrait)
	if not beat.speaker_name.is_empty():
		_name_label(beat.portrait_side).text = beat.speaker_name
		if _portrait_slot(beat.portrait_side).texture == null:
			push_warning("MemoryCodecPlayer: speaker_name '%s' is on a side with no portrait--name labels only show under a face" % beat.speaker_name)
	_active_side = beat.portrait_side
	_style_portrait_side(DialogBeat.PortraitSide.LEFT, beat.portrait_side)
	_style_portrait_side(DialogBeat.PortraitSide.RIGHT, beat.portrait_side)
	if beat.music_pitch_scale > 0.0:
		MusicPlayer.tween_music_pitch(beat.music_pitch_scale, music_pitch_ramp_seconds)
	_reveal_text(beat)


func _set_central(texture: Texture2D) -> void:
	if _central_tween:
		_central_tween.kill()
		_central_tween = null
	if central_image.texture == texture:
		if texture != null:
			central_image.modulate.a = 1.0
		return
	if portrait_fade_seconds <= 0.0:
		central_image.texture = texture
		central_image.visible = texture != null
		central_image.modulate.a = 1.0
		return
	_central_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if texture == null:
		_central_tween.tween_property(central_image, "modulate:a", 0.0, portrait_fade_seconds)
		_central_tween.tween_callback(func() -> void:
			central_image.texture = null
			central_image.visible = false
			central_image.modulate.a = 1.0)
		return
	if central_image.texture != null and central_image.visible:
		_central_tween.tween_property(central_image, "modulate:a", 0.0, portrait_fade_seconds * 0.5)
		_central_tween.tween_callback(func() -> void: central_image.texture = texture)
		_central_tween.tween_property(central_image, "modulate:a", 1.0, portrait_fade_seconds * 0.5)
		return
	central_image.texture = texture
	central_image.visible = true
	central_image.modulate.a = 0.0
	_central_tween.tween_property(central_image, "modulate:a", 1.0, portrait_fade_seconds)


func _show_portrait(side: DialogBeat.PortraitSide, texture: Texture2D) -> void:
	var slot: TextureRect = _portrait_slot(side)
	_kill_slot_tween(side)
	if slot.texture == texture:
		slot.modulate.a = 1.0
		return
	if portrait_fade_seconds <= 0.0:
		slot.texture = texture
		slot.modulate.a = 1.0
		return
	var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if slot.texture != null and slot.visible:
		tween.tween_property(slot, "modulate:a", 0.0, portrait_fade_seconds * 0.5)
		tween.tween_callback(func() -> void: slot.texture = texture)
		tween.tween_property(slot, "modulate:a", 1.0, portrait_fade_seconds * 0.5)
	else:
		slot.texture = texture
		slot.modulate.a = 0.0
		tween.tween_property(slot, "modulate:a", 1.0, portrait_fade_seconds)
	_set_slot_tween(side, tween)


func _fade_out_slot(side: DialogBeat.PortraitSide) -> void:
	var slot: TextureRect = _portrait_slot(side)
	var name_label: Label = _name_label(side)
	_kill_slot_tween(side)
	if slot.texture == null:
		return
	if portrait_fade_seconds <= 0.0:
		_finish_slot_clear(slot, name_label)
		return
	var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(slot, "modulate:a", 0.0, portrait_fade_seconds)
	tween.tween_property(name_label, "modulate:a", 0.0, portrait_fade_seconds)
	tween.chain().tween_callback(_finish_slot_clear.bind(slot, name_label))
	_set_slot_tween(side, tween)


func _finish_slot_clear(slot: TextureRect, name_label: Label) -> void:
	slot.texture = null
	slot.visible = false
	slot.modulate.a = 1.0
	name_label.text = ""
	name_label.visible = false
	name_label.modulate.a = 1.0


func _other_side(side: DialogBeat.PortraitSide) -> DialogBeat.PortraitSide:
	return DialogBeat.PortraitSide.RIGHT if side == DialogBeat.PortraitSide.LEFT else DialogBeat.PortraitSide.LEFT


func _kill_slot_tween(side: DialogBeat.PortraitSide) -> void:
	var tween: Tween = _get_slot_tween(side)
	if tween != null:
		tween.kill()
	_set_slot_tween(side, null)


func _get_slot_tween(side: DialogBeat.PortraitSide) -> Tween:
	return _slot_tween_left if side == DialogBeat.PortraitSide.LEFT else _slot_tween_right


func _set_slot_tween(side: DialogBeat.PortraitSide, tween: Tween) -> void:
	if side == DialogBeat.PortraitSide.LEFT:
		_slot_tween_left = tween
	else:
		_slot_tween_right = tween


func _apply_speaker_bob(side: DialogBeat.PortraitSide, bob: float) -> void:
	var slot: TextureRect = _portrait_slot(side)
	var base: Vector2 = _portrait_left_base if side == DialogBeat.PortraitSide.LEFT else _portrait_right_base
	var offset: Vector2 = Vector2(0.0, bob) if side == _active_side and slot.visible else Vector2.ZERO
	slot.position = base + offset


func _style_portrait_side(side: DialogBeat.PortraitSide, active_side: DialogBeat.PortraitSide) -> void:
	var slot: TextureRect = _portrait_slot(side)
	var name_label: Label = _name_label(side)
	var tint: Color = Color.WHITE if side == active_side else inactive_portrait_dim
	slot.visible = slot.texture != null
	slot.modulate = Color(tint.r, tint.g, tint.b, slot.modulate.a)
	name_label.visible = slot.visible and not name_label.text.is_empty()
	name_label.modulate = Color(tint.r, tint.g, tint.b, name_label.modulate.a)


func _reveal_text(beat: DialogBeat) -> void:
	beat_text.label_settings.font_color = _speaker_color(beat.speaker)
	beat_text.text = beat.text
	beat_text.visible_ratio = 0.0
	if _reveal_tween:
		_reveal_tween.kill()
	_reveal_tween = create_tween()
	_reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var speed_scale: float = beat.reveal_speed_scale if beat.reveal_speed_scale > 0.0 else 1.0
	var reveal_seconds: float = maxf(beat.text.length() / (DialogBubble.REVEAL_CHARACTERS_PER_SECOND * speed_scale), 0.1)
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
		DialogBeat.Speaker.JESSICA:
			return jessica_text_color
		DialogBeat.Speaker.ADOPTION_OFFICER:
			return adoption_officer_text_color
		DialogBeat.Speaker.GRANDPA_RICHARD:
			return grandpa_richard_text_color
		DialogBeat.Speaker.DOCTOR_METCALF:
			return doctor_metcalf_text_color
		DialogBeat.Speaker.NURSE_SUSAN:
			return nurse_susan_text_color
		DialogBeat.Speaker.SCUBA_INSTRUCTOR:
			return scuba_instructor_text_color
		DialogBeat.Speaker.STRANGER:
			return stranger_text_color
		_:
			return david_text_color


func _portrait_slot(side: DialogBeat.PortraitSide) -> TextureRect:
	return portrait_left if side == DialogBeat.PortraitSide.LEFT else portrait_right


func _name_label(side: DialogBeat.PortraitSide) -> Label:
	return name_left if side == DialogBeat.PortraitSide.LEFT else name_right
