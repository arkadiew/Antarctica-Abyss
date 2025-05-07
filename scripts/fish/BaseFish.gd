extends CharacterBody3D
class_name BaseFish
signal removed

@export var max_speed: float = 3.0
@export var rethink_time: float = 2.0
@export var acceleration_speed: float = 2.0
@export var turn_speed: float = 3.0
@export var flee_duration: float = 1.5  # Короткое время для быстрого побега
@export var flee_speed: float = 8.0    # Высокая скорость для стремительного побега
@export var flee_acceleration: float = 5.0  # Ускорение при побеге

var target_direction: Vector3 = Vector3.ZERO
var _timer: float = 0.0
var swimmable_area: SwimmableArea = null
var is_fleeing: bool = false
var flee_timer: float = 0.0
var flee_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	swimmable_area = _find_swimmable_area()
	if not swimmable_area:
		push_error("No SwimmableArea found for BaseFish!")
	target_direction = _get_random_direction()
	
	# Подключаем Area3D для обнаружения попадания копья
	if has_node("HitArea"):
		var hit_area = $HitArea as Area3D
		hit_area.connect("body_entered", _on_hit_area_body_entered)

func _physics_process(delta: float) -> void:
	_timer += delta
	
	if is_fleeing:
		flee_timer -= delta
		if flee_timer <= 0:
			is_fleeing = false
			target_direction = _get_random_direction()
		else:
			# Быстрое движение в направлении побега
			velocity = velocity.lerp(flee_direction * flee_speed, delta * flee_acceleration)
	else:
		if _timer >= rethink_time:
			_timer = 0.0
			target_direction = _get_random_direction()
		velocity = velocity.lerp(target_direction * max_speed, delta * acceleration_speed)

	move_and_slide()
	_keep_inside_bounds(delta)
	_face_direction(delta)

func _on_hit_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("spear"):
		is_fleeing = true
		flee_timer = flee_duration
		# Направление побега — строго от копья
		flee_direction = (global_position - body.global_position).normalized()
		_timer = 0.0

func _get_random_direction() -> Vector3:
	return Vector3(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized()

func _keep_inside_bounds(delta: float) -> void:
	if not swimmable_area:
		return

	var current_pos = global_position
	
	if not swimmable_area.is_point_in_area(current_pos):
		var center = swimmable_area.get_center()
		var pull_direction = (center - current_pos).normalized()
		if is_fleeing:
			flee_direction = pull_direction
			velocity = velocity.lerp(flee_direction * flee_speed, delta * flee_acceleration)
		else:
			target_direction = pull_direction
			velocity = velocity.lerp(pull_direction * max_speed, delta * acceleration_speed)
	else:
		var shape = swimmable_area.collision_shape.shape as BoxShape3D
		var extents = shape.extents
		var box_center = swimmable_area.get_center()
		var local_pos = current_pos - box_center
		var margin = extents * 0.1
		var new_direction = target_direction if not is_fleeing else flee_direction
		
		if local_pos.x > extents.x - margin.x and new_direction.x > 0:
			new_direction.x = -abs(new_direction.x)
		elif local_pos.x < -extents.x + margin.x and new_direction.x < 0:
			new_direction.x = abs(new_direction.x)
			
		if local_pos.y > extents.y - margin.y and new_direction.y > 0:
			new_direction.y = -abs(new_direction.y)
		elif local_pos.y < -extents.y + margin.y and new_direction.y < 0:
			new_direction.y = abs(new_direction.y)
			
		if local_pos.z > extents.z - margin.z and new_direction.z > 0:
			new_direction.z = -abs(new_direction.z)
		elif local_pos.z < -extents.z + margin.z and new_direction.z < 0:
			new_direction.z = abs(new_direction.z)
			
		if new_direction != (target_direction if not is_fleeing else flee_direction):
			if is_fleeing:
				flee_direction = new_direction.normalized()
				velocity = velocity.lerp(flee_direction * flee_speed, delta * flee_acceleration)
			else:
				target_direction = new_direction.normalized()
				velocity = velocity.lerp(target_direction * max_speed, delta * acceleration_speed)

func _face_direction(delta: float) -> void:
	if velocity.length() > 0.01:
		var target_transform = Transform3D().looking_at(global_position + velocity, Vector3.UP)
		var current_quat = transform.basis.get_rotation_quaternion()
		var target_quat = target_transform.basis.get_rotation_quaternion()
		transform.basis = Basis(current_quat.slerp(target_quat, delta * turn_speed))

func _find_swimmable_area() -> SwimmableArea:
	var areas = get_tree().get_nodes_in_group("swimmable_area")
	if areas.is_empty():
		return null
	return areas[0] as SwimmableArea

func _exit_tree() -> void:
	removed.emit()
