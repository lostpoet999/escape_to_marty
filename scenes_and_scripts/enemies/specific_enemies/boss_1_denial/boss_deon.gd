class_name BossDeon
extends Deon

var stage: int = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	Signalbus.deon_boss_cage_cleared.connect(_on_cage_cleared)

func accept_damage(_damage: int, _dmg_type: Array[GameManager.PhaseType])->void:
	if stage >= 2:
		SFX.play_sound("player_hurt")
		take_damage_fx()
		denial_health -= 1
		if denial_health == 0:
			self.modulate = Color.WHITE
			self.modulate.a = 1.0
			stage += 1
		elif denial_health <= -1: die()

func _on_cage_cleared()->void:
	left_clamp_offset = 0 # from placed_enemy
	right_clamp_offset = 0
	Signalbus.blocker_moved.emit()
	stage += 1
