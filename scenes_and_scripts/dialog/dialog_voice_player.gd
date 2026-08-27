class_name DialogVoicePlayer extends AudioStreamPlayer

const SKIPPED_CHARACTERS: String = " \t\n.,!?;:-'\"()[]…"

## Loudness of every blip before the voice's per-speaker trim.
@export var base_volume_db: float = -6.0

var _voice: DialogVoice
var _line_text: String = ""
var _revealed_count: int = 0
var _blip_countdown: int = 0


func begin_line(voice: DialogVoice, line_text: String) -> void:
	_voice = voice
	_line_text = line_text
	_revealed_count = 0
	_blip_countdown = 0


func update_reveal(visible_count: int) -> void:
	var total: int = _line_text.length()
	var revealed: int = visible_count if visible_count >= 0 else total
	revealed = mini(revealed, total)
	if revealed <= _revealed_count:
		return
	var should_blip: bool = false
	for i: int in range(_revealed_count, revealed):
		if SKIPPED_CHARACTERS.contains(_line_text[i]):
			continue
		if _blip_countdown <= 0:
			should_blip = true
			_blip_countdown = maxi(_voice.chars_per_blip, 1) if _voice != null else 1
		_blip_countdown -= 1
	_revealed_count = revealed
	if should_blip:
		_play_blip()


func snap_reveal() -> void:
	if _revealed_count >= _line_text.length():
		return
	_revealed_count = _line_text.length()
	_play_blip()


func _play_blip() -> void:
	if _voice == null or _voice.stream == null:
		return
	if stream != _voice.stream:
		stream = _voice.stream
	volume_db = base_volume_db + _voice.volume_db
	var multiplier: float = 1.0
	if not _voice.pitch_multipliers.is_empty():
		multiplier = _voice.pitch_multipliers.pick_random() as float
	pitch_scale = _voice.base_pitch * multiplier
	play()
