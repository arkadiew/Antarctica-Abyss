extends CSGBox3D

var start_position = Vector3()
var velocity = Vector3()
var speed = 0.3  # Calm normal fish speed
var max_speed = 0.5
var fish_bounds = 60.0
var wander_timer = 0.0
var wander_interval = 6.0
var turn_angle = 10.0
var retreat_distance = 0.2
var acceleration = 0.05
var deceleration = 0.05

# New features
var shoaling_radius = 5.0  # Distance to detect other fish
var points_of_interest = []  # List of Vector3 for interesting spots

var flee_distance = 10.0  # Distance to start fleeing
var predator = Vector3.ZERO  # Вместо null используем Vector3.ZERO

@onready var raycasts = [
	$RayCast3D,
	$RayCast3D4,
	$RayCast3D3,
	$RayCast3D2
]

func _ready():
	randomize()
	start_position = transform.origin
	set_random_velocity()
	enable_raycasting(true)

# Enhanced velocity setting with optional attraction to a point
func set_random_velocity(target: Vector3 = Vector3.ZERO):
	if target != Vector3.ZERO:  # Проверяем, есть ли целевая точка
		velocity = (target - transform.origin).normalized() * speed
	else:
		var random_direction = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		velocity = random_direction * speed


func _process(delta):
	# Check for predator and flee
	if predator != Vector3.ZERO and transform.origin.distance_to(predator) < flee_distance:
		flee_from_predator()
		return


	# Gradually adjust speed to simulate calm movement
	if velocity.length() < max_speed:
		velocity = velocity.normalized() * speed

	# Shoaling: Adjust velocity based on nearby fish
	align_with_neighbors()

	# Move the fish according to the velocity vector
	transform.origin += velocity * delta

	# Occasionally explore points of interest
	wander_timer += delta
	if wander_timer > wander_interval:
		wander_timer = 0
		if points_of_interest.size() > 0 and randi() % 2 == 0:  # 50% chance to visit
			var poi = points_of_interest[randi() % points_of_interest.size()]
			set_random_velocity(poi)
		else:
			set_random_velocity()

	# Keep the fish within the swimming boundary
	if transform.origin.distance_to(start_position) > fish_bounds:
		var direction_to_start = (start_position - transform.origin).normalized()
		velocity = direction_to_start * speed

	# Update all RayCast directions
	update_raycast_targets()

	# Check for collisions
	if is_colliding():
		handle_collision()

# Shoaling: Align fish with nearby neighbors
func align_with_neighbors():
	var neighbors = []
	for neighbor in get_parent().get_children():
		if neighbor != self and neighbor is CSGBox3D:
			if transform.origin.distance_to(neighbor.transform.origin) < shoaling_radius:
				neighbors.append(neighbor)

	if neighbors.size() > 0:
		var average_position = Vector3()
		var average_velocity = Vector3()
		for neighbor in neighbors:
			average_position += neighbor.transform.origin
			average_velocity += neighbor.velocity

		average_position /= neighbors.size()
		average_velocity /= neighbors.size()

		# Steer towards average position and align velocity
		var direction_to_center = (average_position - transform.origin).normalized()
		velocity = (velocity + direction_to_center + average_velocity).normalized() * speed

# Flee from predator
func flee_from_predator():
	if predator != Vector3.ZERO:
		var direction_away = (transform.origin - predator).normalized()
		velocity = direction_away * max_speed

# Enable or disable all RayCasts
func enable_raycasting(enabled: bool):
	for raycast in raycasts:
		raycast.enabled = enabled

# Update targets for all RayCasts
func update_raycast_targets():
	var forward_position = transform.origin + velocity.normalized() * 1.5
	raycasts[0].target_position = forward_position
	raycasts[1].target_position = transform.origin - velocity.normalized() * 1.5
	raycasts[2].target_position = transform.origin + Vector3(0, -1, 0) * 1.5
	raycasts[3].target_position = transform.origin + Vector3(0, 1, 0) * 1.5

# Check for collisions for all RayCasts
func is_colliding() -> bool:
	for raycast in raycasts:
		if raycast.is_colliding():
			return true
	return false

# Handle collision with a smooth turn and slight retreat
func handle_collision():
	var collision_normal = Vector3()
	for raycast in raycasts:
		if raycast.is_colliding():
			collision_normal = raycast.get_collision_normal()
			break

	if collision_normal != Vector3.ZERO:
		var reflect_direction = velocity.bounce(collision_normal).normalized()
		var random_turn = randf_range(-turn_angle, turn_angle)

		var rotation_axis = collision_normal.cross(Vector3.UP)
		if rotation_axis.length_squared() > 0:
			rotation_axis = rotation_axis.normalized()
			velocity = reflect_direction.rotated(rotation_axis, deg_to_rad(random_turn)) * speed
		else:
			velocity = reflect_direction * speed

		if velocity.dot(collision_normal) < 0:
			velocity = reflect_direction * speed

		transform.origin += velocity.normalized() * -retreat_distance
