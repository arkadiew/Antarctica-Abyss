extends Node

# Экспортируемые переменные для настройки
@export var keep_aspect_ratio: bool = true
@export var position_offset: Vector2 = Vector2.ZERO

func _ready():
	resize_all_sprites()
	# Подключаем сигнал изменения размера окна для динамического масштабирования
	get_viewport().connect("resized", Callable(self, "_on_viewport_size_changed"))

func _on_viewport_size_changed():
	resize_all_sprites()

func resize_all_sprites():
	var viewport_size = get_viewport().size

	# Проходим по всем дочерним узлам
	for child in get_children():
		if child is Sprite2D:
			resize_sprite(child, viewport_size)

func resize_sprite(sprite: Sprite2D, viewport_size: Vector2):
	if not sprite.texture:
		push_error("Sprite '%s' не имеет назначенной текстуры." % sprite.name)
		return

	var texture_size = sprite.texture.get_size()

	if keep_aspect_ratio:
		# Рассчитываем масштаб, сохраняя пропорции
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		var scale = max(scale_x, scale_y)  # Используем max, чтобы заполнить экран полностью
		sprite.scale = Vector2(scale, scale)
	else:
		# Масштабируем без сохранения пропорций
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		sprite.scale = Vector2(scale_x, scale_y)

	# Центрируем спрайт с учётом смещения
	sprite.position = (viewport_size / 2) + position_offset
