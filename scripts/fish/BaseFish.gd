extends CharacterBody3D
class_name BaseFish
# Export variables for tweaking in the editor
@export var max_speed: float = 3.0
@export var rethink_time: float = 2.0
@export var bound_radius: float = 50.0
@export var center_position: Vector3 = Vector3.ZERO
@export var acceleration_speed: float = 2.0
@export var turn_speed: float = 3.0

# Internal variables
var target_direction: Vector3 = Vector3.ZERO
var _timer: float = 0.0

# Called when the node enters the scene
func _ready() -> void:
	if center_position == Vector3.ZERO:
		center_position = global_transform.origin
	target_direction = _get_random_direction()

# Called every physics frame
func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= rethink_time:
		_timer = 0.0
		target_direction = _get_random_direction()
	
	velocity = velocity.lerp(target_direction * max_speed, delta * acceleration_speed)
	move_and_slide()
	_keep_inside_bounds(delta)
	_face_direction(delta)

# Virtual method for direction picking (can be overridden)
func _get_random_direction() -> Vector3:
	return Vector3(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0, randf() * 2.0 - 1.0).normalized()

# Keeps the character within bounds
func _keep_inside_bounds(delta: float) -> void:
	var current_position = global_transform.origin
	var dist_to_center = current_position.distance_to(center_position)
	if dist_to_center > bound_radius:
		var pull_direction = (center_position - current_position).normalized()
		velocity = velocity.lerp(velocity + pull_direction * (max_speed * 0.5), delta * acceleration_speed)

# Makes the character face its movement direction
func _face_direction(delta: float) -> void:
	if velocity.length() > 0.01:
		var target_transform = Transform3D().looking_at(global_transform.origin + velocity, Vector3.UP)
		var current_quat = transform.basis.get_rotation_quaternion()
		var target_quat = target_transform.basis.get_rotation_quaternion()
		transform.basis = Basis(current_quat.slerp(target_quat, delta * turn_speed))
