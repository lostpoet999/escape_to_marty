class_name FloorData extends Resource

@export_category("Item Spawn Rates:")
@export var spawn_weight: SpawnWeights
@export var boss_loot_config: BossLootConfig

@export_category("Bankruptcy")
@export var bankruptcy_enabled: bool = true
@export var bankruptcy_stars_per_life: int = 10
@export var bankruptcy_damage_per_life: int = 1

@export_category("Seal Config for Floor:")
@export var seal_difficulty_rates: SealDifficulty
@export var seal_phase_pool: Array[SealPhaseConfig] = []
@export var seal_health_phase: SealPhaseConfig

@export_category("Floor Layout Data")
@export var max_respawn: int
@export var floor_name_id: String
@export var room_entries: Array[RoomEntry]
## content assigned to non-static slots at floor start; required placed first, filler fills the rest
@export var room_pool: Array[RoomContent]
## minimum guaranteed rooms per type (RoomContent.ROOM_TYPES value -> count); empty = unchecked
@export var required_composition: Dictionary
@export var grid_size: Vector2i = Vector2i(5,5)
@export var show_mini_map: bool

@export_category("Enemy Data")
@export var seal_break_enemies: Array[EnemyConfig]

@export_category("Floor Visuals")
# null = keep whatever each wall scene was built with
@export var wall_texture: Texture2D
@export var wall_modulate: Color = Color.WHITE
# separate alpha multiplier so you can fade walls without re-picking the tint color
@export_range(0.0, 1.0, 0.01) var wall_alpha: float = 1.0
@export var wall_texture_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
# per-tile rgb shift, breaks the uniform-grid look. 0 = uniform, 0.5 = chaotic
@export_range(0.0, 0.5, 0.01) var wall_brightness_jitter: float = 0.0
# randomly flip each tile h/v - kills visible repetition in the brick pattern
@export var wall_random_flip: bool = false
# defaults match room_base.tscn's current values so unset floors look unchanged
@export var background_color: Color = Color(0.094, 0.039, 0.067, 1.0)
## 2D drifting-mist particle layer over the play area
@export var misty_background_enabled: bool = true

@export_category("3D Background")
## key SpotLight3D color; alpha 0 = derive a softened tint from wall_modulate
@export var bg_key_light_color: Color = Color(0, 0, 0, 0)
## fog color; alpha 0 = keep the bg_3d scene default
@export var bg_fog_color: Color = Color(0, 0, 0, 0)
## fog density; negative = keep the bg_3d scene default
@export var bg_fog_density: float = -1.0
## glow intensity; negative = keep the bg_3d scene default
@export var bg_glow_intensity: float = -1.0
## tonemap exposure; negative = keep the bg_3d scene default
@export var bg_tonemap_exposure: float = -1.0
## procedural sky top color; alpha 0 = keep the bg_3d scene default
@export var bg_sky_top_color: Color = Color(0, 0, 0, 0)
## procedural sky horizon color; alpha 0 = keep the bg_3d scene default
@export var bg_sky_horizon_color: Color = Color(0, 0, 0, 0)
## 3D column albedo; alpha 0 = derive a darkened/desaturated tint from wall_modulate
@export var bg_box_color: Color = Color(0, 0, 0, 0)
## 3D bg saturation via WorldEnvironment adjustments (1 = unchanged, <1 desaturates); negative = keep scene default
@export var bg_saturation: float = -1.0
