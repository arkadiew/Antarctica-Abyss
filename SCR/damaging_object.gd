extends RigidBody3D
class_name DamagingObject

@export var is_active: bool = false
@export var targets_group: String = "cube"
@export var kill_distance: float = 0.0   

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	var my_pos = global_transform.origin
	var bodies = get_tree().get_nodes_in_group(targets_group)
	for body in bodies:
		if body is RigidBody3D and body != self:
			var dist = my_pos.distance_to(body.global_transform.origin)
			if dist <= kill_distance:
				body.queue_free()
