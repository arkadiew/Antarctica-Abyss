extends Node3D

# Массив для хранения всех рыб
var fishes : Array = []

# Количество рыб
var fish_count : int = 20

# Префаб рыбы (сцена Fish)
@export var fish_scene : PackedScene

func _ready():
	if fish_scene == null:
		print("Error: fish_scene is not assigned!")
		return

	# Создаём рыбу и добавляем их в стаю
	for i in range(fish_count):
		var fish_instance = fish_scene.instantiate()

		# Устанавливаем начальное положение рыбы в случайную позицию
		fish_instance.global_transform.origin = Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))

		# Добавляем рыбу на сцену и в массив
		add_child(fish_instance)
		fishes.append(fish_instance)
