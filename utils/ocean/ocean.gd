extends Node3D
class_name FishSpawner

# Сцены для спавна
@export var fish_scenes: Array[PackedScene] = [
	preload("res://scenes/fish/cod.tscn"),
	preload("res://scenes/fish/haddock.tscn")
]
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://scenes/fish/giant_squid.tscn")
]
@export var max_fish: int = 30
@export var max_enemies: int = 6
@export var spawn_radius: float = 5.0
@export var enemy_spawn_chance: float = 1.0 # Set to 1.0 for testing
@export var avoid_overlap: bool = false # Disabled for testing
@export var overlap_check_radius: float = 0.5

var fish_count: int = 0
var enemy_count: int = 0
var spawn_areas: Array[Node] = [] # Stores nodes in the "swimmable_area" group

func _ready() -> void:
	# Проверяем, есть ли сцены для спавна
	if fish_scenes.is_empty() and enemy_scenes.is_empty():
		push_error("FishSpawner: Нет сцен для спавна!")
		return
	
	# Находим все узлы в группе "swimmable_area"
	spawn_areas = get_tree().get_nodes_in_group("swimmable_area")
	if spawn_areas.is_empty():
		push_error("FishSpawner: Не найдены узлы в группе 'swimmable_area'!")
		return
	
	# Проверяем, что каждый узел имеет CollisionShape3D
	for area in spawn_areas:
		if not area is Area3D:
			push_error("FishSpawner: Узел ", area.name, " в группе 'swimmable_area' не является Area3D!")
			return
		var collision_shape = area.get_node("CollisionShape3D") as CollisionShape3D
		if not collision_shape or not collision_shape.shape:
			push_error("FishSpawner: Узел ", area.name, " не имеет валидного CollisionShape3D!")
			return
	
	print("FishSpawner: Найдено ", spawn_areas.size(), " зон спавна в группе 'swimmable_area'")
	_spawn_all()

func _spawn_all() -> void:
	var enemies_to_spawn = max_enemies if not enemy_scenes.is_empty() else 0
	for i in range(enemies_to_spawn):
		if randf() < enemy_spawn_chance:
			_spawn_instance(true)
		if i % 5 == 0:
			await get_tree().create_timer(0.01).timeout
	
	var fish_to_spawn = max_fish if not fish_scenes.is_empty() else 0
	for i in range(fish_to_spawn):
		_spawn_instance(false)
		if i % 5 == 0:
			await get_tree().create_timer(0.01).timeout

func _generate_unique_name(base_name: String) -> String:
	var counter = 1
	var unique_name = base_name
	while get_tree().current_scene.get_node_or_null(unique_name):
		unique_name = "%s_%d" % [base_name, counter]
		counter += 1
	return unique_name

func _spawn_instance(is_enemy: bool) -> void:
	var spawn_data = _get_random_spawn_position()
	var spawn_pos = spawn_data[0] as Vector3
	var spawn_area = spawn_data[1] as Area3D
	if spawn_pos == Vector3.ZERO:
		push_error("FishSpawner: Не удалось найти позицию для спавна")
		return
	
	if avoid_overlap and _check_overlap(spawn_pos, spawn_area):
		print("FishSpawner: Пересечение при спавне, пропуск")
		return
	
	var scene_array = enemy_scenes if is_enemy else fish_scenes
	if scene_array.is_empty():
		push_error("FishSpawner: Пустой массив сцен для ", "врагов" if is_enemy else "рыб")
		return
	
	var selected_scene = scene_array[randi() % scene_array.size()]
	var instance = selected_scene.instantiate() as Node3D
	if not instance:
		push_error("FishSpawner: Не удалось создать экземпляр сцены: ", selected_scene.resource_path)
		return
	
	var base_name = "Enemy" if is_enemy else "Fish"
	var instance_name = _generate_unique_name(base_name)
	instance.name = instance_name
	print("FishSpawner: Создан экземпляр ", instance_name, " на позиции ", spawn_pos, " в зоне ", spawn_area.name)
	
	if instance is BaseFish:
		instance.center_position = spawn_area.global_position
		instance.bound_radius = spawn_radius
	
	# Деферрированное добавление в сцену
	get_tree().current_scene.call_deferred("add_child", instance)
	# Деферрированная установка позиции
	instance.call_deferred("set", "global_position", spawn_pos)
	
	if is_enemy:
		enemy_count += 1
	else:
		fish_count += 1
	instance.tree_exited.connect(_on_instance_exited.bind(is_enemy))

