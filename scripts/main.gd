extends Node3D

@export var object_scenes: Array[PackedScene] = [
	preload("res://scenes/object/curiosity.tscn"),
	preload("res://scenes/object/stone.tscn"),
	preload("res://scenes/repairable/repairable_object.tscn"),
	preload("res://scenes/box/cube.tscn")
]
@export var spawn_weights: Array[float] = [0.49, 0.49, 0.49, 0.49]
@export var object_count: int = 20
@export var spawn_area: Area3D
@export var background_music: AudioStream = preload("res://sounds/fon.mp3")
@export var background_music_base: AudioStream = preload("res://sounds/base.mp3")
@export var height_offset: float = 0.3

var base_music_player: AudioStreamPlayer3D
var background_music_player: AudioStreamPlayer3D
@onready var player = get_tree().get_first_node_in_group("player")
var is_player_in_no_water_zone: bool = false
var default_volume_db: float = 0.0
var reduced_volume_db: float = -25.0

const ICON_MAPPING = {
	"Curiosity": "curiosity",
	"Stone": "stone",
	"Pipe": "pipe",
	"Cube": "cube" 
}

func _ready() -> void:
	# Initialize spawn area
	if not spawn_area:
		spawn_area = $Area3D as Area3D
		if not spawn_area:
			push_error("Spawn area not found or not an Area3D!")
			return
	
	# Initialize background music
	if background_music:
		background_music_player = AudioStreamPlayer3D.new()
		background_music_player.name = "BackgroundMusic"
		background_music_player.stream = background_music
		if background_music_player.stream is AudioStreamMP3 or background_music_player.stream is AudioStreamWAV:
			background_music_player.stream.loop = true
		background_music_player.autoplay = true
		add_child(background_music_player)
		background_music_player.global_position = spawn_area.global_position
		default_volume_db = background_music_player.volume_db
	else:
		push_warning("Background music not assigned!")

	# Initialize base music
	if background_music_base:
		base_music_player = AudioStreamPlayer3D.new()
		base_music_player.name = "BaseMusic"
		base_music_player.stream = background_music_base
		if base_music_player.stream is AudioStreamMP3 or base_music_player.stream is AudioStreamWAV:
			base_music_player.stream.loop = true
		base_music_player.autoplay = false
		add_child(base_music_player)
		base_music_player.global_position = spawn_area.global_position
	else:
		push_warning("Base music for no_water_effect_zone not assigned!")

	# Validate spawn weights
	if spawn_weights.size() != object_scenes.size():
		push_warning("Spawn weights size does not match object scenes! Using equal weights.")
		spawn_weights.clear()
		spawn_weights.resize(object_scenes.size())
		spawn_weights.fill(1.0 / object_scenes.size())

	# Verify player
	if not player:
		push_error("Player node not found!")
		return

	# Connect no-water zones
	for zone in get_tree().get_nodes_in_group("no_water_effect_zone"):
		if zone is Area3D:
			zone.body_entered.connect(_on_no_water_zone_body_entered.bind(zone))
			zone.body_exited.connect(_on_no_water_zone_body_exited.bind(zone))

	# Wait for tasks to be registered
	await get_tree().process_frame
	generate_objects()

func _on_no_water_zone_body_entered(body: Node, zone: Area3D) -> void:
	if body == player and base_music_player and background_music_player:
		is_player_in_no_water_zone = true
		base_music_player.play()
		var tween = create_tween()
		tween.tween_property(background_music_player, "volume_db", reduced_volume_db, 0.5)
		print("Player entered no_water_effect_zone, base music started, background music reduced.")

func _on_no_water_zone_body_exited(body: Node, zone: Area3D) -> void:
	if body == player and base_music_player and background_music_player:
		is_player_in_no_water_zone = false
		base_music_player.stop()
		var tween = create_tween()
		tween.tween_property(background_music_player, "volume_db", default_volume_db, 0.5)
		print("Player exited no_water_effect_zone, base music stopped, background music restored.")

func is_position_in_no_water_zone(position: Vector3) -> bool:
	for zone in get_tree().get_nodes_in_group("no_water_effect_zone"):
		if zone is Area3D:
			var collision_shape = zone.get_node("CollisionShape3D").shape as BoxShape3D
			if collision_shape:
				var zone_extents = collision_shape.extents
				var zone_position = zone.global_position
				var local_pos = position - zone_position
				if local_pos.abs() < zone_extents:
					return true
	return false

