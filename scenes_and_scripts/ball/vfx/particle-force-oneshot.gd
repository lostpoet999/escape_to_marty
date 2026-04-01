extends CPUParticles2D

# this script helps you edit one-shot particles in the godot editor
# by allowing you to leave one_shot OFF while iterating
# why? in godot if you set oneshot = true in the editor 
# it turns emitting OFF permanantly

func _ready() -> void:
	one_shot = true
	restart()