func _get_random_spawn_position() -> Array:
	if spawn_areas.is_empty():
		return [Vector3.ZERO, null]

	# Случайно выбираем одну зону спавна
	var selected_area = spawn_areas[randi() % spawn_areas.size()] as Area3D
	var collision_shape = selected_area.get_node("CollisionShape3D") as CollisionShape3D
	if not collision_shape or not collision_shape.shape:
		push_error("FishSpawner: Отсутствует CollisionShape3D в зоне ", selected_area.name)
		return [Vector3.ZERO, null]

	var shape = collision_shape.shape
	var spawn_pos = selected_area.global_position
	var max_attempts = 10 # Ограничим количество попыток, чтобы избежать бесконечного цикла

	for attempt in range(max_attempts):
		# Генерируем позицию в зависимости от формы зоны
		if shape is BoxShape3D:
			var extents = (shape as BoxShape3D).size * 0.5
			spawn_pos = selected_area.global_position + Vector3(
				randf_range(-extents.x, extents.x),
				randf_range(-extents.y, extents.y),
				randf_range(-extents.z, extents.z)
			)
		elif shape is SphereShape3D:
			var radius = (shape as SphereShape3D).radius
			var random_dir = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			spawn_pos = selected_area.global_position + random_dir * randf_range(0.0, radius)
		else:
			push_error("FishSpawner: Неподдерживаемая форма CollisionShape3D в зоне ", selected_area.name)
			return [selected_area.global_position, selected_area]

		# Проверяем, не попадает ли позиция в зону "no_water_effect_zone"
		if not _is_in_no_water_effect_zone(spawn_pos):
			return [spawn_pos, selected_area]

	push_warning("FishSpawner: Не удалось найти позицию вне 'no_water_effect_zone' после ", max_attempts, " попыток")
	return [Vector3.ZERO, null]

func _is_in_no_water_effect_zone(position: Vector3) -> bool:
	var no_water_zones = get_tree().get_nodes_in_group("no_water_effect_zone")
	for zone in no_water_zones:
		if not zone is Area3D:
			continue
		var area = zone as Area3D
		var collision_shape = area.get_node("CollisionShape3D") as CollisionShape3D
		if not collision_shape or not collision_shape.shape:
			continue

		# Проверяем, находится ли точка внутри формы зоны
		var shape = collision_shape.shape
		var local_pos = area.global_transform.affine_inverse() * position

		if shape is BoxShape3D:
			var extents = (shape as BoxShape3D).size * 0.5
			if abs(local_pos.x) <= extents.x and abs(local_pos.y) <= extents.y and abs(local_pos.z) <= extents.z:
				return true
		elif shape is SphereShape3D:
			var radius = (shape as SphereShape3D).radius
			if local_pos.length() <= radius:
				return true

	return false

func _check_overlap(position: Vector3, spawn_area: Area3D) -> bool:
	var physics = get_world_3d().direct_space_state
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = overlap_check_radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere_shape
	query.transform = Transform3D(Basis(), position)
	query.collision_mask = 1 # Убедитесь, что это соответствует слою рыб/врагов
	query.exclude = [spawn_area] # Исключаем саму зону спавна
	var result = physics.intersect_shape(query)
	print("FishSpawner: Проверка пересечения, найдено объектов: ", result.size())
	return result.size() > 0

func _on_instance_exited(is_enemy: bool) -> void:
	print("FishSpawner: Удален ", "враг" if is_enemy else "рыба")
	if is_enemy:
		enemy_count = max(0, enemy_count - 1)
	else:
		fish_count = max(0, fish_count - 1)