func generate_objects() -> void:
	if object_scenes.is_empty() or not spawn_area:
		push_error("Object scenes or spawn area missing!")
		return

	var collision_shape = spawn_area.get_node("CollisionShape3D").shape as BoxShape3D
	if not collision_shape:
		push_error("CollisionShape3D not found in spawn_area!")
		return

	var area_position = spawn_area.global_position
	var area_extents = collision_shape.extents
	var placed_objects: Array[Node] = []
	var space_state = get_world_3d().direct_space_state

	# Task requirements
	var task_reqs = TaskManager.get_task_requirements()
	var required_objects: Dictionary = {
		"Stone": task_reqs.get("button_task", {}).get("items", {}).get("Stone", 0),
		"Curiosity": task_reqs.get("button_task", {}).get("items", {}).get("Curiosity", 0),
		"Pipe": max(2, task_reqs.get("pipe_repair", {}).get("pipe_count", 0))
	}

	var spawned_counts = {"Stone": 0, "Curiosity": 0, "Pipe": 0, "Cube": 0}
	var object_indices = {
		"Curiosity": 0,
		"Stone": 1,
		"Pipe": 2,
		"Cube": 3
	}

	# Spawn required objects
	for obj_type in required_objects.keys():
		while spawned_counts[obj_type] < required_objects[obj_type]:
			if not try_place_object(obj_type, object_indices, area_position, area_extents, placed_objects, space_state, spawned_counts, required_objects):
				push_warning("Failed to place %s after max attempts" % obj_type)
				break

	# Spawn remaining objects
	for i in range(placed_objects.size(), object_count):
		var chosen_type = choose_object_type(spawned_counts, required_objects, object_indices)
		if not try_place_object(chosen_type, object_indices, area_position, area_extents, placed_objects, space_state, spawned_counts, required_objects):
			push_warning("Failed to place object %d after max attempts" % i)

	print("Final spawn counts: ", spawned_counts)

func try_place_object(obj_type: String, indices: Dictionary, area_pos: Vector3, area_extents: Vector3, placed_objects: Array, space_state: PhysicsDirectSpaceState3D, spawned_counts: Dictionary, required_objects: Dictionary) -> bool:
	var max_attempts = 50
	for attempt in max_attempts:
		var position = area_pos + Vector3(
			randf_range(-area_extents.x, area_extents.x),
			0,
			randf_range(-area_extents.z, area_extents.z)
		)

		# Raycast to find ground
		var ray_origin = position + Vector3(0, 1000, 0)
		var ray_end = position + Vector3(0, -1000, 0)
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		var result = space_state.intersect_ray(query)
		if not result:
			continue

		position.y = result.position.y + height_offset
		if is_position_in_no_water_zone(position):
			continue

		if not is_overlapping(position, placed_objects):
			var chosen_type = obj_type if obj_type else choose_object_type(spawned_counts, required_objects, indices)
			var object_scene = object_scenes[indices[chosen_type]]
			var container = Node3D.new()
			container.name = "ObjectContainer_%d" % placed_objects.size()
			container.set_script(preload("res://scripts/object_container.gd"))
			add_child(container)
			var new_object = object_scene.instantiate()
			new_object.name = chosen_type
			new_object.add_to_group("minimap_objects")
			new_object.set_meta("minimap_icon", ICON_MAPPING[chosen_type])
			container.add_child(new_object)
			new_object.global_position = position
			placed_objects.append(new_object)
			spawned_counts[chosen_type] = spawned_counts.get(chosen_type, 0) + 1
			print("Spawned: %s at %s" % [chosen_type, new_object.get_path()])
			return true
	return false

func choose_object_type(spawned: Dictionary, required: Dictionary, indices: Dictionary) -> String:
	for type in required.keys():
		if spawned.get(type, 0) < required[type]:
			return type
	var total_weight = spawn_weights.reduce(func(acc, w): return acc + w, 0.0)
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	for i in spawn_weights.size():
		cumulative_weight += spawn_weights[i]
		if random_value <= cumulative_weight:
			return indices.keys()[i]
	return indices.keys()[spawn_weights.size() - 1]

func is_overlapping(position: Vector3, placed_objects: Array) -> bool:
	const DEFAULT_RADIUS = 1.0
	for obj in placed_objects:
		var obj_area = obj.get_node_or_null("Area3D") as Area3D
		if obj_area:
			var obj_collision_shape = obj_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if obj_collision_shape and obj_collision_shape.shape is BoxShape3D:
				var obj_extents = (obj_collision_shape.shape as BoxShape3D).extents
				var obj_position = obj.global_position
				var local_pos = position - obj_position
				if local_pos.abs() < obj_extents:
					return true
		else:
			var distance = position.distance_to(obj.global_position)
			if distance < DEFAULT_RADIUS:
				return true
	return false
