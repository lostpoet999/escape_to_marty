class_name BaseItem extends Resource

enum RarityType{
	COMMON,
	UNCOMMON,
	RARE,
	VERY_RARE	
}

@export var powerup_name: String
@export var rarity: RarityType
@export var min_floor: int
@export var inventory_icon: Texture2D
