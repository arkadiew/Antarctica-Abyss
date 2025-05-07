extends Control

@onready var task_list: VBoxContainer = $TaskControl/VBoxContainer
@onready var total_label: Label = $TaskControl/VBoxContainer/TotalLabel

# Загружаем кастомный шрифт (замените на путь к вашему .ttf файлу, если используете)

var font_size: int = 24  # Размер шрифта
var shadow_color: Color = Color(0, 0, 0, 0.5)  # Цвет тени
var shadow_offset: Vector2 = Vector2(2, 2)  # Смещение тени

func _ready() -> void:
	if not task_list or not total_label:
		push_error("Failed to find task_list or total_label nodes.")
		print("task_list: ", task_list)
		print("total_label: ", total_label)
		return
	
	# Настраиваем total_label
	apply_label_style(total_label)
	total_label.text = "Total Completion: 0%"
	
	await get_tree().process_frame
	connect_signals()
	for task_id in TaskManager.tasks:
		var task = TaskManager.tasks[task_id]
		_on_task_registered(task_id, task.name, task.max_progress)
		var percentage = (task.progress / task.max_progress * 100.0) if task.max_progress > 0 else 0.0
		_on_task_updated(task_id, task.progress, task.max_progress, percentage, task.is_completed, task.details)
	print("TaskUI initialized, tasks: ", TaskManager.tasks.keys())

func connect_signals() -> void:
	if not TaskManager.task_registered.is_connected(_on_task_registered):
		TaskManager.task_registered.connect(_on_task_registered)
	if not TaskManager.task_updated.is_connected(_on_task_updated):
		TaskManager.task_updated.connect(_on_task_updated)
	if not TaskManager.total_completion_updated.is_connected(_on_total_completion_updated):
		TaskManager.total_completion_updated.connect(_on_total_completion_updated)
	print("TaskUI signals connected")

func _on_task_registered(task_id: String, task_name: String, max_progress: float) -> void:
	if not task_list:
		push_error("task_list is null.")
		return
	
	print("Task registered: ", task_id, ", Name: ", task_name, ", Max Progress: ", max_progress)
	var hbox = task_list.get_node_or_null(task_id)
	if not hbox:
		hbox = HBoxContainer.new()
		hbox.name = task_id
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var label = Label.new()
		label.name = "Label"
		label.text = get_task_label_text(task_id)
		apply_label_style(label)  # Применяем стиль к новой метке
		hbox.add_child(label)
		task_list.add_child(hbox)
	else:
		var label = hbox.get_node_or_null("Label")
		if label:
			label.text = get_task_label_text(task_id)
			apply_label_style(label)  # Обновляем стиль для существующей метки
	
	print("Task data: ", TaskManager.tasks.get(task_id, {}))

func _on_task_updated(task_id: String, progress: float, max_progress: float, percentage: float, is_completed: bool, details: Dictionary) -> void:
	if not task_list:
		push_error("task_list is null.")
		return
	
	var hbox = task_list.get_node_or_null(task_id)
	if hbox:
		var label = hbox.get_node_or_null("Label")
		if label:
			label.text = get_task_label_text(task_id, progress, max_progress, percentage, details)
			apply_label_style(label)  # Применяем стиль
			if is_completed:
				label.modulate = Color.GREEN
			else:
				label.modulate = Color.WHITE  # Сбрасываем цвет, если задача не завершена
		else:
			push_error("Label node not found: %s" % task_id)
	else:
		print("Creating missed task HBox for: ", task_id)
		_on_task_registered(task_id, TaskManager.tasks.get(task_id, {}).get("name", "Unknown"), max_progress)
		var hbox_new = task_list.get_node_or_null(task_id)
		if hbox_new:
			var label = hbox_new.get_node_or_null("Label")
			if label:
				label.text = get_task_label_text(task_id, progress, max_progress, percentage, details)
				apply_label_style(label)  # Применяем стиль
				if is_completed:
					label.modulate = Color.GREEN
	
	print("Task updated: ", task_id, ", Progress: ", progress, ", Max: ", max_progress, ", Percentage: ", percentage)

func apply_label_style(label: Label) -> void:
	if not label:
		return
	

	label.add_theme_font_size_override("font_size", font_size)
	
	# Устанавливаем цвет текста
	label.add_theme_color_override("font_color", Color.WHITE)
	
	# Добавляем тень
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
	label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
	# Центрируем текст

	
	# Растягиваем Label, чтобы он занимал весь контейнер
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

func get_task_label_text(task_id: String, progress: float = 0.0, max_progress: float = 0.0, percentage: float = 0.0, details: Dictionary = {}) -> String:
	var task = TaskManager.tasks.get(task_id, {})
	var task_name = task.get("name", "Unknown")
	if task_id == "button_task":
		var items = task.get("details", {}).get("items", {"Stone": 0, "Curiosity": 0})
		var current_items = details.get("current_items", {"Stone": 0, "Curiosity": 0})
		var stones = current_items.get("Stone", 0)
		var curiosities = current_items.get("Curiosity", 0)
		var stones_required = items.get("Stone", 0)
		var curiosities_required = items.get("Curiosity", 0)
		var text = "%s: %.1f%%\n  Stones: %d/%d\n  Curiosities: %d/%d" % [
			task_name, percentage,
			stones, stones_required,
			curiosities, curiosities_required
		]
		print("Button task text: ", text)
		return text
	elif task_id == "pipe_repair":
		var pipe_count = task.get("contributors", {}).size()
		var text = "%s: %.1f%%\n  %d/%d, %d pipe(s)" % [
			task_name, percentage,
			int(progress), int(max_progress), pipe_count
		]
		print("Pipe task text: ", text, ", Contributors: ", task.get("contributors", {}).keys())
		return text
	var text = "%s: %.1f%% (%d/%d)" % [task_name, percentage, int(progress), int(max_progress)]
	print("Generic task text: ", text)
	return text

func _on_total_completion_updated(percentage: float) -> void:
	if not total_label:
		push_error("total_label is null.")
		return
	total_label.text = "Total Completion: %.1f%%" % percentage
	apply_label_style(total_label)  # Применяем стиль при обновлении
	print("Total completion updated: ", percentage)
