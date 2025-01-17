extends RigidBody3D

@export var max_hp: int = 3
var hp: int = max_hp

var destruction_particles: PackedScene = load("res://TSCN/damage.tscn")

func take_damage(amount: int):
	hp -= amount
	print(name + " получил урон. Осталось HP: " + str(hp))
	if hp <= 0:
		break_object()

func break_object():
	if destruction_particles:
		var particles_instance = destruction_particles.instantiate()
		particles_instance.global_transform = self.global_transform
		get_parent().add_child(particles_instance)

	queue_free()
