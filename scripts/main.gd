extends Node3D

@export var object_scenes: Array[PackedScene] = [
	preload("res://scenes/object/curiosity.tscn"),
	preload("res://scenes/object/stone.tscn"),
	preload("res://scenes/repairable/repairable_object.tscn")
]
@export var spawn_weights: Array[float] = [0.49, 0.49, 0.49]
@export var object_count: int = 20
@export var spawn_area: Area3D
@export var background_music: AudioStream = preload("res://sounds/fon.mp3")
@export var background_music_base: AudioStream = preload("res://sounds/base.mp3")
@export var height_offset: float = 0.3
var base_music_player: AudioStreamPlayer3D
var background_music_player: AudioStreamPlayer3D 
@onready var player = get_node_or_null("/root/main/Player")
var is_player_in_no_water_zone: bool = false
var default_volume_db: float = 0.0 
var reduced_volume_db: float = -25.0 

var icon_mapping = {
	"Curiosity": "curiosity",
	"Stone": "stone",
	"Pipe": "pipe"
}

func _ready():
	if not spawn_area:
		spawn_area = $Area3D as Area3D
		if not spawn_area:
			print("Ошибка: spawn_area не найден или не является Area3D!")
			return
	
	if background_music:
		background_music_player = AudioStreamPlayer3D.new()
		background_music_player.name = "BackgroundMusic"
		background_music_player.stream = background_music
		if background_music_player.stream is AudioStreamMP3 or background_music_player.stream is AudioStreamWAV:
			background_music_player.stream.loop = true
		background_music_player.autoplay = true
		add_child(background_music_player)
		background_music_player.global_transform.origin = spawn_area.global_transform.origin
		default_volume_db = background_music_player.volume_db 
	else:
		print("Музыка фона не назначена!")

	if background_music_base:
		base_music_player = AudioStreamPlayer3D.new()
		base_music_player.name = "BaseMusic"
		base_music_player.stream = background_music_base
		if base_music_player.stream is AudioStreamMP3 or base_music_player.stream is AudioStreamWAV:
			base_music_player.stream.loop = true
		base_music_player.autoplay = false
		add_child(base_music_player)
		base_music_player.global_transform.origin = spawn_area.global_transform.origin
	else:
		print("Музыка для no_water_effect_zone не назначена!")

	if spawn_weights.size() != object_scenes.size():
		print("Предупреждение: размер spawn_weights не соответствует object_scenes!")
		spawn_weights = []
		for i in range(object_scenes.size()):
			spawn_weights.append(1.0 / object_scenes.size())

	# Поиск игрока
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Ошибка: Игрок не найден!")
		return

	var no_water_zones = get_tree().get_nodes_in_group("no_water_effect_zone")
	for zone in no_water_zones:
		if zone is Area3D:
			zone.body_entered.connect(_on_no_water_zone_body_entered)
			zone.body_exited.connect(_on_no_water_zone_body_exited)

	# Ждем регистрации задач
	await get_tree().process_frame
	generate_objects()

func _on_no_water_zone_body_entered(body: Node) -> void:
	if body == player and base_music_player and background_music_player:
		is_player_in_no_water_zone = true
		base_music_player.play()
		var tween = create_tween()
		tween.tween_property(background_music_player, "volume_db", reduced_volume_db, 0.5)
		print("Игрок вошел в no_water_effect_zone, музыка base начала играть, фоновая музыка приглушена")

func _on_no_water_zone_body_exited(body: Node) -> void:
	if body == player and base_music_player and background_music_player:
		is_player_in_no_water_zone = false
		base_music_player.stop()
		var tween = create_tween()
		tween.tween_property(background_music_player, "volume_db", default_volume_db, 0.5)
		print("Игрок вышел из no_water_effect_zone, музыка base остановлена, фоновая музыка восстановлена")

func is_position_in_no_water_zone(position: Vector3) -> bool:
	var no_water_zones = get_tree().get_nodes_in_group("no_water_effect_zone")
	for zone in no_water_zones:
		if zone is Area3D:
			var collision_shape = zone.get_node("CollisionShape3D").shape as BoxShape3D
			if collision_shape:
				var zone_extents = collision_shape.extents
				var zone_position = zone.global_transform.origin
				var dx = abs(position.x - zone_position.x)
				var dy = abs(position.y - zone_position.y)
				var dz = abs(position.z - zone_position.z)
				if dx < zone_extents.x and dy < zone_extents.y and dz < zone_extents.z:
					return true
	return false

