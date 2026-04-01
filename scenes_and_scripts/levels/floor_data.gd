class_name FloorData extends Resource

@export_category("Item Spawn Rates:")
@export var spawn_weight: SpawnWeights

@export_category("Seal Config for Floor:")
@export var seal_difficulty_rates: SealDifficulty
@export var seal_phase_pool: Array[SealPhaseConfig] = []
@export var seal_health_phase: SealPhaseConfig

@export_category("Floor Layout Data")
@export var floor_name_id: String
@export var room_entries: Array[RoomEntry]
@export var grid_size: Vector2i = Vector2i(5,5)
@export var show_mini_map: bool
@export var starting_room_id: String
@export var starting_room_scene: PackedScene

@export_category("Enemy Data")
@export var seal_break_enemies: Array[EnemyConfig]
