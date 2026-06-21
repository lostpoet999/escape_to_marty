class_name BG3DRemote extends Node2D

const INACTIVE: Vector2 = Vector2(-6900, -42000)
static var current_global_position: Vector2 = INACTIVE

func _process(_delta: float) -> void: current_global_position = global_position
func _exit_tree() -> void: current_global_position = INACTIVE

static func get_current_position() -> Vector2: return current_global_position
static func is_active() -> bool: return current_global_position != INACTIVE
