class_name DamageEffectRef extends Resource

@export var dmg_effect_scene: PackedScene

func instantiate_effect() -> BaseDamageEffect:
	return dmg_effect_scene.instantiate() as BaseDamageEffect
