class_name EnemyConfig
extends Resource

@export var enemy_name: String
@export var scene_ref: PackedScene
@export var spawn_chance: float
@export var max_global_spawn: int ## Max of this enemy alive at once (seal-break path). 0 = unlimited.
@export var requires_live_seals: bool = false ## Skip this config once no seals remain in the room; for enemies that only make sense mid-fight (e.g. money thieves).
@export var x_offset: float
@export var y_offset: float
