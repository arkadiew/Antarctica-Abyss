extends Control

@onready var continue_button = $menu/Continue

const SAVE_PATH = "user://player_save.json"
const SAVE_PATH2 = "user://object_save.json"
const GAME_SCENE_PATH = "res://Main.tscn"

func _ready():
	$Creadits.visible = false
	$Setting.visible = false
	continue_button.visible = FileAccess.file_exists(SAVE_PATH)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false  # Убедимся, что игра не на паузе
	$menu/NewGame.grab_focus()  # Устанавливаем фокус на кнопку "New Game"
	print("Main menu loaded, mouse mode: ", Input.get_mouse_mode())

func _on_new_game_pressed() -> void:
	print("New Game button pressed")
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH2):
		DirAccess.remove_absolute(SAVE_PATH2)
	if TaskManager:
		TaskManager.reset_tasks()
	else:
		print("TaskManager not found!")
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_continue_pressed() -> void:
	print("Continue button pressed")
	if TaskManager:
		TaskManager.reset_tasks()
	else:
		print("TaskManager not found!")
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_exit_pressed() -> void:
	print("Exit button pressed")
	get_tree().quit()

func _on_frame_pressed() -> void:
	$Creadits.visible = !$Creadits.visible
	if $Creadits.visible:
		$Creadits.grab_focus()  # Устанавливаем фокус на Credits, если нужно

func _on_setting_pressed() -> void:
	$Setting.visible = !$Setting.visible
	if $Setting.visible:
		$Setting.grab_focus()  # Устанавливаем фокус на Settings, если нужно
