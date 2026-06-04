class_name BonusDropPool extends Resource

## Chance per fully-destroyed seal that its drop rerolls from a normal star into one of these payloads.
@export_range(0.0, 1.0, 0.001) var drop_chance: float = 0.015
## The bonus payloads, picked with equal weight on a successful reroll.
@export var payloads: Array[BonusPayload]

func pick_random() -> BonusPayload:
	return payloads.pick_random() if not payloads.is_empty() else null
