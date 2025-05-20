extends Control

const GAME_SCENE_PATH = "res://global_menu.tscn"
@onready var menu = get_node_or_null("/root/main/Player/CameraPivot/Camera3D/UI/CanvasLayer/menu")

func resume():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Adjust to your game's mouse mode
	Input.flush_buffered_events() # Clear any stale inputs

func pause():
	get_tree().paused = true

func _ready():
	if menu == null:
		print("Error: Menu node not found at path!")
	$Creadits.visible = false
	$yesornot.visible = false
	$Setting.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_continue_pressed() -> void:
	print("Continue pressed, hiding menu and resuming")
	menu.visible = false
	resume()
	if menu.get_viewport().gui_get_focus_owner():
		menu.get_viewport().gui_release_focus()

func _on_exit_pressed() -> void:
	$yesornot.visible = true

func _on_no_pressed() -> void:
	$yesornot.visible = false

func _on_yes_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_frame_pressed() -> void:
	$Creadits.visible = !$Creadits.visible

func _on_setting_pressed() -> void:
	$Setting.visible = !$Setting.visible

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Mouse button pressed: ", event.button_index, " Paused: ", get_tree().paused)
