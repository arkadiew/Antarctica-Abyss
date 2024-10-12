extends CSGBox3D

var start_position = Vector3()
var velocity = Vector3()
var speed = 1.0
var start_y = 0
var turn_dir = 1

func _ready():
	randomize()
	start_position = transform.origin
	transform.origin += Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	set_random_velocity()

func set_random_velocity():
	var random_direction = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	velocity = random_direction * speed

func _process(delta):
	transform.origin += velocity * delta
	var distance_from_start = transform.origin.distance_to(start_position)
	if distance_from_start > 2:
		var direction_to_start = (start_position - transform.origin).normalized()
		velocity = direction_to_start * speed
	elif randf() < 0.01:
		set_random_velocity()

	# Поворот объекта, если расстояние больше 20
	if transform.origin.distance_to(Vector3(start_y, transform.origin.y, transform.origin.z)) > 20:
		rotate_y(turn_dir * 0.5 * delta)

	# Продвижение объекта по оси Z
	translate(Vector3(0, 0, -3) * delta)
