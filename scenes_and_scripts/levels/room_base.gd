extends Node2D

var stars_cleared: bool = false
var bricks_cleared: bool = false
var stars_in_level: int = 0

func _ready() -> void:
	Signalbus.stars_updated.emit()
	Signalbus.score_updated.emit()
	Signalbus.player_health_updated.emit()
	Signalbus.brick_destroyed.connect(_on_brick_destroyed)
	Signalbus.star_collected.connect(update_stars_in_level)
	Signalbus.star_spawned.connect(update_stars_in_level)

func check_level_cleared() -> void: #let gamemanager know level is cleared
	if stars_cleared && bricks_cleared:
		Signalbus.level_cleared.emit()

func update_stars_in_level(amount: int) -> void:
	stars_in_level += amount
	if stars_in_level <= 0:
		stars_cleared = true
		check_level_cleared()
	else:
		stars_cleared = false

func _on_brick_destroyed() -> void:
	var bricks_left: int = get_tree().get_nodes_in_group("bricks").size()
	if bricks_left <= 1:
		bricks_cleared = true
		check_level_cleared()

#reconcile north,south, east, west
	#read level scene file
	#know what floor i am on
	#know what room i am in
	#search room entries for floor i am on
	#read the directions:
		#if door north place door scene
		#else place wall scene
