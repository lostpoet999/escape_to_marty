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

## ON: play ONE beat per trigger, advancing front to back across triggers and
## holding on the last beat once exhausted. Resets each run and on save-load
## (a replayed encounter restarts its arc). Wins over pick_random_beat.
@export var pick_next_beat: bool = false

## ON: a tutorial tip. Only plays while "Tutorial Tips" is enabled in settings, and the
## bubble anchors to the node passed to play() even for the Collector, so it points at
## the thing being taught instead of sitting at a screen edge.
@export var tutorial_tip: bool = false

## ON: while this tree's ambient bubble is on screen, other ambient plays are
## discarded (their once_per_run is not burned). Focused trees still take over.
@export var no_override: bool = false

## ON: this tree plays even while a no_override bubble is up, dismissing it the
## way a focused tree would. For must-not-miss barks; codecs and focused trees
## still win.
@export var takes_over: bool = false
