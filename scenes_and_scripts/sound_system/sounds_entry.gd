class_name SoundEntry extends Resource

@export var name: String = "sound"
@export var audio: AudioStream
@export var volume_db: float = -5.0
@export var pitch_scale: float = 1.0 #flat change in pitch
@export var pitch_variance: float = 0.0 #use to breakup repetitive sounds
@export var loop_sound: bool = false
@export var loop_interval: float = 0.0
@export var max_concurrent: int = 0 ## Max simultaneous one-shot players for this sound; 0 = unlimited.
