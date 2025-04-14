# This makes it a 3D node that can spawn stuff in a 3D space
extends Node3D

# List of object scenes you can set in the editor (like curiosities and stones)
@export var object_scenes: Array[PackedScene] = [
	preload("res://scenes/object/curiosity.tscn"),  # Curiosity object
	preload("res://scenes/object/stone.tscn")       # Stone object
]
@export var object_count: int = 20  # How many objects to spawn
@export var spawn_area: Area3D  # The 3D area where objects will pop up
@export var background_music: AudioStream = preload("res://sounds/fon.mp3")

# Runs when the node first loads
func _ready():
	
	# If no spawn area is set, try to grab one from the node’s kids
	if not spawn_area:
		spawn_area = $Area3D as Area3D
		# If that fails, complain and stop
		if not spawn_area:
			print("Oops: spawn_area node not found or isn’t an Area3D!")
			return
	# Set up and play background music
	if background_music:
		var audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "BackgroundMusic"
		audio_player.stream = background_music
		audio_player.autoplay = true
		background_music.loop = true
		add_child(audio_player)
		audio_player.global_transform.origin = spawn_area.global_transform.origin  # Center it in the spawn area
	else:
		print("No background music assigned!")
	# Start spawning the objects
	generate_objects()

# Spawns all the objects in the area
func generate_objects():
	# Check if we’ve got scenes and an area to work with
	if object_scenes.is_empty() or not spawn_area:
		print("Uh-oh: need object scenes and a spawn area to work!")
		return

	# Grab the collision shape (a box) from the spawn area
	var collision_shape = spawn_area.get_node("CollisionShape3D").shape as BoxShape3D
	if not collision_shape:
		print("Dang: CollisionShape3D not found in spawn_area!")
		return

	# Get the center and size of the spawn area
	var area_position = spawn_area.global_transform.origin
	var area_extents = collision_shape.extents

	# Keep track of where we’ve put stuff
	var placed_objects = []

	# Try to spawn the set number of objects
	for i in range(object_count):
		var attempts = 0
		var max_attempts = 50  # Give up after 50 tries
		var placed = false

		# Keep trying until we place it or run out of attempts
		while attempts < max_attempts and not placed:
			# Pick a random spot in the area (only X and Z, Y stays 0)
			var x = randf_range(-area_extents.x, area_extents.x)
			var z = randf_range(-area_extents.z, area_extents.z)
			var position = area_position + Vector3(x, 0, z)
			# Check if this spot’s free
			if not is_overlapping(position, placed_objects):
				# Pick a random object from the list
				var random_index = randi() % object_scenes.size()
				var object_scene = object_scenes[random_index]
				# Make a container node to hold the object
				var container = Node3D.new()
				container.name = "container"
				add_child(container)
				# Spawn the object and put it in the container
				var new_object = object_scene.instantiate()
				container.add_child(new_object)
				new_object.global_transform.origin = position  # Set its position
				placed_objects.append(new_object)  # Add it to the list
				placed = true  # Success!
			attempts += 1  # One more try down

		# If we couldn’t place it, let us know
		if not placed:
			print("Couldn’t place an object after ", max_attempts, " tries")

# Checks if a spot is too close to other objects
func is_overlapping(position: Vector3, placed_objects: Array) -> bool:
	for obj in placed_objects:
		# Look for an Area3D on the object
		var obj_area = obj.get_node_or_null("Area3D") as Area3D
		if obj_area:
			# If it’s got a box-shaped collision area...
			var obj_collision_shape = obj_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if obj_collision_shape and obj_collision_shape.shape is BoxShape3D:
				var obj_extents = (obj_collision_shape.shape as BoxShape3D).extents
				var obj_position = obj.global_transform.origin
				# Check if the new spot overlaps this object’s box
				var dx = abs(position.x - obj_position.x)
				var dz = abs(position.z - obj_position.z)
				if dx < obj_extents.x and dz < obj_extents.z:
					return true  # Yup, it’s overlapping
		else:
			# If no Area3D, just use a default distance check
			var default_radius = 1.0  # Assume objects are about 1 unit wide
			var obj_position = obj.global_transform.origin
			var distance = position.distance_to(obj_position)
			if distance < default_radius:
				return true  # Too close!
	return false  # All clear!
