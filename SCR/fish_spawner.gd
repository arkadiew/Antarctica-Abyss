extends Node3D

@export var fish_scene: PackedScene   # Перетащите сюда сцену рыбы в инспекторе
@export var fish_count: int = 20        # Сколько рыб спавнить
@export var swimmable_area_path: NodePath = "res://utils/WaterMaker3D/WaterMaker3D.tscn" # Путь к SwimmableArea3D (например, родительский узел)

var swimmable_area: Node3D

func _ready():
	swimmable_area = get_node(swimmable_area_path)
	if swimmable_area == null:
		push_warning("SwimmableArea3D не найдена. Рыбы будут спавниться в точке (0,0,0).")

	spawn_fish(fish_count)

func spawn_fish(count: int):
	for i in range(count):
		var fish_scene = load("res://TSCN/fish.tscn")
		var fish = fish_scene.instantiate()
  # Создаём экземпляр рыбы
		var spawn_position: Vector3 = Vector3.ZERO

		if swimmable_area and swimmable_area.has_method("get_random_point_in_area"):
			spawn_position = swimmable_area.call("get_random_point_in_area")

		fish.transform.origin = spawn_position
		add_child(fish)
