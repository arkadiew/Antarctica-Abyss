extends CSGBox3D

var start_position = Vector3()
var velocity = Vector3()
var speed = 1.5  # Fish speed
var max_distance = 60.0  # Maximum distance the fish can wander
var fish_bounds = 60.0  # Boundary for swimming area
var wander_timer = 0.0  # Timer for direction change
var wander_interval = 2.0  # Interval for changing direction
var turn_angle = 180.0  # Large turning angle on collision
var crazy_timer = 0.0  # Timer for craziness
var is_crazy = false  # Craziness state
var normal_wander_interval = 2.0  # Normal direction change interval
var crazy_wander_interval = 0.3  # Very short interval during craziness
var normal_speed = 1.5  # Normal fish speed
var crazy_speed = 4.0  # Increased speed during craziness

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
	# Update craziness state timer
	if is_crazy:
		crazy_timer += delta
		if crazy_timer > randf_range(2.0, 5.0):  # Craziness lasts from 2 to 5 seconds
			stop_crazy_mode()
	else:
		# Randomly initiate craziness
		if randi() % 1000 < 2:  # Small chance (~0.2%) every frame
			start_crazy_mode()

	# Move the fish according to velocity vector
	transform.origin += velocity * delta
	
	# Change direction every few seconds
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

# Handle collision with a sharp and random direction change (spinning)
func handle_collision():
	# Calculate direction from collision
	var collision_normal = Vector3()
	for raycast in raycasts:
		if raycast.is_colliding():
			collision_normal = raycast.get_collision_normal()
			break
	
	# Turn the fish in the direction opposite to the collision normal
	var reflect_direction = velocity.bounce(collision_normal).normalized()
	velocity = reflect_direction * speed  # Set new velocity direction

	# Ensure the fish is not moving too fast in the direction of the collision
	if velocity.dot(collision_normal) < 0:
		velocity = reflect_direction * speed

# Enable craziness mode
func start_crazy_mode():
	is_crazy = true
	crazy_timer = 0.0
	speed = crazy_speed  # Increase speed
	wander_interval = crazy_wander_interval  # Change direction more often

# Stop craziness mode
func stop_crazy_mode():
	is_crazy = false
	speed = normal_speed  # Return to normal speed
	wander_interval = normal_wander_interval  # Return to normal direction change interval
