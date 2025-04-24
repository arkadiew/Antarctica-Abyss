extends Camera3D

@export var Player: Node3D

func _process(delta):
	if Player:
		global_position.x = Player.global_position.x
		global_position.z = Player.global_position.z
