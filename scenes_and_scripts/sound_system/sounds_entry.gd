class_name SoundEntry extends Resource

@export var name: String = "sound"
@export var audio: AudioStream
@export var volume_db = -5.0
@export var pitch_scale = 1.0 #flat change in pitch
@export var pitch_variance: float = 0.0 #use to breakup repetitive sounds
@export var loop_sound = false
@export var loop_interval = 0.0
