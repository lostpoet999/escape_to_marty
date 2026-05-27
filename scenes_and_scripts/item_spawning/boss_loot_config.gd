class_name BossLootConfig extends Resource

# tier weights used for the random rolls — same shape as floor's normal spawn_weight
@export var tier_weights: SpawnWeights
# how many weighted-tier items to roll (in addition to guaranteed_items)
@export var random_drop_count: int = 1
# always spawned regardless of weights
@export var guaranteed_items: Array[BaseItem]
