extends Node3D

## tint for the sparks and shards; the puff stays white like the 2d fx family
@export var body_color: Color = Color(0.92156863, 0.92941177, 0.9137255)
## seconds the burst lives before the fx frees itself
@export var cleanup_time: float = 1.0

const SHARD_TEXTURES: Array[Texture2D] = [
	preload("res://scenes_and_scripts/bricks/brick_vfx/gem-shard-1.png"),
	preload("res://scenes_and_scripts/bricks/brick_vfx/gem-shard-2.png"),
	preload("res://scenes_and_scripts/bricks/brick_vfx/gem-shard-3.png"),
	preload("res://scenes_and_scripts/bricks/brick_vfx/gem-shard-4.png"),
	preload("res://scenes_and_scripts/bricks/brick_vfx/gem-shard-5.png"),
	preload("res://scenes_and_scripts/bricks/brick_vfx/gem-shard-6.png"),
]

func _ready() -> void:
	add_child(_make_sparks())
	add_child(_make_puff())
	for texture: Texture2D in SHARD_TEXTURES:
		add_child(_make_shard(texture))
	var tween: Tween = create_tween()
	tween.tween_interval(cleanup_time)
	tween.tween_callback(queue_free)

func _make_sparks() -> CPUParticles3D:
	var sparks: CPUParticles3D = _make_emitter(64, _soft_texture(GradientTexture2D.FILL_RADIAL), 0.04, body_color)
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sparks.emission_box_extents = Vector3(0.64, 0.64, 0.05)
	sparks.spread = 180.0
	sparks.initial_velocity_min = 0.1
	sparks.initial_velocity_max = 0.25
	sparks.scale_amount_min = 4.0
	sparks.scale_amount_max = 8.0
	return sparks

func _make_puff() -> CPUParticles3D:
	var puff: CPUParticles3D = _make_emitter(1, _soft_texture(GradientTexture2D.FILL_SQUARE), 0.64, Color.WHITE)
	puff.spread = 180.0
	puff.scale_amount_min = 2.0
	puff.scale_amount_max = 2.0
	var grow: Curve = Curve.new()
	grow.add_point(Vector2(0.0, 0.0))
	grow.add_point(Vector2(0.25, 0.8))
	grow.add_point(Vector2(1.0, 1.0))
	puff.scale_amount_curve = grow
	return puff

func _make_shard(texture: Texture2D) -> CPUParticles3D:
	var shard: CPUParticles3D = _make_emitter(1, texture, 0.32, body_color)
	shard.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	shard.emission_box_extents = Vector3(0.64, 0.64, 0.05)
	shard.direction = Vector3(0.0, 1.0, 0.0)
	shard.spread = 90.0
	shard.gravity = Vector3(0.0, -8.0, 0.0)
	shard.initial_velocity_min = 1.0
	shard.initial_velocity_max = 2.0
	shard.angular_velocity_min = 180.0
	shard.angular_velocity_max = 420.0
	return shard

func _make_emitter(amount: int, texture: Texture2D, quad_size: float, tint: Color) -> CPUParticles3D:
	var emitter: CPUParticles3D = CPUParticles3D.new()
	emitter.amount = amount
	emitter.lifetime = 1.0
	emitter.one_shot = true
	emitter.explosiveness = 1.0
	emitter.local_coords = true
	emitter.gravity = Vector3.ZERO
	emitter.color = tint
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	emitter.color_ramp = ramp
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(quad_size, quad_size)
	quad.material = _make_material(texture)
	emitter.mesh = quad
	return emitter

func _make_material(texture: Texture2D) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.disable_fog = true
	material.disable_receive_shadows = true
	material.albedo_texture = texture
	return material

func _soft_texture(fill_mode: GradientTexture2D.Fill) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = fill_mode
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.0, 0.0)
	return texture
