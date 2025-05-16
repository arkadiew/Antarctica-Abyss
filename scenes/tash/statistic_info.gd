extends Control

@onready var info_list: VBoxContainer = $statisticContainer
@onready var info_label: Label = $statisticContainer/Label
@onready var task_manager = get_node_or_null("/root/TaskManager")

var font_size: int = 32
var shadow_color: Color = Color(0, 0, 0, 0.6)
var shadow_offset: Vector2 = Vector2(3, 3)
var completed_tasks: Array[String] = []
var label_margin: int = 0  # Уже установлено в 0
var default_color: Color = Color.WHITE
var completed_color: Color = Color.GREEN
var error_color: Color = Color.RED

func _ready() -> void:
	if not info_list or not info_label:
		push_error("Failed to find info_list or info_label nodes.")
		return
	
	if not task_manager:
		push_error("TaskManager node not found at /root/TaskManager.")
		return
	
	# Configure info_list to expand fully and center content
	info_list.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_list.set_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	info_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_list.add_theme_constant_override("separation", 10)
	info_list.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Убедимся, что у statisticContainer нет отступов
	info_list.add_theme_constant_override("margin_left", 0)
	info_list.add_theme_constant_override("margin_right", 0)
	info_list.add_theme_constant_override("margin_top", 0)
	info_list.add_theme_constant_override("margin_bottom", 0)
	
	# Проверим родительский узел (сам Control)
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	self.add_theme_constant_override("margin_left", 0)
	self.add_theme_constant_override("margin_right", 0)
	self.add_theme_constant_override("margin_top", 0)
	self.add_theme_constant_override("margin_bottom", 0)
	
	apply_label_style(info_label, "Task Statistics", default_color, true)
	await get_tree().process_frame
	
	if task_manager.has_signal("task_completed"):
		task_manager.task_completed.connect(on_task_completed)
	else:
		print("No task_completed signal available in TaskManager.")
	
	display_active_tasks()
	
	# Добавим отладочную информацию
	print("info_list size: ", info_list.size)
	print("info_label size: ", info_label.size)
	print("self size: ", self.size)

func apply_label_style(label: Label, text: String = "", color: Color = default_color, is_header: bool = false) -> void:
	if not label:
		return
	
	label.text = text
	label.add_theme_font_size_override("font_size", font_size if not is_header else font_size + 12)
	label.add_theme_color_override("font_color", color)
	
	# Add shadow
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
	label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
	
	# Add outline
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4 if is_header else 3)
	
	# Center text and ensure full width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_OFF  # Отключаем перенос, чтобы текст не переносился
	label.add_theme_constant_override("margin_left", label_margin)
	label.add_theme_constant_override("margin_right", label_margin)
	label.add_theme_constant_override("margin_top", label_margin)
	label.add_theme_constant_override("margin_bottom", label_margin)
	
	# Add line spacing
	label.add_theme_constant_override("line_spacing", 5 if not is_header else 10)
	
	if is_header:
		label.add_theme_color_override("font_color", Color.LIGHT_BLUE)

func generate_task_label(task: Dictionary, is_completed: bool = false) -> Label:
	var label = Label.new()
	var progress_percent = (task.progress / task.max_progress * 100.0) if not is_completed else 100.0
	var status_text = "Completed" if is_completed else "In Progress"
	var time_estimate = task.get("estimated_time", "N/A")
	var priority = task.get("priority", "Normal")
	
	var label_text = (
		"Task: %s\n" +
		"Progress: %.1f%%\n" +
		"Status: %s\n" +
		"Priority: %s\n" +
		"Estimated Time: %s"
	) % [task.name, progress_percent, status_text, priority, time_estimate]
	
	apply_label_style(
		label,
		label_text,
		completed_color if is_completed else default_color
	)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add hover effect
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.mouse_entered.connect(func(): label.modulate = Color(1.2, 1.2, 1.2))
	label.mouse_exited.connect(func(): label.modulate = Color(1.0, 1.0, 1.0))
	
	return label

func display_active_tasks() -> void:
	for child in info_list.get_children():
		if child != info_label:
			info_list.remove_child(child)
			child.queue_free()
	
	var active_tasks: Array[Dictionary] = []
	
	for task_id in task_manager.tasks:
		var task = task_manager.tasks[task_id]
		if not task.get("is_completed", false) and task.name not in completed_tasks:
			active_tasks.append(task)
			var label = generate_task_label(task)
			info_list.add_child(label)
	
	for completed_task_name in completed_tasks:
		var task = task_manager.tasks.values().filter(func(t): return t.name == completed_task_name).front()
		if task:
			var label = generate_task_label(task, true)
			info_list.add_child(label)
	
	if active_tasks.is_empty() and completed_tasks.is_empty():
		var error_label = Label.new()
		apply_label_style(
			error_label,
			"No active tasks available.\nCreate a new task to get started!",
			error_color
		)
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_list.add_child(error_label)

func on_task_completed(task_id: String, task_name: String) -> void:
	if task_name and task_name not in completed_tasks:
		completed_tasks.append(task_name)
	display_active_tasks()
