extends CharacterBody3D

@export var max_speed: float = 3.0
@export var rethink_time: float = 2.0
@export var bound_radius: float = 50.0
@export var center_position: Vector3 = Vector3.ZERO

# Параметры плавности
@export var acceleration_speed: float = 2.0
@export var turn_speed: float = 3.0

# Текущее «желаемое» направление (куда хотим плыть).
var target_direction: Vector3 = Vector3.ZERO
# Счётчик времени для смены направления.
var _timer: float = 0.0

func _ready() -> void:
	if center_position == Vector3.ZERO:
		center_position = global_transform.origin
	
	target_direction = _get_random_direction()

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= rethink_time:
		_timer = 0.0
		target_direction = _get_random_direction()
	
	# Плавный переход к желаемой скорости.
	# Вместо мгновенного velocity = target_direction * max_speed
	# мы постепенно «притягиваем» текущую скорость к целевой.
	velocity = velocity.lerp(target_direction * max_speed, delta * acceleration_speed)
	
	# Двигаемся, учитывая возможные коллизии.
	move_and_slide()
	
	# Следим, чтобы не уплыть за заданный радиус.
	_keep_inside_bounds(delta)
	
	# Плавно «поворачиваем» рыбу в сторону движения.
	_face_direction(delta)

func _get_random_direction() -> Vector3:
	var dir = Vector3(
		randf() * 2.0 - 1.0,
		randf() * 2.0 - 1.0,
		randf() * 2.0 - 1.0
	).normalized()
	return dir

func _keep_inside_bounds(delta: float) -> void:
	var current_position = global_transform.origin
	var dist_to_center = current_position.distance_to(center_position)
	if dist_to_center > bound_radius:
		var pull_direction = (center_position - current_position).normalized()
		# Чтобы не было рывка, плавно прибавляем «силу» притяжения к velocity
		velocity = velocity.lerp(
			velocity + pull_direction * (max_speed * 0.5),
			delta * acceleration_speed
		)

func _face_direction(delta: float) -> void:
	# Если рыба реально плывёт, то плавно поворачиваем её в сторону velocity.
	if velocity.length() > 0.01:
		# Целевая ориентация: куда смотрит рыба.
		var target_transform = Transform3D().looking_at(
			global_transform.origin + velocity,
			Vector3.UP
		)
		# Плавно «перекручиваем» текущую Basis к целевому
		transform.basis = transform.basis.slerp(
			target_transform.basis,
			delta * turn_speed
		)
