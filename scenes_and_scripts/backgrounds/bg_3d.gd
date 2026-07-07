extends Node3D

const parallax_rest: Vector2 = Vector2(1091, 923)
var cloud_material: StandardMaterial3D = preload("res://scenes_and_scripts/backgrounds/BG Objects/mat_cloud.tres")

## how far the floor tint is darkened toward black before it becomes cloud albedo
@export var bg3d_cloud_darken: float = 0.3
## how far the floor tint is desaturated toward gray before it becomes cloud albedo
@export var bg3d_cloud_desaturate: float = 0.15
## how far a derived key light is whitened toward neutral so it tints rather than washes
@export var bg3d_key_whiten: float = 0.4

@onready var camera_3d: Camera3D = $Camera3D
@onready var lights: Node3D = $Lights
@onready var key_light: SpotLight3D = $World/SpotLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var world: Node3D = $World
@onready var _camera_base: Vector3 = camera_3d.position

func _ready() -> void:
	var frame_guide: Node3D = camera_3d.get_node_or_null("FrameGuide")
	if frame_guide != null:
		frame_guide.queue_free()
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
	var albedo: Color
	if fd.bg_cloud_color.a > 0.0:
		albedo = fd.bg_cloud_color
	else:
		albedo = _cloud_albedo_from_tint(fd.wall_modulate, bg3d_cloud_darken, bg3d_cloud_desaturate)
	albedo.a = cloud_material.albedo_color.a
	cloud_material.albedo_color = albedo
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
	if env.sky != null:
		var sky_mat: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
		if sky_mat != null:
			if fd.bg_sky_top_color.a > 0.0:
				sky_mat.sky_top_color = fd.bg_sky_top_color
				sky_mat.ground_bottom_color = fd.bg_sky_top_color
			if fd.bg_sky_horizon_color.a > 0.0:
				sky_mat.sky_horizon_color = fd.bg_sky_horizon_color
				sky_mat.ground_horizon_color = fd.bg_sky_horizon_color
	if fd.bg_saturation >= 0.0:
		env.adjustment_enabled = true
		env.adjustment_saturation = fd.bg_saturation

func _cloud_albedo_from_tint(tint: Color, darken: float, desaturate: float) -> Color:
	var c: Color = tint.darkened(darken)
	var gray: float = c.get_luminance()
	return c.lerp(Color(gray, gray, gray, c.a), desaturate)

func _process(_delta: float) -> void:
	if not camera_3d: return
	if not BG3DRemote.is_active(): return
	
	var paddle_pos: Vector2 = BG3DRemote.get_current_position()

	var parallax: Vector2 = (paddle_pos - parallax_rest) * 0.00025

	camera_3d.position = _camera_base + Vector3(parallax.x, parallax.y, 0.0)
