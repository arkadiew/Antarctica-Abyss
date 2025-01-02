extends RayCast3D

var fear_scale: int = 0
func increase_fear():
	fear_scale += 25
	if fear_scale > 100:
		fear_scale = 100
	print("Текущая шкала страха: ", fear_scale)
func _physics_process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider is CSGMesh3D:
			if collider.name == "fish":
				increase_fear()
		 
