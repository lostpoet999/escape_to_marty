class_name DefensivePowerup extends BaseItem

@export_group("Reflect Mitigation")
## Fraction of ball-miss reflect damage removed. Stacks additively across owned defensive powerups, then clamps to PlayerData.MAX_REFLECT_REDUCTION.
@export_range(0.0, 0.5, 0.01) var reflect_reduction: float = 0.0

@export_group("Max Health")
## Raises player_max_health additively, summed across owned defensive powerups and clamped to PlayerData.MAX_HEALTH_CEILING.
@export var max_health_bonus: int = 0
## Current HP restored once when this powerup is acquired (0 = none). Applied after max HP updates, so set it to max_health_bonus to fill the new headroom, or higher to top up further (clamps to max).
@export var heal_on_pickup: int = 0
