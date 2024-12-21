extends Node3D

@export var fish_scene: PackedScene
@export var fish_count: int = 30            # Сколько рыб заспавнить при старте
@export var spawn_interval: float = 3.0      # Интервал между волнами спавна
@export var fish_per_wave: int = 5           # Сколько рыб спавнить за волну
@export var max_total_fish: int = 60        # Максимум рыб, чтобы не заспавнить слишком много

var current_fish_count = 0
var swimmable_area: Node = null
var spawn_timer: Timer

func _ready():
	# Ищем область плавания
	swimmable_area = get_parent().find_child("SwimmableArea3D", true, false)
	if swimmable_area == null:
		push_warning("SwimmableArea3D не найдена. Рыбы будут спавниться в точке (0,0,0).")

	# Спавним стартовое количество рыб сразу
	spawn_fish(fish_count)

	# Настраиваем таймер для периодического спавна
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	spawn_timer.start()

func _on_spawn_timer_timeout():
	# Спавним еще часть рыб, если не достигнут максимум
	if current_fish_count < max_total_fish:
		spawn_fish(fish_per_wave)

func spawn_fish(count: int):
	for i in range(count):
		var fish_scene = load("res://TSCN/fish.tscn")
		var fish = fish_scene.instantiate()
		var spawn_position: Vector3
		if swimmable_area and swimmable_area.has_method("get_random_point_in_area"):
			spawn_position = swimmable_area.call("get_random_point_in_area")
		else:
			# Если нет области или метода, ставим в ноль
			spawn_position = Vector3.ZERO
		fish.transform.origin = spawn_position
		add_child(fish)
		current_fish_count += 1
