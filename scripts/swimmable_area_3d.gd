extends Area3D
class_name SwimmableArea3D

# Grabs the collision shape node when the area loads
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# This runs when the area first shows up in the game
func _ready():
	# Check if collision shape exists and is a BoxShape3D
	if not collision_shape:
		push_error("CollisionShape3D not found in SwimmableArea3D!")
		return
	if not collision_shape.shape is BoxShape3D:
		push_error("CollisionShape3D needs to use BoxShape3D!")
		return

	var shape = collision_shape.shape as BoxShape3D
	var extents = shape.extents

	# Check for too small extents
	if extents.length() < 0.1:
		push_warning("BoxShape3D extents are too small: %s. Setting to minimum (1, 1, 1)." % extents)
		shape.extents = Vector3(1, 1, 1)  # Minimum size
		extents = shape.extents  # Update extents after correction

	# Check for too small scale
	if scale.length() < 0.01 or collision_shape.scale.length() < 0.01:
		push_warning("SwimmableArea3D or CollisionShape3D scale is too small: %s (node), %s (collision). Resetting to (1, 1, 1)." % [scale, collision_shape.scale])
		scale = Vector3(1, 1, 1)
		collision_shape.scale = Vector3(1, 1, 1)

	# Warn about massive scales
	if scale.length() > 1000 or collision_shape.scale.length() > 1000:
		push_warning("SwimmableArea3D has an unusually large scale: %s (node), %s (collision)" % [scale, collision_shape.scale])

	# Warn about massive extents
	if extents.length() > 1000:
		push_warning("BoxShape3D extents are unusually large: %s" % extents)

	# Log area size for debugging
	debug_area_size()

# Picks a random spot inside the area for something to spawn or move to
func get_random_point_in_area() -> Vector3:
	if not collision_shape or not collision_shape.shape is BoxShape3D:
		push_error("Invalid collision shape!")
		return global_transform.origin  # Fallback to node position

	var shape = collision_shape.shape as BoxShape3D
	var extents = shape.extents

	# Ensure minimum extents to avoid degenerate cases
	if extents.length() < 0.1:
		push_warning("Extents too small: %s. Using temporary minimum (1, 1, 1)." % extents)
		extents = Vector3(1, 1, 1)  # Temporary minimum size

	var x = randf_range(-extents.x, extents.x)
	var y = randf_range(-extents.y, extents.y)
	var z = randf_range(-extents.z, extents.z)

	return global_transform.origin + collision_shape.position + Vector3(x, y, z)

# Checks if a specific point is inside the area
func is_point_in_area(point: Vector3) -> bool:
	if not collision_shape or not collision_shape.shape is BoxShape3D:
		push_error("CollisionShape3D isn’t set up right!")
		return false

	var shape = collision_shape.shape as BoxShape3D
	var box_extents = shape.extents
	var box_center = global_transform.origin + collision_shape.position

	# Ensure minimum extents for checking
	if box_extents.length() < 0.1:
		push_warning("Extents too small for point check: %s. Using minimum (1, 1, 1)." % box_extents)
		box_extents = Vector3(1, 1, 1)

	var local_point = point - box_center

	return local_point.x >= -box_extents.x and local_point.x <= box_extents.x and \
		   local_point.y >= -box_extents.y and local_point.y <= box_extents.y and \
		   local_point.z >= -box_extents.z and local_point.z <= box_extents.z

# Finds the middle of the area
func get_center() -> Vector3:
	if not collision_shape:
		push_error("CollisionShape3D not found!")
		return global_transform.origin

	return global_transform.origin + collision_shape.position

# Figures out how far the farthest edge is from the center
func get_max_distance_from_center() -> float:
	if collision_shape == null:
		return 0.0

	var shape = collision_shape.shape

	if shape is SphereShape3D:
		return shape.radius

	elif shape is BoxShape3D:
		var extents = shape.extents
		# Ensure minimum extents
		if extents.length() < 0.1:
			push_warning("Extents too small for distance calc: %s. Using minimum (1, 1, 1)." % extents)
			extents = Vector3(1, 1, 1)
		return extents.length()

	else:
		push_error("CollisionShape3D shape isn’t supported!")
		return 0.0

# Debug function to log area size and properties
func debug_area_size():
	if not collision_shape or not collision_shape.shape is BoxShape3D:
		print("Error: Invalid collision shape in SwimmableArea3D")
		return
	var shape = collision_shape.shape as BoxShape3D
	var effective_size = shape.extents * 2  # Full width, height, depth
	print("SwimmableArea3D size (width, height, depth): %s" % effective_size)
	print("Center: %s" % get_center())
	print("Max distance from center: %s" % get_max_distance_from_center())
