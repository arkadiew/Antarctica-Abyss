extends CSGBox3D

enum State { WANDER, FLEE }

var state = State.WANDER
var start_position = Vector3()
var velocity = Vector3()
var speed = 0.3
var max_speed = 0.6
var min_speed = 0.1
var fish_bounds = 60.0
var wander_timer = 0.0
var wander_interval = 10.0
var turn_angle = 10.0
var retreat_distance = 0.2
var acceleration = 0.01
var deceleration = 0.005
var collision_cooldown = 0.0
var collision_cooldown_time = 0.2
var shoaling_radius = 5.0
var avoidance_radius = 2.0
var avoidance_force = 0.1
var cohesion_force = 0.05
var alignment_force = 0.03
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

	if collision_cooldown <= 0 and is_colliding():
		handle_collision()
		collision_cooldown = collision_cooldown_time

	var new_transform = transform
	new_transform.origin += velocity * delta
	transform = new_transform

	if transform.origin.distance_to(start_position) > fish_bounds:
		var direction_to_start = (start_position - transform.origin).normalized()
		velocity = steer_towards(direction_to_start, velocity, delta)

func wander_behavior(delta):
	velocity = adjust_speed(velocity, speed, delta)
	apply_behaviors(delta)

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

func apply_behaviors(delta):
	var neighbors = get_neighbors()

	var alignment = Vector3()
	var cohesion = Vector3()
	var avoidance = Vector3()

	for neighbor in neighbors:
		var to_neighbor = neighbor.transform.origin - transform.origin
		var distance = to_neighbor.length()

		if distance < avoidance_radius:
			avoidance -= to_neighbor.normalized() / distance
		if distance < shoaling_radius:
			alignment += neighbor.velocity
			cohesion += neighbor.transform.origin

	if neighbors.size() > 0:
		alignment = (alignment / neighbors.size()).normalized() * alignment_force
		cohesion = ((cohesion / neighbors.size() - transform.origin).normalized() * cohesion_force)
		avoidance = avoidance.normalized() * avoidance_force

	velocity += alignment + cohesion + avoidance
	velocity = velocity.normalized() * clamp(velocity.length(), min_speed, max_speed)

func get_neighbors():
	var neighbors = []
	for neighbor in get_parent().get_children():
		if neighbor != self and neighbor is CSGBox3D and "velocity" in neighbor:
			var dist = transform.origin.distance_to(neighbor.transform.origin)
			if dist < max(shoaling_radius, avoidance_radius):
				neighbors.append(neighbor)
	return neighbors

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
	var ray_length = 1.0
	raycasts[0].target_position = transform.origin + forward * ray_length

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
		var random_turn = deg_to_rad(randf_range(-turn_angle, turn_angle))
		var rotation_axis = collision_normal.cross(Vector3.UP).normalized()
		if rotation_axis.length() > 0:
			reflect_direction = reflect_direction.rotated(rotation_axis, random_turn).normalized()
		velocity = reflect_direction * (speed * 0.8)
		var new_transform = transform
		new_transform.origin += velocity.normalized() * (-retreat_distance)
		transform = new_transform
