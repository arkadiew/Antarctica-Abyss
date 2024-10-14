extends CSGBox3D

var start_position = Vector3()
var velocity = Vector3()
var speed = 1.5  # Adjust this for desired speed
var max_distance = 60.0  # Max distance the fish will wander from its starting point
var fish_bounds = 60.0  # Limit the swimming area for the fish
var wander_timer = 0.0  # Timer to trigger wandering
var wander_interval = 3.0  # Time between direction changes
var turn_angle = 90.0 #Angle the fish will turn when hitting a wall

@onready var raycast = $RayCast3D

func _ready():
	randomize()
	start_position = transform.origin
	set_random_velocity()
	raycast.enabled = true  # Enable raycasting

# Set random velocity in a random direction
func set_random_velocity():
	var random_direction = Vector3(
		randf_range(-1, 1),
		randf_range(-0.1, 0.1),  # Fish don't change depth much
		randf_range(-1, 1)
	).normalized()
	velocity = random_direction * speed

func _process(delta):
	# Move the fish along its velocity vector
	transform.origin += velocity * delta
	
	# Occasionally change direction (every few seconds)
	wander_timer += delta
	if wander_timer > wander_interval:
		wander_timer = 0
		set_random_velocity()
	
	# Keep the fish within a limited distance from its starting position
	if transform.origin.distance_to(start_position) > fish_bounds:
		var direction_to_start = (start_position - transform.origin).normalized()
		velocity = direction_to_start * speed
	
	# Collision avoidance using RayCast3D
	raycast.target_position = transform.origin + velocity.normalized() * 1.5  # Look slightly ahead
	if raycast.is_colliding():
		handle_collision()

# Handle collision by turning the fish in a random direction
func handle_collision():
	rotate_y(deg_to_rad(turn_angle * randf_range(-1, 1)))  # Randomly rotate left or right
	set_random_velocity()  # Change direction slightly after collision
