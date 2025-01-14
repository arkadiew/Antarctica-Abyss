extends RigidBody3D

@export var max_hp: int = 3
var hp: int = max_hp

# Путь к сцене с частицами (можно выбрать в инспекторе)
# Указываем путь к сцене с частицами
var destruction_particles: PackedScene = load("res://TSCN/damage.tscn")

func take_damage(amount: int):
	hp -= amount
	print(name + " получил урон. Осталось HP: " + str(hp))
	if hp <= 0:
		break_object()

func break_object():
	# Проверяем, есть ли сцена с частицами
	if destruction_particles:
		# Создаем экземпляр частиц
		var particles_instance = destruction_particles.instantiate()
		# Устанавливаем позицию частиц на позицию объекта
		particles_instance.global_transform = self.global_transform
		# Добавляем частицы в текущую сцену
		get_parent().add_child(particles_instance)
	
	# Уничтожаем объект
	queue_free()
