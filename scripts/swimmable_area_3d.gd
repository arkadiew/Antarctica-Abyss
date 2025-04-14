extends Area3D  # This makes it a 3D area in Godot, like a zone where stuff can happen (in this case, swimming!)
class_name SwimmableArea3D  # Gives it a custom name so we can refer to it as "SwimmableArea3D" elsewhere

# Grabs the collision shape node when the area loads (it defines the area’s size and shape)
@onready var collision_shape: CollisionShape3D = $CollisionShape3D  # The thing that says "this is the zone!"

# This runs when the area first shows up in the game
func _ready():
	if not collision_shape:
		push_error("CollisionShape3D not found in SwimmableArea3D!")
		return
	if not collision_shape.shape is BoxShape3D:
		push_error("CollisionShape3D needs to use BoxShape3D!")
		return
	# Warn about massive scales
	if scale.length() > 1000 or collision_shape.scale.length() > 1000:
		push_warning("SwimmableArea3D has an unusually large scale: %s (node), %s (collision)" % [scale, collision_shape.scale])
	# Warn about massive extents
	var shape = collision_shape.shape as BoxShape3D
	if shape.extents.length() > 1000:
		push_warning("BoxShape3D extents are unusually large: %s" % shape.extents)

# Picks a random spot inside the area for something to spawn or move to
func get_random_point_in_area() -> Vector3:
	# If the collision shape is missing or not a box, just give back a boring (0, 0, 0) spot
	if not collision_shape or not collision_shape.shape is BoxShape3D:
		return Vector3.ZERO  # Default "nowhere" position
	
	# Get the box shape and its size (extents is half the width, height, and depth)
	var shape = collision_shape.shape as BoxShape3D
	var extents = shape.extents  # How big the box is on each side
	
	# Pick random numbers within the box’s size for x, y, and z
	var x = randf_range(-extents.x, extents.x)  # Random spot left to right
	var y = randf_range(-extents.y, extents.y)  # Random spot up to down
	var z = randf_range(-extents.z, extents.z)  # Random spot forward to back
	
	# Return the random spot, adjusted for where the area is in the game world
	return global_transform.origin + collision_shape.position + Vector3(x, y, z)

# Checks if a specific point is inside the area
func is_point_in_area(point: Vector3) -> bool:
	# If the collision shape is messed up, complain and say the point isn’t in the area
	if not collision_shape or not collision_shape.shape is BoxShape3D:
		push_error("CollisionShape3D isn’t set up right!")  # Oops, something’s wrong
		return false  # Say the point’s not in there
	
	# Get the box shape and its size
	var shape = collision_shape.shape as BoxShape3D
	var box_extents = shape.extents  # Half the box’s size
	var box_center = global_transform.origin + collision_shape.position  # Middle of the box in the game world
	
	# Figure out where the point is compared to the center
	var local_point = point - box_center
	
	# Check if the point fits inside the box (not too far left, right, up, down, forward, or back)
	return local_point.x >= -box_extents.x and local_point.x <= box_extents.x and \
		   local_point.y >= -box_extents.y and local_point.y <= box_extents.y and \
		   local_point.z >= -box_extents.z and local_point.z <= box_extents.z

# Finds the middle of the area
func get_center() -> Vector3:
	# If there’s no collision shape, complain and just give the area’s basic position
	if not collision_shape:
		push_error("CollisionShape3D not found!")  # Uh-oh, no shape!
		return global_transform.origin  # Default to the area’s starting spot
	
	# Return the center, accounting for any offset from the collision shape
	return global_transform.origin + collision_shape.position

# Figures out how far the farthest edge is from the center
func get_max_distance_from_center() -> float:
	# If there’s no collision shape, just say 0 (no distance)
	if collision_shape == null:
		return 0.0  # Nothing to measure
	
	# Get whatever shape the collision is using
	var shape = collision_shape.shape
	
	# If it’s a sphere, the max distance is just its radius
	if shape is SphereShape3D:
		return shape.radius  # Easy peasy, it’s a ball!
	
	# If it’s a box, calculate the diagonal (the longest line from center to corner)
	elif shape is BoxShape3D:
		var extents = shape.extents  # Half the box’s size
		return extents.length()  # The diagonal length—fancy math for the farthest point
	
	# If it’s neither a sphere nor a box, freak out and say 0
	else:
		push_error("CollisionShape3D shape isn’t supported!")  # What even is this shape?!
		return 0.0  # No idea, so no distance
