class_name BallPowerUp extends Resource

enum RarityType{
	COMMON,
	UNCOMMON,
	RARE,
	VERY_RARE	
}

enum PowerUpTypes {
	BOUNCE,
	MOVEMENT,
	DAMAGE,
}

@export var powerup_name: String
@export var powerup_id: String
@export var inventory_icon: Texture2D
@export_group("Base Stats")
@export var global_damage_bonus: float
@export var global_damage_multi: float
@export var local_damage_bonus: float
@export var local_damage_multi: float

@export_group("Rarity & Type")
@export var rarity: RarityType
@export var powerup_type: PowerUpTypes

@export_group("Damage Effects")
@export var attached_effects: Array[DamageEffectRef]

func _to_string() -> String:
	return powerup_name + powerup_name
