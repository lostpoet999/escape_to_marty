extends Line2D

## Hard cap on stored points (safety / perf). Real length is governed by the
## speed-driven target below; this only stops runaway growth.
@export var max_points: int = 200
## World distance between successive trail samples. Density is spatial, not
## per-frame, so the trail looks identical at any framerate. Smaller = smoother.
@export var sample_spacing: float = 4.0
## Trail length (world units) when the ball is at min_speed (slow / just launched).
@export var min_length: float = 120.0
## Trail length (world units) when the ball is at max_speed.
@export var max_length: float = 570.0
## Speed the trail starts growing from (match ball initial_speed).
@export var min_speed: float = 500.0
## Speed the trail reaches max_length at (match ball max_speed).
@export var max_speed: float = 1500.0
## A single-frame jump larger than this means the ball teleported (room reset,
## warp) — clear the trail so it doesn't streak across the screen.
@export var teleport_threshold: float = 200.0

func _process(_delta: float) -> void:
	var ball: Node2D = get_parent() as Node2D
	var pos: Vector2 = ball.global_position

	# Detect teleports and restart the trail cleanly.
	if points.size() > 0 and points[points.size() - 1].distance_to(pos) > teleport_threshold:
		clear_points()

	# Distance-based sampling: keep the head glued to the ball, but only commit a
	# new fixed-spacing point once the ball has travelled sample_spacing units.
	if points.size() < 2:
		add_point(pos)
	elif points[points.size() - 2].distance_to(pos) >= sample_spacing:
		add_point(pos)
	else:
		set_point_position(points.size() - 1, pos)

	# Target length is a straight lerp on ball speed: small when slow, long when
	# fast. get() so a scriptless ball (e.g. the decorative menu ball) degrades to
	# a min-length trail instead of erroring.
	var vel: Variant = ball.get("velocity")
	var speed: float = (vel as Vector2).length() if vel is Vector2 else 0.0
	var t: float = clampf((speed - min_speed) / (max_speed - min_speed), 0.0, 1.0)
	_trim_to_length(lerpf(min_length, max_length, t))

	# Safety cap.
	while points.size() > max_points:
		remove_point(0)

## Drop points from the tail (oldest, index 0) until the polyline measured back
## from the head fits within max_len world units.
func _trim_to_length(max_len: float) -> void:
	var total: float = 0.0
	for i in range(points.size() - 1, 0, -1):
		total += points[i].distance_to(points[i - 1])
		if total > max_len:
			for _k in range(i):
				remove_point(0)
			return
