class_name DialogTree extends Resource

## Ordered beats, played front to back. Linear only -- no branching.
@export var beats: Array[DialogBeat] = []

## ON = pause and zoome with click to advance
## OFF = timed beats while the game still runs
@export var pauses_game: bool = false

## Play at most once per run including if trigger happens again.
@export var once_per_run: bool = true

## Fires once on every Nth trigger (the Nth, 2Nth, 3Nth...), staying silent in between. IE- a bark every 10th freed spirit. 1 = every trigger.
@export var trigger_threshold: int = 1

## ON: pick a random beat from the "pool" vs play all sequentially
@export var pick_random_beat: bool = false
