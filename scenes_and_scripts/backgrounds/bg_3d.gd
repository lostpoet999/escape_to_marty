extends Node3D

const offset: Vector2 = Vector2(260, 0)

## how far the floor tint is darkened toward black before it becomes box albedo
@export var bg3d_box_darken: float = 0.2
## how far the floor tint is desaturated toward gray before it becomes box albedo
@export var bg3d_box_desaturate: float = 0.3
## how far a derived key light is whitened toward neutral so it tints rather than washes
@export var bg3d_key_whiten: float = 0.4
## camera pitch in degrees; positive tilts the view up toward the sky
@export var bg3d_camera_pitch_deg: float = 25.0

@onready var camera_3d: Camera3D = $Camera3D
@onready var lights: Node3D = $Lights
@onready var first_box: MeshInstance3D = $World/MeshInstance3D
@onready var key_light: SpotLight3D = $World/SpotLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var world: Node3D = $World

func _ready() -> void:
	var pitch: Transform3D = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(bg3d_camera_pitch_deg)), Vector3.ZERO)
	camera_3d.rotation_degrees.x = bg3d_camera_pitch_deg
	world.transform = pitch * world.transform
	lights.transform = pitch * lights.transform
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

	_apply_floor_theme()

func _apply_floor_theme() -> void:
	var fd: FloorData = GameManager.floor_data
	if fd == null:
		return
	var mat: StandardMaterial3D = (first_box.mesh as BoxMesh).material as StandardMaterial3D
	if mat != null:
		mat.albedo_color = _box_albedo_from_tint(fd.wall_modulate, bg3d_box_darken, bg3d_box_desaturate)
	if fd.bg_key_light_color.a > 0.0:
		key_light.light_color = fd.bg_key_light_color
	else:
		key_light.light_color = fd.wall_modulate.lerp(Color.WHITE, bg3d_key_whiten)
	var env: Environment = world_environment.environment
	if fd.bg_fog_color.a > 0.0:
		env.fog_light_color = fd.bg_fog_color
	if fd.bg_fog_density >= 0.0:
		env.fog_density = fd.bg_fog_density
	if fd.bg_glow_intensity >= 0.0:
		env.glow_intensity = fd.bg_glow_intensity
	if fd.bg_tonemap_exposure >= 0.0:
		env.tonemap_exposure = fd.bg_tonemap_exposure

func _box_albedo_from_tint(tint: Color, darken: float, desaturate: float) -> Color:
	var c: Color = tint.darkened(darken)
	var gray: float = c.get_luminance()
	c = c.lerp(Color(gray, gray, gray, c.a), desaturate)
	c.a = 1.0
	return c

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not camera_3d: return
	if not BG3DRemote.is_active(): return
	
	var mouse_pos = BG3DRemote.get_current_position()
	
	var pos: Vector2 = (mouse_pos - offset) * 0.001
	
	camera_3d.position = Vector3(pos.x, pos.y, 0.0)
