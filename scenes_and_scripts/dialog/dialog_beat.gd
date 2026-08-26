class_name DialogBeat extends Resource

enum Speaker { DAVID = 0, COLLECTOR = 1, LINGERING_SPIRIT = 2, BOSS = 3, JESSICA = 4, ADOPTION_OFFICER = 5, GRANDPA_RICHARD = 6, DOCTOR_METCALF = 7, NURSE_SUSAN = 8, SCUBA_INSTRUCTOR = 9, STRANGER = 10 }
enum PortraitSide { LEFT = 0, RIGHT = 1 }

## Who is saying the line--positions box accordingly.
@export var speaker: Speaker = Speaker.DAVID

## The line shown in the bubble for this beat.
@export_multiline var text: String = ""

## Codec player only (bubbles ignore this). Name label under this beat's portrait side; blank = unlabeled. Free text.
@export var speaker_name: String = ""

## Codec player only. The face for this line.
@export var portrait: Texture2D

## Codec player only. Which codec slot this beat's face occupies.
@export var portrait_side: PortraitSide = PortraitSide.LEFT

## Codec player only. Memory image shown center stage for THIS beat.
@export var central_image: Texture2D

## Codec player only. ON = wipe both faces and name labels before applying this beat. Use to introduce a new/unknown speaker on a fresh stage, or to return to pure voice mid-tree.
@export var clears_portraits: bool = false
