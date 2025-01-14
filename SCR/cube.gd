extends RigidBody3D

@export var max_hp: int = 3
var hp: int = max_hp


func take_damage(amount: int):
	hp -= amount
	print(name + " получил урон. Осталось HP: " + str(hp))
	if hp <= 0:
		
		break_object()

func break_object():
	
	# Уничтожаем объект
	queue_free()
