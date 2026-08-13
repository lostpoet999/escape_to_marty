class_name PaddlePowerup
extends BaseItem

@export var paddle_length_mod: float
@export var gold_magnet_radius: float
## fraction of the base radius added by each extra copy of this item
@export var gold_magnet_stack_bonus: float = 0.2
## ceiling on the stacked radius in px; 0 = uncapped
@export var gold_magnet_max_radius: float
