class_name BorderWall
extends Area2D

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body is FallingEnemy:
		body.on_fall_landed()
