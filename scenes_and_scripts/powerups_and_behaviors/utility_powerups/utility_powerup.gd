class_name UtilityPowerup extends BaseItem

## Utility / information powerups that carry no ball/paddle/click/defense stats of
## their own. The Room Scanner lives here via BaseItem.reveals_adjacent_rooms;
## future scouting tiers (e.g. secret-room reveal) slot into this same category.

## seconds between barrier clears; only read when BaseItem.clears_barriers is on
@export var barrier_clear_cooldown: float = 15.0
## barrier clears available per cooldown window; only read when BaseItem.clears_barriers is on
@export var barrier_clear_charges: int = 1
