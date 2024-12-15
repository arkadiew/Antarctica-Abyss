extends CSGBox3D

enum State { WANDER, FLEE }

var state = State.WANDER
var start_position = Vector3()
var velocity = Vector3()
var speed = 0.3
var max_speed = 0.8
var min_speed = 0.1
var fish_bounds = 60.0
var wander_timer = 0.0
var wander_interval = 6.0
var turn_angle = 10.0
var retreat_distance = 0.2
var acceleration = 0.02
var deceleration = 0.01
var collision_cooldown = 0.0
var collision_cooldown_time = 0.2
var shoaling_radius = 5.0
var points_of_interest = []

var flee_distance = 10.0
var predator = Vector3.ZERO

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

func set_random_velocity(target: Vector3 = Vector3.ZERO):
	if target != Vector3.ZERO:
		velocity = (target - transform.origin).normalized() * speed
	else:
		var random_direction = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		velocity = random_direction * speed

func _process(delta):
	# Determine state
	if predator != Vector3.ZERO and transform.origin.distance_to(predator) < flee_distance:
		state = State.FLEE
	else:
		state = State.WANDER

	match state:
		State.FLEE:
			flee_from_predator(delta)
		State.WANDER:
			wander_behavior(delta)

	update_raycast_targets()

	if collision_cooldown > 0:
		collision_cooldown -= delta

	# Existing logic for wander or flee
	# ...
	
	if collision_cooldown <= 0 and is_colliding():
		handle_collision()
		collision_cooldown = collision_cooldown_time

	# Move fish according to the velocity
	var new_transform = transform
	new_transform.origin += velocity * delta
	transform = new_transform

	# Constrain fish within defined bounds
	if transform.origin.distance_to(start_position) > fish_bounds:
		var direction_to_start = (start_position - transform.origin).normalized()
		velocity = steer_towards(direction_to_start, velocity, delta)

func wander_behavior(delta):
	velocity = adjust_speed(velocity, speed, delta)
	align_with_neighbors(delta)

	wander_timer += delta
	if wander_timer > wander_interval:
		wander_timer = 0
		if points_of_interest.size() > 0 and randi() % 2 == 0:
			var poi = points_of_interest[randi() % points_of_interest.size()]
			velocity = steer_towards((poi - transform.origin).normalized(), velocity, delta)
		else:
			var random_dir = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			).normalized()
			velocity = steer_towards(random_dir, velocity, delta)

func flee_from_predator(delta):
	if predator == Vector3.ZERO:
		return
	var direction_away = (transform.origin - predator).normalized()
	velocity = steer_towards(direction_away, velocity, delta, max_speed)

func align_with_neighbors(delta):
	var neighbors = []
	for neighbor in get_parent().get_children():
		if neighbor != self and neighbor is CSGBox3D and "velocity" in neighbor:
			var dist = transform.origin.distance_to(neighbor.transform.origin)
			if dist < shoaling_radius:
				neighbors.append(neighbor)

	if neighbors.size() == 0:
		return

	var average_position = Vector3()
	var average_velocity = Vector3()
	for n in neighbors:
		average_position += n.transform.origin
		average_velocity += n.velocity

	average_position /= neighbors.size()
	average_velocity /= neighbors.size()

	var direction_to_center = (average_position - transform.origin).normalized()
	var align_direction = average_velocity.normalized()
	var combined_direction = (direction_to_center + align_direction).normalized()

	velocity = steer_towards(combined_direction, velocity, delta)

func steer_towards(target_direction: Vector3, current_velocity: Vector3, delta: float, target_speed: float = 0.0) -> Vector3:
	if target_speed == 0.0:
		target_speed = speed

	var desired_velocity = target_direction * target_speed
	var steering = desired_velocity - current_velocity
	var new_velocity = current_velocity + steering * acceleration
	var new_speed = new_velocity.length()

	if new_speed > max_speed:
		new_velocity = new_velocity.normalized() * max_speed
	if new_speed < min_speed:
		new_velocity = new_velocity.normalized() * min_speed

	return new_velocity

func adjust_speed(current_velocity: Vector3, target_speed: float, delta: float) -> Vector3:
	var current_speed = current_velocity.length()
	if abs(current_speed - target_speed) < 0.01:
		return current_velocity

	if current_speed < target_speed:
		current_speed += acceleration
	else:
		current_speed -= deceleration

	current_speed = clamp(current_speed, min_speed, max_speed)
	return current_velocity.normalized() * current_speed

func enable_raycasting(enabled: bool):
	for raycast in raycasts:
		raycast.enabled = enabled

func update_raycast_targets():

	var forward = velocity.normalized()
	# A slightly shorter raycast might help
	var ray_length = 1.0
	raycasts[0].target_position = transform.origin + forward * ray_length
	# Adjust others similarly

func is_colliding() -> bool:
	for raycast in raycasts:
		if raycast.is_colliding():
			return true
	return false

func handle_collision():
	var collision_normal = Vector3()
	for raycast in raycasts:
		if raycast.is_colliding():
			collision_normal = raycast.get_collision_normal()
			break

	if collision_normal != Vector3.ZERO:
		var reflect_direction = velocity.bounce(collision_normal).normalized()

		# Apply a random turn to the reflected direction
		var random_turn = deg_to_rad(randf_range(-turn_angle, turn_angle))
		var rotation_axis = collision_normal.cross(Vector3.UP).normalized()
		if rotation_axis.length() > 0:
			reflect_direction = reflect_direction.rotated(rotation_axis, random_turn).normalized()

		# Set a temporary target direction and reduce speed slightly
		velocity = reflect_direction * (speed * 0.8)  # slightly reduce speed to avoid pushing into obstacle

		# Move fish back slightly
		var new_transform = transform
		new_transform.origin += velocity.normalized() * (-retreat_distance)
		transform = new_transform
func rotate_velocity_towards(target_direction: Vector3, delta: float, rotation_speed: float = 2.0) -> Vector3:
	# Get current direction
	var current_dir = velocity.normalized()
	# Use spherical linear interpolation (slerp) or an approach to gradually rotate
	var angle = acos(current_dir.dot(target_direction))

	# Limit rotation based on rotation_speed
	var max_angle = rotation_speed * delta
	if angle > max_angle:
		angle = max_angle

	# Find rotation axis
	var axis = current_dir.cross(target_direction).normalized()
	# Rotate current_dir towards target_direction by a small angle step
	var rotated_dir = current_dir.rotated(axis, angle).normalized()
	return rotated_dir * velocity.length()
