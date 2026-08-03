class_name EncounterProgressBar
extends Control

const BASE_ALPHA: float = 0.8
const NEAR_ALPHA: float = 0.1
const FADE_RATE: float = 2.5
const BOB_PIXELS: float = 3.0
const BOB_PERIOD: float = 2.8

@export var title: String = ""
@export var ball_fade_distance: float = 160.0

var _tween: Tween
var _breathe: Tween
var _bob_phase: float = 0.0
var _base_y: float = 0.0

@onready var _title_label: Label = $Title
@onready var _bar: ProgressBar = $Bar

func _ready() -> void:
	_title_label.text = title
	_base_y = position.y
	visible = false
	Signalbus.encounter_progress.connect(_on_encounter_progress)

func _process(delta: float) -> void:
	if not visible:
		return
	var target: float = BASE_ALPHA
	var ball: Node2D = get_tree().get_first_node_in_group(&"ball") as Node2D
	if ball != null:
		var rect: Rect2 = get_global_rect()
		var closest: Vector2 = ball.global_position.clamp(rect.position, rect.position + rect.size)
		if ball.global_position.distance_to(closest) <= ball_fade_distance:
			target = NEAR_ALPHA
	modulate.a = move_toward(modulate.a, target, delta * FADE_RATE)
	_bob_phase = wrapf(_bob_phase + delta * TAU / BOB_PERIOD, 0.0, TAU)
	position.y = _base_y + sin(_bob_phase) * BOB_PIXELS

func _on_encounter_progress(stage: int, stage_count: int, stage_remaining: float, stage_max: float) -> void:
	var stage_fraction: float = 0.0
	if stage_max > 0.0:
		stage_fraction = clampf(stage_remaining / stage_max, 0.0, 1.0)
	var remaining: float = (float(stage_count - stage) + stage_fraction) / float(stage_count)
	if not visible:
		visible = true
		_bar.value = remaining
		_breathe = ApolloPalette.make_breathe_tween(self, false)
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_bar, "value", remaining, 0.2)
