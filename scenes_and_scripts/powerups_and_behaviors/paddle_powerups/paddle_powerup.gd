class_name PaddlePowerup
extends BaseItem

@export var paddle_length_mod: float
## Width of EACH ghost paddle as a fraction of the real paddle's collision width; 0 = no ghosts.
## Copies stack additively. Ghosts sit flush against the paddle's ends and bounce balls, but are
## invisible to anything that hunts the "paddle" group (dark cages, spider webs).
@export var ghost_paddle_ratio: float = 0.0
@export var gold_magnet_radius: float
## fraction of the base radius added by each extra copy of this item
@export var gold_magnet_stack_bonus: float = 0.2
## ceiling on the stacked radius in px; 0 = uncapped
@export var gold_magnet_max_radius: float
