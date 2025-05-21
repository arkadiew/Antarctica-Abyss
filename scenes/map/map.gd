extends MeshInstance3D

var noise = FastNoiseLite.new()
var cluster_noise = FastNoiseLite.new()
var seaweed_material = null
var animation_time = 0.0  # New variable to track animation time

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.01
	cluster_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	cluster_noise.frequency = 0.05  # Larger clusters
	generate_terrain()
	generate_seaweed()
	
	# Add a directional light
	var light = DirectionalLight3D.new()
	light.rotation = Vector3(-PI/4, PI/4, 0)
	light.light_energy = 0.5
	light.light_color = Color(0.2, 0.5, 0.6)
	add_child(light)

func generate_terrain():
	var plane_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	var size = 100.0  # Terrain size
	var resolution = 50  # Number of vertices per side

	# Generate vertices and UV coordinates
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var x_pos = (x * size / resolution) - (size / 2.0)
			var z_pos = (z * size / resolution) - (size / 2.0)
			var height = noise.get_noise_2d(x_pos, z_pos) * 10.0
			vertices.append(Vector3(x_pos, height, z_pos))
			uvs.append(Vector2(float(x) / resolution, float(z) / resolution))

	# Generate indices
	for z in range(resolution):
		for x in range(resolution):
			var i = x + z * (resolution + 1)
			indices.append_array([i, i + 1, i + resolution + 1])
			indices.append_array([i + 1, i + resolution + 2, i + resolution + 1])

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs

	# Create surface
	plane_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Create and set material
	var material = StandardMaterial3D.new()
	var texture_path = "res://scenes/map/textures/sand01_BaseColor.jpg"
	var texture = load(texture_path)
	if texture == null:
		push_error("Failed to load texture at '" + texture_path + "'")
		material.albedo_color = Color(1, 0, 0)  # Red for diagnostics
	else:
		material.albedo_texture = texture
		material.uv1_scale = Vector3(10.0, 10.0, 10.0)
		material.uv1_offset = Vector3(0.0, 0.0, 0.0)

	plane_mesh.surface_set_material(0, material)
	self.mesh = plane_mesh

	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = ConcavePolygonShape3D.new()

	var faces = PackedVector3Array()
	for i in range(0, indices.size(), 3):
		faces.append(vertices[indices[i]])
		faces.append(vertices[indices[i + 1]])
		faces.append(vertices[indices[i + 2]])

	shape.set_faces(faces)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	self.add_child(static_body)

func is_position_in_no_water_zone(pos: Vector3) -> bool:
	var zones = get_tree().get_nodes_in_group("no_water_effect_zone")
	for zone in zones:
		if zone is Area3D:
			var collision_shape = zone.get_node("CollisionShape3D") if zone.has_node("CollisionShape3D") else null
			if collision_shape and collision_shape.shape is BoxShape3D:
				var box_shape = collision_shape.shape as BoxShape3D
				var box_extents = box_shape.extents
				var zone_global_transform = zone.global_transform
				var local_pos = zone_global_transform.affine_inverse() * pos
				if (abs(local_pos.x) <= box_extents.x and
					abs(local_pos.y) <= box_extents.y and
					abs(local_pos.z) <= box_extents.z):
					return true
	return false

func generate_seaweed():
	var size = 100.0
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	seaweed_material = ShaderMaterial.new()
	seaweed_material.shader = Shader.new()
	seaweed_material.shader.code = """
		shader_type spatial;
		render_mode cull_disabled, depth_draw_always;

		uniform float sway_amplitude = 0.4;
		uniform float sway_frequency = 1.2;
		uniform vec4 algae_color : source_color = vec4(0.0, 0.5, 0.2, 1.0);
		uniform float animation_time;  // Custom time uniform

		void vertex() {
			float sway = sin(animation_time * sway_frequency + VERTEX.y) * sway_amplitude * VERTEX.y;
			VERTEX.x += sway;
			VERTEX.z += sway * 0.5;
		}

		void fragment() {
			ALBEDO = algae_color.rgb;
			ALPHA = algae_color.a;
			ROUGHNESS = 0.8;
			METALLIC = 0.0;
		}
	"""
	# Optional seaweed texture code (unchanged)
	var seaweed_texture_path = "res://scenes/map/textures/seaweed.png"
	var seaweed_texture = load(seaweed_texture_path)
	if seaweed_texture:
		seaweed_material.set_shader_parameter("albedo_texture", seaweed_texture)
		seaweed_material.shader.code += """
			uniform sampler2D albedo_texture : source_color, filter_linear, repeat_enable;
			void fragment() {
				ALBEDO = texture(albedo_texture, UV).rgb * algae_color.rgb;
				ALPHA = texture(albedo_texture, UV).a;
				ROUGHNESS = 0.8;
				METALLIC = 0.0;
			}
		"""

	var grid_resolution = 40
	var grid_spacing = size / grid_resolution
	var half_size = size / 2.0

	for z in range(grid_resolution):
		for x in range(grid_resolution):
			var x_pos = (x * grid_spacing) - half_size + (grid_spacing / 2.0)
			var z_pos = (z * grid_spacing) - half_size + (grid_spacing / 2.0)
			var cluster_factor = (cluster_noise.get_noise_2d(x_pos, z_pos) + 1.0) / 2.0
			var height = noise.get_noise_2d(x_pos, z_pos) * 10.0

			if is_position_in_no_water_zone(Vector3(x_pos, height, z_pos)):
				continue

			if height < 0.0 and cluster_factor > 0.6:
				var seaweed = MeshInstance3D.new()
				var seaweed_mesh = ArrayMesh.new()
				var arrays = []
				arrays.resize(Mesh.ARRAY_MAX)
				var vertices = PackedVector3Array()
				var uvs = PackedVector2Array()
				var indices = PackedInt32Array()

				var height_scale = rng.randf_range(2.5, 6.0)
				var width = rng.randf_range(0.2, 0.5)
				vertices.append_array([
					Vector3(-width, 0, 0), Vector3(width, 0, 0),
					Vector3(width, height_scale, 0), Vector3(-width, height_scale, 0)
				])
				uvs.append_array([
					Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)
				])
				indices.append_array([0, 1, 2, 0, 2, 3])
				vertices.append_array([
					Vector3(0, 0, -width), Vector3(0, 0, width),
					Vector3(0, height_scale, width), Vector3(0, height_scale, -width)
				])
				uvs.append_array([
					Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)
				])
				indices.append_array([4, 5, 6, 4, 6, 7])

				arrays[Mesh.ARRAY_VERTEX] = vertices
				arrays[Mesh.ARRAY_TEX_UV] = uvs
				arrays[Mesh.ARRAY_INDEX] = indices
				seaweed_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

				seaweed.mesh = seaweed_mesh
				seaweed.material_override = seaweed_material

				seaweed.position = Vector3(x_pos, height, z_pos)
				seaweed.rotation = Vector3(0, rng.randf_range(0, 2 * PI), 0)
				seaweed.scale = Vector3(1, rng.randf_range(1.0, 2.0), 1)

				var color_factor = clamp((height + 10.0) / 8.0, 0.0, 1.0)
				seaweed_material.set_shader_parameter("algae_color", Color(0.0, 0.3 + 0.2 * color_factor, 0.1))

				add_child(seaweed)

func _process(delta):
	if seaweed_material:
		if not get_tree().paused:
			animation_time += delta  # Only update time when not paused
		seaweed_material.set_shader_parameter("animation_time", animation_time)
