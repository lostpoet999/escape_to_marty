extends Line2D
@export var max_points: int = 64

func _process(_delta: float) -> void:
	var parent: Node2D = get_parent() as Node2D
	add_point(parent.global_position)
	if points.size() > max_points:
		remove_point(0)
