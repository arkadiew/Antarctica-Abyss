extends Control

@onready var info_list: VBoxContainer = $VBoxContainer
@onready var info_label: Label = $VBoxContainer/Label
@onready var stat_info = $StatisticInfo
@onready var TaskManager = $TaskManager

# Загружаем кастомный шрифт (замените на путь к вашему .ttf файлу, если используете)

var font_size: int = 24  # Размер шрифта
var shadow_color: Color = Color(0, 0, 0, 0.5)  # Цвет тени
var shadow_offset: Vector2 = Vector2(2, 2)  # Смещение тени

func _ready() -> void:
	if not info_list or not info_label:
		push_error("Failed to find info_list or info_label nodes.")
		print("info_list: ", info_list)
		print("info_label: ", info_label)
		return
	
	# Настраиваем info_label
	apply_label_style(info_label)
	await get_tree().process_frame
	#print("TaskUI initialized, tasks: ", TaskManager.tasks.keys())

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

func get_task_summary() -> String:
	if not TaskManager:
		return "TaskManager не инициализирован."

	var result := "=== Отчёт по заданиям ===\n"
	var completed := 0

	for task_id in TaskManager.tasks:
		var task = TaskManager.tasks[task_id]
		var name = task.get("name", "Без названия")
		var progress = task.get("progress", 0.0)
		var max_progress = task.get("max_progress", 1.0)
		var percentage = (progress / max_progress * 100.0) if max_progress > 0 else 0.0
		var status = "Выполнено" if task.get("is_completed", false) else "В процессе"

		result += "- %s: %.1f%% (%s)\n" % [name, percentage, status]

		if task.get("is_completed", false):
			completed += 1
		var text = "%s: %.1f%%\n  Stones: %d/%d\n  Curiosities: %d/%d" % [task, name, progress, max_progress, percentage, status]
		print("Button task text: ", text)
		return text
	return result
