extends StaticBody3D

var is_button_open: bool = false
var day_counter: int = 0
var oxygen_decrease_count: int = 0
var can_press: bool = true
@onready var button_node: StaticBody3D = $button
@onready var bed: StaticBody3D = $Bed
@onready var player = get_node("/root/main/Player")
@onready var camera = player.get_node("CameraPivot/Camera3D")
@onready var InteractRay = player.get_node("CameraPivot/Camera3D/InteractRay")
@onready var day = player.get_node("CameraPivot/Camera3D/UI/Map/Day")
@onready var day_l = player.get_node("CameraPivot/Camera3D/UI/Map/Day/Day")
@onready var animation_player = $Bed/AnimationPlayer
const SAVE_PATH = "user://player_save.json"
@onready var no_water_zone = get_node("/root/main/Map3d/no_water_zone/CollisionShape3D")


func _ready():
	if animation_player and animation_player.has_animation("static"):
		animation_player.play("static")  # Play the static animation
	# Hook up the buttons so they actually do something when pressed
	if button_node:  # If the cube button exists...
		button_node.connect("button_state_changed", _on_button_state_changed)
	load_player_state()
	update_day_label()
	can_press = true
	# Ensure bed is pickable
	bed.input_ray_pickable = true

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("player_use_item"):
		# Check if InteractRay is colliding with anything
		if InteractRay.is_colliding():
			var collider = InteractRay.get_collider()
			if collider == bed:  # If the ray collided with the bed
				if is_button_open and can_press:
					if can_press:
						# Get the total task completion percentage
						var total_percentage = get_total_task_completion()
						
						if total_percentage >= 20.0 and total_percentage <= 40.0:
							print("20-40% block triggered")
							if no_water_zone:
								no_water_zone.disabled = true
			
							else:
								printerr("Error: no_water_zone or no_water_zone2 is null")
							if player.has_method("decrease_o2"):
								oxygen_decrease_count += 2  # Increment counter
								player.decrease_o2(20.0 * oxygen_decrease_count)
								player.set_can_move(false)  # Disable player movement
								print("Oxygen decreased by 60")
							else:
								printerr("Error: Player has no decrease_o2 method")
							print("Ты проиграл! Прогресс: %.1f%%" % total_percentage)
				
						
						
						# Proceed with day increment and scene restart
						can_press = false
						day_counter += 1
						update_day_label()
						restart_scene()
					else:
						if player.AudioManager:
							player.AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")

func get_total_task_completion() -> float:
	var task_manager = get_node("/root/TaskManager")
	if not task_manager:
		printerr("Error: TaskManager not found.")
		return 0.0
	
	var total_max = 0.0
	var total_progress = 0.0
	for task in task_manager.tasks.values():
		total_max += task.max_progress
		total_progress += task.progress
	
	var total_percentage = (total_progress / total_max) * 100.0 if total_max > 0 else 0.0
	return total_percentage

func update_day_label():
	day_l.text = "Day: " + str(day_counter)

func save_player_state():
	if not player or not camera:
		printerr("Error: Player or camera node is not initialized.")
		return

	var save_data = {
		"money": player.money,
		"day_counter": day_counter,
		"position": {
			"x": player.position.x,
			"y": player.position.y,
			"z": player.position.z
		}
	}
	if camera and camera is Camera3D:
		var camera_quat = camera.quaternion
		save_data["camera_quaternion"] = {
			"x": camera_quat.x,
			"y": camera_quat.y,
			"z": camera_quat.z,
			"w": camera_quat.w
		}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
	else:
		printerr("Error: Could not save player state")

func load_player_state():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			player.money = data.get("money", 0)
			day_counter = data.get("day_counter", 0)
			
			if data.has("position"):
				var pos = data["position"]
				player.position = Vector3(
					pos.get("x", 0.0),
					pos.get("y", 0.0),
					pos.get("z", 0.0)
				)
			
			if data.has("camera_quaternion") and camera and camera is Camera3D:
				var quat_data = data["camera_quaternion"]
				var loaded_quat = Quaternion(
					quat_data.get("x", 0.0),
					quat_data.get("y", 0.0),
					quat_data.get("z", 0.0),
					quat_data.get("w", 1.0)
				)
				camera.quaternion = loaded_quat
			
			update_day_label()
		else:
			printerr("Error parsing save file: ", error)
	else:
		printerr("Error: Could not load player state")

func info_tablet_view():
	print("func working1")
	player.open_info_tablet()
	print("func open info tablet")
	#player.close_info_tablet()

func restart_scene():
	if not get_tree():
		printerr("Error: Scene tree is null.")
		return
	print("func working2")
	info_tablet_view()
	await get_tree().create_timer(5.0).timeout
	save_player_state()
	var total_percentage = get_total_task_completion()
	if total_percentage > 40.0 and total_percentage <= 60.0:
		player.show_notification("Alright, halfway there. Progress: %.1f%%" % total_percentage, 6.0)
		print("Alright, halfway there. Progress: %.1f%%" % total_percentage)
		await get_tree().create_timer(5.0).timeout
		get_tree().reload_current_scene()
	elif total_percentage > 60.0 and total_percentage <= 100.0:
		player.show_notification("Great job! Progress: %.1f%%" % total_percentage, 6.0)
		print("Great job! Progress: %.1f%%" % total_percentage)
		await get_tree().create_timer(5.0).timeout
		get_tree().reload_current_scene()

func _on_button_state_changed(is_pressed: bool):
	if is_pressed:
		if can_press:
			if animation_player:
				if is_button_open:
					if animation_player.has_animation("close"):
						animation_player.play("close")
						is_button_open = false
						# Play sound for closing the bed
						if player.AudioManager:
							player.AudioManager.play_sound("res://sounds/bed.mp3")
						else:
							printerr("Error: AudioManager not found")
					else:
						printerr("Error: Animation 'close' not found")
				else:
					if animation_player.has_animation("open"):
						animation_player.play("open")
						is_button_open = true
						# Play sound for opening the bed
						if player.AudioManager:
							player.AudioManager.play_sound("res://sounds/bed.mp3")
						else:
							printerr("Error: AudioManager not found")
					else:
						printerr("Error: Animation 'open' not found")
			else:
				printerr("Error: AnimationPlayer not found")
	else:
		if player.AudioManager:
			player.AudioManager.play_sound("res://sounds/button/wpn_denyselect.mp3")
		else:
			printerr("Error: AudioManager not found")
