# This makes it a particle system that runs on the CPU (good for simple effects)
extends CPUParticles3D 

# Runs when the particles first show up
func _ready():
	# Waits for the particle system’s lifetime (how long it’s set to last)
	await get_tree().create_timer(lifetime).timeout
	# Deletes the particles once they’re done
	queue_free()
