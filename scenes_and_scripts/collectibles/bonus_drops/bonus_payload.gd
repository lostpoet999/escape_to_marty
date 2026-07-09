class_name BonusPayload extends Resource

## Display label for this drop (debug / future tooltip use).
@export var label: String
## Relative pick weight within the drop pool. Higher weights drop more often; the common currency payload carries the largest weight.
@export var weight: float = 1.0
## When true, spawning plays the rare-drop sting. Leave off for common currency so it stays quiet.
@export var is_rare: bool = true
## Optional sprite override for the falling drop. Leave null to keep the BonusDrop scene's default.
@export var drop_texture: Texture2D
## Tint applied to the falling drop so each payload reads differently in flight.
@export var drop_modulate: Color = Color.WHITE

func apply() -> void:
	pass
