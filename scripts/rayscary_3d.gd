# This makes it a 3D raycast (like a laser that checks what’s in front of it)
extends RayCast3D

# Tracks how scared you are (0 to 100)
var fear_scale: int = 0

# Bumps up the fear level by 25, maxing out at 100
func increase_fear():
	fear_scale += 25
	if fear_scale > 100:
		fear_scale = 100  # Caps it at 100
	print("Current fear level: ", fear_scale)  # Shows the fear level in the console

# Runs every physics frame to check what the ray hits
func _physics_process(_delta: float) -> void:
	if is_colliding():  # If the ray hits something...
		var collider = get_collider()  # Grab whatever it hit
		if collider is CSGMesh3D:  # If it’s a 3D shape (like a fish model)...
			if collider.name == "fish":  # And it’s named "fish"...
				increase_fear()  # Get spooked!
