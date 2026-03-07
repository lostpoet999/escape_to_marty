extends Line2D

@export var max_points = 64

func _process(_delta):
	add_point(get_parent().global_position)
	if points.size() > max_points:
		remove_point(0)
