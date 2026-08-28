class_name DialogBeat extends Resource

enum Speaker { DAVID = 0, COLLECTOR = 1, LINGERING_SPIRIT = 2, BOSS = 3, JESSICA = 4, ADOPTION_OFFICER = 5, GRANDPA_RICHARD = 6, DOCTOR_METCALF = 7, NURSE_SUSAN = 8, SCUBA_INSTRUCTOR = 9, STRANGER = 10 }
enum PortraitSide { LEFT = 0, RIGHT = 1 }
enum ClearSide { NONE = 0, LEFT = 1, RIGHT = 2 }

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

## Codec player only. Tint multiplied into the central image for this beat; white = untinted.
@export var central_image_modulate: Color = Color.WHITE

## Codec player only. Scale of the central image for this beat (1 = full size); changes pop-tween between beats.
@export var central_image_scale: float = 1.0

## Codec player only. Normalized (0-1) points on the central image that get an additive glow this beat (e.g. headlights); empty = none.
@export var central_image_glow_points: PackedVector2Array = PackedVector2Array()

## Codec player only. Tint of the additive glows.
@export var central_image_glow_color: Color = Color(1.0, 0.95, 0.75, 0.85)

## Codec player only. Glow diameter as a fraction of the drawn image's smaller side.
@export var central_image_glow_size: float = 0.3

## Codec player only. SFX name played the moment this beat lands; blank = silent.
@export var beat_sound: String = ""

## Codec player only. A second face placed on the side opposite portrait_side, dimmed as the non-speaking side.
@export var opposite_portrait: Texture2D

## Codec player only. Fade out ONE side's face and name before this beat applies; clears_portraits wipes both instead.
@export var clears_side: ClearSide = ClearSide.NONE

## Codec player only. Multiplies the typewriter reveal rate; 0.5 = letters land at half speed.
@export var reveal_speed_scale: float = 1.0

## Codec player only. Above 0 ramps the music player's pitch to this value as the beat lands; 0 = leave the music alone.
@export var music_pitch_scale: float = 0.0

## Codec player only. ON = wipe both faces and name labels before applying this beat. Use to introduce a new/unknown speaker on a fresh stage, or to return to pure voice mid-tree.
@export var clears_portraits: bool = false