func generate_objects():
	if object_scenes.is_empty() or not spawn_area:
		print("Ошибка: нужны сцены объектов и зона спавна!")
		return

	var collision_shape = spawn_area.get_node("CollisionShape3D").shape as BoxShape3D
	if not collision_shape:
		print("Ошибка: CollisionShape3D не найден!")
		return

	var area_position = spawn_area.global_transform.origin
	var area_extents = collision_shape.extents
	var placed_objects = []
	var space_state = get_world_3d().direct_space_state
	var ray_origin = Vector3(0, 1000, 0)
	var ray_end = Vector3(0, -1000, 0)

	var task_reqs = TaskManager.get_task_requirements()
	var required_objects: Dictionary = {
		"Stone": 0,
		"Curiosity": 0,
		"Pipe": 0
	}
	if task_reqs.has("button_task"):
		var items = task_reqs["button_task"].get("items", {})
		required_objects["Stone"] = items.get("Stone", 0)
		required_objects["Curiosity"] = items.get("Curiosity", 0)
	if task_reqs.has("pipe_repair"):
		var pipe_count = task_reqs["pipe_repair"].get("pipe_count", 0)
		required_objects["Pipe"] = max(2, pipe_count)
		print("Требуется труб: ", required_objects["Pipe"])

	var spawned_counts = {"Stone": 0, "Curiosity": 0, "Pipe": 0}
	var object_indices = {
		"Curiosity": 0,
		"Stone": 1,
		"Pipe": 2
	}

	var priority_types = ["Stone", "Curiosity", "Pipe"]
	for obj_type in priority_types:
		while spawned_counts[obj_type] < required_objects[obj_type]:
			var attempts = 0
			var max_attempts = 100
			var placed = false

			while attempts < max_attempts and not placed:
				var x = randf_range(-area_extents.x, area_extents.x)
				var z = randf_range(-area_extents.z, area_extents.z)
				var position = area_position + Vector3(x, 0, z)

				ray_origin = Vector3(position.x, 1000, position.z)
				ray_end = Vector3(position.x, -1000, position.z)
				var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
				var result = space_state.intersect_ray(query)

				if result:
					position.y = result.position.y + height_offset
				else:
					attempts += 1
					continue

				if is_position_in_no_water_zone(position):
					attempts += 1
					continue

				if not is_overlapping(position, placed_objects):
					var object_scene = object_scenes[object_indices[obj_type]]
					var container = Node3D.new()
					container.name = "ObjectContainer_%d" % (placed_objects.size())
					container.set_script(preload("res://scripts/object_container.gd"))
					add_child(container)
					var new_object = object_scene.instantiate()
					new_object.name = "%s" % [obj_type]
					new_object.add_to_group("minimap_objects")
					new_object.set_meta("minimap_icon", icon_mapping[obj_type])
					print("Спавнер: Установлен minimap_icon для %s: %s" % [new_object.name, new_object.get_meta("minimap_icon")])
					container.add_child(new_object)
					new_object.global_transform.origin = position
					placed_objects.append(new_object)
					spawned_counts[obj_type] += 1
					placed = true
					print("Приоритетный спавн: ", obj_type, ", Путь: ", new_object.get_path())
				attempts += 1

			if not placed:
				print("Не удалось разместить ", obj_type, " после ", max_attempts, " попыток")

	for i in range(placed_objects.size(), object_count):
		var attempts = 0
		var max_attempts = 50
		var placed = false

		while attempts < max_attempts and not placed:
			var x = randf_range(-area_extents.x, area_extents.x)
			var z = randf_range(-area_extents.z, area_extents.z)
			var position = area_position + Vector3(x, 0, z)

			ray_origin = Vector3(position.x, 1000, position.z)
			ray_end = Vector3(position.x, -1000, position.z)
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			var result = space_state.intersect_ray(query)

			if result:
				position.y = result.position.y + height_offset
			else:
				attempts += 1
				continue

			if is_position_in_no_water_zone(position):
				attempts += 1
				continue

			if not is_overlapping(position, placed_objects):
				var object_type = choose_object_type(spawned_counts, required_objects, object_indices)
				var object_scene = object_scenes[object_indices[object_type]]
				var container = Node3D.new()
				container.name = "ObjectContainer_%d" % i
				container.set_script(preload("res://scripts/object_container.gd"))
				add_child(container)
				var new_object = object_scene.instantiate()
				new_object.name = "%s" % [object_type]
				new_object.add_to_group("minimap_objects")
				new_object.set_meta("minimap_icon", icon_mapping[object_type])
				print("Спавнер: Установлен minimap_icon для %s: %s" % [new_object.name, new_object.get_meta("minimap_icon")])
				container.add_child(new_object)
				new_object.global_transform.origin = position
				placed_objects.append(new_object)
				spawned_counts[object_type] += 1
				placed = true
				print("Спавн: ", object_type, ", Путь: ", new_object.get_path())
			attempts += 1

		if not placed:
			print("Не удалось разместить объект %d после %d попыток" % [i, max_attempts])

	print("Итоговое количество: ", spawned_counts)

func choose_object_type(spawned: Dictionary, required: Dictionary, indices: Dictionary) -> String:
	if spawned["Stone"] < required["Stone"]:
		return "Stone"
	if spawned["Curiosity"] < required["Curiosity"]:
		return "Curiosity"
	if spawned["Pipe"] < required["Pipe"]:
		return "Pipe"
	var total_weight = 0.0
	for weight in spawn_weights:
		total_weight += weight
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	for i in range(spawn_weights.size()):
		cumulative_weight += spawn_weights[i]
		if random_value <= cumulative_weight:
			var type = indices.keys()[i]
			return type
	return indices.keys()[spawn_weights.size() - 1]

func is_overlapping(position: Vector3, placed_objects: Array) -> bool:
	for obj in placed_objects:
		var obj_area = obj.get_node_or_null("Area3D") as Area3D
		if obj_area:
			var obj_collision_shape = obj_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if obj_collision_shape and obj_collision_shape.shape is BoxShape3D:
				var obj_extents = (obj_collision_shape.shape as BoxShape3D).extents
				var obj_position = obj.global_transform.origin
				var dx = abs(position.x - obj_position.x)
				var dz = abs(position.z - obj_position.z)
				if dx < obj_extents.x and dz < obj_extents.z:
					return true
		else:
			var default_radius = 1.0
			var obj_position = obj.global_transform.origin
			var distance = position.distance_to(obj_position)
			if distance < default_radius:
				return true
	return false
