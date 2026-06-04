class_name BonusPayload extends Resource

## Display label for this drop (debug / future tooltip use).
@export var label: String
## Optional sprite override for the falling drop. Leave null to keep the BonusDrop scene's default.
@export var drop_texture: Texture2D
## Tint applied to the falling drop so each payload reads differently in flight.
@export var drop_modulate: Color = Color.WHITE

func apply() -> void:
	pass
