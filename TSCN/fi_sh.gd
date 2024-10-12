extends CSGBox3D

var start_position = Vector3()
var velocity = Vector3()
var speed = 1.0  # Added speed definition
var start_y = 0  # Defined start_y to avoid errors
var turn_dir = 1  # Defined turn_dir to handle rotation

# Reference to the RayCast3D node
@onready var raycast = $RayCast3D

func _ready():
	randomize()
	start_position = transform.origin
	transform.origin += Vector3(
		randf_range(-0.5, 0.5),
		randf_range(-0.5, 0.5),
		randf_range(-0.5, 0.5)
	)
	set_random_velocity()
	# Ensure the RayCast is enabled
	raycast.enabled = true

func set_random_velocity():
	var random_direction = Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()
	velocity = random_direction * speed

func _process(delta):
	# Move the object
	transform.origin += velocity * delta

	# Check distance from the start position
	var distance_from_start = transform.origin.distance_to(start_position)
	if distance_from_start > 2:
		var direction_to_start = (start_position - transform.origin).normalized()
		velocity = direction_to_start * speed
	elif randf() < 0.01:
		set_random_velocity()

	# Rotate the object if distance is greater than 20
	if transform.origin.distance_to(Vector3(start_y, transform.origin.y, transform.origin.z)) > 20:
		rotate_y(turn_dir * 0.5 * delta)

	# Move the object along the Z-axis
	translate(Vector3(0, 0, -3) * delta)  # Продвижение объекта по оси Z

	# Check for collision using RayCast3D
	if raycast.is_colliding():
		# Rotate the object upon collision
		rotate_y(turn_dir * 0.5)
		# Optionally, reverse the velocity to move away from the collision
		velocity = -velocity
