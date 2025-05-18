extends Control

@onready var info_label: Label = $TextureRect/Label
@onready var task_manager = get_node_or_null("/root/TaskManager")

var font_size: int = 32
var shadow_color: Color = Color(0, 0, 0, 0.6)
var shadow_offset: Vector2 = Vector2(3, 3)
var completed_tasks: Array[String] = []
var label_margin: int = 0
var default_color: Color = Color.WHITE
var completed_color: Color = Color.GREEN
var error_color: Color = Color.RED

func _ready() -> void:
	# Verify node initialization
	if not info_label:
		push_error("Failed to find info_label at $TextureRect/Label.")
		return
	print("info_label found: ", info_label.name)
	
	if not task_manager:
		push_error("TaskManager node not found at /root/TaskManager.")
		return
	print("task_manager found: ", task_manager.get_path())
	
	# Set up the parent Control
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	self.add_theme_constant_override("margin_left", 0)
	self.add_theme_constant_override("margin_right", 0)
	self.add_theme_constant_override("margin_top", 0)
	self.add_theme_constant_override("margin_bottom", 0)
	
	# Initialize label with header
	apply_label_style(info_label, "Task Statistics", default_color, true)
	
	# Wait for frame to ensure scene is ready
	await get_tree().process_frame
	
	# Connect signals
	if task_manager.has_signal("task_registered"):
		if not task_manager.task_registered.is_connected(_on_task_registered):
			task_manager.task_registered.connect(_on_task_registered)
			print("Connected task_registered signal.")
	if task_manager.has_signal("task_updated"):
		if not task_manager.task_updated.is_connected(_on_task_updated):
			task_manager.task_updated.connect(_on_task_updated)
			print("Connected task_updated signal.")
	if task_manager.has_signal("task_completed"):
		if not task_manager.task_completed.is_connected(_on_task_completed):
			task_manager.task_completed.connect(_on_task_completed)
			print("Connected task_completed signal.")
	else:
		print("No task_completed signal available in TaskManager.")
	
	# Initial display
	display_active_tasks()
	
	# Debug sizes
	print("info_label size: ", info_label.size)
	print("self size: ", self.size)
	if task_manager:
		print("Initial tasks: ", task_manager.tasks.keys())

func apply_label_style(label: Label, text: String = "", color: Color = default_color, is_header: bool = false) -> void:
	if not label:
		push_error("Label is null in apply_label_style.")
		return
	
	label.text = text
	print("Applying style to label with text: ", text.left(50), "...") # Debug first 50 chars
	
	# Set font size
	label.add_theme_font_size_override("font_size", font_size if not is_header else font_size + 12)
	label.add_theme_color_override("font_color", color)
	
	# Add shadow
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
	label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
	
	# Add outline
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4 if is_header else 3)
	
	# Configure alignment and sizing
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Use word wrap to ensure text visibility
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_constant_override("margin_left", label_margin)
	label.add_theme_constant_override("margin_right", label_margin)
	label.add_theme_constant_override("margin_top", label_margin)
	label.add_theme_constant_override("margin_bottom", label_margin)
	
	# Add line spacing
	label.add_theme_constant_override("line_spacing", 5 if not is_header else 10)
	
	if is_header:
		label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	
	# Ensure label is visible
	label.visible = true
	print("Label style applied: font_size=", label.get_theme_font_size("font_size"), ", color=", label.get_theme_color("font_color"))

func generate_task_text(task: Dictionary, is_completed: bool = false) -> String:
	if not task or not task.has("name"):
		print("Invalid task data: ", task)
		return ""
	
	var progress_percent = 0.0
	if task.max_progress > 0:
		progress_percent = (task.progress / task.max_progress * 100.0)
	if is_completed:
		progress_percent = 100.0
	var status_text = "Completed" if is_completed else "In Progress"
	var time_estimate = task.get("estimated_time", "N/A")
	var priority = task.get("priority", "Normal")
	
	var task_text = (
		"Task: %s | Progress: %.1f%% | Status: %s | Priority: %s | Time: %s\n\n"
	) % [task.name, progress_percent, status_text, priority, time_estimate]
	
	print("Generated task text: ", task_text.left(50), "...") # Debug first 50 chars
	return task_text

func display_active_tasks() -> void:
	var text = ""
	var active_tasks: Array[Dictionary] = []
	
	# Collect active tasks
	if task_manager:
		for task_id in task_manager.tasks:
			var task = task_manager.tasks[task_id]
			if not task.get("is_completed", false) and task.name not in completed_tasks:
				active_tasks.append(task)
				text += generate_task_text(task)
	
	# Add completed tasks
	for completed_task_name in completed_tasks:
		var task = task_manager.tasks.values().filter(func(t): return t.name == completed_task_name).front()
		if task:
			text += generate_task_text(task, true)
	
	# Handle no tasks
	if active_tasks.is_empty() and completed_tasks.is_empty():
		text = "No active tasks available.\nCreate a new task to get started!"
		apply_label_style(info_label, text, error_color)
	else:
		apply_label_style(info_label, text, default_color)
	
	# Add hover effect
	info_label.mouse_filter = Control.MOUSE_FILTER_PASS
	if not info_label.mouse_entered.is_connected(_on_label_mouse_entered):
		info_label.mouse_entered.connect(_on_label_mouse_entered)
	if not info_label.mouse_exited.is_connected(_on_label_mouse_exited):
		info_label.mouse_exited.connect(_on_label_mouse_exited)
	
	print("display_active_tasks: Text set to: ", text.left(50), "...")
	print("Active tasks: ", active_tasks.size(), ", Completed tasks: ", completed_tasks.size())

func _on_label_mouse_entered() -> void:
	info_label.modulate = Color(1.2, 1.2, 1.2)
	print("Mouse entered label")

func _on_label_mouse_exited() -> void:
	info_label.modulate = Color(1.0, 1.0, 1.0)
	print("Mouse exited label")

func _on_task_registered(task_id: String, task_name: String, max_progress: float) -> void:
	print("Task registered signal received: ", task_name)
	display_active_tasks()

func _on_task_updated(task_id: String, progress: float, max_progress: float, percentage: float, is_completed: bool, details: Dictionary) -> void:
	print("Task updated signal received: ", task_id, ", Progress: ", percentage, "%")
	display_active_tasks()

func _on_task_completed(task_id: String, task_name: String) -> void:
	if task_name and task_name not in completed_tasks:
		completed_tasks.append(task_name)
		print("Task completed: ", task_name, ", Total completed: ", completed_tasks)
	display_active_tasks()
