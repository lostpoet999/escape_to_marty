class_name DialogBeat extends Resource

enum Speaker {DAVID, COLLECTOR, LINGERING_SPIRIT, BOSS}

## Who is saying the line--positions box accordingly.
@export var speaker: Speaker = Speaker.DAVID

## The line shown in the bubble for this beat.
@export_multiline var text: String = ""
