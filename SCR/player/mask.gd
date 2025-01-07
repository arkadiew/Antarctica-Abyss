extends Sprite2D

# Экспортируемые переменные для настройки поведения скрипта
@export var keep_aspect_ratio: bool = true
@export var position_offset: Vector2 = Vector2.ZERO

func _ready():
	resize_to_fullscreen()
	# Подключаем сигнал изменения размера окна для динамического масштабирования
	get_viewport().connect("resized", Callable(self, "_on_viewport_resized"))

func _on_viewport_resized():
	resize_to_fullscreen()

func resize_to_fullscreen():
	var viewport_size = get_viewport().size

	if not texture:
		push_error("Sprite '%s' не имеет назначенной текстуры." % name)
		return

	var texture_size = texture.get_size()

	if keep_aspect_ratio:
		# Рассчитываем масштаб, сохраняя пропорции
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		var scale = max(scale_x, scale_y)  # Используем max, чтобы заполнить экран полностью
		self.scale = Vector2(scale, scale)
	else:
		# Масштабируем без сохранения пропорций
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		self.scale = Vector2(scale_x, scale_y)

	# Центрируем спрайт с учётом смещения
	self.position = (viewport_size / 2) + position_offset
