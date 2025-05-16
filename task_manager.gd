extends Node

signal task_registered(task_id: String, task_name: String, max_progress: float)
signal task_updated(task_id: String, progress: float, max_progress: float, percentage: float, is_completed: bool, details: Dictionary)
signal task_completed(task_id: String, task_name: String)
signal total_completion_updated(percentage: float)

var tasks: Dictionary = {}

func register_task(task_id: String, task_name: String, max_progress: float, contributor_id: String = "", details: Dictionary = {}) -> void:
	if not tasks.has(task_id):
		tasks[task_id] = {
			"name": task_name,
			"progress": 0.0,
			"max_progress": 0.0,
			"is_completed": false,
			"contributors": {},
			"details": details.duplicate()
		}
	if contributor_id != "":
		if tasks[task_id].contributors.has(contributor_id):
			print("Warning: Duplicate contributor_id ", contributor_id, " for task ", task_id)
		tasks[task_id].contributors[contributor_id] = {
			"progress": 0.0,
			"max_progress": max_progress
		}
		tasks[task_id].max_progress = 0.0
		for contrib in tasks[task_id].contributors.values():
			tasks[task_id].max_progress += contrib.max_progress
	emit_signal("task_registered", task_id, task_name, tasks[task_id].max_progress)
	print("Task registered: ", task_id, ", Contributors: ", tasks[task_id].contributors.keys(), ", Max Progress: ", tasks[task_id].max_progress)

func update_task_progress(task_id: String, contributor_id: String, progress: float) -> void:
	if tasks.has(task_id) and tasks[task_id].contributors.has(contributor_id):
		var task = tasks[task_id]
		var contributor = task.contributors[contributor_id]
		contributor.progress = min(progress, contributor.max_progress)
		
		task.progress = 0.0
		for contrib in task.contributors.values():
			task.progress += contrib.progress
		
		task.is_completed = task.progress >= task.max_progress
		var percentage = (task.progress / task.max_progress) * 100.0 if task.max_progress > 0 else 0.0
		var details = task.details.duplicate()
		if task_id == "button_task":
			details["current_items"] = get_button_task_items(task_id, task.progress)
		emit_signal("task_updated", task_id, task.progress, task.max_progress, percentage, task.is_completed, details)
		if task.is_completed:
			emit_signal("task_completed", task_id, task.name)
		update_total_completion()
		print("Task updated: ", task_id, ", Contributor: ", contributor_id, ", Progress: ", task.progress, ", Max: ", task.max_progress, ", Contributors: ", task.contributors.keys())

func update_button_task_items(task_id: String, item_counters: Dictionary) -> void:
	if tasks.has(task_id) and task_id == "button_task":
		var task = tasks[task_id]
		var contributor_id = task.contributors.keys()[0] if task.contributors.size() > 0 else "button"
		var stones = min(item_counters.get("Stone", 0), task.details.get("items", {}).get("Stone", 0))
		var curiosities = min(item_counters.get("Curiosity", 0), task.details.get("items", {}).get("Curiosity", 0))
		var progress = stones + curiosities
		update_task_progress(task_id, contributor_id, progress)
		var percentage = (progress / task.max_progress) * 100.0 if task.max_progress > 0 else 0.0
		var details = task.details.duplicate()
		details["current_items"] = {"Stone": stones, "Curiosity": curiosities}
		emit_signal("task_updated", task_id, progress, task.max_progress, percentage, task.is_completed, details)
		print("Button task items updated: ", details["current_items"])

func get_button_task_items(task_id: String, progress: float) -> Dictionary:
	var task = tasks.get(task_id, {})
	var items = task.get("details", {}).get("items", {"Stone": 0, "Curiosity": 0})
	var stones = min(int(progress), items.get("Stone", 0))
	var curiosities = min(int(progress) - stones, items.get("Curiosity", 0))
	return {"Stone": stones, "Curiosity": curiosities}

func update_total_completion() -> void:
	var total_max = 0.0
	var total_progress = 0.0
	for task in tasks.values():
		total_max += task.max_progress
		total_progress += task.progress
	var total_percentage = (total_progress / total_max) * 100.0 if total_max > 0 else 0.0
	emit_signal("total_completion_updated", total_percentage)
	print("Total completion: ", total_percentage)

func get_task_requirements() -> Dictionary:
	var requirements = {}
	for task_id in tasks:
		var task = tasks[task_id]
		var req = {
			"name": task.name,
			"details": task.details.duplicate(),
			"contributors": task.contributors.size()
		}
		if task_id == "button_task":
			req["items"] = task.details.get("items", {})
		elif task_id == "pipe_repair":
			req["pipe_count"] = task.contributors.size()
		requirements[task_id] = req
	return requirements
