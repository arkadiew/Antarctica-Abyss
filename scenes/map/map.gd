extends MeshInstance3D

var noise = FastNoiseLite.new()

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.01
	generate_terrain()
	
	# Добавление источника света для проверки
	var light = DirectionalLight3D.new()
	light.rotation = Vector3(-PI/4, PI/4, 0)  # Наклон света
	add_child(light)

func generate_terrain():
	var plane_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var uvs = PackedVector2Array()
	var size = 100.0  # Размер террейна
	var resolution = 50  # Количество вершин на сторону

	# Генерация вершин и UV-координат
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var x_pos = (x * size / resolution) - (size / 2.0)
			var z_pos = (z * size / resolution) - (size / 2.0)
			var height = noise.get_noise_2d(x_pos, z_pos) * 10.0
			vertices.append(Vector3(x_pos, height, z_pos))
			uvs.append(Vector2(float(x) / resolution, float(z) / resolution))

	# Генерация индексов
	for z in range(resolution):
		for x in range(resolution):
			var i = x + z * (resolution + 1)
			indices.append_array([i, i + 1, i + resolution + 1])
			indices.append_array([i + 1, i + resolution + 2, i + resolution + 1])

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs

	# Создание поверхности
	plane_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Создание и настройка материала
	var material = StandardMaterial3D.new()
	var texture_path = "res://scenes/map/textures/sand01_BaseColor.jpg"
	var texture = load(texture_path)
	if texture == null:
		push_error("Failed to load texture at '" + texture_path + "'")
		material.albedo_color = Color(1, 0, 0)  # Красный цвет для диагностики
	else:
		material.albedo_texture = texture
		material.uv1_scale = Vector3(10.0, 10.0, 10.0)
		material.uv1_offset = Vector3(0.0, 0.0, 0.0)

	# Включение Unshaded для тестирования (отключает влияние света)
	# material.flags_unshaded = true  # Раскомментируйте для теста

	plane_mesh.surface_set_material(0, material)
	self.mesh = plane_mesh

	# Добавление коллизии
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
