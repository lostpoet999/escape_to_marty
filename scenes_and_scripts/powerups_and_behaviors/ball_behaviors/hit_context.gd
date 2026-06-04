class_name HitContext extends RefCounted

var source: Node2D
var hit_point: Vector2
var collision_mask: int
var exclude: Array[RID]
var base_damage: float
var dmg_types: Array[GameManager.PhaseType]
var apply: Callable
