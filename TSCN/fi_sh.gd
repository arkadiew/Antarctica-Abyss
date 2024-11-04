extends CSGBox3D

var start_position = Vector3()
var velocity = Vector3()
var speed = 0.3  # Calm normal fish speed
var max_speed = 0.5  # Maximum speed, kept low for realistic effect
var fish_bounds = 60.0  # Boundary for swimming area
var wander_timer = 0.0  # Timer for direction change
var wander_interval = 6.0  # Extended interval for changing direction
var turn_angle = 10.0  # Smaller turn angle for smoother movement
var retreat_distance = 0.2  # Distance to retreat after collision
var acceleration = 0.05  # Reduced acceleration factor
var deceleration = 0.05  # Reduced deceleration factor

@onready var raycasts = [
	$RayCast3D,    # Forward
	$RayCast3D4,   # Backward
	$RayCast3D3,   # Floor (down)
	$RayCast3D2    # Ceiling (up)
]

func _ready():
	randomize()
	start_position = transform.origin
	set_random_velocity()
	enable_raycasting(true)

# Set a random speed in a random direction
func set_random_velocity():
	var random_direction = Vector3(
		randf_range(-1, 1),  # Left-right
		randf_range(-1, 1),  # Up-down
		randf_range(-1, 1)   # Forward-backward
	).normalized()
	velocity = random_direction * speed

func _process(delta):
	# Gradually adjust speed to simulate calm movement
	if velocity.length() < max_speed:
		velocity = velocity.normalized() * speed

	# Move the fish according to the velocity vector
	transform.origin += velocity * delta

	# Change direction at longer intervals for a calm effect
	wander_timer += delta
	if wander_timer > wander_interval:
		wander_timer = 0
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

# Enable or disable all RayCasts
func enable_raycasting(enabled: bool):
	for raycast in raycasts:
		raycast.enabled = enabled

# Update targets for all RayCasts
func update_raycast_targets():
	var forward_position = transform.origin + velocity.normalized() * 1.5
	raycasts[0].target_position = forward_position  # Forward
	raycasts[1].target_position = transform.origin - velocity.normalized() * 1.5  # Backward
	raycasts[2].target_position = transform.origin + Vector3(0, -1, 0) * 1.5  # Floor (down)
	raycasts[3].target_position = transform.origin + Vector3(0, 1, 0) * 1.5  # Ceiling (up)

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

	# Ensure the collision normal is valid
	if collision_normal != Vector3.ZERO:
		# Smoothly turn the fish in response to the collision
		var reflect_direction = velocity.bounce(collision_normal).normalized()
		var random_turn = randf_range(-turn_angle, turn_angle)

		# Calculate the rotation axis
		var rotation_axis = collision_normal.cross(Vector3.UP)

		# Ensure the rotation axis is not zero and normalize it
		if rotation_axis.length_squared() > 0:  # Check if the axis is valid
			rotation_axis = rotation_axis.normalized()
			velocity = reflect_direction.rotated(rotation_axis, deg_to_rad(random_turn)) * speed  # Randomize the bounce
		else:
			# If the rotation axis is zero, just keep the reflect_direction
			velocity = reflect_direction * speed

		# Ensure the fish is not moving too fast in the direction of the collision
		if velocity.dot(collision_normal) < 0:
			velocity = reflect_direction * speed

		# Retreat slightly from the collision
		transform.origin += velocity.normalized() * -retreat_distance

# This version of the code focuses on calm behavior, ensuring the fish swims slowly and naturally.
