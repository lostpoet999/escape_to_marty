class_name DialogVoice extends Resource

## Blip sample for this speaker. A single stream works; an AudioStreamRandomizer holds a multi-sample bank.
@export var stream: AudioStream
@export var base_pitch: float = 1.0
## Each blip plays at base_pitch times one entry picked from here. Pentatonic-ish sets keep overlapping blips consonant.
@export var pitch_multipliers: Array[float] = [1.0, 1.125, 1.25, 1.5]
## A blip fires every Nth revealed character; spaces and punctuation never count.
@export var chars_per_blip: int = 2
## Per-speaker trim on top of the player's base volume.
@export var volume_db: float = 0.0
