extends Area3D


var area_size = Vector3(100, 50, 100)

func get_random_point_in_area() -> Vector3:
	var x = randf_range(-area_size.x/2, area_size.x/2)
	var y = randf_range(-area_size.y/2, area_size.y/2)
	var z = randf_range(-area_size.z/2, area_size.z/2)
	return transform.origin + Vector3(x, y, z)

func is_point_in_area(point: Vector3) -> bool:
	var local_point = transform.affine_inverse() * point


	return abs(local_point.x) <= area_size.x/2 and abs(local_point.y) <= area_size.y/2 and abs(local_point.z) <= area_size.z/2

func get_center() -> Vector3:
	return transform.origin
