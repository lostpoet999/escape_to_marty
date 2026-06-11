class_name DialogTree extends Resource

## Ordered beats, played front to back. Linear only -- no branching.
@export var beats: Array[DialogBeat] = []

## ON = pause and zoome with click to advance
## OFF = timed beats while the game still runs
@export var pauses_game: bool = false

## Play at most once per run including if trigger happens again.
@export var once_per_run: bool = true

## Which call count actuall triggers the dialog. IE- the nth freed spirit trigger dialog.
@export var trigger_threshold: int = 1

## ON: pick a random beat from the "pool" vs play all sequentially
@export var pick_random_beat: bool = false
