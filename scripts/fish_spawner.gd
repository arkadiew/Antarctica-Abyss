# This makes it a 3D node that can hold and manage other 3D stuff (like a fish spawner)
extends Node3D

# Lists of fish and enemy scenes you can set in the editor
@export var fish_scenes: Array[PackedScene] = [
	preload("res://scenes/fish/cod.tscn"),  # Cod fish scene
	preload("res://scenes/fish/haddock.tscn")  # Haddock fish scene
]
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://scenes/fish/Giant_squid.tscn")  # Giant squid enemy scene
]

# Spawning settings for fish
@export var fish_count: int = 20  # How many fish to start with
@export var spawn_interval: float = 3.0  # How often to spawn more fish (seconds)
@export var fish_per_wave: int = 10  # How many fish per spawn wave
@export var max_total_fish: int = 60  # Max fish allowed at once

# Spawning settings for enemies
@export var enemy_count: int = 5  # How many enemies to start with
@export var enemy_spawn_interval: float = 10.0  # How often to spawn enemies (seconds)
@export var enemy_per_wave: int = 2  # How many enemies per spawn wave
@export var max_total_enemies: int = 10  # Max enemies allowed at once

# Tracking how many fish and enemies are out there
var current_fish_count: int = 0  # Current fish in the scene
var current_enemy_count: int = 0  # Current enemies in the scene
var swimmable_area: Node  # The area where fish and enemies can swim
var spawn_timer: Timer  # Timer for fish spawning
var enemy_spawn_timer: Timer  # Timer for enemy spawning

# Runs when the spawner first loads
func _ready():
	# Wait until we find the swimmable area before doing anything
	await wait_for_swimmable_area()
	
	# Once we’ve got the area, spawn the starting fish and enemies
	spawn_fish(fish_count)
	spawn_enemies(enemy_count)

	# Set up a timer to spawn more fish later
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false  # Keeps running forever
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)  # Calls a function when it ticks
	spawn_timer.start()

	# Set up a timer for spawning enemies
	enemy_spawn_timer = Timer.new()
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.wait_time = enemy_spawn_interval
	enemy_spawn_timer.one_shot = false  # Keeps going
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)  # Calls enemy spawn function
	enemy_spawn_timer.start()

	# Turn on regular processing to keep an eye on things
	set_process(true)

# Waits until the swimmable area is found
func wait_for_swimmable_area() -> void:
	while true:
		swimmable_area = get_tree().get_first_node_in_group("fish")  # Look for the fish area
		if swimmable_area != null:
			return  # Found it, we’re good!
		else:
			# If not found, warn and wait a sec before checking again
			push_warning("SwimmableArea3D not found yet! Waiting...")
			await get_tree().create_timer(1.0).timeout

# Runs every frame to keep fish and enemies in bounds
func _process(delta):
	if swimmable_area == null:
		return  # No area yet, skip this

	# Check all kids (fish and enemies)
	for child in get_children():
		if child.is_in_group("fish") or child.is_in_group("enemy"):
			var current_position = child.global_transform.origin
			
			# If they’re outside the swim area...
			if not swimmable_area.is_point_in_area(current_position):
				# Push them back toward the center
				var direction_to_center = (swimmable_area.get_center() - current_position).normalized()
				child.global_transform.origin += direction_to_center * delta * 5.0  # Move back fast
				redirect_from_boundary(child, direction_to_center)
			else:
				# If they’re close to the edge, turn them around
				if is_near_boundary(child, current_position):
					var direction_to_center = (swimmable_area.get_center() - current_position).normalized()
					redirect_from_boundary(child, direction_to_center)

# Checks if something’s near the edge of the swim area
func is_near_boundary(child, position: Vector3) -> bool:
	var boundary_threshold = 1.0  # How close to the edge counts as “near”
	var distance_to_center = position.distance_to(swimmable_area.get_center())
	var max_distance = swimmable_area.get_max_distance_from_center()  # Max distance allowed
	return distance_to_center > (max_distance - boundary_threshold)  # True if near the edge

# Turns fish or enemies back toward the center
func redirect_from_boundary(child, direction_to_center: Vector3):
	if child.has_method("set_direction"):  # If they’ve got a custom direction method...
		child.set_direction(direction_to_center)  # Use it
	else:
		# Otherwise, smoothly turn them toward the center
		var target_rotation = atan2(direction_to_center.x, direction_to_center.z)
		child.rotation.y = lerp_angle(child.rotation.y, target_rotation, 0.1)

# Spawns more fish when the timer ticks
func _on_spawn_timer_timeout():
	if current_fish_count < max_total_fish:  # If we’re under the fish limit...
		# Figure out how many we can spawn without going over
		var allowed_fish_to_spawn = min(fish_per_wave, max_total_fish - current_fish_count)
		if allowed_fish_to_spawn > 0:
			spawn_fish(allowed_fish_to_spawn)  # Spawn ‘em!

# Spawns more enemies when the enemy timer ticks
func _on_enemy_spawn_timer_timeout():
	if current_enemy_count < max_total_enemies:  # If we’re under the enemy limit...
		# Figure out how many we can spawn
		var allowed_enemies_to_spawn = min(enemy_per_wave, max_total_enemies - current_enemy_count)
		if allowed_enemies_to_spawn > 0:
			spawn_enemies(allowed_enemies_to_spawn)  # Spawn ‘em!

# Spawns a batch of fish
func spawn_fish(count: int):
	if fish_scenes.is_empty():  # No fish scenes? Big problem!
		push_error("No fish scenes assigned. Spawning impossible!")
		return

	if swimmable_area == null:  # No swim area? Can’t spawn!
		push_error("No swimmable_area. Spawning impossible!")
		return

	for i in range(count):
		# Pick a random spot in the swim area
		var spawn_position = swimmable_area.get_random_point_in_area()
		if spawn_position == null:
			push_warning("Failed to get valid spawn point. Skipping...")
			continue

		# Pick a random fish type and spawn it
		var fish_scene = fish_scenes[randi() % fish_scenes.size()]
		var fish_instance = fish_scene.instantiate()
		fish_instance.add_to_group("fish")  # Tag it as a fish
		fish_instance.transform.origin = spawn_position  # Put it in the water
		add_child(fish_instance)  # Add it to the scene
		current_fish_count += 1  # Count it

# Spawns a batch of enemies
func spawn_enemies(count: int):
	if enemy_scenes.is_empty():  # No enemy scenes? Nope!
		push_error("No enemy scenes assigned. Spawning impossible!")
		return

	if swimmable_area == null:  # No swim area? Nope!
		push_error("No swimmable_area. Spawning impossible!")
		return

	for i in range(count):
		# Pick a random spot in the swim area
		var spawn_position = swimmable_area.get_random_point_in_area()
		if spawn_position == null:
			push_warning("Failed to get valid spawn point. Skipping...")
			continue

		# Pick a random enemy type and spawn it
		var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.add_to_group("enemy")  # Tag it as an enemy
		enemy_instance.transform.origin = spawn_position  # Drop it in
		add_child(enemy_instance)  # Add it to the scene
		current_enemy_count += 1  # Count it
