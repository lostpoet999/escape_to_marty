class_name BaseItem extends Resource

enum RarityType{
	COMMON,
	UNCOMMON,
	RARE,
	VERY_RARE	
}

@export var powerup_name: String
## The description that appears when you hover over the item in shop or free item screens
@export var shop_description: String
@export var rarity: RarityType
@export var min_floor: int
@export var inventory_icon: Texture2D
@export var cost: int
@export var removable: bool = true 
@export var reveals_adjacent_rooms: bool = false 
