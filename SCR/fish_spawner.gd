extends Node3D

# Экспортированные переменные, которые можно настраивать через инспектор:
@export var fish_scene: PackedScene = preload("res://TSCN/fish.tscn")
@export var fish_count: int = 30         # Сколько рыб сразу спавнится при старте
@export var spawn_interval: float = 3.0  # Интервал спавна волны рыб (в секундах)
@export var fish_per_wave: int = 5       # Количество рыб, спавнимых за каждую волну
@export var max_total_fish: int = 60     # Максимальное кол-во рыб одновременно

# Внутренние переменные
var current_fish_count: int = 0          # Текущее кол-во заспавненных рыб
var swimmable_area: Node                 # Ссылка на зону, в которой рыба может плавать
var spawn_timer: Timer                   # Таймер, который вызывает спавн каждые spawn_interval сек

func _ready():
	# Ищем узел "SwimmableArea3D" в родительских потомках (рекурсивно)
	swimmable_area = get_parent().find_child("SwimmableArea3D", true, false)
	if swimmable_area == null:
		# Если не нашли зону — выводим предупреждение, что рыбы будут спавниться в (0,0,0)
		push_warning("SwimmableArea3D не найдена. Рыбы будут спавниться в (0,0,0).")

	# Первый массовый спавн при старте
	spawn_fish(fish_count)

	# Создаём таймер и добавляем в дерево
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	spawn_timer.start()

func _on_spawn_timer_timeout():
	# Если мы ещё не достигли max_total_fish
	if current_fish_count < max_total_fish:
		# Считаем, сколько рыб мы можем безопасно добавить, чтобы не превысить лимит
		var allowed_fish_to_spawn = min(fish_per_wave, max_total_fish - current_fish_count)
		if allowed_fish_to_spawn > 0:
			spawn_fish(allowed_fish_to_spawn)

func spawn_fish(count: int):
	# Проверяем, действительно ли у нас есть назначенная сцена рыбы
	if fish_scene == null:
		push_error("Не назначена сцена рыбы (fish_scene). Спавн невозможен!")
		return

	for i in range(count):
		# Инстанцируем новый объект рыбы
		var fish_instance = fish_scene.instantiate()

		# Получаем позицию для спавна из зоны, если она задана и содержит нужный метод
		var spawn_position = Vector3.ZERO
		if swimmable_area and swimmable_area.has_method("get_random_point_in_area"):
			spawn_position = swimmable_area.call("get_random_point_in_area")

		# Назначаем позицию
		fish_instance.transform.origin = spawn_position
		add_child(fish_instance)

		# Инкрементируем счётчик
		current_fish_count += 1
