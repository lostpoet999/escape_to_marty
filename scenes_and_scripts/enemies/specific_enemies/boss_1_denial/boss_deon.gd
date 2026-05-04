class_name BossDeon
extends Deon


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	Signalbus.deon_boss_cage_cleared.connect(_on_cage_cleared)

func _on_cage_cleared()->void:
	left_clamp_offset = 0 # from placed_enemy
	right_clamp_offset = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
