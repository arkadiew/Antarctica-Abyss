extends Area3D
class_name SwimmableArea

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	add_to_group("swimmable_area")
	if not collision_shape:
		push_error("CollisionShape3D not found in SwimmableArea3D!")
		return
	if not collision_shape.shape is BoxShape3D:
		push_error("CollisionShape3D needs to use BoxShape3D!")
		return
	if scale.length() > 1000 or collision_shape.scale.length() > 1000:
		push_warning("SwimmableArea3D has an unusually large scale: %s (node), %s (collision)" % [scale, collision_shape.scale])
	var shape = collision_shape.shape as BoxShape3D
	if shape.extents.length() > 1000:
		push_warning("BoxShape3D extents are unusually large: %s" % shape.extents)

func get_random_point_in_area() -> Vector3:
	if not collision_shape or not collision_shape.shape is BoxShape3D:
		return Vector3.ZERO

	var shape = collision_shape.shape as BoxShape3D
	var extents = shape.extents

	var x = randf_range(-extents.x, extents.x)
	var y = randf_range(-extents.y, extents.y)
	var z = randf_range(-extents.z, extents.z)

	return global_position + collision_shape.position + Vector3(x, y, z)

func is_point_in_area(point: Vector3) -> bool:
	if not collision_shape or not collision_shape.shape is BoxShape3D:
		push_error("CollisionShape3D isn’t set up right!")
		return false

	var shape = collision_shape.shape as BoxShape3D
	var box_extents = shape.extents
	var box_center = global_position + collision_shape.position

	var local_point = point - box_center

	return local_point.x >= -box_extents.x and local_point.x <= box_extents.x and \
		   local_point.y >= -box_extents.y and local_point.y <= box_extents.y and \
		   local_point.z >= -box_extents.z and local_point.z <= box_extents.z

func get_center() -> Vector3:
	if not collision_shape:
		push_error("CollisionShape3D not found!")
		return global_position

	return global_position + collision_shape.position

func get_max_distance_from_center() -> float:
	if collision_shape == null:
		return 0.0

	var shape = collision_shape.shape

	if shape is SphereShape3D:
		return shape.radius
	elif shape is BoxShape3D:
		var extents = shape.extents
		return extents.length()
	else:
		push_error("CollisionShape3D shape isn’t supported!")
		return 0.0
