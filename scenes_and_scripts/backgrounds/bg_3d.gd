extends Node3D

const offset: Vector2 = Vector2(260, 0)

@onready var camera_3d: Camera3D = $Camera3D
@onready var lights: Node3D = $Lights

func _ready() -> void:
	var t: Tween = lights.create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(lights, "position:z", lights.position.z + 20, 9.0)
	t.tween_property(lights, "position:z", lights.position.z + 25, 4.0)
	t.tween_property(lights, "position:z", lights.position.z, 7.0)
	t.tween_property(lights, "position:z", lights.position.z - 2, 3.0)
	
	var xt: Tween = lights.create_tween()
	xt.set_loops()
	xt.set_trans(Tween.TRANS_SINE)
	xt.tween_property(lights, "position:y", lights.position.y + 1, 3.0)
	xt.tween_property(lights, "position:y", lights.position.y + 3, 3.0)
	xt.tween_property(lights, "position:y", lights.position.y, 6.0)
	xt.tween_property(lights, "position:y", lights.position.y - 1, 3.0)
	xt.tween_property(lights, "position:y", lights.position.y - 3, 5.0)
	xt.tween_property(lights, "position:y", lights.position.y, 2.5)
	
	var rt: Tween = lights.create_tween()
	rt.set_loops()
	rt.set_trans(Tween.TRANS_SINE)
	rt.tween_property(lights, "rotation:z", lights.rotation.z + deg_to_rad(3), 3.0)
	rt.tween_property(lights, "rotation:z", lights.rotation.z + deg_to_rad(5), 3.0)
	rt.tween_property(lights, "rotation:z", lights.rotation.z, 6.0)
	rt.tween_property(lights, "rotation:z", lights.rotation.z - deg_to_rad(3), 3.0)
	rt.tween_property(lights, "rotation:z", lights.rotation.z - deg_to_rad(6), 5.0)
	rt.tween_property(lights, "rotation:z", lights.rotation.z - deg_to_rad(2), 2.5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not camera_3d: return
	if not BG3DRemote.is_active(): return
	
	var mouse_pos = BG3DRemote.get_current_position()
	
	var pos: Vector2 = (mouse_pos - offset) * 0.001
	
	camera_3d.position = Vector3(pos.x, pos.y, 0.0)
