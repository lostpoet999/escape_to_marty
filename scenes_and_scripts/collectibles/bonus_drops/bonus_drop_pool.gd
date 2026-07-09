class_name BonusDropPool extends Resource

## Every possible drop from a fully-destroyed seal, currency and bonuses alike. Each payload's weight sets how often it is picked, relative to the others.
@export var payloads: Array[BonusPayload]

func pick_weighted() -> BonusPayload:
	if payloads.is_empty():
		return null
	var total: float = 0.0
	for payload: BonusPayload in payloads:
		total += payload.weight
	if total <= 0.0:
		return null
	var roll: float = randf() * total
	for payload: BonusPayload in payloads:
		roll -= payload.weight
		if roll < 0.0:
			return payload
	return payloads[-1]
